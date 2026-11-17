// ==============================================================================
// FILE: lib/models/note_model.dart
// PANDUAN: Model Catatan / Ulasan Pribadi per Item (Fitur Kejutan 2).
// Disimpan di Hive Box 'notesBox' dengan key khusus (misal: 'user_itemId').
// Menggunakan Map/JSON serialization agar bebas dari kerumitan build_runner.
// ==============================================================================

class NoteModel {
  // ---------------------------------------------------------------------------
  // 1. ATRIBUT MODEL CATATAN
  // ---------------------------------------------------------------------------
  final String id;          // ID unik catatan (misal: timestamp string)
  final String username;    // Username pemilik catatan
  final int itemId;         // ID Item/Karakter yang diberi ulasan/catatan
  final String title;       // Judul catatan/ulasan
  final String content;     // Isi ulasan atau catatan pribadi
  final double rating;      // Rating pribadi (misal: 1.0 - 5.0)
  final DateTime createdAt; // Waktu pembuatan
  final DateTime? updatedAt;// Waktu pembaruan terakhir

  // ---------------------------------------------------------------------------
  // 2. CONSTRUCTOR
  // ---------------------------------------------------------------------------
  NoteModel({
    required this.id,
    required this.username,
    required this.itemId,
    required this.title,
    required this.content,
    this.rating = 5.0,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // ---------------------------------------------------------------------------
  // 3. FACTORY FROMJSON
  // ---------------------------------------------------------------------------
  factory NoteModel.fromJson(Map<String, dynamic> json) {
    int parseItemId(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double parseRating(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 5.0;
      return 5.0;
    }

    DateTime parseDate(dynamic value) {
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return NoteModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      itemId: parseItemId(json['itemId']),
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      rating: parseRating(json['rating']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? parseDate(json['updatedAt']) : null,
    );
  }

  // ---------------------------------------------------------------------------
  // 4. FACTORY FROMMAP (UNTUK HIVE)
  // ---------------------------------------------------------------------------
  factory NoteModel.fromMap(Map<dynamic, dynamic> map) {
    return NoteModel.fromJson(
      Map<String, dynamic>.from(
        map.map((key, value) => MapEntry(key.toString(), value)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. METHOD TOJSON / TOMAP
  // Mengubah objek menjadi Map<String, dynamic> untuk disimpan ke Hive
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'itemId': itemId,
      'title': title,
      'content': content,
      'rating': rating,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() => toJson();

  // ---------------------------------------------------------------------------
  // 6. COPYWITH (UNTUK EDIT CATATAN)
  // ---------------------------------------------------------------------------
  NoteModel copyWith({
    String? id,
    String? username,
    int? itemId,
    String? title,
    String? content,
    double? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      username: username ?? this.username,
      itemId: itemId ?? this.itemId,
      title: title ?? this.title,
      content: content ?? this.content,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NoteModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'NoteModel(id: $id, itemId: $itemId, title: $title)';
}

