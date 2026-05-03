import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryDark = Color(0xFF5C3D5C);   // dark purple sidebar
  static const Color primaryMid = Color(0xFF7A4F6D);    // mid purple
  static const Color primaryLight = Color(0xFFB07A9E);  // light mauve panel
  static const Color accentPink = Color(0xFFE8A0C0);    // pink button
  static const Color accentGreen = Color(0xFF4A8C6F);   // green success/budget
  static const Color accentRed = Color(0xFFD04040);     // red error/due
  static const Color background = Color(0xFFF5F0F5);    // light bg
  static const Color white = Colors.white;
  static const Color cardLight = Color(0xFFF2E8F0);     // light pink card
  static const Color successGreen = Color(0xFF5A9E78);  // checkmark green
  static const Color textDark = Color(0xFF2A1A2A);
  static const Color textMid = Color(0xFF6B4F6B);
  static const Color textLight = Color(0xFF9A7A9A);
  static const Color inputBg = Color(0xFFD4C0D0);
  static const Color inputErrorBg = Color(0xFFC07070);
  static const Color budgetCardBg = Color(0xFF4A7A65);  // teal-green
  static const Color incomeBadge = Color(0xFFD0EED8);
  static const Color expenseBadge = Color(0xFFFFD0D0);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      fontFamily: 'Courier',
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryDark,
        primary: AppColors.primaryDark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentPink,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      fontFamily: 'Courier',
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1A0F1A),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryDark,
        primary: AppColors.primaryMid,
        brightness: Brightness.dark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentPink,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF3A2A3A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
      ),
      cardColor: const Color(0xFF2A1A2A),
      dividerColor: AppColors.primaryMid,
    );
  }
}