import SwiftUI
import WidgetKit
import ActivityKit
import NeuroNavKit

struct RoutineLiveActivityWidget: Widget {
    let kind = "RoutineLiveActivity"

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RoutineActivityAttributes.self) { context in
            // Lock Screen view
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: iconForCategory(context.attributes.routineCategory))
                        .font(.title2)
                        .foregroundStyle(.blue)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.currentStepIndex + 1)/\(context.state.totalSteps)")
                        .font(.title3.bold())
                        .foregroundStyle(.blue)
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.currentStepTitle)
                        .font(.headline)
                        .lineLimit(2)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: stepProgress(context.state))
                        .tint(context.state.isStalled ? .orange : .blue)
                }
            } compactLeading: {
                Image(systemName: "list.bullet.clipboard.fill")
                    .foregroundStyle(.blue)
            } compactTrailing: {
                Text("Paso \(context.state.currentStepIndex + 1)/\(context.state.totalSteps)")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            } minimal: {
                Image(systemName: "list.bullet.clipboard.fill")
                    .foregroundStyle(.blue)
            }
        }
    }

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<RoutineActivityAttributes>) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: iconForCategory(context.attributes.routineCategory))
                    .foregroundStyle(.blue)
                Text(context.attributes.routineTitle)
                    .font(.headline)
                Spacer()
                Text("\(context.state.currentStepIndex + 1)/\(context.state.totalSteps)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
            }

            Text(context.state.currentStepTitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ProgressView(value: stepProgress(context.state))
                .tint(context.state.isStalled ? .orange : .blue)

            if context.state.isStalled {
                Text("Tómate tu tiempo")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
    }

    private func stepProgress(_ state: RoutineActivityAttributes.ContentState) -> Double {
        guard state.totalSteps > 0 else { return 0 }
        return Double(state.currentStepIndex) / Double(state.totalSteps)
    }

    private func iconForCategory(_ category: String) -> String {
        AppConstants.RoutineCategory(rawValue: category)?.icon ?? "star.fill"
    }
}
