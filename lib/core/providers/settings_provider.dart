import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/biometric_auth_service.dart';
import '../theme/theme_provider.dart';
import '../services/auto_track_service.dart';

class SettingsState {
  final bool useBiometrics;
  final bool autoTrackEnabled;

  SettingsState({required this.useBiometrics, required this.autoTrackEnabled});

  SettingsState copyWith({bool? useBiometrics, bool? autoTrackEnabled}) {
    return SettingsState(
      useBiometrics: useBiometrics ?? this.useBiometrics,
      autoTrackEnabled: autoTrackEnabled ?? this.autoTrackEnabled,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _useBiometricsKey = 'use_biometrics';
  static const _autoTrackKey = 'auto_track';

  @override
  SettingsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return SettingsState(
      useBiometrics: prefs.getBool(_useBiometricsKey) ?? false,
      autoTrackEnabled: prefs.getBool(_autoTrackKey) ?? false,
    );
  }

  Future<bool> setUseBiometrics(bool value) async {
    if (value) {
      final authService = BiometricAuthService();
      final canCheck = await authService.canCheckBiometrics();
      if (!canCheck) {
        return false; // Not supported
      }
      
      // Optionally authenticate once before enabling
      final authenticated = await authService.authenticate();
      if (!authenticated) {
        return false;
      }
    }
    
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_useBiometricsKey, value);
    state = state.copyWith(useBiometrics: value);
    return true;
  }

  Future<bool> setAutoTrack(bool value) async {
    if (value) {
      final autoTrackService = AutoTrackService();
      final hasPermission = await autoTrackService.requestPermission();
      if (!hasPermission) return false;
      await autoTrackService.init();
    }
    
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_autoTrackKey, value);
    state = state.copyWith(autoTrackEnabled: value);
    return true;
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
