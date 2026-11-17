// ==============================================================================
// FILE: lib/providers/theme_provider.dart
// PANDUAN: State Management tema aplikasi (Light / Dark Mode & Pilihan Warna Aksen).
// Menggunakan SharedPreferences untuk menyimpan preferensi secara permanen.
// ==============================================================================

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/prefs_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  Color _primaryColor = AppTheme.primaryColor;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  Color get primaryColor => _primaryColor;

  /// Inisialisasi membaca preferensi tema yang tersimpan di SharedPreferences
  void init() {
    final isDark = PrefsService.isDarkMode();
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    final savedColorVal = PrefsService.getPrimaryColorValue();
    if (savedColorVal != null) {
      _primaryColor = Color(savedColorVal);
    }
    notifyListeners();
  }

  /// Mengubah tema (Dark/Light) dan menyimpannya secara otomatis
  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    await PrefsService.setDarkMode(isDark);
    notifyListeners();
  }

  /// Mengubah warna tema utama dan menyimpannya secara permanen
  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    // toARGB32() menghasilkan integer 32-bit representasi warna
    await PrefsService.setPrimaryColorValue(color.toARGB32());
    notifyListeners();
  }
}
