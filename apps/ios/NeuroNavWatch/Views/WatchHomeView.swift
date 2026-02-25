import SwiftUI

struct WatchHomeView: View {
    @Environment(WatchConnectivityManager.self) private var connectivity

    var body: some View {
        List {
            Section("Rutinas de Hoy") {
                if connectivity.todayRoutines.isEmpty {
                    Text("Sin rutinas")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(connectivity.todayRoutines) { routine in
                        NavigationLink {
                            WatchRoutinePlayerView(routine: routine)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(routine.title)
                                    .font(.headline)
                                    .lineLimit(2)

                                Text("\(routine.stepsCount) pasos")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section {
                NavigationLink {
                    WatchEmergencyView()
                } label: {
                    Label("Emergencia", systemImage: "sos.circle.fill")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("NeuroNav")
        .onAppear {
            connectivity.requestTodayRoutines()
        }
    }
}
