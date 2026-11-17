import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:template_responsi/core/theme/app_theme.dart';
import 'package:template_responsi/models/item_model.dart';
import 'package:template_responsi/models/user_model.dart';
import 'package:template_responsi/providers/auth_provider.dart';
import 'package:template_responsi/providers/favorite_provider.dart';
import 'package:template_responsi/providers/theme_provider.dart';
import 'package:template_responsi/screens/detail/detail_screen.dart';
import 'package:template_responsi/services/hive_service.dart';
import 'package:template_responsi/services/prefs_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_detail_suite_');
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

  final sampleItem = ItemModel(
    id: 1,
    name: 'Rick Sanchez',
    status: 'Alive',
    species: 'Human',
    gender: 'Male',
    origin: 'Earth (C-137)',
    location: 'Citadel of Ricks',
    episode: ['ep1', 'ep2'],
  );

  Widget createDetailTestWidget(ItemModel item, {AuthProvider? authProvider}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => authProvider ?? AuthProvider(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<FavoriteProvider>(
          create: (_) => FavoriteProvider(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: DetailScreen(item: item),
      ),
    );
  }

  group('DetailScreen Widget Tests', () {
    testWidgets('renders all character details properly', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;

      final itemWithDesc = sampleItem.copyWith(
        description: 'Rick Sanchez adalah ilmuwan jenius.',
      );

      await tester.pumpWidget(createDetailTestWidget(itemWithDesc));
      await tester.pump();

      expect(find.text('Rick Sanchez'), findsWidgets);
      expect(find.text('Alive'), findsOneWidget);
      expect(find.text('Human'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Earth (C-137)'), findsOneWidget);
      expect(find.text('Citadel of Ricks'), findsOneWidget);
      expect(find.text('2 Episode'), findsOneWidget);
      expect(find.text('Deskripsi'), findsOneWidget);
      expect(find.text('Rick Sanchez adalah ilmuwan jenius.'), findsOneWidget);
      expect(find.text('Catatan Pribadi'), findsOneWidget);
    });

    testWidgets('toggles favorite button in AppBar', (tester) async {
      final favProvider = FavoriteProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
            ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
            ChangeNotifierProvider<FavoriteProvider>.value(value: favProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: DetailScreen(item: sampleItem),
          ),
        ),
      );
      await tester.pump();

      expect(favProvider.isFavorite(sampleItem.id), isFalse);

      // Tekan tombol Favorite di AppBar
      await tester.tap(find.byTooltip('Tambah ke Favorit'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(favProvider.isFavorite(sampleItem.id), isTrue);
    });

    testWidgets('creates note in Hive and displays it in DetailScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;

      final authProvider = AuthProvider();
      await tester.runAsync(() async {
        final user = UserModel(
          username: 'user_tester',
          password: 'pass',
          fullName: 'Tester',
        );
        await HiveService.registerUser(user);
        await authProvider.login(username: 'user_tester', password: 'pass');
      });

      await tester.pumpWidget(
        createDetailTestWidget(sampleItem, authProvider: authProvider),
      );
      await tester.pump();

      // Isi form catatan
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Judul Catatan / Ulasan'),
        'Karakter Favorit Saya',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Isi Catatan'),
        'Sangat menghibur dan plotnya luar biasa.',
      );

      // Tekan tombol Simpan Catatan
      await tester.tap(find.text('Simpan Catatan'));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump(const Duration(milliseconds: 300));

      // Verifikasi catatan tersimpan di Hive dan tampil di UI
      expect(find.text('Karakter Favorit Saya'), findsOneWidget);
      expect(find.text('Sangat menghibur dan plotnya luar biasa.'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

      // Verifikasi di Hive Box langsung
      final savedNote = HiveService.notesBox.get('user_tester_1');
      expect(savedNote, isNotNull);
    });
  });
}
