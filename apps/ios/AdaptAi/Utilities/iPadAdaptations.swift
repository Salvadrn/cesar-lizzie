import SwiftUI
import AdaptAiKit

// iPad-specific layout adaptations using horizontalSizeClass

struct iPadSplitModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass

    func body(content: Content) -> some View {
        if sizeClass == .regular {
            content
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
        } else {
            content
        }
    }
}

struct iPadGridModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass
    let compactColumns: Int
    let regularColumns: Int

    func body(content: Content) -> some View {
        content
    }

    var columns: [GridItem] {
        let count = sizeClass == .regular ? regularColumns : compactColumns
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: count)
    }
}

extension View {
    func iPadConstrained() -> some View {
        modifier(iPadSplitModifier())
    }
}

// Helper to get adaptive column count
func adaptiveColumns(compact: Int = 2, regular: Int = 4) -> [GridItem] {
    // This will be overridden at the call site using Environment
    Array(repeating: GridItem(.flexible(), spacing: 16), count: compact)
}
