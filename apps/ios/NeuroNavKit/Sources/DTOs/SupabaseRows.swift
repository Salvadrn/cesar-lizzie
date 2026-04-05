import Foundation


// MARK: - Supabase Row Types (snake_case mapping from DB)
// These map directly to Supabase table schemas and convert to public Response types.

struct RoutineRow: Codable {
    let id: String
    let title: String
    let description: String?
    let category: String
    let isActive: Bool
    let assignedTo: String?
    let complexityLevel: Int?
    let routineSteps: [StepRow]?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, category
        case isActive = "is_active"
        case assignedTo = "assigned_to"
        case complexityLevel = "complexity_level"
        case routineSteps = "routine_steps"
        case createdAt = "created_at"
    }

    func toResponse() -> RoutineResponse {
        RoutineResponse(
            id: id,
            title: title,
            description: description,
            category: category,
            isActive: isActive,
            assignedTo: assignedTo,
            complexityLevel: complexityLevel,
            steps: routineSteps?.sorted(by: { $0.stepOrder < $1.stepOrder }).map { $0.toResponse() },
            createdAt: createdAt
        )
    }
}

struct StepRow: Codable {
    let id: String
    let stepOrder: Int
    let title: String
    let instruction: String
    let instructionSimple: String?
    let instructionDetailed: String?
    let imageUrl: String?
    let audioUrl: String?
    let videoUrl: String?
    let durationHint: Int
    let checkpoint: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, instruction, checkpoint
        case stepOrder = "step_order"
        case instructionSimple = "instruction_simple"
        case instructionDetailed = "instruction_detailed"
        case imageUrl = "image_url"
        case audioUrl = "audio_url"
        case videoUrl = "video_url"
        case durationHint = "duration_hint"
    }

    func toResponse() -> StepResponse {
        StepResponse(
            id: id,
            stepOrder: stepOrder,
            title: title,
            instruction: instruction,
            instructionSimple: instructionSimple,
            instructionDetailed: instructionDetailed,
            imageURL: imageUrl,
            audioURL: audioUrl,
            videoURL: videoUrl,
            durationHint: durationHint,
            checkpoint: checkpoint
        )
    }
}

public struct ExecutionRow: Codable, Identifiable, Sendable {
    public let id: String
    public let routineId: String
    public let userId: String
    public let status: String
    public let startedAt: String
    public let completedAt: String?
    public let completedSteps: Int
    public let totalSteps: Int
    public let errorCount: Int
    public let stallCount: Int

    enum CodingKeys: String, CodingKey {
        case id, status
        case routineId = "routine_id"
        case userId = "user_id"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case completedSteps = "completed_steps"
        case totalSteps = "total_steps"
        case errorCount = "error_count"
        case stallCount = "stall_count"
    }

    func toResponse() -> ExecutionResponse {
        ExecutionResponse(
            id: id,
            routineId: routineId,
            userId: userId,
            status: status,
            startedAt: startedAt,
            completedAt: completedAt,
            completedSteps: completedSteps,
            totalSteps: totalSteps,
            errorCount: errorCount,
            stallCount: stallCount
        )
    }
}

struct NewExecution: Codable {
    let routineId: String
    let userId: String
    let totalSteps: Int

    enum CodingKeys: String, CodingKey {
        case routineId = "routine_id"
        case userId = "user_id"
        case totalSteps = "total_steps"
    }
}

struct NewStepExecution: Codable {
    let executionId: String
    let stepId: String
    let status: String
    let durationSeconds: Int
    let errorCount: Int
    let stallCount: Int
    let rePromptCount: Int

    enum CodingKeys: String, CodingKey {
        case status
        case executionId = "execution_id"
        case stepId = "step_id"
        case durationSeconds = "duration_seconds"
        case errorCount = "error_count"
        case stallCount = "stall_count"
        case rePromptCount = "re_prompt_count"
    }
}

public struct SafetyZoneRow: Codable, Identifiable, Sendable {
    public let id: String
    public let userId: String
    public let name: String
    public let latitude: Double
    public let longitude: Double
    public let radiusMeters: Double
    public let zoneType: String
    public let alertOnExit: Bool
    public let alertOnEnter: Bool
    public let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude
        case userId = "user_id"
        case radiusMeters = "radius_meters"
        case zoneType = "zone_type"
        case alertOnExit = "alert_on_exit"
        case alertOnEnter = "alert_on_enter"
        case isActive = "is_active"
    }

    func toResponse() -> SafetyZoneResponse {
        SafetyZoneResponse(id: id, userId: userId, name: name, latitude: latitude, longitude: longitude, radiusMeters: radiusMeters, zoneType: zoneType, alertOnExit: alertOnExit, alertOnEnter: alertOnEnter, isActive: isActive)
    }
}

