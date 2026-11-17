import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:template_responsi/models/user_model.dart';
import 'package:template_responsi/providers/auth_provider.dart';
import 'package:template_responsi/providers/theme_provider.dart';
import 'package:template_responsi/services/hive_service.dart';
import 'package:template_responsi/services/prefs_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_auth_test_');
    await HiveService.init(customPath: tempDir.path);
    SharedPreferences.setMockInitialValues({});
    await PrefsService.init();
  });

  tearDown(() async {
    await HiveService.clearAll();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('HiveService Tests', () {
    test('registerUser successfully saves user and prevents duplicates', () async {
      final user = UserModel(
        username: 'rick123',
        password: 'password123',
        fullName: 'Rick Sanchez',
        email: 'rick@citadel.com',
      );

      final success = await HiveService.registerUser(user);
      expect(success, isTrue);

      final savedUser = HiveService.getUser('rick123');
      expect(savedUser, isNotNull);
      expect(savedUser?.fullName, 'Rick Sanchez');

      // Coba register dengan username yang sama
      final duplicate = await HiveService.registerUser(user);
      expect(duplicate, isFalse);
    });

    test('loginUser authenticates valid credentials and rejects invalid', () async {
      final user = UserModel(
        username: 'morty123',
        password: 'secretPassword',
        fullName: 'Morty Smith',
      );
      await HiveService.registerUser(user);

      // Login berhasil
      final loggedInUser = await HiveService.loginUser('morty123', 'secretPassword');
      expect(loggedInUser, isNotNull);
      expect(loggedInUser?.username, 'morty123');

      // Password salah
      final wrongPass = await HiveService.loginUser('morty123', 'wrong');
      expect(wrongPass, isNull);

      // User tidak ada
      final notFound = await HiveService.loginUser('nonexistent', 'secretPassword');
      expect(notFound, isNull);
    });

    test('updateUser updates user details in Hive', () async {
      final user = UserModel(
        username: 'summer123',
        password: 'pass',
        fullName: 'Summer Smith',
      );
      await HiveService.registerUser(user);

      final updated = user.copyWith(fullName: 'Summer Sanchez-Smith');
      await HiveService.updateUser(updated);

      final retrieved = HiveService.getUser('summer123');
      expect(retrieved?.fullName, 'Summer Sanchez-Smith');
    });
  });

  group('PrefsService Tests', () {
    test('stores and retrieves auth session properly', () async {
      expect(PrefsService.isLoggedIn(), isFalse);
      expect(PrefsService.getUsername(), isNull);

      await PrefsService.setLoggedIn(true);
      await PrefsService.setUsername('rick123');

      expect(PrefsService.isLoggedIn(), isTrue);
      expect(PrefsService.getUsername(), 'rick123');

      await PrefsService.clearAuth();
      expect(PrefsService.isLoggedIn(), isFalse);
      expect(PrefsService.getUsername(), isNull);
    });

    test('stores and retrieves dark mode preference', () async {
      expect(PrefsService.isDarkMode(), isFalse);

      await PrefsService.setDarkMode(true);
      expect(PrefsService.isDarkMode(), isTrue);

      await PrefsService.setDarkMode(false);
      expect(PrefsService.isDarkMode(), isFalse);
    });

    test('stores and checks favorites list', () async {
      final sampleFavoriteJson = '{"id":1,"name":"Rick Sanchez"}';
      expect(PrefsService.getFavoritesJson(), isEmpty);
      expect(PrefsService.isFavorite(1), isFalse);

      await PrefsService.setFavoritesJson([sampleFavoriteJson]);
      expect(PrefsService.getFavoritesJson().length, 1);
      expect(PrefsService.isFavorite(1), isTrue);
      expect(PrefsService.isFavorite(2), isFalse);
    });
  });

  group('AuthProvider Tests', () {
    late AuthProvider authProvider;

    setUp(() {
      authProvider = AuthProvider();
    });

    test('register succeeds with valid data', () async {
      final success = await authProvider.register(
        username: 'beth123',
        password: 'password',
        fullName: 'Beth Smith',
        email: 'beth@hospital.com',
      );

      expect(success, isTrue);
      expect(authProvider.errorMessage, isNull);
    });

    test('register fails with duplicate username', () async {
      await authProvider.register(
        username: 'jerry123',
        password: 'password',
        fullName: 'Jerry Smith',
      );

      final secondAttempt = await authProvider.register(
        username: 'jerry123',
        password: 'otherPassword',
        fullName: 'Jerry Clone',
      );

      expect(secondAttempt, isFalse);
      expect(authProvider.errorMessage, contains('sudah terdaftar'));
    });

    test('login succeeds and sets session', () async {
      await authProvider.register(
        username: 'birdperson',
        password: 'password123',
        fullName: 'Birdperson',
      );

      final loginSuccess = await authProvider.login(
        username: 'birdperson',
        password: 'password123',
      );

      expect(loginSuccess, isTrue);
      expect(authProvider.isLoggedIn, isTrue);
      expect(authProvider.currentUser?.fullName, 'Birdperson');
      expect(PrefsService.isLoggedIn(), isTrue);
      expect(PrefsService.getUsername(), 'birdperson');
    });

    test('login fails on invalid password', () async {
      await authProvider.register(
        username: 'birdperson2',
        password: 'password123',
        fullName: 'Birdperson 2',
      );

      final loginSuccess = await authProvider.login(
        username: 'birdperson2',
        password: 'wrongpassword',
      );

      expect(loginSuccess, isFalse);
      expect(authProvider.isLoggedIn, isFalse);
      expect(authProvider.errorMessage, contains('Password salah'));
    });

    test('logout clears user state and session', () async {
      await authProvider.register(
        username: 'squanchy',
        password: 'pass',
        fullName: 'Squanchy',
      );
      await authProvider.login(username: 'squanchy', password: 'pass');
      expect(authProvider.isLoggedIn, isTrue);

      await authProvider.logout();
      expect(authProvider.isLoggedIn, isFalse);
      expect(authProvider.currentUser, isNull);
      expect(PrefsService.isLoggedIn(), isFalse);
    });

    test('checkAuthStatus restores session from SharedPreferences and Hive', () async {
      // Setup user in Hive and session in Prefs
      final user = UserModel(
        username: 'portal_gun',
        password: 'secret',
        fullName: 'Portal Gun Owner',
      );
      await HiveService.registerUser(user);
      await PrefsService.setLoggedIn(true);
      await PrefsService.setUsername('portal_gun');

      // Provider baru mengecek status auth
      final newAuthProvider = AuthProvider();
      final isLoggedIn = await newAuthProvider.checkAuthStatus();

      expect(isLoggedIn, isTrue);
      expect(newAuthProvider.isLoggedIn, isTrue);
      expect(newAuthProvider.currentUser?.username, 'portal_gun');
    });

    test('updateProfileImage updates user in AuthProvider and Hive', () async {
      await authProvider.register(
        username: 'beth_smith',
        password: 'password123',
        fullName: 'Beth Smith',
      );
      await authProvider.login(username: 'beth_smith', password: 'password123');
      await authProvider.updateProfileImage('https://example.com/avatar.jpg');

      expect(authProvider.currentUser?.profileImage, 'https://example.com/avatar.jpg');
      final updated = HiveService.getUser('beth_smith');
      expect(updated?.profileImage, 'https://example.com/avatar.jpg');
    });
  });

  group('ThemeProvider Tests', () {
    test('ThemeProvider toggles theme and persists to PrefsService', () async {
      final themeProvider = ThemeProvider();
      themeProvider.init();

      expect(themeProvider.isDarkMode, isFalse);

      await themeProvider.toggleTheme(true);
      expect(themeProvider.isDarkMode, isTrue);
      expect(PrefsService.isDarkMode(), isTrue);

      await themeProvider.toggleTheme(false);
      expect(themeProvider.isDarkMode, isFalse);
      expect(PrefsService.isDarkMode(), isFalse);
    });

    test('ThemeProvider changes primary color and persists to PrefsService', () async {
      final themeProvider = ThemeProvider();
      themeProvider.init();

      final emeraldGreen = const Color(0xFF10B981);
      await themeProvider.setPrimaryColor(emeraldGreen);

      expect(themeProvider.primaryColor, emeraldGreen);
      expect(PrefsService.getPrimaryColorValue(), emeraldGreen.toARGB32());
    });
  });
}

