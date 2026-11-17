import 'package:flutter_test/flutter_test.dart';
import 'package:template_responsi/models/item_model.dart';
import 'package:template_responsi/models/secondary_model.dart';
import 'package:template_responsi/models/user_model.dart';
import 'package:template_responsi/models/note_model.dart';

void main() {
  group('ItemModel Tests', () {
    final sampleJson = {
      'id': 1,
      'name': 'Rick Sanchez',
      'status': 'Alive',
      'species': 'Human',
      'gender': 'Male',
      'image': 'https://rickandmortyapi.com/api/character/avatar/1.jpeg',
      'origin': {'name': 'Earth (C-137)', 'url': 'https://...'},
      'location': {'name': 'Citadel of Ricks', 'url': 'https://...'},
      'episode': [
        'https://rickandmortyapi.com/api/episode/1',
        'https://rickandmortyapi.com/api/episode/2',
      ],
    };

    test('fromJson successfully parses complete Rick & Morty character JSON', () {
      final item = ItemModel.fromJson(sampleJson);

      expect(item.id, 1);
      expect(item.name, 'Rick Sanchez');
      expect(item.status, 'Alive');
      expect(item.species, 'Human');
      expect(item.gender, 'Male');
      expect(item.image, 'https://rickandmortyapi.com/api/character/avatar/1.jpeg');
      expect(item.origin, 'Earth (C-137)');
      expect(item.location, 'Citadel of Ricks');
      expect(item.episode.length, 2);
      expect(item.isAlive, isTrue);
      expect(item.isDead, isFalse);
    });

    test('toJson and fromJson roundtrip preserves data', () {
      final item = ItemModel.fromJson(sampleJson);
      final json = item.toJson();
      final roundtripItem = ItemModel.fromJson(json);

      expect(roundtripItem.id, item.id);
      expect(roundtripItem.name, item.name);
      expect(roundtripItem.origin, item.origin);
      expect(roundtripItem.location, item.location);
      expect(roundtripItem, equals(item));
    });

    test('fromMap safely parses dynamic map from Hive', () {
      final Map<dynamic, dynamic> hiveMap = {
        'id': 2,
        'name': 'Morty Smith',
        'status': 'Alive',
        'species': 'Human',
        'origin': 'Earth (Replacement Dimension)',
        'location': 'Earth',
        'episode': ['ep1', 'ep2'],
      };

      final item = ItemModel.fromMap(hiveMap);
      expect(item.id, 2);
      expect(item.name, 'Morty Smith');
      expect(item.origin, 'Earth (Replacement Dimension)');
    });

    test('fromJson handles null or missing values gracefully', () {
      final item = ItemModel.fromJson({});
      expect(item.id, 0);
      expect(item.name, '');
      expect(item.status, 'unknown');
      expect(item.origin, '');
      expect(item.location, '');
      expect(item.episode, isEmpty);
    });

    test('copyWith updates specified fields', () {
      final item = ItemModel.fromJson(sampleJson);
      final updated = item.copyWith(name: 'Rick Updated', status: 'Dead');

      expect(updated.name, 'Rick Updated');
      expect(updated.status, 'Dead');
      expect(updated.isDead, isTrue);
      expect(updated.id, item.id);
    });
  });

  group('SecondaryModel Tests', () {
    final sampleEpisodeJson = {
      'id': 1,
      'name': 'Pilot',
      'air_date': 'December 2, 2013',
      'episode': 'S01E01',
      'characters': [
        'https://rickandmortyapi.com/api/character/1',
        'https://rickandmortyapi.com/api/character/2',
      ],
      'url': 'https://rickandmortyapi.com/api/episode/1',
    };

    test('fromJson successfully parses episode JSON', () {
      final episode = SecondaryModel.fromJson(sampleEpisodeJson);

      expect(episode.id, 1);
      expect(episode.name, 'Pilot');
      expect(episode.airDate, 'December 2, 2013');
      expect(episode.episode, 'S01E01');
      expect(episode.characters.length, 2);
      expect(episode.url, 'https://rickandmortyapi.com/api/episode/1');
    });

    test('toJson and fromMap roundtrip', () {
      final episode = SecondaryModel.fromJson(sampleEpisodeJson);
      final map = episode.toMap();
      final roundtrip = SecondaryModel.fromMap(map);

      expect(roundtrip.id, episode.id);
      expect(roundtrip.name, episode.name);
      expect(roundtrip.airDate, episode.airDate);
      expect(roundtrip, equals(episode));
    });
  });

  group('UserModel Tests', () {
    test('UserModel serialization and copyWith works properly', () {
      final user = UserModel(
        username: 'andi_test',
        password: 'password123',
        fullName: 'Andi Pratama',
        email: 'andi@example.com',
      );

      final json = user.toJson();
      final fromJsonUser = UserModel.fromJson(json);

      expect(fromJsonUser.username, 'andi_test');
      expect(fromJsonUser.password, 'password123');
      expect(fromJsonUser.fullName, 'Andi Pratama');
      expect(fromJsonUser.email, 'andi@example.com');
      expect(fromJsonUser, equals(user));

      final updated = user.copyWith(fullName: 'Andi Baru');
      expect(updated.fullName, 'Andi Baru');
      expect(updated.username, 'andi_test');
    });

    test('UserModel.fromMap works with Hive dynamic map', () {
      final Map<dynamic, dynamic> hiveMap = {
        'username': 'budi123',
        'password': 'secpass',
        'fullName': 'Budi Santoso',
        'email': 'budi@test.com',
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      };

      final user = UserModel.fromMap(hiveMap);
      expect(user.username, 'budi123');
      expect(user.fullName, 'Budi Santoso');
    });
  });

  group('NoteModel Tests', () {
    test('NoteModel serialization and copyWith works properly', () {
      final note = NoteModel(
        id: 'note_123',
        username: 'andi_test',
        itemId: 1,
        title: 'Karakter Favorit',
        content: 'Rick sangat jenius tapi sinis.',
        rating: 4.8,
      );

      final json = note.toJson();
      final fromJsonNote = NoteModel.fromJson(json);

      expect(fromJsonNote.id, 'note_123');
      expect(fromJsonNote.username, 'andi_test');
      expect(fromJsonNote.itemId, 1);
      expect(fromJsonNote.title, 'Karakter Favorit');
      expect(fromJsonNote.content, 'Rick sangat jenius tapi sinis.');
      expect(fromJsonNote.rating, 4.8);
      expect(fromJsonNote, equals(note));

      final updated = note.copyWith(content: 'Ulasan diperbarui.');
      expect(updated.content, 'Ulasan diperbarui.');
      expect(updated.id, 'note_123');
    });

    test('NoteModel.fromMap works with Hive dynamic map', () {
      final Map<dynamic, dynamic> hiveMap = {
        'id': 'note_456',
        'username': 'andi_test',
        'itemId': 2,
        'title': 'Catatan Morty',
        'content': 'Sering panik.',
        'rating': 3.5,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final note = NoteModel.fromMap(hiveMap);
      expect(note.id, 'note_456');
      expect(note.itemId, 2);
      expect(note.rating, 3.5);
    });
  });
}

