import AppIntents
import NeuroNavKit

struct CheckProgressIntent: AppIntent {
    static var title: LocalizedStringResource = "Cómo Voy Hoy"
    static var description = IntentDescription("Consulta tu progreso de rutinas del día.")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
        let completed = defaults?.integer(forKey: "dailyCompleted") ?? 0
        let total = defaults?.integer(forKey: "dailyTotal") ?? 0

        if total == 0 {
            return .result(dialog: "No tienes rutinas programadas para hoy.")
        }

        let percentage = Int(Double(completed) / Double(total) * 100)

        if completed == total {
            return .result(
                dialog: "Completaste todas tus rutinas hoy (\(total) de \(total)). \u{1F31F} Excelente trabajo."
            )
        }

        let remaining = total - completed
        return .result(
            dialog: "Has completado \(completed) de \(total) rutinas (\(percentage)%). Te faltan \(remaining)."
        )
    }
}

// MARK: - App Shortcuts Provider

struct NeuroNavShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // 1. Start Routine
        AppShortcut(
            intent: StartRoutineIntent(),
            phrases: [
                "Iniciar rutina en \(.applicationName)",
                "Abrir rutina en \(.applicationName)",
                "Empezar rutina con \(.applicationName)",
                "Start routine in \(.applicationName)",
                "Open routine in \(.applicationName)",
            ],
            shortTitle: "Iniciar Rutina",
            systemImageName: "list.bullet.clipboard.fill"
        )

        // 2. Call Caregiver
        AppShortcut(
            intent: CallCaregiverIntent(),
            phrases: [
                "Llamar a mi cuidador con \(.applicationName)",
                "Contactar a mi cuidador en \(.applicationName)",
                "Call my caregiver with \(.applicationName)",
                "Contact my caregiver in \(.applicationName)",
            ],
            shortTitle: "Llamar Cuidador",
            systemImageName: "phone.fill"
        )

        // 3. Check Progress
        AppShortcut(
            intent: CheckProgressIntent(),
            phrases: [
                "Cómo voy hoy en \(.applicationName)",
                "Mi progreso en \(.applicationName)",
                "Cuántas rutinas me faltan en \(.applicationName)",
                "Check my progress in \(.applicationName)",
                "How am I doing in \(.applicationName)",
            ],
            shortTitle: "Mi Progreso",
            systemImageName: "chart.bar.fill"
        )

        // 4. Check Medication
        AppShortcut(
            intent: CheckMedicationIntent(),
            phrases: [
                "Ya tomé mi medicamento en \(.applicationName)",
                "Mis medicamentos en \(.applicationName)",
                "Qué medicinas me faltan en \(.applicationName)",
                "Check my medication in \(.applicationName)",
                "Did I take my medicine in \(.applicationName)",
            ],
            shortTitle: "Mis Medicamentos",
            systemImageName: "pills.fill"
        )

        // 5. Next Routine
        AppShortcut(
            intent: NextRoutineIntent(),
            phrases: [
                "Cuál es mi siguiente rutina en \(.applicationName)",
                "Qué sigue en \(.applicationName)",
                "Mi próxima rutina en \(.applicationName)",
                "What's my next routine in \(.applicationName)",
                "What's next in \(.applicationName)",
            ],
            shortTitle: "Siguiente Rutina",
            systemImageName: "arrow.right.circle.fill"
        )

        // 6. Quick SOS
        AppShortcut(
            intent: QuickSOSIntent(),
            phrases: [
                "Emergencia en \(.applicationName)",
                "SOS en \(.applicationName)",
                "Necesito ayuda en \(.applicationName)",
                "Emergency in \(.applicationName)",
                "I need help in \(.applicationName)",
            ],
            shortTitle: "Emergencia SOS",
            systemImageName: "sos"
        )
    }
}
