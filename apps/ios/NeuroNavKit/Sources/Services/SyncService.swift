import Foundation
import Supabase


@Observable
public final class SyncService {
    public static let shared = SyncService()

    public var isSyncing = false
    public var pendingCount = 0

    private var pendingActions: [PendingAction] = []
    private let supabase = SupabaseManager.shared.client

    public struct PendingAction: Codable, Sendable {
        public let table: String
        public let operation: String  // "insert", "update", "delete"
        public let data: Data?
        public let recordId: String?

        public init(table: String, operation: String, data: Data?, recordId: String?) {
            self.table = table
            self.operation = operation
            self.data = data
            self.recordId = recordId
        }
    }

    private init() {}

    public func enqueue(action: PendingAction) {
        pendingActions.append(action)
        pendingCount = pendingActions.count
        saveQueueToDisk()
    }

    public func syncAll() async {
        guard !isSyncing, !pendingActions.isEmpty else { return }
        isSyncing = true

        var remaining: [PendingAction] = []
        for action in pendingActions {
            do {
                try await executeAction(action)
            } catch {
                remaining.append(action)
            }
        }

        pendingActions = remaining
        pendingCount = remaining.count
        isSyncing = false
        saveQueueToDisk()
    }

    private func executeAction(_ action: PendingAction) async throws {
        // Re-execute the pending action against Supabase
        // This is a simplified version - in production, you'd want more sophisticated retry logic
        guard let data = action.data else { return }

        switch action.operation {
        case "insert":
            try await supabase
                .from(action.table)
                .insert(AnyJSON(data: data))
                .execute()
        case "update":
            if let recordId = action.recordId {
                try await supabase
                    .from(action.table)
                    .update(AnyJSON(data: data))
                    .eq("id", value: recordId)
                    .execute()
            }
        default:
            break
        }
    }

    private func saveQueueToDisk() {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("sync_queue.json") else { return }
        if let data = try? JSONEncoder().encode(pendingActions) {
            try? data.write(to: url)
        }
    }

    public func loadQueueFromDisk() {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("sync_queue.json"),
              let data = try? Data(contentsOf: url),
              let actions = try? JSONDecoder().decode([PendingAction].self, from: data) else { return }
        pendingActions = actions
        pendingCount = actions.count
    }
}

// Helper for encoding raw JSON data
private struct AnyJSON: Encodable {
    let data: Data

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // Re-encode through JSONSerialization
            let reEncoded = try JSONSerialization.data(withJSONObject: dict)
            let value = try JSONDecoder().decode(AnyCodable.self, from: reEncoded)
            try container.encode(value)
        }
    }
}

private struct AnyCodable: Codable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) { value = string }
        else if let int = try? container.decode(Int.self) { value = int }
        else if let double = try? container.decode(Double.self) { value = double }
        else if let bool = try? container.decode(Bool.self) { value = bool }
        else { value = "" }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let s as String: try container.encode(s)
        case let i as Int: try container.encode(i)
        case let d as Double: try container.encode(d)
        case let b as Bool: try container.encode(b)
        default: try container.encodeNil()
        }
    }
}
