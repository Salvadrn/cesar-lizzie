import SwiftUI
import AdaptAiKit

/// Lista de rutinas con estilo Assistive Access:
/// botones enormes, iconos grandes, sin elementos secundarios.
struct SimpleRoutineListView: View {
    @State private var vm = HomeViewModel()
    @State private var selectedRoutine: RoutineResponse?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if vm.isLoading {
                    ProgressView("Cargando...")
                        .font(.nnTitle2)
                        .padding(.top, 60)
                } else if vm.routines.isEmpty {
                    emptyView
                } else {
                    ForEach(vm.routines) { routine in
                        Button {
                            selectedRoutine = routine
                        } label: {
                            routineRow(routine)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Mis Rutinas")
        .task { await vm.load() }
        .fullScreenCover(item: $selectedRoutine) { routine in
            NavigationStack {
                RoutinePlayerView(routineId: routine.id)
            }
        }
    }

    private func routineRow(_ routine: RoutineResponse) -> some View {
        HStack(spacing: 20) {
            Image(systemName: iconFor(category: routine.category))
                .font(.system(size: 48))
                .foregroundStyle(colorFor(category: routine.category))
                .frame(width: 70)

            VStack(alignment: .leading, spacing: 6) {
                Text(routine.title)
                    .font(.nnTitle2)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                if let steps = routine.steps?.count {
                    Text("\(steps) pasos")
                        .font(.nnTitle3)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "play.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(colorFor(category: routine.category))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(colorFor(category: routine.category).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.clipboard")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)
            Text("Aún no tienes rutinas")
                .font(.nnTitle2)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 80)
    }

    private func iconFor(category: String) -> String {
        switch category {
        case "hygiene": return "shower.fill"
        case "cooking": return "fork.knife"
        case "medication": return "pills.fill"
        case "exercise": return "figure.walk"
        case "cleaning": return "sparkles"
        default: return "checklist"
        }
    }

    private func colorFor(category: String) -> Color {
        switch category {
        case "hygiene": return .cyan
        case "cooking": return .orange
        case "medication": return .green
        case "exercise": return .purple
        case "cleaning": return .blue
        default: return .blue
        }
    }
}
