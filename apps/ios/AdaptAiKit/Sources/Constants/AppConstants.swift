import Foundation


public enum AppConstants {
    public static let supabaseURL = "https://hrfipfmxbdaoipjcszif.supabase.co"
    public static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhyZmlwZm14YmRhb2lwamNzemlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2NDI5ODIsImV4cCI6MjA4ODIxODk4Mn0.DnA7b9yXOCtPSC0beXOxa7NCMMFssaZZBtA0FsVlG_0"

    public static let appGroupIdentifier = "group.com.adaptai.shared"
    public static let keychainService = "com.adaptai.keychain"

    public enum UserRole: String, CaseIterable {
        case guest
        case patient
        case caregiver
        case family
        case admin

        // Map old "user" value from DB
        public init(rawValue: String) {
            switch rawValue {
            case "guest": self = .guest
            case "patient", "user": self = .patient
            case "caregiver": self = .caregiver
            case "family": self = .family
            case "admin": self = .admin
            default: self = .patient
            }
        }

        public var displayName: String {
            switch self {
            case .guest: return "Invitado"
            case .patient: return "Paciente"
            case .caregiver: return "Cuidador"
            case .family: return "Familiar"
            case .admin: return "Admin"
            }
        }

        public var canModifyData: Bool {
            switch self {
            case .guest, .family: return false
            case .patient, .caregiver, .admin: return true
            }
        }
    }

    public enum RoutineCategory: String, CaseIterable {
        case cooking
        case hygiene
        case laundry
        case medication
        case transit
        case shopping
        case cleaning
        case social
        case custom

        public var icon: String {
            switch self {
            case .cooking: return "fork.knife"
            case .hygiene: return "shower.fill"
            case .laundry: return "washer.fill"
            case .medication: return "pill.fill"
            case .transit: return "bus.fill"
            case .shopping: return "cart.fill"
            case .cleaning: return "bubbles.and.sparkles.fill"
            case .social: return "person.2.fill"
            case .custom: return "star.fill"
            }
        }
    }

    public enum ScheduleType: String, CaseIterable {
        case daily
        case weekdays
        case weekends
        case custom
    }

    public enum ExecutionStatus: String, Codable {
        case inProgress = "in_progress"
        case completed
        case paused
        case abandoned
    }

    public enum StepExecutionStatus: String, Codable {
        case pending
        case inProgress = "in_progress"
        case completed
        case skipped
        case error
    }

    public enum LinkStatus: String, Codable {
        case pending
        case active
        case revoked
    }

    public enum AlertSeverity: String, Codable {
        case low
        case medium
        case high
        case critical
    }

    public enum AlertType: String, Codable {
        case emergency
        case zoneExit = "zone_exit"
        case zoneEnter = "zone_enter"
        case medicationMissed = "medication_missed"
        case stallDetected = "stall_detected"
        case crashDetected = "crash_detected"
        case system
    }

    public enum AppointmentStatus: String, Codable {
        case scheduled
        case completed
        case cancelled
    }
}
