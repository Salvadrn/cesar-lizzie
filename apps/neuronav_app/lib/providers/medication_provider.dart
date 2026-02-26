import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/medication.dart';
import '../data/sample_data.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

class MedicationNotifier extends StateNotifier<AsyncValue<List<MedicationRow>>> {
  final Ref _ref;

  MedicationNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    final authState = _ref.read(authStateProvider);

    if (authState.isGuestMode) {
      state = AsyncValue.data(SampleData.sampleMedications);
      return;
    }

    try {
      final meds = await ApiClient.fetchMedications();
      state = AsyncValue.data(meds);
      NotificationService.rescheduleAllMedications(meds);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addMedication({
    required String name,
    required String dosage,
    required int hour,
    required int minute,
    List<int>? reminderOffsets,
  }) async {
    try {
      await ApiClient.addMedication(
        name: name,
        dosage: dosage,
        hour: hour,
        minute: minute,
        reminderOffsets: reminderOffsets,
      );
      await load();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAsTaken(String id) async {
    final authState = _ref.read(authStateProvider);
    if (authState.isGuestMode) {
      state = state.whenData((meds) =>
        meds.map((m) => m.id == id ? m.copyWith(takenToday: true) : m).toList(),
      );
      NotificationService.medicationWasTaken(id);
      return;
    }

    try {
      await ApiClient.markMedicationTaken(id);
      NotificationService.medicationWasTaken(id);
      await load();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMedication(String id) async {
    try {
      await ApiClient.deleteMedication(id);
      // Notifications will be rescheduled by load() -> rescheduleAllMedications
      await load();
    } catch (e) {
      rethrow;
    }
  }
}

final medicationsProvider =
    StateNotifierProvider<MedicationNotifier, AsyncValue<List<MedicationRow>>>(
  (ref) => MedicationNotifier(ref),
);

final pendingMedsCountProvider = Provider<int>((ref) {
  final medsAsync = ref.watch(medicationsProvider);
  return medsAsync.whenOrNull(
    data: (meds) => meds.where((m) => !m.takenToday).length,
  ) ?? 0;
});
