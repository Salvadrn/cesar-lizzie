import SwiftUI
import NeuroNavKit

// Estilo Assistive Access: botones grandes, sin toggles pequenos

struct SimpleSettingsView: View {
    @Environment(AuthService.self) private var authService
    @State private var hapticEnabled = true
    @State private var audioEnabled = true
    @State private var isSwitching = false

    private let api = APIClient.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Vibrations toggle button
                SimpleToggleButton(
                    title: "Vibraciones",
                    icon: "iphone.radiowaves.left.and.right",
                    isOn: hapticEnabled,
                    onColor: .blue
                ) {
                    hapticEnabled.toggle()
                    Task {
                        do {
                            try await api.updateProfile(ProfileUpdate(hapticEnabled: hapticEnabled))
                        } catch {
                            print("SimpleSettings: Error actualizando haptic: \(error.localizedDescription)")
                        }
                    }
                }

                // Audio toggle button
                SimpleToggleButton(
                    title: "Audio y Voz",
                    icon: "speaker.wave.2.fill",
                    isOn: audioEnabled,
                    onColor: .green
                ) {
                    audioEnabled.toggle()
                    Task {
                        do {
                            try await api.updateProfile(ProfileUpdate(audioEnabled: audioEnabled))
                        } catch {
                            print("SimpleSettings: Error actualizando audio: \(error.localizedDescription)")
                        }
                    }
                }

                Spacer().frame(height: 12)

                // Switch to normal mode
                Button {
                    Task {
                        isSwitching = true
                        do {
                            try await api.updateProfile(ProfileUpdate(simpleMode: false))
                        } catch {
                            print("SimpleSettings: Error cambiando modo: \(error.localizedDescription)")
                        }
                        await authService.restoreSession()
                        isSwitching = false
                    }
                } label: {
                    HStack(spacing: 20) {
                        Image(systemName: "iphone")
                            .font(.system(size: 40))
                            .foregroundStyle(.purple)
                            .frame(width: 60)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Modo Normal")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                            Text("Cambiar a la interfaz completa")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if isSwitching {
                            ProgressView()
                                .scaleEffect(1.3)
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.purple.opacity(0.6))
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(.purple.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                .buttonStyle(.plain)
                .disabled(isSwitching)

                Spacer().frame(height: 12)

                // Logout
                Button {
                    Task {
                        do {
                            try await authService.logout()
                        } catch {
                            print("SimpleSettings: Error cerrando sesion: \(error.localizedDescription)")
                        }
                    }
                } label: {
                    HStack(spacing: 20) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 36))
                            .foregroundStyle(.red)
                            .frame(width: 60)

                        Text("Cerrar Sesion")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.red)

                        Spacer()
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Ajustes")
        .task {
            if let profile = authService.currentProfile {
                hapticEnabled = profile.hapticEnabled
                audioEnabled = profile.audioEnabled
            }
        }
    }
}

// MARK: - Assistive Access Toggle Button

private struct SimpleToggleButton: View {
    let title: String
    let icon: String
    let isOn: Bool
    let onColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(isOn ? onColor : .gray)
                    .frame(width: 60)

                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Spacer()

                // Large on/off indicator
                Text(isOn ? "SI" : "NO")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 70, height: 44)
                    .background(isOn ? onColor : .gray)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 90)
            .background(isOn ? onColor.opacity(0.1) : Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .animation(.easeInOut(duration: 0.2), value: isOn)
        }
        .buttonStyle(.plain)
    }
}
