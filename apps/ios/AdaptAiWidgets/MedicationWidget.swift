import SwiftUI
import WidgetKit
import AdaptAiKit

struct MedicationEntry: TimelineEntry {
    let date: Date
    let medications: [MedicationItem]

    struct MedicationItem: Identifiable {
        let id: String
        let name: String
        let dosage: String
        let scheduledTime: Date
        let isTaken: Bool
        let reminderOffsets: [Int]

        var nextReminderLabel: String? {
            let filtered = reminderOffsets.filter { $0 > 0 }.sorted()
            guard !filtered.isEmpty else { return nil }
            return filtered.map { "\($0)min" }.joined(separator: ", ")
        }
    }
}

struct MedicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> MedicationEntry {
        MedicationEntry(date: .now, medications: [
            .init(id: "1", name: "Medicamento", dosage: "1 pastilla", scheduledTime: .now, isTaken: false, reminderOffsets: [5])
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (MedicationEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MedicationEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)

        var medications: [MedicationEntry.MedicationItem] = []

        if let data = defaults?.data(forKey: "medications"),
           let decoded = try? JSONDecoder().decode([SharedMedication].self, from: data) {
            let calendar = Calendar.current
            let now = Date()

            medications = decoded.compactMap { med in
                var components = calendar.dateComponents([.year, .month, .day], from: now)
                components.hour = med.hour
                components.minute = med.minute
                guard let scheduledTime = calendar.date(from: components) else { return nil }

                return MedicationEntry.MedicationItem(
                    id: med.id,
                    name: med.name,
                    dosage: med.dosage,
                    scheduledTime: scheduledTime,
                    isTaken: med.takenToday,
                    reminderOffsets: med.reminderOffsets
                )
            }
            .sorted { $0.scheduledTime < $1.scheduledTime }
        }

        let entry = MedicationEntry(date: .now, medications: medications)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct MedicationWidget: Widget {
    let kind = "MedicationWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MedicationProvider()) { entry in
            MedicationWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Medicamentos")
        .description("Recordatorio de medicamentos del día.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MedicationWidgetView: View {
    let entry: MedicationEntry

    private var pendingCount: Int {
        entry.medications.filter { !$0.isTaken }.count
    }

    var body: some View {
        if entry.medications.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "pills.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.blue)
                Text("Sin medicamentos")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "pills.fill")
                        .foregroundStyle(.blue)
                    Text("Medicamentos")
                        .font(.caption.bold())
                    Spacer()
                    if pendingCount > 0 {
                        Text("\(pendingCount) pendiente\(pendingCount == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                ForEach(entry.medications.prefix(3)) { med in
                    HStack(spacing: 8) {
                        Image(systemName: med.isTaken ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(med.isTaken ? .green : nextUpColor(for: med))
                            .font(.caption)

                        VStack(alignment: .leading, spacing: 0) {
                            Text(med.name)
                                .font(.caption2.bold())
                                .lineLimit(1)
                            HStack(spacing: 3) {
                                Text(med.dosage)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                if let label = med.nextReminderLabel {
                                    Image(systemName: "bell.fill")
                                        .font(.system(size: 7))
                                        .foregroundStyle(.orange)
                                    Text(label)
                                        .font(.system(size: 8))
                                        .foregroundStyle(.orange)
                                }
                            }
                        }

                        Spacer()

                        Text(med.scheduledTime, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if entry.medications.count > 3 {
                    Text("+\(entry.medications.count - 3) más")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func nextUpColor(for med: MedicationEntry.MedicationItem) -> Color {
        let diff = med.scheduledTime.timeIntervalSince(Date())
        if diff < 0 { return .red }
        if diff < 3600 { return .orange }
        return .primary
    }
}

// Shared data model matching SharedMedicationData from app
struct SharedMedication: Codable {
    let id: String
    let name: String
    let dosage: String
    let hour: Int
    let minute: Int
    let takenToday: Bool
    let reminderOffsets: [Int]
}
