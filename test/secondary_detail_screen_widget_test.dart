import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template_responsi/models/secondary_model.dart';
import 'package:template_responsi/screens/secondary/secondary_detail_screen.dart';

void main() {
  group('SecondaryDetailScreen Widget Tests', () {
    testWidgets('renders episode details correctly with description and chips', (tester) async {
      final episode = SecondaryModel(
        id: 1,
        name: 'Pilot Episode',
        episode: 'S01E01',
        airDate: 'December 2, 2013',
        description: 'Petualangan pertama Rick dan Morty mencari biji pohon mega.',
        characters: [
          'https://rickandmortyapi.com/api/character/1',
          'https://rickandmortyapi.com/api/character/2',
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SecondaryDetailScreen(item: episode),
        ),
      );

      // Verify AppBar, Header Title, and Specs
      expect(find.text('Pilot Episode'), findsNWidgets(3)); // AppBar + Headline + Specs row
      expect(find.text('S01E01'), findsNWidgets(3)); // Placeholder Header + Chip + Specs row
      expect(find.text('December 2, 2013'), findsNWidgets(2)); // Chip + Specs

      // Verify Description box
      expect(find.text('Deskripsi'), findsOneWidget);
      expect(
        find.text('Petualangan pertama Rick dan Morty mencari biji pohon mega.'),
        findsOneWidget,
      );

      // Verify related items
      expect(find.text('Daftar Terkait (2)'), findsOneWidget);
      expect(find.text('Item #1'), findsOneWidget);
      expect(find.text('Item #2'), findsOneWidget);
    });
  });
}
