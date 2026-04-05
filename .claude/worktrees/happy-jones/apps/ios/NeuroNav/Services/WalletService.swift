import Foundation
import PassKit
import UIKit
import NeuroNavKit

/// Service that generates and adds Apple Wallet passes for the Medical ID card.
/// Uses a Supabase Edge Function to sign the PKPass server-side.
@Observable
final class WalletService {
    static let shared = WalletService()

    var isAddingPass = false
    var error: String?
    var lastGeneratedPass: PKPass?

    /// Whether this device supports adding passes to Wallet
    var canAddPasses: Bool {
        PKPassLibrary.isPassLibraryAvailable() && PKAddPassesViewController.canAddPasses()
    }

    /// Check if the medical ID pass is already in Wallet
    func isPassInWallet(userId: String) -> Bool {
        guard PKPassLibrary.isPassLibraryAvailable() else { return false }
        let library = PKPassLibrary()
        let passes = library.passes()
        return passes.contains { pass in
            pass.passTypeIdentifier == "pass.com.adaptai.medical-id" &&
            pass.serialNumber == "medical-id-\(userId)"
        }
    }

    /// Request a signed PKPass from the Edge Function and present it
    @MainActor
    func addToWallet(
        patientName: String,
        bloodType: String,
        allergies: String,
        conditions: String,
        emergencyNotes: String,
        emergencyContactName: String,
        emergencyContactPhone: String,
        doctorName: String,
        doctorPhone: String,
        age: String,
        userId: String
    ) async -> PKPass? {
        isAddingPass = true
        error = nil

        defer { isAddingPass = false }

        do {
            // Build request body
            let body: [String: String] = [
                "patient_name": patientName,
                "blood_type": bloodType,
                "allergies": allergies,
                "conditions": conditions,
                "emergency_notes": emergencyNotes,
                "emergency_contact_name": emergencyContactName,
                "emergency_contact_phone": emergencyContactPhone,
                "doctor_name": doctorName,
                "doctor_phone": doctorPhone,
                "age": age,
                "user_id": userId
            ]

            let jsonData = try JSONSerialization.data(withJSONObject: body)

            // Call Edge Function
            let projectRef = "hrfipfmxbdaoipjcszif"
            let url = URL(string: "https://\(projectRef).supabase.co/functions/v1/generate-wallet-pass")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            // Get auth token
            if let token = try? await SupabaseManager.shared.client.auth.session.accessToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            request.httpBody = jsonData

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw WalletError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw WalletError.serverError(httpResponse.statusCode, errorBody)
            }

            // Verify content type is pkpass
            guard httpResponse.mimeType == "application/vnd.apple.pkpass" else {
                throw WalletError.invalidPassData
            }

            // Create PKPass from data
            let pass = try PKPass(data: data)
            lastGeneratedPass = pass
            return pass

        } catch {
            self.error = error.localizedDescription
            print("WalletService error: \(error)")
            return nil
        }
    }
}

enum WalletError: LocalizedError {
    case invalidResponse
    case serverError(Int, String)
    case invalidPassData
    case passAlreadyExists

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Respuesta inválida del servidor"
        case .serverError(let code, let body):
            return "Error del servidor (\(code)): \(body)"
        case .invalidPassData:
            return "Los datos del pase no son válidos"
        case .passAlreadyExists:
            return "El pase ya existe en tu Wallet"
        }
    }
}
