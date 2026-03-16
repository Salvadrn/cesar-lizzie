import Foundation
import Supabase


extension APIClient {

    // MARK: - Medications

    public func fetchMedications() async throws -> [MedicationRow] {
        let userId = try await currentUserId()
        let meds: [MedicationRow] = try await supabase
            .from("medications")
            .select()
            .eq("user_id", value: userId)
            .order("hour", ascending: true)
            .execute()
            .value
        return meds
    }

    public func addMedication(name: String, dosage: String, hour: Int, minute: Int, reminderOffsets: [Int] = [5]) async throws {
        let userId = try await currentUserId()
        let newMed = NewMedication(userId: userId, name: name, dosage: dosage, hour: hour, minute: minute, reminderOffsets: reminderOffsets)
        try await supabase
            .from("medications")
            .insert(newMed)
            .execute()
    }

    public func markMedicationTaken(id: String) async throws {
        try await supabase
            .from("medications")
            .update(["taken_today": true])
            .eq("id", value: id)
            .execute()
    }

    public func deleteMedication(id: String) async throws {
        try await supabase
            .from("medications")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Caregiver: Patient Medications

    public func fetchPatientMedications(patientId: String) async throws -> [MedicationRow] {
        let meds: [MedicationRow] = try await supabase
            .from("medications")
            .select()
            .eq("user_id", value: patientId)
            .order("hour", ascending: true)
            .execute()
            .value
        return meds
    }

    public func addPatientMedication(patientId: String, name: String, dosage: String, hour: Int, minute: Int, reminderOffsets: [Int] = [5]) async throws {
        let newMed = NewMedication(userId: patientId, name: name, dosage: dosage, hour: hour, minute: minute, reminderOffsets: reminderOffsets)
        try await supabase
            .from("medications")
            .insert(newMed)
            .execute()
    }
}
