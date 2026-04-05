import Foundation


public struct RoutineResponse: Codable, Identifiable {
    public let id: String
    public let title: String
    public let description: String?
    public let category: String
    public let isActive: Bool
    public let assignedTo: String?
    public let complexityLevel: Int?
    public let steps: [StepResponse]?
    public let createdAt: String?

    public init(
        id: String,
        title: String,
        description: String?,
        category: String,
        isActive: Bool,
        assignedTo: String?,
        complexityLevel: Int?,
        steps: [StepResponse]?,
        createdAt: String?
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.isActive = isActive
        self.assignedTo = assignedTo
        self.complexityLevel = complexityLevel
        self.steps = steps
        self.createdAt = createdAt
    }
}

public struct StepResponse: Codable, Identifiable {
    public let id: String
    public let stepOrder: Int
    public let title: String
    public let instruction: String
    public let instructionSimple: String?
    public let instructionDetailed: String?
    public let imageURL: String?
    public let audioURL: String?
    public let videoURL: String?
    public let durationHint: Int
    public let checkpoint: Bool

    public init(
        id: String,
        stepOrder: Int,
        title: String,
        instruction: String,
        instructionSimple: String?,
        instructionDetailed: String?,
        imageURL: String?,
        audioURL: String?,
        videoURL: String?,
        durationHint: Int,
        checkpoint: Bool
    ) {
        self.id = id
        self.stepOrder = stepOrder
        self.title = title
        self.instruction = instruction
        self.instructionSimple = instructionSimple
        self.instructionDetailed = instructionDetailed
        self.imageURL = imageURL
        self.audioURL = audioURL
        self.videoURL = videoURL
        self.durationHint = durationHint
        self.checkpoint = checkpoint
    }
}

public struct CreateRoutineRequest: Codable {
    public let title: String
    public let description: String?
    public let category: String

    public init(title: String, description: String?, category: String) {
        self.title = title
        self.description = description
        self.category = category
    }
}

public struct CreateStepRequest: Codable {
    public let title: String
    public let instruction: String
    public let instructionSimple: String?
    public let durationHint: Int
    public let checkpoint: Bool
    public let stepOrder: Int

    public init(
        title: String,
        instruction: String,
        instructionSimple: String?,
        durationHint: Int,
        checkpoint: Bool,
        stepOrder: Int
    ) {
        self.title = title
        self.instruction = instruction
        self.instructionSimple = instructionSimple
        self.durationHint = durationHint
        self.checkpoint = checkpoint
        self.stepOrder = stepOrder
    }
}
