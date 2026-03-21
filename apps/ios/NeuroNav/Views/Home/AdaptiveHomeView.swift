import SwiftUI
import NeuroNavKit

struct AdaptiveHomeView: View {
    @Environment(AdaptiveEngine.self) private var engine
    @Environment(AuthService.self) private var authService
    @State private var vm = HomeViewModel()

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return "Buenos dias"
        case 12..<20: return "Buenas tardes"
        default: return "Buenas noches"
        }
    }

    private var todayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "EEEE d 'de' MMMM"
        return formatter.string(from: Date()).capitalized
    }

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView("Cargando...")
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        if authService.isGuestMode {
                            GuestModeBanner()
                                .padding(.horizontal, 16)
                        }

                        // MARK: - Header
                        headerSection
                            .padding(.horizontal, 20)

                        // MARK: - Daily Progress
                        dailyProgressCard
                            .padding(.horizontal, 20)

                        // MARK: - Next Routine
                        if let nextRoutine = vm.routines.first {
                            nextRoutineCard(nextRoutine)
                                .padding(.horizontal, 20)
                        }

                        // MARK: - Quick Actions
                        quickActionsSection
                            .padding(.horizontal, 20)

                        // MARK: - Routines preview
                        if vm.routines.count > 1 {
                            routinesSummary
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 12)
                }
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationTitle("Inicio")
        .task { await vm.load() }
        .refreshable { await vm.load() }
        .navigationDestination(for: String.self) { routineId in
            RoutinePlayerView(routineId: routineId)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let name = authService.currentProfile?.displayName ?? (authService.isGuestMode ? "Invitado" : nil), !name.isEmpty {
                Text("\(greeting), \(name)")
                    .font(.nnTitle2)
                    .foregroundStyle(.nnDarkText)
            } else {
                Text(greeting)
                    .font(.nnTitle2)
                    .foregroundStyle(.nnDarkText)
            }
            Text(todayString)
                .font(.nnSubheadline)
                .foregroundStyle(.nnMidGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Daily Progress Card

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
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Next Routine Card

    private func nextRoutineCard(_ routine: RoutineResponse) -> some View {
        NavigationLink(value: routine.id) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Proxima rutina", systemImage: "clock.fill")
                        .font(.nnCaption)
                        .fontWeight(.bold)
                        .foregroundStyle(.nnPrimary)
                    Spacer()
                    if let steps = routine.steps {
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
                            .foregroundStyle(.primary)

                        if let desc = routine.description, !desc.isEmpty {
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
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accesos rapidos")
                .font(.nnHeadline)

            HStack(spacing: 12) {
                NavigationLink {
                    MedicationView()
                } label: {
                    quickActionTile(title: "Medicamentos", icon: "pills.fill", color: .nnMedication)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    EmergencyView()
                } label: {
                    quickActionTile(title: "Emergencia", icon: "sos.circle.fill", color: .nnEmergency)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    FamilyView()
                } label: {
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

            Text(title)
                .font(.nnCaption)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Routines Summary

    private var routinesSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Mis rutinas")
                    .font(.nnHeadline)
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
                            .foregroundStyle(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }

            if vm.routines.count > 3 {
                Text("Ve a Rutinas para ver todas")
                    .font(.nnCaption)
                    .foregroundStyle(.nnMidGray)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func iconForCategory(_ category: String) -> String {
        AppConstants.RoutineCategory(rawValue: category)?.icon ?? "star.fill"
    }
}
