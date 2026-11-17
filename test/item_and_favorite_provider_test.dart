import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:template_responsi/core/constants/api_constants.dart';
import 'package:template_responsi/models/item_model.dart';
import 'package:template_responsi/providers/favorite_provider.dart';
import 'package:template_responsi/providers/item_provider.dart';
import 'package:template_responsi/services/api_service.dart';
import 'package:template_responsi/services/prefs_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PrefsService.init();
  });

  group('FavoriteProvider Tests', () {
    final item1 = ItemModel(
      id: 1,
      name: 'Rick Sanchez',
      status: 'Alive',
      species: 'Human',
    );
    final item2 = ItemModel(
      id: 2,
      name: 'Morty Smith',
      status: 'Alive',
      species: 'Human',
    );

    test('starts with empty list when preferences are empty', () {
      final provider = FavoriteProvider();
      expect(provider.favorites, isEmpty);
      expect(provider.count, 0);
      expect(provider.isFavorite(1), isFalse);
    });

    test('toggleFavorite adds and removes item from favorites', () async {
      final provider = FavoriteProvider();

      // Tambah favorit
      final added = await provider.toggleFavorite(item1);
      expect(added, isTrue);
      expect(provider.count, 1);
      expect(provider.isFavorite(1), isTrue);
      expect(PrefsService.getFavoritesJson().length, 1);

      // Hapus favorit
      final removed = await provider.toggleFavorite(item1);
      expect(removed, isFalse);
      expect(provider.count, 0);
      expect(provider.isFavorite(1), isFalse);
      expect(PrefsService.getFavoritesJson(), isEmpty);
    });

    test('removeFavorite removes by id and insertFavorite restores it (Undo)', () async {
      final provider = FavoriteProvider();
      await provider.toggleFavorite(item1);
      await provider.toggleFavorite(item2);
      expect(provider.count, 2);

      // Swipe to delete / Remove
      await provider.removeFavorite(item1.id);
      expect(provider.count, 1);
      expect(provider.isFavorite(item1.id), isFalse);

      // UNDO / Insert kembali di index 0
      await provider.insertFavorite(0, item1);
      expect(provider.count, 2);
      expect(provider.favorites.first.id, item1.id);
      expect(provider.isFavorite(item1.id), isTrue);
    });

    test('clearAllFavorites empties all favorites and updates SharedPreferences', () async {
      final provider = FavoriteProvider();
      await provider.toggleFavorite(item1);
      await provider.toggleFavorite(item2);
      expect(provider.count, 2);

      await provider.clearAllFavorites();
      expect(provider.count, 0);
      expect(provider.favorites, isEmpty);
      expect(PrefsService.getFavoritesJson(), isEmpty);
    });
  });

  group('ItemProvider Tests', () {
    late ApiService mockApiService;

    setUp(() {
      final mockClient = MockClient((request) async {
        final sampleData = {
          'info': {'count': 2, 'pages': 1},
          'results': [
            {'id': 2, 'name': 'Morty Smith', 'status': 'Alive'},
            {'id': 1, 'name': 'Rick Sanchez', 'status': 'Alive'},
            {'id': 3, 'name': 'Summer Smith', 'status': 'Alive'},
          ]
        };
        return http.Response(jsonEncode(sampleData), 200);
      });
      mockApiService = ApiService(client: mockClient);
    });

    test('initial state is correct', () {
      final provider = ItemProvider(apiService: mockApiService);
      expect(provider.items, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.selectedStatus, ApiConstants.statusAll);
      expect(provider.selectedSort, SortOption.defaultOrder);
    });

    test('fetchItems loads data and applies local sorting', () async {
      final provider = ItemProvider(apiService: mockApiService);
      await provider.fetchItems();

      expect(provider.items.length, 3);
      // Default order: ID 2, ID 1, ID 3
      expect(provider.items[0].name, 'Morty Smith');

      // Sort Ascending (A - Z): Morty -> Rick -> Summer
      provider.setSortOption(SortOption.nameAsc);
      expect(provider.items[0].name, 'Morty Smith');
      expect(provider.items[1].name, 'Rick Sanchez');
      expect(provider.items[2].name, 'Summer Smith');

      // Sort Descending (Z - A): Summer -> Rick -> Morty
      provider.setSortOption(SortOption.nameDesc);
      expect(provider.items[0].name, 'Summer Smith');
      expect(provider.items[1].name, 'Rick Sanchez');
      expect(provider.items[2].name, 'Morty Smith');
    });

    test('resetFilter restores status, query, and sort', () async {
      final provider = ItemProvider(apiService: mockApiService);
      await provider.fetchItems();

      provider.setSortOption(SortOption.nameDesc);
      provider.setStatusFilter(ApiConstants.statusAlive);

      expect(provider.selectedSort, SortOption.nameDesc);
      expect(provider.selectedStatus, ApiConstants.statusAlive);

      provider.resetFilter();
      expect(provider.selectedSort, SortOption.defaultOrder);
      expect(provider.selectedStatus, ApiConstants.statusAll);
    });
  });
}
