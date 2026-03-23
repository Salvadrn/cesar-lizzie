import AppIntents
import NeuroNavKit

// Mirrors SharedMedication from widget target — separate copy needed per extension
private struct IntentMedication: Codable {
    let id: String
    let name: String
    let dosage: String
    let hour: Int
    let minute: Int
    let takenToday: Bool
    let reminderOffsets: [Int]
}

struct CheckMedicationIntent: AppIntent {
    static var title: LocalizedStringResource = "¿Ya tomé mi medicamento?"
    static var description = IntentDescription("Revisa cuáles medicamentos has tomado y cuáles te faltan hoy.")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)

        guard let data = defaults?.data(forKey: "medications"),
              let medications = try? JSONDecoder().decode([IntentMedication].self, from: data),
              !medications.isEmpty else {
            return .result(dialog: "No tienes medicamentos registrados.")
        }

        let taken = medications.filter { $0.takenToday }
        let pending = medications.filter { !$0.takenToday }

        if pending.isEmpty {
            return .result(
                dialog: "Ya tomaste todos tus medicamentos hoy (\(taken.count) de \(medications.count)). \u{1F389}"
            )
        }

        let pendingNames = pending.map { med in
            let time = String(format: "%d:%02d", med.hour, med.minute)
            return "\(med.name) \(med.dosage) (\(time))"
        }.joined(separator: ", ")

        if taken.isEmpty {
            return .result(
                dialog: "Aun no has tomado ninguno de tus \(medications.count) medicamentos. Te faltan: \(pendingNames)."
            )
        }

        return .result(
            dialog: "Has tomado \(taken.count) de \(medications.count) medicamentos. Te faltan: \(pendingNames)."
        )
    }
}
