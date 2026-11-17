// ==============================================================================
// FILE: lib/models/item_model.dart
// ------------------------------------------------------------------------------
// PANDUAN PEMULA - LANGKAH 2:
// Model adalah "cetakan kue" untuk data yang kamu terima dari API.
// Ketika soal responsi baru keluar:
// 1. Buka URL API di browser untuk melihat nama-nama kolom/key JSON-nya.
// 2. Sesuaikan atribut class ini agar cocok dengan nama kolom tersebut.
//
// CONTOH NYATA JIKA SOAL DIGANTI MENJADI PRODUK TOKO ONLINE (DummyJSON / FakeStore):
// - json['id']          -> final int id;
// - json['title']       -> final String name; (atau ganti jadi title)
// - json['price']       -> final double price;
// - json['description'] -> final String description;
// - json['category']    -> final String category;
// - json['thumbnail']   -> final String image;
// ==============================================================================

class ItemModel {
  // ---------------------------------------------------------------------------
  // [GANTI DISINI 1] ATRIBUT MODEL
  // ---------------------------------------------------------------------------
  // Tentukan variabel apa saja yang ingin kamu simpan dan tampilkan di UI.
  // Tips: Gunakan int untuk ID, String untuk teks, double untuk angka desimal/harga.
  // ---------------------------------------------------------------------------
  final int id;
  final String name;      // Bisa digunakan untuk 'title', 'judul', atau 'nama'
  final String status;    // Bisa diganti 'category', 'status', atau 'genre'
  final String species;   // Bisa diganti 'brand', 'penulis', atau 'author'
  final String gender;    // Bisa diganti 'price', 'rating', atau field lain
  final String image;     // URL gambar (thumbnail, poster, avatar)
  final String origin;    // Deskripsi asal atau detail tambahan
  final String location;  // Lokasi atau informasi pendukung lainnya
  final String description; // [BARU] Deskripsi panjang (description, overview, synopsis)
  final List<String> episode; // List array jika ada (misal tags, images, dll)

  // ---------------------------------------------------------------------------
  // [GANTI DISINI 2] CONSTRUCTOR
  // ---------------------------------------------------------------------------
  // Berikan nilai default (misal: = '', = 0) agar tidak error saat data kosong.
  // ---------------------------------------------------------------------------
  ItemModel({
    required this.id,
    required this.name,
    this.status = 'unknown',
    this.species = '',
    this.gender = '',
    this.image = '',
    this.origin = '',
    this.location = '',
    this.description = '',
    this.episode = const [],
  });

  // ---------------------------------------------------------------------------
  // [GANTI DISINI 3] FACTORY FROMJSON (MAPPING DARI INTERNET KE DART)
  // ---------------------------------------------------------------------------
  // Fungsi ini membaca Map hasil download dari internet lalu mengubahnya jadi objek.
  //
  // TIPS ANTI CRASH (NULL SAFETY):
  // - Selalu gunakan `?? ''` untuk String (jika data null, otomatis jadi teks kosong).
  // - Gunakan `(json['price'] as num?)?.toDouble() ?? 0.0` untuk angka desimal.
  // - Gunakan `json['key']?.toString() ?? ''` jika ragu tipe datanya String atau bukan.
  // ---------------------------------------------------------------------------
  factory ItemModel.fromJson(Map<String, dynamic> json) {
    // -------------------------------------------------------------------------
    // HELPER UNIVERSAL CERDAS: MENGABAIKAN BERSARANG & MENJAMIN TIPE DATA AMAN
    // -------------------------------------------------------------------------
    // Apapun bentuk datanya di JSON (String, int, double, Map {}, atau List []),
    // fungsi di bawah ini otomatis mengekstrak teks bersihnya tanpa pernah error!
    // -------------------------------------------------------------------------

    // 1. Helper aman untuk ID (angka, string angka, maupun UUID string)
    int parseId(dynamic value) {
      if (value is int) return value;
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
        return value.hashCode.abs(); // UUID string diubah jadi ID integer unik positif
      }
      if (value is num) return value.toInt();
      return 0;
    }

