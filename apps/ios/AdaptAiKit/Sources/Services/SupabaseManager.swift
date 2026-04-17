import Foundation
import Supabase


public final class SupabaseManager {
    public static let shared = SupabaseManager()

    public let client: SupabaseClient

    private init() {
        guard let url = URL(string: AppConstants.supabaseURL) else {
            preconditionFailure("SupabaseManager: URL inválida en AppConstants.supabaseURL — verifica la configuración")
        }
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: AppConstants.supabaseAnonKey
        )
    }
}
