import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:template_responsi/core/constants/api_constants.dart';
import 'package:template_responsi/services/api_service.dart';

void main() {
  group('ApiConstants Tests', () {
    test('charactersUri builds expected URI with search, status, and page', () {
      final uri = ApiConstants.charactersUri(
        page: 2,
        search: 'rick',
        status: 'alive',
      );

      expect(uri.path, contains('/character'));
      expect(uri.queryParameters['page'], '2');
      expect(uri.queryParameters['name'], 'rick');
      expect(uri.queryParameters['status'], 'alive');
    });

    test('charactersUri ignores All filter status', () {
      final uri = ApiConstants.charactersUri(page: 1, status: 'All');
      expect(uri.queryParameters.containsKey('status'), isFalse);
    });

    test('characterDetailUri builds valid detail URI', () {
      final uri = ApiConstants.characterDetailUri(42);
      expect(uri.toString(), '${ApiConstants.baseUrl}/character/42');
    });

    test('episodesUri builds valid list URI', () {
      final uri = ApiConstants.episodesUri(page: 3, search: 'pilot');
      expect(uri.path, contains('/episode'));
      expect(uri.queryParameters['page'], '3');
      expect(uri.queryParameters['name'], 'pilot');
    });
  });

  group('ApiService Tests', () {
    test('getItems returns list of ItemModel when HTTP response is 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/character'));
        final responseData = {
          'info': {'count': 1, 'pages': 1},
          'results': [
            {
              'id': 1,
              'name': 'Rick Sanchez',
              'status': 'Alive',
              'species': 'Human',
              'gender': 'Male',
              'origin': {'name': 'Earth'},
              'location': {'name': 'Citadel'},
              'episode': ['ep1'],
            }
          ]
        };
        return http.Response(jsonEncode(responseData), 200);
      });

      final apiService = ApiService(client: mockClient);
      final items = await apiService.getItems(page: 1);

      expect(items.length, 1);
      expect(items.first.id, 1);
      expect(items.first.name, 'Rick Sanchez');
      expect(items.first.isAlive, isTrue);
    });

    test('getItems returns empty list on 404 "There is nothing here"', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'There is nothing here'}),
          404,
        );
      });

      final apiService = ApiService(client: mockClient);
      final items = await apiService.getItems(search: 'nonexistent_name');

      expect(items, isEmpty);
    });

    test('getItems throws ApiException on 500 server error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final apiService = ApiService(client: mockClient);

      expect(
        () async => await apiService.getItems(),
        throwsA(isA<ApiException>()),
      );
    });

    test('getItemDetail returns ItemModel on 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/character/1'));
        final detailData = {
          'id': 1,
          'name': 'Rick Sanchez',
          'status': 'Alive',
          'species': 'Human',
        };
        return http.Response(jsonEncode(detailData), 200);
      });

      final apiService = ApiService(client: mockClient);
      final item = await apiService.getItemDetail(1);

      expect(item.id, 1);
      expect(item.name, 'Rick Sanchez');
    });

    test('getItemDetail throws ApiException on 404', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(client: mockClient);

      expect(
        () async => await apiService.getItemDetail(99999),
        throwsA(isA<ApiException>()),
      );
    });

    test('getSecondaryItems returns list of SecondaryModel on 200', () async {
      final mockClient = MockClient((request) async {
        final episodeData = {
          'results': [
            {
              'id': 1,
              'name': 'Pilot',
              'air_date': 'December 2, 2013',
              'episode': 'S01E01',
              'characters': ['char1'],
            }
          ]
        };
        return http.Response(jsonEncode(episodeData), 200);
      });

      final apiService = ApiService(client: mockClient);
      final episodes = await apiService.getSecondaryItems(page: 1);

      expect(episodes.length, 1);
      expect(episodes.first.name, 'Pilot');
      expect(episodes.first.episode, 'S01E01');
    });

    test('getSecondaryItemDetail returns SecondaryModel on 200', () async {
      final mockClient = MockClient((request) async {
        final episodeData = {
          'id': 1,
          'name': 'Pilot',
          'air_date': 'December 2, 2013',
          'episode': 'S01E01',
        };
        return http.Response(jsonEncode(episodeData), 200);
      });

      final apiService = ApiService(client: mockClient);
      final episode = await apiService.getSecondaryItemDetail(1);

      expect(episode.id, 1);
      expect(episode.name, 'Pilot');
    });
  });
}

