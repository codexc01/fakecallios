import Foundation

// модель сценария фейкового звонка
struct CallScript: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var callerName: String
    var delaySeconds: Double = 5.0
    var audioFileName: String?

    static let samples: [CallScript] = [
        CallScript(
            title: "Звонок от начальника",
            callerName: "Алексей (Босс)",
            delaySeconds: 5
        ),
        CallScript(
            title: "Курьер",
            callerName: "Курьер Доставка",
            delaySeconds: 10
        ),
        CallScript(
            title: "Спасение со свидания",
            callerName: "Мама",
            delaySeconds: 15
        )
    ]
}
