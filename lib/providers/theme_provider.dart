import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/themes/app_themes.dart';
import 'package:mobile_app/helper/db_helper.dart';

/// Riverpod state management for app theme, brightness, and UI scale.
class ThemeState {
  final String username;
  final double uiScale;
  final Brightness brightness;
  final Color accentColor;
  final bool isLoaded;

  const ThemeState({
    this.username = "Student",
    this.uiScale = 1.0,
    this.brightness = Brightness.dark,
    this.accentColor = const Color(0xFF009688),
    this.isLoaded = false,
  });

  ThemeState copyWith({
    String? username,
    double? uiScale,
    Brightness? brightness,
    Color? accentColor,
    bool? isLoaded,
  }) {
    return ThemeState(
      username: username ?? this.username,
      uiScale: uiScale ?? this.uiScale,
      brightness: brightness ?? this.brightness,
      accentColor: accentColor ?? this.accentColor,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  ThemeData get currentTheme => AppThemes.createTheme(brightness, accentColor);
}

class ThemeProvider extends ChangeNotifier {
  String _username = "Student";
  double _uiScale = 1.0;
  Brightness _brightness = Brightness.dark;
  Color _accentColor = const Color(0xFF009688);
  bool _isLoaded = false;

  String get username => _username;
  double get uiScale => _uiScale;
  Brightness get brightness => _brightness;
  Color get currentAccentColor => _accentColor;
  bool get isDarkMode => _brightness == Brightness.dark;
  String get currentThemeName => isDarkMode ? "dark" : "light";
  ThemeData get currentTheme => AppThemes.createTheme(_brightness, _accentColor);
  bool get isLoaded => _isLoaded;

  Future<void> loadSettings() async {
    try {
      final settings = await DatabaseHelper().getSettings();
      if (settings.isNotEmpty) {
        _username = settings['name'] ?? settings['username'] ?? "Student";
        _uiScale = (settings['uiScale'] ?? settings['ui_scale'] ?? 1.0).toDouble();

        if (settings['isDarkMode'] != null) {
          _brightness = (settings['isDarkMode'] == 1)
              ? Brightness.dark
              : Brightness.light;
        } else if (settings['dark'] != null) {
          _brightness = (settings['dark'] == 1) ? Brightness.dark : Brightness.light;
        }

        if (settings['accentColor'] != null && settings['accentColor'] != 0) {
          _accentColor = Color(settings['accentColor'] as int);
        }

        if (_uiScale >= 0.8 && _uiScale <= 1.2) {
        } else {
          _uiScale = 1.0;
        }

        _isLoaded = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading settings: $e");
    }
  }

  Future<void> updateUsername(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isNotEmpty) {
      _username = trimmedName;
      notifyListeners();
      try {
        await DatabaseHelper().saveSettings(name: trimmedName);
      } catch (e) {
        debugPrint("Error saving username: $e");
      }
    }
  }

  Future<void> setScale(double scale) async {
    _uiScale = scale;
    notifyListeners();
    try {
      await DatabaseHelper().saveSettings(uiScale: scale);
    } catch (e) {
      debugPrint("Error saving scale: $e");
    }
  }

  Future<void> setBrightness(Brightness newBrightness) async {
    _brightness = newBrightness;
    notifyListeners();
    await DatabaseHelper().saveSettings(dark: newBrightness == Brightness.dark);
  }

  Future<void> setTheme(String themeName) async {
    _brightness = (themeName == 'light') ? Brightness.light : Brightness.dark;
    notifyListeners();
    await DatabaseHelper().saveSettings(dark: _brightness == Brightness.dark);
  }

  void setColor(Color newColor) {
    _accentColor = newColor;
    notifyListeners();
    try {
      DatabaseHelper().saveSettings(accentColor: newColor.toARGB32());
    } catch (e) {
      debugPrint("Error saving color: $e");
    }
  }
}

final themeProvider = NotifierProvider<ThemeProviderNotifier, ThemeState>(
  ThemeProviderNotifier.new,
);

class ThemeProviderNotifier extends Notifier<ThemeState> {
  final _themeProvider = ThemeProvider();

  @override
  ThemeState build() {
    Future.microtask(() async {
      await _themeProvider.loadSettings();
      state = ThemeState(
        username: _themeProvider.username,
        uiScale: _themeProvider.uiScale,
        brightness: _themeProvider.brightness,
        accentColor: _themeProvider.currentAccentColor,
        isLoaded: true,
      );
    });
    return const ThemeState();
  }

  Future<void> loadSettings() async {
    await _themeProvider.loadSettings();
    state = ThemeState(
      username: _themeProvider.username,
      uiScale: _themeProvider.uiScale,
      brightness: _themeProvider.brightness,
      accentColor: _themeProvider.currentAccentColor,
      isLoaded: true,
    );
  }

  Future<void> updateUsername(String name) async {
    await _themeProvider.updateUsername(name);
    state = state.copyWith(username: _themeProvider.username);
  }

  Future<void> setScale(double scale) async {
    await _themeProvider.setScale(scale);
    state = state.copyWith(uiScale: _themeProvider.uiScale);
  }

  Future<void> setBrightness(Brightness b) async {
    await _themeProvider.setBrightness(b);
    state = state.copyWith(brightness: _themeProvider.brightness);
  }

  void setColor(Color c) {
    _themeProvider.setColor(c);
    state = state.copyWith(accentColor: _themeProvider.currentAccentColor);
  }

  ThemeData get currentTheme => state.currentTheme;
}