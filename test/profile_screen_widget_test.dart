import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:template_responsi/core/theme/app_theme.dart';
import 'package:template_responsi/models/note_model.dart';
import 'package:template_responsi/models/user_model.dart';
import 'package:template_responsi/providers/auth_provider.dart';
import 'package:template_responsi/providers/favorite_provider.dart';
import 'package:template_responsi/providers/theme_provider.dart';
import 'package:template_responsi/screens/profile/profile_screen.dart';
import 'package:template_responsi/services/hive_service.dart';
import 'package:template_responsi/services/prefs_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_profile_suite_');
    await HiveService.init(customPath: tempDir.path);
  });

  setUp(() async {
    await HiveService.clearAll();
    SharedPreferences.setMockInitialValues({});
    await PrefsService.init();
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.clearAllTestValues();
  });

  Widget createProfileTestWidget({
    required AuthProvider authProvider,
    required ThemeProvider themeProvider,
    FavoriteProvider? favoriteProvider,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<FavoriteProvider>(
          create: (_) => favoriteProvider ?? FavoriteProvider(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ProfileScreen(),
      ),
    );
  }

  group('ProfileScreen Widget Tests', () {
    testWidgets('renders user info, statistics, and dark mode switch properly',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final authProvider = AuthProvider();
      final themeProvider = ThemeProvider()..init();

      await tester.runAsync(() async {
        final user = UserModel(
          username: 'rick_c137',
          password: 'password123',
          fullName: 'Rick Sanchez',
          email: 'rick@citadel.com',
        );
        await HiveService.registerUser(user);
        await authProvider.login(username: 'rick_c137', password: 'password123');

        // Tambah 1 catatan di Hive
        final note = NoteModel(
          id: 'note_1',
          username: 'rick_c137',
          itemId: 1,
          title: 'Title',
          content: 'Content',
        );
        await HiveService.saveNote(note);
      });

      await tester.pumpWidget(
        createProfileTestWidget(
          authProvider: authProvider,
          themeProvider: themeProvider,
        ),
      );
      await tester.pump();

      expect(find.text('Profil Pengguna'), findsOneWidget);
      expect(find.text('Rick Sanchez'), findsOneWidget);
      expect(find.text('@rick_c137'), findsOneWidget);
      expect(find.text('rick@citadel.com'), findsOneWidget);
      expect(find.text('Catatan Pribadi'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // 1 catatan pribadi
      expect(find.text('Warna Tema Utama'), findsOneWidget);
      expect(find.text('Mode Gelap (Dark Mode)'), findsOneWidget);
      expect(find.text('KELUAR DARI AKUN'), findsOneWidget);
    });

    testWidgets('toggles Dark Mode switch successfully', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final authProvider = AuthProvider();
      final themeProvider = ThemeProvider()..init();

      await tester.pumpWidget(
        createProfileTestWidget(
          authProvider: authProvider,
          themeProvider: themeProvider,
        ),
      );
      await tester.pump();

      expect(themeProvider.isDarkMode, isFalse);

      // Tekan Switch Dark Mode
      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(themeProvider.isDarkMode, isTrue);
      expect(PrefsService.isDarkMode(), isTrue);
    });

    testWidgets('opens Edit Profile dialog and updates user in Hive', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final authProvider = AuthProvider();
      final themeProvider = ThemeProvider()..init();

      await tester.runAsync(() async {
        final user = UserModel(
          username: 'morty_prime',
          password: 'password123',
          fullName: 'Morty Smith',
          email: 'morty@earth.com',
        );
        await HiveService.registerUser(user);
        await authProvider.login(username: 'morty_prime', password: 'password123');
      });

      await tester.pumpWidget(
        createProfileTestWidget(
          authProvider: authProvider,
          themeProvider: themeProvider,
        ),
      );
      await tester.pump();

      expect(find.text('Morty Smith'), findsOneWidget);

      // Buka dialog edit profil
      await tester.tap(find.text('Edit Profil & Password'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Simpan Perubahan'), findsOneWidget);

      // Ubah nama lengkap
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nama Lengkap'),
        'Morty Smith Updated',
      );

      // Tekan tombol Simpan Perubahan
      await tester.ensureVisible(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump(const Duration(milliseconds: 300));

      // Verifikasi nama ter-update di UI
      expect(find.text('Morty Smith Updated'), findsWidgets);

      // Verifikasi di Hive Box langsung
      final updatedUser = HiveService.getUser('morty_prime');
      expect(updatedUser?.fullName, 'Morty Smith Updated');
    });
  });
}
