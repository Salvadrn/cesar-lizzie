import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Haptic feedback helper providing distinct feedback patterns for different
/// interaction contexts.
///
/// Ported from the Swift `HapticsService`.  Uses [HapticFeedback] for simple
/// taps and the `vibration` package for custom multi-pulse patterns.
class HapticsService {
  HapticsService._();

  // ---------------------------------------------------------------------------
  // Simple taps (system haptics)
  // ---------------------------------------------------------------------------

  /// A light tap -- suitable for selection changes or minor interactions.
  static Future<void> lightTap() async {
    await HapticFeedback.lightImpact();
  }

  /// A medium tap -- suitable for confirming an action.
  static Future<void> mediumTap() async {
    await HapticFeedback.mediumImpact();
  }

  /// A heavy tap -- suitable for destructive or significant actions.
  static Future<void> heavyTap() async {
    await HapticFeedback.heavyImpact();
  }

  // ---------------------------------------------------------------------------
  // Semantic patterns (vibration)
  // ---------------------------------------------------------------------------

  /// Success pattern: single short vibration.
  static Future<void> success() async {
    final hasVibrator = (await Vibration.hasVibrator()) == true;
    if (!hasVibrator) return;
    await Vibration.vibrate(duration: 100);
  }

  /// Warning pattern: two short pulses.
  static Future<void> warning() async {
    final hasVibrator = (await Vibration.hasVibrator()) == true;
    if (!hasVibrator) return;
    await Vibration.vibrate(pattern: [0, 150, 100, 150]);
  }

  /// Error pattern: three rapid pulses.
  static Future<void> error() async {
    final hasVibrator = (await Vibration.hasVibrator()) == true;
    if (!hasVibrator) return;
    await Vibration.vibrate(pattern: [0, 200, 100, 200, 100, 200]);
  }

  /// Stall re-prompt pattern: three escalating pulses to nudge the user back
  /// on task.
  ///
  /// Pattern: pause 0 ms, vibrate 100 ms, pause 100 ms, vibrate 150 ms,
  /// pause 100 ms, vibrate 200 ms.
  static Future<void> stallRePrompt() async {
    final hasVibrator = (await Vibration.hasVibrator()) == true;
    if (!hasVibrator) return;
    await Vibration.vibrate(pattern: [0, 100, 100, 150, 100, 200]);
  }

  /// Emergency pulse: five rapid short vibrations to demand immediate
  /// attention (e.g. fall detection countdown).
  ///
  /// Pattern: 5 x (50 ms vibrate + 50 ms pause).
  static Future<void> emergencyPulse() async {
    final hasVibrator = (await Vibration.hasVibrator()) == true;
    if (!hasVibrator) return;
    await Vibration.vibrate(
      pattern: [0, 50, 50, 50, 50, 50, 50, 50, 50, 50],
    );
  }
}
