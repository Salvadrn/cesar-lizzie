import LocalAuthentication

@Observable
final class BiometricService {
    static let shared = BiometricService()

    private(set) var biometricType: LABiometryType = .none
    private(set) var isAvailable = false
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "biometric_lock_enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "biometric_lock_enabled") }
    }

    init() {
        checkAvailability()
    }

    func checkAvailability() {
        let context = LAContext()
        var error: NSError?
        isAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        biometricType = context.biometryType
    }

    var biometricName: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        @unknown default: return "Biometría"
        }
    }

    var biometricIcon: String {
        switch biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        @unknown default: return "lock.shield"
        }
    }

    /// Authenticate with biometrics. Returns true if authenticated or if biometric lock is disabled.
    @MainActor
    func authenticate(reason: String = "Verificar identidad para acceder a datos sensibles") async -> Bool {
        guard isEnabled, isAvailable else { return true }

        let context = LAContext()
        context.localizedCancelTitle = "Cancelar"

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
        } catch {
            // Fallback to device passcode
            do {
                return try await context.evaluatePolicy(
                    .deviceOwnerAuthentication,
                    localizedReason: reason
                )
            } catch {
                return false
            }
        }
    }
}
