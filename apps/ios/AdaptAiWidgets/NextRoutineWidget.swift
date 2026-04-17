import SwiftUI
import WidgetKit
import AdaptAiKit


struct NextRoutineEntry: TimelineEntry {
    let date: Date
    let routineTitle: String
    let routineCategory: String
    let stepsCount: Int
    let scheduledTime: String?
}

struct NextRoutineProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextRoutineEntry {
        NextRoutineEntry(
            date: .now,
            routineTitle: "Higiene Matutina",
            routineCategory: "hygiene",
            stepsCount: 5,
            scheduledTime: "8:00 AM"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NextRoutineEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextRoutineEntry>) -> Void) {
        // Read from App Group shared UserDefaults
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
        let title = defaults?.string(forKey: "nextRoutineTitle") ?? "Sin rutinas"
        let category = defaults?.string(forKey: "nextRoutineCategory") ?? "custom"
        let steps = defaults?.integer(forKey: "nextRoutineSteps") ?? 0
        let time = defaults?.string(forKey: "nextRoutineTime")

        let entry = NextRoutineEntry(
            date: .now,
            routineTitle: title,
            routineCategory: category,
            stepsCount: steps,
            scheduledTime: time
        )

        let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(30 * 60)))
        completion(timeline)
    }
}

struct NextRoutineWidget: Widget {
    let kind = "NextRoutineWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextRoutineProvider()) { entry in
            NextRoutineWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Próxima Rutina")
        .description("Muestra tu próxima rutina programada.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct NextRoutineWidgetView: View {
    let entry: NextRoutineEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForCategory(entry.routineCategory))
                    .font(.title2)
                    .foregroundStyle(.blue)

                Spacer()

                if let time = entry.scheduledTime {
                    Text(time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(entry.routineTitle)
                .font(.headline)
                .lineLimit(2)

            HStack {
                Text("\(entry.stepsCount) pasos")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("·")
                    .foregroundStyle(.secondary)

                Text(entry.routineCategory.capitalized)
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
        .padding(4)
    }

    private func iconForCategory(_ category: String) -> String {
        AppConstants.RoutineCategory(rawValue: category)?.icon ?? "star.fill"
    }
}
