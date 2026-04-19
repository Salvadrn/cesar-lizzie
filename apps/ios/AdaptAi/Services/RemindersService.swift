import Foundation
import EventKit
import SwiftUI

/// Manages iOS Reminders app integration via EventKit.
/// Syncs medications, routines, and appointments as reminders the user can see in the native Reminders app.
@Observable
final class RemindersService {
    static let shared = RemindersService()

    private let store = EKEventStore()

    var isAuthorized = false

    private init() {
        Task { await refreshAuthStatus() }
    }

    // MARK: - Authorization

    func refreshAuthStatus() async {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        if #available(iOS 17.0, *) {
            isAuthorized = (status == .fullAccess)
        } else {
            isAuthorized = (status == .authorized)
        }
    }

    func requestAccess() async -> Bool {
        do {
            if #available(iOS 17.0, *) {
                let granted = try await store.requestFullAccessToReminders()
                isAuthorized = granted
                return granted
            } else {
                let granted = try await store.requestAccess(to: .reminder)
                isAuthorized = granted
                return granted
            }
        } catch {
            print("Reminders access error: \(error)")
            return false
        }
    }

    // MARK: - Calendar Management

    /// Finds or creates a dedicated "AdaptAi" reminders list so user sees everything grouped.
    private func adaptAiList() -> EKCalendar? {
        if let existing = store.calendars(for: .reminder).first(where: { $0.title == "AdaptAi" }) {
            return existing
        }

        let newList = EKCalendar(for: .reminder, eventStore: store)
        newList.title = "AdaptAi"
        newList.cgColor = UIColor(red: 0.25, green: 0.47, blue: 0.85, alpha: 1.0).cgColor

        guard let source = store.defaultCalendarForNewReminders()?.source
            ?? store.sources.first(where: { $0.sourceType == .local })
            ?? store.sources.first else {
            return nil
        }
        newList.source = source

        do {
            try store.saveCalendar(newList, commit: true)
            return newList
        } catch {
            print("Could not create AdaptAi reminders list: \(error)")
            return store.defaultCalendarForNewReminders()
        }
    }

    // MARK: - Medication Reminders

    /// Creates a repeating daily reminder for a medication.
    /// Returns the EKReminder identifier for later updates/removal.
    @discardableResult
    func addMedicationReminder(
        medicationId: String,
        name: String,
        dosage: String,
        hour: Int,
        minute: Int,
        notes: String? = nil
    ) async throws -> String {
        if !isAuthorized {
            guard await requestAccess() else { throw RemindersError.accessDenied }
        }

        let reminder = EKReminder(eventStore: store)
        reminder.title = "💊 \(name) (\(dosage))"
        reminder.notes = notes ?? "Tomar \(dosage) de \(name)"
        reminder.calendar = adaptAiList()

        // Daily alarm at specified time
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute

        if let alarmDate = Calendar.current.date(from: components) {
            reminder.addAlarm(EKAlarm(absoluteDate: alarmDate))
        }

        // Repeat daily forever
        reminder.recurrenceRules = [
            EKRecurrenceRule(
                recurrenceWith: .daily,
                interval: 1,
                end: nil
            ),
        ]

        // Link back to our medication id via URL (scheme: adaptai://medication/UUID)
        if let url = URL(string: "adaptai://medication/\(medicationId)") {
            reminder.url = url
        }

        try store.save(reminder, commit: true)
        return reminder.calendarItemIdentifier
    }

    // MARK: - Appointment Reminders

    @discardableResult
    func addAppointmentReminder(
        appointmentId: String,
        doctorName: String,
        specialty: String?,
        date: Date,
        location: String?,
        reminderMinutesBefore: Int = 60
    ) async throws -> String {
        if !isAuthorized {
            guard await requestAccess() else { throw RemindersError.accessDenied }
        }

        let reminder = EKReminder(eventStore: store)
        let title = specialty.map { "🏥 Cita \($0) — \(doctorName)" } ?? "🏥 Cita con \(doctorName)"
        reminder.title = title
        reminder.notes = location.map { "Ubicación: \($0)" }
        reminder.calendar = adaptAiList()

        reminder.dueDateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )

        let alarmDate = date.addingTimeInterval(TimeInterval(-reminderMinutesBefore * 60))
        reminder.addAlarm(EKAlarm(absoluteDate: alarmDate))

        if let url = URL(string: "adaptai://appointment/\(appointmentId)") {
            reminder.url = url
        }

        try store.save(reminder, commit: true)
        return reminder.calendarItemIdentifier
    }

    // MARK: - Routine Reminders

    @discardableResult
    func addRoutineReminder(
        routineId: String,
        title: String,
        hour: Int,
        minute: Int,
        daysOfWeek: [Int] = []  // 1 = Sunday ... 7 = Saturday. Empty = daily
    ) async throws -> String {
        if !isAuthorized {
            guard await requestAccess() else { throw RemindersError.accessDenied }
        }

        let reminder = EKReminder(eventStore: store)
        reminder.title = "📋 \(title)"
        reminder.calendar = adaptAiList()

        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute

        if let alarmDate = Calendar.current.date(from: components) {
            reminder.addAlarm(EKAlarm(absoluteDate: alarmDate))
        }

        if daysOfWeek.isEmpty {
            // Daily
            reminder.recurrenceRules = [
                EKRecurrenceRule(recurrenceWith: .daily, interval: 1, end: nil),
            ]
        } else {
            // Specific days of the week
            let weekDays = daysOfWeek.compactMap { EKWeekday(rawValue: $0) }
                .map { EKRecurrenceDayOfWeek($0) }
            reminder.recurrenceRules = [
                EKRecurrenceRule(
                    recurrenceWith: .weekly,
                    interval: 1,
                    daysOfTheWeek: weekDays,
                    daysOfTheMonth: nil,
                    monthsOfTheYear: nil,
                    weeksOfTheYear: nil,
                    daysOfTheYear: nil,
                    setPositions: nil,
                    end: nil
                ),
            ]
        }

        if let url = URL(string: "adaptai://routine/\(routineId)") {
            reminder.url = url
        }

        try store.save(reminder, commit: true)
        return reminder.calendarItemIdentifier
    }

    // MARK: - Remove / Complete

    func removeReminder(identifier: String) throws {
        guard let reminder = store.calendarItem(withIdentifier: identifier) as? EKReminder else {
            return
        }
        try store.remove(reminder, commit: true)
    }

    func markComplete(identifier: String) throws {
        guard let reminder = store.calendarItem(withIdentifier: identifier) as? EKReminder else {
            return
        }
        reminder.isCompleted = true
        try store.save(reminder, commit: true)
    }

    // MARK: - Bulk sync helpers

    /// Removes all AdaptAi reminders (e.g. when user logs out or disables sync).
    func clearAllAdaptAiReminders() async throws {
        guard let list = adaptAiList() else { return }
        let predicate = store.predicateForReminders(in: [list])

        let reminders: [EKReminder] = await withCheckedContinuation { continuation in
            store.fetchReminders(matching: predicate) { result in
                continuation.resume(returning: result ?? [])
            }
        }

        for reminder in reminders {
            try store.remove(reminder, commit: false)
        }
        try store.commit()
    }
}

enum RemindersError: Error, LocalizedError {
    case accessDenied
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "No tienes acceso a los Recordatorios. Actívalo en Ajustes → Privacidad → Recordatorios."
        case .saveFailed:
            return "No se pudo guardar el recordatorio."
        }
    }
}
