import SwiftUI

struct ContentView: View {
    @StateObject private var callManager = CallManager.shared
    @AppStorage("active_script_id") private var activeScriptId = ""
    @AppStorage("saved_scripts") private var savedData = Data()

    @State private var scripts: [CallScript] = []
    @State private var showCreate = false

    // активный сценарий для быстрого запуска
    private var activeScript: CallScript? {
        scripts.first(where: { $0.id.uuidString == activeScriptId }) ?? scripts.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.04, green: 0.04, blue: 0.05)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        // плашка обратного отсчета до звонка
                        if callManager.isCallPending {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.12), lineWidth: 3)
                                        .frame(width: 40, height: 40)

                                    Text("\(callManager.secondsLeft)")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Входящий вызов")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)

                                    Text("Появится системный экран звонка iPhone")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.5))
                                }

                                Spacer()

                                Button("Отмена") {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    callManager.cancelPendingCall()
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.1))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                            }
                            .padding(14)
                            .background(Color(red: 0.11, green: 0.11, blue: 0.13))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                        }

                        // блок быстрого старта звонка
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 6, height: 6)

                                    Text("АКТИВНЫЙ СЦЕНАРИЙ")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white.opacity(0.6))
                                }

                                Spacer()

                                if activeScript?.audioFileName != nil {
                                    HStack(spacing: 4) {
                                        Image(systemName: "waveform")
                                        Text("Голос")
                                    }
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.white.opacity(0.08))
                                    .clipShape(Capsule())
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(activeScript?.title ?? "Сценарий не выбран")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)

                                Text("Абонент: \(activeScript?.callerName ?? "-")")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                            }

                            HStack(spacing: 12) {
                                Button {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    if let script = activeScript {
                                        callManager.startFakeCallSequence(script: script)
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "timer")
                                            .font(.subheadline)
                                        Text("Через \(Int(activeScript?.delaySeconds ?? 5)) сек")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.white)
                                    .foregroundColor(.black)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                                .buttonStyle(.plain)

                                Button {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    if var script = activeScript {
                                        script.delaySeconds = 0
                                        callManager.startFakeCallSequence(script: script)
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "phone.fill")
                                            .font(.caption)
                                        Text("Сейчас")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 14)
                                    .background(Color(red: 0.16, green: 0.16, blue: 0.19))
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(18)
                        .background(Color(red: 0.09, green: 0.09, blue: 0.11))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )

                        // список всех добавленных сценариев
                        VStack(alignment: .leading, spacing: 12) {
                            Text("СПИСОК СЦЕНАРИЕВ")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.horizontal, 4)

                            VStack(spacing: 1) {
                                ForEach(scripts) { item in
                                    let isSelected = item.id.uuidString == activeScript?.id.uuidString

                                    HStack(spacing: 14) {
                                        Circle()
                                            .fill(isSelected ? Color.white : Color.clear)
                                            .frame(width: 8, height: 8)
                                            .padding(3)
                                            .overlay(
                                                Circle()
                                                    .stroke(isSelected ? Color.white : Color.white.opacity(0.2), lineWidth: 1.5)
                                            )

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(item.title)
                                                .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                                                .foregroundColor(.white)

                                            HStack(spacing: 6) {
                                                Text(item.callerName)
                                                Text("•")
                                                Text("\(Int(item.delaySeconds)) с")
                                                if item.audioFileName != nil {
                                                    Text("•")
                                                    Text("голос")
                                                }
                                            }
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.5))
                                        }

                                        Spacer()

                                        Button {
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            callManager.startFakeCallSequence(script: item)
                                        } label: {
                                            Image(systemName: "phone.fill")
                                                .font(.system(size: 13))
                                                .foregroundColor(.white)
                                                .padding(10)
                                                .background(Color.white.opacity(0.08))
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(isSelected ? Color(red: 0.12, green: 0.12, blue: 0.15) : Color(red: 0.08, green: 0.08, blue: 0.10))
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        activeScriptId = item.id.uuidString
                                    }

                                    if item.id != scripts.last?.id {
                                        Divider()
                                            .background(Color.white.opacity(0.05))
                                    }
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("FakeCallKit")
            .toolbarBackground(Color(red: 0.04, green: 0.04, blue: 0.05), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreate = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .sheet(isPresented: $showCreate) {
                CreateScriptView { newScript in
                    scripts.append(newScript)
                    save()
                    if scripts.count == 1 {
                        activeScriptId = newScript.id.uuidString
                    }
                }
            }
            .onAppear(perform: load)
        }
        .preferredColorScheme(.dark)
    }

    private func load() {
        if !savedData.isEmpty, let decoded = try? JSONDecoder().decode([CallScript].self, from: savedData) {
            scripts = decoded
        } else {
            scripts = CallScript.samples
            save()
        }

        if activeScriptId.isEmpty, let first = scripts.first {
            activeScriptId = first.id.uuidString
        }
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(scripts) {
            savedData = encoded
            UserDefaults.standard.set(encoded, forKey: "saved_scripts")
            UserDefaults.standard.set(activeScriptId, forKey: "active_script_id")
        }
    }
}
