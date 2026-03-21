import Foundation
import SwiftUI

// AdaptAi Brand Identity Manual — Section 06: Sensory Modes
// Three distinct visual modes. Never mix colors across modes.

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

    // Default Mode — BG: #F5F7FB  Text: #121827  Accent: #4078DA
    public static let defaultMode = SensoryModeConfig(
        name: "default",
        primaryColor: Color(red: 0x40/255, green: 0x78/255, blue: 0xDA/255),
        backgroundColor: Color(red: 0xF5/255, green: 0xF7/255, blue: 0xFB/255),
        textColor: Color(red: 0x12/255, green: 0x18/255, blue: 0x27/255),
        accentColor: Color(red: 0x40/255, green: 0x78/255, blue: 0xDA/255),
        animationEnabled: true,
        hapticEnabled: true,
        soundEnabled: true,
        borderRadius: 16,
        spacing: 12
    )

    // Low Stimulation — BG: #E8ECF0  Text: #738D9E  Accent: #5A7080
    public static let lowStimulation = SensoryModeConfig(
        name: "lowStimulation",
        primaryColor: Color(red: 0x73/255, green: 0x8D/255, blue: 0x9E/255),
        backgroundColor: Color(red: 0xE8/255, green: 0xEC/255, blue: 0xF0/255),
        textColor: Color(red: 0x73/255, green: 0x8D/255, blue: 0x9E/255),
        accentColor: Color(red: 0x5A/255, green: 0x70/255, blue: 0x80/255),
        animationEnabled: false,
        hapticEnabled: false,
        soundEnabled: false,
        borderRadius: 8,
        spacing: 16
    )

    // High Contrast — BG: #1A1F2E  Text: #FFFFFF  Accent: #FFD700
    public static let highContrast = SensoryModeConfig(
        name: "highContrast",
        primaryColor: .white,
        backgroundColor: Color(red: 0x1A/255, green: 0x1F/255, blue: 0x2E/255),
        textColor: .white,
        accentColor: Color(red: 0xFF/255, green: 0xD7/255, blue: 0x00/255),
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
