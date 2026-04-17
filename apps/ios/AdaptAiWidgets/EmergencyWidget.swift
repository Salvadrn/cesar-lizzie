import SwiftUI
import WidgetKit
import AdaptAiKit

struct EmergencyEntry: TimelineEntry {
    let date: Date
    let contactName: String
}

struct EmergencyProvider: TimelineProvider {
    func placeholder(in context: Context) -> EmergencyEntry {
        EmergencyEntry(date: .now, contactName: "Mamá")
    }

    func getSnapshot(in context: Context, completion: @escaping (EmergencyEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EmergencyEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
        let name = defaults?.string(forKey: "emergencyContactName") ?? "Contacto"

        let entry = EmergencyEntry(date: .now, contactName: name)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct EmergencyWidget: Widget {
    let kind = "EmergencyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EmergencyProvider()) { entry in
            EmergencyWidgetView(entry: entry)
                .containerBackground(.red.opacity(0.15), for: .widget)
        }
        .configurationDisplayName("Emergencia")
        .description("Acceso rápido al botón de emergencia.")
        .supportedFamilies([.systemSmall])
    }
}

struct EmergencyWidgetView: View {
    let entry: EmergencyEntry

    var body: some View {
        // Deep link to emergency screen
        Link(destination: URL(string: "adaptai://emergency")!) {
            VStack(spacing: 12) {
                Image(systemName: "sos.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.red)

                Text("EMERGENCIA")
                    .font(.caption.bold())
                    .foregroundStyle(.red)

                Text("Llamar a \(entry.contactName)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
