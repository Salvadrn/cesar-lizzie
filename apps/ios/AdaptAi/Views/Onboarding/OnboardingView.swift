import SwiftUI
import AdaptAiKit

/// Onboarding con cuestionario de caracteristicas que determina la UI del paciente.
/// Las respuestas afectan: complexity_level, sensory_mode, font_scale, simple_mode.
struct OnboardingView: View {
    @Environment(AuthService.self) private var authService
    @State private var step = 0

    // Basico
    @State private var displayName = ""
    @State private var role = "patient"
    @State private var alsoCares = false

    // Cuestionario de caracteristicas
    @State private var conditions: Set<HealthCondition> = []
    @State private var difficulties: Set<Difficulty> = []
    @State private var conditionOther = ""

    // Preferencias UI
    @State private var simpleMode = false
    @State private var sensoryMode = "default"
    @State private var hapticEnabled = true
    @State private var audioEnabled = true
    @State private var fontScale: Double = 1.0
    @State private var reminderFrequency = "medium"

    // Modo perdido
    @State private var lostModeName = ""
    @State private var lostModePhone = ""
    @State private var lostModeAddress = ""

    @State private var isSaving = false
    @State private var saveError: String?

    private var totalSteps: Int {
        role == "patient" ? 8 : 4
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

            ScrollView {
                VStack(spacing: 24) {
                    if role == "patient" {
                        switch step {
                        case 0: nameRoleStep
                        case 1: conditionsStep
                        case 2: difficultiesStep
                        case 3: suggestedModeStep
                        case 4: sensoryStep
                        case 5: preferencesStep
                        case 6: fontScaleStep
                        case 7: lostModeStep
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
                .padding(.top, 20)
                .padding(.bottom, 24)
            }

            if let err = saveError {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(err)
                        .font(.nnCaption)
                        .foregroundStyle(.primary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }

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
                            ProgressView().tint(.white)
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

    // MARK: - Step 0: Name & Role

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
                Image(systemName: icon).font(.title2)
                Text(title).font(.nnSubheadline)
                Text(subtitle).font(.nnCaption2).foregroundStyle(.secondary)
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

    // MARK: - Step 1: Health Conditions (Patient only)

    private var conditionsStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "stethoscope")
                .font(.system(size: 56))
                .foregroundStyle(.red)

            Text("Condiciones de salud")
                .font(.nnTitle2)

            Text("Selecciona las que apliquen. Esto nos ayuda a adaptar la app. Puedes omitir este paso.")
                .font(.nnSubheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                ForEach(HealthCondition.allCases, id: \.self) { condition in
                    multiSelectRow(
                        title: condition.displayName,
                        icon: condition.icon,
                        color: condition.color,
                        isSelected: conditions.contains(condition)
                    ) {
                        if conditions.contains(condition) {
                            conditions.remove(condition)
                        } else {
                            conditions.insert(condition)
                        }
                    }
                }

                if conditions.contains(.other) {
                    TextField("Describe tu condición", text: $conditionOther)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    // MARK: - Step 2: Difficulties (Patient only)

    private var difficultiesStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 56))
                .foregroundStyle(.purple)

            Text("Dificultades frecuentes")
                .font(.nnTitle2)

            Text("Marca las que experimentas para ajustar la interfaz.")
                .font(.nnSubheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                ForEach(Difficulty.allCases, id: \.self) { d in
                    multiSelectRow(
                        title: d.displayName,
                        icon: d.icon,
                        color: d.color,
                        isSelected: difficulties.contains(d)
                    ) {
                        if difficulties.contains(d) {
                            difficulties.remove(d)
                        } else {
                            difficulties.insert(d)
                        }
                    }
                }
            }
        }
    }

    private func multiSelectRow(title: String, icon: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
                    .frame(width: 28)

                Text(title)
                    .font(.nnBody)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
            .padding(14)
            .background(isSelected ? .blue.opacity(0.08) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 3: Suggested Mode (based on quiz)

    private var suggestedModeStep: some View {
        let suggestedLevel = calculateSuggestedLevel()
        let suggestSimple = suggestedLevel <= 2

        return VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(.yellow)

            Text("Modo recomendado")
                .font(.nnTitle2)

            Text(suggestSimple
                 ? "Basándonos en tus respuestas, recomendamos el Modo Simple con botones grandes y pasos claros."
                 : "Basándonos en tus respuestas, recomendamos el Modo Normal con todas las funciones disponibles.")
                .font(.nnSubheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                modeButton(
                    title: "Modo Simple",
                    desc: "Botones grandes, pasos guiados\nRecomendado si marcaste condiciones o dificultades",
                    icon: "hand.tap.fill",
                    isSelected: simpleMode,
                    isRecommended: suggestSimple
                ) {
                    simpleMode = true
                }

                modeButton(
                    title: "Modo Normal",
                    desc: "Interfaz completa con todas las funciones",
                    icon: "iphone",
                    isSelected: !simpleMode,
                    isRecommended: !suggestSimple
                ) {
                    simpleMode = false
                }
            }

            if !conditions.isEmpty || !difficulties.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill").foregroundStyle(.blue)
                    Text("Nivel de complejidad sugerido: \(suggestedLevel)/5")
                        .font(.nnCaption)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .onAppear {
            simpleMode = suggestSimple
        }
    }

    private func modeButton(title: String, desc: String, icon: String, isSelected: Bool, isRecommended: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .frame(width: 50)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title).font(.nnHeadline)
                        if isRecommended {
                            Text("Recomendado")
                                .font(.nnCaption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.yellow.opacity(0.25))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())
                        }
                    }
                    Text(desc).font(.nnCaption).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill").font(.title2).foregroundStyle(.blue)
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

    // MARK: - Step 4: Sensory

    private var sensoryStep: some View {
        let suggestsLowStim = difficulties.contains(.sensorySensitivity) || conditions.contains(.autism)
        let suggestsHighContrast = difficulties.contains(.vision)

        return VStack(spacing: 24) {
            Image(systemName: "eye.fill").font(.system(size: 56)).foregroundStyle(.purple)
            Text("Modo sensorial").font(.nnTitle2)
            Text("Elige cómo ver la app").foregroundStyle(.secondary)

            VStack(spacing: 12) {
                sensoryButton(title: "Normal", desc: "Colores y animaciones", icon: "sparkles", value: "default", recommended: !suggestsLowStim && !suggestsHighContrast)
                sensoryButton(title: "Bajo Estímulo", desc: "Colores suaves, sin animaciones", icon: "moon.fill", value: "lowStimulation", recommended: suggestsLowStim)
                sensoryButton(title: "Alto Contraste", desc: "Fondo oscuro, colores fuertes", icon: "circle.lefthalf.filled", value: "highContrast", recommended: suggestsHighContrast)
            }
        }
        .onAppear {
            if sensoryMode == "default" {
                if suggestsHighContrast { sensoryMode = "highContrast" }
                else if suggestsLowStim { sensoryMode = "lowStimulation" }
            }
        }
    }

    private func sensoryButton(title: String, desc: String, icon: String, value: String, recommended: Bool = false) -> some View {
        Button {
            sensoryMode = value
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon).font(.title3).frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(title).font(.nnSubheadline)
                        if recommended {
                            Text("★").foregroundStyle(.orange).font(.nnCaption)
                        }
                    }
                    Text(desc).font(.nnCaption).foregroundStyle(.secondary)
                }
                Spacer()
                if sensoryMode == value {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.blue)
                }
            }
            .padding()
            .background(sensoryMode == value ? .blue.opacity(0.1) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 5: Preferences

    private var preferencesStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "hand.tap.fill").font(.system(size: 56)).foregroundStyle(.orange)
            Text("Preferencias").font(.nnTitle2)

            VStack(spacing: 16) {
                Toggle(isOn: $hapticEnabled) {
                    Label("Vibraciones", systemImage: "iphone.radiowaves.left.and.right")
                }
                Toggle(isOn: $audioEnabled) {
                    Label("Audio y voz", systemImage: "speaker.wave.2.fill")
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Label("Frecuencia de recordatorios", systemImage: "bell.fill")
                    Picker("Frecuencia", selection: $reminderFrequency) {
                        Text("Bajo").tag("low")
                        Text("Medio").tag("medium")
                        Text("Alto").tag("high")
                    }
                    .pickerStyle(.segmented)
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

    // MARK: - Step 6: Font Scale (Patient only)

    private var fontScaleStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "textformat.size").font(.system(size: 56)).foregroundStyle(.green)
            Text("Tamaño de texto").font(.nnTitle2)
            Text("Ajusta hasta que puedas leer cómodamente")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Preview
            VStack(spacing: 8) {
                Text("Buenos días")
                    .font(.system(size: 28 * fontScale, weight: .bold))
                Text("Es hora de tus medicinas")
                    .font(.system(size: 16 * fontScale))
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(spacing: 8) {
                Slider(value: $fontScale, in: 0.8...1.5, step: 0.1)
                HStack {
                    Text("Pequeño").font(.nnCaption).foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(fontScale * 100))%").font(.nnHeadline).foregroundStyle(.blue)
                    Spacer()
                    Text("Grande").font(.nnCaption).foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .onAppear {
            // Suggest larger font if vision difficulty
            if difficulties.contains(.vision) && fontScale == 1.0 {
                fontScale = 1.3
            }
        }
    }

    // MARK: - Step 7: Lost Mode / Finish

    private var lostModeStep: some View {
        VStack(spacing: 24) {
            Image(systemName: role == "patient" ? "mappin.and.ellipse" : "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundStyle(role == "patient" ? .orange : .green)

            if role == "patient" {
                Text("Modo Perdido").font(.nnTitle2)
                Text("Estos datos se mostrarán si activas el Modo Perdido")
                    .font(.nnSubheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    TextField("Nombre visible", text: $lostModeName).textFieldStyle(.roundedBorder)
                    TextField("Teléfono de contacto", text: $lostModePhone)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.phonePad)
                    TextField("Dirección (opcional)", text: $lostModeAddress).textFieldStyle(.roundedBorder)
                }

                Text("Puedes completar esto después").font(.nnCaption).foregroundStyle(.secondary)
            } else if role == "caregiver" {
                Text("¡Todo listo!").font(.nnTitle2)
                Text("Como cuidador, podrás vincular pacientes desde la sección Familia.")
                    .font(.nnSubheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Image(systemName: "person.2.fill").font(.system(size: 80)).foregroundStyle(.blue.opacity(0.5))
            } else {
                Text("¡Todo listo!").font(.nnTitle2)
                Text("Tu cuidador configurará qué información puedes ver.")
                    .font(.nnSubheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Image(systemName: "link.circle.fill").font(.system(size: 80)).foregroundStyle(.purple.opacity(0.5))
            }
        }
    }

    // MARK: - Logic: Calculate Complexity Level

    /// Determina complexity level (1-5) basado en condiciones y dificultades.
    /// Mas condiciones severas + dificultades = nivel mas bajo (mas simple).
    private func calculateSuggestedLevel() -> Int {
        let severityScore = conditions.reduce(0) { $0 + $1.severityWeight }
        let difficultyScore = difficulties.reduce(0) { $0 + $1.severityWeight }
        let total = severityScore + difficultyScore

        // Escala: 0 → nivel 5, 10+ → nivel 1
        switch total {
        case 0: return 5
        case 1...2: return 4
        case 3...5: return 3
        case 6...9: return 2
        default: return 1
        }
    }

    // MARK: - Save

    private func saveAndContinue() async {
        isSaving = true
        saveError = nil
        defer { isSaving = false }

        let level = calculateSuggestedLevel()

        var update = ProfileUpdate(
            displayName: displayName,
            sensoryMode: sensoryMode,
            hapticEnabled: hapticEnabled,
            audioEnabled: audioEnabled,
            fontScale: fontScale
        )

        if role == "patient" {
            update.simpleMode = simpleMode
            update.alsoCares = alsoCares
            update.currentComplexity = simpleMode ? min(level, 2) : level

            if alsoCares {
                update.simpleMode = false
            }
            if !lostModeName.isEmpty {
                update.lostModeName = lostModeName
                update.lostModePhone = lostModePhone.isEmpty ? nil : lostModePhone
                update.lostModeAddress = lostModeAddress.isEmpty ? nil : lostModeAddress
            }
        }

        // Always save locally first so we can continue even if backend fails
        saveLocalProfile(update: update, role: role)

        // Try to persist to Supabase
        do {
            try await APIClient.shared.updateProfile(update)

            if role == "patient" && (!conditions.isEmpty || !difficulties.isEmpty) {
                await saveMedicalIDFromQuiz()
            }

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

            // If we have no session, fall back to guest mode with chosen preferences
            if authService.userId == nil {
                applyLocalPreferencesAsGuest()
            } else {
                // Session exists but update failed (network issue). Still let user continue.
                applyLocalProfileInMemory(update: update)
            }
        }
    }

    /// Save preferences to UserDefaults so they survive app restart.
    private func saveLocalProfile(update: ProfileUpdate, role: String) {
        let defaults = UserDefaults.standard
        defaults.set(update.displayName, forKey: "pending_displayName")
        defaults.set(update.sensoryMode, forKey: "pending_sensoryMode")
        defaults.set(update.hapticEnabled, forKey: "pending_haptic")
        defaults.set(update.audioEnabled, forKey: "pending_audio")
        defaults.set(update.fontScale, forKey: "pending_fontScale")
        defaults.set(update.simpleMode, forKey: "pending_simpleMode")
        defaults.set(update.currentComplexity, forKey: "pending_complexity")
        defaults.set(role, forKey: "pending_role")
    }

    /// When no session, activate guest mode with selected preferences so user can continue.
    private func applyLocalPreferencesAsGuest() {
        let userRole = AppConstants.UserRole(rawValue: role)
        authService.guestSelectedRole = userRole
        if role == "patient" {
            authService.setGuestSimpleMode(simpleMode)
        }
        authService.signInAsGuest()
    }

    /// Update in-memory profile so MainTabView shows correctly even if sync failed.
    private func applyLocalProfileInMemory(update: ProfileUpdate) {
        guard let current = authService.currentProfile else {
            applyLocalPreferencesAsGuest()
            return
        }
        var updated = current
        updated.displayName = update.displayName ?? current.displayName
        updated.sensoryMode = update.sensoryMode ?? current.sensoryMode
        updated.hapticEnabled = update.hapticEnabled ?? current.hapticEnabled
        updated.audioEnabled = update.audioEnabled ?? current.audioEnabled
        updated.fontScale = update.fontScale ?? current.fontScale
        updated.simpleMode = update.simpleMode ?? current.simpleMode
        updated.currentComplexity = update.currentComplexity ?? current.currentComplexity
        updated.alsoCares = update.alsoCares ?? current.alsoCares
        authService.currentProfile = updated
        saveError = "Guardado localmente. Se sincronizará cuando recuperes conexión."
    }

    private func saveMedicalIDFromQuiz() async {
        do {
            let userId = try await APIClient.shared.currentUserId()
            var conditionsList = conditions.filter { $0 != .none && $0 != .other }.map { $0.displayName }
            if conditions.contains(.other) && !conditionOther.isEmpty {
                conditionsList.append(conditionOther)
            }
            let difficultiesList = difficulties.map { "Dificultad: \($0.displayName)" }

            let existing = try? await APIClient.shared.fetchMedicalID()

            let row = MedicalIDRow(
                id: existing?.id ?? UUID().uuidString,
                userId: userId,
                fullName: existing?.fullName ?? displayName,
                dateOfBirth: existing?.dateOfBirth,
                bloodType: existing?.bloodType,
                weight: existing?.weight,
                height: existing?.height,
                allergies: existing?.allergies ?? [],
                conditions: conditionsList + difficultiesList,
                currentMedications: existing?.currentMedications ?? [],
                doctorName: existing?.doctorName,
                doctorPhone: existing?.doctorPhone,
                insuranceProvider: existing?.insuranceProvider,
                insuranceNumber: existing?.insuranceNumber,
                organDonor: existing?.organDonor ?? false,
                notes: existing?.notes,
                photoUrl: existing?.photoUrl,
                updatedAt: nil
            )
            try await APIClient.shared.upsertMedicalID(row)
        } catch {
            print("Medical ID save error: \(error)")
        }
    }
}

// MARK: - Quiz Models

enum HealthCondition: String, CaseIterable, Hashable {
    case alzheimer
    case dementia
    case parkinson
    case brainInjury
    case stroke
    case intellectualDisability
    case autism
    case anxiety
    case depression
    case schizophrenia
    case none
    case other

    var displayName: String {
        switch self {
        case .alzheimer: return "Alzheimer"
        case .dementia: return "Demencia"
        case .parkinson: return "Parkinson"
        case .brainInjury: return "Lesión cerebral"
        case .stroke: return "Derrame cerebral"
        case .intellectualDisability: return "Discapacidad intelectual"
        case .autism: return "Autismo"
        case .anxiety: return "Ansiedad"
        case .depression: return "Depresión"
        case .schizophrenia: return "Esquizofrenia"
        case .none: return "Ninguna de las anteriores"
        case .other: return "Otra (especificar)"
        }
    }

    var icon: String {
        switch self {
        case .alzheimer, .dementia: return "brain"
        case .parkinson: return "hand.raised.fill"
        case .brainInjury, .stroke: return "bandage.fill"
        case .intellectualDisability: return "person.fill.questionmark"
        case .autism: return "sparkles"
        case .anxiety, .depression: return "cloud.fill"
        case .schizophrenia: return "exclamationmark.triangle.fill"
        case .none: return "checkmark.circle.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .alzheimer, .dementia, .parkinson, .brainInjury, .stroke: return .red
        case .intellectualDisability, .autism: return .purple
        case .anxiety, .depression, .schizophrenia: return .blue
        case .none: return .green
        case .other: return .gray
        }
    }

    /// Peso que contribuye al calculo de complejidad.
    var severityWeight: Int {
        switch self {
        case .alzheimer, .dementia, .brainInjury, .stroke, .schizophrenia: return 3
        case .parkinson, .intellectualDisability: return 2
        case .autism, .anxiety, .depression: return 1
        case .none, .other: return 0
        }
    }
}

enum Difficulty: String, CaseIterable, Hashable {
    case memory
    case attention
    case language
    case reading
    case fineMovement
    case vision
    case hearing
    case sensorySensitivity
    case speech
    case timeManagement

    var displayName: String {
        switch self {
        case .memory: return "Memoria"
        case .attention: return "Atención / concentración"
        case .language: return "Comprensión del lenguaje"
        case .reading: return "Lectura"
        case .fineMovement: return "Movimiento fino"
        case .vision: return "Visión"
        case .hearing: return "Audición"
        case .sensorySensitivity: return "Sensibilidad a estímulos"
        case .speech: return "Hablar"
        case .timeManagement: return "Manejo del tiempo"
        }
    }

    var icon: String {
        switch self {
        case .memory: return "brain.head.profile"
        case .attention: return "eye.trianglebadge.exclamationmark.fill"
        case .language: return "text.bubble.fill"
        case .reading: return "book.fill"
        case .fineMovement: return "hand.raised.fingers.spread.fill"
        case .vision: return "eye.fill"
        case .hearing: return "ear.fill"
        case .sensorySensitivity: return "wave.3.right"
        case .speech: return "mic.fill"
        case .timeManagement: return "clock.fill"
        }
    }

    var color: Color {
        switch self {
        case .memory, .attention: return .orange
        case .language, .reading, .speech: return .blue
        case .fineMovement: return .green
        case .vision, .hearing: return .red
        case .sensorySensitivity: return .purple
        case .timeManagement: return .teal
        }
    }

    var severityWeight: Int {
        switch self {
        case .memory, .attention: return 2
        case .language, .reading, .speech: return 2
        case .fineMovement, .vision, .hearing: return 1
        case .sensorySensitivity: return 1
        case .timeManagement: return 1
        }
    }
}
