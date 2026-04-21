import Foundation
import NeuroNavKit

@Observable
class EmailAuthViewModel {
    var email = ""
    var password = ""
    var confirmPassword = ""
    var isLoading = false
    var errorMessage: String?
    var isSignUpMode = false

    var isFormValid: Bool {
        let emailValid = email.contains("@") && email.contains(".")
        let passwordValid = password.count >= 8
        if isSignUpMode {
            return emailValid && passwordValid && password == confirmPassword
        }
        return emailValid && passwordValid
    }

    @MainActor
    func signIn(authService: AuthService) async {
        guard isFormValid else {
            errorMessage = "Revisa tu correo y contraseña"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.signInWithEmail(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                password: password
            )
        } catch {
            errorMessage = "Error al iniciar sesión: \(error.localizedDescription)"
        }

        isLoading = false
    }

    @MainActor
    func signUp(authService: AuthService) async {
        guard isFormValid else {
            if password != confirmPassword {
                errorMessage = "Las contraseñas no coinciden"
            } else {
                errorMessage = "Revisa tu correo y contraseña (mínimo 8 caracteres)"
            }
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.signUpWithEmail(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                password: password
            )
        } catch {
            errorMessage = "Error al crear cuenta: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func toggleMode() {
        isSignUpMode.toggle()
        errorMessage = nil
        confirmPassword = ""
    }
}
