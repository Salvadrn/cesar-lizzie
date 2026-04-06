import Foundation
import SwiftData

@Model
public final class NNAchievement {
    @Attribute(.unique) public var id: String
    public var userId: String
    public var achievementType: String   // "streak_3", "streak_7", "first_routine", etc.
    public var title: String
    public var subtitle: String
    public var icon: String              // SF Symbol name
    public var unlockedAt: Date?
    public var progress: Double          // 0.0 - 1.0

    public init(
        id: String = UUID().uuidString,
        userId: String = "",
        achievementType: String,
        title: String,
        subtitle: String,
        icon: String,
        unlockedAt: Date? = nil,
        progress: Double = 0.0
    ) {
        self.id = id
        self.userId = userId
        self.achievementType = achievementType
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.unlockedAt = unlockedAt
        self.progress = progress
    }

    public var isUnlocked: Bool { unlockedAt != nil }
}

@Model
public final class NNUserStats {
    @Attribute(.unique) public var id: String
    public var userId: String
    public var totalPoints: Int
    public var currentStreak: Int
    public var longestStreak: Int
    public var routinesCompleted: Int
    public var medicationsTaken: Int
    public var moodEntriesLogged: Int
    public var lastActiveDate: Date?

    public init(
        id: String = UUID().uuidString,
        userId: String = "",
        totalPoints: Int = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        routinesCompleted: Int = 0,
        medicationsTaken: Int = 0,
        moodEntriesLogged: Int = 0,
        lastActiveDate: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.totalPoints = totalPoints
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.routinesCompleted = routinesCompleted
        self.medicationsTaken = medicationsTaken
        self.moodEntriesLogged = moodEntriesLogged
        self.lastActiveDate = lastActiveDate
    }
}
