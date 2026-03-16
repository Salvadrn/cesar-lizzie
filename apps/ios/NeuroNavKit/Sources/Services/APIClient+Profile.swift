import Foundation
import Supabase


extension APIClient {

    // MARK: - Profile

    public func fetchProfile() async throws -> UserProfileResponse {
        let userId = try await currentUserId()
        let profile: ProfileData = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        return profile.toUserProfileResponse()
    }

    public func updateProfile(_ updates: ProfileUpdate) async throws {
        let userId = try await currentUserId()
        try await supabase
            .from("profiles")
            .update(updates)
            .eq("id", value: userId)
            .execute()
    }

    public func fetchPatientProfile(userId: String) async throws -> ProfileData {
        let profile: ProfileData = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        return profile
    }
}
