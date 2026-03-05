import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/medication_provider.dart';
import '../../../data/models/medication.dart';

class MedicationScreen extends ConsumerWidget {
  const MedicationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(medicationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Medicamentos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/medications/add'),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: medsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => _ErrorBody(
          message: 'No se pudieron cargar los medicamentos.',
          onRetry: () => ref.read(medicationsProvider.notifier).load(),
        ),
        data: (meds) {
          if (meds.isEmpty) {
            return _EmptyState(
              onAdd: () => context.push('/medications/add'),
            );
          }
          return _MedicationList(medications: meds);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.4),
            ),
            const SizedBox(height: 24),
            Text(
              'No tienes medicamentos registrados',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Agrega tus medicamentos para recibir recordatorios.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Agregar medicamento'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(220, 56),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error body
// ---------------------------------------------------------------------------

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(message, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Medication list with pull-to-refresh and grouped sections
// ---------------------------------------------------------------------------

class _MedicationList extends ConsumerWidget {
  final List<MedicationRow> medications;
  const _MedicationList({required this.medications});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = medications.where((m) => !m.takenToday).toList();
    final taken = medications.where((m) => m.takenToday).toList();

    // Sort pending by time
    pending.sort((a, b) {
      final aMin = a.hour * 60 + a.minute;
      final bMin = b.hour * 60 + b.minute;
      return aMin.compareTo(bMin);
    });

    taken.sort((a, b) {
      final aMin = a.hour * 60 + a.minute;
      final bMin = b.hour * 60 + b.minute;
      return aMin.compareTo(bMin);
    });

    return RefreshIndicator(
      onRefresh: () => ref.read(medicationsProvider.notifier).load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          if (pending.isNotEmpty) ...[
            _SectionHeader(
              title: 'Pendientes',
              count: pending.length,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            ...pending.map((med) => _MedicationCard(medication: med)),
            const SizedBox(height: 24),
          ],
          if (taken.isNotEmpty) ...[
            _SectionHeader(
              title: 'Tomados',
              count: taken.length,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            const SizedBox(height: 8),
            ...taken.map((med) => _MedicationCard(medication: med)),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  const _SectionHeader({required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$title ($count)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Medication card
// ---------------------------------------------------------------------------

class _MedicationCard extends ConsumerWidget {
  final MedicationRow medication;
  const _MedicationCard({required this.medication});

  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar medicamento'),
        content: Text(
          '${medication.name} se eliminará permanentemente. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isTaken = medication.takenToday;
    final timeStr = _formatTime(medication.hour, medication.minute);

    return Dismissible(
      key: ValueKey(medication.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) {
        ref.read(medicationsProvider.notifier).deleteMedication(medication.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${medication.name} eliminado')),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onError, size: 28),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Time badge
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isTaken
                      ? theme.colorScheme.tertiaryContainer
                      : theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  timeStr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isTaken
                        ? theme.colorScheme.onTertiaryContainer
                        : theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: isTaken ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      medication.dosage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (isTaken) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: theme.colorScheme.tertiary),
                          const SizedBox(width: 4),
                          Text(
                            'Tomado',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.tertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Action button
              if (!isTaken)
                FilledButton(
                  onPressed: () {
                    ref.read(medicationsProvider.notifier).markAsTaken(medication.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${medication.name} marcado como tomado'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(80, 48),
                  ),
                  child: const Text('Tomar'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
