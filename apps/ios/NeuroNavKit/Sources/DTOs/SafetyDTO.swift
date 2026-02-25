import Foundation

// Flutter equivalent: safety_dto.dart with json_serializable

public struct SafetyZoneResponse: Codable, Identifiable {
    public let id: String
    public let userId: String
    public let name: String
    public let latitude: Double
    public let longitude: Double
    public let radiusMeters: Double
    public let zoneType: String
    public let alertOnExit: Bool
    public let alertOnEnter: Bool
    public let isActive: Bool

    public init(
        id: String,
        userId: String,
        name: String,
        latitude: Double,
        longitude: Double,
        radiusMeters: Double,
        zoneType: String,
        alertOnExit: Bool,
        alertOnEnter: Bool,
        isActive: Bool
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.radiusMeters = radiusMeters
        self.zoneType = zoneType
        self.alertOnExit = alertOnExit
        self.alertOnEnter = alertOnEnter
        self.isActive = isActive
    }
}

public struct EmergencyContactResponse: Codable, Identifiable {
    public let id: String
    public let userId: String
    public let name: String
    public let phone: String
    public let relationship: String
    public let isPrimary: Bool

    public init(
        id: String,
        userId: String,
        name: String,
        phone: String,
        relationship: String,
        isPrimary: Bool
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.phone = phone
        self.relationship = relationship
        self.isPrimary = isPrimary
    }
}

public struct LocationReport: Codable {
    public let latitude: Double
    public let longitude: Double
    public let accuracy: Double
    public let timestamp: String

    public init(latitude: Double, longitude: Double, accuracy: Double, timestamp: String) {
        self.latitude = latitude
        self.longitude = longitude
        self.accuracy = accuracy
        self.timestamp = timestamp
    }
}

public struct EmergencyTriggerRequest: Codable {
    public let latitude: Double?
    public let longitude: Double?

    public init(latitude: Double?, longitude: Double?) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
