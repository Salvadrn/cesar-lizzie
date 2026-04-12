import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/push_notification_service.dart';
import '../core/constants/app_constants.dart';
import '../data/models/profile_data.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final bool isGuestMode;
  final UserRole currentRole;
  final ProfileData? currentProfile;
  final bool isSimpleModeActive;
  final String? errorMessage;

  const AuthState({
    this.isLoading = true,
    this.isAuthenticated = false,
    this.isGuestMode = false,
    this.currentRole = UserRole.guest,
    this.currentProfile,
    this.isSimpleModeActive = false,
    this.errorMessage,
  });

  bool get isPatient => currentRole == UserRole.patient;
  bool get isCaregiver =>
      currentRole == UserRole.caregiver || (currentProfile?.alsoCares ?? false);
  bool get isFamily => currentRole == UserRole.family;
  bool get isGuest => currentRole == UserRole.guest;

  bool get needsOnboarding {
    if (isGuestMode) return false;
    final profile = currentProfile;
    if (profile == null) return true;
    return profile.displayName.isEmpty;
  }

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    bool? isGuestMode,
    UserRole? currentRole,
    ProfileData? currentProfile,
    bool clearProfile = false,
    bool? isSimpleModeActive,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isGuestMode: isGuestMode ?? this.isGuestMode,
      currentRole: currentRole ?? this.currentRole,
      currentProfile: clearProfile ? null : (currentProfile ?? this.currentProfile),
      isSimpleModeActive: isSimpleModeActive ?? this.isSimpleModeActive,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    await _authService.restoreSession();
    _syncState();
  }

  void _syncState() {
    state = state.copyWith(
      isLoading: false,
      isAuthenticated: _authService.isAuthenticated,
      isGuestMode: _authService.isGuestMode,
      currentRole: _authService.currentRole,
      currentProfile: _authService.currentProfile,
      isSimpleModeActive: _authService.isSimpleModeActive,
      clearError: true,
    );

    // Subscribe to FCM topics when authenticated
    if (_authService.isAuthenticated && !_authService.isGuestMode) {
      final profile = _authService.currentProfile;
      if (profile != null) {
        PushNotificationService.subscribeUserTopics(
          profile.id,
          _authService.currentRole.name,
        );
      }
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.signInWithEmail(email: email, password: password);
      _syncState();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.signUpWithEmail(email: email, password: password);
      _syncState();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void signInAsGuest({UserRole role = UserRole.patient}) {
    _authService.signInAsGuest(role: role);
    _syncState();
  }

  Future<void> logout() async {
    // Unsubscribe from FCM topics
    final currentAuth = state;
    if (currentAuth.currentProfile != null && !currentAuth.isGuestMode) {
      try {
        await PushNotificationService.unsubscribeUserTopics(
          currentAuth.currentProfile!.id,
          currentAuth.currentRole.name,
        );
      } catch (_) {}
    }

    state = state.copyWith(isLoading: true);
    try {
      await _authService.logout();
    } catch (_) {}
    state = const AuthState(isLoading: false);
  }

  Future<void> refreshProfile() async {
    await _authService.restoreSession();
    _syncState();
  }

  void setGuestSimpleMode(bool enabled) {
    _authService.setGuestSimpleMode(enabled);
    _syncState();
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isAuthenticated;
});

final currentRoleProvider = Provider<UserRole>((ref) {
  return ref.watch(authStateProvider).currentRole;
});

final isGuestModeProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isGuestMode;
});

final isSimpleModeProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isSimpleModeActive;
});

final currentProfileProvider = Provider<ProfileData?>((ref) {
  return ref.watch(authStateProvider).currentProfile;
});
