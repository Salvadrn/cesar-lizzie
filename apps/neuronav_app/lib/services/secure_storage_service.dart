import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around `flutter_secure_storage` for persisting tokens and
/// other small secrets in the OS keychain / keystore.
///
/// Ported from the Swift `SecureStorageService`.
class SecureStorageService {
  SecureStorageService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // ---------------------------------------------------------------------------
  // Token CRUD
  // ---------------------------------------------------------------------------

  /// Persists a value under [key].
  static Future<void> saveToken(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Reads the value stored under [key], or `null` if absent.
  static Future<String?> getToken(String key) async {
    return _storage.read(key: key);
  }

  /// Removes a single token by [key].
  static Future<void> deleteToken(String key) async {
    await _storage.delete(key: key);
  }

  /// Wipes all stored tokens (e.g. on logout).
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // ---------------------------------------------------------------------------
  // Convenience
  // ---------------------------------------------------------------------------

  /// Returns `true` when at least one token exists in secure storage.
  static Future<bool> get hasTokens async {
    final all = await _storage.readAll();
    return all.isNotEmpty;
  }
}
