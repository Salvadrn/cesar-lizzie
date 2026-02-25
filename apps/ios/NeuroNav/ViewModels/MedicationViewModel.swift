import Foundation
import NeuroNavKit
import WidgetKit

@Observable
final class MedicationViewModel {
    var medications: [MedicationItem] = []
    var isLoading = false
    var errorMessage: String?

    private let api = APIClient.shared

    struct MedicationItem: Identifiable {
        let id: String
        var name: String
        var dosage: String
        var hour: Int
        var minute: Int
        var takenToday: Bool
        var reminderOffsets: [Int]

        var scheduledTime: String {
            String(format: "%02d:%02d", hour, minute)
        }

        var offsetsLabel: String? {
            let filtered = reminderOffsets.filter { $0 > 0 }.sorted()
            guard !filtered.isEmpty else { return nil }
            return filtered.map { "\($0) min" }.joined(separator: ", ") + " antes"
        }
    }

    func load() async {
        isLoading = true

        if AuthService.shared.isGuestMode {
            medications = SampleData.medications
            isLoading = false
            return
        }

        do {
            let rows = try await api.fetchMedications()
            medications = rows.map { row in
                MedicationItem(
                    id: row.id,
                    name: row.name,
                    dosage: row.dosage,
                    hour: row.hour,
                    minute: row.minute,
                    takenToday: row.takenToday,
                    reminderOffsets: row.reminderOffsets ?? [5]
                )
            }
            syncToWidget()
            // Reprogramar notificaciones locales cada vez que carga (funciona sin internet)
            NotificationService.shared.rescheduleAllMedications(medications)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addMedication(name: String, dosage: String, hour: Int, minute: Int, offsets: [Int]) async {
        do {
            try await api.addMedication(name: name, dosage: dosage, hour: hour, minute: minute, reminderOffsets: offsets)
            await load()

            // Schedule notifications with offsets — find by name+hour+minute since order may vary
            if let med = medications.first(where: { $0.name == name && $0.hour == hour && $0.minute == minute }) {
                NotificationService.shared.scheduleMedicationReminder(
                    medicationId: med.id,
                    name: name,
                    dosage: dosage,
                    hour: hour,
                    minute: minute,
                    offsets: med.reminderOffsets
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markAsTaken(id: String) async {
        do {
            try await api.markMedicationTaken(id: id)
            if let idx = medications.firstIndex(where: { $0.id == id }) {
                medications[idx].takenToday = true
            }
            // Cancelar followup y limpiar notificaciones entregadas
            NotificationService.shared.medicationWasTaken(medicationId: id)
            syncToWidget()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteMedication(id: String) async {
        do {
            try await api.deleteMedication(id: id)
            NotificationService.shared.cancelMedicationReminder(medicationId: id)
            medications.removeAll { $0.id == id }
            syncToWidget()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func syncToWidget() {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
        let shared = medications.map { med in
            SharedMedicationData(
                id: med.id,
                name: med.name,
                dosage: med.dosage,
                hour: med.hour,
                minute: med.minute,
                takenToday: med.takenToday,
                reminderOffsets: med.reminderOffsets
            )
        }
        if let data = try? JSONEncoder().encode(shared) {
            defaults?.set(data, forKey: "medications")
        }
        WidgetCenter.shared.reloadTimelines(ofKind: "MedicationWidget")
    }
}

struct SharedMedicationData: Codable {
    let id: String
    let name: String
    let dosage: String
    let hour: Int
    let minute: Int
    let takenToday: Bool
    let reminderOffsets: [Int]
}
