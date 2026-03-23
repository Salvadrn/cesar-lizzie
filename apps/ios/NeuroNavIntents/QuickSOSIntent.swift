import AppIntents
import NeuroNavKit

struct QuickSOSIntent: AppIntent {
    static var title: LocalizedStringResource = "Emergencia SOS"
    static var description = IntentDescription("Abre la pantalla de emergencia para pedir ayuda rápidamente.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
        let contactName = defaults?.string(forKey: "emergencyContactName") ?? "tu contacto de emergencia"

        return .result(
            dialog: "Abriendo pantalla de emergencia. Contactando a \(contactName)..."
        )
    }
}
