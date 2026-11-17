// ==============================================================================
// FILE: lib/providers/favorite_provider.dart
// PANDUAN: State Management untuk daftar item favorit aplikasi.
// Reaktif (mengupdate UI secara instan di semua halaman) dan otomatis
// menyimpan daftar favorit ke SharedPreferences dalam bentuk JSON list string.
// ==============================================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/item_model.dart';
import '../services/prefs_service.dart';

class FavoriteProvider extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // 1. STATE VARIABLES
  // ---------------------------------------------------------------------------
  List<ItemModel> _favorites = [];

  // ---------------------------------------------------------------------------
  // 2. GETTERS
  // ---------------------------------------------------------------------------
  List<ItemModel> get favorites => List.unmodifiable(_favorites);
  int get count => _favorites.length;
  bool get isEmpty => _favorites.isEmpty;

  // ---------------------------------------------------------------------------
  // 3. CONSTRUCTOR & LOAD DATA
  // Otomatis memuat data dari SharedPreferences saat provider diinisialisasi
  // ---------------------------------------------------------------------------
  FavoriteProvider() {
    loadFavorites();
  }

  /// Memuat daftar item favorit dari SharedPreferences
  void loadFavorites() {
    final rawList = PrefsService.getFavoritesJson();
    final List<ItemModel> loaded = [];

    for (final jsonStr in rawList) {
      try {
        final Map<String, dynamic> map = jsonDecode(jsonStr);
        loaded.add(ItemModel.fromJson(map));
      } catch (_) {
        // Abaikan data korup jika ada
        continue;
      }
    }

    _favorites = loaded;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // 4. CEK STATUS FAVORIT
  // ---------------------------------------------------------------------------
  bool isFavorite(int id) {
    return _favorites.any((item) => item.id == id);
  }

  // ---------------------------------------------------------------------------
  // 5. TOGGLE FAVORITE (TAMBAH / HAPUS)
  // Dipanggil saat ikon hati di Card atau Detail Screen ditekan.
  // Mengembalikan true jika sekarang menjadi Favorit, false jika dihapus.
  // ---------------------------------------------------------------------------
  Future<bool> toggleFavorite(ItemModel item) async {
    final exists = isFavorite(item.id);

    if (exists) {
      _favorites.removeWhere((element) => element.id == item.id);
      await _saveToPrefs();
      notifyListeners();
      return false; // Dihapus dari favorit
    } else {
      _favorites.add(item);
      await _saveToPrefs();
      notifyListeners();
      return true; // Ditambahkan ke favorit
    }
  }

  /// Menghapus item dari favorit berdasarkan ID (misal via Swipe to Delete)
  Future<void> removeFavorite(int id) async {
    _favorites.removeWhere((item) => item.id == id);
    await _saveToPrefs();
    notifyListeners();
  }

  /// --------------------------------------------------------------------------
  /// [FITUR KEJUTAN 9] HAPUS SEMUA FAVORIT SEKALIGUS
  /// Mengosongkan daftar favorit dan menyinkronkannya ke SharedPreferences
  /// --------------------------------------------------------------------------
  Future<void> clearAllFavorites() async {
    _favorites.clear();
    await _saveToPrefs();
    notifyListeners();
  }

  /// Menyisipkan kembali item ke posisi tertentu (Fitur UNDO SnackBar)
  Future<void> insertFavorite(int index, ItemModel item) async {
    if (index >= 0 && index <= _favorites.length) {
      _favorites.insert(index, item);
    } else {
      _favorites.add(item);
    }
    await _saveToPrefs();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // 6. HELPER PRIVATE: SIMPAN KE PREFERENCES
  // ---------------------------------------------------------------------------
  Future<void> _saveToPrefs() async {
    final List<String> jsonStringList = _favorites
        .map((item) => jsonEncode(item.toJson()))
        .toList();

    await PrefsService.setFavoritesJson(jsonStringList);
  }
}
