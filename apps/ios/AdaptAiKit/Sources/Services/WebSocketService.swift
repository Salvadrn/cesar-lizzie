import Foundation
import Supabase


@Observable
public final class WebSocketService {
    public static let shared = WebSocketService()

    public var isConnected = false
    public var onAlert: ((AlertResponse) -> Void)?

    private let supabase = SupabaseManager.shared.client
    private var channel: RealtimeChannelV2?

    private init() {}

    public func connect() async {
        // Listen for new alerts in real-time
        channel = supabase.realtimeV2.channel("alerts-channel")

        let insertions = channel?.postgresChange(InsertAction.self, table: "alerts")

        await channel?.subscribe()
        isConnected = true

        if let insertions {
            Task {
                for await insertion in insertions {
                    if let record = insertion.record as? [String: Any],
                       let id = record["id"] as? String,
                       let alertType = record["alert_type"] as? String,
                       let severity = record["severity"] as? String,
                       let title = record["title"] as? String,
                       let createdAt = record["created_at"] as? String {
                        let alert = AlertResponse(
                            id: id,
                            alertType: alertType,
                            severity: severity,
                            title: title,
                            message: record["message"] as? String,
                            isRead: false,
                            createdAt: createdAt
                        )
                        await MainActor.run {
                            self.onAlert?(alert)
                        }
                    }
                }
            }
        }
    }

    public func disconnect() async {
        await channel?.unsubscribe()
        channel = nil
        isConnected = false
    }
}
