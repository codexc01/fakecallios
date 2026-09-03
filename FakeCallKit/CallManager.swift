import Foundation
import CallKit
import Combine

final class CallManager: NSObject, ObservableObject, CXProviderDelegate {
    static let shared = CallManager()

    private let provider: CXProvider
    private var countdownTimer: Timer?
    private var activeCallUUID: UUID?

    // текущий сценарий и статус ожидания
    @Published var currentScript: CallScript?
    @Published var isCallPending = false
    @Published var secondsLeft = 0
    @Published var isCallPresented = false

    private override init() {
        // конфигурация системного callkit
        let config = CXProviderConfiguration()
        config.supportsVideo = false
        config.maximumCallsPerCallGroup = 1
        config.supportedHandleTypes = [.phoneNumber, .generic]
        config.includesCallsInRecents = false

        self.provider = CXProvider(configuration: config)
        super.init()
        self.provider.setDelegate(self, queue: DispatchQueue.main)
    }

    // запуск таймера перед вызовом
    func startFakeCallSequence(script: CallScript) {
        cancelPendingCall()

        currentScript = script
        let callUUID = UUID()
        activeCallUUID = callUUID

        let totalDelay = Int(script.delaySeconds)
        if totalDelay <= 0 {
            triggerIncomingCall(uuid: callUUID, script: script)
            return
        }

        isCallPending = true
        secondsLeft = totalDelay

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else { return }
            if self.secondsLeft > 1 {
                self.secondsLeft -= 1
            } else {
                timer.invalidate()
                self.countdownTimer = nil
                self.isCallPending = false
                self.secondsLeft = 0
                self.triggerIncomingCall(uuid: callUUID, script: script)
            }
        }
    }

    // отмена запланированного звонка
    func cancelPendingCall() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        isCallPending = false
        secondsLeft = 0
    }

    // вызов реального системного звонка iphone
    private func triggerIncomingCall(uuid: UUID, script: CallScript) {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .phoneNumber, value: script.callerName)
        update.localizedCallerName = script.callerName
        update.hasVideo = false
        update.supportsHolding = false
        update.supportsGrouping = false
        update.supportsUngrouping = false
        update.supportsDTMF = false

        DispatchQueue.main.async {
            self.isCallPresented = true
        }

        // отправляем сигнал в систему ios для показа реального экрана звонка
        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            if let error {
                print("callkit error: \(error.localizedDescription)")
            }
        }
    }

    func providerDidReset(_ provider: CXProvider) {
        AudioPlayerService.shared.stopVoice()
        activeCallUUID = nil
        isCallPending = false
        isCallPresented = false
    }

    // пользователь принял вызов
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        if let audioFileName = currentScript?.audioFileName {
            AudioPlayerService.shared.playScenarioAudio(fileName: audioFileName)
        }
        action.fulfill()
    }

    // пользователь отклонил или завершил вызов
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        AudioPlayerService.shared.stopVoice()
        activeCallUUID = nil
        isCallPresented = false
        action.fulfill()
    }

    func dismissCallManually() {
        AudioPlayerService.shared.stopVoice()
        activeCallUUID = nil
        isCallPresented = false
    }
}
