import SwiftUI
import AdaptAiKit

/// Routine list with Soulspring-inspired aesthetics: warm background,
/// rounded cards with circular icon badges, eyebrow labels, soft shadows.
/// Keeps AdaptAi brand palette (blue + gold).
struct RoutineListView: View {
    @Environment(AuthService.self) private var authService
    @Environment(AdaptiveEngine.self) private var engine
    @State private var routines: [RoutineResponse] = []
    @State private var isLoading = true

    private var level: Int { engine.currentLevel }
    private var config: ComplexityLevelConfig { engine.levelConfig() }

    var body: some View {
        ZStack {
            AdaptBackground()

            Group {
                if isLoading {
                    ProgressView("Cargando rutinas...")
                        .font(AdaptTheme.Font.bodyText)
                } else if routines.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
        }
        .navigationTitle("Rutinas")
        .navigationDestination(for: String.self) { routineId in
            RoutinePlayerView(routineId: routineId)
        }
        .task { await loadRoutines() }
        .refreshable { await loadRoutines() }
    }

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AdaptTheme.Spacing.md) {
                if authService.isGuestMode {
                    GuestModeBanner()
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }

                HStack {
                    AdaptEyebrow("Hoy")
                    Spacer()
                    Text("\(routines.prefix(config.itemsPerScreen).count) rutinas")
                        .font(AdaptTheme.Font.caption)
                        .foregroundStyle(AdaptTheme.Color.textTertiary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                VStack(spacing: level <= 2 ? 12 : 10) {
                    ForEach(routines.prefix(config.itemsPerScreen)) { routine in
                        NavigationLink(value: routine.id) {
                            routineRow(routine)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)

                if routines.count > config.itemsPerScreen {
                    Text("Mostrando \(config.itemsPerScreen) de \(routines.count) rutinas")
                        .font(AdaptTheme.Font.caption)
                        .foregroundStyle(AdaptTheme.Color.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
            }
            .padding(.bottom, 32)
        }
    }

    @ViewBuilder
    private func routineRow(_ routine: RoutineResponse) -> some View {
        switch level {
        case 1:
            essentialRoutineRow(routine)
        case 2:
            simpleRoutineRow(routine)
        default:
            standardRoutineRow(routine)
        }
    }

    private func essentialRoutineRow(_ routine: RoutineResponse) -> some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(categoryTint(routine.category).opacity(0.18))
                    .frame(width: 72, height: 72)
                Image(systemName: iconForCategory(routine.category))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(categoryTint(routine.category))
            }

            Text(routine.title)
                .font(AdaptTheme.Font.title)
                .foregroundStyle(AdaptTheme.Color.textPrimary)
                .lineLimit(2)

            Spacer(minLength: 8)

            ZStack {
                Circle().fill(AdaptTheme.Palette.primary).frame(width: 48, height: 48)
                Image(systemName: "play.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            .shadow(color: AdaptTheme.Palette.primary.opacity(0.3), radius: 8, y: 4)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: AdaptTheme.Radius.lg, style: .continuous)
                .fill(AdaptTheme.Color.surface)
        )
    }

    private func simpleRoutineRow(_ routine: RoutineResponse) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(categoryTint(routine.category).opacity(0.18))
                    .frame(width: 52, height: 52)
                Image(systemName: iconForCategory(routine.category))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(categoryTint(routine.category))
            }

            Text(routine.title)
                .font(AdaptTheme.Font.sectionHead)
                .foregroundStyle(AdaptTheme.Color.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(AdaptTheme.Color.textTertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AdaptTheme.Radius.md, style: .continuous)
                .fill(AdaptTheme.Color.surface)
        )
    }

    private func standardRoutineRow(_ routine: RoutineResponse) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(categoryTint(routine.category).opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: iconForCategory(routine.category))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(categoryTint(routine.category))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(routine.title)
                    .font(AdaptTheme.Font.card)
                    .foregroundStyle(AdaptTheme.Color.textPrimary)

                HStack(spacing: 8) {
                    Text(categoryLabel(routine.category))
                    if let steps = routine.steps {
                        Circle().fill(AdaptTheme.Color.textTertiary).frame(width: 3, height: 3)
                        Text("\(steps.count) pasos")
                    }
                }
                .font(AdaptTheme.Font.caption)
                .foregroundStyle(AdaptTheme.Color.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(AdaptTheme.Color.textTertiary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: AdaptTheme.Radius.md, style: .continuous)
                .fill(AdaptTheme.Color.surface)
        )
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(AdaptTheme.Palette.primary.opacity(0.18))
                    .frame(width: 100, height: 100)
                Image(systemName: "list.bullet.clipboard.fill")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(AdaptTheme.Palette.primary)
            }
            VStack(spacing: 6) {
                Text("Sin rutinas")
                    .font(AdaptTheme.Font.title)
                    .foregroundStyle(AdaptTheme.Color.textPrimary)
                Text("Pide a tu cuidador que cree\nrutinas personalizadas para ti.")
                    .font(AdaptTheme.Font.bodyText)
                    .foregroundStyle(AdaptTheme.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 60)
    }

    private func loadRoutines() async {
        if authService.isGuestMode {
            routines = SampleData.routines
            isLoading = false
            return
        }
        do {
            routines = try await APIClient.shared.fetchRoutines()
        } catch {
            print("Failed to load routines: \(error)")
        }
        isLoading = false
    }

    private func iconForCategory(_ category: String) -> String {
        AppConstants.RoutineCategory(rawValue: category)?.icon ?? "star.fill"
    }

    private func categoryLabel(_ category: String) -> String {
        switch category {
        case "hygiene": return "Higiene"
        case "cooking": return "Cocina"
        case "medication": return "Medicamentos"
        case "exercise": return "Ejercicio"
        case "cleaning": return "Limpieza"
        case "social": return "Social"
        case "transit": return "Transporte"
        case "shopping": return "Compras"
        default: return category.capitalized
        }
    }

    private func categoryTint(_ category: String) -> Color {
        switch category {
        case "hygiene": return AdaptTheme.Palette.breath
        case "cooking": return AdaptTheme.Palette.warning
        case "medication": return AdaptTheme.Palette.success
        case "exercise": return AdaptTheme.Palette.family
        case "cleaning": return AdaptTheme.Palette.primary
        case "social": return AdaptTheme.Palette.caregiver
        default: return AdaptTheme.Palette.primary
        }
    }
}
