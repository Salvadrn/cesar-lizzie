import Foundation
import AdaptAiKit

@Observable
final class FamilyViewModel {
    var links: [CaregiverLinkRow] = []
    var isLoading = false
    var errorMessage: String?

    // Invite
    var generatedCode: String?
    var isGenerating = false
    var acceptCode = ""
    var isAccepting = false

    // Patient detail
    var patientProfile: ProfileData?
    var patientExecutions: [ExecutionRow] = []
    var patientAlerts: [AlertRow] = []
    var patientZones: [SafetyZoneRow] = []
    var isLoadingPatient = false

    private let api = APIClient.shared
    private let auth = AuthService.shared

    var currentRole: String {
        auth.currentProfile?.role ?? "user"
    }

    var isCaregiver: Bool {
        if auth.isGuestMode {
            return auth.guestSelectedRole == .caregiver
        }
        return currentRole == "caregiver"
    }

    // MARK: - Links

    func fetchLinks() async {
        isLoading = true
        errorMessage = nil

        if auth.isGuestMode {
            switch auth.guestSelectedRole {
            case .caregiver:
                links = SampleData.caregiverLinks
            case .family:
                links = SampleData.familyLinks
            default:
                links = []
            }
            isLoading = false
            return
        }

        do {
            links = try await api.fetchLinkedUsers()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Invite (User generates, Caregiver accepts)

    func generateInvite() async {
        isGenerating = true
        errorMessage = nil
        do {
            generatedCode = try await api.generateInviteCode()
        } catch {
            errorMessage = error.localizedDescription
        }
        isGenerating = false
    }

    func acceptInvite() async {
        guard !acceptCode.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isAccepting = true
        errorMessage = nil
        do {
            try await api.acceptInvite(code: acceptCode.trimmingCharacters(in: .whitespaces).uppercased())
            acceptCode = ""
            await fetchLinks()
        } catch {
            errorMessage = "Código inválido o ya usado"
        }
        isAccepting = false
    }

    func revokeLink(_ linkId: String) async {
        do {
            try await api.revokeLink(linkId: linkId)
            await fetchLinks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Patient Detail (Caregiver views patient data)

    func loadPatientDetail(link: CaregiverLinkRow) async {
        isLoadingPatient = true
        let patientId = link.userId

        do {
            patientProfile = try await api.fetchPatientProfile(userId: patientId)
        } catch {
            print("Could not load patient profile: \(error)")
        }

        if link.permViewActivity {
            do {
                patientExecutions = try await api.fetchPatientExecutions(userId: patientId)
            } catch {
                print("Could not load patient executions: \(error)")
            }
            do {
                patientAlerts = try await api.fetchPatientAlerts(userId: patientId)
            } catch {
                print("Could not load patient alerts: \(error)")
            }
        }

        if link.permViewLocation {
            do {
                patientZones = try await api.fetchPatientSafetyZones(userId: patientId)
            } catch {
                print("Could not load patient zones: \(error)")
            }
        }

        isLoadingPatient = false
    }

    func clearPatientDetail() {
        patientProfile = nil
        patientExecutions = []
        patientAlerts = []
        patientZones = []
    }
}
