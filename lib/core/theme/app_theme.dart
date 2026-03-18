import 'package:flutter/material.dart';

/// Luxury dark theme — think Robinhood meets high-end watch brand.
class AppTheme {
  AppTheme._();

  // ── Brand Palette ──────────────────────────────────────────────
  static const Color background    = Color(0xFF0A0A0F);  // Near-black
  static const Color surface       = Color(0xFF13131A);  // Card surface
  static const Color surfaceHigh   = Color(0xFF1C1C27);  // Elevated surface
  static const Color accent        = Color(0xFFD4AF37);  // Luxury gold
  static const Color accentLight   = Color(0xFFFFD966);  // Lighter gold highlight
  static const Color priceUp       = Color(0xFF00D4AA);  // Teal green — price up
  static const Color priceDown     = Color(0xFFFF5C5C);  // Red — price down
  static const Color textPrimary   = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFF8A8A9A);
  static const Color divider       = Color(0xFF252535);
  static const Color chartLine     = Color(0xFFD4AF37);
  static const Color chartFill     = Color(0x22D4AF37);  // Translucent gold fill

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: priceUp,
        surface: surface,
        error: priceDown,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -1.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          letterSpacing: 0.15,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textSecondary,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
