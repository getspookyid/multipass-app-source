import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Jinx Color Palette (League of Legends)
  static const Color electricBlue = Color(0xFF00D9FF); // Primary (Jinx's hair)
  static const Color hotPink = Color(0xFFFF1493); // Accent (Jinx's signature)
  static const Color deepPurple = Color(0xFF6B2E8F); // Tertiary
  static const Color darkBg = Color(0xFF000000); // Near-black background

  static final ThemeData darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: electricBlue,
      brightness: Brightness.dark,
      surface: const Color(0xFF0A0A0A), // Near-black
      background: const Color(0xFF000000),
      primary: electricBlue,
      secondary: hotPink,
      tertiary: deepPurple,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF000000),
    fontFamily: GoogleFonts.outfit().fontFamily,
  );
}
