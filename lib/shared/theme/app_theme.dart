import 'package:flutter/material.dart';

class AppTheme {
  // Modern Soft Color Palette (from inspiration)
  static const Color sageBackground = Color(0xFFE5E4D7); // Lighter, softer beige
  static const Color oliveGreen = Color(0xFF919849);
  static const Color mutedGreen = Color(0xFF7FB069);
  static const Color warmCream = Color(0xFFF5F4ED);
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color cardWhite = Color(0xFFFFFFFF);
  
  // Additional accent colors for meal times and status
  static const Color breakfastColor = Color(0xFFFFE5B4);
  static const Color lunchColor = Color(0xFFB4E5D4);
  static const Color supperColor = Color(0xFFFFB4D4);
  static const Color dinnerColor = Color(0xFFB4C7E5);
  static const Color cookingStatus = Color(0xFF919849);
  static const Color finishedStatus = Color(0xFF7FB069);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: sageBackground,
      colorScheme: ColorScheme.light(
        primary: oliveGreen,
        secondary: mutedGreen,
        surface: cardWhite,
        surfaceContainerHighest: warmCream,
        onPrimary: cardWhite,
        onSecondary: cardWhite,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        error: const Color(0xFFDC2626),
      ),
      textTheme: _buildTextTheme(),
      appBarTheme: _buildAppBarTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(),
      cardTheme: _buildCardTheme(),
      floatingActionButtonTheme: _buildFABTheme(),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      colorScheme: ColorScheme.dark(
        primary: oliveGreen,
        secondary: mutedGreen,
        surface: const Color(0xFF2D2D2D),
        surfaceContainerHighest: const Color(0xFF3A3A3A),
        onPrimary: cardWhite,
        onSecondary: cardWhite,
        onSurface: const Color(0xFFE5E5E5),
        onSurfaceVariant: const Color(0xFFB0B0B0),
        error: const Color(0xFFEF4444),
      ),
      textTheme: _buildTextTheme(),
      appBarTheme: _buildAppBarTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(),
      cardTheme: _buildCardTheme(),
      floatingActionButtonTheme: _buildFABTheme(),
    );
  }

  static TextTheme _buildTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16),
      bodyMedium: TextStyle(fontSize: 14),
      bodySmall: TextStyle(fontSize: 12),
    );
  }

  static AppBarTheme _buildAppBarTheme() {
    return const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: cardWhite,
        backgroundColor: oliveGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        elevation: 0,
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme() {
    return InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: textSecondary.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: oliveGreen, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      filled: true,
      fillColor: cardWhite,
    );
  }

  static CardThemeData _buildCardTheme() {
    return CardThemeData(
      color: cardWhite,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  static FloatingActionButtonThemeData _buildFABTheme() {
    return FloatingActionButtonThemeData(
      backgroundColor: oliveGreen,
      foregroundColor: cardWhite,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    );
  }
}
