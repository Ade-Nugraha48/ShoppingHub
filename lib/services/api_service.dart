// ==============================================================================
// FILE: lib/services/api_service.dart
// PANDUAN: Service terpusat untuk seluruh pemanggilan HTTP REST API.
// Menangani GET List (Search, Filter, Pagination) & GET Detail dengan
// error handling yang rapi (Timeout, SocketException, dan HTTP Status Code).
// ==============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/item_model.dart';
import '../models/secondary_model.dart';

/// Exception khusus untuk penanganan error API dengan pesan yang user-friendly
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  final http.Client _client;

  /// Constructor dengan opsi inject http.Client (sangat berguna untuk Unit Testing)
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // ---------------------------------------------------------------------------
  // 1. GET ITEMS (LIST UTAMA DENGAN SEARCH, FILTER, & PAGINATION)
  // [GANTI DISINI SAAT RESPONSI] Jika struktur response berbeda
  // (misal langsung List [] atau key-nya bernama 'data' bukan 'results').
  // ---------------------------------------------------------------------------
  Future<List<ItemModel>> getItems({
    int page = 1,
    String? search,
    String? status,
  }) async {
    final uri = ApiConstants.charactersUri(
      page: page,
      search: search,
      status: status,
    );

    try {
      final response = await _client
          .get(uri, headers: ApiConstants.defaultHeaders)
          .timeout(ApiConstants.timeoutDuration);

      // Status 200: Berhasil memuat data
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);

        List rawList = [];

        // ---------------------------------------------------------------------
        // [GANTI DISINI 3A] CEK FORMAT PEMBUNGKUS JSON DARI API
        // ---------------------------------------------------------------------
        // Buka URL API di browser atau Postman. Lihat apakah list item dibungkus
        // di dalam suatu key/properti tertentu:
        //
        // 1. Dibungkus 'results'  -> Rick & Morty, Pokemon API, Movie DB API
        // 2. Dibungkus 'products' -> DummyJSON Products (https://dummyjson.com/products)
        // 3. Dibungkus 'data'     -> GoRest, Reqres, banyak REST API standar
        // 4. Dibungkus 'articles' -> News API
        // 5. Langsung List [...]  -> FakeStore API (https://fakestoreapi.com/products)
        // ---------------------------------------------------------------------
        if (decoded is Map<String, dynamic> && decoded.containsKey('results')) {
          rawList = decoded['results'] as List;
        } else if (decoded is Map && decoded.containsKey('products')) {
          rawList = decoded['products'] as List;
        } else if (decoded is Map && decoded.containsKey('restaurants')) {
          rawList = decoded['restaurants'] as List;
        } else if (decoded is Map && decoded.containsKey('meals')) {
          rawList = decoded['meals'] as List;
        } else if (decoded is Map && decoded.containsKey('recipes')) {
          rawList = decoded['recipes'] as List;
        } else if (decoded is Map && decoded.containsKey('data')) {
          rawList = decoded['data'] as List;
        } else if (decoded is Map && decoded.containsKey('articles')) {
          rawList = decoded['articles'] as List;
        } else if (decoded is List) {
          // Jika API mengembalikan array langsung tanpa pembungkus: [ {...}, {...} ]
          rawList = decoded;
        } else if (decoded is Map) {
          // Fallback cerdas: otomatis mencari list pertama di dalam Map pembungkus apapun (items, books, anime, dll)
          for (final value in decoded.values) {
            if (value is List) {
              rawList = value;
              break;
            }
          }
        }

        return rawList
            .map((item) => ItemModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }

      // Status 404: Pada Rick & Morty API, jika pencarian / filter tidak ada hasil,
      // API mengembalikan 404 dengan pesan "There is nothing here".
      // Kita kembalikan List kosong [] agar UI menampilkan Empty State bukan Error.
      if (response.statusCode == 404) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['error'] == 'There is nothing here') {
          return <ItemModel>[];
        }
        throw ApiException('Data tidak ditemukan.', 404);
      }

      // Status lainnya: Lempar exception dengan status code
      throw ApiException(
        'Gagal memuat data dari server (Kode: ${response.statusCode}).',
        response.statusCode,
      );
    } on SocketException {
      throw ApiException('Tidak ada koneksi internet. Periksa jaringan Anda.');
    } on TimeoutException {
      throw ApiException('Waktu koneksi habis. Silakan coba beberapa saat lagi.');
    } on FormatException {
      throw ApiException('Format data dari server tidak valid.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Terjadi kesalahan yang tidak terduga: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 2. GET ITEM DETAIL (BY ID)
  // Mengambil satu data spesifik berdasarkan ID untuk Halaman Detail.
  // ---------------------------------------------------------------------------
  Future<ItemModel> getItemDetail(int id) async {
    final uri = ApiConstants.characterDetailUri(id);

    try {
      final response = await _client
          .get(uri, headers: ApiConstants.defaultHeaders)
          .timeout(ApiConstants.timeoutDuration);

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map) {
          return ItemModel.fromJson(Map<String, dynamic>.from(decoded));
        }
        throw ApiException('Format detail data tidak sesuai.');
      }

      if (response.statusCode == 404) {
        throw ApiException('Item dengan ID $id tidak ditemukan.', 404);
      }

      throw ApiException(
        'Gagal mengambil detail item (Kode: ${response.statusCode}).',
        response.statusCode,
      );
    } on SocketException {
      throw ApiException('Tidak ada koneksi internet. Periksa jaringan Anda.');
    } on TimeoutException {
      throw ApiException('Waktu koneksi habis. Silakan coba beberapa saat lagi.');
    } on FormatException {
      throw ApiException('Format data dari server tidak valid.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Terjadi kesalahan yang tidak terduga: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 3. GET SECONDARY ITEMS (LIST TAB KEDUA: EPISODES)
  // [GANTI DISINI SAAT RESPONSI] Jika tab kedua menggunakan endpoint lain.
  // ---------------------------------------------------------------------------
  Future<List<SecondaryModel>> getSecondaryItems({
    int page = 1,
    String? search,
  }) async {
    final uri = ApiConstants.episodesUri(page: page, search: search);

    try {
      final response = await _client
          .get(uri, headers: ApiConstants.defaultHeaders)
          .timeout(ApiConstants.timeoutDuration);

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);

        List rawList = [];
        if (decoded is Map<String, dynamic> && decoded.containsKey('results')) {
          rawList = decoded['results'] as List;
        } else if (decoded is Map && decoded.containsKey('products')) {
          rawList = decoded['products'] as List;
        } else if (decoded is Map && decoded.containsKey('restaurants')) {
          rawList = decoded['restaurants'] as List;
        } else if (decoded is Map && decoded.containsKey('meals')) {
          rawList = decoded['meals'] as List;
        } else if (decoded is Map && decoded.containsKey('recipes')) {
          rawList = decoded['recipes'] as List;
        } else if (decoded is Map && decoded.containsKey('categories')) {
          rawList = decoded['categories'] as List;
        } else if (decoded is Map && decoded.containsKey('data')) {
          rawList = decoded['data'] as List;
        } else if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map) {
          // Fallback cerdas: otomatis mencari list pertama di dalam Map pembungkus apapun
          for (final value in decoded.values) {
            if (value is List) {
              rawList = value;
              break;
            }
          }
        }

        return rawList
            .map((item) =>
                SecondaryModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }

      if (response.statusCode == 404) {
        return <SecondaryModel>[];
      }

      throw ApiException(
        'Gagal memuat data sekunder (Kode: ${response.statusCode}).',
        response.statusCode,
      );
    } on SocketException {
      throw ApiException('Tidak ada koneksi internet. Periksa jaringan Anda.');
    } on TimeoutException {
      throw ApiException('Waktu koneksi habis. Silakan coba beberapa saat lagi.');
    } on FormatException {
      throw ApiException('Format data dari server tidak valid.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Terjadi kesalahan yang tidak terduga: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 4. GET SECONDARY ITEM DETAIL (BY ID)
  // ---------------------------------------------------------------------------
  Future<SecondaryModel> getSecondaryItemDetail(int id) async {
    final uri = ApiConstants.episodeDetailUri(id);

    try {
      final response = await _client
          .get(uri, headers: ApiConstants.defaultHeaders)
          .timeout(ApiConstants.timeoutDuration);

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map) {
          return SecondaryModel.fromJson(Map<String, dynamic>.from(decoded));
        }
        throw ApiException('Format detail sekunder tidak sesuai.');
      }

      if (response.statusCode == 404) {
        throw ApiException('Data dengan ID $id tidak ditemukan.', 404);
      }

      throw ApiException(
        'Gagal mengambil detail (Kode: ${response.statusCode}).',
        response.statusCode,
      );
    } on SocketException {
      throw ApiException('Tidak ada koneksi internet. Periksa jaringan Anda.');
    } on TimeoutException {
      throw ApiException('Waktu koneksi habis. Silakan coba beberapa saat lagi.');
    } on FormatException {
      throw ApiException('Format data dari server tidak valid.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Terjadi kesalahan yang tidak terduga: $e');
    }
  }

  /// Menutup client jika sudah tidak digunakan
  void close() {
    _client.close();
  }
}

