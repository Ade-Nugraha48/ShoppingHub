// ==============================================================================
// FILE: lib/main.dart
// PANDUAN: Titik masuk utama aplikasi (Entry Point).
// Menginisialisasi Hive, SharedPreferences, serta MultiProvider (Auth, Theme, Item, & Favorite).
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/favorite_provider.dart';
import 'providers/item_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'services/hive_service.dart';
import 'services/prefs_service.dart';

void main() async {
  // Pastikan binding Flutter sudah siap sebelum inisialisasi async
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Database Lokal Hive (NoSQL)
  await HiveService.init();

  // Inisialisasi SharedPreferences (Sesi, Tema, & Favorit)
  await PrefsService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider Autentikasi & Akun User (Hive & Prefs)
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        // Provider Pengaturan Tema Gelap / Terang (Prefs)
        ChangeNotifierProvider(
          create: (_) => ThemeProvider()..init(),
        ),
        // Provider Data Utama Item & REST API (Rick & Morty)
        ChangeNotifierProvider(
          create: (_) => ItemProvider(),
        ),
        // Provider Daftar Favorit Reaktif (Prefs)
        ChangeNotifierProvider(
          create: (_) => FavoriteProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Universal Explorer - Rick & Morty Responsi',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getLightTheme(themeProvider.primaryColor),
            darkTheme: AppTheme.getDarkTheme(themeProvider.primaryColor),
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
