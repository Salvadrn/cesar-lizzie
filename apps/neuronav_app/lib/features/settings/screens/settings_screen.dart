import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/api_client.dart';
import '../../../core/constants/app_constants.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final profile = authState.currentProfile;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ----------------------------------------------------------------
          // PERFIL
          // ----------------------------------------------------------------
          _SectionHeader(title: 'Perfil'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      _initials(
                        profile?.displayName ??
                            authState.currentRole.displayName,
                      ),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.displayName.isNotEmpty == true
                              ? profile!.displayName
                              : (authState.isGuestMode
                                  ? 'Invitado'
                                  : 'Usuario'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            authState.currentRole.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ----------------------------------------------------------------
          // ACCESIBILIDAD
          // ----------------------------------------------------------------
          _SectionHeader(title: 'Accesibilidad'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                // -- Modo Sensorial --
                _SensoryModeTile(
                  currentMode: profile?.sensoryMode ?? 'default',
                  isGuest: authState.isGuestMode,
                  onChanged: (mode) =>
                      _updateProfile(context, ref, sensoryMode: mode),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),

                // -- Tamano de Fuente --
                _FontScaleTile(
                  fontScale: profile?.fontScale ?? 1.0,
                  isGuest: authState.isGuestMode,
                  onChanged: (scale) =>
                      _updateProfile(context, ref, fontScale: scale),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),

                // -- Haptics --
                SwitchListTile(
                  secondary: const Icon(Icons.vibration_rounded),
                  title: const Text('Vibraciones'),
                  subtitle: const Text('Retroalimentacion haptica'),
                  value: profile?.hapticEnabled ?? true,
                  onChanged: (val) =>
                      _updateProfile(context, ref, hapticEnabled: val),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),

                // -- Audio --
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up_rounded),
                  title: const Text('Audio'),
                  subtitle: const Text('Instrucciones por voz'),
                  value: profile?.audioEnabled ?? true,
                  onChanged: (val) =>
                      _updateProfile(context, ref, audioEnabled: val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ----------------------------------------------------------------
          // MODO SIMPLE (only for patients who are NOT also caregivers)
          // ----------------------------------------------------------------
          if (authState.isPatient) ...[
            _SectionHeader(title: 'Modo Simple'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  if (authState.isCaregiver)
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      title: const Text('Modo Simple no disponible'),
                      subtitle: const Text(
                        'Los usuarios con rol de cuidador no pueden activar el Modo Simple.',
                      ),
                      enabled: false,
                    )
                  else
                    SwitchListTile(
                      secondary: const Icon(Icons.touch_app_rounded),
                      title: const Text('Modo Simple'),
                      subtitle: const Text(
                        'Interfaz simplificada con botones grandes',
                      ),
                      value: authState.isSimpleModeActive,
                      onChanged: (val) {
                        if (authState.isGuestMode) {
                          ref
                              .read(authStateProvider.notifier)
                              .setGuestSimpleMode(val);
                        } else {
                          _updateProfile(context, ref, simpleMode: val);
                        }
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ----------------------------------------------------------------
          // CUENTA
          // ----------------------------------------------------------------
          _SectionHeader(title: 'Cuenta'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('Creditos'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/settings/credits'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(
                    Icons.logout_rounded,
                    color: colorScheme.error,
                  ),
                  title: Text(
                    authState.isGuestMode
                        ? 'Salir del Modo Invitado'
                        : 'Cerrar Sesion',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => _confirmLogout(context, ref, authState),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> _updateProfile(
    BuildContext context,
    WidgetRef ref, {
    String? sensoryMode,
    double? fontScale,
    bool? hapticEnabled,
    bool? audioEnabled,
    bool? simpleMode,
  }) async {
    final authState = ref.read(authStateProvider);
    if (authState.isGuestMode) {
      // Guest mode: no backend calls -- only local state is relevant.
      // For simplicity, most settings are no-ops in guest mode except
      // simpleMode which is handled separately.
      return;
    }

    try {
      await ApiClient.updateProfile(
        ProfileUpdate(
          sensoryMode: sensoryMode,
          fontScale: fontScale,
          hapticEnabled: hapticEnabled,
          audioEnabled: audioEnabled,
          simpleMode: simpleMode,
        ),
      );
      await ref.read(authStateProvider.notifier).refreshProfile();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _confirmLogout(
    BuildContext context,
    WidgetRef ref,
    AuthState authState,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          authState.isGuestMode ? 'Salir del Modo Invitado' : 'Cerrar Sesion',
        ),
        content: Text(
          authState.isGuestMode
              ? 'Volveras a la pantalla de inicio de sesion. Los datos de prueba no se guardaran.'
              : 'Se cerrara tu sesion actual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authStateProvider.notifier).logout();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(authState.isGuestMode ? 'Salir' : 'Cerrar Sesion'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Private helper widgets
// =============================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _SensoryModeTile extends StatelessWidget {
  final String currentMode;
  final bool isGuest;
  final ValueChanged<String> onChanged;

  const _SensoryModeTile({
    required this.currentMode,
    required this.isGuest,
    required this.onChanged,
  });

  static const _modes = [
    ('default', 'Predeterminado'),
    ('low_stimulation', 'Baja Estimulacion'),
    ('high_contrast', 'Alto Contraste'),
  ];

  String _displayName(String mode) {
    for (final m in _modes) {
      if (m.$1 == mode) return m.$2;
    }
    return 'Predeterminado';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.palette_rounded),
      title: const Text('Modo Sensorial'),
      subtitle: Text(_displayName(currentMode)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Modo Sensorial',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ..._modes.map((m) => RadioListTile<String>(
                      title: Text(m.$2),
                      value: m.$1,
                      groupValue: currentMode,
                      onChanged: (val) {
                        Navigator.of(ctx).pop();
                        if (val != null) onChanged(val);
                      },
                    )),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FontScaleTile extends StatelessWidget {
  final double fontScale;
  final bool isGuest;
  final ValueChanged<double> onChanged;

  const _FontScaleTile({
    required this.fontScale,
    required this.isGuest,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final displayPercent = (fontScale * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.text_fields_rounded),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Tamano de Fuente',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              Text(
                '$displayPercent%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          Slider(
            value: fontScale,
            min: 0.8,
            max: 1.6,
            divisions: 8,
            label: '$displayPercent%',
            onChangeEnd: onChanged,
            onChanged: (_) {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'A',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  'A',
                  style: TextStyle(
                    fontSize: 20,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
