import AppIntents
import NeuroNavKit

struct NextRoutineIntent: AppIntent {
    static var title: LocalizedStringResource = "¿Cuál es mi siguiente rutina?"
    static var description = IntentDescription("Te dice cuál es tu siguiente rutina programada y a qué hora.")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)

        guard let title = defaults?.string(forKey: "nextRoutineTitle"),
              !title.isEmpty else {
            return .result(dialog: "No tienes más rutinas programadas por hoy. \u{1F44D}")
        }

        let category = defaults?.string(forKey: "nextRoutineCategory") ?? ""
        let steps = defaults?.integer(forKey: "nextRoutineSteps") ?? 0
        let timeString = defaults?.string(forKey: "nextRoutineTime") ?? ""

        var response = "Tu siguiente rutina es: \(title)"

        if !timeString.isEmpty {
            response += " a las \(timeString)"
        }

        if !category.isEmpty {
            response += " (categoría: \(category))"
        }

        if steps > 0 {
            response += ". Tiene \(steps) pasos."
        } else {
            response += "."
        }

        return .result(dialog: "\(response)")
    }
}
