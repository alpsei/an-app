import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeType { light, dark }

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeType>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<AppThemeType> {
  ThemeNotifier() : super(AppThemeType.light) {
    _loadTheme(); // Başlangıçta temayı yükle
  }

  static const _prefsKey = 'savedTheme';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_prefsKey);
    state = savedTheme == 'dark' ? AppThemeType.dark : AppThemeType.light;
  }

  void toggleTheme() async {
    final newTheme = state == AppThemeType.light ? AppThemeType.dark : AppThemeType.light;
    state = newTheme;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, newTheme.name); // 'light' veya 'dark' olarak kaydet
  }
}