import Foundation
import AVFoundation
import AudioToolbox

final class RingtoneService {
    static let shared = RingtoneService()

    private var player: AVAudioPlayer?
    private var vibrationTimer: Timer?

    private init() {
        prepareRingtoneFile()
    }

    func startRinging() {
        stopRinging()

        let docs = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let fileURL = docs.appendingPathComponent("iphone_opening.wav")

        if !FileManager.default.fileExists(atPath: fileURL.path) {
            prepareRingtoneFile()
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)

            player = try AVAudioPlayer(contentsOf: fileURL)
            player?.numberOfLoops = -1
            player?.volume = 1.0
            player?.prepareToPlay()
            player?.play()

            vibrationTimer?.invalidate()
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            vibrationTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
        } catch {
            print("ringtone playback error: \(error.localizedDescription)")
        }
    }

    func stopRinging() {
        player?.stop()
        player = nil
        vibrationTimer?.invalidate()
        vibrationTimer = nil
    }

    private func prepareRingtoneFile() {
        let docs = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let fileURL = docs.appendingPathComponent("iphone_opening.wav")

        let sampleRate: Double = 44100.0
        let bpm = 120.0
        let beatSec = 60.0 / bpm

        let notes: [(freq: Double, beats: Double)] = [
            (587.33, 0.5),
            (739.99, 0.5),
            (880.00, 0.5),
            (1174.66, 1.0),
            (880.00, 0.5),
            (739.99, 0.5),
            (587.33, 1.0),
            (0.0, 1.5)
        ]

        var audioSamples = [Int16]()

        for note in notes {
            let numSamples = Int(note.beats * beatSec * sampleRate)
            if note.freq == 0 {
                audioSamples.append(contentsOf: Array(repeating: 0, count: numSamples))
            } else {
                let angularFreq = 2.0 * Double.pi * note.freq
                for i in 0..<numSamples {
                    let t = Double(i) / sampleRate
                    let decay = exp(-3.0 * t)
                    let wave = sin(angularFreq * t) + 0.35 * sin(2.0 * angularFreq * t) + 0.15 * sin(3.0 * angularFreq * t)
                    let sampleVal = wave * decay * 0.75 * Double(Int16.max)
                    let clamped = max(Double(Int16.min), min(Double(Int16.max), sampleVal))
                    audioSamples.append(Int16(clamped))
                }
            }
        }

        let dataSize = audioSamples.count * 2
        var header = [UInt8]()
        header.append(contentsOf: [0x52, 0x49, 0x46, 0x46])
        let chunkSize = UInt32(dataSize + 36)
        header.append(contentsOf: withUnsafeBytes(of: chunkSize.littleEndian) { Array($0) })
        header.append(contentsOf: [0x57, 0x41, 0x56, 0x45])
        header.append(contentsOf: [0x66, 0x6D, 0x74, 0x20])
        header.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Array($0) })
        let byteRate = UInt32(sampleRate * 1 * 2)
        header.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt16(2).littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian) { Array($0) })
        header.append(contentsOf: [0x64, 0x61, 0x74, 0x61])
        header.append(contentsOf: withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Array($0) })

        var rawData = Data(header)
        rawData.append(Data(bytes: audioSamples, count: dataSize))

        try? rawData.write(to: fileURL, options: .atomic)
    }
}
