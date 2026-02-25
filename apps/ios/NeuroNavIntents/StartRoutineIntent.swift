import AppIntents

struct StartRoutineIntent: AppIntent {
    static var title: LocalizedStringResource = "Iniciar Rutina"
    static var description = IntentDescription("Inicia una de tus rutinas asignadas.")
    static var openAppWhenRun = true

    @Parameter(title: "Nombre de la rutina")
    var routineName: String?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Deep link into the app to start the routine
        // The app will handle finding and starting the routine by name
        if let name = routineName {
            return .result(dialog: "Abriendo la rutina '\(name)'...")
        } else {
            return .result(dialog: "Abriendo tus rutinas...")
        }
    }
}
