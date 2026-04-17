import SwiftUI
import AdaptAiKit

struct StallBanner: View {
    let phase: StallPhase
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: iconForPhase)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(titleForPhase)
                        .font(.nnHeadline)
                    Text(messageForPhase)
                        .font(.nnCaption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            if phase == .needHelp {
                Text("Quieres que llamemos a tu cuidador?")
                    .font(.nnSubheadline)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(backgroundForPhase)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var iconForPhase: String {
        switch phase {
        case .none: return ""
        case .visual: return "clock.badge.exclamationmark"
        case .audio: return "speaker.wave.2.fill"
        case .haptic: return "iphone.radiowaves.left.and.right"
        case .needHelp: return "questionmark.circle.fill"
        }
    }

    private var titleForPhase: String {
        switch phase {
        case .none: return ""
        case .visual: return "Tómate tu tiempo"
        case .audio: return "Escucha la instrucción"
        case .haptic: return "Sigue intentando"
        case .needHelp: return "Necesitas ayuda?"
        }
    }

    private var messageForPhase: String {
        switch phase {
        case .none: return ""
        case .visual: return "Estás en este paso hace un rato."
        case .audio: return "Te repito la instrucción por audio."
        case .haptic: return "Sientes la vibración? Sigue con el paso."
        case .needHelp: return "Podemos contactar a tu cuidador."
        }
    }

    private var backgroundForPhase: Color {
        switch phase {
        case .none: return .clear
        case .visual: return .yellow.opacity(0.15)
        case .audio: return .blue.opacity(0.15)
        case .haptic: return .purple.opacity(0.15)
        case .needHelp: return .orange.opacity(0.15)
        }
    }
}
