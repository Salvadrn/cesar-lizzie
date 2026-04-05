import Foundation

// Flutter equivalent: alert_types.dart (portable directly)

public enum NNAlertType: String, CaseIterable {
    case routineStuck = "routine_stuck"
    case zoneExit = "zone_exit"
    case zoneEnter = "zone_enter"
    case emergency = "emergency"
    case missedRoutine = "missed_routine"
    case lowCompletion = "low_completion"
    case lostMode = "lost_mode"
    case system = "system"

    public var defaultSeverity: NNAlertSeverity {
        switch self {
        case .emergency, .lostMode: return .critical
        case .routineStuck, .zoneExit, .zoneEnter: return .warning
        case .missedRoutine, .lowCompletion, .system: return .info
        }
    }

    public var icon: String {
        switch self {
        case .routineStuck: return "pause.circle.fill"
        case .zoneExit: return "figure.walk.departure"
        case .zoneEnter: return "figure.walk.arrival"
        case .emergency: return "sos.circle.fill"
        case .missedRoutine: return "clock.badge.xmark"
        case .lowCompletion: return "chart.bar.xaxis"
        case .lostMode: return "mappin.and.ellipse"
        case .system: return "gear"
        }
    }
}

public enum NNAlertSeverity: String, CaseIterable {
    case info
    case warning
    case critical
}
