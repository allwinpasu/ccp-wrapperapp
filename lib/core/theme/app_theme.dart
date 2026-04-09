import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_fonts.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundLight,

    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      primaryContainer: AppColors.primaryLight,
      secondary: AppColors.secondary,
      secondaryContainer: AppColors.secondaryLight,
      surface: AppColors.surfaceLight,
      background: AppColors.backgroundLight,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimaryLight,
      onBackground: AppColors.textPrimaryLight,
      onError: Colors.white,
    ),

    // Text Theme
    textTheme: TextTheme(
      displayLarge: AppFonts.h1.copyWith(color: AppColors.textPrimaryLight),
      displayMedium: AppFonts.h2.copyWith(color: AppColors.textPrimaryLight),
      displaySmall: AppFonts.h3.copyWith(color: AppColors.textPrimaryLight),
      headlineMedium: AppFonts.h4.copyWith(color: AppColors.textPrimaryLight),
      bodyLarge:
          AppFonts.bodyLargeStyle.copyWith(color: AppColors.textPrimaryLight),
      bodyMedium:
          AppFonts.bodyMediumStyle.copyWith(color: AppColors.textPrimaryLight),
      bodySmall:
          AppFonts.bodySmallStyle.copyWith(color: AppColors.textSecondaryLight),
    ),

    // App Bar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppFonts.h4.copyWith(color: Colors.white),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        textStyle:
            AppFonts.bodyMediumStyle.copyWith(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      labelStyle: AppFonts.bodyMediumStyle
          .copyWith(color: AppColors.textSecondaryLight),
      hintStyle: AppFonts.bodyMediumStyle
          .copyWith(color: AppColors.textSecondaryLight),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundDark,

    // Color Scheme
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      primaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      secondaryContainer: AppColors.secondaryDark,
      surface: AppColors.surfaceDark,
      background: AppColors.backgroundDark,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimaryDark,
      onBackground: AppColors.textPrimaryDark,
      onError: Colors.white,
    ),

    // Text Theme
    textTheme: TextTheme(
      displayLarge: AppFonts.h1.copyWith(color: AppColors.textPrimaryDark),
      displayMedium: AppFonts.h2.copyWith(color: AppColors.textPrimaryDark),
      displaySmall: AppFonts.h3.copyWith(color: AppColors.textPrimaryDark),
      headlineMedium: AppFonts.h4.copyWith(color: AppColors.textPrimaryDark),
      bodyLarge:
          AppFonts.bodyLargeStyle.copyWith(color: AppColors.textPrimaryDark),
      bodyMedium:
          AppFonts.bodyMediumStyle.copyWith(color: AppColors.textPrimaryDark),
      bodySmall:
          AppFonts.bodySmallStyle.copyWith(color: AppColors.textSecondaryDark),
    ),

    // App Bar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: AppColors.textPrimaryDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppFonts.h4.copyWith(color: AppColors.textPrimaryDark),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        textStyle:
            AppFonts.bodyMediumStyle.copyWith(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      labelStyle:
          AppFonts.bodyMediumStyle.copyWith(color: AppColors.textSecondaryDark),
      hintStyle:
          AppFonts.bodyMediumStyle.copyWith(color: AppColors.textSecondaryDark),
    ),
  );
}
