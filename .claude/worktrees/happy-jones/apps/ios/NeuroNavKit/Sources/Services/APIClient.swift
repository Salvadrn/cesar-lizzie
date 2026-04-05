import Foundation
import Supabase

// Flutter equivalent: api_client.dart

public enum APIError: Error, LocalizedError {
    case notAuthenticated
    case notFound
    case serverError(String)
    case decodingError(Error)

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "No autenticado"
        case .notFound: return "No encontrado"
        case .serverError(let msg): return msg
        case .decodingError(let err): return "Error de datos: \(err.localizedDescription)"
        }
    }
}

@Observable
public final class APIClient {
    public static let shared = APIClient()

    private let supabase = SupabaseManager.shared.client

    public init() {}

    // MARK: - Routines

    public func fetchRoutines() async throws -> [RoutineResponse] {
        let routines: [RoutineRow] = try await supabase
            .from("routines")
            .select("*, routine_steps(*)")
            .order("created_at", ascending: false)
            .execute()
            .value
        return routines.map { $0.toResponse() }
    }

    public func fetchRoutine(id: String) async throws -> RoutineResponse {
        let routine: RoutineRow = try await supabase
            .from("routines")
            .select("*, routine_steps(*)")
            .eq("id", value: id)
            .single()
            .execute()
            .value
        return routine.toResponse()
    }

    // MARK: - Profile

    public func fetchProfile() async throws -> UserProfileResponse {
        guard let userId = try? await supabase.auth.session.user.id else {
            throw APIError.notAuthenticated
        }
        let profile: ProfileData = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
        return profile.toUserProfileResponse()
    }

    public func updateProfile(_ updates: ProfileUpdate) async throws {
        guard let userId = try? await supabase.auth.session.user.id else {
            throw APIError.notAuthenticated
        }
        try await supabase
            .from("profiles")
            .update(updates)
            .eq("id", value: userId.uuidString)
            .execute()
    }

    // MARK: - Executions

    public func startExecution(routineId: String) async throws -> ExecutionResponse {
        guard let userId = try? await supabase.auth.session.user.id else {
            throw APIError.notAuthenticated
        }
        // Get total steps count
        let steps: [StepRow] = try await supabase
            .from("routine_steps")
            .select()
            .eq("routine_id", value: routineId)
            .execute()
            .value

        let newExecution = NewExecution(
            routineId: routineId,
            userId: userId.uuidString,
            totalSteps: steps.count
        )

        let row: ExecutionRow = try await supabase
            .from("routine_executions")
            .insert(newExecution)
            .select()
            .single()
            .execute()
            .value
        return row.toResponse()
    }

    public func completeStep(executionId: String, stepId: String, duration: Int, errors: Int, stalls: Int, rePrompts: Int) async throws {
        let stepExec = NewStepExecution(
            executionId: executionId,
            stepId: stepId,
            status: "completed",
            durationSeconds: duration,
            errorCount: errors,
            stallCount: stalls,
            rePromptCount: rePrompts
        )
        try await supabase
            .from("step_executions")
            .insert(stepExec)
            .execute()

        // Update completed_steps count
        let current: ExecutionRow = try await supabase
            .from("routine_executions")
            .select()
            .eq("id", value: executionId)
            .single()
            .execute()
            .value

        try await supabase
            .from("routine_executions")
            .update(["completed_steps": current.completedSteps + 1, "error_count": current.errorCount + errors, "stall_count": current.stallCount + stalls])
            .eq("id", value: executionId)
            .execute()
    }