struct EmergencyContactRow: Codable {
    let id: String
    let userId: String
    let name: String
    let phone: String
    let relationship: String
    let isPrimary: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, phone, relationship
        case userId = "user_id"
        case isPrimary = "is_primary"
    }

    func toResponse() -> EmergencyContactResponse {
        EmergencyContactResponse(id: id, userId: userId, name: name, phone: phone, relationship: relationship, isPrimary: isPrimary)
    }
}

public struct AlertRow: Codable, Identifiable, Sendable {
    public let id: String
    public let alertType: String
    public let severity: String
    public let title: String
    public let message: String?
    public let isRead: Bool
    public let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, title, message, severity
        case alertType = "alert_type"
        case isRead = "is_read"
        case createdAt = "created_at"
    }

    func toResponse() -> AlertResponse {
        AlertResponse(id: id, alertType: alertType, severity: severity, title: title, message: message, isRead: isRead, createdAt: createdAt)
    }
}

struct NewAlert: Codable {
    let userId: String
    let alertType: String
    let severity: String
    let title: String
    let message: String?

    enum CodingKeys: String, CodingKey {
        case title, message, severity
        case userId = "user_id"
        case alertType = "alert_type"
    }
}

public struct LinkedProfileInfo: Codable, Sendable {
    public let displayName: String
    public let email: String?
    public let currentComplexity: Int?
    public let sensoryMode: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case email
        case currentComplexity = "current_complexity"
        case sensoryMode = "sensory_mode"
    }

    public init(displayName: String, email: String? = nil, currentComplexity: Int? = nil, sensoryMode: String? = nil) {
        self.displayName = displayName
        self.email = email
        self.currentComplexity = currentComplexity
        self.sensoryMode = sensoryMode
    }
}

public struct CaregiverLinkRow: Codable, Identifiable, Sendable {
    public let id: String
    public let userId: String
    public let caregiverId: String
    public let relationship: String?
    public let status: String
    public let inviteCode: String?
    public let permViewActivity: Bool
    public let permEditRoutines: Bool
    public let permViewLocation: Bool
    public let permViewMedications: Bool
    public let permViewEmergency: Bool
    public let createdAt: String
    public let profiles: LinkedProfileInfo?

    enum CodingKeys: String, CodingKey {
        case id, relationship, status, profiles
        case userId = "user_id"
        case caregiverId = "caregiver_id"
        case inviteCode = "invite_code"
        case permViewActivity = "perm_view_activity"
        case permEditRoutines = "perm_edit_routines"
        case permViewLocation = "perm_view_location"
        case permViewMedications = "perm_view_medications"
        case permViewEmergency = "perm_view_emergency"
        case createdAt = "created_at"
    }

    public init(id: String, userId: String, caregiverId: String, relationship: String? = nil,
                status: String, inviteCode: String? = nil, permViewActivity: Bool = true,
                permEditRoutines: Bool = false, permViewLocation: Bool = false,
                permViewMedications: Bool = true, permViewEmergency: Bool = true,
                createdAt: String, profiles: LinkedProfileInfo? = nil) {
        self.id = id
        self.userId = userId
        self.caregiverId = caregiverId
        self.relationship = relationship
        self.status = status
        self.inviteCode = inviteCode
        self.permViewActivity = permViewActivity
        self.permEditRoutines = permEditRoutines
        self.permViewLocation = permViewLocation
        self.permViewMedications = permViewMedications
        self.permViewEmergency = permViewEmergency
        self.createdAt = createdAt
        self.profiles = profiles
    }
}

struct NewCaregiverLink: Codable {
    let userId: String
    let caregiverId: String
    let inviteCode: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case status
        case userId = "user_id"
        case caregiverId = "caregiver_id"
        case inviteCode = "invite_code"
    }
}

public struct MedicationRow: Codable, Identifiable, Sendable {
    public let id: String
    public let userId: String
    public let name: String
    public let dosage: String
    public let hour: Int
    public let minute: Int
    public let takenToday: Bool
    public let isActive: Bool
    public let reminderOffsets: [Int]?

    enum CodingKeys: String, CodingKey {
        case id, name, dosage, hour, minute
        case userId = "user_id"
        case takenToday = "taken_today"
        case isActive = "is_active"
        case reminderOffsets = "reminder_offsets"
    }
}

