import SwiftUI

struct WatchRoutinePlayerView: View {
    let routine: WatchRoutine
    @Environment(WatchConnectivityManager.self) private var connectivity
    @State private var currentStepIndex = 0
    @State private var isCompleted = false

    private var currentStep: WatchStep? {
        guard currentStepIndex < routine.steps.count else { return nil }
        return routine.steps[currentStepIndex]
    }

    private var progress: Double {
        guard !routine.steps.isEmpty else { return 0 }
        return Double(currentStepIndex) / Double(routine.steps.count)
    }

    var body: some View {
        if isCompleted {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)

                Text("Completada!")
                    .font(.headline)
            }
        } else if let step = currentStep {
            ScrollView {
                VStack(spacing: 16) {
                    // Progress
                    ProgressView(value: progress)
                        .tint(.blue)

                    Text("Paso \(currentStepIndex + 1)/\(routine.steps.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    // Instruction
                    Text(step.title)
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    Text(step.instruction)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)

                    // Big "Done" button
                    Button {
                        completeStep()
                    } label: {
                        Text("Listo")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            }
            .navigationTitle(routine.title)
        }
    }

    private func completeStep() {
        if let step = currentStep {
            connectivity.reportStepCompletion(routineId: routine.id, stepId: step.id)
        }
        currentStepIndex += 1
        if currentStepIndex >= routine.steps.count {
            isCompleted = true
        }
    }
}
