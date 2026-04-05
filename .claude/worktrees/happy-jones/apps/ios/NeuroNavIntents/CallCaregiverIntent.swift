import AppIntents
import NeuroNavKit

struct CallCaregiverIntent: AppIntent {
    static var title: LocalizedStringResource = "Llamar a mi Cuidador"
    static var description = IntentDescription("Llama a tu contacto de emergencia principal.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
        let contactName = defaults?.string(forKey: "emergencyContactName") ?? "tu cuidador"

        return .result(dialog: "Conectando con \(contactName)...")
    }
}
