import SwiftUI
import NeuroNavKit

struct AdaptiveButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    @Environment(AdaptiveEngine.self) private var engine

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    private var config: ComplexityLevelConfig {
        engine.levelConfig()
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: config.buttonSize * 0.5))
                }

                if config.showText {
                    Text(title)
                        .font(.system(size: config.buttonSize * 0.35, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: config.buttonSize)
            .background(.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: config.buttonSize * 0.25))
        }
    }
}
