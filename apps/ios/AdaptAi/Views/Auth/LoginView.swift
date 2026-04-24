import SwiftUI
import AuthenticationServices
import AdaptAiKit

/// Welcoming login screen with Soulspring-inspired UI:
/// warm gradient background, pill-shaped buttons, soft card feel.
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
                VStack(spacing: 24) {
                    heroSection
                    featuresGrid
                    authCard
                    guestSection
                    privacyFootnote
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 18) {
            // Brand logo circle
            ZStack {
                Circle()
                    .fill(AdaptTheme.Gradient.primary)
                    .frame(width: 92, height: 92)
                    .shadow(color: AdaptTheme.Palette.primary.opacity(0.35), radius: 20, y: 8)

                Image(systemName: "location.north.circle.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 6) {
                HStack(spacing: 0) {
                    Text("Adapt")
                        .foregroundStyle(AdaptTheme.Color.textPrimary)
                    Text("Ai")
                        .foregroundStyle(AdaptTheme.Palette.gold)
                }
                .font(.system(size: 42, weight: .bold))

                Text("Tu asistente adaptativo\npara la vida diaria")
                    .font(AdaptTheme.Font.body(15, weight: .regular))
                    .foregroundStyle(AdaptTheme.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Features (soft chips)

    private var featuresGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10),
        ], spacing: 10) {
            featureChip(icon: "list.clipboard.fill", title: "Rutinas", tint: AdaptTheme.Palette.primary)
            featureChip(icon: "pill.fill", title: "Medicamentos", tint: AdaptTheme.Palette.success)
            featureChip(icon: "person.3.fill", title: "Familia", tint: AdaptTheme.Palette.family)
            featureChip(icon: "sos", title: "Emergencia", tint: AdaptTheme.Palette.error)
        }
    }

    private func featureChip(icon: String, title: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(tint.opacity(0.18)).frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint)
            }
            Text(title)
                .font(AdaptTheme.Font.body(14, weight: .semibold))
                .foregroundStyle(AdaptTheme.Color.textPrimary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: AdaptTheme.Radius.sm, style: .continuous)
                .fill(AdaptTheme.Color.surface)
        )
    }

    // MARK: - Auth card (Apple + email form)

    private var authCard: some View {
        VStack(spacing: 12) {
            appleSignInButton

            dividerWithLabel

            emailFormSection
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: AdaptTheme.Radius.lg, style: .continuous)
                .fill(AdaptTheme.Color.surface)
        )
    }

    private var appleSignInButton: some View {
        VStack(spacing: 8) {
            SignInWithAppleButton(.signIn) { request in
                appleVM.handleSignInRequest(request)
            } onCompletion: { result in
                Task {
                    await appleVM.handleSignInCompletion(result, authService: authService)
                }
            }
            .signInWithAppleButtonStyle(isDark ? .white : .black)
            .frame(height: 50)
            .clipShape(Capsule())

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
            Text("o")
                .font(AdaptTheme.Font.caption)
                .foregroundStyle(AdaptTheme.Color.textTertiary)
            Rectangle().fill(AdaptTheme.Color.divider).frame(height: 1)
        }
    }

    // MARK: - Email form

    private var emailFormSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                emailModeTab(title: "Iniciar sesión", isActive: !isSignUp) {
                    withAnimation { isSignUp = false; emailError = nil }
                }
                emailModeTab(title: "Crear cuenta", isActive: isSignUp) {
                    withAnimation { isSignUp = true; emailError = nil }
                }
            }
            .padding(3)
            .background(
                Capsule().fill(AdaptTheme.Color.surfaceElevated)
            )

            if isSignUp {
                emailField(icon: "person.fill", placeholder: "Nombre", text: $displayName)
                    .textContentType(.name)
            }

            emailField(icon: "envelope.fill", placeholder: "Correo", text: $email)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()

            emailField(icon: "lock.fill", placeholder: "Contraseña", text: $password, secure: true)
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
                ZStack {
                    if isLoadingEmail {
                        ProgressView().tint(.white)
                    } else {
                        Text(isSignUp ? "Crear cuenta" : "Iniciar sesión")
                            .font(AdaptTheme.Font.body(16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule().fill(AdaptTheme.Gradient.primary)
                )
            }
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
                .padding(.top, 4)
            }
        }
    }

    private func emailModeTab(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AdaptTheme.Font.body(14, weight: isActive ? .semibold : .regular))
                .foregroundStyle(isActive ? AdaptTheme.Color.textPrimary : AdaptTheme.Color.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(isActive ? AdaptTheme.Color.surface : Color.clear)
                )
        }
    }

    private func emailField(icon: String, placeholder: String, text: Binding<String>, secure: Bool = false) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(AdaptTheme.Color.textTertiary)
                .frame(width: 18)
            Group {
                if secure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                }
            }
            .font(AdaptTheme.Font.bodyText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            Capsule().fill(AdaptTheme.Color.surfaceElevated)
        )
    }

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
            } else {
                try await authService.signInWithEmail(email: email, password: password)
            }
        } catch {
            emailError = parseAuthError(error)
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

    // MARK: - Guest section

    private var guestSection: some View {
        VStack(spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showRoleOptions.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Text("Explorar sin cuenta")
                    Image(systemName: showRoleOptions ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
                .font(AdaptTheme.Font.body(14, weight: .medium))
                .foregroundStyle(AdaptTheme.Palette.primary)
            }

            if showRoleOptions {
                HStack(spacing: 8) {
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
            authService.guestSelectedRole = role
            authService.signInAsGuest()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 18))
                Text(title).font(AdaptTheme.Font.caption)
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: AdaptTheme.Radius.md, style: .continuous)
                    .fill(color.opacity(0.12))
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
}

