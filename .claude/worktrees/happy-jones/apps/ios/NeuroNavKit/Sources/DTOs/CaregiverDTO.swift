import Foundation

// Flutter equivalent: caregiver_dto.dart with json_serializable

public struct LinkedUserResponse: Codable, Identifiable {
    public let id: String
    public let userId: String
    public let relationship: String?
    public let status: String
    public let user: LinkedUserInfo?

    public init(
        id: String,
        userId: String,
        relationship: String?,
        status: String,
        user: LinkedUserInfo?
    ) {
        self.id = id
        self.userId = userId
        self.relationship = relationship
        self.status = status
        self.user = user
    }
}

public struct LinkedUserInfo: Codable {
    public let displayName: String
    public let email: String

    public init(displayName: String, email: String) {
        self.displayName = displayName
        self.email = email
    }
}

public struct InviteResponse: Codable {
    public let inviteCode: String

    public init(inviteCode: String) {
        self.inviteCode = inviteCode
    }
}

public struct AcceptInviteRequest: Codable {
    public let inviteCode: String

    public init(inviteCode: String) {
        self.inviteCode = inviteCode
    }
}
