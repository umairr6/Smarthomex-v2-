import 'package:flutter/material.dart';

import 'colors.dart';

class SmartHomeTheme {
  SmartHomeTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,

      brightness: Brightness.dark,

      scaffoldBackgroundColor:
          SmartHomeColors.background,

      colorScheme: const ColorScheme.dark(
        primary: SmartHomeColors.gold,
        onPrimary: Colors.black,

        secondary: SmartHomeColors.goldLight,
        onSecondary: Colors.black,

        surface: SmartHomeColors.surface,
        onSurface: SmartHomeColors.textPrimary,

        error: SmartHomeColors.offline,
        onError: Colors.white,
      ),

      // ========================================================
      // APP BAR
      // ========================================================

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: SmartHomeColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),

      // ========================================================
      // CARD
      // ========================================================

      cardTheme: CardThemeData(
        color: SmartHomeColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: SmartHomeColors.border,
            width: 1,
          ),
        ),
      ),

      // ========================================================
      // INPUT FIELDS
      // ========================================================

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SmartHomeColors.surfaceElevated,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: SmartHomeColors.border,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: SmartHomeColors.border,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: SmartHomeColors.gold,
            width: 1.4,
          ),
        ),

        labelStyle: const TextStyle(
          color: SmartHomeColors.textMuted,
        ),

        hintStyle: const TextStyle(
          color: SmartHomeColors.textDisabled,
        ),

        prefixIconColor: SmartHomeColors.gold,
      ),

      // ========================================================
      // ELEVATED BUTTON
      // ========================================================

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SmartHomeColors.gold,
          foregroundColor: Colors.black,

          elevation: 0,

          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 15,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),

          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ========================================================
      // OUTLINED BUTTON
      // ========================================================

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SmartHomeColors.goldLight,

          side: const BorderSide(
            color: SmartHomeColors.borderGold,
          ),

          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 15,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),

      // ========================================================
      // TEXT BUTTON
      // ========================================================

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SmartHomeColors.goldLight,
        ),
      ),

      // ========================================================
      // SWITCH
      // ========================================================

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return SmartHomeColors.goldLight;
            }

            return SmartHomeColors.textMuted;
          },
        ),

        trackColor: WidgetStateProperty.resolveWith<Color?>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return SmartHomeColors.goldDark;
            }

            return SmartHomeColors.surfaceElevated;
          },
        ),

        trackOutlineColor:
            WidgetStateProperty.all(
          SmartHomeColors.border,
        ),
      ),

      // ========================================================
      // PROGRESS INDICATOR
      // ========================================================

      progressIndicatorTheme:
          const ProgressIndicatorThemeData(
        color: SmartHomeColors.gold,
      ),

      // ========================================================
      // DIVIDER
      // ========================================================

      dividerTheme: const DividerThemeData(
        color: SmartHomeColors.border,
        thickness: 1,
      ),

      // ========================================================
      // ICON
      // ========================================================

      iconTheme: const IconThemeData(
        color: SmartHomeColors.goldLight,
      ),

      // ========================================================
      // SNACKBAR
      // ========================================================

      snackBarTheme: SnackBarThemeData(
        backgroundColor: SmartHomeColors.surfaceElevated,
        contentTextStyle: const TextStyle(
          color: SmartHomeColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}