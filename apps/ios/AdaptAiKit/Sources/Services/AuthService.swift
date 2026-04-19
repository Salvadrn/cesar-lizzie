import Foundation
import Supabase

@Observable
public final class AuthService {
    public static let shared = AuthService()

    public var userId: UUID?
    public var currentProfile: ProfileData?
    public var isGuestMode = false
    public var guestSelectedRole: AppConstants.UserRole = .patient
    public var guestSimpleMode = false

    public var isAuthenticated: Bool {
        userId != nil || isGuestMode
    }

    public var currentRole: AppConstants.UserRole {
        if isGuestMode { return guestSelectedRole }
        guard let role = currentProfile?.role else { return .guest }
        return AppConstants.UserRole(rawValue: role)
    }

    public var isGuest: Bool { currentRole == .guest }
    public var isPatient: Bool { currentRole == .patient }
    public var isCaregiver: Bool { currentRole == .caregiver || (currentProfile?.alsoCares == true) }
    public var isFamily: Bool { currentRole == .family }
    public var isPatientWithCaregiverAbilities: Bool { isPatient && (currentProfile?.alsoCares == true) }

    /// Modo simple activo: solo para pacientes (no cuidadores, no familia)
    public var isSimpleModeActive: Bool {
        guard isPatient else { return false }
        // Cuidadores (incluyendo alsoCares) no pueden usar modo simple
        if currentProfile?.alsoCares == true { return false }
        if isGuestMode { return guestSimpleMode }
        return currentProfile?.simpleMode == true
    }

    /// Activa/desactiva modo simple localmente para guest
    public func setGuestSimpleMode(_ enabled: Bool) {
        guard isGuestMode, isPatient else { return }
        guestSimpleMode = enabled
    }

    private let supabase = SupabaseManager.shared.client

    private init() {}

    // MARK: - Guest Mode

    public func signInAsGuest() {
        isGuestMode = true
        userId = nil
        currentProfile = nil
    }

    public func exitGuestMode() {
        isGuestMode = false
        guestSimpleMode = false
    }

    // MARK: - Apple Sign In

    public func signInWithApple(idToken: String, nonce: String) async throws {
        isGuestMode = false
        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
        userId = session.user.id
        await loadProfile()
    }

    // MARK: - Email / Password

    public func signInWithEmail(email: String, password: String) async throws {
        isGuestMode = false
        let session = try await supabase.auth.signIn(
            email: email,
            password: password
        )
        userId = session.user.id
        await loadProfile()
    }

    public func signUpWithEmail(email: String, password: String, displayName: String) async throws {
        isGuestMode = false
        let response = try await supabase.auth.signUp(
            email: email,
            password: password,
            data: ["display_name": .string(displayName)]
        )
        userId = response.user.id

        // Try immediate sign-in (works if email confirmation is disabled)
        do {
            _ = try await supabase.auth.signIn(email: email, password: password)
        } catch {
            // Email confirmation required — throw clear error
            throw APIError.serverError("Revisa tu correo electrónico para confirmar tu cuenta antes de iniciar sesión.")
        }

        // Create profile row (only if we have an active session)
        let profile = ProfileData(
            id: response.user.id.uuidString,
            displayName: displayName,
            email: email,
            role: "patient"
        )
        try? await supabase
            .from("profiles")
            .upsert(profile)
            .execute()
        await loadProfile()
    }

    public func resetPassword(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email)
    }

    public func restoreSession() async {
        do {
            let session = try await supabase.auth.session
            userId = session.user.id
            isGuestMode = false
            await loadProfile()
        } catch {
            userId = nil
            currentProfile = nil
        }
    }

    public func logout() async throws {
        try await supabase.auth.signOut()
        userId = nil
        currentProfile = nil
        isGuestMode = false
    }

    private func loadProfile() async {
        guard let uid = userId else { return }
        do {
            let profile: ProfileData = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: uid.uuidString)
                .single()
                .execute()
                .value
            currentProfile = profile
        } catch {
            print("Failed to load profile: \(error)")
        }
    }
}

public struct ProfileData: Codable, Sendable {
    public let id: String
    public var displayName: String
    public var email: String?
    public var role: String
    public var currentComplexity: Int
    public var complexityFloor: Int
    public var complexityCeiling: Int
    public var sensoryMode: String
    public var preferredInput: String
    public var hapticEnabled: Bool
    public var audioEnabled: Bool
    public var fontScale: Double
    public var lostModeName: String?
    public var lostModeAddress: String?
    public var lostModePhone: String?
    public var lostModePhotoUrl: String?
    public var totalSessions: Int
    public var totalErrors: Int
    public var avgResponseTime: Double
    public var lastSessionAt: String?
    public var simpleMode: Bool
    public var alsoCares: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case email, role
        case currentComplexity = "current_complexity"
        case complexityFloor = "complexity_floor"
        case complexityCeiling = "complexity_ceiling"
        case sensoryMode = "sensory_mode"
        case preferredInput = "preferred_input"
        case hapticEnabled = "haptic_enabled"
        case audioEnabled = "audio_enabled"
        case fontScale = "font_scale"
        case lostModeName = "lost_mode_name"
        case lostModeAddress = "lost_mode_address"
        case lostModePhone = "lost_mode_phone"
        case lostModePhotoUrl = "lost_mode_photo_url"
        case totalSessions = "total_sessions"
        case totalErrors = "total_errors"
        case avgResponseTime = "avg_response_time"
        case lastSessionAt = "last_session_at"
        case simpleMode = "simple_mode"
        case alsoCares = "also_cares"
    }

    public init(id: String, displayName: String = "", email: String? = nil, role: String = "patient",
                currentComplexity: Int = 3, complexityFloor: Int = 1, complexityCeiling: Int = 5,
                sensoryMode: String = "default", preferredInput: String = "touch",
                hapticEnabled: Bool = true, audioEnabled: Bool = true, fontScale: Double = 1.0,
                lostModeName: String? = nil, lostModeAddress: String? = nil,
                lostModePhone: String? = nil, lostModePhotoUrl: String? = nil,
                totalSessions: Int = 0, totalErrors: Int = 0, avgResponseTime: Double = 0,
                lastSessionAt: String? = nil, simpleMode: Bool = false, alsoCares: Bool = false) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.role = role
        self.currentComplexity = currentComplexity
        self.complexityFloor = complexityFloor
        self.complexityCeiling = complexityCeiling
        self.sensoryMode = sensoryMode
        self.preferredInput = preferredInput
        self.hapticEnabled = hapticEnabled
        self.audioEnabled = audioEnabled
        self.fontScale = fontScale
        self.lostModeName = lostModeName
        self.lostModeAddress = lostModeAddress
        self.lostModePhone = lostModePhone
        self.lostModePhotoUrl = lostModePhotoUrl
        self.totalSessions = totalSessions
        self.totalErrors = totalErrors
        self.avgResponseTime = avgResponseTime
        self.lastSessionAt = lastSessionAt
        self.simpleMode = simpleMode
        self.alsoCares = alsoCares
    }
}
