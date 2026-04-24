import SwiftUI

// MARK: - Screen background

/// Warm gradient canvas — primary color tint fades to main background.
public struct AdaptBackground: View {
    public init() {}
    public var body: some View {
        ZStack {
            AdaptTheme.Color.background.ignoresSafeArea()
            LinearGradient(
                colors: [
                    AdaptTheme.Palette.primary.opacity(0.10),
                    AdaptTheme.Color.background.opacity(0),
                ],
                startPoint: .top, endPoint: .center
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Eyebrow (small caps label)

public struct AdaptEyebrow: View {
    let text: String
    var color: Color = AdaptTheme.Color.textSecondary

    public init(_ text: String, color: Color? = nil) {
        self.text = text
        if let color { self.color = color }
    }

    public var body: some View {
        Text(text.uppercased())
            .font(AdaptTheme.Font.eyebrow)
            .tracking(1.8)
            .foregroundStyle(color)
    }
}

// MARK: - Section header

public struct AdaptSectionHeader: View {
    let eyebrow: String?
    let title: String
    var subtitle: String?

    public init(eyebrow: String? = nil, title: String, subtitle: String? = nil) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let eyebrow { AdaptEyebrow(eyebrow) }
            Text(title)
                .font(AdaptTheme.Font.sectionHead)
                .foregroundStyle(AdaptTheme.Color.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(AdaptTheme.Font.bodyText)
                    .foregroundStyle(AdaptTheme.Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Card

public struct AdaptCard<Content: View>: View {
    var padding: CGFloat = AdaptTheme.Spacing.md
    var tinted: Bool = false
    @ViewBuilder var content: Content

    public init(padding: CGFloat = AdaptTheme.Spacing.md, tinted: Bool = false, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.tinted = tinted
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: AdaptTheme.Radius.md, style: .continuous)
                    .fill(tinted
                          ? AdaptTheme.Color.surfaceElevated
                          : AdaptTheme.Color.surface)
            )
    }
}

// MARK: - Metric tile

/// Tile with circular icon badge + large number + small unit + label underneath.
/// Designed to sit in a 2-column grid.
public struct AdaptMetricTile: View {
    let eyebrow: String
    let value: String
    let unit: String
    let icon: String
    var tint: Color = AdaptTheme.Color.primary
    var alert: Bool = false

    public init(eyebrow: String, value: String, unit: String, icon: String,
                tint: Color = AdaptTheme.Color.primary, alert: Bool = false) {
        self.eyebrow = eyebrow
        self.value = value
        self.unit = unit
        self.icon = icon
        self.tint = tint
        self.alert = alert
    }

    public var body: some View {
        AdaptCard(padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.18))
                        .frame(width: 42, height: 42)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(value)
                            .font(AdaptTheme.Font.metric)
                            .foregroundStyle(alert ? AdaptTheme.Palette.error : AdaptTheme.Color.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)
                        Text(unit)
                            .font(AdaptTheme.Font.unit)
                            .foregroundStyle(AdaptTheme.Color.textSecondary)
                            .lineLimit(1)
                    }
                    Text(eyebrow)
                        .font(AdaptTheme.Font.caption)
                        .foregroundStyle(AdaptTheme.Color.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Pill stat (for top-bar indicators like streak)

public struct AdaptPillStat: View {
    let icon: String
    let value: String
    var tint: Color = AdaptTheme.Color.accent

    public init(icon: String, value: String, tint: Color = AdaptTheme.Color.accent) {
        self.icon = icon
        self.value = value
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(AdaptTheme.Color.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(AdaptTheme.Color.surface)
                .overlay(Capsule().stroke(AdaptTheme.Color.divider, lineWidth: 1))
        )
    }
}

// MARK: - Chip

public struct AdaptChip: View {
    let text: String
    var tint: Color = AdaptTheme.Palette.primary

    public init(_ text: String, tint: Color = AdaptTheme.Palette.primary) {
        self.text = text
        self.tint = tint
    }

    public var body: some View {
        Text(text)
            .font(AdaptTheme.Font.caption)
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(tint.opacity(0.14)))
    }
}

// MARK: - Progress Ring

public struct AdaptProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 10
    var gradient: LinearGradient = AdaptTheme.Gradient.primary

    public init(progress: Double, lineWidth: CGFloat = 10, gradient: LinearGradient = AdaptTheme.Gradient.primary) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.gradient = gradient
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(AdaptTheme.Color.surfaceElevated, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: progress)
        }
    }
}

// MARK: - Primary button

public struct AdaptPrimaryButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AdaptTheme.Font.body(16, weight: .bold))
            .foregroundStyle(AdaptTheme.Color.onAccent)
            .padding(.horizontal, 28)
            .padding(.vertical, 17)
            .frame(maxWidth: .infinity)
            .background(Capsule().fill(AdaptTheme.Color.primary))
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

public struct AdaptSecondaryButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AdaptTheme.Font.body(15, weight: .semibold))
            .foregroundStyle(AdaptTheme.Color.textPrimary)
            .padding(.horizontal, 24)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(AdaptTheme.Color.surface)
                    .overlay(Capsule().stroke(AdaptTheme.Color.divider, lineWidth: 1))
            )
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

// MARK: - Quick action tile

/// Large tile for home quick actions. Icon + eyebrow + title + subtitle.
public struct AdaptQuickActionTile: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let icon: String
    var tint: Color = AdaptTheme.Palette.primary

    public init(eyebrow: String, title: String, subtitle: String, icon: String, tint: Color = AdaptTheme.Palette.primary) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.tint = tint
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                Circle().fill(tint.opacity(0.18)).frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                AdaptEyebrow(eyebrow)
                Text(title)
                    .font(AdaptTheme.Font.card)
                    .foregroundStyle(AdaptTheme.Color.textPrimary)
                Text(subtitle)
                    .font(AdaptTheme.Font.caption)
                    .foregroundStyle(AdaptTheme.Color.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AdaptTheme.Radius.md, style: .continuous)
                .fill(AdaptTheme.Color.surface)
        )
    }
}

// MARK: - Divider

public struct AdaptDivider: View {
    public init() {}
    public var body: some View {
        Rectangle()
            .fill(AdaptTheme.Color.divider)
            .frame(height: 1)
    }
}
