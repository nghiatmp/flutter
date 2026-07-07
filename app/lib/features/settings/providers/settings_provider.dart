import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/storage/local_storage.dart';
import '../../auth/providers/auth_provider.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(ref.watch(localStorageProvider)),
);

class SettingsState {
  const SettingsState({
    required this.themeMode,
    required this.locale,
    required this.isReady,
  });

  const SettingsState.initial()
    : themeMode = ThemeMode.system,
      locale = const Locale('vi'),
      isReady = false;

  final ThemeMode themeMode;
  final Locale locale;
  final bool isReady;

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? isReady,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      isReady: isReady ?? this.isReady,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._storage) : super(const SettingsState.initial()) {
    loadSettings();
  }

  final LocalStorage _storage;

  Future<void> loadSettings() async {
    final rawThemeMode = await _storage.getString(StorageKeys.themeMode);
    final languageCode = await _storage.getString(StorageKeys.languageCode);

    state = SettingsState(
      themeMode: _parseThemeMode(rawThemeMode),
      locale: Locale(languageCode ?? 'vi'),
      isReady: true,
    );
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    await _storage.setString(StorageKeys.themeMode, themeMode.name);
    state = state.copyWith(themeMode: themeMode, isReady: true);
  }

  Future<void> setLocale(Locale locale) async {
    await _storage.setString(StorageKeys.languageCode, locale.languageCode);
    state = state.copyWith(locale: locale, isReady: true);
  }

  ThemeMode _parseThemeMode(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}
