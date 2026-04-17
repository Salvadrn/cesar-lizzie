import SwiftUI
import WidgetKit
import AdaptAiKit

struct DailyProgressEntry: TimelineEntry {
    let date: Date
    let completedCount: Int
    let totalCount: Int
}

struct DailyProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyProgressEntry {
        DailyProgressEntry(date: .now, completedCount: 3, totalCount: 5)
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyProgressEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyProgressEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
        let completed = defaults?.integer(forKey: "dailyCompleted") ?? 0
        let total = defaults?.integer(forKey: "dailyTotal") ?? 0

        let entry = DailyProgressEntry(date: .now, completedCount: completed, totalCount: total)
        let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(15 * 60)))
        completion(timeline)
    }
}

struct DailyProgressWidget: Widget {
    let kind = "DailyProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyProgressProvider()) { entry in
            DailyProgressWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Progreso Diario")
        .description("Muestra cuántas rutinas has completado hoy.")
        .supportedFamilies([.systemSmall])
    }
}

struct DailyProgressWidgetView: View {
    let entry: DailyProgressEntry

    private var progress: Double {
        guard entry.totalCount > 0 else { return 0 }
        return Double(entry.completedCount) / Double(entry.totalCount)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(entry.completedCount)")
                        .font(.title.bold())
                    Text("de \(entry.totalCount)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(4)

            Text("Hoy")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(4)
    }
}
