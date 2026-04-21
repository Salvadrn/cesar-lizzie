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
                todayCard
                if let today = vm.todayEntry, !today.feelingsList.isEmpty {
                    todayFeelingsCard(today)
                }
                if !vm.topFeelings.isEmpty, level >= 3 {
                    feelingsInsightsCard
                }
                if !vm.weekEntries.isEmpty {
                    weekOverview
                }
                if level >= 3, !vm.allEntries.isEmpty {
                    journalSection
                }
            }
            .padding(16)
        }
        .background(isDark ? Color.nnNightBG : Color(.systemGroupedBackground))
        .navigationTitle(level <= 2 ? "Sentimientos" : "Cómo me siento")
        .navigationBarTitleDisplayMode(level <= 2 ? .inline : .large)
        .sheet(isPresented: $vm.showingCheckIn) {
            MoodCheckInSheet(vm: vm, level: level, userId: userId, context: modelContext)
                .presentationDetents([.large])
        }
        .onAppear {
            vm.loadEntries(context: modelContext, userId: userId)
        }
    }

    // MARK: - Today Card

    private var todayCard: some View {
        VStack(spacing: 16) {
            if let today = vm.todayEntry {
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
                        .padding(12)
                        .background(isDark ? Color(.systemGray5) : Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            } else {
                VStack(spacing: 12) {
                    Text(level <= 2 ? "¿Cómo estás?" : "¿Cómo te sientes hoy?")
                        .font(level <= 2 ? .title.bold() : .title2.bold())

                    Text(level <= 2
                         ? "Cuéntame cómo te sientes"
                         : "Registra tus emociones y sentimientos del día")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        vm.showingCheckIn = true
                    } label: {
                        Label(
                            level <= 2 ? "Registrar" : "Registrar mis sentimientos",
                            systemImage: "heart.circle.fill"
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

    // MARK: - Today's Feelings

    private func todayFeelingsCard(_ entry: NNMoodEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(level <= 2 ? "Sentimientos" : "Cómo me siento hoy")
                .font(.headline)

            FlowLayout(spacing: 8) {
                ForEach(entry.feelingsList, id: \.self) { feeling in
                    HStack(spacing: 4) {
                        Text(vm.emojiFor(feeling))
                        Text(vm.labelFor(feeling))
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.nnPrimary.opacity(0.1))
                    .foregroundStyle(.nnPrimary)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(20)
        .background(isDark ? Color(.systemGray6) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Feelings Insights

    private var feelingsInsightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.nnPrimary)
                Text("Mis sentimientos frecuentes")
                    .font(.headline)
            }

            Text("Últimos 30 días")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(vm.topFeelings, id: \.feeling) { item in
                HStack(spacing: 12) {
                    Text(vm.emojiFor(item.feeling))
                        .font(.title3)

                    Text(vm.labelFor(item.feeling))
                        .font(.subheadline)

                    Spacer()

                    // Bar
                    let maxCount = vm.topFeelings.first?.count ?? 1
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.nnPrimary.opacity(0.3))
                            .frame(
                                width: geo.size.width * CGFloat(item.count) / CGFloat(maxCount),
                                height: geo.size.height
                            )
                            .overlay(alignment: .trailing) {
                                Text("\(item.count)")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.nnPrimary)
                                    .padding(.trailing, 6)
                            }
                    }
                    .frame(width: 100, height: 22)
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

    // MARK: - Journal / Diary

    private var journalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundStyle(.nnFamily)
                Text("Diario emocional")
                    .font(.headline)
            }

            ForEach(vm.allEntries.prefix(10)) { entry in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(entry.moodEmoji)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.moodLabel)
                                .font(.subheadline.bold())
                            Text(entry.createdAt, format: .dateTime.day().month(.wide).hour().minute())
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

                    if !entry.feelingsList.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(entry.feelingsList.prefix(4), id: \.self) { f in
                                Text("\(vm.emojiFor(f)) \(vm.labelFor(f))")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.nnPrimary.opacity(0.08))
                                    .clipShape(Capsule())
                            }
                            if entry.feelingsList.count > 4 {
                                Text("+\(entry.feelingsList.count - 4)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if let note = entry.note, !note.isEmpty {
                        Text(note)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(14)
                .background(isDark ? Color(.systemGray5) : Color(.systemGray6).opacity(0.5))
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

// MARK: - Check-In Sheet (Enhanced with Feelings)

struct MoodCheckInSheet: View {
    @Bindable var vm: MoodViewModel
    let level: Int
    let userId: String
    let context: ModelContext
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0 // 0=mood, 1=feelings, 2=details

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
                VStack(spacing: 28) {
                    // Progress dots
                    if level >= 2 {
                        HStack(spacing: 8) {
                            ForEach(0..<(level >= 3 ? 3 : 2), id: \.self) { i in
                                Circle()
                                    .fill(i <= step ? Color.nnPrimary : Color.nnMidGray.opacity(0.3))
                                    .frame(width: 10, height: 10)
                            }
                        }
                    }

                    switch step {
                    case 0:
                        moodStep
                    case 1:
                        feelingsStep
                    default:
                        detailsStep
                    }
                }
                .padding(20)
            }
            .navigationTitle(
                step == 0 ? (level <= 2 ? "¿Cómo estás?" : "Estado de ánimo")
                : step == 1 ? "Sentimientos"
                : "Detalles"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }

    // MARK: - Step 0: Mood

    private var moodStep: some View {
        VStack(spacing: 24) {
            Text(level <= 2 ? "¿Cómo estás?" : "¿Cómo te sientes ahora mismo?")
                .font(level <= 2 ? .title.bold() : .title2.bold())
                .multilineTextAlignment(.center)

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
                                .stroke(vm.selectedMood == mood ? Color.nnPrimary : .clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
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

            Button {
                if level <= 1 {
                    vm.saveMoodEntry(context: context, userId: userId)
                } else {
                    withAnimation { step = 1 }
                }
            } label: {
                Text(level <= 1 ? "Guardar" : "Siguiente")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.nnPrimary)
        }
    }

    // MARK: - Step 1: Feelings

    private var feelingsStep: some View {
        VStack(spacing: 20) {
            Text(level <= 2
                 ? "¿Qué sientes?"
                 : "¿Qué sentimientos describes mejor?")
                .font(level <= 2 ? .title2.bold() : .title3.bold())
                .multilineTextAlignment(.center)

            Text("Selecciona los que apliquen")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(FeelingCategory.allCases, id: \.rawValue) { category in
                VStack(alignment: .leading, spacing: 10) {
                    Text(category.rawValue)
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)

                    FlowLayout(spacing: 8) {
                        ForEach(category.feelings, id: \.id) { feeling in
                            let isSelected = vm.selectedFeelings.contains(feeling.id)
                            Button {
                                if isSelected {
                                    vm.selectedFeelings.remove(feeling.id)
                                } else {
                                    vm.selectedFeelings.insert(feeling.id)
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(feeling.emoji)
                                    Text(feeling.label)
                                        .font(.subheadline)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(isSelected ? Color.nnPrimary : Color(.systemGray5))
                                .foregroundStyle(isSelected ? .white : .primary)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                Button {
                    withAnimation { step = 0 }
                } label: {
                    Text("Atrás")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)

                Button {
                    if level < 3 {
                        vm.saveMoodEntry(context: context, userId: userId)
                    } else {
                        withAnimation { step = 2 }
                    }
                } label: {
                    Text(level < 3 ? "Guardar" : "Siguiente")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.nnPrimary)
            }
        }
    }

    // MARK: - Step 2: Details (level 3+)

    private var detailsStep: some View {
        VStack(spacing: 20) {
            // Activity tags
            VStack(alignment: .leading, spacing: 8) {
                Text("¿Qué hiciste hoy?")
                    .font(.headline)

                FlowLayout(spacing: 8) {
                    ForEach(vm.availableTags, id: \.self) { tag in
                        let isSelected = vm.selectedTags.contains(tag)
                        Button {
                            if isSelected {
                                vm.selectedTags.remove(tag)
                            } else {
                                vm.selectedTags.insert(tag)
                            }
                        } label: {
                            Text(tag.capitalized)
                                .font(.subheadline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isSelected ? Color.nnPrimary : Color(.systemGray5))
                                .foregroundStyle(isSelected ? .white : .primary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // Note / journal entry
            VStack(alignment: .leading, spacing: 8) {
                Text("Diario (opcional)")
                    .font(.headline)
                Text("Escribe lo que quieras recordar de hoy")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("¿Cómo fue tu día? ¿Qué te hizo sentir así?", text: $vm.note, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Summary
            VStack(spacing: 8) {
                Text("Resumen")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 16) {
                    VStack {
                        Text(moods.first { $0.0 == vm.selectedMood }?.1 ?? "😐")
                            .font(.largeTitle)
                        Text("Ánimo")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { i in
                                Image(systemName: i <= vm.selectedEnergy ? "bolt.fill" : "bolt")
                                    .font(.caption)
                                    .foregroundStyle(i <= vm.selectedEnergy ? .nnWarning : .nnMidGray)
                            }
                        }
                        Text("Energía")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack {
                        Text("\(vm.selectedFeelings.count)")
                            .font(.title2.bold())
                        Text("Sentimientos")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.nnTint)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack(spacing: 12) {
                Button {
                    withAnimation { step = 1 }
                } label: {
                    Text("Atrás")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)

                Button {
                    vm.saveMoodEntry(context: context, userId: userId)
                } label: {
                    Text("Guardar")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.nnPrimary)
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
