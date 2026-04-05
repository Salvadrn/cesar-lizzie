import Foundation
import NeuroNavKit
import AuthenticationServices
import CryptoKit

class AppleSignInViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var currentNonce: String?

    func handleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    @MainActor
    func handleSignInCompletion(_ result: Result<ASAuthorization, Error>, authService: AuthService) async {
        isLoading = true
        errorMessage = nil

        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = appleIDCredential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8),
                  let nonce = currentNonce else {
                errorMessage = "No se pudo obtener la credencial de Apple"
                isLoading = false
                return
            }

            do {
                try await authService.signInWithApple(idToken: identityToken, nonce: nonce)
            } catch {
                errorMessage = "Error al iniciar sesión: \(error.localizedDescription)"
            }

        case .failure(let error):
            // User cancelled is not an error
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = "Error: \(error.localizedDescription)"
            }
        }

        isLoading = false
    }

    // MARK: - Nonce helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        guard errorCode == errSecSuccess else {
            // Fallback: use arc4random if SecRandomCopyBytes fails
            randomBytes = (0..<length).map { _ in UInt8.random(in: 0...255) }
            let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
            return String(randomBytes.map { charset[Int($0) % charset.count] })
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
