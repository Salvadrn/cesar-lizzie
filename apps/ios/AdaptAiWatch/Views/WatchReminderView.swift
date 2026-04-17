import SwiftUI

struct WatchReminderView: View {
    let routine: WatchRoutine

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.fill")
                .font(.title)
                .foregroundStyle(.blue)

            Text("Próxima Rutina")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(routine.title)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("\(routine.stepsCount) pasos")
                .font(.caption)
                .foregroundStyle(.secondary)

            NavigationLink("Iniciar") {
                WatchRoutinePlayerView(routine: routine)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
