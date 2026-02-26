/// Complexity level definitions for the adaptive engine.
///
/// Ported from Swift ComplexityLevels. Each level (1-5) adjusts the UI
/// density, audio behaviour, confirmation requirements, and animation
/// settings to match the cognitive needs of the user.
library;

// ---------------------------------------------------------------------------
// AudioMode
// ---------------------------------------------------------------------------

enum AudioMode {
  /// Audio plays automatically when a step is presented.
  autoPlay,

  /// Audio plays only when the user taps the speaker button.
  onTap,

  /// Audio is available but not highlighted in the UI.
  optional,

  /// Audio controls are completely hidden.
  hidden;
}

// ---------------------------------------------------------------------------
// ConfirmationLevel
// ---------------------------------------------------------------------------

enum ConfirmationLevel {
  /// No confirmation required -- actions are immediate.
  none,

  /// A single tap to confirm (e.g. "Done" button).
  simple,

  /// A more explicit confirmation flow (e.g. "Are you sure?" dialog).
  detailed;
}

// ---------------------------------------------------------------------------
// ComplexityLevelConfig
// ---------------------------------------------------------------------------

class ComplexityLevelConfig {
  const ComplexityLevelConfig({
    required this.level,
    required this.name,
    required this.buttonSize,
    required this.itemsPerScreen,
    required this.showText,
    required this.audioMode,
    required this.confirmationLevel,
    required this.animationEnabled,
    required this.colorCoding,
  });

  /// Numeric level identifier (1 = simplest, 5 = most complex).
  final int level;

  /// Human-readable name in Spanish.
  final String name;

  /// Minimum tap-target size in logical pixels.
  final double buttonSize;

  /// Maximum number of visible items on screen at once.
  final int itemsPerScreen;

  /// Whether to display textual labels alongside icons.
  final bool showText;

  /// How audio cues are presented to the user.
  final AudioMode audioMode;

  /// How actions are confirmed before execution.
  final ConfirmationLevel confirmationLevel;

  /// Whether UI transition animations are enabled.
  final bool animationEnabled;

  /// Whether color-coded indicators are used for status.
  final bool colorCoding;
}

// ---------------------------------------------------------------------------
// ComplexityLevels registry
// ---------------------------------------------------------------------------

class ComplexityLevels {
  ComplexityLevels._(); // non-instantiable

  /// All available complexity level configurations keyed by level number.
  static final Map<int, ComplexityLevelConfig> all = {
    1: const ComplexityLevelConfig(
      level: 1,
      name: 'Muy simplificado',
      buttonSize: 88,
      itemsPerScreen: 1,
      showText: false,
      audioMode: AudioMode.autoPlay,
      confirmationLevel: ConfirmationLevel.none,
      animationEnabled: false,
      colorCoding: true,
    ),
    2: const ComplexityLevelConfig(
      level: 2,
      name: 'Simplificado',
      buttonSize: 72,
      itemsPerScreen: 2,
      showText: true,
      audioMode: AudioMode.autoPlay,
      confirmationLevel: ConfirmationLevel.simple,
      animationEnabled: true,
      colorCoding: true,
    ),
    3: const ComplexityLevelConfig(
      level: 3,
      name: 'Estandar',
      buttonSize: 56,
      itemsPerScreen: 3,
      showText: true,
      audioMode: AudioMode.onTap,
      confirmationLevel: ConfirmationLevel.simple,
      animationEnabled: true,
      colorCoding: true,
    ),
    4: const ComplexityLevelConfig(
      level: 4,
      name: 'Detallado',
      buttonSize: 48,
      itemsPerScreen: 5,
      showText: true,
      audioMode: AudioMode.optional,
      confirmationLevel: ConfirmationLevel.detailed,
      animationEnabled: true,
      colorCoding: false,
    ),
    5: const ComplexityLevelConfig(
      level: 5,
      name: 'Completo',
      buttonSize: 44,
      itemsPerScreen: 8,
      showText: true,
      audioMode: AudioMode.hidden,
      confirmationLevel: ConfirmationLevel.detailed,
      animationEnabled: true,
      colorCoding: false,
    ),
  };

  /// Returns the configuration for the given [level].
  ///
  /// Clamps to the nearest valid level (1-5) when the value is out of range.
  static ComplexityLevelConfig config(int level) {
    final clamped = level.clamp(1, 5);
    return all[clamped]!;
  }
}
