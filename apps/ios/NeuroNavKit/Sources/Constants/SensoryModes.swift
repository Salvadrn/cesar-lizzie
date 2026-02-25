import Foundation
import SwiftUI

// Flutter equivalent: sensory_modes.dart (portable directly)

public struct SensoryModeConfig {
    public let name: String
    public let primaryColor: Color
    public let backgroundColor: Color
    public let textColor: Color
    public let accentColor: Color
    public let animationEnabled: Bool
    public let hapticEnabled: Bool
    public let soundEnabled: Bool
    public let borderRadius: CGFloat
    public let spacing: CGFloat

    public init(
        name: String,
        primaryColor: Color,
        backgroundColor: Color,
        textColor: Color,
        accentColor: Color,
        animationEnabled: Bool,
        hapticEnabled: Bool,
        soundEnabled: Bool,
        borderRadius: CGFloat,
        spacing: CGFloat
    ) {
        self.name = name
        self.primaryColor = primaryColor
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.accentColor = accentColor
        self.animationEnabled = animationEnabled
        self.hapticEnabled = hapticEnabled
        self.soundEnabled = soundEnabled
        self.borderRadius = borderRadius
        self.spacing = spacing
    }
}

public enum SensoryModes {
    public static let defaultMode = SensoryModeConfig(
        name: "default",
        primaryColor: Color(red: 0.25, green: 0.47, blue: 0.85),
        backgroundColor: Color(red: 0.96, green: 0.97, blue: 0.98),
        textColor: Color(red: 0.07, green: 0.09, blue: 0.15),
        accentColor: Color(red: 0.25, green: 0.47, blue: 0.85),
        animationEnabled: true,
        hapticEnabled: true,
        soundEnabled: true,
        borderRadius: 16,
        spacing: 12
    )

    public static let lowStimulation = SensoryModeConfig(
        name: "lowStimulation",
        primaryColor: Color(red: 0.45, green: 0.55, blue: 0.62),
        backgroundColor: Color(red: 0.95, green: 0.95, blue: 0.94),
        textColor: Color(red: 0.20, green: 0.22, blue: 0.25),
        accentColor: Color(red: 0.45, green: 0.55, blue: 0.62),
        animationEnabled: false,
        hapticEnabled: false,
        soundEnabled: false,
        borderRadius: 8,
        spacing: 16
    )

    public static let highContrast = SensoryModeConfig(
        name: "highContrast",
        primaryColor: .white,
        backgroundColor: .black,
        textColor: .white,
        accentColor: Color(red: 1.0, green: 0.84, blue: 0.0),
        animationEnabled: false,
        hapticEnabled: true,
        soundEnabled: true,
        borderRadius: 4,
        spacing: 16
    )

    public static func config(for mode: String) -> SensoryModeConfig {
        switch mode {
        case "lowStimulation": return lowStimulation
        case "highContrast": return highContrast
        default: return defaultMode
        }
    }
}
