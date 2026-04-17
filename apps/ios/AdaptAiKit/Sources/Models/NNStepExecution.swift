import Foundation
import SwiftData

@Model
public final class NNStepExecution {
    @Attribute(.unique) public var id: String
    public var stepId: String
    public var status: String // "pending" | "in_progress" | "completed" | "skipped" | "error"
    public var startedAt: Date?
    public var completedAt: Date?
    public var durationSeconds: Int
    public var errorCount: Int
    public var stallCount: Int
    public var rePromptCount: Int

    public var execution: NNRoutineExecution?

    public init(
        id: String = UUID().uuidString,
        stepId: String,
        status: String = "pending",
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        durationSeconds: Int = 0,
        errorCount: Int = 0,
        stallCount: Int = 0,
        rePromptCount: Int = 0
    ) {
        self.id = id
        self.stepId = stepId
        self.status = status
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.durationSeconds = durationSeconds
        self.errorCount = errorCount
        self.stallCount = stallCount
        self.rePromptCount = rePromptCount
    }
}
