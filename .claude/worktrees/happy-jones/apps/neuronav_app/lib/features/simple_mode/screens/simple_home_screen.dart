import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/medication_provider.dart';
import '../../../providers/emergency_provider.dart';

class SimpleHomeScreen extends ConsumerWidget {
  const SimpleHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final pendingMeds = ref.watch(pendingMedsCountProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final profile = authState.currentProfile;
    final name = profile?.displayName.isNotEmpty == true
        ? profile!.displayName
        : (authState.isGuestMode
            ? 'Invitado'
            : 'Usuario');
    final greeting = _greeting();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -- Greeting --
              const SizedBox(height: 12),
              Text(
                '$greeting,',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                name,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 32),

              // -- Buttons --
              Expanded(
                child: Column(
                  children: [
                    _SimpleBigButton(
                      icon: Icons.checklist_rounded,
                      label: 'Mis Rutinas',
                      color: colorScheme.primary,
                      onTap: () => context.go('/routines'),
                    ),
                    const SizedBox(height: 16),
                    _SimpleBigButton(
                      icon: Icons.medication_rounded,
                      label: 'Medicamentos',
                      color: const Color(0xFF34C759),
                      badge: pendingMeds > 0 ? '$pendingMeds' : null,
                      onTap: () => context.go('/medications'),
                    ),
                    const SizedBox(height: 16),
                    _SimpleBigButton(
                      icon: Icons.sos_rounded,
                      label: 'Llamar Ayuda',
                      color: Colors.red,
                      onTap: () => _triggerEmergency(context, ref),
                    ),
                    const SizedBox(height: 16),
                    _SimpleBigButton(
                      icon: Icons.settings_rounded,
                      label: 'Ajustes',
                      color: Colors.grey.shade600,
                      onTap: () => context.go('/simple/settings'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos dias';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  void _triggerEmergency(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.sos_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Llamar Ayuda'),
          ],
        ),
        content: const Text(
          'Se activara la alerta de emergencia y se llamara a tu contacto principal. Deseas continuar?',
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 18),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(emergencyProvider.notifier).triggerEmergency();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Llamar Ayuda',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleBigButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _SimpleBigButton({
    required this.icon,
    required this.label,
    required this.color,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, size: 36, color: color),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                  if (badge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: color.withValues(alpha: 0.5),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
