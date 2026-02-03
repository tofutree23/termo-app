import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_theme.dart';

class SettingsProvider extends ChangeNotifier {
  TerminalTheme _currentTheme = AppThemes.termoDark;
  double _fontSize = 14.0;

  TerminalTheme get currentTheme => _currentTheme;
  double get fontSize => _fontSize;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('theme') ?? 'Termo Dark';
    final fontSize = prefs.getDouble('fontSize') ?? 14.0;

    _currentTheme = AppThemes.all.firstWhere(
      (t) => t.name == themeName,
      orElse: () => AppThemes.termoDark,
    );
    _fontSize = fontSize;
    notifyListeners();
  }

  Future<void> setTheme(TerminalTheme theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme.name);
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size.clamp(8.0, 32.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', _fontSize);
    notifyListeners();
  }
}
