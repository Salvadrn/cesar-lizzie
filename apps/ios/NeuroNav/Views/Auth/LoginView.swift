import SwiftUI
import NeuroNavKit
import AuthenticationServices

struct LoginView: View {
    @Environment(AuthService.self) private var authService
    @StateObject private var viewModel = AppleSignInViewModel()
    @State private var showRoleOptions = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                featuresSection
                adaptiveSection
                authSection
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.05, green: 0.25, blue: 0.23)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 16) {
                Spacer().frame(height: 60)

                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 90))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 5)

                Text("NeuroNav")
                    .font(.nnDisplay)
                    .foregroundStyle(.white)

                Text("Tu asistente adaptativo\npara la vida diaria")
                    .font(.nnTitle3)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 24)
        }
        .frame(minHeight: 340)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(spacing: 12) {
            Text("Todo lo que necesitas")
                .font(.nnTitle2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)

            FeatureCard(
                icon: "list.bullet.clipboard.fill",
                title: "Rutinas guiadas",
                description: "Sigue pasos claros para tus actividades diarias, con audio y temporizadores",
                color: Color(red: 0.145, green: 0.388, blue: 0.922)
            )

            FeatureCard(
                icon: "pills.fill",
                title: "Recordatorios de medicamentos",
                description: "Recibe alertas para tomar tus medicamentos a tiempo",
                color: Color(red: 0.051, green: 0.580, blue: 0.533)
            )

            FeatureCard(
                icon: "person.2.fill",
                title: "Red de apoyo",
                description: "Conecta con tu familia y cuidadores para que te acompañen",
                color: Color(red: 0.486, green: 0.227, blue: 0.929)
            )

            FeatureCard(
                icon: "sos.circle.fill",
                title: "Seguridad",
                description: "Botón de emergencia, detección de caídas y modo perdido",
                color: .red
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
    }

    // MARK: - Adaptive Intelligence

    private var adaptiveSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Image(systemName: "brain.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(colors: [Color(red: 0.08, green: 0.08, blue: 0.12), Color(red: 0.05, green: 0.25, blue: 0.23)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 60, height: 60)
                    .background(Color(red: 0.051, green: 0.580, blue: 0.533).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Se adapta a ti")
                        .font(.nnHeadline)
                    Text("La interfaz se ajusta a tu nivel de comodidad")
                        .font(.nnSubheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { level in
                    VStack(spacing: 6) {
                        Circle()
                            .fill(colorForLevel(level))
                            .frame(width: level == 3 ? 18 : 12, height: level == 3 ? 18 : 12)
                            .overlay {
                                if level == 3 {
                                    Circle()
                                        .stroke(.white, lineWidth: 2)
                                        .frame(width: 22, height: 22)
                                }
                            }

                        Text(labelForLevel(level))
                            .font(.nnCaption2)
                            .foregroundStyle(level == 3 ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    // MARK: - Auth

    private var authSection: some View {
        VStack(spacing: 16) {
            SignInWithAppleButton(.signIn) { request in
                viewModel.handleSignInRequest(request)
            } onCompletion: { result in
                Task {
                    await viewModel.handleSignInCompletion(result, authService: authService)
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 55)
            .cornerRadius(12)

            if viewModel.isLoading {
                ProgressView("Iniciando sesion...")
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.nnCallout)
                    .multilineTextAlignment(.center)
            }

            // Explorar sin cuenta — con selector de rol
            VStack(spacing: 12) {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showRoleOptions.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "eye.fill")
                        Text("Explorar sin cuenta")
                        Spacer()
                        Image(systemName: showRoleOptions ? "chevron.up" : "chevron.down")
                            .font(.nnCaption)
                    }
                    .font(.nnSubheadline)
                    .foregroundStyle(Color(red: 0.051, green: 0.580, blue: 0.533))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(Color(red: 0.051, green: 0.580, blue: 0.533).opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if showRoleOptions {
                    VStack(spacing: 10) {
                        Text("Elige como quieres explorar")
                            .font(.nnCaption)
                            .foregroundStyle(.secondary)

                        guestRoleButton(
                            icon: "person.fill",
                            title: "Paciente",
                            desc: "Ver rutinas, medicamentos y emergencia",
                            color: Color(red: 0.145, green: 0.388, blue: 0.922),
                            role: .patient
                        )

                        guestRoleButton(
                            icon: "heart.fill",
                            title: "Cuidador",
                            desc: "Ver como supervisas pacientes",
                            color: Color(red: 0.051, green: 0.580, blue: 0.533),
                            role: .caregiver
                        )

                        guestRoleButton(
                            icon: "person.2.fill",
                            title: "Familiar",
                            desc: "Ver el seguimiento de un ser querido",
                            color: Color(red: 0.486, green: 0.227, blue: 0.929),
                            role: .family
                        )
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            Text("Tu informacion esta protegida con Apple")
                .font(.nnCaption)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
        .padding(.horizontal, 32)
        .padding(.top, 40)
        .padding(.bottom, 40)
    }

    private func guestRoleButton(icon: String, title: String, desc: String, color: Color, role: AppConstants.UserRole) -> some View {
        Button {
            authService.guestSelectedRole = role
            authService.signInAsGuest()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.nnTitle3)
                    .foregroundStyle(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.nnSubheadline)
                        .foregroundStyle(.primary)
                    Text(desc)
                        .font(.nnCaption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.nnTitle3)
                    .foregroundStyle(color.opacity(0.6))
            }
            .padding(12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func colorForLevel(_ level: Int) -> Color {
        switch level {
        case 1: return Color(red: 0.051, green: 0.580, blue: 0.533)
        case 2: return .mint
        case 3: return Color(red: 0.145, green: 0.388, blue: 0.922)
        case 4: return Color(red: 0.486, green: 0.227, blue: 0.929)
        case 5: return .red
        default: return .gray
        }
    }

    private func labelForLevel(_ level: Int) -> String {
        switch level {
        case 1: return "Simple"
        case 2: return "Básico"
        case 3: return "Normal"
        case 4: return "Detallado"
        case 5: return "Avanzado"
        default: return ""
        }
    }
}

// MARK: - Feature Card

private struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(color)
                .frame(width: 56, height: 56)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.nnHeadline)
                Text(description)
                    .font(.nnSubheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}
