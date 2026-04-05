import Foundation
import SwiftData

@Model
public final class NNAlert {
    @Attribute(.unique) public var id: String
    public var userId: String
    public var caregiverId: String?
    public var alertType: String // "routine_stuck" | "zone_exit" | "zone_enter" | "emergency" | "missed_routine" | "low_completion" | "lost_mode" | "system"
    public var severity: String  // "info" | "warning" | "critical"
    public var title: String
    public var message: String?
    public var isRead: Bool
    public var createdAt: Date

    public init(
        id: String = UUID().uuidString,
        userId: String,
        caregiverId: String? = nil,
        alertType: String,
        severity: String = "info",
        title: String = "",
        message: String? = nil,
        isRead: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.userId = userId
        self.caregiverId = caregiverId
        self.alertType = alertType
        self.severity = severity
        self.title = title
        self.message = message
        self.isRead = isRead
        self.createdAt = createdAt
    }
}
