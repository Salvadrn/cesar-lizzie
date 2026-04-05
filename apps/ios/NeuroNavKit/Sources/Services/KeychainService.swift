import Foundation
import Security


public final class KeychainService {
    public static let shared = KeychainService()

    private let service = AppConstants.keychainService
    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"

    // MARK: - Access Token

    public func saveAccessToken(_ token: String) {
        save(key: accessTokenKey, value: token)
    }

    public func getAccessToken() -> String? {
        load(key: accessTokenKey)
    }

    // MARK: - Refresh Token

    public func saveRefreshToken(_ token: String) {
        save(key: refreshTokenKey, value: token)
    }

    public func getRefreshToken() -> String? {
        load(key: refreshTokenKey)
    }

    // MARK: - Clear

    public func clearTokens() {
        delete(key: accessTokenKey)
        delete(key: refreshTokenKey)
    }

    public var hasTokens: Bool {
        getAccessToken() != nil
    }

    // MARK: - Private

    private func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        delete(key: key) // Remove existing first

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
