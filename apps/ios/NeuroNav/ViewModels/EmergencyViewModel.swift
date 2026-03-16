import Foundation
import NeuroNavKit
import UIKit

@Observable
final class EmergencyViewModel {
    var contacts: [EmergencyContactResponse] = []
    var isLoading = false
    var errorMessage: String?
    var isEmergencyActive = false

    private let api = APIClient.shared

    func load() async {
        isLoading = true

        if AuthService.shared.isGuestMode {
            contacts = SampleData.emergencyContacts
            isLoading = false
            return
        }

        do {
            contacts = try await api.fetchEmergencyContacts()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func triggerEmergency() async {
        isEmergencyActive = true
        do {
            // 1. Create alert for the user
            try await api.createAlert(
                type: .emergency,
                severity: .critical,
                title: "Emergencia activada",
                message: "El usuario ha activado la alerta de emergencia"
            )

            // 2. Notify all linked family members/caregivers
            try await api.notifyFamilyMembers(
                alertType: .emergency,
                title: "Emergencia activada",
                message: "Un usuario vinculado ha activado la alerta de emergencia"
            )

            // 3. Call primary contact
            await callPrimaryContact()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func callPrimaryContact() async {
        guard let primary = contacts.first(where: { $0.isPrimary }) ?? contacts.first,
              let url = URL(string: "tel://\(primary.phone)") else { return }
        await UIApplication.shared.open(url)
    }
}
