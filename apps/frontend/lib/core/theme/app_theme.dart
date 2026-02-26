import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors
  static const primaryAccent = Color(0xFF8161FF); // Vibrant Purple/Indigo
  static const darkBackground = Color(0xFF0F0F12); // Sleek Deep Charcoal
  static const darkSurface = Color(0xFF1A1A1F);

  static const lightBackground = Color(0xFFF8F9FE);
  static const lightSurface = Color(0xFFFFFFFF);

  static const double _defaultRadius = 16.0;

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryAccent,
      brightness: brightness,
      primary: primaryAccent,
      surface: isDark ? darkSurface : lightSurface,
      onSurface: isDark ? Colors.white : Colors.black87,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? darkBackground : lightBackground,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData(brightness: brightness).textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_defaultRadius)),
        color: isDark ? darkSurface : lightSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_defaultRadius)),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkSurface : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_defaultRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_defaultRadius),
          borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_defaultRadius),
          borderSide: const BorderSide(color: primaryAccent, width: 2),
        ),
      ),
    );
  }
}
