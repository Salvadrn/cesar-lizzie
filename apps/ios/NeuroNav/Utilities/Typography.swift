import SwiftUI

// Brand Identity Manual — Section 04: Typography
// Primary typeface: Avenir Next (iOS equivalent of Aptos)
// Weights: Bold / Semibold / Medium

extension Font {
    private static let family = "Avenir Next"

    // MARK: - Display / Hero

    /// 42pt Bold — app title, hero text
    static let nnDisplay = Font.custom(family, size: 42).weight(.bold)

    // MARK: - Titles

    /// 34pt Bold — Title 1
    static let nnLargeTitle = Font.custom(family, size: 34).weight(.bold)
    /// 28pt Bold — Title 2
    static let nnTitle = Font.custom(family, size: 28).weight(.bold)
    /// 22pt Semibold — Title 3
    static let nnTitle2 = Font.custom(family, size: 22).weight(.semibold)
    /// 20pt Semibold — Title 3 alternate (adaptive)
    static let nnTitle3 = Font.custom(family, size: 20).weight(.semibold)

    // MARK: - Body

    /// 17pt Semibold — section headers, card titles
    static let nnHeadline = Font.custom(family, size: 17).weight(.semibold)
    /// 17pt Medium — body text
    static let nnBody = Font.custom(family, size: 17).weight(.medium)
    /// 16pt Medium — callout text
    static let nnCallout = Font.custom(family, size: 16).weight(.medium)
    /// 15pt Medium — secondary labels
    static let nnSubheadline = Font.custom(family, size: 15).weight(.medium)
    /// 13pt Medium — footnote text
    static let nnFootnote = Font.custom(family, size: 13).weight(.medium)

    // MARK: - Small

    /// 12pt Medium — captions
    static let nnCaption = Font.custom(family, size: 12).weight(.medium)
    /// 11pt Medium — tiny labels
    static let nnCaption2 = Font.custom(family, size: 11).weight(.medium)

    // MARK: - Adaptive (for complexity-based sizing)

    /// Custom size with bold weight
    static func nnBold(size: CGFloat) -> Font {
        Font.custom(family, size: size).weight(.bold)
    }

    /// Custom size with semibold weight
    static func nnSemibold(size: CGFloat) -> Font {
        Font.custom(family, size: size).weight(.semibold)
    }

    /// Custom size with medium weight
    static func nnMedium(size: CGFloat) -> Font {
        Font.custom(family, size: size).weight(.medium)
    }
}
