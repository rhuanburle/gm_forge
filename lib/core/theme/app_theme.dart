import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// GM Forge Design System
///
/// Medieval fantasy theme with dark mode and rich aesthetics.
class AppTheme {
  AppTheme._();

  // === Colors ===

  static const Color primary = Color(0xFF8B4513); // Saddle Brown
  static const Color primaryDark = Color(0xFF5D2E0C); // Dark Brown
  static const Color secondary = Color(0xFFDAA520); // Goldenrod
  static const Color accent = Color(0xFF9B2335); // Deep Red

  static const Color background = Color(0xFF1A1A1A); // Near Black
  static const Color surface = Color(0xFF2D2D2D); // Dark Gray
  static const Color surfaceLight = Color(0xFF3D3D3D); // Lighter Gray

  static const Color textPrimary = Color(0xFFF5F5DC); // Beige
  static const Color textSecondary = Color(0xFFB8B8A0);
  static const Color textMuted = Color(0xFF808080);

  static const Color success = Color(0xFF228B22); // Forest Green
  static const Color warning = Color(0xFFDAA520); // Goldenrod
  static const Color error = Color(0xFF9B2335); // Deep Red
  static const Color info = Color(0xFF4169E1); // Royal Blue

  // === Gradients ===

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1A1A1A), Color(0xFF2D1810)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // === Theme Data ===

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
        onPrimary: textPrimary,
        onSecondary: background,
        onSurface: textPrimary,
        onError: textPrimary,
      ),

      scaffoldBackgroundColor: background,

      textTheme: _buildTextTheme(),

      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cinzel(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),

      cardTheme: const CardThemeData(
        color: surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: primaryDark, width: 1),
        ),
        margin: EdgeInsets.all(8),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondary,
          side: const BorderSide(color: secondary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: secondary),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryDark.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: background,
        elevation: 6,
      ),

      dividerTheme: DividerThemeData(
        color: primaryDark.withValues(alpha: 0.3),
        thickness: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight,
        labelStyle: const TextStyle(color: textPrimary),
        side: BorderSide(color: primaryDark.withValues(alpha: 0.5)),
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: primaryDark),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceLight,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return TextTheme(
      // Display styles - for hero sections
      displayLarge: GoogleFonts.cinzel(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      displayMedium: GoogleFonts.cinzel(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      displaySmall: GoogleFonts.cinzel(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),

      // Headlines - for page titles
      headlineLarge: GoogleFonts.cinzel(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.cinzel(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.lato(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),

      // Titles - for cards and sections
      titleLarge: GoogleFonts.lato(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleSmall: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textSecondary,
      ),

      // Body - for content
      bodyLarge: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodySmall: GoogleFonts.lato(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),

      // Labels - for buttons and inputs
      labelLarge: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      labelMedium: GoogleFonts.lato(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      labelSmall: GoogleFonts.lato(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textMuted,
      ),
    );
  }

  // === Decorations ===

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: primaryDark, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.3),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration get parchmentDecoration => BoxDecoration(
    color: const Color(0xFFF5DEB3).withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: secondary.withValues(alpha: 0.3)),
  );
}
