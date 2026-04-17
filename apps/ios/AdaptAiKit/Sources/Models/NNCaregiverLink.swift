import Foundation
import SwiftData

@Model
public final class NNCaregiverLink {
    @Attribute(.unique) public var id: String
    public var userId: String
    public var caregiverId: String
    public var relationship: String?
    public var status: String // "pending" | "active" | "revoked"
    public var inviteCode: String?
    public var permViewActivity: Bool
    public var permEditRoutines: Bool
    public var permViewLocation: Bool
    public var permViewMedications: Bool
    public var permViewEmergency: Bool
    public var createdAt: Date

    public var user: NNUser?

    public init(
        id: String = UUID().uuidString,
        userId: String,
        caregiverId: String,
        relationship: String? = nil,
        status: String = "pending",
        inviteCode: String? = nil,
        permViewActivity: Bool = true,
        permEditRoutines: Bool = false,
        permViewLocation: Bool = false,
        permViewMedications: Bool = true,
        permViewEmergency: Bool = true,
        createdAt: Date = .now
    ) {
        self.id = id
        self.userId = userId
        self.caregiverId = caregiverId
        self.relationship = relationship
        self.status = status
        self.inviteCode = inviteCode
        self.permViewActivity = permViewActivity
        self.permEditRoutines = permEditRoutines
        self.permViewLocation = permViewLocation
        self.permViewMedications = permViewMedications
        self.permViewEmergency = permViewEmergency
        self.createdAt = createdAt
    }
}
