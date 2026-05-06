import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_themes.dart';

const _kThemeKey = 'app_theme';

/// ChangeNotifier que gerencia o tema global (princesa ou carros).
/// Persiste a escolha em SharedPreferences entre sessões.
class ThemeProvider extends ChangeNotifier {
  AppThemeMode _mode;

  ThemeProvider(AppThemeMode initial) : _mode = initial;

  AppThemeMode get mode => _mode;
  AppThemeTokens get tokens => tokensFor(_mode);
  ThemeData get themeData => buildThemeData(_mode);

  /// Troca o tema e persiste imediatamente.
  Future<void> setTheme(AppThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, mode.name);
  }

  /// Fábrica: carrega o tema salvo (ou usa [fallback]).
  static Future<ThemeProvider> load({
    AppThemeMode fallback = AppThemeMode.cars,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemeKey);
    final mode = saved == AppThemeMode.princess.name
        ? AppThemeMode.princess
        : fallback;
    return ThemeProvider(mode);
  }
}
