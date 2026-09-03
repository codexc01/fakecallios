import AppIntents

// регистрация быстрых фраз для siri и шорткатов
struct FakeCallShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TriggerFakeCallIntent(),
            phrases: [
                "Фейковый звонок в \(.applicationName)",
                "Спаси меня в \(.applicationName)"
            ],
            shortTitle: "Фейковый звонок",
            systemImageName: "phone.arrow.down.left.fill"
        )
    }
}
