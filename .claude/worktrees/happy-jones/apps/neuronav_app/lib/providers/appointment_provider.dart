import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/appointment.dart';
import '../data/sample_data.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

class AppointmentNotifier extends StateNotifier<AsyncValue<List<AppointmentRow>>> {
  final Ref _ref;

  AppointmentNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    final authState = _ref.read(authStateProvider);

    if (authState.isGuestMode) {
      state = AsyncValue.data(SampleData.sampleAppointments);
      return;
    }

    try {
      final appointments = await ApiClient.fetchAppointments();
      state = AsyncValue.data(appointments);
      _scheduleNotifications(appointments);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _scheduleNotifications(List<AppointmentRow> appointments) {
    for (final appt in appointments) {
      final date = appt.date;
      if (date != null && date.isAfter(DateTime.now())) {
        NotificationService.scheduleDoctorAppointment(
          id: appt.id,
          doctorName: appt.doctorName,
          date: date,
        );
      }
    }
  }

  Future<void> addAppointment({
    required String doctorName,
    String? specialty,
    String? location,
    String? notes,
    required DateTime date,
    bool isRecurring = false,
    int? recurringMonths,
  }) async {
    try {
      await ApiClient.addAppointment(
        doctorName: doctorName,
        specialty: specialty,
        location: location,
        notes: notes,
        date: date,
        isRecurring: isRecurring,
        recurringMonths: recurringMonths,
      );
      await load();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAppointment(String id) async {
    try {
      await ApiClient.deleteAppointment(id);
      NotificationService.cancelDoctorAppointment(id);
      await load();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> completeAppointment(String id) async {
    try {
      await ApiClient.completeAppointment(id);
      await load();
    } catch (e) {
      rethrow;
    }
  }
}

final appointmentsProvider =
    StateNotifierProvider<AppointmentNotifier, AsyncValue<List<AppointmentRow>>>(
  (ref) => AppointmentNotifier(ref),
);

final upcomingAppointmentsProvider = Provider<List<AppointmentRow>>((ref) {
  final apptsAsync = ref.watch(appointmentsProvider);
  return apptsAsync.whenOrNull(
    data: (appts) => appts.where((a) => !a.isPast && a.status != 'cancelled').toList(),
  ) ?? [];
});

final pastAppointmentsProvider = Provider<List<AppointmentRow>>((ref) {
  final apptsAsync = ref.watch(appointmentsProvider);
  return apptsAsync.whenOrNull(
    data: (appts) => appts.where((a) => a.isPast || a.status == 'completed').toList(),
  ) ?? [];
});
