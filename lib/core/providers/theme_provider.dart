import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

class ThemeState {
  final AppThemeMode themeMode;
  final ThemeMode flutterThemeMode;

  ThemeState({required this.themeMode, required this.flutterThemeMode});

  ThemeState copyWith({AppThemeMode? themeMode, ThemeMode? flutterThemeMode}) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      flutterThemeMode: flutterThemeMode ?? this.flutterThemeMode,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  static const String _themeKey = 'app_theme_mode';

  ThemeNotifier()
    : super(
        ThemeState(
          themeMode: AppThemeMode.system,
          flutterThemeMode: ThemeMode.system,
        ),
      ) {
    _loadTheme();
  }

  /// Load theme preference from storage
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeName = prefs.getString(_themeKey) ?? 'system';

      final themeMode = AppThemeMode.values.firstWhere(
        (e) => e.name == themeName,
        orElse: () => AppThemeMode.system,
      );

      state = ThemeState(
        themeMode: themeMode,
        flutterThemeMode: _getFlutterThemeMode(themeMode),
      );
    } catch (e) {
      // If loading fails, keep default system theme
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(AppThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);

      state = ThemeState(
        themeMode: mode,
        flutterThemeMode: _getFlutterThemeMode(mode),
      );
    } catch (e) {
      // Handle error silently
    }
  }

  /// Convert app theme mode to Flutter theme mode
  ThemeMode _getFlutterThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});
