import Foundation
import Supabase


extension APIClient {

    // MARK: - Medical ID

    public func fetchMedicalID() async throws -> MedicalIDRow? {
        let userId = try await currentUserId()
        let rows: [MedicalIDRow] = try await supabase
            .from("medical_ids")
            .select()
            .eq("user_id", value: userId)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    public func upsertMedicalID(_ data: MedicalIDRow) async throws {
        try await supabase
            .from("medical_ids")
            .upsert(data)
            .execute()
    }

    public func updateMedicalID(_ updates: MedicalIDUpdate) async throws {
        let userId = try await currentUserId()
        try await supabase
            .from("medical_ids")
            .update(updates)
            .eq("user_id", value: userId)
            .execute()
    }
}
