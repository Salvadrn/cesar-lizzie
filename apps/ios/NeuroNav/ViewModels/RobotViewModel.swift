import SwiftUI
import NeuroNavKit

@Observable
class RobotViewModel {
    static let shared = RobotViewModel()

    var robotId: String?
    var robotName: String = ""
    var serialNumber: String = ""
    var status: String = "offline"
    var state: String = "idle"
    var batteryPercent: Double = 0
    var bleDistance: Double?
    var bleTargetFound: Bool = false
    var lidarNearest: Double?
    var ultrasonicLeft: Double?
    var ultrasonicRight: Double?
    var motorSpeed: Double = 0
    var steeringAngle: Double = 0
    var cpuTemp: Double = 0
    var uptimeSeconds: Int = 0
    var hasRobot: Bool = false

    var followDistance: Double = 1.5
    var maxSpeed: Double = 0.5
    var emergencyStopCm: Int = 30
    var lidarEnabled: Bool = true

    func fetchRobot() async {
        do {
            guard let robot = try await APIClient.shared.fetchMyRobot() else {
                hasRobot = false
                return
            }
            robotId = robot.id
            robotName = robot.name
            serialNumber = robot.serialNumber
            status = robot.status
            hasRobot = true

            if let config = try await APIClient.shared.fetchRobotConfig(robotId: robot.id) {
                followDistance = config.followDistanceM
                maxSpeed = config.maxSpeed
                emergencyStopCm = config.emergencyStopCm
                lidarEnabled = config.lidarEnabled
            }

            if let telemetry = try await APIClient.shared.fetchLatestTelemetry(robotId: robot.id) {
                updateFromTelemetry(telemetry)
            }
        } catch {
            hasRobot = false
        }
    }

    func updateFromTelemetry(_ t: RobotTelemetryRow) {
        state = t.state
        batteryPercent = t.batteryPercent
        bleDistance = t.bleEstimatedDistance
        bleTargetFound = t.bleTargetFound
        lidarNearest = t.lidarNearestObstacle
        ultrasonicLeft = t.ultrasonicFrontLeft
        ultrasonicRight = t.ultrasonicFrontRight
        motorSpeed = t.motorSpeed
        steeringAngle = t.steeringAngle
        cpuTemp = t.cpuTemp
        uptimeSeconds = t.uptimeSeconds
    }

    func sendCommand(_ command: String) async {
        guard let id = robotId else { return }
        // For prototype: log the command. In production this would go via Socket.IO or a commands table
        print("[RobotVM] Command '\(command)' sent to robot \(id)")
    }

    var stateColor: Color {
        switch state {
        case "following": return .green
        case "paused": return .yellow
        case "error", "emergency_stop": return .red
        case "disconnected": return .gray
        default: return .secondary
        }
    }

    var stateEmoji: String {
        switch state {
        case "following": return "figure.walk.motion"
        case "paused": return "pause.circle.fill"
        case "error": return "exclamationmark.triangle.fill"
        case "emergency_stop": return "stop.circle.fill"
        case "disconnected": return "wifi.slash"
        default: return "circle.dashed"
        }
    }
}
