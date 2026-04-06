import Foundation
import SwiftData

@Model
public final class NNMoodEntry {
    @Attribute(.unique) public var id: String
    public var userId: String
    public var mood: String          // "great", "good", "okay", "bad", "terrible"
    public var energy: Int           // 1-5
    public var note: String?
    public var activities: String?   // comma-separated tags
    public var createdAt: Date

    public init(
        id: String = UUID().uuidString,
        userId: String = "",
        mood: String = "okay",
        energy: Int = 3,
        note: String? = nil,
        activities: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.mood = mood
        self.energy = energy
        self.note = note
        self.activities = activities
        self.createdAt = createdAt
    }

    public var moodEmoji: String {
        switch mood {
        case "great": return "😄"
        case "good": return "🙂"
        case "okay": return "😐"
        case "bad": return "😟"
        case "terrible": return "😢"
        default: return "😐"
        }
    }

    public var moodLabel: String {
        switch mood {
        case "great": return "Excelente"
        case "good": return "Bien"
        case "okay": return "Normal"
        case "bad": return "Mal"
        case "terrible": return "Muy mal"
        default: return "Normal"
        }
    }
}
