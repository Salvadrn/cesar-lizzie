import Foundation
import Supabase


extension APIClient {

    // MARK: - Alerts

    public func fetchAlerts() async throws -> [AlertResponse] {
        let alerts: [AlertRow] = try await supabase
            .from("alerts")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
        return alerts.map { $0.toResponse() }
    }

    public func createAlert(type: AppConstants.AlertType, severity: AppConstants.AlertSeverity, title: String, message: String?) async throws {
        let userId = try await currentUserId()
        let newAlert = NewAlert(userId: userId, alertType: type.rawValue, severity: severity.rawValue, title: title, message: message)
        try await supabase
            .from("alerts")
            .insert(newAlert)
            .execute()
    }

    /// Notifies all linked family members/caregivers via batch insert.
    public func notifyFamilyMembers(alertType: AppConstants.AlertType, title: String, message: String?) async throws {
        let userId = try await currentUserId()

        let links: [CaregiverLinkRow] = try await supabase
            .from("caregiver_links")
            .select()
            .eq("user_id", value: userId)
            .eq("status", value: AppConstants.LinkStatus.active.rawValue)
            .execute()
            .value

        guard !links.isEmpty else { return }

        // Batch insert — single round-trip instead of N
        let alerts = links.map { link in
            NewAlert(
                userId: link.caregiverId,
                alertType: alertType.rawValue,
                severity: AppConstants.AlertSeverity.critical.rawValue,
                title: title,
                message: message
            )
        }
        try await supabase.from("alerts").insert(alerts).execute()
    }

    public func fetchPatientAlerts(userId: String) async throws -> [AlertRow] {
        let alerts: [AlertRow] = try await supabase
            .from("alerts")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .limit(20)
            .execute()
            .value
        return alerts
    }
}
