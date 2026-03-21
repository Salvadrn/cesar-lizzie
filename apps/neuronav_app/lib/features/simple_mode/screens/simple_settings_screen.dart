import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/api_client.dart';

class SimpleSettingsScreen extends ConsumerWidget {
  const SimpleSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final profile = authState.currentProfile;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final fontScale = profile?.fontScale ?? 1.0;
    final hapticEnabled = profile?.hapticEnabled ?? true;
    final audioEnabled = profile?.audioEnabled ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ajustes',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 32),
          onPressed: () => context.go('/simple'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // -- Cambiar a Modo Normal --
              _SimpleLargeButton(
                icon: Icons.dashboard_rounded,
                label: 'Cambiar a Modo Normal',
                color: colorScheme.primary,
                onTap: () => _toggleSimpleMode(context, ref, authState),
              ),
              const SizedBox(height: 20),

              // -- Font size controls --
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.12),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tamano de Texto',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(fontScale * 100).round()}%',
                        style: TextStyle(
                          fontSize: 18,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 64,
                              child: ElevatedButton.icon(
                                onPressed: fontScale <= 0.8
                                    ? null
                                    : () => _updateFontScale(
                                        context, ref, authState,
                                        fontScale - 0.1),
                                icon: const Icon(Icons.text_decrease_rounded,
                                    size: 28),
                                label: const Text(
                                  'Mas Pequeno',
                                  style: TextStyle(fontSize: 18),
                                ),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 64,
                              child: ElevatedButton.icon(
                                onPressed: fontScale >= 1.6
                                    ? null
                                    : () => _updateFontScale(
                                        context, ref, authState,
                                        fontScale + 0.1),
                                icon: const Icon(Icons.text_increase_rounded,
                                    size: 28),
                                label: const Text(
                                  'Mas Grande',
                                  style: TextStyle(fontSize: 18),
                                ),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // -- Haptics toggle --
              _SimpleSwitchTile(
                icon: Icons.vibration_rounded,
                label: 'Vibraciones',
                value: hapticEnabled,
                onChanged: (val) =>
                    _updateSetting(context, ref, authState, hapticEnabled: val),
              ),
              const SizedBox(height: 12),

              // -- Audio toggle --
              _SimpleSwitchTile(
                icon: Icons.volume_up_rounded,
                label: 'Audio',
                value: audioEnabled,
                onChanged: (val) =>
                    _updateSetting(context, ref, authState, audioEnabled: val),
              ),

              const Spacer(),

              // -- Logout / Exit --
              SizedBox(
                width: double.infinity,
                height: 64,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmExit(context, ref, authState),
                  icon: Icon(Icons.logout_rounded,
                      size: 28, color: colorScheme.error),
                  label: Text(
                    authState.isGuestMode
                        ? 'Salir del Modo Invitado'
                        : 'Cerrar Sesion',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.error,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colorScheme.error, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleSimpleMode(
    BuildContext context,
    WidgetRef ref,
    AuthState authState,
  ) {
    if (authState.isGuestMode) {
      ref.read(authStateProvider.notifier).setGuestSimpleMode(false);
    } else {
      _updateSetting(context, ref, authState, simpleMode: false);
    }
  }

  Future<void> _updateFontScale(
    BuildContext context,
    WidgetRef ref,
    AuthState authState,
    double newScale,
  ) async {
    final clamped = newScale.clamp(0.8, 1.6);
    final rounded = (clamped * 10).round() / 10;

    if (authState.isGuestMode) return;

    try {
      await ApiClient.updateProfile(ProfileUpdate(fontScale: rounded));
      await ref.read(authStateProvider.notifier).refreshProfile();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    }
  }

  Future<void> _updateSetting(
    BuildContext context,
    WidgetRef ref,
    AuthState authState, {
    bool? hapticEnabled,
    bool? audioEnabled,
    bool? simpleMode,
  }) async {
    if (authState.isGuestMode) {
      if (simpleMode != null) {
        ref.read(authStateProvider.notifier).setGuestSimpleMode(simpleMode);
      }
      return;
    }

    try {
      await ApiClient.updateProfile(
        ProfileUpdate(
          hapticEnabled: hapticEnabled,
          audioEnabled: audioEnabled,
          simpleMode: simpleMode,
        ),
      );
      await ref.read(authStateProvider.notifier).refreshProfile();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    }
  }

  void _confirmExit(
    BuildContext context,
    WidgetRef ref,
    AuthState authState,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          authState.isGuestMode ? 'Salir del Modo Invitado' : 'Cerrar Sesion',
          style: const TextStyle(fontSize: 22),
        ),
        content: Text(
          authState.isGuestMode
              ? 'Volveras a la pantalla de inicio de sesion.'
              : 'Se cerrara tu sesion actual.',
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(fontSize: 18)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authStateProvider.notifier).logout();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              authState.isGuestMode ? 'Salir' : 'Cerrar Sesion',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleLargeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SimpleLargeButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 32),
        label: Text(
          label,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

class _SimpleSwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SimpleSwitchTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 32, color: colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Transform.scale(
              scale: 1.3,
              child: Switch(
                value: value,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
