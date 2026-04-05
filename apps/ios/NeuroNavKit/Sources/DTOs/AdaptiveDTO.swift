import Foundation


public struct AdaptiveMetrics: Codable {
    public let errorRate: Double
    public let avgResponseTime: Double
    public let taskCompletionRate: Double
    public let stallRate: Double
    public let tapAccuracy: Double

    public init(
        errorRate: Double,
        avgResponseTime: Double,
        taskCompletionRate: Double,
        stallRate: Double,
        tapAccuracy: Double
    ) {
        self.errorRate = errorRate
        self.avgResponseTime = avgResponseTime
        self.taskCompletionRate = taskCompletionRate
        self.stallRate = stallRate
        self.tapAccuracy = tapAccuracy
    }
}

public struct InteractionEvent: Codable {
    public let eventType: String
    public let screen: String
    public let tapAccuracy: Double?
    public let responseTime: Double?
    public let wasError: Bool
    public let timestamp: String

    public init(
        eventType: String,
        screen: String,
        tapAccuracy: Double?,
        responseTime: Double?,
        wasError: Bool,
        timestamp: String
    ) {
        self.eventType = eventType
        self.screen = screen
        self.tapAccuracy = tapAccuracy
        self.responseTime = responseTime
        self.wasError = wasError
        self.timestamp = timestamp
    }
}

public struct InteractionBatch: Codable {
    public let events: [InteractionEvent]

    public init(events: [InteractionEvent]) {
        self.events = events
    }
}

public struct AdaptivePrediction: Codable {
    public let currentLevel: Int
    public let recommendedLevel: Int
    public let metrics: AdaptiveMetrics

    public init(currentLevel: Int, recommendedLevel: Int, metrics: AdaptiveMetrics) {
        self.currentLevel = currentLevel
        self.recommendedLevel = recommendedLevel
        self.metrics = metrics
    }
}

public struct UserProfileResponse: Codable {
    public let id: String
    public let currentComplexity: Int
    public let complexityFloor: Int
    public let complexityCeiling: Int
    public let sensoryMode: String
    public let preferredInput: String
    public let hapticEnabled: Bool
    public let audioEnabled: Bool
    public let fontScale: Double
    public let lostModeName: String?
    public let lostModeAddress: String?
    public let lostModePhone: String?
    public let lostModePhotoURL: String?

    public init(
        id: String,
        currentComplexity: Int,
        complexityFloor: Int,
        complexityCeiling: Int,
        sensoryMode: String,
        preferredInput: String,
        hapticEnabled: Bool,
        audioEnabled: Bool,
        fontScale: Double,
        lostModeName: String?,
        lostModeAddress: String?,
        lostModePhone: String?,
        lostModePhotoURL: String?
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
    }
}
