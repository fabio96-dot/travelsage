import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemes {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF7F3FF),
      primaryColor: const Color(0xFF6A4DFF),
      cardColor: Colors.white,
      textTheme: GoogleFonts.poppinsTextTheme(), // ✅ CORRETTO QUI
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6A4DFF),
        onPrimary: Colors.white,
        secondary: Color(0xFF80CBC4),
        onSecondary: Colors.black,
        background: Color(0xFFF7F3FF),
        onBackground: Colors.black,
        surface: Colors.white,
        onSurface: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      primaryColor: const Color(0xFF8A7EFF),
      cardColor: const Color(0xFF1E1E1E),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme), // ✅ CORRETTO QUI
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF8A7EFF),
        onPrimary: Colors.white,
        secondary: Color(0xFFB39DDB),
        onSecondary: Colors.white,
        background: Color(0xFF121212),
        onBackground: Colors.white,
        surface: Color(0xFF1E1E1E),
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
