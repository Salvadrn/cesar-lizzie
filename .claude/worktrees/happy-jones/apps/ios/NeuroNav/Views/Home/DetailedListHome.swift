import SwiftUI
import NeuroNavKit

// Complexity Level 4-5: Full text interface with details
struct DetailedListHome: View {
    let routines: [RoutineResponse]

    var body: some View {
        List(routines) { routine in
            NavigationLink(value: routine.id) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: iconForCategory(routine.category))
                            .font(.title3)
                            .foregroundStyle(.blue)

                        Text(routine.title)
                            .font(.headline)

                        Spacer()

                        statusBadge(routine.isActive)
                    }

                    if let description = routine.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    HStack(spacing: 16) {
                        Label(routine.category.capitalized, systemImage: "tag")
                        if let steps = routine.steps {
                            Label("\(steps.count) pasos", systemImage: "list.number")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
        .navigationDestination(for: String.self) { routineId in
            RoutinePlayerView(routineId: routineId)
        }
    }

    @ViewBuilder
    private func statusBadge(_ isActive: Bool) -> some View {
        Text(isActive ? "Activa" : "Inactiva")
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(isActive ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
            .foregroundStyle(isActive ? .green : .gray)
            .clipShape(Capsule())
    }

    private func iconForCategory(_ category: String) -> String {
        AppConstants.RoutineCategory(rawValue: category)?.icon ?? "star.fill"
    }
}
