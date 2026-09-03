import Foundation
import AVFoundation
import Combine

final class AudioRecorderService: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var lastRecordedFileName: String?
    @Published var recordingDuration: TimeInterval = 0
    @Published var permissionDenied = false

    private var recorder: AVAudioRecorder?
    private var timer: Timer?

    // запуск записи с проверкой разрешений
    func startRecording() {
        permissionDenied = false

        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.beginRecordingSession()
                    } else {
                        self?.permissionDenied = true
                    }
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.beginRecordingSession()
                    } else {
                        self?.permissionDenied = true
                    }
                }
            }
        }
    }

    // создание файла и старт сессии записи m4a
    private func beginRecordingSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)

            let fileName = "voice_\(UUID().uuidString).m4a"
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = docs.appendingPathComponent(fileName)

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            recorder = try AVAudioRecorder(url: fileURL, settings: settings)
            recorder?.delegate = self
            recorder?.isMeteringEnabled = true
            
            guard recorder?.record() == true else {
                print("recorder could not start")
                return
            }

            isRecording = true
            lastRecordedFileName = fileName
            recordingDuration = 0

            // таймер длительности записи
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self, let recorder = self.recorder, recorder.isRecording else { return }
                self.recordingDuration = recorder.currentTime
            }
        } catch {
            print("record session error: \(error.localizedDescription)")
            isRecording = false
        }
    }

    // остановка записи голоса
    func stopRecording() {
        timer?.invalidate()
        timer = nil

        recorder?.stop()
        recorder = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        isRecording = false
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isRecording = false
            self.timer?.invalidate()
            self.timer = nil
        }
    }
}
