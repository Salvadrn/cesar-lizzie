import Foundation
import SwiftData

@Model
public final class NNSafetyZone {
    @Attribute(.unique) public var id: String
    public var userId: String
    public var name: String
    public var latitude: Double
    public var longitude: Double
    public var radiusMeters: Double
    public var zoneType: String // "home" | "school" | "work" | "medical" | "custom"
    public var alertOnExit: Bool
    public var alertOnEnter: Bool
    public var isActive: Bool

    public init(
        id: String = UUID().uuidString,
        userId: String,
        name: String = "",
        latitude: Double = 0,
        longitude: Double = 0,
        radiusMeters: Double = 200,
        zoneType: String = "custom",
        alertOnExit: Bool = true,
        alertOnEnter: Bool = false,
        isActive: Bool = true
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
