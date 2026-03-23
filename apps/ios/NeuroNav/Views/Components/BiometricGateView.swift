import SwiftUI

/// Wraps sensitive content behind a biometric authentication gate.
/// If biometric lock is disabled, shows content immediately.
struct BiometricGateView<Content: View>: View {
    let reason: String
    @ViewBuilder let content: () -> Content

    @State private var isUnlocked = false
    @State private var isAuthenticating = false
    @State private var authFailed = false

    private let biometric = BiometricService.shared

    var body: some View {
        Group {
            if !biometric.isEnabled || isUnlocked {
                content()
            } else {
                lockedView
            }
        }
        .task {
            guard biometric.isEnabled else {
                isUnlocked = true
                return
            }
            await attemptAuth()
        }
    }

    private var lockedView: some View {
        VStack(spacing: 24) {
            Image(systemName: biometric.biometricIcon)
                .font(.system(size: 64))
                .foregroundStyle(.nnPrimary)

            Text("Contenido protegido")
                .font(.nnTitle2)

            Text("Usa \(biometric.biometricName) para acceder a esta información sensible.")
                .font(.nnBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if authFailed {
                Text("Autenticación fallida")
                    .font(.nnCaption)
                    .foregroundStyle(.nnError)
            }

            Button {
                Task { await attemptAuth() }
            } label: {
                Label("Desbloquear", systemImage: biometric.biometricIcon)
                    .font(.nnHeadline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.nnPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isAuthenticating)
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func attemptAuth() async {
        isAuthenticating = true
        authFailed = false
        let result = await biometric.authenticate(reason: reason)
        isAuthenticating = false
        if result {
            withAnimation(.easeOut(duration: 0.3)) {
                isUnlocked = true
            }
        } else {
            authFailed = true
        }
    }
}