struct NewMedication: Codable {
    let userId: String
    let name: String
    let dosage: String
    let hour: Int
    let minute: Int
    let reminderOffsets: [Int]

    enum CodingKeys: String, CodingKey {
        case name, dosage, hour, minute
        case userId = "user_id"
        case reminderOffsets = "reminder_offsets"
    }
}

struct NewEmergencyContact: Codable {
    let userId: String
    let name: String
    let phone: String
    let relationship: String
    let isPrimary: Bool

    enum CodingKeys: String, CodingKey {
        case name, phone, relationship
        case userId = "user_id"
        case isPrimary = "is_primary"
    }
}

public struct AppointmentRow: Codable, Identifiable, Sendable {
    public let id: String
    public let userId: String
    public let doctorName: String
    public let specialty: String?
    public let location: String?
    public let notes: String?
    public let appointmentDate: String
    public let isRecurring: Bool
    public let recurringMonths: Int?
    public let status: String
    public let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, specialty, location, notes, status
        case userId = "user_id"
        case doctorName = "doctor_name"
        case appointmentDate = "appointment_date"
        case isRecurring = "is_recurring"
        case recurringMonths = "recurring_months"
        case createdAt = "created_at"
    }

    public var date: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = formatter.date(from: appointmentDate) { return d }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: appointmentDate)
    }

    public var isPast: Bool {
        guard let d = date else { return false }
        return d < Date()
    }

    public init(id: String, userId: String, doctorName: String, specialty: String?,
                location: String?, notes: String?, appointmentDate: String,
                isRecurring: Bool, recurringMonths: Int?, status: String, createdAt: String) {
        self.id = id
        self.userId = userId
        self.doctorName = doctorName
        self.specialty = specialty
        self.location = location
        self.notes = notes
        self.appointmentDate = appointmentDate
        self.isRecurring = isRecurring
        self.recurringMonths = recurringMonths
        self.status = status
        self.createdAt = createdAt
    }
}

struct NewAppointment: Codable {
    let userId: String
    let doctorName: String
    let specialty: String?
    let location: String?
    let notes: String?
    let appointmentDate: String
    let isRecurring: Bool
    let recurringMonths: Int?

    enum CodingKeys: String, CodingKey {
        case specialty, location, notes
        case userId = "user_id"
        case doctorName = "doctor_name"
        case appointmentDate = "appointment_date"
        case isRecurring = "is_recurring"
        case recurringMonths = "recurring_months"
    }
}

// MARK: - ProfileData extensions

extension ProfileData {
    func toUserProfileResponse() -> UserProfileResponse {
        UserProfileResponse(
            id: id,
            currentComplexity: currentComplexity,
            complexityFloor: complexityFloor,
            complexityCeiling: complexityCeiling,
            sensoryMode: sensoryMode,
            preferredInput: preferredInput,
            hapticEnabled: hapticEnabled,
            audioEnabled: audioEnabled,
            fontScale: fontScale,
            lostModeName: lostModeName,
            lostModeAddress: lostModeAddress,
            lostModePhone: lostModePhone,
            lostModePhotoURL: lostModePhotoUrl
        )
    }
}

public struct ProfileUpdate: Codable, Sendable {
    public var displayName: String?
    public var sensoryMode: String?
    public var preferredInput: String?
    public var hapticEnabled: Bool?
    public var audioEnabled: Bool?
    public var fontScale: Double?
    public var currentComplexity: Int?
    public var lostModeName: String?
    public var lostModeAddress: String?
    public var lostModePhone: String?
    public var simpleMode: Bool?
    public var alsoCares: Bool?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case sensoryMode = "sensory_mode"
        case preferredInput = "preferred_input"
        case hapticEnabled = "haptic_enabled"
        case audioEnabled = "audio_enabled"
        case fontScale = "font_scale"
        case currentComplexity = "current_complexity"
        case lostModeName = "lost_mode_name"
        case lostModeAddress = "lost_mode_address"
        case lostModePhone = "lost_mode_phone"
        case simpleMode = "simple_mode"
        case alsoCares = "also_cares"
    }

    public init(displayName: String? = nil, sensoryMode: String? = nil, preferredInput: String? = nil,
                hapticEnabled: Bool? = nil, audioEnabled: Bool? = nil, fontScale: Double? = nil,
                currentComplexity: Int? = nil, lostModeName: String? = nil, lostModeAddress: String? = nil,
                lostModePhone: String? = nil, simpleMode: Bool? = nil, alsoCares: Bool? = nil) {
        self.displayName = displayName
        self.sensoryMode = sensoryMode
        self.preferredInput = preferredInput
        self.hapticEnabled = hapticEnabled
        self.audioEnabled = audioEnabled
        self.fontScale = fontScale
        self.currentComplexity = currentComplexity
        self.lostModeName = lostModeName
        self.lostModeAddress = lostModeAddress
        self.lostModePhone = lostModePhone
        self.simpleMode = simpleMode
        self.alsoCares = alsoCares
    }
}


