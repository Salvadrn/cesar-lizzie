import Foundation
import SwiftData

// Flutter equivalent: User model with json_serializable

@Model
public final class NNUser {
    @Attribute(.unique) public var id: String
    public var email: String
    public var displayName: String
    public var role: String // "user" | "caregiver" | "admin"
    public var profile: NNUserProfile?
    @Relationship(inverse: \NNCaregiverLink.user) public var caregiverLinks: [NNCaregiverLink]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String,
        email: String,
        displayName: String,
        role: String = "user",
        profile: NNUserProfile? = nil,
        caregiverLinks: [NNCaregiverLink] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.role = role
        self.profile = profile
        self.caregiverLinks = caregiverLinks
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
