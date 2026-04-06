import Foundation
import UserNotifications

/// Enhanced notification service with intelligent scheduling based on user patterns
@Observable
public final class SmartNotificationService {
    public static let shared = SmartNotificationService()

    public init() {}

    // MARK: - Mood Check-In Reminders

    /// Schedule daily mood check-in reminder
    public func scheduleMoodReminder(hour: Int = 20, minute: Int = 0) {
        let content = UNMutableNotificationContent()
        content.title = "¿Cómo te sientes hoy?"
        content.body = "Tómate un momento para registrar tu estado de ánimo"
        content.sound = .default
        content.categoryIdentifier = "MOOD_REMINDER"
        content.interruptionLevel = .timeSensitive

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "mood_daily_reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Streak Reminders

    /// Remind user to keep their streak alive if they haven't been active today
    public func scheduleStreakReminder(currentStreak: Int) {
        guard currentStreak > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Tu racha de \(currentStreak) días"
        content.body = currentStreak >= 7
            ? "No pierdas tu racha increíble. ¡Abre la app!"
            : "Completa una actividad para mantener tu racha"
        content.sound = .default
        content.categoryIdentifier = "STREAK_REMINDER"
        content.interruptionLevel = .timeSensitive

        var dateComponents = DateComponents()
        dateComponents.hour = 18
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "streak_reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Achievement Notifications

    /// Send a local notification when an achievement is unlocked
    public func sendAchievementNotification(title: String) {
        let content = UNMutableNotificationContent()
        content.title = "Logro desbloqueado!"
        content.body = title
        content.sound = UNNotificationSound(named: UNNotificationSoundName("achievement.wav"))
        content.categoryIdentifier = "ACHIEVEMENT"
        content.interruptionLevel = .active

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "achievement_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Routine Pattern Reminders

    /// Schedule smart reminder based on user's typical routine time
    public func scheduleSmartRoutineReminder(
        routineTitle: String,
        typicalHour: Int,
        typicalMinute: Int
    ) {
        let content = UNMutableNotificationContent()
        content.title = "Hora de: \(routineTitle)"
        content.body = "Normalmente haces esta rutina a esta hora"
        content.sound = .default
        content.categoryIdentifier = "SMART_ROUTINE"
        content.interruptionLevel = .timeSensitive

        var dateComponents = DateComponents()
        dateComponents.hour = typicalHour
        dateComponents.minute = typicalMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "smart_routine_\(routineTitle.hashValue)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Caregiver Alerts

    /// Alert caregiver about patient inactivity
    public func sendCaregiverInactivityAlert(patientName: String, hoursSinceActive: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Alerta: \(patientName)"
        content.body = "\(patientName) no ha tenido actividad en \(hoursSinceActive) horas"
        content.sound = .default
        content.categoryIdentifier = "CAREGIVER_ALERT"
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "caregiver_inactivity_\(patientName.hashValue)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// Alert caregiver about mood decline pattern
    public func sendMoodDeclineAlert(patientName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Atención: \(patientName)"
        content.body = "Se detectó una tendencia de bajo ánimo en los últimos días"
        content.sound = .default
        content.categoryIdentifier = "CAREGIVER_MOOD"
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "caregiver_mood_\(patientName.hashValue)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Cleanup

    /// Remove all scheduled smart notifications
    public func removeAllSmartNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [
            "mood_daily_reminder",
            "streak_reminder"
        ])
    }
}
