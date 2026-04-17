import Foundation
import UserNotifications
import AdaptAiKit

@Observable
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    var isAuthorized = false
    var hasCriticalAlerts = false

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() async {
        do {
            // Solicitar permisos incluyendo critical alerts (suenan en silencio)
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound, .criticalAlert, .providesAppNotificationSettings])
            isAuthorized = granted
            hasCriticalAlerts = granted
            registerCategories()
        } catch {
            print("NotificationService: critical auth error: \(error)")
            // Fallback: intentar sin critical alerts
            do {
                let granted = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .badge, .sound])
                isAuthorized = granted
                hasCriticalAlerts = false
                registerCategories()
            } catch {
                print("NotificationService: fallback auth error: \(error)")
            }
        }
    }

    // MARK: - Routine Reminders

    func scheduleRoutineReminder(
        routineId: String,
        title: String,
        body: String,
        at date: Date
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["routineId": routineId, "type": "routine"]
        content.categoryIdentifier = "ROUTINE_REMINDER"
        content.interruptionLevel = .timeSensitive

        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "routine-\(routineId)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelRoutineReminder(routineId: String) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["routine-\(routineId)"])
    }

    // MARK: - Medication Reminders (CRITICAL — suena en silencio)

    /// Programa recordatorios de medicamento con nivel CRÍTICO.
    /// Suenan INCLUSO en modo silencio/No Molestar porque la toma
    /// de medicamentos puede ser un riesgo de salud si se omite.
    func scheduleMedicationReminder(
        medicationId: String,
        name: String,
        dosage: String,
        hour: Int,
        minute: Int,
        offsets: [Int] = [0]
    ) {
        cancelMedicationReminder(medicationId: medicationId)

        let allOffsets = offsets.contains(0) ? offsets : offsets + [0]

        for offset in allOffsets {
            let content = UNMutableNotificationContent()
            let isMainReminder = (offset == 0)

            if isMainReminder {
                content.title = "⚠️ Hora de tu medicamento"
                content.body = "\(name) — \(dosage)\nEs importante que lo tomes ahora."
            } else {
                content.title = "🔔 En \(offset) min: \(name)"
                content.body = "\(dosage) — Prepárate para tomarlo"
            }

            // CRITICAL: suena aunque esté en silencio/Do Not Disturb
            if isMainReminder {
                content.sound = .defaultCriticalSound(withAudioVolume: 1.0)
                content.interruptionLevel = .critical
            } else {
                content.sound = .defaultCritical
                content.interruptionLevel = .timeSensitive
            }

            content.userInfo = [
                "medicationId": medicationId,
                "medicationName": name,
                "medicationDosage": dosage,
                "type": "medication",
                "isMainReminder": isMainReminder
            ]
            content.categoryIdentifier = "MEDICATION_REMINDER"
            content.badge = NSNumber(value: 1)

            // Calcular la hora menos el offset
            var totalMinutes = hour * 60 + minute - offset
            if totalMinutes < 0 { totalMinutes += 24 * 60 }
            var components = DateComponents()
            components.hour = totalMinutes / 60
            components.minute = totalMinutes % 60
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

            let request = UNNotificationRequest(
                identifier: "medication-\(medicationId)-\(offset)min",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request)
        }

        // Re-notificación 10 min después si no se marca como tomado
        scheduleFollowUp(medicationId: medicationId, name: name, dosage: dosage, hour: hour, minute: minute)
    }

    /// Re-notificación 10 minutos después si el medicamento no se ha marcado como tomado.
    private func scheduleFollowUp(medicationId: String, name: String, dosage: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🚨 ¿Ya tomaste tu medicamento?"
        content.body = "\(name) — \(dosage)\nHace 10 min era la hora. Por favor tómalo."
        content.sound = .defaultCriticalSound(withAudioVolume: 1.0)
        content.interruptionLevel = .critical
        content.userInfo = [
            "medicationId": medicationId,
            "medicationName": name,
            "type": "medication_followup"
        ]
        content.categoryIdentifier = "MEDICATION_FOLLOWUP"

        var totalMinutes = hour * 60 + minute + 10
        if totalMinutes >= 24 * 60 { totalMinutes -= 24 * 60 }
        var components = DateComponents()
        components.hour = totalMinutes / 60
        components.minute = totalMinutes % 60
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "medication-followup-\(medicationId)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelMedicationReminder(medicationId: String) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests
                .filter {
                    $0.identifier.hasPrefix("medication-\(medicationId)") ||
                    $0.identifier == "medication-followup-\(medicationId)"
                }
                .map(\.identifier)
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    /// Cuando el usuario marca medicamento como tomado, cancelar followup y limpiar badge
    func medicationWasTaken(medicationId: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(
            withIdentifiers: ["medication-followup-\(medicationId)"]
        )
        center.removeDeliveredNotifications(
            withIdentifiers: ["medication-\(medicationId)-0min", "medication-followup-\(medicationId)"]
        )
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    // MARK: - Doctor Appointment Reminders

    /// Programa recordatorio de cita médica — un día antes y 1 hora antes.
    func scheduleDoctorAppointment(
        appointmentId: String,
        doctorName: String,
        specialty: String?,
        date: Date,
        location: String?
    ) {
        cancelDoctorAppointment(appointmentId: appointmentId)

        let locationStr = location.map { " en \($0)" } ?? ""
        let specialtyStr = specialty ?? "Médico"

        // 1 día antes
        if let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: date) {
            let content = UNMutableNotificationContent()
            content.title = "📋 Cita médica mañana"
            content.body = "\(specialtyStr): \(doctorName)\(locationStr)"
            content.sound = .default
            content.interruptionLevel = .timeSensitive
            content.userInfo = ["appointmentId": appointmentId, "type": "appointment"]
            content.categoryIdentifier = "APPOINTMENT_REMINDER"

            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dayBefore)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(
                identifier: "appointment-day-\(appointmentId)",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)
        }

        // 1 hora antes
        if let hourBefore = Calendar.current.date(byAdding: .hour, value: -1, to: date) {
            let content = UNMutableNotificationContent()
            content.title = "⏰ Cita en 1 hora"
            content.body = "\(specialtyStr): \(doctorName)\(locationStr)\nPrepárate para salir."
            content.sound = .defaultCritical
            content.interruptionLevel = .critical
            content.userInfo = ["appointmentId": appointmentId, "type": "appointment"]
            content.categoryIdentifier = "APPOINTMENT_REMINDER"

            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: hourBefore)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(
                identifier: "appointment-hour-\(appointmentId)",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)
        }
    }

    func cancelDoctorAppointment(appointmentId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [
                "appointment-day-\(appointmentId)",
                "appointment-hour-\(appointmentId)"
            ]
        )
    }

    // MARK: - Stall Alert

    func sendStallAlert(stepTitle: String) {
        let content = UNMutableNotificationContent()
        content.title = "¿Necesitas ayuda?"
        content.body = "Parece que te trabaste en: \(stepTitle)"
        content.sound = .default
        content.categoryIdentifier = "STALL_ALERT"

        let request = UNNotificationRequest(
            identifier: "stall-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Emergency Alert

    func sendEmergencyAlert(userName: String) {
        let content = UNMutableNotificationContent()
        content.title = "🆘 EMERGENCIA"
        content.body = "\(userName) activó el botón de emergencia"
        content.sound = .defaultCriticalSound(withAudioVolume: 1.0)
        content.categoryIdentifier = "EMERGENCY"
        content.interruptionLevel = .critical

        let request = UNNotificationRequest(
            identifier: "emergency-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Zone Alert

    func sendZoneAlert(zoneName: String, event: String) {
        let content = UNMutableNotificationContent()
        content.title = event == "exit" ? "⚠️ Salió de zona segura" : "📍 Entró a zona"
        content.body = "Zona: \(zoneName)"
        content.sound = .defaultCriticalSound(withAudioVolume: 1.0)
        content.categoryIdentifier = "ZONE_ALERT"
        content.interruptionLevel = .critical

        let request = UNNotificationRequest(
            identifier: "zone-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Fall Detection Alert

    func sendFallDetectionAlert() {
        let content = UNMutableNotificationContent()
        content.title = "🚨 Impacto detectado"
        content.body = "Se detectó una caída o golpe fuerte. Si no cancelas en 30s, se llamará a tu contacto de emergencia."
        content.sound = .defaultCriticalSound(withAudioVolume: 1.0)
        content.categoryIdentifier = "FALL_DETECTION"
        content.interruptionLevel = .critical

        let request = UNNotificationRequest(
            identifier: "fall-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Register Categories

    private func registerCategories() {
        let cancelFall = UNNotificationAction(identifier: "CANCEL_FALL", title: "Estoy bien", options: .foreground)
        let fallCategory = UNNotificationCategory(identifier: "FALL_DETECTION", actions: [cancelFall], intentIdentifiers: [])

        let openRoutine = UNNotificationAction(identifier: "OPEN_ROUTINE", title: "Abrir rutina", options: .foreground)
        let routineCategory = UNNotificationCategory(identifier: "ROUTINE_REMINDER", actions: [openRoutine], intentIdentifiers: [])

        // Medicamento — principal (Ya lo tomé + Snooze)
        let takeMed = UNNotificationAction(identifier: "TAKE_MED", title: "✅ Ya lo tomé", options: [])
        let snoozeMed = UNNotificationAction(identifier: "SNOOZE_MED", title: "⏰ Recordar en 5 min", options: [])
        let medCategory = UNNotificationCategory(identifier: "MEDICATION_REMINDER", actions: [takeMed, snoozeMed], intentIdentifiers: [])

        // Medicamento — seguimiento
        let takeMedFollowup = UNNotificationAction(identifier: "TAKE_MED", title: "✅ Ya lo tomé", options: [])
        let medFollowupCategory = UNNotificationCategory(identifier: "MEDICATION_FOLLOWUP", actions: [takeMedFollowup], intentIdentifiers: [])

        // Cita médica
        let confirmAppt = UNNotificationAction(identifier: "CONFIRM_APPOINTMENT", title: "✅ Confirmar", options: [])
        let apptCategory = UNNotificationCategory(identifier: "APPOINTMENT_REMINDER", actions: [confirmAppt], intentIdentifiers: [])

        UNUserNotificationCenter.current().setNotificationCategories([
            fallCategory, routineCategory, medCategory, medFollowupCategory, apptCategory
        ])
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .badge, .sound, .list]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        let actionId = response.actionIdentifier

        switch actionId {
        case "CANCEL_FALL":
            CrashDetectionService.shared.cancelCountdown()

        case "TAKE_MED":
            if let medId = userInfo["medicationId"] as? String {
                medicationWasTaken(medicationId: medId)
                NotificationCenter.default.post(
                    name: .init("medicationTaken"),
                    object: nil,
                    userInfo: ["medicationId": medId]
                )
            }

        case "SNOOZE_MED":
            if let medId = userInfo["medicationId"] as? String,
               let name = userInfo["medicationName"] as? String,
               let dosage = userInfo["medicationDosage"] as? String {
                let content = UNMutableNotificationContent()
                content.title = "⚠️ Recordatorio: \(name)"
                content.body = "\(dosage) — Tómalo ahora"
                content.sound = .defaultCriticalSound(withAudioVolume: 1.0)
                content.interruptionLevel = .critical
                content.userInfo = userInfo
                content.categoryIdentifier = "MEDICATION_REMINDER"

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5 * 60, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "medication-snooze-\(medId)",
                    content: content,
                    trigger: trigger
                )
                try? await UNUserNotificationCenter.current().add(request)
            }

        case "OPEN_ROUTINE":
            if let routineId = userInfo["routineId"] as? String {
                NotificationCenter.default.post(
                    name: .init("openRoutine"),
                    object: nil,
                    userInfo: ["routineId": routineId]
                )
            }

        case "CONFIRM_APPOINTMENT":
            if let apptId = userInfo["appointmentId"] as? String {
                NotificationCenter.default.post(
                    name: .init("appointmentConfirmed"),
                    object: nil,
                    userInfo: ["appointmentId": apptId]
                )
            }

        case UNNotificationDefaultActionIdentifier:
            if let routineId = userInfo["routineId"] as? String {
                NotificationCenter.default.post(
                    name: .init("openRoutine"),
                    object: nil,
                    userInfo: ["routineId": routineId]
                )
            } else if userInfo["type"] as? String == "appointment" {
                NotificationCenter.default.post(
                    name: .init("openAppointments"),
                    object: nil,
                    userInfo: userInfo
                )
            }

        default:
            break
        }
    }

    // MARK: - Reschedule All (on app launch)

    /// Reprograma todas las notificaciones de medicamentos al abrir la app.
    /// Esto asegura que aunque no haya internet, las locales siempre estén activas.
    func rescheduleAllMedications(_ medications: [MedicationViewModel.MedicationItem]) {
        for med in medications where !med.takenToday {
            scheduleMedicationReminder(
                medicationId: med.id,
                name: med.name,
                dosage: med.dosage,
                hour: med.hour,
                minute: med.minute,
                offsets: med.reminderOffsets
            )
        }
    }
}
