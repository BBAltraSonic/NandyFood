import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlack = Color(0xFF111111);
  static const Color primaryColor = Color(0xFF111111);
  static const Color secondaryText = Color(0xFF6F6F6F);
  
  static ThemeData get light {
    const background = Color(0xFFF6F6F6);
    const surface = Color(0xFFFFFFFF);
    const border = Color(0xFFE2E2E2);
    const textPrimary = Color(0xFF111111);
    const textSecondary = Color(0xFF6F6F6F);
    
    return ThemeData(
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.6),
        elevation: 0,
        indicatorColor: Colors.black.withValues(alpha: 0.05),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF111111),
        onPrimary: Colors.white,
        secondary: Color(0xFF6F6F6F),
        onSecondary: Colors.white,
        error: Color(0xFFB00020),
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary),
        bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.05),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: textPrimary, width: 1.4),
        ),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: textPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
