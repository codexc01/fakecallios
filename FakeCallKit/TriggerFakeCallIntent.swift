import Foundation
import AppIntents

// интент для запуска сценария через action button и команды
struct TriggerFakeCallIntent: AppIntent {
    static var title: LocalizedStringResource = "Фейковый звонок"
    static var description = IntentDescription("Запускает таймер звонка по активному сценарию")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        var script = CallScript(
            title: "Срочный звонок",
            callerName: "Директор",
            delaySeconds: 5
        )

        // считываем выбранный пользователем сценарий
        if let data = UserDefaults.standard.data(forKey: "saved_scripts"),
           let list = try? JSONDecoder().decode([CallScript].self, from: data) {
            let activeId = UserDefaults.standard.string(forKey: "active_script_id")
            if let target = list.first(where: { $0.id.uuidString == activeId }) {
                script = target
            } else if let first = list.first {
                script = first
            }
        }

        CallManager.shared.startFakeCallSequence(script: script)
        return .result(dialog: "Звонок от '\(script.callerName)' через \(Int(script.delaySeconds)) сек")
    }
}
