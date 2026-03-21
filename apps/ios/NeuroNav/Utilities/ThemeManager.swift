import SwiftUI

// AdaptAi Brand Identity Manual — Section 10: Dark Mode
// System / Light / Dark theme switching
// Dark mode uses Night BG #1A1F2E as background

@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    enum AppTheme: String, CaseIterable {
        case system
        case light
        case dark

        var displayName: String {
            switch self {
            case .system: return "Automatico"
            case .light: return "Claro"
            case .dark: return "Oscuro"
            }
        }

        var icon: String {
            switch self {
            case .system: return "circle.lefthalf.filled"
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            }
        }

        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }

    var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "app_theme")
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "app_theme") ?? "system"
        self.currentTheme = AppTheme(rawValue: saved) ?? .system
    }
}
