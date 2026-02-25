import Foundation
import SwiftData

@Model
public final class NNRoutineStep {
    @Attribute(.unique) public var id: String
    public var stepOrder: Int
    public var title: String
    public var instruction: String
    public var instructionSimple: String
    public var instructionDetailed: String
    public var imageURL: String?
    public var audioURL: String?
    public var videoURL: String?
    public var durationHint: Int // seconds
    public var checkpoint: Bool

    public var routine: NNRoutine?

    public init(
        id: String = UUID().uuidString,
        stepOrder: Int = 1,
        title: String = "",
        instruction: String = "",
        instructionSimple: String = "",
        instructionDetailed: String = "",
        imageURL: String? = nil,
        audioURL: String? = nil,
        videoURL: String? = nil,
        durationHint: Int = 60,
        checkpoint: Bool = false
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
