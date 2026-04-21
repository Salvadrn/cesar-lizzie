import Foundation
import SwiftData

@Model
public final class NNMoodEntry {
    @Attribute(.unique) public var id: String
    public var userId: String
    public var mood: String          // "great", "good", "okay", "bad", "terrible"
    public var energy: Int           // 1-5
    public var feelings: String?     // comma-separated: "tranquilo,agradecido,motivado"
    public var note: String?
    public var activities: String?   // comma-separated tags
    public var createdAt: Date

    public init(
        id: String = UUID().uuidString,
        userId: String = "",
        mood: String = "okay",
        energy: Int = 3,
        feelings: String? = nil,
        note: String? = nil,
        activities: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.mood = mood
        self.energy = energy
        self.feelings = feelings
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

    public var feelingsList: [String] {
        feelings?.components(separatedBy: ",").filter { !$0.isEmpty } ?? []
    }
}

/// Predefined feelings organized by category
public enum FeelingCategory: String, CaseIterable {
    case positive = "Positivos"
    case calm = "Tranquilos"
    case negative = "Difíciles"
    case physical = "Físicos"

    public var feelings: [(id: String, emoji: String, label: String)] {
        switch self {
        case .positive:
            return [
                ("feliz", "😊", "Feliz"),
                ("agradecido", "🙏", "Agradecido"),
                ("motivado", "💪", "Motivado"),
                ("emocionado", "🤩", "Emocionado"),
                ("orgulloso", "🌟", "Orgulloso"),
                ("esperanzado", "🌈", "Con esperanza"),
            ]
        case .calm:
            return [
                ("tranquilo", "😌", "Tranquilo"),
                ("relajado", "🧘", "Relajado"),
                ("seguro", "🛡️", "Seguro"),
                ("en_paz", "☮️", "En paz"),
            ]
        case .negative:
            return [
                ("ansioso", "😰", "Ansioso"),
                ("triste", "😢", "Triste"),
                ("frustrado", "😤", "Frustrado"),
                ("enojado", "😠", "Enojado"),
                ("confundido", "😵‍💫", "Confundido"),
                ("solo", "🥺", "Solo"),
                ("asustado", "😨", "Asustado"),
                ("abrumado", "🤯", "Abrumado"),
            ]
        case .physical:
            return [
                ("cansado", "😴", "Cansado"),
                ("con_dolor", "🤕", "Con dolor"),
                ("con_energia", "⚡", "Con energía"),
                ("enfermo", "🤒", "Enfermo"),
            ]
        }
    }
}

