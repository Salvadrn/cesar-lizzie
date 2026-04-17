import SwiftUI
import AdaptAiKit

struct RoutineListView: View {
    @Environment(AuthService.self) private var authService
    @Environment(AdaptiveEngine.self) private var engine
    @Environment(\.colorScheme) private var colorScheme
    @State private var routines: [RoutineResponse] = []
    @State private var isLoading = true

    private var isDark: Bool { colorScheme == .dark }
    private var level: Int { engine.currentLevel }
    private var config: ComplexityLevelConfig { engine.levelConfig() }

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Cargando rutinas...")
            } else if routines.isEmpty {
                ContentUnavailableView {
                    Label("Sin rutinas", systemImage: "list.bullet.clipboard")
                } description: {
                    Text("Pide a tu cuidador que cree rutinas para ti.")
                        .font(.nnSubheadline)
                }
            } else {
                ScrollView {
                    VStack(spacing: level <= 2 ? 16 : 10) {
                        if authService.isGuestMode {
                            GuestModeBanner()
                                .padding(.horizontal, 16)
                        }

                        ForEach(routines.prefix(config.itemsPerScreen)) { routine in
                            NavigationLink(value: routine.id) {
                                routineRow(routine)
                            }
                            .buttonStyle(.plain)
                        }

                        // Show "more" indicator for levels that limit items
                        if routines.count > config.itemsPerScreen {
                            Text("Mostrando \(config.itemsPerScreen) de \(routines.count) rutinas")
                                .font(.nnCaption)
                                .foregroundStyle(.nnMidGray)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .background(isDark ? Color.nnNightBG : Color(.systemGroupedBackground))
            }
        }
        .navigationTitle("Rutinas")
        .navigationDestination(for: String.self) { routineId in
            RoutinePlayerView(routineId: routineId)
        }
        .task { await loadRoutines() }
        .refreshable { await loadRoutines() }
    }

    @ViewBuilder
    private func routineRow(_ routine: RoutineResponse) -> some View {
        switch level {
        case 1:
            // Essential: huge icon + title only
            HStack(spacing: 20) {
                Image(systemName: iconForCategory(routine.category))
                    .font(.system(size: 40))
                    .foregroundStyle(.nnPrimary)
                    .frame(width: 72, height: 72)
                    .background(Color.nnPrimary.opacity(isDark ? 0.15 : 0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                Text(routine.title)
                    .font(.nnTitle2)
                    .foregroundStyle(isDark ? .white : .nnDarkText)

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.nnPrimary)
            }
            .padding(16)
            .background(isDark ? Color.white.opacity(0.08) : .white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(isDark ? 0 : 0.05), radius: 6, y: 3)

        case 2:
            // Simple: icon + title + play button
            HStack(spacing: 14) {
                Image(systemName: iconForCategory(routine.category))
                    .font(.system(size: 28))
                    .foregroundStyle(.nnPrimary)
                    .frame(width: 52, height: 52)
                    .background(Color.nnPrimary.opacity(isDark ? 0.15 : 0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                Text(routine.title)
                    .font(.nnHeadline)
                    .foregroundStyle(isDark ? .white : .nnDarkText)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.nnCaption)
                    .foregroundStyle(.nnMidGray)
            }
            .padding(14)
            .background(isDark ? Color.white.opacity(0.08) : .white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(isDark ? 0 : 0.04), radius: 4, y: 2)

        default:
            // Standard+: icon + title + category + step count
            HStack(spacing: 14) {
                Image(systemName: iconForCategory(routine.category))
                    .font(.title2)
                    .foregroundStyle(.nnPrimary)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.title)
                        .font(.nnHeadline)
                        .foregroundStyle(isDark ? .white : .nnDarkText)

                    HStack(spacing: 8) {
                        Text(routine.category.capitalized)
                        if let steps = routine.steps {
                            Text("·")
                            Text("\(steps.count) pasos")
                        }
                    }
                    .font(.nnCaption)
                    .foregroundStyle(.nnMidGray)

                    if level >= 4, let desc = routine.description, !desc.isEmpty {
                        Text(desc)
                            .font(.nnCaption)
                            .foregroundStyle(.nnMidGray)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(isDark ? Color.white.opacity(0.06) : .white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
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
}
