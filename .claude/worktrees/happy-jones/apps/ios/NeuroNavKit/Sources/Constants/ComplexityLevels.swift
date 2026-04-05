import Foundation
import SwiftUI

// Flutter equivalent: complexity_levels.dart (portable directly)

public struct ComplexityLevelConfig {
    public let level: Int
    public let name: String
    public let buttonSize: CGFloat
    public let itemsPerScreen: Int
    public let showText: Bool
    public let audioMode: AudioMode
    public let confirmationLevel: ConfirmationLevel
    public let animationEnabled: Bool
    public let colorCoding: Bool

    public enum AudioMode {
        case autoPlay
        case onTap
        case optional
        case hidden
    }

    public enum ConfirmationLevel {
        case none
        case simple
        case detailed
    }

    public init(
        level: Int,
        name: String,
        buttonSize: CGFloat,
        itemsPerScreen: Int,
        showText: Bool,
        audioMode: AudioMode,
        confirmationLevel: ConfirmationLevel,
        animationEnabled: Bool,
        colorCoding: Bool
    ) {
        self.level = level
        self.name = name
        self.buttonSize = buttonSize
        self.itemsPerScreen = itemsPerScreen
        self.showText = showText
        self.audioMode = audioMode
        self.confirmationLevel = confirmationLevel
        self.animationEnabled = animationEnabled
        self.colorCoding = colorCoding
    }
}

public enum ComplexityLevels {
    public static let all: [Int: ComplexityLevelConfig] = [
        1: ComplexityLevelConfig(
            level: 1,
            name: "Essential",
            buttonSize: 80,
            itemsPerScreen: 2,
            showText: false,
            audioMode: .autoPlay,
            confirmationLevel: .none,
            animationEnabled: false,
            colorCoding: true
        ),
        2: ComplexityLevelConfig(
            level: 2,
            name: "Simple",
            buttonSize: 64,
            itemsPerScreen: 4,
            showText: true,
            audioMode: .onTap,
            confirmationLevel: .simple,
            animationEnabled: false,
            colorCoding: true
        ),
        3: ComplexityLevelConfig(
            level: 3,
            name: "Standard",
            buttonSize: 48,
            itemsPerScreen: 6,
            showText: true,
            audioMode: .optional,
            confirmationLevel: .simple,
            animationEnabled: true,
            colorCoding: true
        ),
        4: ComplexityLevelConfig(
            level: 4,
            name: "Detailed",
            buttonSize: 44,
            itemsPerScreen: 8,
            showText: true,
            audioMode: .hidden,
            confirmationLevel: .detailed,
            animationEnabled: true,
            colorCoding: false
        ),
        5: ComplexityLevelConfig(
            level: 5,
            name: "Full",
            buttonSize: 36,
            itemsPerScreen: 12,
            showText: true,
            audioMode: .hidden,
            confirmationLevel: .detailed,
            animationEnabled: true,
            colorCoding: false
        )
    ]

    public static let defaultConfig = ComplexityLevelConfig(
        level: 3, name: "Standard", buttonSize: 48, itemsPerScreen: 6,
        showText: true, audioMode: .optional, confirmationLevel: .simple,
        animationEnabled: true, colorCoding: true
    )

    public static func config(for level: Int) -> ComplexityLevelConfig {
        all[max(1, min(5, level))] ?? defaultConfig
    }
}
