import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:template_responsi/models/note_model.dart';
import 'package:template_responsi/services/hive_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_notes_test_');
    await HiveService.init(customPath: tempDir.path);
  });

  tearDown(() async {
    await HiveService.clearAll();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('HiveService Notes CRUD Tests', () {
    test('saveNote and getNote creates and retrieves a note properly', () async {
      final note = NoteModel(
        id: 'rick123_1',
        username: 'rick123',
        itemId: 1,
        title: 'Karakter Utama',
        content: 'Sangat cerdas dan eksentrik.',
        rating: 5.0,
      );

      // CREATE
      await HiveService.saveNote(note);

      // READ
      final retrieved = HiveService.getNote('rick123_1');
      expect(retrieved, isNotNull);
      expect(retrieved?.id, 'rick123_1');
      expect(retrieved?.title, 'Karakter Utama');
      expect(retrieved?.rating, 5.0);
    });

    test('saveNote updates existing note data', () async {
      final note = NoteModel(
        id: 'morty123_2',
        username: 'morty123',
        itemId: 2,
        title: 'Catatan Awal',
        content: 'Isi awal.',
        rating: 3.0,
      );
      await HiveService.saveNote(note);

      // UPDATE
      final updatedNote = note.copyWith(
        title: 'Catatan Baru',
        content: 'Isi ulasan yang sudah diperbarui.',
        rating: 4.5,
      );
      await HiveService.saveNote(updatedNote);

      final retrieved = HiveService.getNote('morty123_2');
      expect(retrieved?.title, 'Catatan Baru');
      expect(retrieved?.content, 'Isi ulasan yang sudah diperbarui.');
      expect(retrieved?.rating, 4.5);
    });

    test('deleteNote removes note from Hive Box', () async {
      final note = NoteModel(
        id: 'beth_3',
        username: 'beth',
        itemId: 3,
        title: 'Catatan Beth',
        content: 'Review.',
      );
      await HiveService.saveNote(note);
      expect(HiveService.getNote('beth_3'), isNotNull);

      // DELETE
      await HiveService.deleteNote('beth_3');
      expect(HiveService.getNote('beth_3'), isNull);
    });

    test('getUserNotes and getNotesByItem filters notes correctly', () async {
      final note1 = NoteModel(
        id: 'andi_1',
        username: 'andi',
        itemId: 1,
        title: 'Note 1',
        content: 'Content 1',
      );
      final note2 = NoteModel(
        id: 'andi_2',
        username: 'andi',
        itemId: 2,
        title: 'Note 2',
        content: 'Content 2',
      );
      final note3 = NoteModel(
        id: 'budi_1',
        username: 'budi',
        itemId: 1,
        title: 'Note 3',
        content: 'Content 3',
      );

      await HiveService.saveNote(note1);
      await HiveService.saveNote(note2);
      await HiveService.saveNote(note3);

      final andiNotes = HiveService.getUserNotes('andi');
      expect(andiNotes.length, 2);

      final item1Notes = HiveService.getNotesByItem(1);
      expect(item1Notes.length, 2);

      final item1AndiNotes = HiveService.getNotesByItem(1, username: 'andi');
      expect(item1AndiNotes.length, 1);
      expect(item1AndiNotes.first.id, 'andi_1');
    });
  });
}
