import SwiftUI
import AdaptAiKit

struct SimpleModeTabView: View {
    @Environment(AuthService.self) private var authService
    @State private var crashService = CrashDetectionService.shared

    var body: some View {
        ZStack {
            NavigationStack {
                SimpleHomeView()
            }

            CrashCountdownOverlay(crashService: crashService)
                .animation(.easeInOut, value: crashService.showingCountdown)
        }
        .task {
            crashService.startMonitoring {
                NotificationService.shared.sendFallDetectionAlert()
            }
            await NotificationService.shared.requestAuthorization()
            LocationService.shared.requestAuthorization()
            await LocationService.shared.loadAndMonitorZones()
        }
    }
}
