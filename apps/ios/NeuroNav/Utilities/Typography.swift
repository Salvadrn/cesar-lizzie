import SwiftUI

extension Font {
    private static let family = "Avenir Next"

    // MARK: - Display / Hero

    /// 42pt Bold — app title, hero text
    static let nnDisplay = Font.custom(family, size: 42).weight(.bold)

    // MARK: - Titles

    /// 34pt Bold
    static let nnLargeTitle = Font.custom(family, size: 34).weight(.bold)
    /// 28pt Bold
    static let nnTitle = Font.custom(family, size: 28).weight(.bold)
    /// 22pt Bold
    static let nnTitle2 = Font.custom(family, size: 22).weight(.bold)
    /// 20pt Bold
    static let nnTitle3 = Font.custom(family, size: 20).weight(.bold)

    // MARK: - Body

    /// 17pt Bold — section headers, card titles
    static let nnHeadline = Font.custom(family, size: 17).weight(.bold)
    /// 15pt DemiBold — secondary labels
    static let nnSubheadline = Font.custom(family, size: 15).weight(.semibold)
    /// 17pt Medium — body text
    static let nnBody = Font.custom(family, size: 17).weight(.medium)
    /// 16pt Medium — callout text
    static let nnCallout = Font.custom(family, size: 16).weight(.medium)

    // MARK: - Small

    /// 12pt DemiBold — captions
    static let nnCaption = Font.custom(family, size: 12).weight(.semibold)
    /// 11pt Medium — tiny labels
    static let nnCaption2 = Font.custom(family, size: 11).weight(.medium)

    // MARK: - Adaptive (for complexity-based sizing)

    /// Custom size with bold weight
    static func nnBold(size: CGFloat) -> Font {
        Font.custom(family, size: size).weight(.bold)
    }

    /// Custom size with demibold weight
    static func nnSemibold(size: CGFloat) -> Font {
        Font.custom(family, size: size).weight(.semibold)
    }

    /// Custom size with medium weight
    static func nnMedium(size: CGFloat) -> Font {
        Font.custom(family, size: size).weight(.medium)
    }
}
