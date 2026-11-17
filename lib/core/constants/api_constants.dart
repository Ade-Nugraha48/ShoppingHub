// ==============================================================================
// FILE: lib/core/constants/api_constants.dart
// ------------------------------------------------------------------------------
// PANDUAN PEMULA - LANGKAH 1:
// File ini adalah tempat pertama yang WAJIB kamu buka saat menerima soal responsi baru!
// Di sini kamu mengatur:
// 1. Alamat dasar API (Base URL)
// 2. Endpoint (Path ke data yang diminta soal)
// 3. Nama kata kunci pencarian (Query Param: name/q/search)
// 4. Pilihan filter (misal: kategori produk atau status)
// ==============================================================================

class ApiConstants {
  // ---------------------------------------------------------------------------
  // [GANTI DISINI 1] BASE URL
  // ---------------------------------------------------------------------------
  // Aturan penting:
  // - Ambil domain utama API dari soal responsi.
  // - JANGAN beri tanda garis miring (/) di ujungnya agar tidak dobel.
  //
  // CONTOH LAIN:
  // - Toko Produk (DummyJSON) : 'https://dummyjson.com'
  // - Toko FakeStore          : 'https://fakestoreapi.com'
  // - Berita / News API       : 'https://newsapi.org/v2'
  // ---------------------------------------------------------------------------
  static const String baseUrl = 'https://dummyjson.com';

  // ---------------------------------------------------------------------------
  // [GANTI DISINI 2] ENDPOINT UTAMA (LIST & DETAIL)
  // ---------------------------------------------------------------------------
  // Masukkan path endpoint sesuai tabel di lembar soal.
  //
  // CONTOH:
  // - Rick & Morty Karakter   : '/character'
  // - Soal Toko Produk        : '/products'
  // - Soal Buku / Library     : '/books'
  // - Soal Anime / Manga      : '/anime'
  // - Soal Resep Makanan      : '/recipes'
  // ---------------------------------------------------------------------------
  static const String charactersEndpoint = '/products'; // Endpoint Item Utama
  static const String episodesEndpoint =
      '/products/category-list'; // Endpoint Item Sekunder (Tab 3)

  // ---------------------------------------------------------------------------
  // [GANTI DISINI 3] QUERY PARAMETER PENCARIAN & PAGINATION
  // ---------------------------------------------------------------------------
  // Buka dokumentasi API soal atau coba di browser.
  // Cek apa kata kunci untuk search:
  // - Rick & Morty : /character?name=rick  -> paramSearch = 'name'
  // - DummyJSON    : /products/search?q=phone -> paramSearch = 'q'
  // - Umumnya API  : ?search=... atau ?query=...
  // ---------------------------------------------------------------------------
  static const String paramPage = 'page';
  static const String paramSearch =
      'category-list'; // Ganti jadi 'q' atau 'search' jika soal memintanya
  static const String paramStatus = 'status';

  // ---------------------------------------------------------------------------
  // [GANTI DISINI 4] PILIHAN FILTER CHIP DI HALAMAN HOME
  // ---------------------------------------------------------------------------
  // Jika soal meminta filter (misal filter status atau filter kategori):
  // 1. statusAll biarkan string kosong '' (artinya menampilkan semua).
  // 2. Buat konstanta string sesuai nilai yang diterima server API.
  // 3. Masukkan ke dalam list `statusFilterList` agar muncul tombolnya di UI.
  //
  // ---------------------------------------------------------------------------
  static const String statusAll = ''; // Kosong = Tampilkan semua data
  static const String statusAlive = 'beauty';
  static const String statusDead = 'fragrances';
  static const String statusUnknown = 'furniture';
  static const String statusGroceries = 'groceries';

  /// Daftar tombol filter yang langsung muncul di bagian atas HomeScreen
  static const List<String> statusFilterList = [
    'All',
    'Beauty',
    'Fragrances',
    'Furniture',
    'Groceries',
  ];

  // ---------------------------------------------------------------------------
  // 5. TIMEOUT & HEADERS
  // Konfigurasi durasi timeout koneksi HTTP agar aplikasi tidak hang.
  // ---------------------------------------------------------------------------
  static const Duration timeoutDuration = Duration(seconds: 15);

  /// Header standar untuk HTTP request
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ---------------------------------------------------------------------------
  // 6. HELPER BUILDER URI
  // Membantu membuat Uri lengkap dengan query parameters secara aman & rapi.
  // ---------------------------------------------------------------------------

  /// Membentuk Uri untuk endpoint Karakter / Item Utama (dengan pagination, search, filter)
  static Uri charactersUri({int page = 1, String? search, String? status}) {
    final queryParams = <String, String>{};

    // Tambahkan pagination jika page > 0
    if (page > 0) {
      queryParams[paramPage] = page.toString();
    }

    // Tambahkan pencarian nama jika tidak kosong
    if (search != null && search.trim().isNotEmpty) {
      queryParams[paramSearch] = search.trim();
    }

    // Tambahkan filter status jika ada dan bukan 'All' / string kosong
    if (status != null &&
        status.trim().isNotEmpty &&
        status.toLowerCase() != 'all') {
      queryParams[paramStatus] = status.trim().toLowerCase();
    }

    return Uri.parse('$baseUrl$charactersEndpoint')
        .replace(queryParameters: queryParams.isEmpty ? null : queryParams);
  }

  /// Membentuk Uri untuk detail Karakter berdasarkan ID
  static Uri characterDetailUri(int id) {
    return Uri.parse('$baseUrl$charactersEndpoint/$id');
  }

  /// Membentuk Uri untuk endpoint Episode / Item Sekunder
  static Uri episodesUri({int page = 1, String? search}) {
    final queryParams = <String, String>{};

    if (page > 0) {
      queryParams[paramPage] = page.toString();
    }

    if (search != null && search.trim().isNotEmpty) {
      queryParams[paramSearch] = search.trim();
    }

    return Uri.parse('$baseUrl$episodesEndpoint')
        .replace(queryParameters: queryParams.isEmpty ? null : queryParams);
  }

  /// Membentuk Uri untuk detail Episode berdasarkan ID
  static Uri episodeDetailUri(int id) {
    return Uri.parse('$baseUrl$episodesEndpoint/$id');
  }
}
