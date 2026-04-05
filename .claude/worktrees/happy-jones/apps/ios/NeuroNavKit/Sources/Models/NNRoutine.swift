import Foundation
import SwiftData

@Model
public final class NNRoutine {
    @Attribute(.unique) public var id: String
    public var title: String
    public var routineDescription: String
    public var category: String
    public var isActive: Bool
    public var assignedTo: String?
    public var scheduleCron: String?
    public var scheduleType: String?
    public var complexityLevel: Int
    @Relationship(deleteRule: .cascade) public var steps: [NNRoutineStep]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String,
        title: String,
        routineDescription: String = "",
        category: String = "custom",
        isActive: Bool = true,
        assignedTo: String? = nil,
        scheduleCron: String? = nil,
        scheduleType: String? = nil,
        complexityLevel: Int = 3,
        steps: [NNRoutineStep] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.routineDescription = routineDescription
        self.category = category
        self.isActive = isActive
        self.assignedTo = assignedTo
        self.scheduleCron = scheduleCron
        self.scheduleType = scheduleType
        self.complexityLevel = complexityLevel
        self.steps = steps
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
