import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/api_client.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);

    try {
      await ApiClient.updateProfile(
        ProfileUpdate(displayName: _nameController.text.trim()),
      );
      await ref.read(authStateProvider.notifier).refreshProfile();

      if (mounted) {
        final isSimple = ref.read(authStateProvider).isSimpleModeActive;
        context.go(isSimple ? '/simple' : '/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _goToNextStep() {
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;
    }

    if (_currentStep < 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // -- Step indicator --
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: List.generate(2, (index) {
                  final isActive = index <= _currentStep;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? colorScheme.primary
                            : colorScheme.outline.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 16),

            // -- Pages --
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildNameStep(theme, colorScheme),
                  _buildWelcomeStep(theme, colorScheme),
                ],
              ),
            ),

            // -- Bottom button --
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _goToNextStep,
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _currentStep == 1 ? 'Comenzar' : 'Siguiente',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
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

  Widget _buildNameStep(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.waving_hand_rounded,
              size: 64,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Como te llamas?',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Usaremos tu nombre para personalizar tu experiencia.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Tu nombre',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa tu nombre';
                }
                return null;
              },
              onFieldSubmitted: (_) => _goToNextStep(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeStep(ThemeData theme, ColorScheme colorScheme) {
    final name = _nameController.text.trim();
    final greeting = name.isNotEmpty ? 'Hola, $name!' : 'Hola!';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.psychology_rounded,
              size: 48,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            greeting,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Bienvenido a NeuroNav',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildFeatureItem(
            icon: Icons.checklist_rounded,
            title: 'Rutinas paso a paso',
            subtitle: 'Te guiamos en tus actividades diarias con instrucciones claras.',
            colorScheme: colorScheme,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            icon: Icons.medication_rounded,
            title: 'Recordatorios de medicamentos',
            subtitle: 'Nunca olvides tomar tus medicinas a tiempo.',
            colorScheme: colorScheme,
            theme: theme,
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            icon: Icons.sos_rounded,
            title: 'Asistencia de emergencia',
            subtitle: 'Acceso rapido a ayuda cuando la necesites.',
            colorScheme: colorScheme,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
