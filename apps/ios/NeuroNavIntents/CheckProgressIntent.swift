import AppIntents
import NeuroNavKit

struct CheckProgressIntent: AppIntent {
    static var title: LocalizedStringResource = "Cómo Voy Hoy"
    static var description = IntentDescription("Consulta tu progreso de rutinas del día.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
        let completed = defaults?.integer(forKey: "dailyCompleted") ?? 0
        let total = defaults?.integer(forKey: "dailyTotal") ?? 0

        if total == 0 {
            return .result(dialog: "No tienes rutinas programadas para hoy.")
        }

        let percentage = Int(Double(completed) / Double(total) * 100)
        return .result(dialog: "Has completado \(completed) de \(total) rutinas hoy (\(percentage)%).")
    }
}

struct NeuroNavShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartRoutineIntent(),
            phrases: [
                "Iniciar rutina en \(.applicationName)",
                "Abrir rutina en \(.applicationName)",
            ],
            shortTitle: "Iniciar Rutina",
            systemImageName: "list.bullet.clipboard.fill"
        )

        AppShortcut(
            intent: CallCaregiverIntent(),
            phrases: [
                "Llamar a mi cuidador con \(.applicationName)",
                "Emergencia en \(.applicationName)",
            ],
            shortTitle: "Llamar Cuidador",
            systemImageName: "phone.fill"
        )

        AppShortcut(
            intent: CheckProgressIntent(),
            phrases: [
                "Cómo voy hoy en \(.applicationName)",
                "Mi progreso en \(.applicationName)",
            ],
            shortTitle: "Mi Progreso",
            systemImageName: "chart.bar.fill"
        )
    }
}
