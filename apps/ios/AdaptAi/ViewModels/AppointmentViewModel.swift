import Foundation
import AdaptAiKit
import WidgetKit

@Observable
final class AppointmentViewModel {
    var appointments: [AppointmentRow] = []
    var isLoading = false
    var errorMessage: String?

    private let api = APIClient.shared

    var upcoming: [AppointmentRow] {
        appointments.filter { !$0.isPast && $0.status == AppConstants.AppointmentStatus.scheduled.rawValue }
    }

    var past: [AppointmentRow] {
        appointments.filter { $0.isPast || $0.status == AppConstants.AppointmentStatus.completed.rawValue }
    }

    var nextAppointment: AppointmentRow? {
        upcoming.first
    }

    func load() async {
        isLoading = true

        if AuthService.shared.isGuestMode {
            appointments = SampleData.appointments
            isLoading = false
            syncToWidget()
            return
        }

        do {
            appointments = try await api.fetchAppointments()
            syncToWidget()
            scheduleAllNotifications()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addAppointment(doctorName: String, specialty: String?, location: String?, notes: String?,
                        date: Date, isRecurring: Bool, recurringMonths: Int?) async {
        do {
            try await api.addAppointment(
                doctorName: doctorName,
                specialty: specialty,
                location: location,
                notes: notes,
                date: date,
                isRecurring: isRecurring,
                recurringMonths: recurringMonths
            )
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAppointment(id: String) async {
        do {
            try await api.deleteAppointment(id: id)
            NotificationService.shared.cancelDoctorAppointment(appointmentId: id)
            appointments.removeAll { $0.id == id }
            syncToWidget()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeAppointment(_ appt: AppointmentRow) async {
        do {
            try await api.completeAppointment(id: appt.id)

            // Si es recurrente, crear la siguiente cita
            if appt.isRecurring, let months = appt.recurringMonths, let currentDate = appt.date {
                if let nextDate = Calendar.current.date(byAdding: .month, value: months, to: currentDate) {
                    try await api.addAppointment(
                        doctorName: appt.doctorName,
                        specialty: appt.specialty,
                        location: appt.location,
                        notes: appt.notes,
                        date: nextDate,
                        isRecurring: true,
                        recurringMonths: months
                    )
                }
            }

            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func scheduleAllNotifications() {
        for appt in upcoming {
            guard let date = appt.date else { continue }
            NotificationService.shared.scheduleDoctorAppointment(
                appointmentId: appt.id,
                doctorName: appt.doctorName,
                specialty: appt.specialty,
                date: date,
                location: appt.location
            )
        }
    }

    private func syncToWidget() {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
        if let next = nextAppointment {
            defaults?.set(next.doctorName, forKey: "nextAppointmentDoctor")
            defaults?.set(next.specialty ?? "Médico", forKey: "nextAppointmentSpecialty")
            defaults?.set(next.appointmentDate, forKey: "nextAppointmentDate")
            defaults?.set(next.location ?? "", forKey: "nextAppointmentLocation")
        } else {
            defaults?.removeObject(forKey: "nextAppointmentDoctor")
        }
        WidgetCenter.shared.reloadTimelines(ofKind: "MedicationWidget")
    }
}
