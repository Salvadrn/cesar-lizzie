import Foundation
import SwiftData
import NeuroNavKit

@Observable
final class GamificationViewModel {
    var stats: NNUserStats?
    var achievements: [NNAchievement] = []
    var showUnlockAnimation = false
    var lastUnlockedAchievement: NNAchievement?

    // Points per action
    static let pointsPerRoutine = 50
    static let pointsPerMedication = 30
    static let pointsPerMoodCheckIn = 15
    static let pointsPerStreak = 100

    var levelName: String {
        guard let pts = stats?.totalPoints else { return "Principiante" }
        switch pts {
        case 0..<200: return "Principiante"
        case 200..<500: return "Aprendiz"
        case 500..<1000: return "Constante"
        case 1000..<2500: return "Experto"
        default: return "Maestro"
        }
    }

    var levelIcon: String {
        guard let pts = stats?.totalPoints else { return "star" }
        switch pts {
        case 0..<200: return "star"
        case 200..<500: return "star.leadinghalf.filled"
        case 500..<1000: return "star.fill"
        case 1000..<2500: return "star.circle.fill"
        default: return "crown.fill"
        }
    }

    var nextLevelPoints: Int {
        guard let pts = stats?.totalPoints else { return 200 }
        switch pts {
        case 0..<200: return 200
        case 200..<500: return 500
        case 500..<1000: return 1000
        case 1000..<2500: return 2500
        default: return 5000
        }
    }

    var levelProgress: Double {
        guard let pts = stats?.totalPoints else { return 0 }
        let prevThreshold: Int
        switch pts {
        case 0..<200: prevThreshold = 0
        case 200..<500: prevThreshold = 200
        case 500..<1000: prevThreshold = 500
        case 1000..<2500: prevThreshold = 1000
        default: prevThreshold = 2500
        }
        let range = nextLevelPoints - prevThreshold
        let progress = pts - prevThreshold
        return min(1.0, Double(progress) / Double(range))
    }

    @MainActor
    func loadStats(context: ModelContext, userId: String) {
        let descriptor = FetchDescriptor<NNUserStats>(
            predicate: #Predicate { $0.userId == userId }
        )
        do {
            let results = try context.fetch(descriptor)
            if let existing = results.first {
                stats = existing
            } else {
                let newStats = NNUserStats(userId: userId)
                context.insert(newStats)
                stats = newStats
            }
        } catch {
            print("Error loading stats: \(error)")
        }

        loadAchievements(context: context, userId: userId)
    }

    @MainActor
    func loadAchievements(context: ModelContext, userId: String) {
        let descriptor = FetchDescriptor<NNAchievement>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\NNAchievement.unlockedAt, order: .reverse)]
        )
        do {
            achievements = try context.fetch(descriptor)
            if achievements.isEmpty {
                seedAchievements(context: context, userId: userId)
            }
        } catch {
            print("Error loading achievements: \(error)")
        }
    }

    @MainActor
    func addPoints(_ points: Int, context: ModelContext) {
        stats?.totalPoints = (stats?.totalPoints ?? 0) + points
    }

    @MainActor
    func recordRoutineCompletion(context: ModelContext, userId: String) {
        guard let stats else { return }
        stats.routinesCompleted += 1
        stats.totalPoints += Self.pointsPerRoutine
        updateStreak(stats: stats)
        checkAchievements(context: context, userId: userId)
    }

    @MainActor
    func recordMedicationTaken(context: ModelContext, userId: String) {
        guard let stats else { return }
        stats.medicationsTaken += 1
        stats.totalPoints += Self.pointsPerMedication
        updateStreak(stats: stats)
        checkAchievements(context: context, userId: userId)
    }

    @MainActor
    func recordMoodCheckIn(context: ModelContext, userId: String) {
        guard let stats else { return }
        stats.moodEntriesLogged += 1
        stats.totalPoints += Self.pointsPerMoodCheckIn
        updateStreak(stats: stats)
        checkAchievements(context: context, userId: userId)
    }

    private func updateStreak(stats: NNUserStats) {
        let calendar = Calendar.current
        if let lastActive = stats.lastActiveDate,
           calendar.isDateInYesterday(lastActive) {
            stats.currentStreak += 1
            if stats.currentStreak > stats.longestStreak {
                stats.longestStreak = stats.currentStreak
            }
        } else if let lastActive = stats.lastActiveDate,
                  !calendar.isDateInToday(lastActive) {
            stats.currentStreak = 1
        }
        stats.lastActiveDate = Date()
    }

    @MainActor
    private func checkAchievements(context: ModelContext, userId: String) {
        guard let stats else { return }

        let checks: [(String, Bool)] = [
            ("first_routine", stats.routinesCompleted >= 1),
            ("first_medication", stats.medicationsTaken >= 1),
            ("streak_3", stats.currentStreak >= 3),
            ("streak_7", stats.currentStreak >= 7),
            ("streak_30", stats.currentStreak >= 30),
            ("routines_10", stats.routinesCompleted >= 10),
            ("routines_50", stats.routinesCompleted >= 50),
            ("medications_10", stats.medicationsTaken >= 10),
            ("points_500", stats.totalPoints >= 500),
            ("points_1000", stats.totalPoints >= 1000),
        ]

        for (type, met) in checks {
            if met, let achievement = achievements.first(where: { $0.achievementType == type }),
               !achievement.isUnlocked {
                achievement.unlockedAt = Date()
                achievement.progress = 1.0
                lastUnlockedAchievement = achievement
                showUnlockAnimation = true
            }
        }
    }

    @MainActor
    private func seedAchievements(context: ModelContext, userId: String) {
        let definitions: [(String, String, String, String)] = [
            ("first_routine", "Primera Rutina", "Completa tu primera rutina", "checkmark.circle.fill"),
            ("first_medication", "Primera Medicina", "Toma tu primera medicina a tiempo", "pill.circle.fill"),
            ("streak_3", "3 Días Seguidos", "Mantén una racha de 3 días", "flame.fill"),
            ("streak_7", "Semana Perfecta", "Mantén una racha de 7 días", "flame.circle.fill"),
            ("streak_30", "Mes Imparable", "Mantén una racha de 30 días", "trophy.fill"),
            ("routines_10", "10 Rutinas", "Completa 10 rutinas en total", "list.clipboard.fill"),
            ("routines_50", "50 Rutinas", "Completa 50 rutinas en total", "star.circle.fill"),
            ("medications_10", "Constancia", "Toma 10 medicinas a tiempo", "heart.circle.fill"),
            ("points_500", "500 Puntos", "Acumula 500 puntos", "bolt.circle.fill"),
            ("points_1000", "1000 Puntos", "Acumula 1000 puntos", "crown.fill"),
        ]

        for (type, title, subtitle, icon) in definitions {
            let achievement = NNAchievement(
                userId: userId,
                achievementType: type,
                title: title,
                subtitle: subtitle,
                icon: icon
            )
            context.insert(achievement)
            achievements.append(achievement)
        }
    }
}
