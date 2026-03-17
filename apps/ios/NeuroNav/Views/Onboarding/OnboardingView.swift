import SwiftUI
import NeuroNavKit

struct OnboardingView: View {
    @Environment(AuthService.self) private var authService
    @State private var step = 0
    @State private var displayName = ""
    @State private var role = "patient"
    @State private var sensoryMode = "default"
    @State private var hapticEnabled = true
    @State private var audioEnabled = true
    @State private var lostModeName = ""
    @State private var lostModePhone = ""
    @State private var lostModeAddress = ""
    @State private var simpleMode = false
    @State private var alsoCares = false
    @State private var isSaving = false

    private var totalSteps: Int {
        role == "patient" ? 5 : 4
    }

    var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(step + 1), total: Double(totalSteps))
                .tint(.blue)
                .padding(.horizontal, 24)
                .padding(.top, 16)

            Text("Paso \(step + 1) de \(totalSteps)")
                .font(.nnCaption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            Spacer()

            Group {
                if role == "patient" {
                    switch step {
                    case 0: nameRoleStep
                    case 1: modeSelectionStep
                    case 2: sensoryStep
                    case 3: preferencesStep
                    case 4: lostModeStep
                    default: EmptyView()
                    }
                } else {
                    switch step {
                    case 0: nameRoleStep
                    case 1: sensoryStep
                    case 2: preferencesStep
                    case 3: lostModeStep
                    default: EmptyView()
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            HStack(spacing: 16) {
                if step > 0 {
                    Button {
                        withAnimation { step -= 1 }
                    } label: {
                        Label("Atrás", systemImage: "chevron.left")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }

                Button {
                    if step < totalSteps - 1 {
                        withAnimation { step += 1 }
                    } else {
                        Task { await saveAndContinue() }
                    }
                } label: {
                    Group {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text(step == totalSteps - 1 ? "Comenzar" : "Siguiente")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canContinue ? .blue : .gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!canContinue || isSaving)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private var canContinue: Bool {
        switch step {
        case 0: return !displayName.trimmingCharacters(in: .whitespaces).isEmpty
        default: return true
        }
    }

    // MARK: - Step 1: Name & Role

    private var nameRoleStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("¿Cómo te llamas?")
                .font(.nnTitle2)

            TextField("Tu nombre", text: $displayName)
                .font(.nnTitle3)
                .multilineTextAlignment(.center)
                .textFieldStyle(.roundedBorder)

            VStack(spacing: 12) {
                Text("¿Cuál es tu rol?")
                    .font(.nnHeadline)

                HStack(spacing: 12) {
                    roleButton(title: "Paciente", subtitle: "Uso la app para mí", icon: "person.fill", value: "patient")
                    roleButton(title: "Cuidador", subtitle: "Apoyo a alguien", icon: "heart.fill", value: "caregiver")
                    roleButton(title: "Familiar", subtitle: "Sigo a alguien", icon: "person.2.fill", value: "family")
                }
            }

            if role == "patient" {
                Toggle(isOn: $alsoCares) {
                    HStack(spacing: 10) {
                        Image(systemName: "person.2.badge.gearshape.fill")
                            .foregroundStyle(.purple)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("También soy cuidador")
                                .font(.nnSubheadline)
                            Text("Podré supervisar a otras personas")
                                .font(.nnCaption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .tint(.purple)
                .padding()
                .background(alsoCares ? .purple.opacity(0.08) : Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .onChange(of: alsoCares) { _, newValue in
                    if newValue { simpleMode = false }
                }
            }
        }
    }

    private func roleButton(title: String, subtitle: String, icon: String, value: String) -> some View {
        Button {
            role = value
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.nnSubheadline)
                Text(subtitle)
                    .font(.nnCaption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(role == value ? .blue.opacity(0.15) : Color(.systemGray6))
            .foregroundStyle(role == value ? .blue : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(role == value ? .blue : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step (Patient only): Mode Selection

    private var modeSelectionStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "accessibility.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("¿Cómo quieres usar la app?")
                .font(.nnTitle2)

            Text("Puedes cambiar esto después en Ajustes")
                .font(.nnSubheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 16) {
                modeButton(
                    title: "Modo Simple",
                    desc: "Botones grandes, fácil de usar\nIdeal para personas mayores",
                    icon: "hand.tap.fill",
                    isSelected: simpleMode
                ) {
                    simpleMode = true
                }

                modeButton(
                    title: "Modo Normal",
                    desc: "Todas las funciones disponibles\nInterfaz completa",
                    icon: "iphone",
                    isSelected: !simpleMode
                ) {
                    simpleMode = false
                }
            }
        }
    }

    private func modeButton(title: String, desc: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .frame(width: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.nnHeadline)
                    Text(desc)
                        .font(.nnCaption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
            }
            .padding()
            .background(isSelected ? .blue.opacity(0.1) : Color(.systemGray6))
            .foregroundStyle(isSelected ? .blue : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? .blue : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 2: Sensory Mode

    private var sensoryStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "eye.fill")
                .font(.system(size: 60))
                .foregroundStyle(.purple)

            Text("Modo sensorial")
                .font(.nnTitle2)

            Text("Elige cómo quieres ver la app")
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                sensoryButton(title: "Normal", desc: "Colores, animaciones y sonidos", icon: "sparkles", value: "default")
                sensoryButton(title: "Bajo Estímulo", desc: "Colores suaves, sin animaciones", icon: "moon.fill", value: "lowStimulation")
                sensoryButton(title: "Alto Contraste", desc: "Fondo oscuro, colores fuertes", icon: "circle.lefthalf.filled", value: "highContrast")
            }
        }
    }

    private func sensoryButton(title: String, desc: String, icon: String, value: String) -> some View {
        Button {
            sensoryMode = value
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.nnSubheadline)
                    Text(desc).font(.nnCaption).foregroundStyle(.secondary)
                }
                Spacer()
                if sensoryMode == value {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding()
            .background(sensoryMode == value ? .blue.opacity(0.1) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 3: Preferences

    private var preferencesStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            Text("Preferencias")
                .font(.nnTitle2)

            VStack(spacing: 16) {
                Toggle(isOn: $hapticEnabled) {
                    Label("Vibraciones", systemImage: "iphone.radiowaves.left.and.right")
                }
                Toggle(isOn: $audioEnabled) {
                    Label("Audio y voz", systemImage: "speaker.wave.2.fill")
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Text("Puedes cambiar esto después en Ajustes")
                .font(.nnCaption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Step 4: Lost Mode / Finish

    private var lostModeStep: some View {
        VStack(spacing: 24) {
            Image(systemName: role == "patient" ? "mappin.and.ellipse" : "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundStyle(role == "patient" ? .orange : .green)

            if role == "patient" {
                Text("Modo Perdido")
                    .font(.nnTitle2)

                Text("Estos datos se mostrarán si activas el Modo Perdido")
                    .font(.nnSubheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    TextField("Nombre visible", text: $lostModeName)
                        .textFieldStyle(.roundedBorder)
                    TextField("Teléfono de contacto", text: $lostModePhone)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.phonePad)
                    TextField("Dirección (opcional)", text: $lostModeAddress)
                        .textFieldStyle(.roundedBorder)
                }

                Text("Puedes completar esto después")
                    .font(.nnCaption)
                    .foregroundStyle(.secondary)
            } else if role == "caregiver" {
                Text("¡Todo listo!")
                    .font(.nnTitle2)

                Text("Como cuidador, podrás vincular pacientes desde la sección Familia y monitorear su actividad.")
                    .font(.nnSubheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Image(systemName: "person.2.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue.opacity(0.5))
            } else {
                Text("¡Todo listo!")
                    .font(.nnTitle2)

                Text("Tu cuidador configurará qué información puedes ver. Vincula tu cuenta desde la sección Familia.")
                    .font(.nnSubheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Image(systemName: "link.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.purple.opacity(0.5))
            }
        }
    }

    // MARK: - Save

    private func saveAndContinue() async {
        isSaving = true
        do {
            var update = ProfileUpdate(
                displayName: displayName,
                sensoryMode: sensoryMode,
                hapticEnabled: hapticEnabled,
                audioEnabled: audioEnabled
            )
            if role == "patient" {
                update.simpleMode = simpleMode
                update.alsoCares = alsoCares
                if alsoCares {
                    update.simpleMode = false // Cuidadores no usan modo simple
                }
                if simpleMode && !alsoCares {
                    update.currentComplexity = 1
                    update.sensoryMode = "lowStimulation"
                }
                if !lostModeName.isEmpty {
                    update.lostModeName = lostModeName
                    update.lostModePhone = lostModePhone.isEmpty ? nil : lostModePhone
                    update.lostModeAddress = lostModeAddress.isEmpty ? nil : lostModeAddress
                }
            }
            try await APIClient.shared.updateProfile(update)

            // Update role
            guard let userId = authService.userId?.uuidString else {
                throw APIError.notAuthenticated
            }
            try await SupabaseManager.shared.client
                .from("profiles")
                .update(["role": role])
                .eq("id", value: userId)
                .execute()

            await authService.restoreSession()
        } catch {
            print("Onboarding save error: \(error)")
        }
        isSaving = false
    }
}