    // 2. Helper Universal untuk Teks Bersarang (Map/List/String/num/bool)
    String parseSafe(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is num || value is bool) return value.toString();
      if (value is Map) {
        // Otomatis cari key umum yang ada di dalam objek bersarang { ... }
        for (final key in [
          'name',
          'title',
          'val',
          'value',
          'label',
          'city',
          'address',
          'desc',
          'description'
        ]) {
          if (value.containsKey(key) && value[key] != null) {
            return parseSafe(value[key]);
          }
        }
        // Jika tidak ada key di atas, ambil string pertama dari Map
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
        // Gabungkan list jadi satu string koma (misal: "Action, Adventure")
        return value.map((e) => parseSafe(e)).where((s) => s.isNotEmpty).join(', ');
      }
      return value.toString();
    }

    // 3. Helper Universal untuk URL Gambar (String, Map {url, src, ...}, atau List)
    String parseSafeImage(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is Map) {
        for (final key in [
          'url',
          'src',
          'path',
          'thumbnail',
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

    // 4. Helper untuk menangani list / array asli (misal daftar episode)
    List<String> parseEpisodeList(dynamic list) {
      if (list == null || list is! List) return [];
      return list.map((e) => parseSafe(e)).toList();
    }

    // Mencari deskripsi asli dari API (mendukung berbagai macam nama properti di JSON)
    final apiDescription = parseSafe(
      json['description'] ??
          json['desc'] ??
          json['overview'] ??
          json['synopsis'] ??
          json['detail'] ??
          json['details'] ??
          json['summary'] ??
          json['bio'] ??
          json['content'] ??
          json['about'],
    );

    return ItemModel(
      // [COCOKKAN KEY DI SINI] Nama di dalam kurung siku ['...'] harus sama persis dengan JSON API
      id: parseId(json['id']),
      name: parseSafe(json['name'] ?? json['title']),
      status: parseSafe(json['status'] ?? json['category'] ?? json['city'] ?? 'unknown'),
      species: parseSafe(json['species'] ?? json['brand'] ?? json['cuisine']),
      gender: parseSafe(json['gender'] ?? json['price'] ?? json['rating']),
      image: parseSafeImage(
        json['image'] ??
            json['thumbnail'] ??
            json['pictureId'] ??
            json['strMealThumb'],
      ),
      origin: parseSafe(json['origin']),
      location: parseSafe(json['location']).isNotEmpty
          ? parseSafe(json['location'])
          : parseSafe(json['city'] ?? json['address']),
      // -----------------------------------------------------------------------
      // [LOGIKA DESKRIPSI OTOMATIS]:
      // 1. Jika API baru ADA deskripsinya (description, overview, synopsis, dll),
      //    maka OTOMATIS deskripsi asli dari API tersebut yang akan dipakai!
      // 2. Jika API TIDAK ADA deskripsinya (seperti Rick & Morty),
      //    maka otomatis memakai kalimat buatan: "(nama) adalah entitas..."
      // -----------------------------------------------------------------------
      description: apiDescription.isNotEmpty
          ? apiDescription
          : (json['species'] != null
              ? '${parseSafe(json['name']).isNotEmpty ? parseSafe(json['name']) : 'Karakter ini'} adalah entitas dengan status ${parseSafe(json['status']).isNotEmpty ? parseSafe(json['status']) : 'unknown'} dan spesies ${parseSafe(json['species']).isNotEmpty ? parseSafe(json['species']) : 'unknown'}, yang tercatat berasal dari ${parseSafe(json['origin']).isNotEmpty ? parseSafe(json['origin']) : 'tempat yang tidak diketahui'}.'
              : ''),
      episode: parseEpisodeList(json['episode']),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. FACTORY FROMMAP (UNTUK PENYIMPANAN LOCAL HIVE & SHARED PREFERENCES)
  // ---------------------------------------------------------------------------
  // Tidak perlu diubah! Sudah otomatis mengubah Map lokal ke format yang benar.
  // ---------------------------------------------------------------------------
  factory ItemModel.fromMap(Map<dynamic, dynamic> map) {
    return ItemModel.fromJson(
      Map<String, dynamic>.from(
        map.map((key, value) => MapEntry(key.toString(), value)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // [GANTI DISINI 4] METHOD TOJSON (MENYIMPAN KEMBALI KE MAP)
  // ---------------------------------------------------------------------------
  // Pastikan seluruh atribut yang kamu buat di atas didaftarkan di sini.
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'species': species,
      'gender': gender,
      'image': image,
      'origin': origin,
      'location': location,
      'description': description,
      'episode': episode,
    };
  }

  /// Alias toMap() untuk konsistensi penyimpanan ke Hive/Shared Preferences
  Map<String, dynamic> toMap() => toJson();

  // ---------------------------------------------------------------------------
  // 6. HELPER GETTERS
  // Properti tambahan yang mempermudah logika tampilan di UI.
  // ---------------------------------------------------------------------------

  /// Cek apakah karakter masih hidup
  bool get isAlive => status.toLowerCase() == 'alive';

  /// Cek apakah karakter sudah mati
  bool get isDead => status.toLowerCase() == 'dead';

  // ---------------------------------------------------------------------------
  // 7. COPYWITH
  // Berguna untuk mengkloning objek dengan perubahan pada sebagian atribut.
  // ---------------------------------------------------------------------------
  ItemModel copyWith({
    int? id,
    String? name,
    String? status,
    String? species,
    String? gender,
    String? image,
    String? origin,
    String? location,
    String? description,
    List<String>? episode,
  }) {
    return ItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      species: species ?? this.species,
      gender: gender ?? this.gender,
      image: image ?? this.image,
      origin: origin ?? this.origin,
      location: location ?? this.location,
      description: description ?? this.description,
      episode: episode ?? this.episode,
    );
  }

  // ---------------------------------------------------------------------------
  // 8. EQUALITY & HASHCODE
  // Agar dua objek ItemModel dengan ID yang sama dianggap identik
  // (sangat berguna untuk operasi List.contains() pada fitur Favorit).
  // ---------------------------------------------------------------------------
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItemModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ItemModel(id: $id, name: $name, status: $status)';
}

