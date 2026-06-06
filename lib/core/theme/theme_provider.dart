import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(); // Override in main.dart
});

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(ThemeNotifier.new);

class ThemeState {
  final ThemeMode themeMode;
  final Color primaryColor;

  ThemeState({required this.themeMode, required this.primaryColor});

  ThemeState copyWith({ThemeMode? themeMode, Color? primaryColor}) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      primaryColor: primaryColor ?? this.primaryColor,
    );
  }
}

class ThemeNotifier extends Notifier<ThemeState> {
  static const _themeModeKey = 'themeMode';
  static const _primaryColorKey = 'primaryColor';

  @override
  ThemeState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    
    // Đọc cài đặt ThemeMode (0: system, 1: light, 2: dark)
    final themeModeIndex = prefs.getInt(_themeModeKey) ?? 0;
    final themeMode = ThemeMode.values[themeModeIndex];

    // Đọc cài đặt PrimaryColor
    final colorValue = prefs.getInt(_primaryColorKey) ?? 0xFF2E5BFF; // Mặc định là màu xanh hiện tại
    final primaryColor = Color(colorValue);

    return ThemeState(themeMode: themeMode, primaryColor: primaryColor);
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    ref.read(sharedPreferencesProvider).setInt(_themeModeKey, mode.index);
  }

  void setPrimaryColor(Color color) {
    state = state.copyWith(primaryColor: color);
    ref.read(sharedPreferencesProvider).setInt(_primaryColorKey, color.value);
  }
}
