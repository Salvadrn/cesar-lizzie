/// Application theme configuration for NeuroNav.
///
/// Provides a Material 3 [ThemeData] and a helper to derive a theme from
/// any [SensoryModeConfig] so the UI can dynamically adapt to different
/// sensory profiles.
library;

import 'package:flutter/material.dart';
import '../constants/sensory_modes.dart';

class AppTheme {
  AppTheme._(); // non-instantiable

  // -----------------------------------------------------------------------
  // Brand colours (from default SensoryModeConfig)
  // -----------------------------------------------------------------------

  // ignore: unused_field — kept as brand reference
  static const Color _primaryBlue = Color(0xFF4078D9);
  // ignore: unused_field
  static const Color _accentGreen = Color(0xFF34C759);
  // ignore: unused_field
  static const Color _backgroundLight = Color(0xFFF5F5F7);
  // ignore: unused_field
  static const Color _textDark = Color(0xFF1C1C1E);

  // -----------------------------------------------------------------------
  // Light theme
  // -----------------------------------------------------------------------

  static final ThemeData light = _buildTheme(SensoryModes.defaultMode);

  // -----------------------------------------------------------------------
  // Theme from SensoryModeConfig
  // -----------------------------------------------------------------------

  /// Build a full [ThemeData] from the given [config].
  ///
  /// This lets the app switch visual modes at runtime while keeping
  /// consistent Material 3 styling.
  static ThemeData fromSensoryMode(SensoryModeConfig config) {
    return _buildTheme(config);
  }

  // -----------------------------------------------------------------------
  // Private builder
  // -----------------------------------------------------------------------

  static ThemeData _buildTheme(SensoryModeConfig config) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: config.primaryColor,
      brightness: _brightnessFor(config),
      primary: config.primaryColor,
      secondary: config.accentColor,
      surface: config.backgroundColor,
      onSurface: config.textColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // Scaffold
      scaffoldBackgroundColor: config.backgroundColor,

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        backgroundColor: config.backgroundColor,
        foregroundColor: config.textColor,
        titleTextStyle: TextStyle(
          color: config.textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(config.borderRadius),
        ),
        color: colorScheme.surfaceContainerLowest,
        margin: EdgeInsets.symmetric(
          horizontal: config.spacing,
          vertical: config.spacing / 2,
        ),
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: config.primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: config.spacing * 1.5,
            vertical: config.spacing,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(config.borderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: config.primaryColor,
          side: BorderSide(color: config.primaryColor),
          padding: EdgeInsets.symmetric(
            horizontal: config.spacing * 1.5,
            vertical: config.spacing,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(config.borderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: config.primaryColor,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Floating action button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: config.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(config.borderRadius),
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        contentPadding: EdgeInsets.all(config.spacing),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.borderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.borderRadius),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.borderRadius),
          borderSide: BorderSide(color: config.primaryColor, width: 2),
        ),
      ),

      // Bottom navigation bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: config.backgroundColor,
        selectedItemColor: config.primaryColor,
        unselectedItemColor: config.textColor.withValues(alpha: 0.5),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Navigation bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: config.backgroundColor,
        indicatorColor: config.primaryColor.withValues(alpha: 0.15),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: config.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(
            color: config.textColor.withValues(alpha: 0.6),
            fontSize: 12,
          );
        }),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: config.textColor.withValues(alpha: 0.1),
        thickness: 1,
        space: config.spacing,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(config.borderRadius * 1.5),
        ),
        backgroundColor: config.backgroundColor,
      ),

      // Bottom sheet
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(config.borderRadius * 1.5),
          ),
        ),
        backgroundColor: config.backgroundColor,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(config.borderRadius / 2),
        ),
      ),

      // Typography
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: config.textColor,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: config.textColor,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: config.textColor,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: config.textColor,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: config.textColor,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: config.textColor,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: config.textColor,
        ),
        bodyMedium: TextStyle(
          color: config.textColor,
        ),
        bodySmall: TextStyle(
          color: config.textColor.withValues(alpha: 0.7),
        ),
        labelLarge: TextStyle(
          color: config.textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Determine brightness from the background colour luminance.
  static Brightness _brightnessFor(SensoryModeConfig config) {
    return config.backgroundColor.computeLuminance() > 0.5
        ? Brightness.light
        : Brightness.dark;
  }
}
