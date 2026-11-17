// ==============================================================================
// FILE: lib/services/prefs_service.dart
// PANDUAN: Service penyimpanan sesi & preferensi ringan menggunakan SharedPreferences.
// Digunakan untuk:
// 1. Status login (isLoggedIn) & username aktif.
// 2. Preferensi tampilan tema gelap/terang (isDarkMode).
// 3. Daftar item favorit dalam bentuk List JSON String (tahan saat app ditutup).
// ==============================================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  // ---------------------------------------------------------------------------
  // 1. KEYS PENYIMPANAN
  // ---------------------------------------------------------------------------
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyActiveUsername = 'active_username';
  static const String _keyIsDarkMode = 'is_dark_mode';
  static const String _keyThemePrimaryColor = 'theme_primary_color';
  static const String _keyFavorites = 'favorites_list';

  static SharedPreferences? _prefs;

  // ---------------------------------------------------------------------------
  // 2. INISIALISASI
  // Dipanggil di awal main.dart
  // ---------------------------------------------------------------------------
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Helper untuk memastikan instance SharedPreferences selalu tersedia
  static Future<SharedPreferences> get _instance async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  // ===========================================================================
  // 3. SESI AUTENTIKASI
  // ===========================================================================

  /// Mengecek apakah user saat ini sedang dalam status login
  static bool isLoggedIn() {
    return _prefs?.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Menyimpan status login (true = login, false = logout)
  static Future<bool> setLoggedIn(bool value) async {
    final sp = await _instance;
    return sp.setBool(_keyIsLoggedIn, value);
  }

  /// Mengambil username user yang sedang aktif login
  static String? getUsername() {
    return _prefs?.getString(_keyActiveUsername);
  }

  /// Menyimpan username user yang berhasil login
  static Future<bool> setUsername(String username) async {
    final sp = await _instance;
    return sp.setString(_keyActiveUsername, username);
  }

  /// Menghapus sesi login saat user logout
  static Future<void> clearAuth() async {
    final sp = await _instance;
    await sp.remove(_keyIsLoggedIn);
    await sp.remove(_keyActiveUsername);
  }

  // ===========================================================================
  // 4. PREFERENSI TEMA (DARK MODE)
  // ===========================================================================

  /// Mengecek apakah preferensi Dark Mode aktif
  static bool isDarkMode() {
    return _prefs?.getBool(_keyIsDarkMode) ?? false;
  }

  /// Menyimpan preferensi Dark Mode (true = dark, false = light)
  static Future<bool> setDarkMode(bool value) async {
    final sp = await _instance;
    return sp.setBool(_keyIsDarkMode, value);
  }

  /// Mengambil nilai warna tema utama (ARGB 32-bit int)
  static int? getPrimaryColorValue() {
    return _prefs?.getInt(_keyThemePrimaryColor);
  }

  /// Menyimpan nilai warna tema utama
  static Future<bool> setPrimaryColorValue(int value) async {
    final sp = await _instance;
    return sp.setInt(_keyThemePrimaryColor, value);
  }

  // ===========================================================================
  // 5. DAFTAR FAVORIT (PERSISTENT JSON)
  // Menyimpan list item favorit dalam bentuk string JSON agar tetap ada
  // meskipun aplikasi ditutup atau dibuka kembali.
  // ===========================================================================

  /// Mengambil semua raw JSON string item favorit
  static List<String> getFavoritesJson() {
    return _prefs?.getStringList(_keyFavorites) ?? [];
  }

  /// Menyimpan daftar JSON string item favorit
  static Future<bool> setFavoritesJson(List<String> list) async {
    final sp = await _instance;
    return sp.setStringList(_keyFavorites, list);
  }

  /// Cek apakah suatu item (berdasarkan id) sudah ada di dalam favorit
  static bool isFavorite(int id) {
    final list = getFavoritesJson();
    for (final itemStr in list) {
      try {
        final Map<String, dynamic> map = jsonDecode(itemStr);
        if (map['id'] == id) {
          return true;
        }
      } catch (_) {
        continue;
      }
    }
    return false;
  }

  // ===========================================================================
  // 6. RESET TOTAL DATA PREFS
  // ===========================================================================
  static Future<void> clearAll() async {
    final sp = await _instance;
    await sp.clear();
  }
}

