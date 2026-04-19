import SwiftUI
import AdaptAiKit

struct LoginView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme
    @State private var showRoleOptions = false
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var emailError: String?
    @State private var isLoadingEmail = false
    @State private var isLoadingGoogle = false
    @State private var googleError: String?

    private var isDark: Bool { colorScheme == .dark }
    private let hPad: CGFloat = 32

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                heroSection
                featuresGrid
                authSection
            }
            .padding(.horizontal, hPad)
            .padding(.top, 72)
            .padding(.bottom, 40)
        }
        .background(
            LinearGradient(
                colors: isDark
                    ? [Color.nnNightBG, Color.nnNightBG]
                    : [Color.nnLightBG, .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.nnPrimary.opacity(isDark ? 0.2 : 0.1))
                    .frame(width: 88, height: 88)

                Image(systemName: "location.north.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.nnPrimary)
            }

            HStack(spacing: 0) {
                Text("Adapt")
                    .foregroundStyle(isDark ? .white : .nnDarkText)
                Text("Ai")
                    .foregroundStyle(.nnGold)
            }
            .font(.nnDisplay)

            Text("Tu asistente adaptativo\npara la vida diaria")
                .font(.nnSubheadline)
                .foregroundStyle(.nnMidGray)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Features

    private var featuresGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ], spacing: 10) {
            featureCard(icon: "list.clipboard.fill", title: "Rutinas", color: .nnPrimary)
            featureCard(icon: "pill.fill", title: "Medicamentos", color: .nnSuccess)
            featureCard(icon: "person.3.fill", title: "Familia", color: .nnFamily)
            featureCard(icon: "sos", title: "Emergencia", color: .nnError)
        }
    }

    private func featureCard(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(color)

            Text(title)
                .font(.nnFootnote)
                .foregroundStyle(isDark ? .white : .nnDarkText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isDark ? Color.white.opacity(0.08) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(isDark ? 0 : 0.04), radius: 4, y: 2)
    }

    // MARK: - Auth

    private var authSection: some View {
        VStack(spacing: 14) {
            googleSignInButton

            HStack {
                Rectangle().fill(Color.nnMidGray.opacity(0.3)).frame(height: 1)
                Text("o")
                    .font(.nnCaption)
                    .foregroundStyle(.nnMidGray)
                Rectangle().fill(Color.nnMidGray.opacity(0.3)).frame(height: 1)
            }
            .padding(.vertical, 4)

            emailFormSection

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showRoleOptions.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Text("Explorar sin cuenta")
                    Image(systemName: showRoleOptions ? "chevron.up" : "chevron.down")
                        .font(.nnCaption2)
                }
                .font(.nnFootnote)
                .foregroundStyle(.nnPrimary)
            }

            if showRoleOptions {
                HStack(spacing: 8) {
                    guestRoleChip(title: "Paciente", icon: "person.fill", color: .nnPrimary, role: .patient)
                    guestRoleChip(title: "Cuidador", icon: "heart.fill", color: .nnCaregiver, role: .caregiver)
                    guestRoleChip(title: "Familiar", icon: "person.2.fill", color: .nnWarning, role: .family)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            HStack(spacing: 4) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 9))
                Text("Tus datos están protegidos")
                    .font(.nnCaption2)
            }
            .foregroundStyle(.nnMidGray)
            .padding(.top, 2)
        }
    }

    // MARK: - Google Sign In

    private var googleSignInButton: some View {
        VStack(spacing: 8) {
            Button {
                Task { await handleGoogleSignIn() }
            } label: {
                HStack(spacing: 10) {
                    if isLoadingGoogle {
                        ProgressView()
                            .tint(isDark ? .white : .nnDarkText)
                    } else {
                        GoogleLogo()
                            .frame(width: 18, height: 18)
                        Text("Continuar con Google")
                            .font(.nnBody.weight(.medium))
                    }
                }
                .foregroundStyle(isDark ? .white : .nnDarkText)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isDark ? Color.white.opacity(0.1) : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isDark ? Color.white.opacity(0.2) : Color.nnMidGray.opacity(0.3), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isLoadingGoogle)

            if let err = googleError {
                Text(err)
                    .font(.nnCaption)
                    .foregroundStyle(.nnError)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func handleGoogleSignIn() async {
        googleError = nil
        isLoadingGoogle = true
        defer { isLoadingGoogle = false }

        do {
            try await GoogleSignInService.shared.signIn(authService: authService)
        } catch {
            // User-cancelled flow is not an error we should show
            let nsError = error as NSError
            if nsError.domain == "com.apple.AuthenticationServices.WebAuthenticationSession" && nsError.code == 1 {
                return
            }
            googleError = error.localizedDescription
        }
    }

    // MARK: - Email Form

    private var emailFormSection: some View {
        VStack(spacing: 10) {
            // Toggle Sign In / Sign Up
            HStack(spacing: 0) {
                emailModeTab(title: "Iniciar sesión", isActive: !isSignUp) {
                    withAnimation { isSignUp = false; emailError = nil }
                }
                emailModeTab(title: "Crear cuenta", isActive: isSignUp) {
                    withAnimation { isSignUp = true; emailError = nil }
                }
            }
            .background(isDark ? Color.white.opacity(0.08) : Color.nnLightBG)
            .clipShape(RoundedRectangle(cornerRadius: 10))

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
                    .font(.nnCaption)
                    .foregroundStyle(.nnError)
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
                            .font(.nnBody.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.nnPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isLoadingEmail || email.isEmpty || password.isEmpty || (isSignUp && displayName.isEmpty))
            .opacity((isLoadingEmail || email.isEmpty || password.isEmpty || (isSignUp && displayName.isEmpty)) ? 0.5 : 1)

            if !isSignUp {
                Button {
                    Task { await handleForgotPassword() }
                } label: {
                    Text("¿Olvidaste tu contraseña?")
                        .font(.nnCaption)
                        .foregroundStyle(.nnPrimary)
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(isDark ? Color.white.opacity(0.04) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(isDark ? 0 : 0.04), radius: 8, y: 2)
    }

    private func emailModeTab(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.nnFootnote.weight(isActive ? .semibold : .regular))
                .foregroundStyle(isActive ? .nnPrimary : .nnMidGray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isActive ? (isDark ? Color.nnPrimary.opacity(0.2) : .white) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(3)
    }

    private func emailField(icon: String, placeholder: String, text: Binding<String>, secure: Bool = false) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.nnMidGray)
                .frame(width: 18)
            if secure {
                SecureField(placeholder, text: text)
                    .font(.nnBody)
            } else {
                TextField(placeholder, text: text)
                    .font(.nnBody)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(isDark ? Color.white.opacity(0.06) : Color.nnLightBG)
        .clipShape(RoundedRectangle(cornerRadius: 10))
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

    /// Enforces: 8+ chars, at least one uppercase letter, one lowercase letter, and one digit.
    private func validatePasswordStrength(_ password: String) -> String? {
        if password.count < 8 {
            return "La contraseña debe tener al menos 8 caracteres"
        }
        if password.range(of: "[A-Z]", options: .regularExpression) == nil {
            return "Debe incluir al menos una letra mayúscula"
        }
        if password.range(of: "[a-z]", options: .regularExpression) == nil {
            return "Debe incluir al menos una letra minúscula"
        }
        if password.range(of: "[0-9]", options: .regularExpression) == nil {
            return "Debe incluir al menos un número"
        }
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
        if msg.contains("invalid") && msg.contains("credentials") {
            return "Correo o contraseña incorrectos"
        }
        if msg.contains("already registered") || msg.contains("already exists") {
            return "Este correo ya está registrado"
        }
        if msg.contains("invalid email") {
            return "Correo no válido"
        }
        return error.localizedDescription
    }

    private func guestRoleChip(title: String, icon: String, color: Color, role: AppConstants.UserRole) -> some View {
        Button {
            authService.guestSelectedRole = role
            authService.signInAsGuest()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.nnCaption)
                    .lineLimit(1)
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(color.opacity(isDark ? 0.15 : 0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Google Logo (multicolor "G")

private struct GoogleLogo: View {
    var body: some View {
        ZStack {
            // Blue right stroke
            Path { path in
                path.addArc(center: CGPoint(x: 9, y: 9), radius: 7,
                            startAngle: .degrees(-60), endAngle: .degrees(60), clockwise: false)
            }
            .stroke(Color(red: 0.26, green: 0.52, blue: 0.96), lineWidth: 3)

            // Green bottom stroke
            Path { path in
                path.addArc(center: CGPoint(x: 9, y: 9), radius: 7,
                            startAngle: .degrees(60), endAngle: .degrees(180), clockwise: false)
            }
            .stroke(Color(red: 0.20, green: 0.66, blue: 0.33), lineWidth: 3)

            // Yellow left stroke
            Path { path in
                path.addArc(center: CGPoint(x: 9, y: 9), radius: 7,
                            startAngle: .degrees(180), endAngle: .degrees(240), clockwise: false)
            }
            .stroke(Color(red: 0.98, green: 0.74, blue: 0.02), lineWidth: 3)

            // Red top stroke
            Path { path in
                path.addArc(center: CGPoint(x: 9, y: 9), radius: 7,
                            startAngle: .degrees(240), endAngle: .degrees(300), clockwise: false)
            }
            .stroke(Color(red: 0.92, green: 0.26, blue: 0.21), lineWidth: 3)

            // Blue horizontal bar (the cross of the G)
            Rectangle()
                .fill(Color(red: 0.26, green: 0.52, blue: 0.96))
                .frame(width: 5, height: 2.5)
                .offset(x: 2.5, y: 0)
        }
    }
}
