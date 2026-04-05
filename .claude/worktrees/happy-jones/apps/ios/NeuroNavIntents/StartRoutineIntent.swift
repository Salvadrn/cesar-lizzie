import AppIntents
import NeuroNavKit

struct StartRoutineIntent: AppIntent {
    static var title: LocalizedStringResource = "Iniciar Rutina"
    static var description = IntentDescription("Inicia una de tus rutinas asignadas.")
    static var openAppWhenRun = true

    @Parameter(title: "Nombre de la rutina")
    var routineName: String?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)

        if let name = routineName {
            return .result(dialog: "Abriendo la rutina '\(name)'...")
        }

        // If no name specified, suggest the next routine
        if let nextTitle = defaults?.string(forKey: "nextRoutineTitle"),
           !nextTitle.isEmpty {
            return .result(dialog: "Abriendo tu siguiente rutina: \(nextTitle)...")
        }

        return .result(dialog: "Abriendo tus rutinas...")
    }
}
