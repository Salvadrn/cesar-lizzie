import SwiftUI
import AdaptAiKit

struct AdaptiveHomeView: View {
    @Environment(AdaptiveEngine.self) private var engine
    @Environment(AuthService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme
    @State private var vm = HomeViewModel()

    private var isDark: Bool { colorScheme == .dark }
    private var level: Int { engine.currentLevel }
    private var config: ComplexityLevelConfig { engine.levelConfig() }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return "Buenos días"
        case 12..<20: return "Buenas tardes"
        default: return "Buenas noches"
        }
    }

    private var firstName: String {
        let name = authService.currentProfile?.displayName ?? (authService.isGuestMode ? "Invitado" : "")
        return name.components(separatedBy: " ").first ?? name
    }

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView("Cargando...")
            } else {
                ScrollView {
                    VStack(spacing: level <= 2 ? 24 : 20) {
                        if authService.isGuestMode {
                            GuestModeBanner()
                                .padding(.horizontal, 16)
                        }

                        switch level {
                        case 1:
                            essentialLayout
                        case 2:
                            simpleLayout
                        case 3:
                            standardLayout
                        default:
                            detailedLayout
                        }
                    }
                    .padding(.vertical, 12)
                }
                .background(isDark ? Color.nnNightBG : Color(.systemGroupedBackground))
            }
        }
        .navigationTitle(level <= 2 ? "" : "Inicio")
        .navigationBarTitleDisplayMode(level <= 2 ? .inline : .large)
        .task { await vm.load() }
        .refreshable { await vm.load() }
        .navigationDestination(for: String.self) { routineId in
            RoutinePlayerView(routineId: routineId)
        }
    }

    // MARK: - Level 1: Essential
    // Big icons, no text details, just the core actions

    private var essentialLayout: some View {
        VStack(spacing: 24) {
            // Simple greeting
            Text("\(greeting), \(firstName)")
                .font(.nnLargeTitle)
                .foregroundStyle(isDark ? .white : .nnDarkText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

            // Big next routine button
            if let nextRoutine = vm.routines.first {
                NavigationLink(value: nextRoutine.id) {
                    HStack(spacing: 20) {
                        Image(systemName: iconForCategory(nextRoutine.category))
                            .font(.system(size: 48))
                            .foregroundStyle(.nnPrimary)
                            .frame(width: 80, height: 80)
                            .background(Color.nnPrimary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                        VStack(alignment: .leading, spacing: 6) {
                            Text(nextRoutine.title)
                                .font(.nnTitle)
                                .foregroundStyle(isDark ? .white : .nnDarkText)
                            Text("Toca para empezar")
                                .font(.nnSubheadline)
                                .foregroundStyle(.nnPrimary)
                        }

                        Spacer()

                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.nnPrimary)
                    }
                    .padding(20)
                    .background(isDark ? Color.white.opacity(0.08) : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(isDark ? 0 : 0.06), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
            }

            // Big action grid (2 columns, huge buttons)
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                essentialTile(title: "Medicinas", icon: "pills.fill", color: .nnMedication) {
                    MedicationView()
                }
                essentialTile(title: "Emergencia", icon: "sos.circle.fill", color: .nnEmergency) {
                    EmergencyView()
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func essentialTile<Destination: View>(title: String, icon: String, color: Color, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink {
            destination()
        } label: {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 44))
                    .foregroundStyle(color)
                Text(title)
                    .font(.nnTitle3)
                    .foregroundStyle(isDark ? .white : .nnDarkText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(color.opacity(isDark ? 0.15 : 0.08))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Level 2: Simple
    // Shows greeting, progress ring, next routine, and quick actions (larger)

    private var simpleLayout: some View {
        VStack(spacing: 20) {
            // Greeting
            Text("\(greeting), \(firstName)")
                .font(.nnTitle)
                .foregroundStyle(isDark ? .white : .nnDarkText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

            // Simple progress
            simpleProgressCard
                .padding(.horizontal, 20)

            // Next routine
            if let nextRoutine = vm.routines.first {
                simpleRoutineCard(nextRoutine)
                    .padding(.horizontal, 20)
            }

            // Quick actions (3 columns, medium size)
            HStack(spacing: 12) {
                quickActionTile(title: "Medicinas", icon: "pills.fill", color: .nnMedication)
                quickActionTile(title: "Emergencia", icon: "sos.circle.fill", color: .nnEmergency)
                quickActionTile(title: "Familia", icon: "person.2.fill", color: .nnFamily)
            }
            .padding(.horizontal, 20)
        }
    }

    private var simpleProgressCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.nnPrimary.opacity(0.15), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: vm.dailyProgress)
                    .stroke(Color.nnPrimary, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.6), value: vm.dailyProgress)

                Text("\(Int(vm.dailyProgress * 100))%")
                    .font(.nnTitle2)
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 4) {
                Text("Tu progreso de hoy")
                    .font(.nnHeadline)
                    .foregroundStyle(isDark ? .white : .nnDarkText)
                Text("\(vm.completedToday) de \(vm.routines.count) rutinas")
                    .font(.nnSubheadline)
                    .foregroundStyle(.nnMidGray)
            }

            Spacer()
        }
        .padding(16)
        .background(isDark ? Color.white.opacity(0.08) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(isDark ? 0 : 0.04), radius: 6, y: 3)
    }

    private func simpleRoutineCard(_ routine: RoutineResponse) -> some View {
        NavigationLink(value: routine.id) {
            HStack(spacing: 14) {
                Image(systemName: iconForCategory(routine.category))
                    .font(.system(size: 32))
                    .foregroundStyle(.nnPrimary)
                    .frame(width: 56, height: 56)
                    .background(Color.nnPrimary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Siguiente")
                        .font(.nnCaption)
                        .foregroundStyle(.nnPrimary)
                    Text(routine.title)
                        .font(.nnTitle3)
                        .foregroundStyle(isDark ? .white : .nnDarkText)
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.nnPrimary)
            }
            .padding(16)
            .background(isDark ? Color.white.opacity(0.08) : .white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(isDark ? 0 : 0.04), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Level 3: Standard (current default)

    private var standardLayout: some View {
        VStack(spacing: 20) {
            headerSection
                .padding(.horizontal, 20)

            dailyProgressCard
                .padding(.horizontal, 20)

            if let nextRoutine = vm.routines.first {
                nextRoutineCard(nextRoutine)
                    .padding(.horizontal, 20)
            }

            quickActionsSection
                .padding(.horizontal, 20)

            if vm.routines.count > 1 {
                routinesSummary
                    .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Level 4-5: Detailed
    // All info visible: progress, routines list, medications, stats

    private var detailedLayout: some View {
        VStack(spacing: 16) {
            headerSection
                .padding(.horizontal, 20)

            dailyProgressCard
                .padding(.horizontal, 20)

            if let nextRoutine = vm.routines.first {
                nextRoutineCard(nextRoutine)
                    .padding(.horizontal, 20)
            }

            quickActionsSection
                .padding(.horizontal, 20)

            // Show ALL routines, not just 3
            if !vm.routines.isEmpty {
                allRoutinesSection
                    .padding(.horizontal, 20)
            }

            // Pending medications summary
            if vm.pendingMedications > 0 {
                pendingMedsCard
                    .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Shared Components

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !firstName.isEmpty {
                Text("\(greeting), \(firstName)")
                    .font(.nnTitle2)
                    .foregroundStyle(isDark ? .white : .nnDarkText)
            } else {
                Text(greeting)
                    .font(.nnTitle2)
                    .foregroundStyle(isDark ? .white : .nnDarkText)
            }
            Text(todayString)
                .font(.nnSubheadline)
                .foregroundStyle(.nnMidGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var todayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "EEEE d 'de' MMMM"
        return formatter.string(from: Date()).capitalized
    }

    private var dailyProgressCard: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.nnPrimary.opacity(0.15), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: vm.dailyProgress)
                    .stroke(Color.nnPrimary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.6), value: vm.dailyProgress)

                VStack(spacing: 2) {
                    Text("\(Int(vm.dailyProgress * 100))%")
                        .font(.nnTitle3)
                    Text("hoy")
                        .font(.nnCaption2)
                        .foregroundStyle(.nnMidGray)
                }
            }
            .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: 6) {
                Text("Progreso diario")
                    .font(.nnHeadline)
                    .foregroundStyle(isDark ? .white : .nnDarkText)

                Text("\(vm.completedToday) de \(vm.routines.count) rutinas")
                    .font(.nnSubheadline)
                    .foregroundStyle(.nnMidGray)

                if vm.pendingMedications > 0 {
                    Label("\(vm.pendingMedications) medicamento\(vm.pendingMedications == 1 ? "" : "s") pendiente\(vm.pendingMedications == 1 ? "" : "s")", systemImage: "pills.fill")
                        .font(.nnCaption)
                        .foregroundStyle(.nnWarning)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(isDark ? Color.white.opacity(0.08) : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func nextRoutineCard(_ routine: RoutineResponse) -> some View {
        NavigationLink(value: routine.id) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Próxima rutina", systemImage: "clock.fill")
                        .font(.nnCaption)
                        .fontWeight(.bold)
                        .foregroundStyle(.nnPrimary)
                    Spacer()
                    if level >= 3, let steps = routine.steps {
                        Text("\(steps.count) pasos")
                            .font(.nnCaption)
                            .foregroundStyle(.nnMidGray)
                    }
                }

                HStack(spacing: 14) {
                    Image(systemName: iconForCategory(routine.category))
                        .font(.system(size: 36))
                        .foregroundStyle(.nnPrimary)
                        .frame(width: 50)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(routine.title)
                            .font(.nnTitle3)
                            .foregroundStyle(isDark ? .white : .primary)

                        if level >= 3, let desc = routine.description, !desc.isEmpty {
                            Text(desc)
                                .font(.nnSubheadline)
                                .foregroundStyle(.nnMidGray)
                                .lineLimit(2)
                        }
                    }
                }

                HStack {
                    Text("Comenzar rutina")
                        .font(.nnSubheadline)
                        .fontWeight(.semibold)
                    Image(systemName: "play.fill")
                        .font(.nnCaption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.nnPrimary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(16)
            .background(isDark ? AnyShapeStyle(Color.white.opacity(0.08)) : AnyShapeStyle(.regularMaterial))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if level >= 3 {
                Text("Accesos rápidos")
                    .font(.nnHeadline)
                    .foregroundStyle(isDark ? .white : .nnDarkText)
            }

            HStack(spacing: 12) {
                NavigationLink { MedicationView() } label: {
                    quickActionTile(title: "Medicamentos", icon: "pills.fill", color: .nnMedication)
                }
                .buttonStyle(.plain)

                NavigationLink { EmergencyView() } label: {
                    quickActionTile(title: "Emergencia", icon: "sos.circle.fill", color: .nnEmergency)
                }
                .buttonStyle(.plain)

                NavigationLink { FamilyView() } label: {
                    quickActionTile(title: "Familia", icon: "person.2.fill", color: .nnFamily)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func quickActionTile(title: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            if config.showText {
                Text(title)
                    .font(.nnCaption)
                    .fontWeight(.bold)
                    .foregroundStyle(isDark ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(isDark ? 0.15 : 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var routinesSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Mis rutinas")
                    .font(.nnHeadline)
                    .foregroundStyle(isDark ? .white : .nnDarkText)
                Spacer()
                Text("\(vm.routines.count) total")
                    .font(.nnCaption)
                    .foregroundStyle(.nnMidGray)
            }

            ForEach(vm.routines.prefix(3)) { routine in
                NavigationLink(value: routine.id) {
                    HStack(spacing: 12) {
                        Image(systemName: iconForCategory(routine.category))
                            .font(.title3)
                            .foregroundStyle(.nnPrimary)
                            .frame(width: 32)

                        Text(routine.title)
                            .font(.nnSubheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(isDark ? .white : .primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(isDark ? AnyShapeStyle(Color.white.opacity(0.08)) : AnyShapeStyle(.regularMaterial))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Level 4-5 Extra Sections

    private var allRoutinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Todas las rutinas")
                    .font(.nnHeadline)
                    .foregroundStyle(isDark ? .white : .nnDarkText)
                Spacer()
                Text("\(vm.completedToday)/\(vm.routines.count)")
                    .font(.nnCaption)
                    .foregroundStyle(.nnMidGray)
            }

            ForEach(vm.routines) { routine in
                NavigationLink(value: routine.id) {
                    HStack(spacing: 12) {
                        Image(systemName: iconForCategory(routine.category))
                            .font(.body)
                            .foregroundStyle(.nnPrimary)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(routine.title)
                                .font(.nnSubheadline)
                                .foregroundStyle(isDark ? .white : .primary)
                            if let desc = routine.description, !desc.isEmpty {
                                Text(desc)
                                    .font(.nnCaption)
                                    .foregroundStyle(.nnMidGray)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        if let steps = routine.steps {
                            Text("\(steps.count) pasos")
                                .font(.nnCaption2)
                                .foregroundStyle(.nnMidGray)
                        }

                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)

                if routine.id != vm.routines.last?.id {
                    Divider()
                }
            }
        }
        .padding(16)
        .background(isDark ? AnyShapeStyle(Color.white.opacity(0.08)) : AnyShapeStyle(.regularMaterial))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var pendingMedsCard: some View {
        NavigationLink {
            MedicationView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "pills.fill")
                    .font(.title2)
                    .foregroundStyle(.nnWarning)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(vm.pendingMedications) medicamento\(vm.pendingMedications == 1 ? "" : "s") pendiente\(vm.pendingMedications == 1 ? "" : "s")")
                        .font(.nnSubheadline)
                        .foregroundStyle(isDark ? .white : .nnDarkText)
                    Text("Toca para ver detalles")
                        .font(.nnCaption)
                        .foregroundStyle(.nnMidGray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.nnMidGray)
            }
            .padding(14)
            .background(Color.nnWarning.opacity(isDark ? 0.15 : 0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func iconForCategory(_ category: String) -> String {
        AppConstants.RoutineCategory(rawValue: category)?.icon ?? "star.fill"
    }
}