// MARK: - Medical ID

public struct MedicalIDRow: Codable, Identifiable, Sendable {
    public let id: String
    public let userId: String
    public var fullName: String
    public var dateOfBirth: String?
    public var bloodType: String?
    public var weight: Double?
    public var height: Double?
    public var allergies: [String]
    public var conditions: [String]
    public var currentMedications: [String]
    public var doctorName: String?
    public var doctorPhone: String?
    public var insuranceProvider: String?
    public var insuranceNumber: String?
    public var organDonor: Bool
    public var notes: String?
    public var photoUrl: String?
    public var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case fullName = "full_name"
        case dateOfBirth = "date_of_birth"
        case bloodType = "blood_type"
        case weight, height, allergies, conditions
        case currentMedications = "current_medications"
        case doctorName = "doctor_name"
        case doctorPhone = "doctor_phone"
        case insuranceProvider = "insurance_provider"
        case insuranceNumber = "insurance_number"
        case organDonor = "organ_donor"
        case notes
        case photoUrl = "photo_url"
        case updatedAt = "updated_at"
    }

    public init(id: String, userId: String, fullName: String, dateOfBirth: String? = nil,
                bloodType: String? = nil, weight: Double? = nil, height: Double? = nil,
                allergies: [String] = [], conditions: [String] = [], currentMedications: [String] = [],
                doctorName: String? = nil, doctorPhone: String? = nil,
                insuranceProvider: String? = nil, insuranceNumber: String? = nil,
                organDonor: Bool = false, notes: String? = nil, photoUrl: String? = nil,
                updatedAt: String? = nil) {
        self.id = id
        self.userId = userId
        self.fullName = fullName
        self.dateOfBirth = dateOfBirth
        self.bloodType = bloodType
        self.weight = weight
        self.height = height
        self.allergies = allergies
        self.conditions = conditions
        self.currentMedications = currentMedications
        self.doctorName = doctorName
        self.doctorPhone = doctorPhone
        self.insuranceProvider = insuranceProvider
        self.insuranceNumber = insuranceNumber
        self.organDonor = organDonor
        self.notes = notes
        self.photoUrl = photoUrl
        self.updatedAt = updatedAt
    }
}

public struct MedicalIDUpdate: Codable, Sendable {
    public var fullName: String?
    public var dateOfBirth: String?
    public var bloodType: String?
    public var weight: Double?
    public var height: Double?
    public var allergies: [String]?
    public var conditions: [String]?
    public var currentMedications: [String]?
    public var doctorName: String?
    public var doctorPhone: String?
    public var insuranceProvider: String?
    public var insuranceNumber: String?
    public var organDonor: Bool?
    public var notes: String?

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case dateOfBirth = "date_of_birth"
        case bloodType = "blood_type"
        case weight, height, allergies, conditions
        case currentMedications = "current_medications"
        case doctorName = "doctor_name"
        case doctorPhone = "doctor_phone"
        case insuranceProvider = "insurance_provider"
        case insuranceNumber = "insurance_number"
        case organDonor = "organ_donor"
        case notes
    }

    public init(fullName: String? = nil, dateOfBirth: String? = nil, bloodType: String? = nil,
                weight: Double? = nil, height: Double? = nil, allergies: [String]? = nil,
                conditions: [String]? = nil, currentMedications: [String]? = nil,
                doctorName: String? = nil, doctorPhone: String? = nil,
                insuranceProvider: String? = nil, insuranceNumber: String? = nil,
                organDonor: Bool? = nil, notes: String? = nil) {
        self.fullName = fullName
        self.dateOfBirth = dateOfBirth
        self.bloodType = bloodType
        self.weight = weight
        self.height = height
        self.allergies = allergies
        self.conditions = conditions
        self.currentMedications = currentMedications
        self.doctorName = doctorName
        self.doctorPhone = doctorPhone
        self.insuranceProvider = insuranceProvider
        self.insuranceNumber = insuranceNumber
        self.organDonor = organDonor
        self.notes = notes
    }
}
