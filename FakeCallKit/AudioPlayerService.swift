import Foundation
import AVFoundation
import Combine

final class AudioPlayerService: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = AudioPlayerService()

    private var player: AVAudioPlayer?
    @Published private(set) var isPlaying = false

    private override init() {
        super.init()
    }

    // воспроизведение реплики в разговорный динамик
    func playScenarioAudio(fileName: String) {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent(fileName)

        guard FileManager.default.fileExists(atPath: url.path) else {
            print("audio file not found: \(url.path)")
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            // режим voiceChat перенаправляет звук в ушной динамик
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowBluetoothA2DP])
            try session.setActive(true)

            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.prepareToPlay()
            player?.play()

            DispatchQueue.main.async {
                self.isPlaying = true
            }
        } catch {
            print("failed to play audio: \(error.localizedDescription)")
        }
    }

    // остановка звука
    func stopVoice() {
        player?.stop()
        player = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
}
