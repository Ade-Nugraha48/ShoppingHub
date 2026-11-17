// ==============================================================================
// FILE: lib/providers/item_provider.dart
// PANDUAN: State Management untuk data utama (ItemModel / Karakter).
// Menangani:
// 1. Fetching API dengan Loading & Error handling
// 2. Pagination (Load More) & Pull-to-Refresh
// 3. Filter status (All, Alive, Dead, Unknown)
// 4. Pencarian berdasarkan nama (Search)
// 5. Pengurutan lokal (Sort Default, A-Z, Z-A)
// ==============================================================================

import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../models/item_model.dart';
import '../services/api_service.dart';

enum SortOption {
  defaultOrder,
  nameAsc,  // A - Z
  nameDesc, // Z - A
}

class ItemProvider extends ChangeNotifier {
  final ApiService _apiService;

  // ---------------------------------------------------------------------------
  // 1. STATE VARIABLES
  // ---------------------------------------------------------------------------
  List<ItemModel> _items = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;

  // Filter & Search
  String _selectedStatus = ApiConstants.statusAll;
  String _searchQuery = '';
  SortOption _selectedSort = SortOption.defaultOrder;

  // ---------------------------------------------------------------------------
  // 2. CONSTRUCTOR
  // ---------------------------------------------------------------------------
  ItemProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // ---------------------------------------------------------------------------
  // 3. GETTERS
  // ---------------------------------------------------------------------------
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  String? get errorMessage => _errorMessage;
  String get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;
  SortOption get selectedSort => _selectedSort;

  /// Daftar item yang sudah diproses dengan sorting lokal
  List<ItemModel> get items {
    final list = List<ItemModel>.from(_items);

    switch (_selectedSort) {
      case SortOption.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortOption.nameDesc:
        list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case SortOption.defaultOrder:
        // Urutan bawaan ID dari API
        break;
    }

    return list;
  }

  // ---------------------------------------------------------------------------
  // 4. FETCH INITIAL DATA / REFRESH
  // Memuat data halaman 1 dengan parameter pencarian dan filter aktif
  // ---------------------------------------------------------------------------
  Future<void> fetchItems() async {
    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();

    try {
      final fetched = await _apiService.getItems(
        page: _currentPage,
        search: _searchQuery,
        status: _selectedStatus,
      );

      _items = fetched;
      // Jika data yang didapat kosong atau kurang dari 20, asumsikan sudah halaman terakhir
      if (fetched.isEmpty || fetched.length < 20) {
        _hasMore = false;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // 5. LOAD MORE (PAGINATION)
  // Memuat data halaman berikutnya (page + 1) dan menambahkannya ke list
  // ---------------------------------------------------------------------------
  Future<void> loadMoreItems() async {
    // Jangan load jika sedang proses atau tidak ada halaman lagi
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final newItems = await _apiService.getItems(
        page: nextPage,
        search: _searchQuery,
        status: _selectedStatus,
      );

      if (newItems.isEmpty) {
        _hasMore = false;
      } else {
        _items.addAll(newItems);
        _currentPage = nextPage;
        if (newItems.length < 20) {
          _hasMore = false;
        }
      }

      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      // Pada pagination, error tidak menghapus item yang sudah tampil
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // 6. FILTER STATUS (FILTER CHIPS)
  // Mengubah kategori filter dan otomatis fetch ulang halaman 1
  // ---------------------------------------------------------------------------
  void setStatusFilter(String status) {
    if (_selectedStatus == status) return;

    _selectedStatus = status;
    fetchItems();
  }

  // ---------------------------------------------------------------------------
  // 7. PENCARIAN (SEARCH)
  // Mencari item berdasarkan kata kunci nama
  // ---------------------------------------------------------------------------
  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    fetchItems();
  }

  // ---------------------------------------------------------------------------
  // 8. SORTING LOKAL (A-Z / Z-A)
  // Mengubah urutan daftar item tanpa perlu reload API
  // ---------------------------------------------------------------------------
  void setSortOption(SortOption option) {
    _selectedSort = option;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // 9. RESET FILTER
  // Mengembalikan filter, search, dan sorting ke kondisi awal
  // ---------------------------------------------------------------------------
  void resetFilter() {
    _selectedStatus = ApiConstants.statusAll;
    _searchQuery = '';
    _selectedSort = SortOption.defaultOrder;
    fetchItems();
  }
}
