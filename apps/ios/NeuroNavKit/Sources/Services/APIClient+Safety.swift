import Foundation
import Supabase


extension APIClient {

    // MARK: - Safety Zones

    public func fetchSafetyZones() async throws -> [SafetyZoneResponse] {
        let zones: [SafetyZoneRow] = try await supabase
            .from("safety_zones")
            .select()
            .execute()
            .value
        return zones.map { $0.toResponse() }
    }

    public func fetchPatientSafetyZones(userId: String) async throws -> [SafetyZoneRow] {
        let zones: [SafetyZoneRow] = try await supabase
            .from("safety_zones")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        return zones
    }

    // MARK: - Emergency Contacts

    public func fetchEmergencyContacts() async throws -> [EmergencyContactResponse] {
        let contacts: [EmergencyContactRow] = try await supabase
            .from("emergency_contacts")
            .select()
            .execute()
            .value
        return contacts.map { $0.toResponse() }
    }

    public func addEmergencyContact(name: String, phone: String, relationship: String, isPrimary: Bool) async throws {
        let userId = try await currentUserId()
        let contact = NewEmergencyContact(userId: userId, name: name, phone: phone, relationship: relationship, isPrimary: isPrimary)
        try await supabase
            .from("emergency_contacts")
            .insert(contact)
            .execute()
    }

    public func deleteEmergencyContact(id: String) async throws {
        try await supabase
            .from("emergency_contacts")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    /// Sets a contact as primary atomically via RPC.
    /// Falls back to two-step update if RPC is not available.
    public func setEmergencyContactPrimary(id: String) async throws {
        let userId = try await currentUserId()

        // Try atomic RPC first
        do {
            try await supabase.rpc("set_primary_emergency_contact", params: [
                "p_user_id": userId,
                "p_contact_id": id
            ]).execute()
        } catch {
            // Fallback: two-step (set new primary first to avoid zero-primary state)
            try await supabase
                .from("emergency_contacts")
                .update(["is_primary": true])
                .eq("id", value: id)
                .execute()

            // Then unset others
            try await supabase
                .from("emergency_contacts")
                .update(["is_primary": false])
                .eq("user_id", value: userId)
                .neq("id", value: id)
                .execute()
        }
    }
}