    public func completeExecution(id: String) async throws {
        try await supabase
            .from("routine_executions")
            .update(["status": "completed", "completed_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Safety Zones

    public func fetchSafetyZones() async throws -> [SafetyZoneResponse] {
        let zones: [SafetyZoneRow] = try await supabase
            .from("safety_zones")
            .select()
            .execute()
            .value
        return zones.map { $0.toResponse() }
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

    public func createAlert(type: String, severity: String, title: String, message: String?) async throws {
        guard let userId = try? await supabase.auth.session.user.id else {
            throw APIError.notAuthenticated
        }
        let newAlert = NewAlert(userId: userId.uuidString, alertType: type, severity: severity, title: title, message: message)
        try await supabase
            .from("alerts")
            .insert(newAlert)
            .execute()
    }

    public func notifyFamilyMembers(alertType: String, title: String, message: String?) async throws {
        guard let userId = try? await supabase.auth.session.user.id else {
            throw APIError.notAuthenticated
        }
        // Fetch all active links where I'm the user (my caregivers/family)
        let links: [CaregiverLinkRow] = try await supabase
            .from("caregiver_links")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("status", value: "active")
            .execute()
            .value
        // Create alert for each linked caregiver/family member
        for link in links {
            let alert = NewAlert(
                userId: link.caregiverId,
                alertType: alertType,
                severity: "critical",
                title: title,
                message: message
            )
            try await supabase.from("alerts").insert(alert).execute()
        }
    }

    // MARK: - Medications

    public func fetchMedications() async throws -> [MedicationRow] {
        guard let userId = try? await supabase.auth.session.user.id else {
            throw APIError.notAuthenticated
        }
        let meds: [MedicationRow] = try await supabase
            .from("medications")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("hour", ascending: true)
            .execute()
            .value
        return meds
    }

    public func addMedication(name: String, dosage: String, hour: Int, minute: Int, reminderOffsets: [Int] = [5], bottleImageUrl: String? = nil, pillImageUrl: String? = nil) async throws {
        guard let userId = try? await supabase.auth.session.user.id else {
            throw APIError.notAuthenticated
        }
        var newMed = NewMedication(userId: userId.uuidString, name: name, dosage: dosage, hour: hour, minute: minute, reminderOffsets: reminderOffsets)
        newMed.bottleImageUrl = bottleImageUrl
        newMed.pillImageUrl = pillImageUrl
        try await supabase
            .from("medications")
            .insert(newMed)
            .execute()
    }

    public func uploadMedicationImage(data: Data, fileName: String) async throws -> String {
        guard let userId = try? await supabase.auth.session.user.id else {
            throw APIError.notAuthenticated
        }
        let path = "\(userId.uuidString)/\(fileName)"
        try await supabase.storage
            .from("medication-images")
            .upload(path, data: data, options: .init(contentType: "image/jpeg", upsert: true))
        let publicURL = try supabase.storage
            .from("medication-images")
            .getPublicURL(path: path)
        return publicURL.absoluteString
    }

    public func markMedicationTaken(id: String) async throws {
        try await supabase
            .from("medications")
            .update(["taken_today": true])
            .eq("id", value: id)
            .execute()
    }

    public func deleteMedication(id: String) async throws {
        try await supabase
            .from("medications")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Caregiver: Patient Medications

    public func fetchPatientMedications(patientId: String) async throws -> [MedicationRow] {
        let meds: [MedicationRow] = try await supabase
            .from("medications")
            .select()
            .eq("user_id", value: patientId)
            .order("hour", ascending: true)
            .execute()
            .value
        return meds
    }

    public func addPatientMedication(patientId: String, name: String, dosage: String, hour: Int, minute: Int, reminderOffsets: [Int] = [5], bottleImageUrl: String? = nil, pillImageUrl: String? = nil) async throws {
        var newMed = NewMedication(userId: patientId, name: name, dosage: dosage, hour: hour, minute: minute, reminderOffsets: reminderOffsets)
        newMed.bottleImageUrl = bottleImageUrl
        newMed.pillImageUrl = pillImageUrl
        try await supabase
            .from("medications")
            .insert(newMed)
            .execute()
    }

    // MARK: - Emergency Contacts (CRUD)

    public func addEmergencyContact(name: String, phone: String, relationship: String, isPrimary: Bool) async throws {
        guard let userId = try? await supabase.auth.session.user.id else {
            throw APIError.notAuthenticated
        }
        let contact = NewEmergencyContact(userId: userId.uuidString, name: name, phone: phone, relationship: relationship, isPrimary: isPrimary)
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

    public func setEmergencyContactPrimary(id: String) async throws {
        guard let userId = try? await supabase.auth.session.user.id else {
            throw APIError.notAuthenticated
        }
        // Unset all primaries first
        try await supabase
            .from("emergency_contacts")
            .update(["is_primary": false])
            .eq("user_id", value: userId.uuidString)
            .execute()
        // Set the chosen one
        try await supabase
            .from("emergency_contacts")
            .update(["is_primary": true])
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Doctor Appointments

    public func fetchAppointments() async throws -> [AppointmentRow] {
        guard let userId = try? await supabase.auth.session.user.id else {
            throw APIError.notAuthenticated
        }
        let rows: [AppointmentRow] = try await supabase
            .from("appointments")
            .select()
            .eq("user_id", value: userId.uuidString)
            .neq("status", value: "cancelled")
            .order("appointment_date", ascending: true)
            .execute()
            .value
        return rows
    }

    public func addAppointment(doctorName: String, specialty: String?, location: String?, notes: String?,
                               date: Date, isRecurring: Bool, recurringMonths: Int?) async throws {
        guard let userId = try? await supabase.auth.session.user.id else {
            throw APIError.notAuthenticated
        }
        let formatter = ISO8601DateFormatter()
        let newAppt = NewAppointment(
            userId: userId.uuidString,
            doctorName: doctorName,
            specialty: specialty,
            location: location,
            notes: notes,
            appointmentDate: formatter.string(from: date),
            isRecurring: isRecurring,
            recurringMonths: recurringMonths
        )
        try await supabase
            .from("appointments")
            .insert(newAppt)
            .execute()
    }

    public func deleteAppointment(id: String) async throws {
        try await supabase
            .from("appointments")
            .update(["status": "cancelled"])
            .eq("id", value: id)
            .execute()
    }

    public func completeAppointment(id: String) async throws {
        try await supabase
            .from("appointments")
            .update(["status": "completed"])
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Family / Caregiver Links

    public func fetchLinkedUsers() async throws -> [CaregiverLinkRow] {
        guard let userId = try? await supabase.auth.session.user.id else {
            throw APIError.notAuthenticated
        }
        // Get links where I'm the caregiver (I monitor patients)
        let asCaregiver: [CaregiverLinkRow] = try await supabase
            .from("caregiver_links")
            .select("*, profiles!caregiver_links_user_id_fkey(display_name, email, current_complexity, sensory_mode)")
            .eq("caregiver_id", value: userId.uuidString)
            .neq("status", value: "revoked")
            .execute()
            .value

        // Get links where I'm the user (caregivers monitoring me)
        let asUser: [CaregiverLinkRow] = try await supabase
            .from("caregiver_links")
            .select("*, profiles!caregiver_links_caregiver_id_fkey(display_name, email, current_complexity, sensory_mode)")
            .eq("user_id", value: userId.uuidString)
            .neq("status", value: "revoked")
            .execute()
            .value

        return asCaregiver + asUser
    }

    public func generateInviteCode() async throws -> String {
        guard let userId = try? await supabase.auth.session.user.id else {
            throw APIError.notAuthenticated
        }
        let charset = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        let code = String((0..<8).compactMap { _ in charset.randomElement() })
        let invite = NewCaregiverLink(
            userId: userId.uuidString,
            caregiverId: userId.uuidString, // placeholder, updated when accepted
            inviteCode: code,
            status: "pending"
        )
        try await supabase
            .from("caregiver_links")
            .insert(invite)
            .execute()
        return code
    }

    public func acceptInvite(code: String) async throws {
        guard let userId = try? await supabase.auth.session.user.id else {
            throw APIError.notAuthenticated
        }
        // Find the pending link with this code
        let links: [CaregiverLinkRow] = try await supabase
            .from("caregiver_links")
            .select()
            .eq("invite_code", value: code)
            .eq("status", value: "pending")
            .execute()
            .value

        guard let link = links.first else {
            throw APIError.notFound
        }

        // Update: set the caregiver_id to current user, activate link
        try await supabase
            .from("caregiver_links")
            .update(["caregiver_id": userId.uuidString, "status": "active"])
            .eq("id", value: link.id)
            .execute()
    }

    public func revokeLink(linkId: String) async throws {
        try await supabase
            .from("caregiver_links")
            .update(["status": "revoked"])
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

    public func fetchPatientExecutions(userId: String) async throws -> [ExecutionRow] {
        let executions: [ExecutionRow] = try await supabase
            .from("routine_executions")
            .select()
            .eq("user_id", value: userId)
            .order("started_at", ascending: false)
            .limit(20)
            .execute()
            .value
        return executions
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

    public func fetchPatientSafetyZones(userId: String) async throws -> [SafetyZoneRow] {
        let zones: [SafetyZoneRow] = try await supabase
            .from("safety_zones")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        return zones
    }
}

// MARK: - Supabase Row Types (snake_case mapping)

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

// MARK: - Caregiver Link Types

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

// MARK: - Medication Types

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
    public let bottleImageUrl: String?
    public let pillImageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, name, dosage, hour, minute
        case userId = "user_id"
        case takenToday = "taken_today"
        case isActive = "is_active"
        case reminderOffsets = "reminder_offsets"
        case bottleImageUrl = "bottle_image_url"
        case pillImageUrl = "pill_image_url"
    }
}

struct NewMedication: Codable {
    let userId: String
    let name: String
    let dosage: String
    let hour: Int
    let minute: Int
    let reminderOffsets: [Int]
    var bottleImageUrl: String?
    var pillImageUrl: String?

    enum CodingKeys: String, CodingKey {
        case name, dosage, hour, minute
        case userId = "user_id"
        case reminderOffsets = "reminder_offsets"
        case bottleImageUrl = "bottle_image_url"
        case pillImageUrl = "pill_image_url"
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

// MARK: - Doctor Appointment Types

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
