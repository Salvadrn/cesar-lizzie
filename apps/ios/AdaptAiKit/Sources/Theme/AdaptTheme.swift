import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// AdaptAi brand design system.
/// Inspired by Soulspring's shape-first approach — consistent radii, spacing,
/// rounded numbers, eyebrows in small caps, surfaces that swap between
/// light/dark while keeping accent colors intentional.
public enum AdaptTheme {

    // MARK: - Fixed Palette (from brand identity manual)

    public enum Palette {
        // Primary brand
        public static let primary = SwiftUI.Color(adaptHex: 0x4078DA)       // Primary Blue #4078DA
        public static let primarySoft = SwiftUI.Color(adaptHex: 0x6690E0)
        public static let gold = SwiftUI.Color(adaptHex: 0xFFD700)          // Brand Gold
        public static let sensoryGray = SwiftUI.Color(adaptHex: 0x738D9E)   // Low-stimulation

        // Backgrounds (light + dark)
        public static let cream = SwiftUI.Color(adaptHex: 0xF5F7FB)         // Light BG
        public static let ink = SwiftUI.Color(adaptHex: 0x1A1F2E)           // Night BG
        public static let inkSoft = SwiftUI.Color(adaptHex: 0x232838)
        public static let inkRaised = SwiftUI.Color(adaptHex: 0x2D3244)

        // Text
        public static let darkText = SwiftUI.Color(adaptHex: 0x121827)      // Primary text light mode
        public static let midGray = SwiftUI.Color(adaptHex: 0xA0AEC0)       // Secondary text
        public static let whisper = SwiftUI.Color(adaptHex: 0x6B7280)

        // Semantic
        public static let success = SwiftUI.Color(adaptHex: 0x38A169)
        public static let error = SwiftUI.Color(adaptHex: 0xE53E3E)
        public static let warning = SwiftUI.Color(adaptHex: 0xED8936)
        public static let tint = SwiftUI.Color(adaptHex: 0xEBF0FF)
        public static let rule = SwiftUI.Color(adaptHex: 0xE2E8F0)

        // Accent role tints
        public static let caregiver = SwiftUI.Color(adaptHex: 0xE87D9B)     // soft pink for family/caregiver
        public static let family = SwiftUI.Color(adaptHex: 0x9F7AEA)        // lilac
        public static let heart = SwiftUI.Color(adaptHex: 0xE53E3E)
        public static let breath = SwiftUI.Color(adaptHex: 0x63B3ED)
    }

    // MARK: - Adaptive colors (auto light/dark)

    public enum Color {
        public static let background = adaptive(light: 0xF5F7FB, dark: 0x1A1F2E)
        public static let backgroundWarm = adaptive(light: 0xEBF0FF, dark: 0x232838)
        public static let surface = adaptive(light: 0xFFFFFF, dark: 0x232838)
        public static let surfaceElevated = adaptive(light: 0xF5F7FB, dark: 0x2D3244)
        public static let divider = adaptive(light: 0xE2E8F0, dark: 0x3D4356)
        public static let textPrimary = adaptive(light: 0x121827, dark: 0xF5F7FB)
        public static let textSecondary = adaptive(light: 0x6B7280, dark: 0xA0AEC0)
        public static let textTertiary = adaptive(light: 0xA0AEC0, dark: 0x6B7280)

        public static let primary = adaptive(light: 0x4078DA, dark: 0x6690E0)
        public static let accent = adaptive(light: 0xC8A028, dark: 0xFFD700)
        public static let onAccent = adaptive(light: 0xFFFFFF, dark: 0x121827)

        private static func adaptive(light: UInt32, dark: UInt32) -> SwiftUI.Color {
            #if os(iOS)
            return SwiftUI.Color(uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(SwiftUI.Color(adaptHex: dark))
                    : UIColor(SwiftUI.Color(adaptHex: light))
            })
            #else
            // watchOS / other platforms: no adaptive light/dark, use dark tone
            return SwiftUI.Color(adaptHex: dark)
            #endif
        }
    }

    // MARK: - Gradients

    public enum Gradient {
        public static let primary = LinearGradient(
            colors: [Palette.primary, Palette.primarySoft],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )

        public static let gold = LinearGradient(
            colors: [Palette.gold, SwiftUI.Color(adaptHex: 0xFFB800)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )

        public static let flame = LinearGradient(
            colors: [Palette.gold, SwiftUI.Color(adaptHex: 0xFF8A3D)],
            startPoint: .top, endPoint: .bottom
        )

        public static let heart = LinearGradient(
            colors: [Palette.heart, SwiftUI.Color(adaptHex: 0xFF7B7B)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )

        public static let calm = LinearGradient(
            colors: [SwiftUI.Color(adaptHex: 0x9FB4B8), SwiftUI.Color(adaptHex: 0xB8A3D4)],
            startPoint: .top, endPoint: .bottom
        )
    }

    // MARK: - Typography

    public enum Font {
        public static func display(_ size: CGFloat, weight: SwiftUI.Font.Weight = .bold) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .default)
        }
        public static func number(_ size: CGFloat, weight: SwiftUI.Font.Weight = .bold) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .rounded)
        }
        public static func body(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .default)
        }

        // Bigger by default than Soulspring since our users may have cognitive/visual impairments
        public static let hero = display(40, weight: .bold)
        public static let title = display(28, weight: .bold)
        public static let sectionHead = display(22, weight: .bold)
        public static let card = body(17, weight: .semibold)
        public static let metric = number(34, weight: .bold)
        public static let metricLarge = number(52, weight: .bold)
        public static let unit = body(13, weight: .medium)
        public static let bodyText = body(16, weight: .regular)
        public static let caption = body(13, weight: .medium)
        public static let eyebrow = body(11, weight: .bold)
    }

    // MARK: - Radius

    public enum Radius {
        public static let xs: CGFloat = 10
        public static let sm: CGFloat = 14
        public static let md: CGFloat = 20
        public static let lg: CGFloat = 28
        public static let xl: CGFloat = 40
        public static let pill: CGFloat = 999
    }

    // MARK: - Spacing

    public enum Spacing {
        public static let xs: CGFloat = 6
        public static let sm: CGFloat = 12
        public static let md: CGFloat = 18
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 36
    }
}

// MARK: - Hex helper

public extension Color {
    init(adaptHex hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >>  8) & 0xFF) / 255
        let b = Double( hex        & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
