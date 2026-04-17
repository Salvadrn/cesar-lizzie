import Foundation


public struct AlertResponse: Codable, Identifiable {
    public let id: String
    public let alertType: String
    public let severity: String
    public let title: String
    public let message: String?
    public let isRead: Bool
    public let createdAt: String

    public init(
        id: String,
        alertType: String,
        severity: String,
        title: String,
        message: String?,
        isRead: Bool,
        createdAt: String
    ) {
        self.id = id
        self.alertType = alertType
        self.severity = severity
        self.title = title
        self.message = message
        self.isRead = isRead
        self.createdAt = createdAt
    }
}
