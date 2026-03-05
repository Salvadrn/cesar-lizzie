import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/caregiver_link.dart';
import '../data/models/execution.dart';
import '../data/models/alert.dart';
import '../data/models/safety_zone.dart';
import '../data/models/profile_data.dart';
import '../data/sample_data.dart';
import '../services/api_client.dart';
import 'auth_provider.dart';

class FamilyState {
  final List<CaregiverLinkRow> links;
  final bool isLoading;
  final String? generatedCode;
  final String? errorMessage;
  // Patient detail data (for caregiver view)
  final ProfileData? patientProfile;
  final List<ExecutionRow> patientExecutions;
  final List<AlertRow> patientAlerts;
  final List<SafetyZoneRow> patientZones;

  const FamilyState({
    this.links = const [],
    this.isLoading = false,
    this.generatedCode,
    this.errorMessage,
    this.patientProfile,
    this.patientExecutions = const [],
    this.patientAlerts = const [],
    this.patientZones = const [],
  });

  FamilyState copyWith({
    List<CaregiverLinkRow>? links,
    bool? isLoading,
    String? generatedCode,
    bool clearCode = false,
    String? errorMessage,
    bool clearError = false,
    ProfileData? patientProfile,
    bool clearPatient = false,
    List<ExecutionRow>? patientExecutions,
    List<AlertRow>? patientAlerts,
    List<SafetyZoneRow>? patientZones,
  }) {
    return FamilyState(
      links: links ?? this.links,
      isLoading: isLoading ?? this.isLoading,
      generatedCode: clearCode ? null : (generatedCode ?? this.generatedCode),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      patientProfile: clearPatient ? null : (patientProfile ?? this.patientProfile),
      patientExecutions: patientExecutions ?? this.patientExecutions,
      patientAlerts: patientAlerts ?? this.patientAlerts,
      patientZones: patientZones ?? this.patientZones,
    );
  }
}

class FamilyNotifier extends StateNotifier<FamilyState> {
  final Ref _ref;

  FamilyNotifier(this._ref) : super(const FamilyState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final authState = _ref.read(authStateProvider);

    if (authState.isGuestMode) {
      final links = authState.isCaregiver
          ? SampleData.sampleCaregiverLinks
          : SampleData.sampleFamilyLinks;
      state = state.copyWith(links: links, isLoading: false);
      return;
    }

    try {
      final links = await ApiClient.fetchLinkedUsers();
      state = state.copyWith(links: links, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> generateInvite() async {
    try {
      final code = await ApiClient.generateInviteCode();
      state = state.copyWith(generatedCode: code);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> acceptInvite(String code) async {
    try {
      await ApiClient.acceptInvite(code);
      await load();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> revokeLink(String linkId) async {
    try {
      await ApiClient.revokeLink(linkId);
      await load();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> loadPatientDetail(String userId, CaregiverLinkRow link) async {
    state = state.copyWith(isLoading: true, clearPatient: true);
    try {
      final profile = await ApiClient.fetchPatientProfile(userId);
      final executions = link.permViewActivity
          ? await ApiClient.fetchPatientExecutions(userId)
          : <ExecutionRow>[];
      final alertsRaw = await ApiClient.fetchPatientAlerts(userId);
      final alerts = alertsRaw.map((e) => AlertRow.fromJson(e)).toList();
      final zones = link.permViewLocation
          ? await ApiClient.fetchPatientSafetyZones(userId)
          : <SafetyZoneRow>[];

      state = state.copyWith(
        isLoading: false,
        patientProfile: profile,
        patientExecutions: executions,
        patientAlerts: alerts,
        patientZones: zones,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final familyProvider =
    StateNotifierProvider<FamilyNotifier, FamilyState>(
  (ref) => FamilyNotifier(ref),
);
