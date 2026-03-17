import SwiftUI
import NeuroNavKit

// ViewModifier that adapts UI elements based on current complexity level

struct AdaptiveStyleModifier: ViewModifier {
    let level: Int

    private var config: ComplexityLevelConfig {
        ComplexityLevels.config(for: level)
    }

    func body(content: Content) -> some View {
        content
            .animation(config.animationEnabled ? .easeInOut(duration: 0.3) : nil, value: level)
    }
}

struct AdaptiveButtonModifier: ViewModifier {
    let level: Int

    private var config: ComplexityLevelConfig {
        ComplexityLevels.config(for: level)
    }

    func body(content: Content) -> some View {
        content
            .font(.nnSemibold(size: config.buttonSize * 0.4))
            .frame(minHeight: config.buttonSize)
    }
}

struct AdaptiveTextModifier: ViewModifier {
    let level: Int
    let sensoryMode: String

    private var modeConfig: SensoryModeConfig {
        SensoryModes.config(for: sensoryMode)
    }

    func body(content: Content) -> some View {
        content
            .foregroundStyle(modeConfig.textColor)
    }
}

// MARK: - View Extensions

extension View {
    func adaptiveStyle(level: Int) -> some View {
        modifier(AdaptiveStyleModifier(level: level))
    }

    func adaptiveButton(level: Int) -> some View {
        modifier(AdaptiveButtonModifier(level: level))
    }

    func adaptiveText(level: Int, sensoryMode: String = "default") -> some View {
        modifier(AdaptiveTextModifier(level: level, sensoryMode: sensoryMode))
    }
}
