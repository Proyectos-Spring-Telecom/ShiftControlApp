import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import 'auth_controller.dart';

/// Valores guardados para el modo de tema.
enum ThemeModePreference {
  light('light', ThemeMode.light),
  dark('dark', ThemeMode.dark),
  system('system', ThemeMode.system);

  const ThemeModePreference(this.value, this.mode);
  final String value;
  final ThemeMode mode;

  static ThemeModePreference fromValue(String? value) {
    return ThemeModePreference.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ThemeModePreference.system,
    );
  }

  String get label {
    return switch (this) {
      ThemeModePreference.light => 'Claro',
      ThemeModePreference.dark => 'Oscuro',
      ThemeModePreference.system => 'Según el dispositivo',
    };
  }
}

final themeModePreferenceProvider = StateNotifierProvider<ThemeController, ThemeModePreference>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeController(prefs);
});

class ThemeController extends StateNotifier<ThemeModePreference> {
  ThemeController(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static ThemeModePreference _load(SharedPreferences prefs) {
    return ThemeModePreference.fromValue(prefs.getString(AppConstants.keyThemeMode));
  }

  Future<void> setThemeMode(ThemeModePreference preference) async {
    await _prefs.setString(AppConstants.keyThemeMode, preference.value);
    state = preference;
  }
}
