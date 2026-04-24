import Foundation
import Supabase


// MARK: - Location Row (Supabase)

public struct LocationUpdateRow: Codable, Identifiable, Sendable {
    public let id: String
    public let userId: String
    public let latitude: Double
    public let longitude: Double
    public let accuracy: Double?
    public let batteryLevel: Double?
    public let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case latitude, longitude, accuracy
        case batteryLevel = "battery_level"
        case createdAt = "created_at"
    }
}

struct NewLocationUpdate: Codable {
    let userId: String
    let latitude: Double
    let longitude: Double
    let accuracy: Double?
    let batteryLevel: Double?

    enum CodingKeys: String, CodingKey {
        case latitude, longitude, accuracy
        case userId = "user_id"
        case batteryLevel = "battery_level"
    }
}


extension APIClient {

    // MARK: - Publish my location (patient)

    /// Uploads a location ping for the current user.
    /// Caregivers with permViewLocation=true can read the latest row.
    public func publishLocation(
        latitude: Double,
        longitude: Double,
        accuracy: Double? = nil,
        batteryLevel: Double? = nil
    ) async throws {
        let userId = try await currentUserId()
        let row = NewLocationUpdate(
            userId: userId,
            latitude: latitude,
            longitude: longitude,
            accuracy: accuracy,
            batteryLevel: batteryLevel
        )
        try await supabase
            .from("patient_locations")
            .insert(row)
            .execute()
    }

    // MARK: - Get latest location of a patient (caregiver)

    public func fetchLatestLocation(patientId: String) async throws -> LocationUpdateRow? {
        let rows: [LocationUpdateRow] = try await supabase
            .from("patient_locations")
            .select()
            .eq("user_id", value: patientId)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    /// Streams the latest N locations (for trail/breadcrumb view).
    public func fetchLocationTrail(patientId: String, limit: Int = 20) async throws -> [LocationUpdateRow] {
        let rows: [LocationUpdateRow] = try await supabase
            .from("patient_locations")
            .select()
            .eq("user_id", value: patientId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        return rows
    }
}
