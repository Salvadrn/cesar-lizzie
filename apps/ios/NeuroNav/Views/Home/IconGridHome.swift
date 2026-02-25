import SwiftUI
import NeuroNavKit

// Complexity Level 1-2: Large icons with minimal text
struct IconGridHome: View {
    let routines: [RoutineResponse]
    @Environment(AdaptiveEngine.self) private var engine

    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(routines) { routine in
                    NavigationLink(value: routine.id) {
                        VStack(spacing: 12) {
                            Image(systemName: iconForCategory(routine.category))
                                .font(.system(size: engine.levelConfig().buttonSize))
                                .foregroundStyle(.blue)

                            if engine.currentLevel >= 2 {
                                Text(routine.title)
                                    .font(.headline)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationDestination(for: String.self) { routineId in
            RoutinePlayerView(routineId: routineId)
        }
    }

    private func iconForCategory(_ category: String) -> String {
        AppConstants.RoutineCategory(rawValue: category)?.icon ?? "star.fill"
    }
}
