import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/home/screens/adaptive_home_screen.dart';
import '../../features/routines/screens/routine_list_screen.dart';
import '../../features/routines/screens/routine_player_screen.dart';
import '../../features/medications/screens/medication_screen.dart';
import '../../features/medications/screens/add_medication_screen.dart';
import '../../features/appointments/screens/appointment_screen.dart';
import '../../features/appointments/screens/add_appointment_screen.dart';
import '../../features/emergency/screens/emergency_screen.dart';
import '../../features/emergency/screens/emergency_contacts_screen.dart';
import '../../features/emergency/screens/lost_mode_screen.dart';
import '../../features/family/screens/family_screen.dart';
import '../../features/family/screens/invite_code_screen.dart';
import '../../features/family/screens/patient_detail_screen.dart';
import '../../features/family/screens/patient_medications_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/credits_screen.dart';
import '../../features/simple_mode/screens/simple_home_screen.dart';
import '../../features/simple_mode/screens/simple_settings_screen.dart';
import '../../providers/auth_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isAuth = authState.isAuthenticated;
      final isSimple = authState.isSimpleModeActive;
      final loc = state.matchedLocation;

      if (isLoading) return null;

      // Not authenticated -> login
      if (!isAuth && loc != '/login') return '/login';

      // Authenticated but on login -> redirect
      if (isAuth && loc == '/login') {
        if (authState.needsOnboarding) return '/onboarding';
        return isSimple ? '/simple' : '/';
      }

      // Simple mode redirect
      if (isAuth && isSimple && !loc.startsWith('/simple') && loc != '/onboarding') {
        return '/simple';
      }

      // Normal mode but on simple route
      if (isAuth && !isSimple && loc.startsWith('/simple')) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),

      // Simple mode routes
      GoRoute(path: '/simple', builder: (_, __) => const SimpleHomeScreen()),
      GoRoute(path: '/simple/settings', builder: (_, __) => const SimpleSettingsScreen()),

      // Main shell with bottom nav
      StatefulShellRoute.indexedStack(
        builder: (context, state, child) => MainShell(child: child),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (_, __) => const AdaptiveHomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/routines', builder: (_, __) => const RoutineListScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/medications', builder: (_, __) => const MedicationScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/family', builder: (_, __) => const FamilyScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/emergency', builder: (_, __) => const EmergencyScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
          ]),
        ],
      ),

      // Nested routes
      GoRoute(
        path: '/routine/:id',
        builder: (_, state) => RoutinePlayerScreen(
          routineId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(path: '/medications/add', builder: (_, __) => const AddMedicationScreen()),
      GoRoute(path: '/appointments', builder: (_, __) => const AppointmentScreen()),
      GoRoute(path: '/appointments/add', builder: (_, __) => const AddAppointmentScreen()),
      GoRoute(path: '/emergency/contacts', builder: (_, __) => const EmergencyContactsScreen()),
      GoRoute(path: '/emergency/lost-mode', builder: (_, __) => const LostModeScreen()),
      GoRoute(path: '/family/invite', builder: (_, __) => const InviteCodeScreen()),
      GoRoute(
        path: '/family/patient/:linkId',
        builder: (_, state) => PatientDetailScreen(
          linkId: state.pathParameters['linkId']!,
        ),
      ),
      GoRoute(
        path: '/family/patient/:id/medications',
        builder: (_, state) => PatientMedicationsScreen(
          patientId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(path: '/settings/credits', builder: (_, __) => const CreditsScreen()),
    ],
  );
});

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateIndex(context),
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_filled), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.checklist_rounded), label: 'Rutinas'),
          NavigationDestination(icon: Icon(Icons.medication_rounded), label: 'Medicamentos'),
          NavigationDestination(icon: Icon(Icons.people_rounded), label: 'Familia'),
          NavigationDestination(icon: Icon(Icons.sos_rounded), label: 'Emergencia'),
          NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Ajustes'),
        ],
      ),
    );
  }

  int _calculateIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/routines')) return 1;
    if (loc.startsWith('/medications')) return 2;
    if (loc.startsWith('/family')) return 3;
    if (loc.startsWith('/emergency')) return 4;
    if (loc.startsWith('/settings')) return 5;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/');
      case 1: context.go('/routines');
      case 2: context.go('/medications');
      case 3: context.go('/family');
      case 4: context.go('/emergency');
      case 5: context.go('/settings');
    }
  }
}
