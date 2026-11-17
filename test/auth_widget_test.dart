import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:template_responsi/core/theme/app_theme.dart';
import 'package:template_responsi/models/user_model.dart';
import 'package:template_responsi/providers/auth_provider.dart';
import 'package:template_responsi/providers/theme_provider.dart';
import 'package:template_responsi/providers/favorite_provider.dart';
import 'package:template_responsi/providers/item_provider.dart';
import 'package:template_responsi/screens/auth/login_screen.dart';
import 'package:template_responsi/screens/auth/register_screen.dart';
import 'package:template_responsi/screens/main_nav_screen.dart';
import 'package:template_responsi/screens/splash_screen.dart';
import 'package:template_responsi/services/hive_service.dart';
import 'package:template_responsi/services/prefs_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_widget_suite_');
    await HiveService.init(customPath: tempDir.path);
  });

  setUp(() async {
    await HiveService.clearAll();
    SharedPreferences.setMockInitialValues({});
    await PrefsService.init();
  });

  Widget createTestWidget(Widget child, {AuthProvider? authProvider}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => authProvider ?? AuthProvider(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<ItemProvider>(
          create: (_) => ItemProvider(),
        ),
        ChangeNotifierProvider<FavoriteProvider>(
          create: (_) => FavoriteProvider(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  group('SplashScreen Route Guard Tests', () {
    testWidgets('routes to LoginScreen when user is NOT logged in', (tester) async {
      await tester.pumpWidget(createTestWidget(const SplashScreen()));

      expect(find.text('Universal Explorer'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Selesaikan jeda timer splash (800ms) dan transisi halaman
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Masuk ke Akun'), findsOneWidget);
    });

    testWidgets('routes to MainNavScreen when user IS logged in', (tester) async {
      await tester.runAsync(() async {
        final user = UserModel(
          username: 'active_rick',
          password: 'password123',
          fullName: 'Active Rick Sanchez',
        );
        await HiveService.registerUser(user);
        await PrefsService.setLoggedIn(true);
        await PrefsService.setUsername('active_rick');
      });

      await tester.pumpWidget(createTestWidget(const SplashScreen()));

      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(MainNavScreen), findsOneWidget);
      expect(find.text('Rick & Morty Explorer'), findsOneWidget);
    });
  });

  group('LoginScreen Widget Tests', () {
    testWidgets('displays validation errors on empty fields submission', (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginScreen()));

      await tester.tap(find.text('MASUK'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Username tidak boleh kosong'), findsOneWidget);
      expect(find.text('Password tidak boleh kosong'), findsOneWidget);
    });

    testWidgets('login with valid credentials redirects to MainNavScreen', (tester) async {
      await tester.runAsync(() async {
        final user = UserModel(
          username: 'test_user',
          password: 'password123',
          fullName: 'Test User',
        );
        await HiveService.registerUser(user);
      });

      await tester.pumpWidget(createTestWidget(const LoginScreen()));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'test_user',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );

      await tester.tap(find.text('MASUK'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(MainNavScreen), findsOneWidget);
    });
  });

  group('RegisterScreen Widget Tests', () {
    testWidgets('validates matching passwords', (tester) async {
      await tester.pumpWidget(createTestWidget(const RegisterScreen()));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nama Lengkap'),
        'Beth Smith',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'beth_smith',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Konfirmasi Password'),
        'mismatchedPassword',
      );

      await tester.tap(find.text('DAFTAR SEKARANG'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Password tidak cocok'), findsOneWidget);
    });

    testWidgets('successful registration saves user to Hive', (tester) async {
      await tester.pumpWidget(createTestWidget(const RegisterScreen()));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nama Lengkap'),
        'Jerry Smith',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'jerry_smith',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Konfirmasi Password'),
        'password123',
      );

      await tester.tap(find.text('DAFTAR SEKARANG'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump(const Duration(milliseconds: 300));

      final savedUser = HiveService.getUser('jerry_smith');
      expect(savedUser, isNotNull);
      expect(savedUser?.fullName, 'Jerry Smith');
    });
  });
}
