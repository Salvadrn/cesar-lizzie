import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/alert.dart';
import '../../../data/models/caregiver_link.dart';
import '../../../data/models/execution.dart';
import '../../../data/models/profile_data.dart';
import '../../../providers/family_provider.dart';

class PatientDetailScreen extends ConsumerStatefulWidget {
  final String linkId;

  const PatientDetailScreen({super.key, required this.linkId});

  @override
  ConsumerState<PatientDetailScreen> createState() =>
      _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  CaregiverLinkRow? _link;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  void _loadData() {
    final state = ref.read(familyProvider);
    final link = state.links
        .where((l) => l.id == widget.linkId)
        .firstOrNull;

    if (link != null) {
      _link = link;
      // Load patient detail using the linked user's ID
      ref
          .read(familyProvider.notifier)
          .loadPatientDetail(link.userId, link);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(familyProvider);
    final link = _link;

    final displayName =
        state.patientProfile?.displayName ??
        link?.profiles?.displayName ??
        'Paciente';

    return Scaffold(
      appBar: AppBar(
        title: Text(displayName),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person_rounded), text: 'Perfil'),
            Tab(icon: Icon(Icons.timeline_rounded), text: 'Actividad'),
            Tab(icon: Icon(Icons.notifications_rounded), text: 'Alertas'),
          ],
        ),
        actions: [
          if (link != null && link.permViewMedications)
            IconButton(
              onPressed: () {
                context.push(
                  '/family/patient/${link.userId}/medications',
                );
              },
              icon: const Icon(Icons.medication_rounded),
              tooltip: 'Medicamentos',
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _ProfileTab(
                  profile: state.patientProfile,
                  link: link,
                ),
                _ActivityTab(
                  executions: state.patientExecutions,
                  hasPermission: link?.permViewActivity ?? false,
                ),
                _AlertsTab(
                  alerts: state.patientAlerts,
                ),
              ],
            ),
    );
  }
}

// =============================================================================
// Profile Tab
// =============================================================================

class _ProfileTab extends StatelessWidget {
  final ProfileData? profile;
  final CaregiverLinkRow? link;

  const _ProfileTab({
    required this.profile,
    required this.link,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (profile == null) {
      return const Center(
        child: Text('No se pudo cargar el perfil'),
      );
    }

    final p = profile!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 48,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              p.displayName.isNotEmpty
                  ? p.displayName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            p.displayName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (p.email != null) ...[
            const SizedBox(height: 4),
            Text(
              p.email!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Info cards
          _InfoTile(
            icon: Icons.speed_rounded,
            label: 'Nivel de Complejidad',
            value: '${p.currentComplexity} / ${p.complexityCeiling}',
            subtitle:
                'Rango: ${p.complexityFloor} - ${p.complexityCeiling}',
          ),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.hearing_rounded,
            label: 'Modo Sensorial',
            value: _sensoryModeLabel(p.sensoryMode),
          ),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.touch_app_rounded,
            label: 'Entrada Preferida',
            value: _inputLabel(p.preferredInput),
          ),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.bar_chart_rounded,
            label: 'Sesiones Totales',
            value: '${p.totalSessions}',
            subtitle: 'Errores totales: ${p.totalErrors}',
          ),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.timer_rounded,
            label: 'Tiempo Promedio de Respuesta',
            value: '${p.avgResponseTime.toStringAsFixed(1)}s',
          ),

