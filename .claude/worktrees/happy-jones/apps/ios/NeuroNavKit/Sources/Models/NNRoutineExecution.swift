import Foundation
import SwiftData

@Model
public final class NNRoutineExecution {
    @Attribute(.unique) public var id: String
    public var routineId: String
    public var userId: String
    public var status: String // "in_progress" | "completed" | "paused" | "abandoned"
    public var startedAt: Date
    public var completedAt: Date?
    public var completedSteps: Int
    public var totalSteps: Int
    public var errorCount: Int
    public var stallCount: Int
    @Relationship(deleteRule: .cascade) public var stepExecutions: [NNStepExecution]

    public init(
        id: String = UUID().uuidString,
        routineId: String,
        userId: String,
        status: String = "in_progress",
        startedAt: Date = .now,
        completedAt: Date? = nil,
        completedSteps: Int = 0,
        totalSteps: Int = 0,
        errorCount: Int = 0,
        stallCount: Int = 0,
        stepExecutions: [NNStepExecution] = []
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
        self.stepExecutions = stepExecutions
    }
}
