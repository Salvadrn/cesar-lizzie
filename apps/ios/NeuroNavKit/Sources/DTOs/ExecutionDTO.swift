import Foundation

// Flutter equivalent: execution_dto.dart with json_serializable

public struct StartExecutionRequest: Codable {
    public let routineId: String

    public init(routineId: String) {
        self.routineId = routineId
    }
}

public struct ExecutionResponse: Codable, Identifiable {
    public let id: String
    public let routineId: String
    public let userId: String
    public let status: String
    public let startedAt: String
    public let completedAt: String?
    public let completedSteps: Int
    public let totalSteps: Int
    public let errorCount: Int
    public let stallCount: Int

    public init(
        id: String,
        routineId: String,
        userId: String,
        status: String,
        startedAt: String,
        completedAt: String?,
        completedSteps: Int,
        totalSteps: Int,
        errorCount: Int,
        stallCount: Int
    ) {
        self.id = id
        self.routineId = routineId
        self.userId = userId
        self.status = status
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.completedSteps = completedSteps
        self.totalSteps = totalSteps
        self.errorCount = errorCount
        self.stallCount = stallCount
    }
}

public struct StepCompletionRequest: Codable {
    public let stepId: String
    public let durationSeconds: Int
    public let errorCount: Int
    public let stallCount: Int
    public let rePromptCount: Int

    public init(
        stepId: String,
        durationSeconds: Int,
        errorCount: Int,
        stallCount: Int,
        rePromptCount: Int
    ) {
        self.stepId = stepId
        self.durationSeconds = durationSeconds
        self.errorCount = errorCount
        self.stallCount = stallCount
        self.rePromptCount = rePromptCount
    }
}

public struct CompleteExecutionResponse: Codable {
    public let id: String
    public let status: String
    public let completedAt: String
    public let completedSteps: Int
    public let totalSteps: Int

    public init(
        id: String,
        status: String,
        completedAt: String,
        completedSteps: Int,
        totalSteps: Int
    ) {
        self.id = id
        self.status = status
        self.completedAt = completedAt
        self.completedSteps = completedSteps
        self.totalSteps = totalSteps
    }
}
