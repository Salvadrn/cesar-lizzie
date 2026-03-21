import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/routine_provider.dart';
import '../../../data/models/routine.dart';

class RoutinePlayerScreen extends ConsumerStatefulWidget {
  final String routineId;

  const RoutinePlayerScreen({super.key, required this.routineId});

  @override
  ConsumerState<RoutinePlayerScreen> createState() =>
      _RoutinePlayerScreenState();
}

class _RoutinePlayerScreenState extends ConsumerState<RoutinePlayerScreen>
    with TickerProviderStateMixin {
  late final AnimationController _stallPulseController;
  late final AnimationController _completionController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _stallPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _completionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Load routine after the first frame so ref is accessible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRoutine();
    });
  }

  Future<void> _loadRoutine() async {
    try {
      await ref
          .read(routinePlayerProvider.notifier)
          .loadRoutine(widget.routineId);
    } catch (_) {
      // Error is handled via state
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _stallPulseController.dispose();
    _completionController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final state = ref.read(routinePlayerProvider);
    if (state.isCompleted || state.routine == null) return true;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abandonar rutina'),
        content: const Text(
          'Si sales ahora se perdera el progreso de esta sesion. '
          'Estas seguro que deseas abandonar la rutina?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Abandonar'),
          ),
        ],
      ),
    );

    if (shouldLeave == true) {
      ref.read(routinePlayerProvider.notifier).abandon();
    }

    return shouldLeave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(routinePlayerProvider);
    final theme = Theme.of(context);

    // Manage stall pulse animation
    if (playerState.stallPhase == StallPhase.visual) {
      if (!_stallPulseController.isAnimating) {
        _stallPulseController.repeat(reverse: true);
      }
    } else {
      if (_stallPulseController.isAnimating) {
        _stallPulseController.stop();
        _stallPulseController.reset();
      }
    }

    // Trigger completion animation
    if (playerState.isCompleted && !_completionController.isAnimating) {
      _completionController.forward();
    }

    // Loading state
    if (_isLoading || playerState.routine == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Completed state
    if (playerState.isCompleted) {
      return PopScope(
        canPop: true,
        child: _CompletionView(
          state: playerState,
          animationController: _completionController,
          onDone: () => context.pop(),
        ),
      );
    }

    // Active player state
    final step = playerState.currentStep;
    if (step == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Error: paso no encontrado')),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            context.pop();
          }
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              // Main content
              Column(
                children: [
                  // Top bar with close, pause, progress
                  _PlayerTopBar(
                    state: playerState,
                    onClose: () async {
                      final shouldPop = await _onWillPop();
                      if (shouldPop && mounted) {
                        context.pop();
                      }
                    },
                    onPauseResume: () {
                      final notifier =
                          ref.read(routinePlayerProvider.notifier);
                      if (playerState.isPaused) {
                        notifier.resume();
                      } else {
                        notifier.pause();
                      }
                    },
                  ),

                  // Progress bar
                  _StepProgressBar(state: playerState),

                  // Step content
                  Expanded(
                    child: _StepContent(
                      step: step,
                      stepIndex: playerState.currentStepIndex,
                      totalSteps: playerState.steps.length,
                    ),
                  ),

                  // Action buttons
                  _PlayerActions(
                    isPaused: playerState.isPaused,
                    onComplete: () {
                      ref
                          .read(routinePlayerProvider.notifier)
                          .completeCurrentStep();
                    },
                    onError: () {
                      ref.read(routinePlayerProvider.notifier).markError();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Error registrado'),
                          backgroundColor: theme.colorScheme.error,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Stall detection overlays
              if (playerState.stallPhase != StallPhase.none)
                _StallOverlay(
                  phase: playerState.stallPhase,
                  pulseController: _stallPulseController,
                ),

              // Pause overlay
              if (playerState.isPaused) const _PauseOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Player Top Bar
// ---------------------------------------------------------------------------

class _PlayerTopBar extends StatelessWidget {
  final RoutinePlayerState state;
  final VoidCallback onClose;
  final VoidCallback onPauseResume;

  const _PlayerTopBar({
    required this.state,
    required this.onClose,
    required this.onPauseResume,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Cerrar',
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              state.routine?.title ?? '',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onPauseResume,
            icon: Icon(
              state.isPaused
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
            ),
            tooltip: state.isPaused ? 'Reanudar' : 'Pausar',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step Progress Bar
// ---------------------------------------------------------------------------

class _StepProgressBar extends StatelessWidget {
  final RoutinePlayerState state;

  const _StepProgressBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = state.steps.length;
    final current = state.currentStepIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Step dots
          Row(
            children: List.generate(total, (index) {
              final isCompleted = index < current;
              final isCurrent = index == current;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < total - 1 ? 4 : 0,
                  ),
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: isCompleted
                        ? theme.colorScheme.primary
                        : isCurrent
                            ? theme.colorScheme.primary.withValues(alpha: 0.5)
                            : theme.colorScheme.primary.withValues(alpha: 0.12),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          // Step counter text
          Text(
            'Paso ${current + 1} de $total',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step Content
// ---------------------------------------------------------------------------

class _StepContent extends StatelessWidget {
  final StepRow step;
  final int stepIndex;
  final int totalSteps;

  const _StepContent({
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),

          // Step number badge
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${stepIndex + 1}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Step title
          Text(
            step.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Step instruction
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              step.instruction,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.5,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Optional image placeholder
          if (step.imageUrl != null && step.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: 200,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Image.network(
                  step.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 40,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Imagen no disponible',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Duration hint
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                _formatDuration(step.durationHint),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),

          // Checkpoint indicator
          if (step.checkpoint) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag_rounded, size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Punto de control',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds seg';
    final minutes = (seconds / 60).ceil();
    return '$minutes min aprox.';
  }
}

// ---------------------------------------------------------------------------
// Player Actions
// ---------------------------------------------------------------------------

class _PlayerActions extends StatelessWidget {
  final bool isPaused;
  final VoidCallback onComplete;
  final VoidCallback onError;

  const _PlayerActions({
    required this.isPaused,
    required this.onComplete,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Error button
          Expanded(
            flex: 1,
            child: OutlinedButton.icon(
              onPressed: isPaused ? null : onError,
              icon: const Icon(Icons.error_outline_rounded),
              label: const Text('Error'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Complete button
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: isPaused ? null : onComplete,
              icon: const Icon(Icons.check_rounded, size: 24),
              label: const Text(
                'Completado',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stall Detection Overlay
// ---------------------------------------------------------------------------

class _StallOverlay extends StatelessWidget {
  final StallPhase phase;
  final AnimationController pulseController;

  const _StallOverlay({
    required this.phase,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (phase) {
      case StallPhase.none:
        return const SizedBox.shrink();

      case StallPhase.visual:
        return Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              final opacity = 0.7 + (pulseController.value * 0.3);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade600.withValues(alpha: opacity),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.help_outline_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Necesitas ayuda?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );

      case StallPhase.audio:
        return Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: Colors.blue.shade600,
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.volume_up_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Escuchando instruccion...',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      case StallPhase.haptic:
        return Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: Colors.orange.shade700,
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.vibration_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Vibracion de alerta',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      case StallPhase.needHelp:
        return Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.7),
            child: Center(
              child: Card(
                margin: const EdgeInsets.all(32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.sos_rounded,
                          size: 40,
                          color: Colors.red.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Se ha notificado a tu cuidador',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tu cuidador ha sido avisado para ayudarte. '
                        'Puedes esperar o intentar continuar.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () {
                          // The overlay disappears when the user interacts
                          // (completes step or resumes), no direct dismiss needed
                        },
                        child: const Text('Entendido'),
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
}

// ---------------------------------------------------------------------------
// Pause Overlay
// ---------------------------------------------------------------------------

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pause_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Rutina en pausa',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pulsa el boton de reanudar para continuar',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Completion View
// ---------------------------------------------------------------------------

class _CompletionView extends StatelessWidget {
  final RoutinePlayerState state;
  final AnimationController animationController;
  final VoidCallback onDone;

  const _CompletionView({
    required this.state,
    required this.animationController,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Confetti-like celebration particles
            _CelebrationParticles(controller: animationController),

            // Main content
            Center(
              child: AnimatedBuilder(
                animation: animationController,
                builder: (context, child) {
                  final scale = Curves.elasticOut
                      .transform(animationController.value.clamp(0.0, 1.0));

                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Success icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.2),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 56,
                          color: Colors.green.shade600,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Title
                      Text(
                        'Rutina Completada!',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.routine?.title ?? '',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Stats card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text(
                                'Resumen',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _StatItem(
                                    icon: Icons.check_circle_outline_rounded,
                                    label: 'Pasos',
                                    value: '${state.steps.length}',
                                    color: Colors.green,
                                  ),
                                  _StatItem(
                                    icon: Icons.error_outline_rounded,
                                    label: 'Errores',
                                    value: '${state.totalErrors}',
                                    color: state.totalErrors > 0
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                  _StatItem(
                                    icon: Icons.timer_outlined,
                                    label: 'Alertas',
                                    value: '${state.totalStalls}',
                                    color: state.totalStalls > 0
                                        ? Colors.amber
                                        : Colors.green,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Done button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: onDone,
                          icon: const Icon(Icons.home_rounded),
                          label: const Text(
                            'Volver al inicio',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat Item (for completion summary)
// ---------------------------------------------------------------------------

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Celebration Particles (confetti-like effect)
// ---------------------------------------------------------------------------

class _CelebrationParticles extends StatelessWidget {
  final AnimationController controller;

  const _CelebrationParticles({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.value < 0.1) return const SizedBox.shrink();

        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _ConfettiPainter(
            progress: controller.value,
          ),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  static final _random = Random(42); // Fixed seed for consistent pattern
  static final List<_Particle> _particles = _generateParticles();

  _ConfettiPainter({required this.progress});

  static List<_Particle> _generateParticles() {
    const colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.amber,
    ];

    return List.generate(40, (i) {
      return _Particle(
        x: _random.nextDouble(),
        startY: -0.1 - _random.nextDouble() * 0.3,
        speed: 0.3 + _random.nextDouble() * 0.7,
        size: 4 + _random.nextDouble() * 8,
        color: colors[_random.nextInt(colors.length)],
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 4,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in _particles) {
      final y = particle.startY + progress * particle.speed * 1.5;
      if (y < -0.1 || y > 1.1) continue;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: (1 - progress).clamp(0.0, 1.0) * 0.8)
        ..style = PaintingStyle.fill;

      final px = particle.x * size.width;
      final py = y * size.height;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(particle.rotation + progress * particle.rotationSpeed);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          Radius.circular(particle.size * 0.15),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _Particle {
  final double x;
  final double startY;
  final double speed;
  final double size;
  final Color color;
  final double rotation;
  final double rotationSpeed;

  const _Particle({
    required this.x,
    required this.startY,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });
}
