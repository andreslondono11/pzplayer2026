import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData = AppTheme.lightTheme;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeData get themeData => _themeData;
  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeFromPrefs(); // 🔑 carga al iniciar
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('themeMode') ?? 'system';

    switch (mode) {
      case 'light':
        _themeMode = ThemeMode.light;
        _themeData = AppTheme.lightTheme;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        _themeData = AppTheme.darkTheme;
        break;
      default:
        _themeMode = ThemeMode.system;
        _themeData = AppTheme.lightTheme; // por defecto
    }
    notifyListeners();
  }

  Future<void> _saveThemeToPrefs(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode);
  }

  void setTheme(ThemeData theme) {
    _themeData = theme;
    if (theme.brightness == Brightness.dark) {
      _themeMode = ThemeMode.dark;
      _saveThemeToPrefs('dark');
    } else {
      _themeMode = ThemeMode.light;
      _saveThemeToPrefs('light');
    }
    notifyListeners();
  }

  void setSystemTheme() {
    _themeMode = ThemeMode.system;
    _saveThemeToPrefs('system');
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.system || _themeMode == ThemeMode.light) {
      setTheme(AppTheme.darkTheme);
    } else {
      setTheme(AppTheme.lightTheme);
    }
  }
}
