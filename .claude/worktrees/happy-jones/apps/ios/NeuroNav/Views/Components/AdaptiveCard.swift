import SwiftUI
import NeuroNavKit

struct AdaptiveCard<Content: View>: View {
    @Environment(AdaptiveEngine.self) private var engine
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    private var config: ComplexityLevelConfig {
        engine.levelConfig()
    }

    var body: some View {
        content()
            .padding(config.level <= 2 ? 20 : 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: config.level <= 2 ? 20 : 14))
            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }
}