          // Permissions section
          if (link != null) ...[
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Permisos',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _PermissionChip(
              label: 'Ver Actividad',
              enabled: link!.permViewActivity,
            ),
            _PermissionChip(
              label: 'Editar Rutinas',
              enabled: link!.permEditRoutines,
            ),
            _PermissionChip(
              label: 'Ver Ubicacion',
              enabled: link!.permViewLocation,
            ),
            _PermissionChip(
              label: 'Ver Medicamentos',
              enabled: link!.permViewMedications,
            ),
            _PermissionChip(
              label: 'Ver Emergencias',
              enabled: link!.permViewEmergency,
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _sensoryModeLabel(String mode) {
    switch (mode) {
      case 'visual':
        return 'Visual';
      case 'auditory':
        return 'Auditivo';
      case 'haptic':
        return 'Haptico';
      case 'minimal':
        return 'Minimo';
      default:
        return 'Predeterminado';
    }
  }

  String _inputLabel(String input) {
    switch (input) {
      case 'touch':
        return 'Tactil';
      case 'voice':
        return 'Voz';
      case 'switch':
        return 'Interruptor';
      default:
        return input;
    }
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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

class _PermissionChip extends StatelessWidget {
  final String label;
  final bool enabled;

  const _PermissionChip({
    required this.label,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            enabled
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            color: enabled ? Colors.green.shade700 : Colors.grey,
            size: 22,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: enabled
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Activity Tab
// =============================================================================

class _ActivityTab extends StatelessWidget {
  final List<ExecutionRow> executions;
  final bool hasPermission;

  const _ActivityTab({
    required this.executions,
    required this.hasPermission,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!hasPermission) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_rounded,
                size: 64,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Sin permiso para ver actividad',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'El paciente no ha otorgado permiso para ver su actividad.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (executions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history_rounded,
                size: 64,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Sin actividad reciente',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: executions.length,
      itemBuilder: (context, index) {
        final exec = executions[index];
        return _ExecutionCard(execution: exec);
      },
    );
  }
}

class _ExecutionCard extends StatelessWidget {
  final ExecutionRow execution;

  const _ExecutionCard({required this.execution});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm', 'es');
    final startDate = DateTime.tryParse(execution.startedAt);
    final startText =
        startDate != null ? dateFormatter.format(startDate.toLocal()) : '--';

    String? durationText;
    if (execution.completedAt != null) {
      final endDate = DateTime.tryParse(execution.completedAt!);
      if (startDate != null && endDate != null) {
        final diff = endDate.difference(startDate);
        if (diff.inHours > 0) {
          durationText = '${diff.inHours}h ${diff.inMinutes % 60}min';
        } else {
          durationText = '${diff.inMinutes}min';
        }
      }
    }

    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (execution.status) {
      case 'completed':
        statusColor = Colors.green.shade700;
        statusLabel = 'Completada';
        statusIcon = Icons.check_circle_rounded;
      case 'in_progress':
        statusColor = Colors.blue.shade700;
        statusLabel = 'En progreso';
        statusIcon = Icons.play_circle_rounded;
      case 'aborted':
        statusColor = Colors.red.shade700;
        statusLabel = 'Cancelada';
        statusIcon = Icons.cancel_rounded;
      default:
        statusColor = Colors.grey;
        statusLabel = execution.status;
        statusIcon = Icons.circle_outlined;
    }

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                const Spacer(),
                if (durationText != null)
                  Text(
                    durationText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              startText,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            // Progress bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: execution.totalSteps > 0
                          ? execution.completedSteps /
                              execution.totalSteps
                          : 0,
                      minHeight: 6,
                      backgroundColor:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.15),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${execution.completedSteps}/${execution.totalSteps}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (execution.errorCount > 0 || execution.stallCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    if (execution.errorCount > 0) ...[
                      Icon(Icons.error_outline,
                          size: 14, color: Colors.red.shade400),
                      const SizedBox(width: 4),
                      Text(
                        '${execution.errorCount} errores',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade400,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (execution.stallCount > 0) ...[
                      Icon(Icons.pause_circle_outline,
                          size: 14, color: Colors.orange.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${execution.stallCount} pausas',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade600,
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

// =============================================================================
// Alerts Tab
// =============================================================================

class _AlertsTab extends StatelessWidget {
  final List<AlertRow> alerts;

  const _AlertsTab({required this.alerts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (alerts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_off_rounded,
                size: 64,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Sin alertas',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return _AlertCard(alert: alert);
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertRow alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm', 'es');
    final date = DateTime.tryParse(alert.createdAt);
    final dateText =
        date != null ? dateFormatter.format(date.toLocal()) : '--';

    Color severityColor;
    IconData severityIcon;
    switch (alert.severity) {
      case 'critical':
        severityColor = Colors.red.shade700;
        severityIcon = Icons.warning_amber_rounded;
      case 'high':
        severityColor = Colors.orange.shade700;
        severityIcon = Icons.priority_high_rounded;
      case 'medium':
        severityColor = Colors.amber.shade700;
        severityIcon = Icons.info_outline_rounded;
      default:
        severityColor = Colors.blue.shade700;
        severityIcon = Icons.info_outline_rounded;
    }

    return Card(
      elevation: 0,
      color: alert.isRead
          ? colorScheme.surfaceContainerLow
          : severityColor.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: alert.isRead
            ? BorderSide.none
            : BorderSide(
                color: severityColor.withValues(alpha: 0.3),
                width: 1,
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(severityIcon, color: severityColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: severityColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _severityLabel(alert.severity),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: severityColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (alert.message != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      alert.message!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _alertTypeLabel(alert.alertType),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _severityLabel(String severity) {
    switch (severity) {
      case 'critical':
        return 'Critico';
      case 'high':
        return 'Alto';
      case 'medium':
        return 'Medio';
      case 'low':
        return 'Bajo';
      default:
        return 'Info';
    }
  }

  String _alertTypeLabel(String type) {
    switch (type) {
      case 'emergency':
        return 'Emergencia';
      case 'stall':
        return 'Pausa detectada';
      case 'fall':
        return 'Caida detectada';
      case 'zone_exit':
        return 'Salio de zona segura';
      case 'medication_missed':
        return 'Medicamento no tomado';
      default:
        return type;
    }
  }
}
