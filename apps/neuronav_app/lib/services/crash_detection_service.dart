import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Monitors accelerometer data and triggers an emergency callback when a
/// sudden high-g impact is detected (potential fall or crash).
///
/// Ported from the Swift `CrashDetectionService`.  Uses the `sensors_plus`
/// package for raw accelerometer events.  After detecting an impact exceeding
/// [_impactThresholdG] g, a 30-second countdown begins.  If the user does not
/// cancel, the emergency callback fires.
class CrashDetectionService extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// The g-force threshold above which an impact is considered a potential
  /// crash.  Earth gravity (9.81 m/s^2) is ~1 g, so 3.5 g is a significant
  /// impact.
  static const double _impactThresholdG = 3.5;

  /// Length of the countdown (seconds) before the emergency callback fires.
  static const int _countdownDuration = 30;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  StreamSubscription<AccelerometerEvent>? _accelerometerSub;
  Timer? _countdownTimer;
  VoidCallback? _onEmergency;

  bool _showingCountdown = false;
  int _countdownSeconds = _countdownDuration;

  /// `true` while the countdown overlay should be visible.
  bool get showingCountdown => _showingCountdown;

  /// Remaining seconds in the countdown.  UI should display this value.
  int get countdownSeconds => _countdownSeconds;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Starts listening to the accelerometer.
  ///
  /// [onEmergency] is invoked if the countdown reaches zero without the user
  /// calling [cancelCountdown].
  void startMonitoring(VoidCallback onEmergency) {
    _onEmergency = onEmergency;

    _accelerometerSub?.cancel();
    _accelerometerSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen(_handleAccelerometerEvent);
  }

  /// Stops monitoring and cancels any in-progress countdown.
  void stopMonitoring() {
    _accelerometerSub?.cancel();
    _accelerometerSub = null;
    _cancelTimer();
  }

  // ---------------------------------------------------------------------------
  // Accelerometer handler
  // ---------------------------------------------------------------------------

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    if (_showingCountdown) return; // Already counting down; ignore new events.

    // Compute the magnitude in g (1 g ~ 9.81 m/s^2).
    final magnitude =
        sqrt(event.x * event.x + event.y * event.y + event.z * event.z) /
            9.81;

    if (magnitude > _impactThresholdG) {
      debugPrint(
        '[CrashDetection] Impact detected: ${magnitude.toStringAsFixed(2)} g',
      );
      _startCountdown();
    }
  }

  // ---------------------------------------------------------------------------
  // Countdown
  // ---------------------------------------------------------------------------

  void _startCountdown() {
    _showingCountdown = true;
    _countdownSeconds = _countdownDuration;
    notifyListeners();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownSeconds--;
      notifyListeners();

      if (_countdownSeconds <= 0) {
        timer.cancel();
        _showingCountdown = false;
        notifyListeners();
        _onEmergency?.call();
      }
    });
  }

  /// Called by the UI when the user indicates they are fine.
  void cancelCountdown() {
    _cancelTimer();
    _showingCountdown = false;
    _countdownSeconds = _countdownDuration;
    notifyListeners();
  }

  void _cancelTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
