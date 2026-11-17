import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:template_responsi/core/theme/app_theme.dart';
import 'package:template_responsi/screens/secondary/secondary_screen.dart';
import 'package:template_responsi/services/api_service.dart';

void main() {
  Widget createSecondaryTestWidget(ApiService apiService) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: SecondaryScreen(apiService: apiService),
    );
  }

  group('SecondaryScreen Widget Tests', () {
    testWidgets('displays list of episodes on successful API fetch', (tester) async {
      final mockClient = MockClient((request) async {
        final mockResponse = {
          'info': {'count': 1, 'pages': 1},
          'results': [
            {
              'id': 1,
              'name': 'Pilot',
              'air_date': 'December 2, 2013',
              'episode': 'S01E01',
              'characters': ['c1', 'c2'],
            }
          ]
        };
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final apiService = ApiService(client: mockClient);

      await tester.pumpWidget(createSecondaryTestWidget(apiService));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Daftar Episode'), findsOneWidget);
      expect(find.text('Pilot'), findsOneWidget);
      expect(find.text('S01E01'), findsOneWidget);
      expect(find.text('December 2, 2013'), findsOneWidget);
      expect(find.text('2 Karakter'), findsOneWidget);
    });

    testWidgets('displays ErrorStateWidget on server error and allows retry', (tester) async {
      int requestCount = 0;

      final mockClient = MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          return http.Response('Server error', 500);
        }
        final mockResponse = {
          'results': [
            {
              'id': 2,
              'name': 'Lawnmower Dog',
              'air_date': 'December 9, 2013',
              'episode': 'S01E02',
              'characters': [],
            }
          ]
        };
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final apiService = ApiService(client: mockClient);

      await tester.pumpWidget(createSecondaryTestWidget(apiService));
      await tester.pump(const Duration(milliseconds: 300));

      // Error ditampilkan
      expect(find.text('Gagal Memuat Data'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);

      // Tekan tombol Coba Lagi
      await tester.tap(find.text('Coba Lagi'));
      await tester.pump(const Duration(milliseconds: 300));

      // Berhasil memuat data
      expect(find.text('Lawnmower Dog'), findsOneWidget);
      expect(find.text('S01E02'), findsOneWidget);
    });
  });
}
