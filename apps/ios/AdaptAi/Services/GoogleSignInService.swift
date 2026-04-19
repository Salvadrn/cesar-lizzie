import AuthenticationServices
import SwiftUI
import AdaptAiKit

/// Handles Google Sign In via Supabase OAuth + ASWebAuthenticationSession.
/// Opens an in-app Safari window for Google account selection, then the
/// callback URL (adaptai://auth-callback) triggers handleCallback on AuthService.
@MainActor
final class GoogleSignInService: NSObject {
    static let shared = GoogleSignInService()

    private var authSession: ASWebAuthenticationSession?

    /// Starts the Google OAuth flow. Returns when the user either completes auth,
    /// cancels, or an error occurs.
    func signIn(authService: AuthService) async throws {
        let oauthURL = try await authService.googleOAuthURL()
        let callbackURL = try await startSession(url: oauthURL)
        try await authService.handleGoogleCallback(url: callbackURL)
    }

    private func startSession(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "adaptai"
            ) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let callbackURL = callbackURL else {
                    continuation.resume(throwing: GoogleSignInError.noCallback)
                    return
                }
                continuation.resume(returning: callbackURL)
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false

            if !session.start() {
                continuation.resume(throwing: GoogleSignInError.failedToStart)
            }

            self.authSession = session
        }
    }
}

extension GoogleSignInService: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Find the key window for presenting the Safari sheet
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.keyWindow ?? ASPresentationAnchor()
    }
}

enum GoogleSignInError: LocalizedError {
    case noCallback
    case failedToStart
    case cancelled

    var errorDescription: String? {
        switch self {
        case .noCallback: return "No se recibió respuesta de Google"
        case .failedToStart: return "No se pudo iniciar el flujo de Google"
        case .cancelled: return "Cancelaste el inicio de sesión"
        }
    }
}
