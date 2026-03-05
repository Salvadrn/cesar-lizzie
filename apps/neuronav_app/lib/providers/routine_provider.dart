import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/routine.dart';
import '../data/sample_data.dart';
import '../services/api_client.dart';
import '../services/speech_service.dart';
import '../services/haptics_service.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

// --- Routines list ---

final routinesProvider = FutureProvider<List<RoutineRow>>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (authState.isGuestMode) return SampleData.sampleRoutines;
  if (!authState.isAuthenticated) return [];
  return await ApiClient.fetchRoutines();
});

// --- Routine Player ---

enum StallPhase { none, visual, audio, haptic, needHelp }

class RoutinePlayerState {
  final RoutineRow? routine;
  final List<StepRow> steps;
  final int currentStepIndex;
  final String? executionId;
  final bool isCompleted;
  final bool isPaused;
  final StallPhase stallPhase;
  final int stallTimerSeconds;
  final int totalErrors;
  final int totalStalls;
  final int stepErrorCount;
  final int stepStallCount;
  final int stepRePromptCount;

  const RoutinePlayerState({
    this.routine,
    this.steps = const [],
    this.currentStepIndex = 0,
    this.executionId,
    this.isCompleted = false,
    this.isPaused = false,
    this.stallPhase = StallPhase.none,
    this.stallTimerSeconds = 0,
    this.totalErrors = 0,
    this.totalStalls = 0,
    this.stepErrorCount = 0,
    this.stepStallCount = 0,
    this.stepRePromptCount = 0,
  });

  StepRow? get currentStep =>
      currentStepIndex < steps.length ? steps[currentStepIndex] : null;

  double get progress =>
      steps.isNotEmpty ? currentStepIndex / steps.length : 0.0;

  RoutinePlayerState copyWith({
    RoutineRow? routine,
    List<StepRow>? steps,
    int? currentStepIndex,
    String? executionId,
    bool? isCompleted,
    bool? isPaused,
    StallPhase? stallPhase,
    int? stallTimerSeconds,
    int? totalErrors,
    int? totalStalls,
    int? stepErrorCount,
    int? stepStallCount,
    int? stepRePromptCount,
  }) {
    return RoutinePlayerState(
      routine: routine ?? this.routine,
      steps: steps ?? this.steps,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      executionId: executionId ?? this.executionId,
      isCompleted: isCompleted ?? this.isCompleted,
      isPaused: isPaused ?? this.isPaused,
      stallPhase: stallPhase ?? this.stallPhase,
      stallTimerSeconds: stallTimerSeconds ?? this.stallTimerSeconds,
      totalErrors: totalErrors ?? this.totalErrors,
      totalStalls: totalStalls ?? this.totalStalls,
      stepErrorCount: stepErrorCount ?? this.stepErrorCount,
      stepStallCount: stepStallCount ?? this.stepStallCount,
      stepRePromptCount: stepRePromptCount ?? this.stepRePromptCount,
    );
  }
}

class RoutinePlayerNotifier extends StateNotifier<RoutinePlayerState> {
  final Ref _ref;
  Timer? _stallTimer;
  DateTime? _stepStartTime;
  final SpeechService _speech = SpeechService();

  RoutinePlayerNotifier(this._ref) : super(const RoutinePlayerState());

  Future<void> loadRoutine(String routineId) async {
    final authState = _ref.read(authStateProvider);

    RoutineRow routine;
    if (authState.isGuestMode) {
      routine = SampleData.sampleRoutines.firstWhere((r) => r.id == routineId);
    } else {
      routine = await ApiClient.fetchRoutine(routineId);
    }

    final steps = List<StepRow>.from(routine.routineSteps ?? [])
      ..sort((a, b) => a.stepOrder.compareTo(b.stepOrder));

    String? execId;
    if (!authState.isGuestMode) {
      final exec = await ApiClient.startExecution(routineId);
      execId = exec.id;
    }

    state = state.copyWith(
      routine: routine,
      steps: steps,
      currentStepIndex: 0,
      executionId: execId,
      isCompleted: false,
      isPaused: false,
    );

    _startStep();
  }

