import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSignUpMode = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final emailValid = email.contains('@') && email.contains('.');
    final passwordValid = password.length >= 6;
    if (_isSignUpMode) {
      return emailValid && passwordValid && password == _confirmController.text;
    }
    return emailValid && passwordValid;
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (!_isFormValid) {
      if (_isSignUpMode && password != _confirmController.text) {
        _showError('Las contraseñas no coinciden');
      } else {
        _showError('Revisa tu correo y contraseña (mínimo 6 caracteres)');
      }
      return;
    }

    if (_isSignUpMode) {
      await ref.read(authStateProvider.notifier).signUpWithEmail(email, password);
    } else {
      await ref.read(authStateProvider.notifier).signInWithEmail(email, password);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildHeader(colorScheme),
                  const SizedBox(height: 40),
                  _buildEmailForm(theme, colorScheme),
                  const SizedBox(height: 32),
                  _buildDivider(colorScheme),
                  const SizedBox(height: 32),

                  // Guest section
                  Text(
                    'Continuar como Invitado',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explora la aplicación sin crear una cuenta',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  _buildRoleCard(
                    context: context,
                    ref: ref,
                    icon: Icons.person_rounded,
                    title: 'Paciente',
                    description: 'Persona que utilizará las rutinas y herramientas de asistencia diaria.',
                    role: UserRole.patient,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  _buildRoleCard(
                    context: context,
                    ref: ref,
                    icon: Icons.health_and_safety_rounded,
                    title: 'Cuidador',
                    description: 'Profesional o familiar que supervisa y apoya al paciente.',
                    role: UserRole.caregiver,
                    color: const Color(0xFF34C759),
                  ),
                  const SizedBox(height: 12),
                  _buildRoleCard(
                    context: context,
                    ref: ref,
                    icon: Icons.family_restroom_rounded,
                    title: 'Familiar',
                    description: 'Miembro de la familia que desea monitorear el progreso.',
                    role: UserRole.family,
                    color: const Color(0xFFFF9500),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),

            // Error message
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            authState.errorMessage!,
                            style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Loading overlay
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
                          Text('Iniciando sesión...'),
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
          child: Icon(Icons.psychology_rounded, size: 44, color: colorScheme.primary),
        ),
        const SizedBox(height: 20),
        Text(
          'AdaptAi',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        ),
        const SizedBox(height: 8),
        Text(
          'Asistente de Vida Diaria Adaptativo',
          style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.6)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailForm(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Correo electrónico',
            hintText: 'tu@correo.com',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),

        // Password
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: _isSignUpMode ? TextInputAction.next : TextInputAction.done,
          onSubmitted: _isSignUpMode ? null : (_) => _submit(),
          decoration: InputDecoration(
            labelText: 'Contraseña',
            hintText: 'Mínimo 6 caracteres',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onChanged: (_) => setState(() {}),
        ),

        // Confirm password (sign up)
        if (_isSignUpMode) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Confirmar contraseña',
              hintText: 'Repite tu contraseña',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],

        const SizedBox(height: 24),

        // Submit button
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isFormValid ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(
              _isSignUpMode ? 'Crear cuenta' : 'Iniciar sesión',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Toggle mode
        TextButton(
          onPressed: () {
            setState(() {
              _isSignUpMode = !_isSignUpMode;
              _confirmController.clear();
            });
          },
          child: Text(
            _isSignUpMode ? '¿Ya tienes cuenta? Inicia sesión' : '¿No tienes cuenta? Regístrate',
            style: TextStyle(color: colorScheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(child: Divider(color: colorScheme.outline.withValues(alpha: 0.3))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('o', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 15)),
        ),
        Expanded(child: Divider(color: colorScheme.outline.withValues(alpha: 0.3))),
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
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => ref.read(authStateProvider.notifier).signInAsGuest(role: role),
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
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(description, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
