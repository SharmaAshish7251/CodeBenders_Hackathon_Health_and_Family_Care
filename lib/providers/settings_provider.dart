import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeKey = 'theme_mode';
const _localeKey = 'locale';
const _analyticsEnabledKey = 'analytics_enabled';
const _supportedLanguageCodes = {'en', 'hi'};

/// Reads the analytics opt-out from storage. Defaults to enabled. Used by the
/// analytics repository so it never depends on provider load timing.
Future<bool> isAnalyticsEnabledStored() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_analyticsEnabledKey) ?? true;
}

/// Immutable user-facing app settings. Holds no sensitive data.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('en'),
    this.analyticsEnabled = true,
  });

  final ThemeMode themeMode;
  final Locale locale;

  /// Local usage analytics (PRD F20). On by default; the user can opt out.
  final bool analyticsEnabled;

  AppSettings copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? analyticsEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
    );
  }
}

/// Holds [AppSettings]. Returns defaults synchronously from [build] and then
/// applies persisted values from shared_preferences once they load.
class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _persist(_themeModeKey, mode.name);
  }

  void setLocale(Locale locale) {
    state = state.copyWith(locale: locale);
    _persist(_localeKey, locale.languageCode);
  }

  void setAnalyticsEnabled(bool enabled) {
    state = state.copyWith(analyticsEnabled: enabled);
    _persistBool(_analyticsEnabledKey, enabled);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;

    final themeMode = _themeModeFromName(prefs.getString(_themeModeKey));
    final languageCode = prefs.getString(_localeKey);
    final locale = languageCode != null &&
            _supportedLanguageCodes.contains(languageCode)
        ? Locale(languageCode)
        : null;
    final analyticsEnabled = prefs.getBool(_analyticsEnabledKey) ?? true;
    state = state.copyWith(
      themeMode: themeMode,
      locale: locale,
      analyticsEnabled: analyticsEnabled,
    );
  }

  Future<void> _persist(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _persistBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  ThemeMode? _themeModeFromName(String? name) {
    for (final mode in ThemeMode.values) {
      if (mode.name == name) return mode;
    }
    return null;
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
