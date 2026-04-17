import AppIntents

struct CallCaregiverIntent: AppIntent {
    static var title: LocalizedStringResource = "Llamar a mi Cuidador"
    static var description = IntentDescription("Llama a tu contacto de emergencia principal.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // The app will handle fetching the primary contact and initiating the call
        return .result(dialog: "Conectando con tu cuidador...")
    }
}
