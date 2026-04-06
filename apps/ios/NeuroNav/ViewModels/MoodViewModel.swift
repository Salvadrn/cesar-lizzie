import Foundation
import SwiftData
import NeuroNavKit

@Observable
final class MoodViewModel {
    var todayEntry: NNMoodEntry?
    var weekEntries: [NNMoodEntry] = []
    var selectedMood: String = "okay"
    var selectedEnergy: Int = 3
    var note: String = ""
    var showingCheckIn = false
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

        let descriptor = FetchDescriptor<NNMoodEntry>(
            predicate: #Predicate { $0.userId == userId && $0.createdAt >= weekAgo },
            sortBy: [SortDescriptor(\NNMoodEntry.createdAt, order: .reverse)]
        )

        do {
            weekEntries = try context.fetch(descriptor)
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
            note: note.isEmpty ? nil : note,
            activities: selectedTags.isEmpty ? nil : selectedTags.joined(separator: ",")
        )
        context.insert(entry)
        todayEntry = entry
        hasCheckedInToday = true
        showingCheckIn = false

        // Reset form
        selectedMood = "okay"
        selectedEnergy = 3
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
