import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light();
    final Color primary = const Color(0xFF0B4F6C);
    final Color accent = const Color(0xFF2B9DBB);
    final Color surface = const Color(0xFFFFFFFF);
    final Color background = const Color(0xFFF1F6FA);

    return base.copyWith(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 6,
        centerTitle: false,
        toolbarHeight: 64,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: accent,
        background: background,
        surface: surface,
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        elevation: 6,
      ),
    );
  }
}
