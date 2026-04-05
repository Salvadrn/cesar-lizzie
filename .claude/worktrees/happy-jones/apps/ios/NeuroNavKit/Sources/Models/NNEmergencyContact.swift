import Foundation
import SwiftData

@Model
public final class NNEmergencyContact {
    @Attribute(.unique) public var id: String
    public var userId: String
    public var name: String
    public var phone: String
    public var relationship: String
    public var isPrimary: Bool

    public init(
        id: String = UUID().uuidString,
        userId: String,
        name: String = "",
        phone: String = "",
        relationship: String = "",
        isPrimary: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.phone = phone
        self.relationship = relationship
        self.isPrimary = isPrimary
    }
}
