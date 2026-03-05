import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/home_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/medication_provider.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/routine.dart';
import '../../../data/models/medication.dart';

class AdaptiveHomeScreen extends ConsumerWidget {
  const AdaptiveHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeDataProvider);
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Scaffold(
      body: homeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(homeDataProvider),
        ),
        data: (data) {
          final name = authState.currentProfile?.displayName ??
              (authState.isGuestMode ? 'Invitado' : '');

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(homeDataProvider),
            child: CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        now.greetingPrefix,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        name,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Guest mode banner
                      if (authState.isGuestMode) ...[
                        const _GuestBanner(),
                        const SizedBox(height: 16),
                      ],
                      // Daily Progress Card
                      _DailyProgressCard(data: data),
                      const SizedBox(height: 16),
                      // Next Routine Card
                      if (data.routines.isNotEmpty) ...[
                        _NextRoutineCard(routine: data.routines.first),
                        const SizedBox(height: 16),
                      ],
                      // Pending Medications
                      _PendingMedsSection(
                        medications: data.medications,
                        onMarkTaken: (id) {
                          ref.read(medicationsProvider.notifier).markAsTaken(id);
                          ref.invalidate(homeDataProvider);
                        },
                      ),
                      const SizedBox(height: 16),
                      // Quick Actions
                      const _QuickActionsGrid(),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error View
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'No se pudieron cargar los datos',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Guest Banner
// ---------------------------------------------------------------------------

class _GuestBanner extends StatelessWidget {
  const _GuestBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.orange.shade700, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Modo Invitado - Los datos no se guardan',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Daily Progress Card
// ---------------------------------------------------------------------------

class _DailyProgressCard extends StatelessWidget {
  final HomeData data;

  const _DailyProgressCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = data.dailyProgress;
    final percentage = (progress * 100).toInt();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Circular progress
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0
                          ? Colors.green
                          : theme.colorScheme.primary,
                    ),
                  ),
                  Center(
                    child: Text(
                      '$percentage%',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: progress >= 1.0
                            ? Colors.green
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Text info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progreso del Dia',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${data.completedToday} de ${data.totalToday} completados',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  if (progress >= 1.0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Todo completado',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Next Routine Card
// ---------------------------------------------------------------------------

class _NextRoutineCard extends StatelessWidget {
  final RoutineRow routine;

  const _NextRoutineCard({required this.routine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = RoutineCategory.fromString(routine.category);
    final stepCount = routine.routineSteps?.length ?? 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/routine/${routine.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.play_circle_fill_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Proxima Rutina',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Routine info
              Row(
                children: [
                  // Category icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _categoryIcon(category),
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routine.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${category.displayName} - $stepCount pasos',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pending Medications Section
// ---------------------------------------------------------------------------

class _PendingMedsSection extends StatelessWidget {
  final List<MedicationRow> medications;
  final void Function(String id) onMarkTaken;

  const _PendingMedsSection({
    required this.medications,
    required this.onMarkTaken,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendingMeds = medications.where((m) => !m.takenToday).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(
              Icons.medication_rounded,
              color: theme.colorScheme.primary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Medicamentos Pendientes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: pendingMeds.isEmpty
                    ? Colors.green.shade50
                    : theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${pendingMeds.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: pendingMeds.isEmpty
                      ? Colors.green.shade700
                      : theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Medication list
        if (pendingMeds.isEmpty)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.green.shade600,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Todos los medicamentos tomados',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...pendingMeds.map(
            (med) => _MedicationTile(
              medication: med,
              onTaken: () => onMarkTaken(med.id),
            ),
          ),
      ],
    );
  }
}

class _MedicationTile extends StatelessWidget {
  final MedicationRow medication;
  final VoidCallback onTaken;

  const _MedicationTile({
    required this.medication,
    required this.onTaken,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr =
        '${medication.hour.toString().padLeft(2, '0')}:${medication.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Pill icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.medication_rounded,
                color: theme.colorScheme.secondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medication.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${medication.dosage} - $timeStr',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            // Take button
            FilledButton.tonal(
              onPressed: onTaken,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Tomar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick Actions Grid
// ---------------------------------------------------------------------------

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones Rapidas',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _QuickActionButton(
              icon: Icons.checklist_rounded,
              label: 'Rutinas',
              color: Colors.blue,
              onTap: () => context.go('/routines'),
            ),
            _QuickActionButton(
              icon: Icons.medication_rounded,
              label: 'Medicamentos',
              color: Colors.teal,
              onTap: () => context.go('/medications'),
            ),
            _QuickActionButton(
              icon: Icons.calendar_month_rounded,
              label: 'Citas',
              color: Colors.purple,
              onTap: () => context.push('/appointments'),
            ),
            _QuickActionButton(
              icon: Icons.sos_rounded,
              label: 'Emergencia',
              color: Colors.red,
              onTap: () => context.go('/emergency'),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper: category to IconData mapping
// ---------------------------------------------------------------------------

IconData _categoryIcon(RoutineCategory category) {
  switch (category) {
    case RoutineCategory.cooking:
      return Icons.restaurant_rounded;
    case RoutineCategory.hygiene:
      return Icons.shower_rounded;
    case RoutineCategory.laundry:
      return Icons.local_laundry_service_rounded;
    case RoutineCategory.medication:
      return Icons.medication_rounded;
    case RoutineCategory.transit:
      return Icons.directions_bus_rounded;
    case RoutineCategory.shopping:
      return Icons.shopping_cart_rounded;
    case RoutineCategory.cleaning:
      return Icons.cleaning_services_rounded;
    case RoutineCategory.social:
      return Icons.people_rounded;
    case RoutineCategory.custom:
      return Icons.tune_rounded;
  }
}
