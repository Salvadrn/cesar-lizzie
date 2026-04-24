import SwiftUI
import AuthenticationServices
import AdaptAiKit

/// Login screen with Soulspring-inspired aesthetics:
/// warm gradient canvas, shape-first layout (cards, pills, circular badges),
/// rounded numbers, eyebrows in small caps, haptic feedback on all taps.
struct LoginView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var appleVM = AppleSignInViewModel()
    @State private var showRoleOptions = false
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var emailError: String?
    @State private var isLoadingEmail = false

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        ZStack(alignment: .top) {
            AdaptBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AdaptTheme.Spacing.lg) {
                    hero
                    authCard
                    guestSection
                    privacyFootnote
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(AdaptTheme.Gradient.primary)
                    .frame(width: 88, height: 88)
                    .shadow(color: AdaptTheme.Palette.primary.opacity(0.4), radius: 18, y: 8)

                Image(systemName: "location.north.circle.fill")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    Text("Adapt")
                        .foregroundStyle(AdaptTheme.Color.textPrimary)
                    Text("Ai")
                        .foregroundStyle(AdaptTheme.Palette.gold)
                }
                .font(AdaptTheme.Font.hero)

                Text("Tu asistente adaptativo\npara la vida diaria")
                    .font(AdaptTheme.Font.body(15, weight: .regular))
                    .foregroundStyle(AdaptTheme.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
    }

    // MARK: - Auth card

    private var authCard: some View {
        VStack(spacing: 14) {
            appleButton

            dividerWithLabel

            emailFormSection
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: AdaptTheme.Radius.lg, style: .continuous)
                .fill(AdaptTheme.Color.surface)
                .shadow(color: .black.opacity(isDark ? 0 : 0.06), radius: 20, y: 8)
        )
    }

    private var appleButton: some View {
        VStack(spacing: 6) {
            SignInWithAppleButton(.signIn) { request in
                AdaptHaptics.tap()
                appleVM.handleSignInRequest(request)
            } onCompletion: { result in
                Task {
                    await appleVM.handleSignInCompletion(result, authService: authService)
                }
            }
            .signInWithAppleButtonStyle(isDark ? .white : .black)
            .frame(height: 52)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(isDark ? 0.4 : 0.15), radius: 6, y: 3)

            if appleVM.isLoading {
                HStack(spacing: 6) {
                    ProgressView().scaleEffect(0.8)
                    Text("Iniciando sesión...")
                        .font(AdaptTheme.Font.caption)
                        .foregroundStyle(AdaptTheme.Color.textSecondary)
                }
            }

            if let err = appleVM.errorMessage {
                Text(err)
                    .font(AdaptTheme.Font.caption)
                    .foregroundStyle(AdaptTheme.Palette.error)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var dividerWithLabel: some View {
        HStack(spacing: 10) {
            Rectangle().fill(AdaptTheme.Color.divider).frame(height: 1)
            Text("o continúa con correo")
                .font(AdaptTheme.Font.caption)
                .foregroundStyle(AdaptTheme.Color.textTertiary)
            Rectangle().fill(AdaptTheme.Color.divider).frame(height: 1)
        }
    }

    // MARK: - Email form

    private var emailFormSection: some View {
        VStack(spacing: 12) {
            modeTabSelector

            if isSignUp {
                pillTextField(icon: "person.fill", placeholder: "Nombre", text: $displayName)
                    .textContentType(.name)
            }

            pillTextField(icon: "envelope.fill", placeholder: "Correo", text: $email)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()

            pillTextField(icon: "lock.fill", placeholder: "Contraseña", text: $password, secure: true)
                .textContentType(isSignUp ? .newPassword : .password)

            if let err = emailError {
                Text(err)
                    .font(AdaptTheme.Font.caption)
                    .foregroundStyle(AdaptTheme.Palette.error)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            Button {
                Task { await handleEmailAuth() }
            } label: {
                if isLoadingEmail {
                    ProgressView().tint(.white)
                } else {
                    Text(isSignUp ? "Crear cuenta" : "Iniciar sesión")
                }
            }
            .buttonStyle(AdaptPrimaryButtonStyle())
            .disabled(isLoadingEmail || email.isEmpty || password.isEmpty || (isSignUp && displayName.isEmpty))
            .opacity((isLoadingEmail || email.isEmpty || password.isEmpty || (isSignUp && displayName.isEmpty)) ? 0.5 : 1)

            if !isSignUp {
                Button {
                    Task { await handleForgotPassword() }
                } label: {
                    Text("¿Olvidaste tu contraseña?")
                        .font(AdaptTheme.Font.caption)
                        .foregroundStyle(AdaptTheme.Palette.primary)
                }
                .padding(.top, 2)
            }
        }
    }

    private var modeTabSelector: some View {
        HStack(spacing: 4) {
            modeTab(title: "Iniciar sesión", active: !isSignUp) {
                withAnimation { isSignUp = false; emailError = nil }
                AdaptHaptics.select()
            }
            modeTab(title: "Crear cuenta", active: isSignUp) {
                withAnimation { isSignUp = true; emailError = nil }
                AdaptHaptics.select()
            }
        }
        .padding(4)
        .background(Capsule().fill(AdaptTheme.Color.surfaceElevated))
    }

    private func modeTab(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AdaptTheme.Font.body(14, weight: active ? .bold : .regular))
                .foregroundStyle(active ? .white : AdaptTheme.Color.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    Capsule()
                        .fill(active ? AnyShapeStyle(AdaptTheme.Gradient.primary) : AnyShapeStyle(Color.clear))
                )
        }
        .buttonStyle(.plain)
    }

    private func pillTextField(icon: String, placeholder: String, text: Binding<String>, secure: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AdaptTheme.Palette.primary)
                .frame(width: 20)

            Group {
                if secure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                }
            }
            .font(AdaptTheme.Font.bodyText)
            .foregroundStyle(AdaptTheme.Color.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(
            Capsule().fill(AdaptTheme.Color.surfaceElevated)
        )
    }

    // MARK: - Guest section

    private var guestSection: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showRoleOptions.toggle()
                    AdaptHaptics.tap()
                }
            } label: {
                HStack(spacing: 6) {
                    Text("Explorar sin cuenta")
                    Image(systemName: showRoleOptions ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
                .font(AdaptTheme.Font.body(14, weight: .semibold))
                .foregroundStyle(AdaptTheme.Palette.primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(AdaptTheme.Palette.primary.opacity(0.1))
                )
            }
            .buttonStyle(.plain)

            if showRoleOptions {
                HStack(spacing: 10) {
                    guestRoleChip(title: "Paciente", icon: "person.fill", color: AdaptTheme.Palette.primary, role: .patient)
                    guestRoleChip(title: "Cuidador", icon: "heart.fill", color: AdaptTheme.Palette.caregiver, role: .caregiver)
                    guestRoleChip(title: "Familiar", icon: "person.2.fill", color: AdaptTheme.Palette.family, role: .family)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }

    private func guestRoleChip(title: String, icon: String, color: Color, role: AppConstants.UserRole) -> some View {
        Button {
            AdaptHaptics.tap()
            authService.guestSelectedRole = role
            authService.signInAsGuest()
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle().fill(color.opacity(0.2)).frame(width: 40, height: 40)
                    Image(systemName: icon).font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(color)
                Text(title)
                    .font(AdaptTheme.Font.caption)
                    .foregroundStyle(AdaptTheme.Color.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: AdaptTheme.Radius.md, style: .continuous)
                    .fill(AdaptTheme.Color.surface)
            )
        }
        .buttonStyle(.plain)
    }

    private var privacyFootnote: some View {
        HStack(spacing: 5) {
            Image(systemName: "lock.shield.fill").font(.system(size: 10))
            Text("Protegido con Apple")
        }
        .font(AdaptTheme.Font.body(11, weight: .medium))
        .foregroundStyle(AdaptTheme.Color.textTertiary)
    }

    // MARK: - Actions

    private func handleEmailAuth() async {
        emailError = nil
        isLoadingEmail = true
        defer { isLoadingEmail = false }
        do {
            if isSignUp {
                if let err = validatePasswordStrength(password) {
                    emailError = err
                    return
                }
                try await authService.signUpWithEmail(email: email, password: password, displayName: displayName)
                AdaptHaptics.success()
            } else {
                try await authService.signInWithEmail(email: email, password: password)
                AdaptHaptics.success()
            }
        } catch {
            emailError = parseAuthError(error)
            AdaptHaptics.fire(.error)
        }
    }

    private func validatePasswordStrength(_ password: String) -> String? {
        if password.count < 8 { return "La contraseña debe tener al menos 8 caracteres" }
        if password.range(of: "[A-Z]", options: .regularExpression) == nil { return "Incluye una letra mayúscula" }
        if password.range(of: "[a-z]", options: .regularExpression) == nil { return "Incluye una letra minúscula" }
        if password.range(of: "[0-9]", options: .regularExpression) == nil { return "Incluye un número" }
        return nil
    }

    private func handleForgotPassword() async {
        guard !email.isEmpty else {
            emailError = "Ingresa tu correo primero"
            return
        }
        do {
            try await authService.resetPassword(email: email)
            emailError = "Revisa tu correo para restablecer la contraseña"
        } catch {
            emailError = parseAuthError(error)
        }
    }

    private func parseAuthError(_ error: Error) -> String {
        let msg = error.localizedDescription.lowercased()
        if msg.contains("invalid") && msg.contains("credentials") { return "Correo o contraseña incorrectos" }
        if msg.contains("already registered") || msg.contains("already exists") { return "Este correo ya está registrado" }
        if msg.contains("invalid email") { return "Correo no válido" }
        return error.localizedDescription
    }
}
