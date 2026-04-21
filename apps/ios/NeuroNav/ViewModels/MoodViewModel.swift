import Foundation
import SwiftData
import NeuroNavKit

@Observable
final class MoodViewModel {
    var todayEntry: NNMoodEntry?
    var weekEntries: [NNMoodEntry] = []
    var allEntries: [NNMoodEntry] = []
    var selectedMood: String = "okay"
    var selectedEnergy: Int = 3
    var selectedFeelings: Set<String> = []
    var note: String = ""
    var showingCheckIn = false
    var showingJournal = false
    var hasCheckedInToday = false

    private let activityTags = [
        "ejercicio", "familia", "trabajo", "descanso",
        "música", "paseo", "lectura", "cocina"
    ]

    var availableTags: [String] { activityTags }
    var selectedTags: Set<String> = []

    @MainActor
    func loadEntries(context: ModelContext, userId: String) {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: startOfToday)!
        let monthAgo = calendar.date(byAdding: .day, value: -30, to: startOfToday)!

        let weekDescriptor = FetchDescriptor<NNMoodEntry>(
            predicate: #Predicate { $0.userId == userId && $0.createdAt >= weekAgo },
            sortBy: [SortDescriptor(\NNMoodEntry.createdAt, order: .reverse)]
        )

        let allDescriptor = FetchDescriptor<NNMoodEntry>(
            predicate: #Predicate { $0.userId == userId && $0.createdAt >= monthAgo },
            sortBy: [SortDescriptor(\NNMoodEntry.createdAt, order: .reverse)]
        )

        do {
            weekEntries = try context.fetch(weekDescriptor)
            allEntries = try context.fetch(allDescriptor)
            todayEntry = weekEntries.first { calendar.isDateInToday($0.createdAt) }
            hasCheckedInToday = todayEntry != nil
        } catch {
            print("Error loading mood entries: \(error)")
        }
    }

    @MainActor
    func saveMoodEntry(context: ModelContext, userId: String) {
        let entry = NNMoodEntry(
            userId: userId,
            mood: selectedMood,
            energy: selectedEnergy,
            feelings: selectedFeelings.isEmpty ? nil : selectedFeelings.joined(separator: ","),
            note: note.isEmpty ? nil : note,
            activities: selectedTags.isEmpty ? nil : selectedTags.joined(separator: ",")
        )
        context.insert(entry)
        todayEntry = entry
        hasCheckedInToday = true
        showingCheckIn = false

        selectedMood = "okay"
        selectedEnergy = 3
        selectedFeelings = []
        note = ""
        selectedTags = []
    }

    var moodTrend: String {
        guard weekEntries.count >= 2 else { return "Sin datos suficientes" }
        let moodValues = weekEntries.map { moodScore($0.mood) }
        let avg = Double(moodValues.reduce(0, +)) / Double(moodValues.count)
        if avg >= 4.0 { return "Excelente semana" }
        if avg >= 3.0 { return "Buena semana" }
        if avg >= 2.0 { return "Semana regular" }
        return "Semana difícil"
    }

    /// Most frequent feelings in the last 30 days
    var topFeelings: [(feeling: String, count: Int)] {
        var counts: [String: Int] = [:]
        for entry in allEntries {
            for feeling in entry.feelingsList {
                counts[feeling, default: 0] += 1
            }
        }
        return counts.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
    }

    /// Feeling emoji lookup
    func emojiFor(_ feelingId: String) -> String {
        for category in FeelingCategory.allCases {
            if let match = category.feelings.first(where: { $0.id == feelingId }) {
                return match.emoji
            }
        }
        return "💭"
    }

    /// Feeling label lookup
    func labelFor(_ feelingId: String) -> String {
        for category in FeelingCategory.allCases {
            if let match = category.feelings.first(where: { $0.id == feelingId }) {
                return match.label
            }
        }
        return feelingId.capitalized
    }

    private func moodScore(_ mood: String) -> Int {
        switch mood {
        case "great": return 5
        case "good": return 4
        case "okay": return 3
        case "bad": return 2
        case "terrible": return 1
        default: return 3
        }
    }
}
