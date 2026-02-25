import Foundation
import NeuroNavKit

// Flutter equivalent: routine_player_bloc.dart or routine_player_provider.dart

enum StallPhase: Int {
    case none = 0
    case visual = 1     // Show banner
    case audio = 2      // TTS re-prompt
    case haptic = 3     // CoreHaptics pulse
    case needHelp = 4   // "Need help?" alert
}

@Observable
final class RoutinePlayerViewModel {
    // State
    var routine: RoutineResponse?
    var steps: [StepResponse] = []
    var currentStepIndex = 0
    var executionId: String?
    var isLoading = true
    var isCompleted = false
    var isPaused = false
    var errorMessage: String?

    // Stall detection
    var stallPhase: StallPhase = .none
    var stallTimerSeconds = 0
    private var stallTask: Task<Void, Never>?

    // Step metrics
    var stepStartTime: Date?
    var stepErrorCount = 0
    var stepStallCount = 0
    var stepRePromptCount = 0

    // Overall metrics
    var totalErrors = 0
    var totalStalls = 0

    private let api = APIClient.shared
    private let speech = SpeechService.shared
    private let haptics = HapticsService.shared

    var currentStep: StepResponse? {
        guard currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }

    var progress: Double {
        guard !steps.isEmpty else { return 0 }
        return Double(currentStepIndex) / Double(steps.count)
    }

    var progressText: String {
        "\(currentStepIndex + 1) de \(steps.count)"
    }

    // MARK: - Lifecycle

    func loadRoutine(id: String) async {
        isLoading = true
        do {
            let response = try await api.fetchRoutine(id: id)
            routine = response
            steps = (response.steps ?? []).sorted { $0.stepOrder < $1.stepOrder }

            // Start execution on server
            let exec = try await api.startExecution(routineId: id)
            executionId = exec.id
            startStep()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Step Navigation

    func startStep() {
        guard currentStep != nil else { return }
        stepStartTime = .now
        stepErrorCount = 0
        stepStallCount = 0
        stepRePromptCount = 0
        stallPhase = .none
        startStallTimer()
    }

    func completeCurrentStep() {
        cancelStallTimer()
        speech.stop()

        // Record step metrics
        let duration = Int(Date.now.timeIntervalSince(stepStartTime ?? .now))
        reportStepCompletion(duration: duration)

        haptics.success()

        // Advance
        currentStepIndex += 1
        if currentStepIndex >= steps.count {
            completeExecution()
        } else {
            startStep()
        }
    }

    func markError() {
        stepErrorCount += 1
        totalErrors += 1
        haptics.error()
    }

    func pause() {
        isPaused = true
        cancelStallTimer()
        speech.stop()
    }

    func resume() {
        isPaused = false
        startStallTimer()
    }

    func abandon() {
        cancelStallTimer()
        speech.stop()
        guard let executionId else { return }
        Task {
            do {
                try await api.completeExecution(id: executionId)
            } catch {
                print("RoutinePlayer: Error al abandonar ejecución: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Stall Detection

    private func startStallTimer() {
        cancelStallTimer()
        stallTimerSeconds = 0
        stallPhase = .none

        guard let step = currentStep else { return }
        let stallThreshold = Double(step.durationHint) * 1.5

        stallTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, !self.isPaused else { continue }

                self.stallTimerSeconds += 1
                let elapsed = Double(self.stallTimerSeconds)

                if elapsed >= stallThreshold && self.stallPhase == .none {
                    self.triggerStallPhase(.visual)
                } else if elapsed >= stallThreshold + 10 && self.stallPhase == .visual {
                    self.triggerStallPhase(.audio)
                } else if elapsed >= stallThreshold + 20 && self.stallPhase == .audio {
                    self.triggerStallPhase(.haptic)
                } else if elapsed >= stallThreshold + 30 && self.stallPhase == .haptic {
                    self.triggerStallPhase(.needHelp)
                }
            }
        }
    }

    private func cancelStallTimer() {
        stallTask?.cancel()
        stallTask = nil
    }

    private func triggerStallPhase(_ phase: StallPhase) {
        stallPhase = phase
        stepStallCount += 1
        stepRePromptCount += 1
        totalStalls += 1

        switch phase {
        case .none: break
        case .visual:
            // Banner is shown via UI
            break
        case .audio:
            if let step = currentStep {
                let instruction = step.instructionSimple ?? step.instruction
                speech.speak("Recuerda: \(instruction)")
            }
        case .haptic:
            haptics.stallRePrompt()
        case .needHelp:
            haptics.warning()
            // The UI shows a "Need help?" prompt
            break
        }
    }

    // MARK: - Server Communication

    private func reportStepCompletion(duration: Int) {
        guard let executionId, let step = currentStep else { return }
        Task {
            do {
                try await api.completeStep(
                    executionId: executionId,
                    stepId: step.id,
                    duration: duration,
                    errors: stepErrorCount,
                    stalls: stepStallCount,
                    rePrompts: stepRePromptCount
                )
            } catch {
                print("RoutinePlayer: Error reportando paso: \(error.localizedDescription)")
            }
        }
    }

    private func completeExecution() {
        isCompleted = true
        cancelStallTimer()
        haptics.success()

        guard let executionId else { return }
        Task {
            do {
                try await api.completeExecution(id: executionId)
            } catch {
                print("RoutinePlayer: Error completando ejecución: \(error.localizedDescription)")
            }
        }
    }
}
