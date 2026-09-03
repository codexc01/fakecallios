import SwiftUI

struct CreateScriptView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recorder = AudioRecorderService()
    @StateObject private var player = AudioPlayerService.shared

    @State private var title = ""
    @State private var callerName = ""
    @State private var delaySeconds = 5.0
    @State private var recordedFileName: String?

    let onSave: (CallScript) -> Void

    private let availableDelays = [5.0, 10.0, 20.0, 30.0]

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !callerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.06)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // параметры сценария
                        VStack(alignment: .leading, spacing: 14) {
                            Text("ДАННЫЕ ВЫЗОВА")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)

                            VStack(spacing: 1) {
                                TextField("Название (напр. Шеф звонит)", text: $title)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 13)
                                    .background(Color(red: 0.10, green: 0.10, blue: 0.12))

                                Divider()
                                    .background(Color.white.opacity(0.06))

                                TextField("Имя абонента (напр. Иван Сергеевич)", text: $callerName)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 13)
                                    .background(Color(red: 0.10, green: 0.10, blue: 0.12))
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }

                        // выбор задержки перед звонком
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ЗАДЕРЖКА")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)

                            HStack(spacing: 8) {
                                ForEach(availableDelays, id: \.self) { val in
                                    Button {
                                        delaySeconds = val
                                    } label: {
                                        Text("\(Int(val)) сек")
                                            .font(.system(size: 13, weight: .medium))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(delaySeconds == val ? Color.white : Color(red: 0.10, green: 0.10, blue: 0.12))
                                            .foregroundColor(delaySeconds == val ? .black : .white)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.white.opacity(delaySeconds == val ? 0 : 0.08), lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // запись голосовой реплики
                        VStack(alignment: .leading, spacing: 12) {
                            Text("РЕПЛИКА В ДИНАМИКЕ")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)

                            VStack(spacing: 12) {
                                if recorder.permissionDenied {
                                    Text("Разрешите доступ к микрофону в Настройках iOS")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                HStack {
                                    Button {
                                        toggleRecording()
                                    } label: {
                                        HStack(spacing: 8) {
                                            Circle()
                                                .fill(recorder.isRecording ? Color.red : Color.white)
                                                .frame(width: 10, height: 10)

                                            Text(recorder.isRecording ? "Идет запись..." : (recordedFileName != nil ? "Перезаписать" : "Записать голос"))
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 9)
                                        .background(recorder.isRecording ? Color.red.opacity(0.15) : Color.white.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)

                                    Spacer()

                                    if recorder.isRecording {
                                        Text(String(format: "%.1f с", recorder.recordingDuration))
                                            .font(.system(size: 14, weight: .semibold).monospacedDigit())
                                            .foregroundColor(.red)
                                    }
                                }

                                if let file = recordedFileName ?? recorder.lastRecordedFileName, !recorder.isRecording {
                                    Divider()
                                        .background(Color.white.opacity(0.06))

                                    HStack {
                                        Image(systemName: "waveform")
                                            .foregroundColor(.secondary)
                                            .font(.subheadline)

                                        Text("Голос сохранен")
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)

                                        Spacer()

                                        Button {
                                            if player.isPlaying {
                                                player.stopVoice()
                                            } else {
                                                player.playScenarioAudio(fileName: file)
                                            }
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: player.isPlaying ? "stop.fill" : "play.fill")
                                                    .font(.caption2)
                                                Text(player.isPlaying ? "Стоп" : "Тест")
                                                    .font(.system(size: 12, weight: .medium))
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.white.opacity(0.08))
                                            .foregroundColor(.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                        }
                                        .buttonStyle(.plain)

                                        Button {
                                            recordedFileName = nil
                                            recorder.lastRecordedFileName = nil
                                            player.stopVoice()
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.caption)
                                                .foregroundColor(.red.opacity(0.8))
                                                .padding(6)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(14)
                            .background(Color(red: 0.10, green: 0.10, blue: 0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Новый сценарий")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(red: 0.05, green: 0.05, blue: 0.06), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        close()
                    }
                    .foregroundColor(.secondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        let script = CallScript(
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            callerName: callerName.trimmingCharacters(in: .whitespacesAndNewlines),
                            delaySeconds: delaySeconds,
                            audioFileName: recordedFileName ?? recorder.lastRecordedFileName
                        )
                        onSave(script)
                        close()
                    }
                    .disabled(!isValid)
                    .foregroundColor(isValid ? .white : .secondary.opacity(0.4))
                    .fontWeight(.semibold)
                }
            }
            .onDisappear {
                close()
            }
        }
        .preferredColorScheme(.dark)
    }

    private func toggleRecording() {
        if recorder.isRecording {
            recorder.stopRecording()
            recordedFileName = recorder.lastRecordedFileName
        } else {
            player.stopVoice()
            recorder.startRecording()
        }
    }

    private func close() {
        if recorder.isRecording {
            recorder.stopRecording()
        }
        player.stopVoice()
        dismiss()
    }
}
