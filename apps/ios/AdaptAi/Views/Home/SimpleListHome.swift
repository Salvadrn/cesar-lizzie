import SwiftUI
import AdaptAiKit

// Complexity Level 3: Icons with short phrases
struct SimpleListHome: View {
    let routines: [RoutineResponse]

    var body: some View {
        List(routines) { routine in
            NavigationLink(value: routine.id) {
                HStack(spacing: 16) {
                    Image(systemName: iconForCategory(routine.category))
                        .font(.system(size: 32))
                        .foregroundStyle(.blue)
                        .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(routine.title)
                            .font(.nnBody)

                        Text(routine.category.capitalized)
                            .font(.nnCaption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if let steps = routine.steps {
                        Text("\(steps.count) pasos")
                            .font(.nnCaption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(.insetGrouped)
        .navigationDestination(for: String.self) { routineId in
            RoutinePlayerView(routineId: routineId)
        }
    }

    private func iconForCategory(_ category: String) -> String {
        AppConstants.RoutineCategory(rawValue: category)?.icon ?? "star.fill"
    }
}
