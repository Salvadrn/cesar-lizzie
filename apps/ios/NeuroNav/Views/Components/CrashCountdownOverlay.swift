import SwiftUI

struct CrashCountdownOverlay: View {
    var crashService: CrashDetectionService

    var body: some View {
        if crashService.showingCountdown {
            ZStack {
                Color.black.opacity(0.85)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.yellow)
                        .symbolEffect(.pulse)

                    Text("Impacto detectado")
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    Text("¿Estás bien?")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.8))

                    // Countdown circle
                    ZStack {
                        Circle()
                            .stroke(.red.opacity(0.3), lineWidth: 8)
                            .frame(width: 120, height: 120)

                        Circle()
                            .trim(from: 0, to: CGFloat(crashService.countdownSeconds) / 30.0)
                            .stroke(.red, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: crashService.countdownSeconds)

                        Text("\(crashService.countdownSeconds)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    Text("Se llamará a tu contacto\nde emergencia en \(crashService.countdownSeconds)s")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)

                    Button {
                        crashService.cancelCountdown()
                    } label: {
                        Text("ESTOY BIEN")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
                }
            }
            .transition(.opacity)
        }
    }
}
