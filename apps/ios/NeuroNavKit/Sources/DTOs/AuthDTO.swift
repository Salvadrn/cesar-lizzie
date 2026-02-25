import Foundation

// Flutter equivalent: auth_dto.dart with json_serializable / freezed

public struct LoginRequest: Codable {
    public let email: String
    public let password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

public struct RegisterRequest: Codable {
    public let email: String
    public let password: String
    public let displayName: String
    public let role: String

    public init(email: String, password: String, displayName: String, role: String) {
        self.email = email
        self.password = password
        self.displayName = displayName
        self.role = role
    }
}

public struct TokenResponse: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let user: UserResponse

    public init(accessToken: String, refreshToken: String, user: UserResponse) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.user = user
    }
}

public struct RefreshRequest: Codable {
    public let refreshToken: String

    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}

public struct UserResponse: Codable {
    public let id: String
    public let email: String
    public let displayName: String
    public let role: String
    public let createdAt: String

    public init(id: String, email: String, displayName: String, role: String, createdAt: String) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.role = role
        self.createdAt = createdAt
    }
}
