import SwiftUI
import NeuroNavKit

struct LoginView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel = EmailAuthViewModel()
    @State private var showRoleOptions = false
    @FocusState private var focusedField: Field?

    private enum Field { case email, password, confirm }

    private var isDark: Bool { colorScheme == .dark }
    private let hPad: CGFloat = 32

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                heroSection
                featuresGrid
                emailAuthSection
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

    // MARK: - Email Auth

    private var emailAuthSection: some View {
        VStack(spacing: 16) {
            // Email field
            VStack(alignment: .leading, spacing: 6) {
                Text("Correo electrónico")
                    .font(.nnCaption)
                    .foregroundStyle(.nnMidGray)

                HStack(spacing: 10) {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(.nnMidGray)
                        .font(.subheadline)
                    TextField("tu@correo.com", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .email)
                }
                .padding(14)
                .background(isDark ? Color(.systemGray5) : .white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focusedField == .email ? Color.nnPrimary : Color.nnRule, lineWidth: 1)
                )
            }

            // Password field
            VStack(alignment: .leading, spacing: 6) {
                Text("Contraseña")
                    .font(.nnCaption)
                    .foregroundStyle(.nnMidGray)

                HStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.nnMidGray)
                        .font(.subheadline)
                    SecureField("Mínimo 6 caracteres", text: $viewModel.password)
                        .textContentType(viewModel.isSignUpMode ? .newPassword : .password)
                        .focused($focusedField, equals: .password)
                }
                .padding(14)
                .background(isDark ? Color(.systemGray5) : .white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focusedField == .password ? Color.nnPrimary : Color.nnRule, lineWidth: 1)
                )
            }

            // Confirm password (sign up only)
            if viewModel.isSignUpMode {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Confirmar contraseña")
                        .font(.nnCaption)
                        .foregroundStyle(.nnMidGray)

                    HStack(spacing: 10) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.nnMidGray)
                            .font(.subheadline)
                        SecureField("Repite tu contraseña", text: $viewModel.confirmPassword)
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .confirm)
                    }
                    .padding(14)
                    .background(isDark ? Color(.systemGray5) : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(focusedField == .confirm ? Color.nnPrimary : Color.nnRule, lineWidth: 1)
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.nnError)
                    .font(.nnCaption)
                    .multilineTextAlignment(.center)
            }

            // Main action button
            Button {
                focusedField = nil
                Task {
                    if viewModel.isSignUpMode {
                        await viewModel.signUp(authService: authService)
                    } else {
                        await viewModel.signIn(authService: authService)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(viewModel.isSignUpMode ? "Crear cuenta" : "Iniciar sesión")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(viewModel.isFormValid ? Color.nnPrimary : Color.nnMidGray)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!viewModel.isFormValid || viewModel.isLoading)

            // Toggle sign in / sign up
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.toggleMode()
                }
            } label: {
                Text(viewModel.isSignUpMode
                     ? "¿Ya tienes cuenta? Inicia sesión"
                     : "¿No tienes cuenta? Regístrate")
                    .font(.nnFootnote)
                    .foregroundStyle(.nnPrimary)
            }

            // Divider
            HStack {
                Rectangle().fill(Color.nnRule).frame(height: 1)
                Text("o")
                    .font(.nnCaption)
                    .foregroundStyle(.nnMidGray)
                Rectangle().fill(Color.nnRule).frame(height: 1)
            }

            // Guest mode
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
                Text("Conexión segura con Supabase")
                    .font(.nnCaption2)
            }
            .foregroundStyle(.nnMidGray)
            .padding(.top, 2)
        }
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
