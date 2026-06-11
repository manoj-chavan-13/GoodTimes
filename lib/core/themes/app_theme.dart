import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color netflixRed = Color(0xFFE50914);
  static const Color onyxBlack = Color(0xFF141414);
  static const Color darkGray = Color(0xFF2B2B2B);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: netflixRed,
      scaffoldBackgroundColor: onyxBlack,
      cardColor: darkGray,
      fontFamily: GoogleFonts.inter().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: netflixRed,
        secondary: Colors.white,
        surface: darkGray,
        background: onyxBlack,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          headlineMedium: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          titleLarge: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          bodyLarge: const TextStyle(color: Colors.white, fontSize: 16),
          bodyMedium: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: netflixRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
    );
  }
}
