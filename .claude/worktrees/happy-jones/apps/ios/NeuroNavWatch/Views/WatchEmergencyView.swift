import SwiftUI
import WatchKit

struct WatchEmergencyView: View {
    @Environment(WatchConnectivityManager.self) private var connectivity
    @State private var isTriggered = false

    var body: some View {
        VStack(spacing: 16) {
            if isTriggered {
                Image(systemName: "phone.connection.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
                    .symbolEffect(.pulse)

                Text("Ayuda en camino")
                    .font(.headline)

                Text("Se notificó a tus cuidadores")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "sos.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.red)

                Text("EMERGENCIA")
                    .font(.headline)
                    .foregroundStyle(.red)

                Button {
                    triggerEmergency()
                } label: {
                    Text("PEDIR AYUDA")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding()
    }

    private func triggerEmergency() {
        isTriggered = true
        WKInterfaceDevice.current().play(.failure) // Strong haptic
        connectivity.triggerEmergency()
    }
}
