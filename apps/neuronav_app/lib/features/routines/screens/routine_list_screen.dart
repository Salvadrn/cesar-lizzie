import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/routine_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/routine.dart';

class RoutineListScreen extends ConsumerWidget {
  const RoutineListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routinesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: routinesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(routinesProvider),
        ),
        data: (routines) {
          if (routines.isEmpty) {
            return const _EmptyState();
          }

          // Group routines by category
          final grouped = <RoutineCategory, List<RoutineRow>>{};
          for (final routine in routines) {
            final cat = RoutineCategory.fromString(routine.category);
            grouped.putIfAbsent(cat, () => []).add(routine);
          }

          final categories = grouped.keys.toList();

          // If there is only one category, show a flat list
          final showCategories = categories.length > 1;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(routinesProvider),
            child: CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mis Rutinas',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${routines.length} rutina${routines.length == 1 ? '' : 's'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (showCategories)
                  ..._buildGroupedList(context, grouped, categories)
                else
                  _buildFlatList(context, routines),
              ],
            ),
          );
        },
      ),
    );
  }

  // Build a flat SliverList when there is a single category
  Widget _buildFlatList(BuildContext context, List<RoutineRow> routines) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RoutineCard(routine: routines[index]),
          ),
          childCount: routines.length,
        ),
      ),
    );
  }

  // Build grouped sections when there are multiple categories
  List<Widget> _buildGroupedList(
    BuildContext context,
    Map<RoutineCategory, List<RoutineRow>> grouped,
    List<RoutineCategory> categories,
  ) {
    final theme = Theme.of(context);
    final widgets = <Widget>[];

    for (final category in categories) {
      final routinesInCategory = grouped[category]!;

      // Category header
      widgets.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Icon(
                  _categoryIcon(category),
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  category.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${routinesInCategory.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Routine cards in this category
      widgets.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RoutineCard(routine: routinesInCategory[index]),
              ),
              childCount: routinesInCategory.length,
            ),
          ),
        ),
      );
    }

    // Bottom padding
    widgets.add(const SliverPadding(padding: EdgeInsets.only(bottom: 32)));

    return widgets;
  }
}

// ---------------------------------------------------------------------------
// Routine Card
// ---------------------------------------------------------------------------

class _RoutineCard extends StatelessWidget {
  final RoutineRow routine;

  const _RoutineCard({required this.routine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = RoutineCategory.fromString(routine.category);
    final stepCount = routine.routineSteps?.length ?? 0;
    final estimatedMinutes = _estimateDuration(routine);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/routine/${routine.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _categoryIcon(category),
                  color: theme.colorScheme.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              // Info
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
                    if (routine.description != null &&
                        routine.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        routine.description!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Metadata chips
                    Row(
                      children: [
                        _MetaChip(
                          icon: Icons.format_list_numbered_rounded,
                          label: '$stepCount paso${stepCount == 1 ? '' : 's'}',
                        ),
                        const SizedBox(width: 8),
                        _MetaChip(
                          icon: Icons.timer_outlined,
                          label: '$estimatedMinutes min',
                        ),
                        if (routine.complexityLevel != null) ...[
                          const SizedBox(width: 8),
                          _MetaChip(
                            icon: Icons.signal_cellular_alt_rounded,
                            label: 'Nv ${routine.complexityLevel}',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Play icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _estimateDuration(RoutineRow routine) {
    final steps = routine.routineSteps;
    if (steps == null || steps.isEmpty) return 0;
    final totalSeconds =
        steps.fold<int>(0, (sum, step) => sum + step.durationHint);
    return (totalSeconds / 60).ceil();
  }
}

// ---------------------------------------------------------------------------
// Metadata Chip
// ---------------------------------------------------------------------------

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.checklist_rounded,
                size: 48,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No tienes rutinas asignadas',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tu cuidador puede asignarte rutinas desde el panel de control.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
              'No se pudieron cargar las rutinas',
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