  void _startStep() {
    _stepStartTime = DateTime.now();
    state = state.copyWith(
      stallPhase: StallPhase.none,
      stallTimerSeconds: 0,
      stepErrorCount: 0,
      stepStallCount: 0,
      stepRePromptCount: 0,
    );
    _startStallTimer();
  }

  void _startStallTimer() {
    _stallTimer?.cancel();
    _stallTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isPaused || state.isCompleted) return;

      final seconds = state.stallTimerSeconds + 1;
      final hint = state.currentStep?.durationHint ?? 60;
      final threshold = (hint * 1.5).toInt();

      StallPhase newPhase = state.stallPhase;

      if (seconds >= threshold + 30 && newPhase != StallPhase.needHelp) {
        newPhase = StallPhase.needHelp;
        _triggerStallPhase(newPhase);
      } else if (seconds >= threshold + 20 && newPhase == StallPhase.audio) {
        newPhase = StallPhase.haptic;
        _triggerStallPhase(newPhase);
      } else if (seconds >= threshold + 10 && newPhase == StallPhase.visual) {
        newPhase = StallPhase.audio;
        _triggerStallPhase(newPhase);
      } else if (seconds >= threshold && newPhase == StallPhase.none) {
        newPhase = StallPhase.visual;
        _triggerStallPhase(newPhase);
      }

      state = state.copyWith(stallTimerSeconds: seconds, stallPhase: newPhase);
    });
  }

  void _triggerStallPhase(StallPhase phase) {
    final step = state.currentStep;
    if (step == null) return;

    state = state.copyWith(
      stepStallCount: state.stepStallCount + 1,
      totalStalls: state.totalStalls + 1,
    );

    switch (phase) {
      case StallPhase.visual:
        // Banner shown by UI
        break;
      case StallPhase.audio:
        _speech.speak(step.instruction);
        state = state.copyWith(stepRePromptCount: state.stepRePromptCount + 1);
        break;
      case StallPhase.haptic:
        HapticsService.stallRePrompt();
        break;
      case StallPhase.needHelp:
        NotificationService.sendStallAlert();
        break;
      case StallPhase.none:
        break;
    }
  }

  Future<void> completeCurrentStep() async {
    if (state.isCompleted) return;

    final duration = _stepStartTime != null
        ? DateTime.now().difference(_stepStartTime!).inSeconds
        : 0;

    // Report to server
    if (state.executionId != null && state.currentStep != null) {
      try {
        await ApiClient.completeStep(
          executionId: state.executionId!,
          stepId: state.currentStep!.id,
          durationSeconds: duration,
          errorCount: state.stepErrorCount,
          stallCount: state.stepStallCount,
          rePromptCount: state.stepRePromptCount,
        );
      } catch (_) {}
    }

    HapticsService.success();

    final nextIndex = state.currentStepIndex + 1;
    if (nextIndex >= state.steps.length) {
      // Routine complete
      _stallTimer?.cancel();
      if (state.executionId != null) {
        try {
          await ApiClient.completeExecution(state.executionId!);
        } catch (_) {}
      }
      state = state.copyWith(isCompleted: true);
    } else {
      state = state.copyWith(currentStepIndex: nextIndex);
      _startStep();
    }
  }

  void markError() {
    HapticsService.error();
    state = state.copyWith(
      stepErrorCount: state.stepErrorCount + 1,
      totalErrors: state.totalErrors + 1,
    );
  }

  void pause() {
    _stallTimer?.cancel();
    state = state.copyWith(isPaused: true);
  }

  void resume() {
    state = state.copyWith(isPaused: false);
    _startStallTimer();
  }

  void abandon() {
    _stallTimer?.cancel();
    _speech.stop();
    state = const RoutinePlayerState();
  }

  @override
  void dispose() {
    _stallTimer?.cancel();
    _speech.dispose();
    super.dispose();
  }
}

final routinePlayerProvider =
    StateNotifierProvider.autoDispose<RoutinePlayerNotifier, RoutinePlayerState>(
  (ref) => RoutinePlayerNotifier(ref),
);
