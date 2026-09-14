import 'package:flutter/material.dart';

import 'colors.dart';

class SmartHomeTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,

      brightness: Brightness.dark,

      // ==========================================
      // IMPORTANT
      // ==========================================

      scaffoldBackgroundColor: Colors.transparent,

      canvasColor: Colors.transparent,

      fontFamily: 'Poppins',

      // ==========================================
      // COLORS
      // ==========================================

      colorScheme: const ColorScheme.dark(
        primary: SmartHomeColors.primary,
        secondary: SmartHomeColors.secondary,
        surface: SmartHomeColors.surface,
        error: SmartHomeColors.danger,
      ),

      // ==========================================
      // APP BAR
      // ==========================================

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),

      // ==========================================
      // INPUT
      // ==========================================

      inputDecorationTheme: InputDecorationTheme(
        filled: true,

        fillColor: Colors.white.withOpacity(0.055),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: SmartHomeColors.border,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: SmartHomeColors.border,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: SmartHomeColors.primary,
            width: 1.5,
          ),
        ),

        hintStyle: const TextStyle(
          color: SmartHomeColors.textMuted,
        ),
      ),

      // ==========================================
      // BUTTON
      // ==========================================

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SmartHomeColors.primary,
          foregroundColor: Colors.black,

          elevation: 0,

          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 15,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),

          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ==========================================
      // SNACKBAR
      // ==========================================

      snackBarTheme: SnackBarThemeData(
        backgroundColor: SmartHomeColors.surfaceLight,

        behavior: SnackBarBehavior.floating,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ==========================================
      // DIVIDER
      // ==========================================

      dividerTheme: const DividerThemeData(
        color: SmartHomeColors.border,
      ),
    );
  }
}