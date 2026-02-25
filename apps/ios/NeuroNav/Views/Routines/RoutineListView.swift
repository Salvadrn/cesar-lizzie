import SwiftUI
import NeuroNavKit

struct RoutineListView: View {
    @Environment(AuthService.self) private var authService
    @State private var routines: [RoutineResponse] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Cargando rutinas...")
            } else if routines.isEmpty {
                ContentUnavailableView {
                    Label("Sin rutinas", systemImage: "list.bullet.clipboard")
                } description: {
                    Text("Pide a tu cuidador que cree rutinas para ti.")
                }
            } else {
                List {
                    if authService.isGuestMode {
                        Section {
                            GuestModeBanner()
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                        }
                    }

                    ForEach(routines) { routine in
                        NavigationLink(value: routine.id) {
                            HStack(spacing: 14) {
                                Image(systemName: iconForCategory(routine.category))
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                    .frame(width: 40)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(routine.title)
                                        .font(.headline)

                                    HStack(spacing: 8) {
                                        Text(routine.category.capitalized)
                                        if let steps = routine.steps {
                                            Text("·")
                                            Text("\(steps.count) pasos")
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Rutinas")
        .navigationDestination(for: String.self) { routineId in
            RoutinePlayerView(routineId: routineId)
        }
        .task { await loadRoutines() }
        .refreshable { await loadRoutines() }
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
