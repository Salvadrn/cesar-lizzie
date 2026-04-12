import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';
import '../data/models/profile_data.dart';
import 'supabase_service.dart';

/// Manages authentication state: Supabase auth, guest mode, and the current
/// user profile.
///
/// Ported from the Swift `AuthService`.  Uses [ChangeNotifier] so that
/// widgets can rebuild when auth state changes (e.g. via `Provider` /
/// `ListenableBuilder`).
class AuthService extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  String? _userId;
  ProfileData? _currentProfile;
  bool _isGuestMode = false;
  UserRole _guestSelectedRole = UserRole.patient;
  bool _guestSimpleMode = false;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// The authenticated user's ID, or `null` when not signed in / guest.
  String? get userId => _userId;

  /// The full profile fetched from the `profiles` table after sign-in.
  ProfileData? get currentProfile => _currentProfile;

  /// Whether the user chose to continue as guest (no Supabase session).
  bool get isGuestMode => _isGuestMode;

  /// The role the guest selected from the onboarding picker.
  UserRole get guestSelectedRole => _guestSelectedRole;

  /// Whether the guest toggled "simple mode" on.
  bool get guestSimpleMode => _guestSimpleMode;

  /// `true` when a valid Supabase session exists AND we have a userId.
  bool get isAuthenticated => _userId != null && !_isGuestMode;

  /// Returns the effective role: profile role if authenticated, else the
  /// guest-selected role.
  UserRole get currentRole {
    if (_currentProfile != null) {
      return UserRole.fromString(_currentProfile!.role);
    }
    if (_isGuestMode) {
      return _guestSelectedRole;
    }
    return UserRole.guest;
  }

  bool get isGuest => _isGuestMode || _userId == null;

  bool get isPatient => currentRole == UserRole.patient;

  bool get isCaregiver => currentRole == UserRole.caregiver;

  bool get isFamily => currentRole == UserRole.family;

  /// A patient whose profile has the `alsoCares` flag can also manage other
  /// patients like a caregiver would.
  bool get isPatientWithCaregiverAbilities =>
      isPatient && (_currentProfile?.alsoCares ?? false);

  /// Simple-mode is active either when the profile says so or the guest
  /// toggled it on.
  bool get isSimpleModeActive {
    if (_isGuestMode) return _guestSimpleMode;
    return _currentProfile?.simpleMode ?? false;
  }

  // ---------------------------------------------------------------------------
  // Auth Methods
  // ---------------------------------------------------------------------------

  /// Sign in with email and password via Supabase Auth.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _userId = response.user?.id;
      _isGuestMode = false;
      _guestSimpleMode = false;

      if (_userId != null) {
        await loadProfile();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[AuthService] signInWithEmail error: $e');
      rethrow;
    }
  }

  /// Create a new account with email and password via Supabase Auth.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
      );

      _userId = response.user?.id;
      _isGuestMode = false;
      _guestSimpleMode = false;

      if (_userId != null) {
        await loadProfile();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[AuthService] signUpWithEmail error: $e');
      rethrow;
    }
  }

  /// Enter guest mode -- no network required.
  void signInAsGuest({UserRole role = UserRole.patient}) {
    _isGuestMode = true;
    _userId = null;
    _currentProfile = null;
    _guestSelectedRole = role;
    _guestSimpleMode = false;
    notifyListeners();
  }

  /// Leave guest mode and return to the unauthenticated state.
  void exitGuestMode() {
    _isGuestMode = false;
    _userId = null;
    _currentProfile = null;
    _guestSelectedRole = UserRole.patient;
    _guestSimpleMode = false;
    notifyListeners();
  }

  /// Attempts to restore a previous Supabase session from secure storage.
  /// Returns `true` when a valid session was found and the profile loaded.
  Future<bool> restoreSession() async {
    try {
      final session = SupabaseService.client.auth.currentSession;
      if (session != null) {
        _userId = session.user.id;
        _isGuestMode = false;
        await loadProfile();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[AuthService] restoreSession error: $e');
      return false;
    }
  }

  /// Sign out of Supabase and reset all local state.
  Future<void> logout() async {
    try {
      await SupabaseService.client.auth.signOut();
    } catch (e) {
      debugPrint('[AuthService] logout error: $e');
    }
    _userId = null;
    _currentProfile = null;
    _isGuestMode = false;
    _guestSelectedRole = UserRole.patient;
    _guestSimpleMode = false;
    notifyListeners();
  }

  /// Fetches (or refreshes) the profile row for the current user.
  Future<void> loadProfile() async {
    if (_userId == null) return;

    try {
      final data = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', _userId!)
          .maybeSingle();

      if (data != null) {
        _currentProfile = ProfileData.fromJson(data);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[AuthService] loadProfile error: $e');
      rethrow;
    }
  }

  /// Toggles the guest-mode "simple mode" flag.
  void setGuestSimpleMode(bool value) {
    _guestSimpleMode = value;
    notifyListeners();
  }
}
