import 'dart:math';

/// Pure-math adaptive complexity engine.
///
/// Ported from the Swift `AdaptiveEngine`.  No external dependencies -- just
/// heuristic scoring that maps user performance metrics to a complexity level
/// from 1 (simplest) to 5 (most complex).
class AdaptiveEngine {
  AdaptiveEngine._();

  /// Computes a raw complexity score from live session metrics.
  ///
  /// Parameters
  /// ----------
  /// * [errorRate]           – fraction of steps with errors (0..1).
  /// * [avgResponseTime]     – average seconds per step.
  /// * [taskCompletionRate]  – fraction of steps completed (0..1).
  /// * [stallRate]           – fraction of steps where user stalled (0..1).
  /// * [tapAccuracy]         – fraction of taps on the correct target (0..1).
  ///
  /// Returns an integer in the range 1..5.
  static int computeRawScore({
    required double errorRate,
    required double avgResponseTime,
    required double taskCompletionRate,
    required double stallRate,
    required double tapAccuracy,
  }) {
    double score = 3.0;

    // --- Error rate ---
    if (errorRate < 0.1) {
      score += 0.5;
    } else if (errorRate > 0.3) {
      score -= 0.5;
    }

    // --- Average response time (seconds per step) ---
    if (avgResponseTime < 15.0) {
      score += 0.5;
    } else if (avgResponseTime > 45.0) {
      score -= 0.5;
    }

    // --- Task completion rate ---
    if (taskCompletionRate > 0.9) {
      score += 0.3;
    } else if (taskCompletionRate < 0.5) {
      score -= 0.3;
    }

    // --- Stall rate ---
    if (stallRate > 0.2) {
      score -= 0.5;
    }

    // --- Tap accuracy ---
    if (tapAccuracy < 0.7) {
      score -= 0.3;
    }

    // Clamp to 1..5 and round.
    return score.clamp(1.0, 5.0).round();
  }

  /// Smooths the transition between the [current] level and the newly
  /// [computed] level using an exponential moving average (EMA), ensuring
  /// at most +-1 level change per session and clamping to the profile's
  /// [floor]..[ceiling] range.
  ///
  /// * EMA weight: 70 % current, 30 % computed.
  /// * Maximum delta per call: 1 level.
  static int smoothLevel({
    required int current,
    required int computed,
    required int floor,
    required int ceiling,
  }) {
    // EMA blend.
    final blended = (0.7 * current + 0.3 * computed).round();

    // Limit to +-1 delta from current.
    final delta = (blended - current).clamp(-1, 1);
    final next = current + delta;

    // Clamp to profile boundaries.
    return min(ceiling, max(floor, next));
  }
}
