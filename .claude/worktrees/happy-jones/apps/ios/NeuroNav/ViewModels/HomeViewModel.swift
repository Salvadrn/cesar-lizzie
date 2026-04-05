import Foundation
import NeuroNavKit

@Observable
final class HomeViewModel {
    var routines: [RoutineResponse] = []
    var profile: UserProfileResponse?
    var isLoading = true
    var errorMessage: String?

    // Dashboard data
    var completedToday: Int = 0
    var pendingMedications: Int = 0

    var dailyProgress: Double {
        guard !routines.isEmpty else { return 0 }
        return Double(completedToday) / Double(routines.count)
    }

    private let api = APIClient.shared

    func load() async {
        isLoading = true

        if AuthService.shared.isGuestMode {
            routines = SampleData.routines
            completedToday = 1 // Sample: 1 out of 3 done
            pendingMedications = 2 // Sample: 2 pending meds
            isLoading = false
            return
        }

        do {
            async let routinesTask = api.fetchRoutines()
            async let profileTask = api.fetchProfile()
            async let medsTask = api.fetchMedications()

            routines = try await routinesTask
            profile = try await profileTask

            let meds = try await medsTask
            pendingMedications = meds.filter { !$0.takenToday }.count

            if let level = profile?.currentComplexity {
                AdaptiveEngine.shared.currentLevel = level
            }

            // Count today's completed executions
            await loadTodayProgress()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func loadTodayProgress() async {
        // For now, completedToday stays at 0 until executions are tracked per-day
        // This can be enhanced later with a dedicated API endpoint
        completedToday = 0
    }
}
