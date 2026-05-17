import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF006B4F);
  static const Color darkPrimary = Color(0xFF004D3A);
  static const Color lightGreen = Color(0xFFA7E3C3);
  static const Color background = Color(0xFFF7F9FC);
  static const Color card = Colors.white;
  static const Color textDark = Color(0xFF0F172A);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color softBlue = Color(0xFFDDEBFF);
  static const Color danger = Color(0xFFE53935);
  static const Color warning = Color(0xFFF9A825);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: primary,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
