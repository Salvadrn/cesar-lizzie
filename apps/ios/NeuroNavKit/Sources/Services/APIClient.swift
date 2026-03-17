import Foundation
import Supabase


public enum APIError: Error, LocalizedError {
    case notAuthenticated
    case notFound
    case serverError(String)
    case decodingError(Error)

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "No autenticado"
        case .notFound: return "No encontrado"
        case .serverError(let msg): return msg
        case .decodingError(let err): return "Error de datos: \(err.localizedDescription)"
        }
    }
}

@Observable
public final class APIClient {
    public static let shared = APIClient()

    let supabase = SupabaseManager.shared.client

    public static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private init() {}

    // MARK: - Helpers

    func currentUserId() async throws -> String {
        guard let userId = try? await supabase.auth.session.user.id else {
            throw APIError.notAuthenticated
        }
        return userId.uuidString
    }
}
