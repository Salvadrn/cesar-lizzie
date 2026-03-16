import Foundation
import Supabase


extension APIClient {

    // MARK: - Doctor Appointments

    public func fetchAppointments() async throws -> [AppointmentRow] {
        let userId = try await currentUserId()
        let rows: [AppointmentRow] = try await supabase
            .from("appointments")
            .select()
            .eq("user_id", value: userId)
            .neq("status", value: AppConstants.AppointmentStatus.cancelled.rawValue)
            .order("appointment_date", ascending: true)
            .execute()
            .value
        return rows
    }

    public func addAppointment(doctorName: String, specialty: String?, location: String?, notes: String?,
                               date: Date, isRecurring: Bool, recurringMonths: Int?) async throws {
        let userId = try await currentUserId()
        let newAppt = NewAppointment(
            userId: userId,
            doctorName: doctorName,
            specialty: specialty,
            location: location,
            notes: notes,
            appointmentDate: Self.iso8601.string(from: date),
            isRecurring: isRecurring,
            recurringMonths: recurringMonths
        )
        try await supabase
            .from("appointments")
            .insert(newAppt)
            .execute()
    }

    public func deleteAppointment(id: String) async throws {
        try await supabase
            .from("appointments")
            .update(["status": AppConstants.AppointmentStatus.cancelled.rawValue])
            .eq("id", value: id)
            .execute()
    }

    public func completeAppointment(id: String) async throws {
        try await supabase
            .from("appointments")
            .update(["status": AppConstants.AppointmentStatus.completed.rawValue])
            .eq("id", value: id)
            .execute()
    }
}
