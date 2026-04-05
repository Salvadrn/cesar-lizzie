import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';

/// Thin wrapper around the Supabase singleton.
///
/// Call [initialize] once at app startup (before `runApp`) and then access
/// [client] anywhere in the app.
class SupabaseService {
  SupabaseService._();

  /// Initializes the Supabase SDK with the project URL and anon key defined
  /// in [AppConstants].  Safe to call multiple times -- subsequent calls are
  /// no-ops because the SDK guards against double-init internally.
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  /// Convenience accessor for the global [SupabaseClient].
  static SupabaseClient get client => Supabase.instance.client;
}
