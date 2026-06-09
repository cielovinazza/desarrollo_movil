import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF006B4F);
  static const Color darkPrimary = Color(0xFF004D3A);
  static const Color lightGreen = Color(0xFFA7E3C3);
  static const Color background = Color.fromARGB(255, 247, 252, 250);
  static const Color cardLight = Colors.white;
  static const Color textDark = Color(0xFF0F172A);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color softBlue = Color(0xFFDDEBFF);
  static const Color danger = Color(0xFFE53935);
  static const Color warning = Color(0xFFF9A825);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      cardColor: cardLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: darkPrimary,
        surface: cardLight,
        error: danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF4F6F8),
        foregroundColor: Color(0xFF0F5A3C),
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textDark, fontWeight: FontWeight.w500),
        bodyMedium: TextStyle(color: textGrey),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 1,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      primaryColor: primary,
      cardColor: const Color(0xFF1E1E1E),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
        secondary: lightGreen,
        surface: const Color(0xFF1E1E1E),
        error: danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF004D3A),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 1,
        ),
      ),
    );
  }
}
