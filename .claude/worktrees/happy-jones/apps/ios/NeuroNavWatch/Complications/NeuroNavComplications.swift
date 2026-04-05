import SwiftUI
import WidgetKit

struct NeuroNavComplicationEntry: TimelineEntry {
    let date: Date
    let nextRoutineTitle: String?
    let dailyProgress: Double
}

struct NextRoutineComplication: Widget {
    let kind = "NextRoutineComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ComplicationProvider()) { entry in
            VStack(spacing: 2) {
                Image(systemName: "list.bullet.clipboard")
                    .font(.caption)
                    .foregroundStyle(.blue)

                if let title = entry.nextRoutineTitle {
                    Text(title)
                        .font(.caption2)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Sin rutinas")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .configurationDisplayName("Próxima Rutina")
        .description("Muestra la próxima rutina del día.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner,
        ])
    }
}

struct DailyProgressComplication: Widget {
    let kind = "DailyProgressComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ComplicationProvider()) { entry in
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 2) {
                    Gauge(value: entry.dailyProgress) {
                        Image(systemName: "brain.head.profile.fill")
                    }
                    .gaugeStyle(.accessoryCircularCapacity)
                    .tint(.blue)
                }
            }
        }
        .configurationDisplayName("Progreso Diario")
        .description("Muestra el progreso de rutinas completadas hoy.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct ComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> NeuroNavComplicationEntry {
        NeuroNavComplicationEntry(date: .now, nextRoutineTitle: "Higiene Matutina", dailyProgress: 0.6)
    }

    func getSnapshot(in context: Context, completion: @escaping (NeuroNavComplicationEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NeuroNavComplicationEntry>) -> Void) {
        let entry = NeuroNavComplicationEntry(
            date: .now,
            nextRoutineTitle: WatchConnectivityManager.shared.todayRoutines.first?.title,
            dailyProgress: calculateDailyProgress()
        )
        let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(15 * 60)))
        completion(timeline)
    }

    private func calculateDailyProgress() -> Double {
        let manager = WatchConnectivityManager.shared
        guard !manager.todayRoutines.isEmpty else { return 0 }
        let completed = Double(manager.completedRoutineIds.count)
        return completed / Double(manager.todayRoutines.count)
    }
}
