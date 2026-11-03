import 'package:flutter/material.dart';

abstract final class AppColors {
  static const forest = Color(0xFF0B3D2E);
  static const primaryAction = Color(0xFF176B45);
  static const green = primaryAction;
  static const leaf = Color(0xFF2E9C63);
  static const mint = Color(0xFFDDF2E4);
  static const cream = Color(0xFFF7F5ED);
  static const creamDark = Color(0xFFEDE8DC);
  static const creamDeep = Color(0xFF7B6F50);
  static const yellow = Color(0xFFF6C453);
  static const ink = Color(0xFF17231D);
  static const muted = Color(0xFF66736C);
  static const cellBorder = Color(0xFFE1E7E3);
}

abstract final class AppTypography {
  static const navigationTitleFontSize = 18.0;
  static const navigationTitleFontWeight = FontWeight.w600;

  static const navigationTitle = TextStyle(
    fontFamily: 'ProductSans',
    fontSize: navigationTitleFontSize,
    fontWeight: navigationTitleFontWeight,
  );
}

abstract final class AppRadii {
  static const profileCard = 18.0;
}

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.green,
      brightness: Brightness.light,
      primary: AppColors.primaryAction,
      surface: AppColors.cream,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.cream,
      fontFamily: 'ProductSans',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.ink,
          fontSize: 34,
          height: 1.05,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.1,
        ),
        headlineMedium: TextStyle(
          color: AppColors.ink,
          fontSize: 27,
          height: 1.12,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.7,
        ),
        titleLarge: TextStyle(
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: AppColors.ink, fontSize: 16, height: 1.45),
        bodyMedium: TextStyle(
          color: AppColors.muted,
          fontSize: 14,
          height: 1.45,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryAction,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        constraints: BoxConstraints(maxWidth: double.infinity),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.mint,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColors.forest
                : AppColors.muted,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
      ),
    );
  }
}
