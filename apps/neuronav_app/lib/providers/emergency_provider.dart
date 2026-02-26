import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/emergency_contact.dart';
import '../data/sample_data.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_provider.dart';

class EmergencyState {
  final List<EmergencyContactRow> contacts;
  final bool isLoading;
  final bool isEmergencyActive;
  final String? errorMessage;

  const EmergencyState({
    this.contacts = const [],
    this.isLoading = false,
    this.isEmergencyActive = false,
    this.errorMessage,
  });

  EmergencyState copyWith({
    List<EmergencyContactRow>? contacts,
    bool? isLoading,
    bool? isEmergencyActive,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EmergencyState(
      contacts: contacts ?? this.contacts,
      isLoading: isLoading ?? this.isLoading,
      isEmergencyActive: isEmergencyActive ?? this.isEmergencyActive,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  EmergencyContactRow? get primaryContact =>
      contacts.where((c) => c.isPrimary).firstOrNull ?? contacts.firstOrNull;
}

class EmergencyNotifier extends StateNotifier<EmergencyState> {
  final Ref _ref;

  EmergencyNotifier(this._ref) : super(const EmergencyState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final authState = _ref.read(authStateProvider);

    if (authState.isGuestMode) {
      state = state.copyWith(
        contacts: SampleData.sampleEmergencyContacts,
        isLoading: false,
      );
      return;
    }

    try {
      final contacts = await ApiClient.fetchEmergencyContacts();
      state = state.copyWith(contacts: contacts, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> triggerEmergency() async {
    state = state.copyWith(isEmergencyActive: true);

    try {
      await ApiClient.createAlert(
        type: 'emergency',
        severity: 'critical',
        title: 'Alerta de Emergencia',
        message: 'El usuario ha activado la alerta de emergencia.',
      );
      await ApiClient.notifyFamilyMembers(
        alertType: 'emergency',
        title: 'Emergencia',
        message: 'Tu ser querido necesita ayuda.',
      );
    } catch (_) {}

    NotificationService.sendEmergencyAlert();

    await callPrimaryContact();
    state = state.copyWith(isEmergencyActive: false);
  }

  Future<void> callPrimaryContact() async {
    final contact = state.primaryContact;
    if (contact != null) {
      final uri = Uri.parse('tel:${contact.phone}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  Future<void> addContact({
    required String name,
    required String phone,
    required String relationship,
    bool isPrimary = false,
  }) async {
    try {
      await ApiClient.addEmergencyContact(
        name: name,
        phone: phone,
        relationship: relationship,
        isPrimary: isPrimary,
      );
      await load();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteContact(String id) async {
    try {
      await ApiClient.deleteEmergencyContact(id);
      await load();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setPrimary(String id) async {
    try {
      await ApiClient.setEmergencyContactPrimary(id);
      await load();
    } catch (e) {
      rethrow;
    }
  }
}

final emergencyProvider =
    StateNotifierProvider<EmergencyNotifier, EmergencyState>(
  (ref) => EmergencyNotifier(ref),
);
