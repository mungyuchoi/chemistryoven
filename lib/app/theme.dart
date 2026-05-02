import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.burgundy,
      brightness: Brightness.light,
      primary: AppColors.burgundy,
      secondary: AppColors.caramel,
      surface: AppColors.ivory,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.cream,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.wine,
        titleTextStyle: TextStyle(
          color: AppColors.wine,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.ivory,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.ivory,
        selectedItemColor: AppColors.burgundy,
        unselectedItemColor: AppColors.mutedText,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.burgundy,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.burgundy,
          side: const BorderSide(color: AppColors.burgundy),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.wine,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cream,
        selectedColor: AppColors.burgundy,
        labelStyle: const TextStyle(color: AppColors.cocoa),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.burgundy, width: 1.4),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.wine,
          fontWeight: FontWeight.w900,
          fontSize: 30,
          height: 1.16,
        ),
        headlineMedium: TextStyle(
          color: AppColors.wine,
          fontWeight: FontWeight.w800,
          fontSize: 24,
        ),
        titleLarge: TextStyle(
          color: AppColors.wine,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
        titleMedium: TextStyle(
          color: AppColors.cocoa,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: AppColors.cocoa,
          fontSize: 14,
          height: 1.45,
        ),
        bodySmall: TextStyle(
          color: AppColors.mutedText,
          fontSize: 12,
          height: 1.35,
        ),
      ),
    );
  }
}
