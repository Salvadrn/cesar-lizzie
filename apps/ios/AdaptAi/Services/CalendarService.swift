import Foundation
import EventKit
import SwiftUI

/// Manages iOS Calendar integration via EventKit.
/// Allows syncing medical appointments with the user's calendar app.
@Observable
final class CalendarService {
    static let shared = CalendarService()

    private let store = EKEventStore()

    var isAuthorized = false

    private init() {
        Task { await refreshAuthStatus() }
    }

    // MARK: - Authorization

    func refreshAuthStatus() async {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(iOS 17.0, *) {
            isAuthorized = (status == .fullAccess || status == .writeOnly)
        } else {
            isAuthorized = (status == .authorized)
        }
    }

    func requestAccess() async -> Bool {
        do {
            if #available(iOS 17.0, *) {
                let granted = try await store.requestWriteOnlyAccessToEvents()
                isAuthorized = granted
                return granted
            } else {
                let granted = try await store.requestAccess(to: .event)
                isAuthorized = granted
                return granted
            }
        } catch {
            print("Calendar access error: \(error)")
            return false
        }
    }

    // MARK: - Events

    /// Adds a medical appointment to the user's default calendar.
    /// Returns the event identifier for later updates/removal.
    @discardableResult
    func addAppointment(
        title: String,
        doctorName: String,
        date: Date,
        durationMinutes: Int = 60,
        location: String? = nil,
        notes: String? = nil,
        reminderMinutesBefore: Int = 60
    ) async throws -> String {
        if !isAuthorized {
            let granted = await requestAccess()
            guard granted else {
                throw CalendarError.accessDenied
            }
        }

        let event = EKEvent(eventStore: store)
        event.title = "Cita: \(doctorName) — \(title)"
        event.startDate = date
        event.endDate = date.addingTimeInterval(TimeInterval(durationMinutes * 60))
        event.location = location
        event.notes = notes
        event.calendar = store.defaultCalendarForNewEvents

        // Add reminder
        let alarm = EKAlarm(relativeOffset: TimeInterval(-reminderMinutesBefore * 60))
        event.addAlarm(alarm)

        try store.save(event, span: .thisEvent)
        return event.eventIdentifier
    }

    /// Removes an event from the calendar by its identifier.
    func removeAppointment(eventId: String) throws {
        guard let event = store.event(withIdentifier: eventId) else {
            return
        }
        try store.remove(event, span: .thisEvent)
    }

    /// Updates an existing calendar event (or adds it if not found).
    @discardableResult
    func updateAppointment(
        eventId: String?,
        title: String,
        doctorName: String,
        date: Date,
        durationMinutes: Int = 60,
        location: String? = nil,
        notes: String? = nil
    ) async throws -> String {
        if let id = eventId, let existing = store.event(withIdentifier: id) {
            existing.title = "Cita: \(doctorName) — \(title)"
            existing.startDate = date
            existing.endDate = date.addingTimeInterval(TimeInterval(durationMinutes * 60))
            existing.location = location
            existing.notes = notes
            try store.save(existing, span: .thisEvent)
            return id
        } else {
            return try await addAppointment(
                title: title,
                doctorName: doctorName,
                date: date,
                durationMinutes: durationMinutes,
                location: location,
                notes: notes
            )
        }
    }
}

enum CalendarError: Error, LocalizedError {
    case accessDenied
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .accessDenied: return "No tienes acceso al calendario. Actívalo en Ajustes."
        case .saveFailed: return "No se pudo guardar el evento."
        }
    }
}
