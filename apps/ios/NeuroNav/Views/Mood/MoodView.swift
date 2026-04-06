import SwiftUI
import SwiftData
import NeuroNavKit

struct MoodView: View {
    @Environment(AdaptiveEngine.self) private var engine
    @Environment(AuthService.self) private var authService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var vm = MoodViewModel()

    private var level: Int { engine.currentLevel }
    private var isDark: Bool { colorScheme == .dark }

    private var userId: String {
        authService.userId?.uuidString ?? "guest"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Today's check-in card
                todayCard

                // Week overview
                if !vm.weekEntries.isEmpty {
                    weekOverview
                }

                // History
                if vm.weekEntries.count > 1 {
                    historySection
                }
            }
            .padding(16)
        }
        .background(isDark ? Color.nnNightBG : Color(.systemGroupedBackground))
        .navigationTitle(level <= 2 ? "Ánimo" : "Estado de Ánimo")
        .navigationBarTitleDisplayMode(level <= 2 ? .inline : .large)
        .sheet(isPresented: $vm.showingCheckIn) {
            MoodCheckInSheet(vm: vm, level: level, userId: userId, context: modelContext)
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            vm.loadEntries(context: modelContext, userId: userId)
        }
    }

    // MARK: - Today Card

    private var todayCard: some View {
        VStack(spacing: 16) {
            if let today = vm.todayEntry {
                // Already checked in
                HStack(spacing: 12) {
                    Text(today.moodEmoji)
                        .font(.system(size: level <= 2 ? 56 : 44))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(level <= 2 ? "Hoy" : "Hoy te sientes")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(today.moodLabel)
                            .font(level <= 2 ? .title.bold() : .title2.bold())
                    }
                    Spacer()

                    VStack(spacing: 2) {
                        Text("Energía")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { i in
                                Image(systemName: i <= today.energy ? "bolt.fill" : "bolt")
                                    .font(.caption2)
                                    .foregroundStyle(i <= today.energy ? .nnWarning : .nnMidGray)
                            }
                        }
                    }
                }

                if let note = today.note, !note.isEmpty, level >= 3 {
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                // Not checked in yet
                VStack(spacing: 12) {
                    Text(level <= 2 ? "¿Cómo estás?" : "¿Cómo te sientes hoy?")
                        .font(level <= 2 ? .title.bold() : .title2.bold())

                    Button {
                        vm.showingCheckIn = true
                    } label: {
                        Label(
                            level <= 2 ? "Registrar" : "Registrar mi estado",
                            systemImage: "face.smiling"
                        )
                        .font(level <= 2 ? .title3.bold() : .body.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, level <= 2 ? 16 : 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.nnPrimary)
                }
            }
        }
        .padding(20)
        .background(isDark ? Color(.systemGray6) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Week Overview

    private var weekOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(level <= 2 ? "Semana" : "Esta semana")
                    .font(.headline)
                Spacer()
                Text(vm.moodTrend)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                ForEach(weekDays(), id: \.0) { day, entry in
                    VStack(spacing: 6) {
                        Text(entry?.moodEmoji ?? "·")
                            .font(.title2)
                        Text(day)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(20)
        .background(isDark ? Color(.systemGray6) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Historial")
                .font(.headline)

            ForEach(vm.weekEntries.prefix(7)) { entry in
                HStack(spacing: 12) {
                    Text(entry.moodEmoji)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.moodLabel)
                            .font(.subheadline.bold())
                        Text(entry.createdAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= entry.energy ? "bolt.fill" : "bolt")
                                .font(.caption2)
                                .foregroundStyle(i <= entry.energy ? .nnWarning : .nnMidGray)
                        }
                    }
                }
                .padding(12)
                .background(isDark ? Color(.systemGray5) : Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(20)
        .background(isDark ? Color(.systemGray6) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func weekDays() -> [(String, NNMoodEntry?)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "es_MX")

        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            dayFormatter.dateFormat = "EEE"
            let label = dayFormatter.string(from: date).prefix(2).uppercased()
            let entry = vm.weekEntries.first { calendar.isDate($0.createdAt, inSameDayAs: date) }
            return (String(label), entry)
        }
    }
}

// MARK: - Check-In Sheet

struct MoodCheckInSheet: View {
    @Bindable var vm: MoodViewModel
    let level: Int
    let userId: String
    let context: ModelContext
    @Environment(\.dismiss) private var dismiss

    private let moods = [
        ("great", "😄", "Excelente"),
        ("good", "🙂", "Bien"),
        ("okay", "😐", "Normal"),
        ("bad", "😟", "Mal"),
        ("terrible", "😢", "Muy mal"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Mood selection
                    VStack(spacing: 12) {
                        Text(level <= 2 ? "¿Cómo estás?" : "¿Cómo te sientes?")
                            .font(level <= 2 ? .title.bold() : .title2.bold())

                        HStack(spacing: level <= 2 ? 16 : 12) {
                            ForEach(moods, id: \.0) { mood, emoji, label in
                                Button {
                                    vm.selectedMood = mood
                                } label: {
                                    VStack(spacing: 6) {
                                        Text(emoji)
                                            .font(.system(size: level <= 2 ? 44 : 36))
                                        if level >= 2 {
                                            Text(label)
                                                .font(.caption)
                                        }
                                    }
                                    .padding(10)
                                    .background(
                                        vm.selectedMood == mood
                                            ? Color.nnPrimary.opacity(0.15)
                                            : Color.clear
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                vm.selectedMood == mood ? Color.nnPrimary : .clear,
                                                lineWidth: 2
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Energy level
                    VStack(spacing: 8) {
                        Text(level <= 2 ? "Energía" : "Nivel de energía")
                            .font(.headline)

                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { i in
                                Button {
                                    vm.selectedEnergy = i
                                } label: {
                                    Image(systemName: i <= vm.selectedEnergy ? "bolt.fill" : "bolt")
                                        .font(level <= 2 ? .title : .title2)
                                        .foregroundStyle(i <= vm.selectedEnergy ? .nnWarning : .nnMidGray)
                                }
                            }
                        }
                    }

                    // Activity tags (level 3+)
                    if level >= 3 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Actividades")
                                .font(.headline)

                            FlowLayout(spacing: 8) {
                                ForEach(vm.availableTags, id: \.self) { tag in
                                    Button {
                                        if vm.selectedTags.contains(tag) {
                                            vm.selectedTags.remove(tag)
                                        } else {
                                            vm.selectedTags.insert(tag)
                                        }
                                    } label: {
                                        Text(tag.capitalized)
                                            .font(.subheadline)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                vm.selectedTags.contains(tag)
                                                    ? Color.nnPrimary
                                                    : Color(.systemGray5)
                                            )
                                            .foregroundStyle(
                                                vm.selectedTags.contains(tag) ? .white : .primary
                                            )
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }

                    // Note (level 3+)
                    if level >= 3 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nota (opcional)")
                                .font(.headline)
                            TextField("¿Algo más que quieras anotar?", text: $vm.note, axis: .vertical)
                                .lineLimit(2...4)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    // Save button
                    Button {
                        vm.saveMoodEntry(context: context, userId: userId)
                    } label: {
                        Text(level <= 2 ? "Guardar" : "Guardar registro")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, level <= 2 ? 16 : 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.nnPrimary)
                }
                .padding(20)
            }
            .navigationTitle(level <= 2 ? "Ánimo" : "Registrar estado")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
