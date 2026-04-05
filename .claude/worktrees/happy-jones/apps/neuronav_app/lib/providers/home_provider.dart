import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/routine.dart';
import '../data/models/medication.dart';
import '../data/models/profile_data.dart';
import '../data/sample_data.dart';
import '../services/api_client.dart';
import 'auth_provider.dart';

class HomeData {
  final List<RoutineRow> routines;
  final List<MedicationRow> medications;
  final ProfileData? profile;
  final int completedToday;
  final int totalToday;

  const HomeData({
    this.routines = const [],
    this.medications = const [],
    this.profile,
    this.completedToday = 0,
    this.totalToday = 0,
  });

  double get dailyProgress =>
      totalToday > 0 ? completedToday / totalToday : 0.0;
}

final homeDataProvider = FutureProvider<HomeData>((ref) async {
  final authState = ref.watch(authStateProvider);

  if (authState.isGuestMode) {
    final meds = SampleData.sampleMedications;
    final takenCount = meds.where((m) => m.takenToday).length;
    return HomeData(
      routines: SampleData.sampleRoutines,
      medications: meds,
      profile: null,
      completedToday: takenCount,
      totalToday: meds.length,
    );
  }

  if (!authState.isAuthenticated) {
    return const HomeData();
  }

  try {
    final routines = await ApiClient.fetchRoutines();
    final meds = await ApiClient.fetchMedications();
    final profile = await ApiClient.fetchProfile();
    final takenCount = meds.where((m) => m.takenToday).length;

    return HomeData(
      routines: routines,
      medications: meds,
      profile: profile,
      completedToday: takenCount,
      totalToday: meds.length,
    );
  } catch (e) {
    return const HomeData();
  }
});
