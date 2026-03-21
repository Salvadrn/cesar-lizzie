import SwiftUI
import NeuroNavKit
import AuthenticationServices

struct LoginView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = AppleSignInViewModel()
    @State private var showRoleOptions = false

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                heroSection
                featuresRow
                authSection
            }
            .padding(.top, 80)
            .padding(.bottom, 40)
        }
        .background(
            LinearGradient(
                colors: isDark
                    ? [Color.nnPrimary.opacity(0.12), Color.nnNightBG]
                    : [Color.nnPrimary.opacity(0.06), Color.nnLightBG],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        )
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.nnPrimary.opacity(isDark ? 0.2 : 0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "location.north.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.nnPrimary)
            }

            // "Adapt" + "Ai" wordmark
            HStack(spacing: 0) {
                Text("Adapt")
                    .foregroundStyle(isDark ? .white : .nnDarkText)
                Text("Ai")
                    .foregroundStyle(.nnGold)
            }
            .font(.nnDisplay)

            Text("Tu asistente adaptativo\npara la vida diaria")
                .font(.nnBody)
                .foregroundStyle(.nnMidGray)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Features

    private var featuresRow: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                featurePill(icon: "list.clipboard.fill", title: "Rutinas", color: .nnPrimary)
                featurePill(icon: "pill.fill", title: "Medicamentos", color: .nnSuccess)
            }
            HStack(spacing: 12) {
                featurePill(icon: "person.3.fill", title: "Familia", color: .nnFamily)
                featurePill(icon: "sos", title: "Emergencia", color: .nnError)
            }
        }
        .padding(.horizontal, 32)
    }

    private func featurePill(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            Text(title)
                .font(.nnSubheadline)
                .foregroundStyle(isDark ? .white : .nnDarkText)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(isDark ? Color.white.opacity(0.08) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(isDark ? 0 : 0.04), radius: 6, y: 3)
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
            .signInWithAppleButtonStyle(isDark ? .white : .black)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 14))

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
            .padding(.top, 4)

            if showRoleOptions {
                HStack(spacing: 10) {
                    guestRoleChip(title: "Paciente", icon: "person.fill", color: .nnPrimary, role: .patient)
                    guestRoleChip(title: "Cuidador", icon: "heart.fill", color: .nnCaregiver, role: .caregiver)
                    guestRoleChip(title: "Familiar", icon: "person.2.fill", color: .nnWarning, role: .family)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            HStack(spacing: 4) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 10))
                Text("Protegido con Apple")
                    .font(.nnCaption2)
            }
            .foregroundStyle(.nnMidGray)
            .padding(.top, 4)
        }
        .padding(.horizontal, 32)
    }

    private func guestRoleChip(title: String, icon: String, color: Color, role: AppConstants.UserRole) -> some View {
        Button {
            authService.guestSelectedRole = role
            authService.signInAsGuest()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(.nnCaption)
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(isDark ? 0.15 : 0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
