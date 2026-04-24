import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Centralized haptic feedback for AdaptAi.
/// Generators are kept alive as static instances so they're warm on first use.
public enum AdaptHaptics {
    public enum Kind {
        case tap        // soft impact — most button presses
        case select     // selection changed (toggles, pickers)
        case success    // completion notification
        case warning
        case error
    }

    #if os(iOS)
    private static let soft = UIImpactFeedbackGenerator(style: .soft)
    private static let selection = UISelectionFeedbackGenerator()
    private static let notification = UINotificationFeedbackGenerator()
    #endif

    public static func fire(_ kind: Kind = .tap) {
        #if os(iOS)
        switch kind {
        case .tap:     soft.impactOccurred()
        case .select:  selection.selectionChanged()
        case .success: notification.notificationOccurred(.success)
        case .warning: notification.notificationOccurred(.warning)
        case .error:   notification.notificationOccurred(.error)
        }
        #endif
    }

    public static func tap()     { fire(.tap) }
    public static func select()  { fire(.select) }
    public static func success() { fire(.success) }
}

public extension View {
    /// Attach to any tappable view that doesn't go through AdaptPrimaryButtonStyle
    /// to get consistent haptic feedback on tap.
    func adaptHapticOnTap(_ kind: AdaptHaptics.Kind = .tap) -> some View {
        simultaneousGesture(
            TapGesture().onEnded { AdaptHaptics.fire(kind) }
        )
    }
}
