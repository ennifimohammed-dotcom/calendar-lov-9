import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFFF5F3EF);
  static const white = Color(0xFFFFFFFF);
  static const navy = Color(0xFF1B2B3A);
  static const green = Color(0xFF2D7D5F);
  static const greenPale = Color(0xFFEAF4EF);
  static const gold = Color(0xFFC8943A);
  static const goldPale = Color(0xFFFDF5E8);
  static const blue = Color(0xFF3A72C8);
  static const bluePale = Color(0xFFEBF0FC);
  static const red = Color(0xFFD94F4F);
  static const text = Color(0xFF1A1A1A);
  static const text2 = Color(0xFF555555);
  static const text3 = Color(0xFF999999);
  static const border = Color(0xFFE8E4DC);

  // dark
  static const bgDark = Color(0xFF0F1820);
  static const surfaceDark = Color(0xFF1B2B3A);
  static const textDark = Color(0xFFF1F1F1);
  static const borderDark = Color(0xFF2A3A48);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.green,
        secondary: AppColors.gold,
        surface: AppColors.white,
        error: AppColors.red,
      ),
      textTheme: _buildTextTheme(base.textTheme, AppColors.text),
      cardTheme: CardTheme(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.white,
      ),
      dividerColor: AppColors.border,
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.green,
        secondary: AppColors.gold,
        surface: AppColors.surfaceDark,
        error: AppColors.red,
      ),
      textTheme: _buildTextTheme(base.textTheme, AppColors.textDark),
      cardTheme: CardTheme(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgDark,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.white,
      ),
      dividerColor: AppColors.borderDark,
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, Color color) {
    final body = GoogleFonts.cairoTextTheme(base).apply(
      bodyColor: color,
      displayColor: color,
    );
    return body.copyWith(
      headlineLarge: GoogleFonts.amiri(
        textStyle: body.headlineLarge,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      headlineMedium: GoogleFonts.amiri(
        textStyle: body.headlineMedium,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      titleLarge: GoogleFonts.amiri(
        textStyle: body.titleLarge,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}
