import Foundation
import Supabase


extension APIClient {

    // MARK: - Family / Caregiver Links

    public func fetchLinkedUsers() async throws -> [CaregiverLinkRow] {
        let userId = try await currentUserId()

        let asCaregiver: [CaregiverLinkRow] = try await supabase
            .from("caregiver_links")
            .select("*, profiles!caregiver_links_user_id_fkey(display_name, email, current_complexity, sensory_mode)")
            .eq("caregiver_id", value: userId)
            .neq("status", value: AppConstants.LinkStatus.revoked.rawValue)
            .execute()
            .value

        let asUser: [CaregiverLinkRow] = try await supabase
            .from("caregiver_links")
            .select("*, profiles!caregiver_links_caregiver_id_fkey(display_name, email, current_complexity, sensory_mode)")
            .eq("user_id", value: userId)
            .neq("status", value: AppConstants.LinkStatus.revoked.rawValue)
            .execute()
            .value

        return asCaregiver + asUser
    }

    /// Generates a unique invite code with retry on collision.
    public func generateInviteCode() async throws -> String {
        let userId = try await currentUserId()
        let charset = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

        for _ in 0..<5 {
            let code = String((0..<8).compactMap { _ in charset.randomElement() })

            // Verify uniqueness
            let existing: [CaregiverLinkRow] = try await supabase
                .from("caregiver_links")
                .select("id")
                .eq("invite_code", value: code)
                .execute()
                .value

            guard existing.isEmpty else { continue }

            let invite = NewCaregiverLink(
                userId: userId,
                caregiverId: userId,
                inviteCode: code,
                status: AppConstants.LinkStatus.pending.rawValue
            )
            try await supabase
                .from("caregiver_links")
                .insert(invite)
                .execute()
            return code
        }

        throw APIError.serverError("No se pudo generar un código único. Intenta de nuevo.")
    }

    public func acceptInvite(code: String) async throws {
        let userId = try await currentUserId()

        let links: [CaregiverLinkRow] = try await supabase
            .from("caregiver_links")
            .select()
            .eq("invite_code", value: code)
            .eq("status", value: AppConstants.LinkStatus.pending.rawValue)
            .execute()
            .value

        guard let link = links.first else {
            throw APIError.notFound
        }

        try await supabase
            .from("caregiver_links")
            .update([
                "caregiver_id": userId,
                "status": AppConstants.LinkStatus.active.rawValue
            ])
            .eq("id", value: link.id)
            .execute()
    }

    public func revokeLink(linkId: String) async throws {
        try await supabase
            .from("caregiver_links")
            .update(["status": AppConstants.LinkStatus.revoked.rawValue])
            .eq("id", value: linkId)
            .execute()
    }

    public func updateLinkPermissions(linkId: String, permissions: [String: Bool]) async throws {
        try await supabase
            .from("caregiver_links")
            .update(permissions)
            .eq("id", value: linkId)
            .execute()
    }
}
