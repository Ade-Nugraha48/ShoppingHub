import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:template_responsi/core/theme/app_theme.dart';
import 'package:template_responsi/models/item_model.dart';
import 'package:template_responsi/providers/favorite_provider.dart';
import 'package:template_responsi/screens/favorite/favorite_screen.dart';
import 'package:template_responsi/services/prefs_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PrefsService.init();
  });

  final sampleItem = ItemModel(
    id: 1,
    name: 'Rick Sanchez',
    status: 'Alive',
    species: 'Human',
    gender: 'Male',
  );

  Widget createFavoriteTestWidget(FavoriteProvider favoriteProvider) {
    return ChangeNotifierProvider<FavoriteProvider>.value(
      value: favoriteProvider,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const FavoriteScreen(),
      ),
    );
  }

  group('FavoriteScreen Widget Tests', () {
    testWidgets('displays EmptyStateWidget when no items in favorites', (tester) async {
      final provider = FavoriteProvider();

      await tester.pumpWidget(createFavoriteTestWidget(provider));
      await tester.pump();

      expect(find.text('Belum Ada Favorit'), findsOneWidget);
      expect(
        find.text('Tandai karakter favorit Anda dengan menekan ikon hati di halaman utama.'),
        findsOneWidget,
      );
    });

    testWidgets('displays list of favorites when items exist', (tester) async {
      final provider = FavoriteProvider();
      await provider.toggleFavorite(sampleItem);

      await tester.pumpWidget(createFavoriteTestWidget(provider));
      await tester.pump();

      expect(find.text('Rick Sanchez'), findsOneWidget);
      expect(find.text('Human • Male'), findsOneWidget);
      expect(find.text('Status: Alive'), findsOneWidget);
    });

    testWidgets('dismissible swipe to delete removes item and UNDO button restores it',
        (tester) async {
      final provider = FavoriteProvider();
      await provider.toggleFavorite(sampleItem);

      await tester.pumpWidget(createFavoriteTestWidget(provider));
      await tester.pump();

      expect(find.text('Rick Sanchez'), findsOneWidget);

      // Lakukan gesture swipe ke kiri (endToStart)
      await tester.fling(find.byType(Dismissible), const Offset(-500, 0), 1000.0);
      await tester.pumpAndSettle();

      // Verifikasi item terhapus dari provider & SnackBar UNDO muncul
      expect(provider.isFavorite(sampleItem.id), isFalse);
      expect(find.text('Rick Sanchez dihapus dari favorit'), findsOneWidget);
      expect(find.text('UNDO'), findsOneWidget);

      // Tekan tombol UNDO
      await tester.tap(find.text('UNDO'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifikasi item dipulihkan
      expect(provider.isFavorite(sampleItem.id), isTrue);
      expect(find.text('Rick Sanchez'), findsOneWidget);
    });
  });
}
