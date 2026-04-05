import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/caregiver_link.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/family_provider.dart';

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(familyProvider);
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Familia'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // -- Error message --
                  if (state.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Card(
                        color: colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: colorScheme.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.errorMessage!,
                                  style: TextStyle(
                                    color: colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // -- Action buttons --
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: () =>
                                  _generateInvite(context, ref),
                              icon: const Icon(Icons.qr_code_rounded),
                              label: const Text(
                                'Generar Codigo',
                                style: TextStyle(fontSize: 15),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  context.push('/family/invite'),
                              icon: const Icon(Icons.keyboard_rounded),
                              label: const Text(
                                'Ingresar Codigo',
                                style: TextStyle(fontSize: 15),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // -- Generated code display --
                  if (state.generatedCode != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        color: colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                'Codigo de Invitacion',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    state.generatedCode!,
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 6,
                                      color:
                                          colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(
                                        text: state.generatedCode!,
                                      ));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Codigo copiado al portapapeles',
                                          ),
                                        ),
                                      );
                                    },
                                    icon: Icon(
                                      Icons.copy_rounded,
                                      color:
                                          colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Comparte este codigo con tu familiar o cuidador',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer
                                      .withValues(alpha: 0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // -- Linked users list --
                  Expanded(
                    child: state.links.isEmpty
                        ? _EmptyState()
                        : RefreshIndicator(
                            onRefresh: () =>
                                ref.read(familyProvider.notifier).load(),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: state.links.length,
                              itemBuilder: (context, index) {
                                final link = state.links[index];
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 12),
                                  child: _LinkCard(
                                    link: link,
                                    isCurrentUserCaregiver:
                                        authState.isCaregiver,
                                    currentUserId:
                                        authState.currentProfile?.id,
                                    onTap: () {
                                      // Navigate to patient detail
                                      // if the current user is the
                                      // caregiver viewing a patient
                                      if (authState.isCaregiver &&
                                          link.userId !=
                                              authState
                                                  .currentProfile?.id) {
                                        context.push(
                                          '/family/patient/${link.id}',
                                        );
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  void _generateInvite(BuildContext context, WidgetRef ref) async {
    await ref.read(familyProvider.notifier).generateInvite();
    final state = ref.read(familyProvider);

    if (state.generatedCode != null && context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Codigo Generado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Comparte este codigo con la persona que quieres vincular:',
              ),
              const SizedBox(height: 16),
              SelectableText(
                state.generatedCode!,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: state.generatedCode!),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Codigo copiado al portapapeles'),
                  ),
                );
              },
              child: const Text('Copiar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }
}

// =============================================================================
// Empty State
// =============================================================================

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 80,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No tienes personas vinculadas',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Genera un codigo de invitacion o ingresa uno para vincular a tu familiar o cuidador.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Link Card
// =============================================================================

class _LinkCard extends StatelessWidget {
  final CaregiverLinkRow link;
  final bool isCurrentUserCaregiver;
  final String? currentUserId;
  final VoidCallback onTap;

  const _LinkCard({
    required this.link,
    required this.isCurrentUserCaregiver,
    required this.currentUserId,
    required this.onTap,
  });

  String get _roleLabel {
    // If the current user is the caregiver, the linked person is the patient
    if (isCurrentUserCaregiver && link.userId != currentUserId) {
      return 'Paciente';
    }
    // If the current user is the patient, the linked person is the caregiver
    if (link.caregiverId != currentUserId) {
      return 'Cuidador';
    }
    return 'Familiar';
  }

  Color _roleColor(ColorScheme colorScheme) {
    switch (_roleLabel) {
      case 'Paciente':
        return Colors.blue.shade700;
      case 'Cuidador':
        return Colors.green.shade700;
      default:
        return Colors.purple.shade700;
    }
  }

  IconData get _roleIcon {
    switch (_roleLabel) {
      case 'Paciente':
        return Icons.person_rounded;
      case 'Cuidador':
        return Icons.medical_services_rounded;
      default:
        return Icons.family_restroom_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayName =
        link.profiles?.displayName ?? 'Usuario';
    final canViewDetail =
        isCurrentUserCaregiver && link.userId != currentUserId;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: canViewDetail ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: _roleColor(colorScheme).withValues(alpha: 0.15),
                child: Icon(
                  _roleIcon,
                  size: 28,
                  color: _roleColor(colorScheme),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _roleColor(colorScheme)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _roleLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _roleColor(colorScheme),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: link.status == 'active'
                                ? Colors.green.withValues(alpha: 0.12)
                                : Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            link.status == 'active'
                                ? 'Activo'
                                : 'Pendiente',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: link.status == 'active'
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow for navigable cards
              if (canViewDetail)
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
