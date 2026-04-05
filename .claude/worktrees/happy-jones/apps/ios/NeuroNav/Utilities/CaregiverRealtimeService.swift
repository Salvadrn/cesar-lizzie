import Foundation
import UserNotifications
import Supabase
import NeuroNavKit

// MARK: - Caregiver Realtime Notification Service
// Listens for Supabase Realtime changes on patient tables and delivers
// local notifications to the caregiver device.

@Observable
final class CaregiverRealtimeService {
    static let shared = CaregiverRealtimeService()

    // MARK: - Public State

    var isConnected = false
    var patientName: String = ""
    var patientId: String = ""

    // MARK: - Notification Preferences (UserDefaults-backed)

    var notifyRoutines: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.notifyRoutines) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.notifyRoutines) }
    }

    var notifyMedications: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.notifyMedications) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.notifyMedications) }
    }

    /// Emergencies are always enabled; setter is a no-op.
    var notifyEmergencies: Bool {
        get { true }
        set { /* always on */ }
    }

    var notifyZones: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.notifyZones) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.notifyZones) }
    }

    // MARK: - Private

    private let supabase = SupabaseManager.shared.client

    private var routineChannel: RealtimeChannelV2?
    private var medicationChannel: RealtimeChannelV2?
    private var alertChannel: RealtimeChannelV2?

    private var routineTask: Task<Void, Never>?
    private var medicationTask: Task<Void, Never>?
    private var alertTask: Task<Void, Never>?

    private enum Keys {
        static let notifyRoutines    = "caregiver_notify_routines"
        static let notifyMedications = "caregiver_notify_medications"
        static let notifyEmergencies = "caregiver_notify_emergencies"
        static let notifyZones       = "caregiver_notify_zones"
    }

    // MARK: - Init

    init() {
        // Register defaults so first launch has sensible values
        UserDefaults.standard.register(defaults: [
            Keys.notifyRoutines: true,
            Keys.notifyMedications: true,
            Keys.notifyEmergencies: true,
            Keys.notifyZones: true
        ])
    }

    // MARK: - Connect

    /// Subscribes to all relevant Realtime channels for the currently-selected patient.
    /// Call this after setting `patientId` and `patientName`.
    func connect() async {
        guard !patientId.isEmpty else { return }
        await disconnect()

        await subscribeToRoutineExecutions()
        await subscribeToMedicationLogs()
        await subscribeToAlerts()

        isConnected = true
    }

    // MARK: - Disconnect

    func disconnect() async {
        routineTask?.cancel()
        medicationTask?.cancel()
        alertTask?.cancel()
        routineTask = nil
        medicationTask = nil
        alertTask = nil

        await routineChannel?.unsubscribe()
        await medicationChannel?.unsubscribe()
        await alertChannel?.unsubscribe()
        routineChannel = nil
        medicationChannel = nil
        alertChannel = nil

        isConnected = false
    }

    // MARK: - Routine Executions

    private func subscribeToRoutineExecutions() async {
        let channel = supabase.realtimeV2.channel("caregiver-routines-\(patientId)")
        routineChannel = channel

        let insertions = channel.postgresChange(
            InsertAction.self,
            table: "routine_executions"
        )
        let updates = channel.postgresChange(
            UpdateAction.self,
            table: "routine_executions"
        )

        await channel.subscribe()

        // Handle new executions (routine started / completed in one go)
        routineTask = Task { [weak self] in
            guard let self else { return }

            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    for await insertion in insertions {
                        guard !Task.isCancelled else { return }
                        await self.handleRoutineChange(record: insertion.record)
                    }
                }
                group.addTask {
                    for await update in updates {
                        guard !Task.isCancelled else { return }
                        await self.handleRoutineChange(record: update.record)
                    }
                }
            }
        }
    }

    private func handleRoutineChange(record: [String: AnyJSON]) async {
        guard notifyRoutines else { return }

        let status = record["status"]?.stringValue
        let routineName = record["routine_name"]?.stringValue ?? "rutina"
        let userId = record["user_id"]?.stringValue

        // Only notify for the patient we're monitoring
        if let userId, userId != patientId { return }

        let (title, body): (String, String)

        switch status {
        case "completed":
            title = "Rutina completada"
            body = "\u{2705} \(patientName) complet\u{00f3} su rutina '\(routineName)'"
        case "abandoned", "cancelled":
            title = "Rutina abandonada"
            body = "\u{26a0}\u{fe0f} \(patientName) abandon\u{00f3} su rutina"
        default:
            return
        }

        await sendLocalNotification(
            id: "caregiver-routine-\(UUID().uuidString)",
            title: title,
            body: body,
            category: "CAREGIVER_ROUTINE",
            interruptionLevel: .timeSensitive
        )
    }

    // MARK: - Medication Logs

    private func subscribeToMedicationLogs() async {
        let channel = supabase.realtimeV2.channel("caregiver-medications-\(patientId)")
        medicationChannel = channel

        let insertions = channel.postgresChange(
            InsertAction.self,
            table: "medication_logs"
        )

        await channel.subscribe()

        medicationTask = Task { [weak self] in
            guard let self else { return }
            for await insertion in insertions {
                guard !Task.isCancelled else { return }
                await self.handleMedicationLog(record: insertion.record)
            }
        }
    }

    private func handleMedicationLog(record: [String: AnyJSON]) async {
        guard notifyMedications else { return }

        let userId = record["user_id"]?.stringValue
        if let userId, userId != patientId { return }

        let medName = record["medication_name"]?.stringValue ?? "medicamento"

        await sendLocalNotification(
            id: "caregiver-med-\(UUID().uuidString)",
            title: "Medicamento tomado",
            body: "\u{1f48a} \(patientName) tom\u{00f3} su medicamento \(medName)",
            category: "CAREGIVER_MEDICATION",
            interruptionLevel: .active
        )
    }

    // MARK: - Alerts (Emergency + Zone)

    private func subscribeToAlerts() async {
        let channel = supabase.realtimeV2.channel("caregiver-alerts-\(patientId)")
        alertChannel = channel

        let insertions = channel.postgresChange(
            InsertAction.self,
            table: "alerts"
        )

        await channel.subscribe()

        alertTask = Task { [weak self] in
            guard let self else { return }
            for await insertion in insertions {
                guard !Task.isCancelled else { return }
                await self.handleAlert(record: insertion.record)
            }
        }
    }

    private func handleAlert(record: [String: AnyJSON]) async {
        let alertType = record["alert_type"]?.stringValue ?? ""
        let userId = record["user_id"]?.stringValue

        if let userId, userId != patientId { return }

        switch alertType {
        case "emergency":
            // Emergencies always notify
            await sendLocalNotification(
                id: "caregiver-emergency-\(UUID().uuidString)",
                title: "EMERGENCIA",
                body: "\u{1f198} \(patientName) activ\u{00f3} emergencia",
                category: "CAREGIVER_EMERGENCY",
                interruptionLevel: .critical,
                sound: .defaultCriticalSound(withAudioVolume: 1.0)
            )

        case "zone_exit":
            guard notifyZones else { return }
            await sendLocalNotification(
                id: "caregiver-zone-\(UUID().uuidString)",
                title: "Alerta de zona",
                body: "\u{1f4cd} \(patientName) sali\u{00f3} de zona segura",
                category: "CAREGIVER_ZONE",
                interruptionLevel: .critical,
                sound: .defaultCriticalSound(withAudioVolume: 1.0)
            )

        case "zone_enter":
            guard notifyZones else { return }
            await sendLocalNotification(
                id: "caregiver-zone-\(UUID().uuidString)",
                title: "Zona segura",
                body: "\u{1f4cd} \(patientName) entr\u{00f3} a zona segura",
                category: "CAREGIVER_ZONE",
                interruptionLevel: .timeSensitive
            )

        default:
            break
        }
    }

    // MARK: - Local Notification Helper

    private func sendLocalNotification(
        id: String,
        title: String,
        body: String,
        category: String,
        interruptionLevel: UNNotificationInterruptionLevel = .active,
        sound: UNNotificationSound = .default
    ) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound
        content.categoryIdentifier = category
        content.interruptionLevel = interruptionLevel
        content.userInfo = [
            "type": "caregiver_realtime",
            "patientId": patientId,
            "patientName": patientName
        ]

        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: nil // deliver immediately
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("CaregiverRealtimeService: failed to deliver notification: \(error)")
        }
    }
}

// MARK: - AnyJSON String Helper

private extension AnyJSON {
    /// Attempts to extract a plain String from the AnyJSON value.
    var stringValue: String? {
        switch self {
        case .string(let s):
            return s
        default:
            // Fallback: encode to JSON and strip quotes
            if let data = try? JSONEncoder().encode(self),
               let raw = String(data: data, encoding: .utf8) {
                let trimmed = raw.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                return trimmed == "null" ? nil : trimmed
            }
            return nil
        }
    }
}
