import SwiftUI

@main
struct NeuroNavWatchApp: App {
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
