/// Sensory mode visual configurations for NeuroNav.
///
/// Ported from Swift SensoryModes. Each mode provides a coherent set of
/// colours, spacing, and feedback settings designed for different sensory
/// needs (e.g. low-stimulation environments or high-contrast requirements).
library;

import 'dart:ui';

// ---------------------------------------------------------------------------
// SensoryModeConfig
// ---------------------------------------------------------------------------

class SensoryModeConfig {
  const SensoryModeConfig({
    required this.name,
    required this.primaryColor,
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.animationEnabled,
    required this.hapticEnabled,
    required this.soundEnabled,
    required this.borderRadius,
    required this.spacing,
  });

  /// Human-readable mode name.
  final String name;

  /// Main brand / action colour.
  final Color primaryColor;

  /// Screen / card background colour.
  final Color backgroundColor;

  /// Primary text colour.
  final Color textColor;

  /// Secondary highlight / CTA colour.
  final Color accentColor;

  /// Whether transitions and micro-animations are enabled.
  final bool animationEnabled;

  /// Whether haptic feedback (vibration) is enabled.
  final bool hapticEnabled;

  /// Whether UI sound effects are enabled.
  final bool soundEnabled;

  /// Default corner radius for cards and buttons (logical pixels).
  final double borderRadius;

  /// Base spacing unit used for padding / gaps (logical pixels).
  final double spacing;
}

// ---------------------------------------------------------------------------
// SensoryModes
// ---------------------------------------------------------------------------

class SensoryModes {
  SensoryModes._(); // non-instantiable

  // -- Default mode -------------------------------------------------------

  static const SensoryModeConfig defaultMode = SensoryModeConfig(
    name: 'Default',
    primaryColor: Color(0xFF4078D9),   // Calm blue
    backgroundColor: Color(0xFFF5F5F7), // Light grey
    textColor: Color(0xFF1C1C1E),       // Near-black
    accentColor: Color(0xFF34C759),     // Green accent
    animationEnabled: true,
    hapticEnabled: true,
    soundEnabled: true,
    borderRadius: 16,
    spacing: 16,
  );

  // -- Low Stimulation mode ------------------------------------------------

  static const SensoryModeConfig lowStimulation = SensoryModeConfig(
    name: 'Baja estimulacion',
    primaryColor: Color(0xFF8E8E93),   // Muted grey
    backgroundColor: Color(0xFFF2F2F7), // Very soft grey
    textColor: Color(0xFF3A3A3C),       // Dark grey
    accentColor: Color(0xFFA2845E),     // Warm brown
    animationEnabled: false,
    hapticEnabled: false,
    soundEnabled: false,
    borderRadius: 8,
    spacing: 24,
  );

  // -- High Contrast mode --------------------------------------------------

  static const SensoryModeConfig highContrast = SensoryModeConfig(
    name: 'Alto contraste',
    primaryColor: Color(0xFF0A84FF),   // Bright blue
    backgroundColor: Color(0xFF000000), // Pure black
    textColor: Color(0xFFFFFFFF),       // Pure white
    accentColor: Color(0xFFFFD60A),     // Vivid yellow
    animationEnabled: true,
    hapticEnabled: true,
    soundEnabled: true,
    borderRadius: 12,
    spacing: 20,
  );

  /// Look up a sensory mode configuration by its key name.
  ///
  /// Accepted keys: `"default"`, `"lowStimulation"` / `"low_stimulation"`,
  /// `"highContrast"` / `"high_contrast"`. Falls back to [defaultMode].
  static SensoryModeConfig config(String mode) {
    switch (mode.toLowerCase()) {
      case 'default':
        return defaultMode;
      case 'lowstimulation':
      case 'low_stimulation':
        return lowStimulation;
      case 'highcontrast':
      case 'high_contrast':
        return highContrast;
      default:
        return defaultMode;
    }
  }
}
