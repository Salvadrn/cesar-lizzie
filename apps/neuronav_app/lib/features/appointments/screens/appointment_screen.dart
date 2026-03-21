import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/appointment_provider.dart';
import '../../../data/models/appointment.dart';

class AppointmentScreen extends ConsumerWidget {
  const AppointmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apptsAsync = ref.watch(appointmentsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Citas Medicas'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Proximas'),
              Tab(text: 'Pasadas'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/appointments/add'),
          icon: const Icon(Icons.add),
          label: const Text('Agregar'),
        ),
        body: apptsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorBody(
            onRetry: () => ref.read(appointmentsProvider.notifier).load(),
          ),
          data: (_) => const TabBarView(
            children: [
              _UpcomingTab(),
              _PastTab(),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error body
// ---------------------------------------------------------------------------

class _ErrorBody extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorBody({required this.onRetry});

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
            Text(
              'No se pudieron cargar las citas.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
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
// Upcoming appointments tab
// ---------------------------------------------------------------------------

class _UpcomingTab extends ConsumerWidget {
  const _UpcomingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingAppointmentsProvider);

    if (upcoming.isEmpty) {
      return _EmptyTabState(
        icon: Icons.event_available,
        message: 'No tienes citas proximas',
        subtitle: 'Agrega una cita para llevar el control de tus visitas medicas.',
      );
    }

    // Sort upcoming by date ascending (nearest first)
    final sorted = List<AppointmentRow>.from(upcoming)
      ..sort((a, b) {
        final dateA = a.date ?? DateTime(2100);
        final dateB = b.date ?? DateTime(2100);
        return dateA.compareTo(dateB);
      });

    return RefreshIndicator(
      onRefresh: () => ref.read(appointmentsProvider.notifier).load(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: sorted.length,
        itemBuilder: (context, index) => _AppointmentCard(
          appointment: sorted[index],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Past appointments tab
// ---------------------------------------------------------------------------

class _PastTab extends ConsumerWidget {
  const _PastTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final past = ref.watch(pastAppointmentsProvider);

    if (past.isEmpty) {
      return _EmptyTabState(
        icon: Icons.history,
        message: 'No hay citas pasadas',
        subtitle: 'Las citas anteriores apareceran aqui.',
      );
    }

    // Sort past by date descending (most recent first)
    final sorted = List<AppointmentRow>.from(past)
      ..sort((a, b) {
        final dateA = a.date ?? DateTime(2000);
        final dateB = b.date ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });

    return RefreshIndicator(
      onRefresh: () => ref.read(appointmentsProvider.notifier).load(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: sorted.length,
        itemBuilder: (context, index) => _AppointmentCard(
          appointment: sorted[index],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state for each tab
// ---------------------------------------------------------------------------

class _EmptyTabState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;

  const _EmptyTabState({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: theme.colorScheme.primary.withOpacity(0.4)),
            const SizedBox(height: 20),
            Text(
              message,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
// Appointment card
// ---------------------------------------------------------------------------

class _AppointmentCard extends ConsumerWidget {
  final AppointmentRow appointment;
  const _AppointmentCard({required this.appointment});

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Fecha no disponible';
    final months = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    final day = dt.day.toString();
    final month = months[dt.month];
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year - $hour:$minute';
  }

  String _formatDateLong(DateTime? dt) {
    if (dt == null) return 'Fecha no disponible';
    final weekdays = ['', 'Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado', 'Domingo'];
    final months = [
      '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    final weekday = weekdays[dt.weekday];
    final day = dt.day;
    final month = months[dt.month];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$weekday $day de $month $year, $hour:$minute';
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cita'),
        content: Text(
          'La cita con ${appointment.doctorName} se eliminara permanentemente.',
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

  void _showDetails(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor name
              Text(
                appointment.doctorName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (appointment.specialty != null && appointment.specialty!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  appointment.specialty!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Date & time
              _DetailRow(
                icon: Icons.calendar_today,
                label: 'Fecha y hora',
                value: _formatDateLong(appointment.date),
              ),
              const SizedBox(height: 16),

              // Location
              if (appointment.location != null && appointment.location!.isNotEmpty) ...[
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Ubicacion',
                  value: appointment.location!,
                ),
                const SizedBox(height: 16),
              ],

              // Recurring
              if (appointment.isRecurring) ...[
                _DetailRow(
                  icon: Icons.repeat,
                  label: 'Recurrente',
                  value: 'Cada ${appointment.recurringMonths ?? 1} ${(appointment.recurringMonths ?? 1) == 1 ? "mes" : "meses"}',
                ),
                const SizedBox(height: 16),
              ],

              // Status
              _DetailRow(
                icon: Icons.info_outline,
                label: 'Estado',
                value: _statusLabel(appointment.status),
              ),

              // Notes
              if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Notas',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    appointment.notes!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'scheduled':
        return 'Programada';
      case 'completed':
        return 'Completada';
      case 'cancelled':
        return 'Cancelada';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPast = appointment.isPast;

    return Dismissible(
      key: ValueKey(appointment.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) {
        ref.read(appointmentsProvider.notifier).deleteAppointment(appointment.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cita con ${appointment.doctorName} eliminada')),
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
        child: InkWell(
          onTap: () => _showDetails(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Date circle
                _DateBadge(date: appointment.date, isPast: isPast),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.doctorName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (appointment.specialty != null &&
                          appointment.specialty!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          appointment.specialty!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(appointment.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (appointment.location != null &&
                          appointment.location!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                appointment.location!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Recurring icon
                if (appointment.isRecurring)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.repeat,
                      size: 20,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),

                // Chevron
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Date badge
// ---------------------------------------------------------------------------

class _DateBadge extends StatelessWidget {
  final DateTime? date;
  final bool isPast;
  const _DateBadge({required this.date, required this.isPast});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final months = [
      '', 'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
      'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
    ];

    final bgColor = isPast
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.primaryContainer;
    final textColor = isPast
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onPrimaryContainer;

    return Container(
      width: 56,
      height: 64,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            date != null ? '${date!.day}' : '--',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            date != null ? months[date!.month] : '---',
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail row (for bottom sheet)
// ---------------------------------------------------------------------------

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
