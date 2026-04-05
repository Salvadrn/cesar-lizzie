import Foundation
import SwiftData

@Model
public final class NNUserProfile {
    @Attribute(.unique) public var id: String
    public var currentComplexity: Int
    public var complexityFloor: Int
    public var complexityCeiling: Int
    public var sensoryMode: String
    public var preferredInput: String
    public var hapticEnabled: Bool
    public var audioEnabled: Bool
    public var fontScale: Double
    public var lostModeName: String?
    public var lostModeAddress: String?
    public var lostModePhone: String?
    public var lostModePhotoURL: String?
    public var totalSessions: Int
    public var totalErrors: Int
    public var avgResponseTime: Double
    public var lastSessionAt: Date?

    public var user: NNUser?

    public init(
        id: String = UUID().uuidString,
        currentComplexity: Int = 3,
        complexityFloor: Int = 1,
        complexityCeiling: Int = 5,
        sensoryMode: String = "default",
        preferredInput: String = "touch",
        hapticEnabled: Bool = true,
        audioEnabled: Bool = true,
        fontScale: Double = 1.0,
        lostModeName: String? = nil,
        lostModeAddress: String? = nil,
        lostModePhone: String? = nil,
        lostModePhotoURL: String? = nil,
        totalSessions: Int = 0,
        totalErrors: Int = 0,
        avgResponseTime: Double = 0,
        lastSessionAt: Date? = nil
    ) {
        self.id = id
        self.currentComplexity = currentComplexity
        self.complexityFloor = complexityFloor
        self.complexityCeiling = complexityCeiling
        self.sensoryMode = sensoryMode
        self.preferredInput = preferredInput
        self.hapticEnabled = hapticEnabled
        self.audioEnabled = audioEnabled
        self.fontScale = fontScale
        self.lostModeName = lostModeName
        self.lostModeAddress = lostModeAddress
        self.lostModePhone = lostModePhone
        self.lostModePhotoURL = lostModePhotoURL
        self.totalSessions = totalSessions
        self.totalErrors = totalErrors
        self.avgResponseTime = avgResponseTime
        self.lastSessionAt = lastSessionAt
    }
}
