import SwiftUI
import NeuroNavKit

struct SettingsView: View {
    @Environment(AuthService.self) private var authService
    @State private var vm = SettingsViewModel()
    @State private var sensoryMode = "default"
    @State private var hapticEnabled = true
    @State private var audioEnabled = true
    @State private var fontScale = 1.0
    @State private var simpleModeEnabled = false
    @State private var alsoCaresEnabled = false
    @State private var biometricService = BiometricService.shared
    @State private var themeManager = ThemeManager.shared

    var body: some View {
        Form {
            // Modo simple: SOLO pacientes que NO sean cuidadores ni familia
            if authService.isPatient && !authService.isFamily {
                Section("Modo de Interfaz") {
                    Toggle(isOn: $simpleModeEnabled) {
                        Label("Modo Simple", systemImage: "hand.tap.fill")
                    }
                    .disabled(alsoCaresEnabled)
                    if alsoCaresEnabled {
                        Text("No disponible mientras 'También soy cuidador' esté activo.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else {
                        Text("Botones grandes, menos opciones. Ideal para uso básico.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: simpleModeEnabled) { _, newValue in
                    Task { await vm.updateSimpleMode(newValue) }
                }

                Section("Rol Adicional") {
                    Toggle(isOn: $alsoCaresEnabled) {
                        HStack(spacing: 10) {
                            Image(systemName: "person.2.badge.gearshape.fill")
                                .foregroundStyle(.purple)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("También soy cuidador")
                                    .font(.subheadline)
                                Text("Supervisar a otras personas")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .tint(.purple)
                }
                .onChange(of: alsoCaresEnabled) { _, newValue in
                    Task {
                        await vm.updateAlsoCares(newValue)
                        if newValue {
                            simpleModeEnabled = false
                            await vm.updateSimpleMode(false)
                        }
                    }
                }
            }

            Section("Modo Sensorial") {
                Picker("Modo", selection: $sensoryMode) {
                    Text("Normal").tag("default")
                    Text("Bajo Estímulo").tag("lowStimulation")
                    Text("Alto Contraste").tag("highContrast")
                }
                .pickerStyle(.segmented)
                .onChange(of: sensoryMode) { _, newValue in
                    Task { await vm.updateSensoryMode(newValue) }
                }

                sensoryModeDescription
            }

            Section("Preferencias") {
                Toggle("Vibraciones", isOn: $hapticEnabled)
                    .onChange(of: hapticEnabled) { _, newValue in
                        Task { await vm.updateHaptic(newValue) }
                    }
                Toggle("Audio y TTS", isOn: $audioEnabled)
                    .onChange(of: audioEnabled) { _, newValue in
                        Task { await vm.updateAudio(newValue) }
                    }

                VStack(alignment: .leading) {
                    Text("Tamaño de texto: \(String(format: "%.0f%%", fontScale * 100))")
                    Slider(value: $fontScale, in: 0.8...1.5, step: 0.1)
                        .onChange(of: fontScale) { _, newValue in
                            Task { await vm.updateFontScale(newValue) }
                        }
                }
            }

            Section("Nivel Adaptativo") {
                if let profile = vm.profile {
                    HStack {
                        Text("Nivel actual")
                        Spacer()
                        Text("\(profile.currentComplexity) / 5")
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                    HStack {
                        Text("Rango permitido")
                        Spacer()
                        Text("\(profile.complexityFloor) - \(profile.complexityCeiling)")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Perfil del Paciente") {
                NavigationLink {
                    PatientProfileView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.text.rectangle")
                            .font(.title3)
                            .foregroundStyle(.nnPrimary)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Datos personales")
                                .font(.nnBody)
                            Text("Edad, peso, alergias y más (opcional)")
                                .font(.nnCaption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Apariencia") {
                Picker("Tema", selection: Binding(
                    get: { themeManager.currentTheme },
                    set: { themeManager.currentTheme = $0 }
                )) {
                    Text("Automático").tag(ThemeManager.AppTheme.system)
                    Text("Claro").tag(ThemeManager.AppTheme.light)
                    Text("Oscuro").tag(ThemeManager.AppTheme.dark)
                }
            }

            if biometricService.isAvailable {
                Section("Seguridad") {
                    Toggle(isOn: Binding(
                        get: { biometricService.isEnabled },
                        set: { biometricService.isEnabled = $0 }
                    )) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Bloqueo con \(biometricService.biometricName)")
                                    .font(.nnBody)
                                Text("Protege tarjeta médica y datos sensibles")
                                    .font(.nnCaption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: biometricService.biometricIcon)
                                .foregroundStyle(.nnPrimary)
                        }
                    }
                }
            }

            Section("Acerca de") {
                Link(destination: URL(string: "https://salvadrn.github.io/cesar-lizzie/terms.html")!) {
                    HStack {
                        Label("Términos y Condiciones", systemImage: "doc.text")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(.secondary)
                    }
                }

                Link(destination: URL(string: "https://salvadrn.github.io/cesar-lizzie/privacy.html")!) {
                    HStack {
                        Label("Política de Privacidad", systemImage: "hand.raised.fill")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(.secondary)
                    }
                }

                NavigationLink {
                    CreditsView()
                } label: {
                    Label("Créditos", systemImage: "info.circle")
                }
            }

            Section {
                Button("Cerrar sesión", role: .destructive) {
                    Task { await vm.logout() }
                }
            }
        }
        .navigationTitle("Ajustes")
        .task {
            await vm.load()
            if let profile = vm.profile {
                sensoryMode = profile.sensoryMode
                hapticEnabled = profile.hapticEnabled
                audioEnabled = profile.audioEnabled
                fontScale = profile.fontScale
            }
            simpleModeEnabled = authService.currentProfile?.simpleMode ?? false
            alsoCaresEnabled = authService.currentProfile?.alsoCares ?? false
        }
    }

    @ViewBuilder
    private var sensoryModeDescription: some View {
        switch sensoryMode {
        case "lowStimulation":
            Text("Colores suaves, sin animaciones, sin sonido ni vibración.")
                .font(.caption)
                .foregroundStyle(.secondary)
        case "highContrast":
            Text("Fondo negro, colores puros, alto contraste para mejor visibilidad.")
                .font(.caption)
                .foregroundStyle(.secondary)
        default:
            Text("Modo estándar con colores, animaciones y retroalimentación completa.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
