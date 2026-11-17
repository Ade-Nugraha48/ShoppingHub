// ==============================================================================
// FILE: lib/providers/auth_provider.dart
// PANDUAN: State Management autentikasi menggunakan Provider (ChangeNotifier).
// Menangani status login, registrasi akun baru, update profil, dan logout.
// Menghubungkan Hive (penyimpanan akun) dengan SharedPreferences (status sesi).
// ==============================================================================

import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/hive_service.dart';
import '../services/prefs_service.dart';

class AuthProvider extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // 1. STATE VARIABLES
  // ---------------------------------------------------------------------------
  UserModel? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;

  // ---------------------------------------------------------------------------
  // 2. GETTERS (MEMBACA STATE DARI UI)
  // ---------------------------------------------------------------------------
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ---------------------------------------------------------------------------
  // 3. CHECK AUTH STATUS (STARTUP / SPLASH SCREEN)
  // Memeriksa SharedPreferences saat aplikasi pertama dibuka.
  // ---------------------------------------------------------------------------
  Future<bool> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    final savedLoggedIn = PrefsService.isLoggedIn();
    final savedUsername = PrefsService.getUsername();

    if (savedLoggedIn && savedUsername != null && savedUsername.isNotEmpty) {
      // Ambil detail akun dari Hive Box berdasarkan username yang tersimpan
      final user = HiveService.getUser(savedUsername);
      if (user != null) {
        _currentUser = user;
        _isLoggedIn = true;
      } else {
        // Jika data user terhapus dari Hive, reset sesi di SharedPreferences
        _isLoggedIn = false;
        _currentUser = null;
        await PrefsService.clearAuth();
      }
    } else {
      _isLoggedIn = false;
      _currentUser = null;
    }

    _isLoading = false;
    notifyListeners();
    return _isLoggedIn;
  }

  // ---------------------------------------------------------------------------
  // 4. REGISTRASI AKUN BARU
  // Menyimpan data user baru ke Hive Box 'usersBox'.
  // ---------------------------------------------------------------------------
  Future<bool> register({
    required String username,
    required String password,
    required String fullName,
    String email = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanUsername = username.trim();
      final cleanFullName = fullName.trim();

      // Validasi input dasar
      if (cleanUsername.isEmpty || password.isEmpty || cleanFullName.isEmpty) {
        _errorMessage = 'Semua field wajib diisi.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final newUser = UserModel(
        username: cleanUsername,
        password: password,
        fullName: cleanFullName,
        email: email.trim(),
        createdAt: DateTime.now(),
      );

      // Simpan ke Hive via HiveService
      final success = await HiveService.registerUser(newUser);
      if (!success) {
        _errorMessage = 'Username "$cleanUsername" sudah terdaftar. Gunakan yang lain.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal melakukan registrasi: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 5. LOGIN
  // Memvalidasi username & password di Hive, lalu menyimpan sesi ke SharedPreferences.
  // ---------------------------------------------------------------------------
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanUsername = username.trim();

      if (cleanUsername.isEmpty || password.isEmpty) {
        _errorMessage = 'Username dan password tidak boleh kosong.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Validasi kredensial ke Hive
      final user = await HiveService.loginUser(cleanUsername, password);

      if (user != null) {
        _currentUser = user;
        _isLoggedIn = true;

        // Simpan sesi ke SharedPreferences
        await PrefsService.setLoggedIn(true);
        await PrefsService.setUsername(user.username);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Cek apakah username memang tidak ada atau hanya password yang keliru
        final existing = HiveService.getUser(cleanUsername);
        if (existing == null) {
          _errorMessage = 'Username tidak ditemukan. Silakan daftar terlebih dahulu.';
        } else {
          _errorMessage = 'Password salah. Periksa kembali password Anda.';
        }

        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Gagal melakukan login: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 6. LOGOUT
  // Menghapus data sesi di SharedPreferences dan mereset state provider.
  // ---------------------------------------------------------------------------
  Future<void> logout() async {
    _currentUser = null;
    _isLoggedIn = false;
    await PrefsService.clearAuth();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // 7. EDIT PROFIL / GANTI PASSWORD (FITUR KEJUTAN 1)
  // Memperbarui data user yang sedang login di Hive Box.
  // ---------------------------------------------------------------------------
  Future<bool> updateProfile({
    required String fullName,
    String? newPassword,
    String? email,
    String? profileImage,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = _currentUser!.copyWith(
        fullName: fullName.trim(),
        password: (newPassword != null && newPassword.isNotEmpty)
            ? newPassword
            : _currentUser!.password,
        email: email?.trim() ?? _currentUser!.email,
        profileImage: profileImage ?? _currentUser!.profileImage,
      );

      // Simpan ke Hive
      await HiveService.updateUser(updatedUser);
      _currentUser = updatedUser;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui profil: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Memperbarui foto profil user (berupa path lokal dari galeri/kamera atau URL)
  Future<bool> updateProfileImage(String imagePathOrUrl) async {
    if (_currentUser == null) return false;

    try {
      final updatedUser = _currentUser!.copyWith(
        profileImage: imagePathOrUrl.trim(),
      );
      await HiveService.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui foto profil: $e';
      notifyListeners();
      return false;
    }
  }

  /// Menghapus pesan error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

