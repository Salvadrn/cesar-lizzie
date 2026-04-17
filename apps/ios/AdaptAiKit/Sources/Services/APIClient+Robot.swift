import Foundation
import Supabase


// MARK: - Robot Codable Models

public struct RobotRow: Codable {
    public let id: String
    public let userId: String?
    public let serialNumber: String
    public let name: String
    public let status: String
    public let lastSeenAt: String?
    public let firmwareVersion: String?
    public let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case serialNumber = "serial_number"
        case name
        case status
        case lastSeenAt = "last_seen_at"
        case firmwareVersion = "firmware_version"
        case isActive = "is_active"
    }
}

public struct RobotConfigRow: Codable {
    public let id: String
    public let robotId: String
    public let followDistanceM: Double
    public let maxSpeed: Double
    public let emergencyStopCm: Int
    public let telemetryRateHz: Int
    public let bleTargetUuid: String?
    public let lidarEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case robotId = "robot_id"
        case followDistanceM = "follow_distance_m"
        case maxSpeed = "max_speed"
        case emergencyStopCm = "emergency_stop_cm"
        case telemetryRateHz = "telemetry_rate_hz"
        case bleTargetUuid = "ble_target_uuid"
        case lidarEnabled = "lidar_enabled"
    }
}

public struct RobotTelemetryRow: Codable {
    public let id: String
    public let robotId: String
    public let state: String
    public let batteryPercent: Double
    public let bleEstimatedDistance: Double?
    public let bleTargetFound: Bool
    public let lidarNearestObstacle: Double?
    public let ultrasonicFrontLeft: Double?
    public let ultrasonicFrontRight: Double?
    public let motorSpeed: Double
    public let steeringAngle: Double
    public let cpuTemp: Double
    public let uptimeSeconds: Int
    public let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case robotId = "robot_id"
        case state
        case batteryPercent = "battery_percent"
        case bleEstimatedDistance = "ble_estimated_distance"
        case bleTargetFound = "ble_target_found"
        case lidarNearestObstacle = "lidar_nearest_obstacle"
        case ultrasonicFrontLeft = "ultrasonic_front_left"
        case ultrasonicFrontRight = "ultrasonic_front_right"
        case motorSpeed = "motor_speed"
        case steeringAngle = "steering_angle"
        case cpuTemp = "cpu_temp"
        case uptimeSeconds = "uptime_seconds"
        case createdAt = "created_at"
    }
}


extension APIClient {

    // MARK: - Fetch My Robot

    public func fetchMyRobot() async throws -> RobotRow? {
        let userId = try await currentUserId()
        let robots: [RobotRow] = try await supabase
            .from("robots")
            .select()
            .eq("user_id", value: userId)
            .eq("is_active", value: true)
            .limit(1)
            .execute()
            .value
        return robots.first
    }

    // MARK: - Fetch Robot Config

    public func fetchRobotConfig(robotId: String) async throws -> RobotConfigRow? {
        let configs: [RobotConfigRow] = try await supabase
            .from("robot_configs")
            .select()
            .eq("robot_id", value: robotId)
            .limit(1)
            .execute()
            .value
        return configs.first
    }

    // MARK: - Fetch Latest Telemetry

    public func fetchLatestTelemetry(robotId: String) async throws -> RobotTelemetryRow? {
        let rows: [RobotTelemetryRow] = try await supabase
            .from("robot_telemetry")
            .select()
            .eq("robot_id", value: robotId)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    // MARK: - QR Pairing

    public func pairRobot(serialNumber: String, pairingCode: String) async throws -> RobotRow {
        let userId = try await currentUserId()

        // Find robot by serial number
        let robots: [RobotRow] = try await supabase
            .from("robots")
            .select()
            .eq("serial_number", value: serialNumber)
            .eq("is_active", value: true)
            .limit(1)
            .execute()
            .value

        guard let robot = robots.first else {
            throw APIError.notFound
        }

        // Verify pairing code (first 8 chars of api_key_hash starting at pos 4)
        let hashRows: [[String: String]] = try await supabase
            .from("robots")
            .select("api_key_hash")
            .eq("id", value: robot.id)
            .limit(1)
            .execute()
            .value

        guard let hash = hashRows.first?["api_key_hash"],
              hash.count >= 12 else {
            throw APIError.serverError("Invalid robot data")
        }

        let startIdx = hash.index(hash.startIndex, offsetBy: 4)
        let endIdx = hash.index(hash.startIndex, offsetBy: 12)
        let expectedCode = String(hash[startIdx..<endIdx])

        guard pairingCode == expectedCode else {
            throw APIError.serverError("Codigo de vinculacion incorrecto")
        }

        // Link robot to user
        try await supabase
            .from("robots")
            .update(["user_id": userId])
            .eq("id", value: robot.id)
            .execute()

        // Return updated robot
        let updated: [RobotRow] = try await supabase
            .from("robots")
            .select()
            .eq("id", value: robot.id)
            .limit(1)
            .execute()
            .value

        guard let result = updated.first else {
            throw APIError.notFound
        }
        return result
    }

    // MARK: - Unpair

    public func unpairRobot(robotId: String) async throws {
        try await supabase
            .from("robots")
            .update(["status": "offline"])
            .eq("id", value: robotId)
            .execute()
    }
}
