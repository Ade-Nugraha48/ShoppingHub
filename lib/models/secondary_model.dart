// ==============================================================================
// FILE: lib/models/secondary_model.dart
// PANDUAN: Model untuk tab kedua (Secondary Screen).
// Pada template default ini digunakan untuk menampung data 'Episode'.
// Saat responsi, jika diminta menampilkan data kedua (misal: Kategori, Berita, dll),
// sesuaikan atribut dan parsing JSON di file ini.
// ==============================================================================

class SecondaryModel {
  // ---------------------------------------------------------------------------
  // 1. ATRIBUT MODEL
  // [GANTI DISINI SAAT RESPONSI]
  // Sesuaikan atribut dengan endpoint sekunder dari API soal responsi.
  // ---------------------------------------------------------------------------
  final int id;
  final String name;
  final String airDate;
  final String episode;
  final List<String> characters;
  final String url;
  final String image; // [BARU] Menampung URL gambar jika API kedua memiliki gambar
  final String description; // [BARU] Menampung deskripsi/keterangan jika API kedua memiliki penjelasan

  // ---------------------------------------------------------------------------
  // 2. CONSTRUCTOR
  // ---------------------------------------------------------------------------
  SecondaryModel({
    required this.id,
    required this.name,
    this.airDate = '',
    this.episode = '',
    this.characters = const [],
    this.url = '',
    this.image = '',
    this.description = '',
  });

  // ---------------------------------------------------------------------------
  // 3. FACTORY FROMJSON
  // Mengubah Map/JSON response API menjadi objek SecondaryModel.
  // ---------------------------------------------------------------------------
  factory SecondaryModel.fromJson(Map<String, dynamic> json) {
    // 1. Safe parser untuk integer ID (angka, string angka, maupun UUID)
    int parseId(dynamic value) {
      if (value is int) return value;
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
        return value.hashCode.abs();
      }
      if (value is num) return value.toInt();
      return 0;
    }

    // 2. Safe parser universal untuk teks (String, num, Map {}, List [])
    String parseSafe(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is num || value is bool) return value.toString();
      if (value is Map) {
        for (final key in [
          'name',
          'title',
          'val',
          'value',
          'label',
          'date',
          'air_date',
          'episode',
          'category',
          'desc',
          'description'
        ]) {
          if (value.containsKey(key) && value[key] != null) {
            return parseSafe(value[key]);
          }
        }
        for (final val in value.values) {
          if (val != null) {
            final str = parseSafe(val);
            if (str.isNotEmpty) return str;
          }
        }
        return '';
      }
      if (value is List) {
        if (value.isEmpty) return '';
        return value.map((e) => parseSafe(e)).where((s) => s.isNotEmpty).join(', ');
      }
      return value.toString();
    }

    // 3. Safe parser untuk URL gambar
    String parseSafeImage(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is Map) {
        for (final key in [
          'url',
          'src',
          'path',
          'thumbnail',
          'cover',
          'large',
          'medium',
          'original',
          'link'
        ]) {
          if (value.containsKey(key) && value[key] != null) {
            return parseSafe(value[key]);
          }
        }
      }
      if (value is List && value.isNotEmpty) {
        return parseSafeImage(value.first);
      }
      return value.toString();
    }

    // 4. Safe parser untuk list character URLs
    List<String> parseCharacters(dynamic list) {
      if (list == null || list is! List) return [];
      return list.map((e) => parseSafe(e)).toList();
    }

    return SecondaryModel(
      // [GANTI DISINI] Sesuaikan key JSON dengan response API sekunder
      id: parseId(json['id']),
      name: parseSafe(json['name'] ?? json['title']),
      airDate: parseSafe(json['air_date'] ?? json['date'] ?? json['release_date']),
      episode: parseSafe(json['episode'] ?? json['category'] ?? json['type']),
      characters: parseCharacters(json['characters'] ?? json['cast'] ?? json['items']),
      url: parseSafe(json['url']),
      image: parseSafeImage(
        json['image'] ??
            json['thumbnail'] ??
            json['cover'] ??
            json['pictureId'] ??
            json['picture'] ??
            json['strMealThumb'],
      ),
      description: parseSafe(
        json['description'] ??
            json['overview'] ??
            json['details'] ??
            json['summary'],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. FACTORY FROMMAP (UNTUK HIVE & STORAGE)
  // Membaca dari Map<dynamic, dynamic> tanpa perlu generator build_runner.
  // ---------------------------------------------------------------------------
  factory SecondaryModel.fromMap(Map<dynamic, dynamic> map) {
    return SecondaryModel.fromJson(
      Map<String, dynamic>.from(
        map.map((key, value) => MapEntry(key.toString(), value)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. METHOD TOJSON / TOMAP
  // Mengubah objek kembali ke bentuk Map untuk penyimpanan lokal jika diperlukan.
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'air_date': airDate,
      'episode': episode,
      'characters': characters,
      'url': url,
      'image': image,
      'description': description,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  // ---------------------------------------------------------------------------
  // 6. COPYWITH
  // ---------------------------------------------------------------------------
  SecondaryModel copyWith({
    int? id,
    String? name,
    String? airDate,
    String? episode,
    List<String>? characters,
    String? url,
    String? image,
  }) {
    return SecondaryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      airDate: airDate ?? this.airDate,
      episode: episode ?? this.episode,
      characters: characters ?? this.characters,
      url: url ?? this.url,
      image: image ?? this.image,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SecondaryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SecondaryModel(id: $id, name: $name, episode: $episode)';
}

