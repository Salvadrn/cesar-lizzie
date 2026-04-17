import Foundation
import AdaptAiKit


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
    private let sync = SyncService.shared
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

        let duration = Int(Date.now.timeIntervalSince(stepStartTime ?? .now))
        reportStepCompletion(duration: duration)

        haptics.success()

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
            await completeExecutionWithRetry(executionId: executionId)
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
            break
        }
    }

    // MARK: - Server Communication (with offline fallback)

    private func reportStepCompletion(duration: Int) {
        guard let executionId, let step = currentStep else { return }
        let stepId = step.id
        let errors = stepErrorCount
        let stalls = stepStallCount
        let rePrompts = stepRePromptCount

        Task {
            do {
                try await api.completeStep(
                    executionId: executionId,
                    stepId: stepId,
                    duration: duration,
                    errors: errors,
                    stalls: stalls,
                    rePrompts: rePrompts
                )
            } catch {
                enqueueStepCompletion(
                    executionId: executionId,
                    stepId: stepId,
                    duration: duration,
                    errors: errors,
                    stalls: stalls,
                    rePrompts: rePrompts
                )
            }
        }
    }

    private func completeExecution() {
        isCompleted = true
        cancelStallTimer()
        haptics.success()

        guard let executionId else { return }
        Task {
            await completeExecutionWithRetry(executionId: executionId)
        }
    }

    private func completeExecutionWithRetry(executionId: String) async {
        do {
            try await api.completeExecution(id: executionId)
        } catch {
            let payload: [String: Any] = [
                "status": AppConstants.ExecutionStatus.completed.rawValue,
                "completed_at": APIClient.iso8601.string(from: Date())
            ]
            if let data = try? JSONSerialization.data(withJSONObject: payload) {
                sync.enqueue(action: SyncService.PendingAction(
                    table: "routine_executions",
                    operation: "update",
                    data: data,
                    recordId: executionId
                ))
            }
        }
    }

    private func enqueueStepCompletion(executionId: String, stepId: String, duration: Int, errors: Int, stalls: Int, rePrompts: Int) {
        let payload: [String: Any] = [
            "execution_id": executionId,
            "step_id": stepId,
            "status": AppConstants.StepExecutionStatus.completed.rawValue,
            "duration_seconds": duration,
            "error_count": errors,
            "stall_count": stalls,
            "re_prompt_count": rePrompts
        ]
        if let data = try? JSONSerialization.data(withJSONObject: payload) {
            sync.enqueue(action: SyncService.PendingAction(
                table: "step_executions",
                operation: "insert",
                data: data,
                recordId: nil
            ))
        }
    }
}
