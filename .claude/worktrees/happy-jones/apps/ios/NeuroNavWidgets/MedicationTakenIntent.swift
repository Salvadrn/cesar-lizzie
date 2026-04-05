import AppIntents
import WidgetKit
import NeuroNavKit

/// Interactive widget intent: mark a medication as taken directly from the widget.
struct MedicationTakenIntent: AppIntent {
    static var title: LocalizedStringResource = "Marcar medicamento como tomado"
    static var description = IntentDescription("Marca un medicamento como tomado desde el widget.")

    @Parameter(title: "ID del medicamento")
    var medicationId: String

    @Parameter(title: "Nombre del medicamento")
    var medicationName: String

    init() {}

    init(medicationId: String, medicationName: String) {
        self.medicationId = medicationId
        self.medicationName = medicationName
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)

        // Update the medication's takenToday status in shared UserDefaults
        if let data = defaults?.data(forKey: "medications"),
           var decoded = try? JSONDecoder().decode([MutableSharedMedication].self, from: data) {
            if let index = decoded.firstIndex(where: { $0.id == medicationId }) {
                decoded[index].takenToday = true
                if let encoded = try? JSONEncoder().encode(decoded) {
                    defaults?.set(encoded, forKey: "medications")
                }
            }
        }

        // Reload widget timeline
        WidgetCenter.shared.reloadTimelines(ofKind: "MedicationWidget")

        return .result(dialog: "✅ \(medicationName) marcado como tomado")
    }
}

// Mutable version for encoding back
struct MutableSharedMedication: Codable {
    let id: String
    let name: String
    let dosage: String
    let hour: Int
    let minute: Int
    var takenToday: Bool
    let reminderOffsets: [Int]
}
