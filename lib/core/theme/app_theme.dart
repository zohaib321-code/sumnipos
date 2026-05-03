import 'package:flutter/material.dart';

/// Kinetic POS Design System – flat, sharp-cornered, Inter font.
class AppTheme {
  // ─── Primary Palette ────────────────────────────────────────────────────────
  static const Color primary        = Color(0xFF0050CB);
  static const Color primaryDark    = Color(0xFF003FA4);
  static const Color primaryLight   = Color(0xFF0066FF);
  static const Color onPrimary      = Colors.white;

  static const Color secondary      = Color(0xFF006C49);
  static const Color error          = Color(0xFFBA1A1A);
  static const Color warning        = Color(0xFFCC4204);

  // ─── Surface Palette ────────────────────────────────────────────────────────
  static const Color background     = Color(0xFFF2F3FF); // light grey-blue
  static const Color surface        = Colors.white;
  static const Color surfaceVariant = Color(0xFFE1E2EE);
  static const Color outline        = Color(0xFFC2C6D8);
  static const Color outlineVariant = Color(0xFFE4E4E7);
  static const Color outlineDark    = Color(0xFF727687);

  // ─── Text ────────────────────────────────────────────────────────────────────
  static const Color onSurface      = Color(0xFF191B24);
  static const Color onSurfaceVar   = Color(0xFF424656);
  static const Color textMuted      = Color(0xFF727687);
  static const Color surfaceDim     = Color(0xFFD8D9E6);

  // ─── Typography ──────────────────────────────────────────────────────────────
  static const TextStyle numeralLg = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static const TextStyle labelXl = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
  );

  static const TextStyle headlineMd = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.0,
  );

  // ─── Geometry ────────────────────────────────────────────────────────────────
  static const double radius        = 0.0;   // Fully square as requested
  static const double radiusSm      = 0.0;   // Fully square
  static const double touchMin      = 56.0;

  // ─── ThemeData ───────────────────────────────────────────────────────────────
  static ThemeData get themeData => ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.light(
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      error: error,
      surface: surface,
      onSurface: onSurface,
      outline: outline,
      surfaceContainerHighest: surfaceVariant,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: onSurface,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      elevation: 4,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      titleTextStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: onSurface,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: onSurfaceVar,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        elevation: 0,
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: outline),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: outline),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: textMuted, fontFamily: 'Inter'),
      hintStyle: const TextStyle(color: outlineDark, fontFamily: 'Inter'),
    ),
    dividerTheme: const DividerThemeData(color: outline, thickness: 1, space: 1),
    cardTheme: const CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: outline),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? Colors.white : Colors.white),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? primary
              : const Color(0xFFD1D5DB)),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
  );
}
