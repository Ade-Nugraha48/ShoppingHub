// ==============================================================================
// FILE: lib/services/hive_service.dart
// PANDUAN: Service terpusat untuk operasi database NoSQL lokal Hive.
// 
// CARA KERJA HIVE:
// 1. Hive bekerja seperti kamus (Key-Value database) berkecepatan tinggi.
// 2. Data disimpan dalam 'Box' (mirip tabel di SQL atau koleksi di MongoDB).
// 3. Agar tidak perlu menjalankan 'build_runner' saat ujian responsi,
//    seluruh objek disimpan dan dibaca dalam bentuk Map (JSON).
// ==============================================================================

import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/note_model.dart';

class HiveService {
  // ---------------------------------------------------------------------------
  // 1. NAMA HIVE BOXES
  // ---------------------------------------------------------------------------
  static const String usersBoxName = 'usersBox'; // Box untuk menyimpan akun user
  static const String notesBoxName = 'notesBox'; // Box untuk catatan/ulasan item

  // ---------------------------------------------------------------------------
  // 2. INISIALISASI HIVE & BUKA BOX
  // Dipanggil sekali saat aplikasi pertama kali berjalan di main.dart
  // ---------------------------------------------------------------------------
  static Future<void> init({String? customPath}) async {
    // Jika customPath diberikan (misal pada unit test), inisialisasi dengan path tersebut.
    // Jika tidak, gunakan Hive.initFlutter() bawaan.
    if (customPath != null) {
      Hive.init(customPath);
    } else {
      await Hive.initFlutter();
    }

    // Buka Box users jika belum terbuka
    if (!Hive.isBoxOpen(usersBoxName)) {
      await Hive.openBox(usersBoxName);
    }

    // Buka Box notes jika belum terbuka
    if (!Hive.isBoxOpen(notesBoxName)) {
      await Hive.openBox(notesBoxName);
    }
  }

  // ---------------------------------------------------------------------------
  // 3. GETTER BOXES
  // Mempermudah akses instan ke Hive Box yang sedang aktif
  // ---------------------------------------------------------------------------
  static Box get usersBox => Hive.box(usersBoxName);
  static Box get notesBox => Hive.box(notesBoxName);

  // ===========================================================================
  // 4. OPERASI USER (AUTH & PROFIL)
  // ===========================================================================

  /// Mendaftarkan user baru ke dalam Hive Box.
  /// Mengembalikan true jika berhasil, atau false jika username sudah terpakai.
  static Future<bool> registerUser(UserModel user) async {
    // CARA KERJA: Cek apakah key (username) sudah ada di dalam box
    if (usersBox.containsKey(user.username)) {
      return false; // Username duplikat
    }

    // CARA KERJA: Simpan data UserModel dalam bentuk Map<String, dynamic>
    // dengan key = user.username
    await usersBox.put(user.username, user.toJson());
    return true;
  }

  /// Memvalidasi login user berdasarkan username dan password.
  /// Mengembalikan objek UserModel jika valid, atau null jika gagal.
  static Future<UserModel?> loginUser(String username, String password) async {
    // CARA KERJA: Ambil Map berdasarkan key (username)
    final rawData = usersBox.get(username);
    if (rawData == null) return null; // User tidak ditemukan

    // Ubah Map dari Hive menjadi objek UserModel
    final user = UserModel.fromMap(rawData as Map);

    // Cek kecocokan password
    if (user.password == password) {
      return user;
    }
    return null; // Password salah
  }

  /// Mengambil data user berdasarkan username
  static UserModel? getUser(String username) {
    final rawData = usersBox.get(username);
    if (rawData == null) return null;
    return UserModel.fromMap(rawData as Map);
  }

  /// Memperbarui profil atau password user yang sudah terdaftar
  static Future<void> updateUser(UserModel user) async {
    // put() akan otomatis menimpa (overwrite) data lama jika key sudah ada
    await usersBox.put(user.username, user.toJson());
  }

  /// Menghapus akun user dari Hive
  static Future<void> deleteUser(String username) async {
    await usersBox.delete(username);
  }

  /// Mengambil seluruh daftar user terdaftar (berguna untuk debug / admin)
  static List<UserModel> getAllUsers() {
    return usersBox.values
        .map((data) => UserModel.fromMap(data as Map))
        .toList();
  }

  // ===========================================================================
  // 5. OPERASI CATATAN / ULASAN PRIBADI (FITUR KEJUTAN 2)
  // ===========================================================================

  /// Menyimpan catatan/ulasan pribadi ke Hive Box
  static Future<void> saveNote(NoteModel note) async {
    // Gunakan note.id sebagai key penyimpanan
    await notesBox.put(note.id, note.toJson());
  }

  /// Mengambil seluruh catatan untuk item tertentu (opsional difilter per user aktif)
  static List<NoteModel> getNotesByItem(int itemId, {String? username}) {
    final allNotes = notesBox.values
        .map((data) => NoteModel.fromMap(data as Map))
        .where((note) => note.itemId == itemId);

    if (username != null && username.isNotEmpty) {
      return allNotes.where((note) => note.username == username).toList();
    }
    return allNotes.toList();
  }

  /// Mengambil satu catatan berdasarkan ID catatan
  static NoteModel? getNote(String noteId) {
    final rawData = notesBox.get(noteId);
    if (rawData == null) return null;
    return NoteModel.fromMap(rawData as Map);
  }

  /// Menghapus catatan berdasarkan ID catatan
  static Future<void> deleteNote(String noteId) async {
    await notesBox.delete(noteId);
  }

  /// Mengambil semua catatan milik user tertentu
  static List<NoteModel> getUserNotes(String username) {
    return notesBox.values
        .map((data) => NoteModel.fromMap(data as Map))
        .where((note) => note.username == username)
        .toList();
  }

  // ===========================================================================
  // 6. BERSIHKAN DATA
  // ===========================================================================

  /// Menghapus seluruh data dalam semua box (berguna saat reset atau testing)
  static Future<void> clearAll() async {
    await usersBox.clear();
    await notesBox.clear();
  }
}

