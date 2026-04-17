import SwiftUI

@main
struct AdaptAiWatchApp: App {
    @State private var connectivityManager = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environment(connectivityManager)
        }
    }
}

struct WatchContentView: View {
    @Environment(WatchConnectivityManager.self) private var connectivity

    var body: some View {
        NavigationStack {
            WatchHomeView()
        }
    }
}
