import SwiftUI

// AdaptAi Brand Identity Manual — Section 04: Typography
// Primary typeface: Aptos (Avenir Next used as iOS substitute)
// Weights: Bold / Semibold / Medium
// Dynamic Scaling: 80% to 150% (respects iOS Dynamic Type)

extension Font {
    private static let family = "Avenir Next"

    // ── Display & Titles ───────────────────────────────────────────

    /// 42 pt Bold — app title, hero text
    static let nnDisplay = Font.custom(family, size: 42).weight(.bold)

    /// 34 pt Bold — Title 1
    static let nnLargeTitle = Font.custom(family, size: 34).weight(.bold)

    /// 28 pt Bold — Title 2
    static let nnTitle = Font.custom(family, size: 28).weight(.bold)

    /// 22 pt Semibold — Title 3
    static let nnTitle2 = Font.custom(family, size: 22).weight(.semibold)

    /// 22 pt Semibold — alias for Title 3
    static let nnTitle3 = Font.custom(family, size: 22).weight(.semibold)

    // ── Body ───────────────────────────────────────────────────────

    /// 17 pt Semibold — section headers, card titles
    static let nnHeadline = Font.custom(family, size: 17).weight(.semibold)

    /// 17 pt Medium — body text
    static let nnBody = Font.custom(family, size: 17).weight(.medium)

    /// 16 pt Medium — callout text
    static let nnCallout = Font.custom(family, size: 16).weight(.medium)

    /// 15 pt Medium — secondary labels
    static let nnSubheadline = Font.custom(family, size: 15).weight(.medium)

    /// 13 pt Medium — footnote text
    static let nnFootnote = Font.custom(family, size: 13).weight(.medium)

    // ── Small ──────────────────────────────────────────────────────

    /// 12 pt Medium — Caption 1
    static let nnCaption = Font.custom(family, size: 12).weight(.medium)

    /// 11 pt Medium — Caption 2
    static let nnCaption2 = Font.custom(family, size: 11).weight(.medium)

    // ── Adaptive helpers (complexity-based sizing) ──────────────────

    static func nnBold(size: CGFloat) -> Font {
        Font.custom(family, size: size).weight(.bold)
    }

    static func nnSemibold(size: CGFloat) -> Font {
        Font.custom(family, size: size).weight(.semibold)
    }

    static func nnMedium(size: CGFloat) -> Font {
        Font.custom(family, size: size).weight(.medium)
    }
}
