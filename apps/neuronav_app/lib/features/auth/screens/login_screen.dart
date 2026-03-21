import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  /// Generates a cryptographically-secure random nonce string.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the sha256 hash of [input] as a hex string.
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _signInWithApple(BuildContext context, WidgetRef ref) async {
    final rawNonce = _generateNonce();
    final sha256Nonce = _sha256ofString(rawNonce);

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256Nonce,
      );

      await ref.read(authStateProvider.notifier).signInWithApple(
            credential.identityToken!,
            rawNonce,
          );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return;
      if (context.mounted) {
        _showError(context, 'Error al iniciar sesion con Apple: ${e.message}');
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Error inesperado: $e');
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // -- Logo & Title --
                  _buildHeader(colorScheme),

                  const SizedBox(height: 48),

                  // -- Apple Sign In --
                  _buildAppleSignInButton(context, ref),

                  const SizedBox(height: 32),

                  // -- Divider --
                  _buildDivider(colorScheme),

                  const SizedBox(height: 32),

                  // -- Guest Section --
                  Text(
                    'Continuar como Invitado',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explora la aplicacion sin crear una cuenta',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // -- Role cards --
                  _buildRoleCard(
                    context: context,
                    ref: ref,
                    icon: Icons.person_rounded,
                    title: 'Paciente',
                    description:
                        'Persona que utilizara las rutinas y herramientas de asistencia diaria.',
                    role: UserRole.patient,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  _buildRoleCard(
                    context: context,
                    ref: ref,
                    icon: Icons.health_and_safety_rounded,
                    title: 'Cuidador',
                    description:
                        'Profesional o familiar que supervisa y apoya al paciente.',
                    role: UserRole.caregiver,
                    color: const Color(0xFF34C759),
                  ),
                  const SizedBox(height: 12),
                  _buildRoleCard(
                    context: context,
                    ref: ref,
                    icon: Icons.family_restroom_rounded,
                    title: 'Familiar',
                    description:
                        'Miembro de la familia que desea monitorear el progreso.',
                    role: UserRole.family,
                    color: const Color(0xFFFF9500),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),

            // -- Error message --
            if (authState.errorMessage != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  color: colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: colorScheme.onErrorContainer),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            authState.errorMessage!,
                            style: TextStyle(
                              color: colorScheme.onErrorContainer,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // -- Loading overlay --
            if (authState.isLoading)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Iniciando sesion...'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.psychology_rounded,
            size: 44,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'NeuroNav',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Asistente de Vida Diaria Adaptativo',
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAppleSignInButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () => _signInWithApple(context, ref),
        icon: const Icon(Icons.apple, size: 28),
        label: const Text(
          'Iniciar sesion con Apple',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'o',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 15,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String title,
    required String description,
    required UserRole role,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ref.read(authStateProvider.notifier).signInAsGuest(role: role);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
