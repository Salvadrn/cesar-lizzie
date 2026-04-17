import Foundation
import AdaptAiKit

@Observable
final class SettingsViewModel {
    var profile: UserProfileResponse?
    var isLoading = false
    var errorMessage: String?
    var isSaving = false

    private let api = APIClient.shared

    func load() async {
        isLoading = true
        do {
            profile = try await api.fetchProfile()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func updateSensoryMode(_ mode: String) async {
        isSaving = true
        do {
            try await api.updateProfile(ProfileUpdate(sensoryMode: mode))
            profile = try await api.fetchProfile()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    func updateHaptic(_ enabled: Bool) async {
        do {
            try await api.updateProfile(ProfileUpdate(hapticEnabled: enabled))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateAudio(_ enabled: Bool) async {
        do {
            try await api.updateProfile(ProfileUpdate(audioEnabled: enabled))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateFontScale(_ scale: Double) async {
        do {
            try await api.updateProfile(ProfileUpdate(fontScale: scale))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateSimpleMode(_ enabled: Bool) async {
        let auth = AuthService.shared
        // Guest mode: solo local
        if auth.isGuestMode {
            auth.setGuestSimpleMode(enabled)
            return
        }
        isSaving = true
        do {
            var update = ProfileUpdate(simpleMode: enabled)
            if enabled {
                update.currentComplexity = 1
                update.sensoryMode = "lowStimulation"
            }
            try await api.updateProfile(update)
            await auth.restoreSession()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    func updateAlsoCares(_ enabled: Bool) async {
        let auth = AuthService.shared
        isSaving = true
        do {
            var update = ProfileUpdate(alsoCares: enabled)
            if enabled {
                update.simpleMode = false
            }
            try await api.updateProfile(update)
            await auth.restoreSession()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    func logout() async {
        do {
            try await AuthService.shared.logout()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
