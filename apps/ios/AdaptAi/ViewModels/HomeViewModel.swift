import Foundation
import AdaptAiKit

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
            completedToday = 1
            pendingMedications = 2
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
                AdaptiveEngine.shared.updateFromServer(level: level)
            }

            await loadTodayProgress()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func loadTodayProgress() async {
        do {
            let todayExecutions = try await api.fetchTodayExecutions()
            completedToday = todayExecutions.count
        } catch {
            completedToday = 0
        }
    }
}
