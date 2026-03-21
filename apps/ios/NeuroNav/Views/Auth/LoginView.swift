import SwiftUI
import NeuroNavKit
import AuthenticationServices

struct LoginView: View {
    @Environment(AuthService.self) private var authService
    @StateObject private var viewModel = AppleSignInViewModel()
    @State private var showRoleOptions = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            heroSection
            featuresGrid
            Spacer()
            authSection
        }
        .background(Color.nnLightBG)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.north.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.nnPrimary)

            Text("AdaptAi")
                .font(.nnDisplay)
                .foregroundStyle(.nnDarkText)

            Text("Empowering independence through\nadaptive technology")
                .font(.nnSubheadline)
                .foregroundStyle(.nnMidGray)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 40)
    }

    // MARK: - Features (2x2 grid)

    private var featuresGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            featureTile(icon: "list.clipboard.fill", title: "Rutinas", color: .nnPrimary)
            featureTile(icon: "pill.fill", title: "Medicamentos", color: .nnSuccess)
            featureTile(icon: "person.3.fill", title: "Familia", color: .nnFamily)
            featureTile(icon: "sos", title: "Emergencia", color: .nnError)
        }
        .padding(.horizontal, 40)
    }

    private func featureTile(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
            Text(title)
                .font(.nnCaption)
                .foregroundStyle(.nnDarkText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Auth

    private var authSection: some View {
        VStack(spacing: 14) {
            SignInWithAppleButton(.signIn) { request in
                viewModel.handleSignInRequest(request)
            } onCompletion: { result in
                Task {
                    await viewModel.handleSignInCompletion(result, authService: authService)
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if viewModel.isLoading {
                ProgressView("Iniciando sesion...")
                    .font(.nnCaption)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.nnError)
                    .font(.nnCaption)
                    .multilineTextAlignment(.center)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showRoleOptions.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Text("Explorar sin cuenta")
                    Image(systemName: showRoleOptions ? "chevron.up" : "chevron.down")
                        .font(.nnCaption2)
                }
                .font(.nnSubheadline)
                .foregroundStyle(.nnPrimary)
            }

            if showRoleOptions {
                HStack(spacing: 10) {
                    guestRoleChip(title: "Paciente", icon: "person.fill", color: .nnPrimary, role: .patient)
                    guestRoleChip(title: "Cuidador", icon: "heart.fill", color: .nnCaregiver, role: .caregiver)
                    guestRoleChip(title: "Familiar", icon: "person.2.fill", color: .nnWarning, role: .family)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            Text("Protegido con Apple")
                .font(.nnCaption2)
                .foregroundStyle(.nnMidGray)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 40)
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
                    .font(.nnCaption2)
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
