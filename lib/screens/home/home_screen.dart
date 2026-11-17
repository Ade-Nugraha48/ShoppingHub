// ==============================================================================
// FILE: lib/screens/home/home_screen.dart
// PANDUAN: Halaman Utama (Tab 1 - Explorer).
// Menampilkan:
// 1. Search Bar dengan Debounce
// 2. Filter Chips Horizontal (Status: All, Alive, Dead, Unknown)
// 3. Tombol Sorting (A-Z / Z-A) dan Reset Filter di AppBar
// 4. Grid Katalog Item dengan Pull-to-Refresh & Pagination (Load More)
// ==============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_constants.dart';
import '../../providers/item_provider.dart';
import '../../widgets/item_card.dart';
import '../../widgets/state_widgets.dart';
import '../detail/detail_screen.dart';

class HomeScreen extends StatefulWidget {
  // ---------------------------------------------------------------------------
  // [CONFIG FITUR KEJUTAN (BISA DINONAKTIFKAN KAPAN SAJA DENGAN UBAH JADI FALSE)]
  // ---------------------------------------------------------------------------
  static const bool enableViewModeToggle =
      true; // [FITUR 6] Tombol Switch Grid / List
  static const bool enableScrollToTop =
      true; // [FITUR 7] Tombol Mengambang (FAB) Scroll ke Atas
  static const bool enableSummaryBar =
      true; // [FITUR 10] Banner Ringkasan Jumlah & Filter

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  // State untuk Fitur Kejutan
  bool _isGridView = true; // true: Grid 2 kolom, false: List 1 kolom
  bool _showBackToTop = false; // Otomatis true saat scroll ke bawah > 300px

  @override
  void initState() {
    super.initState();
    // Memuat data saat halaman pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().fetchItems();
    });

    // Listener Scroll untuk Auto-Pagination & Scroll to Top FAB
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    // 1. Auto-Pagination saat mendekati dasar halaman
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ItemProvider>().loadMoreItems();
    }

    // 2. Deteksi Scroll untuk memunculkan tombol 'Scroll to Top'
    if (HomeScreen.enableScrollToTop && _scrollController.hasClients) {
      final shouldShow = _scrollController.offset > 300;
      if (shouldShow != _showBackToTop) {
        setState(() {
          _showBackToTop = shouldShow;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    // Debounce 500ms agar tidak spam API setiap kali user mengetik karakter
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<ItemProvider>().setSearchQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = context.watch<ItemProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Halaman Utama'),
        actions: [
          // -------------------------------------------------------------------
          // TOMBOL SORTING (A-Z / Z-A / DEFAULT) - FITUR KEJUTAN 4
          // -------------------------------------------------------------------
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Urutkan Karakter',
            initialValue: itemProvider.selectedSort,
            onSelected: (option) {
              itemProvider.setSortOption(option);
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: SortOption.defaultOrder,
                child: Row(
                  children: [
                    Icon(Icons.format_list_numbered_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Bawaan (ID)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: SortOption.nameAsc,
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Nama (A - Z)'),
                  ],
                ),
              ),

        
              const PopupMenuItem(
                value: SortOption.nameDesc,
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Nama (Z - A)'),
                  ],
                ),
              ),
            ],
          ),

          // -------------------------------------------------------------------
          // [FITUR KEJUTAN 6] TOMBOL TOGGLE TAMPILAN GRID / LIST
          // Cara mematikan: ubah 'enableViewModeToggle' di atas menjadi false
          // -------------------------------------------------------------------
          if (HomeScreen.enableViewModeToggle)
            IconButton(
              icon: Icon(
                _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              ),
              tooltip: _isGridView ? 'Tampilan List' : 'Tampilan Grid',
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
            ),

          // -------------------------------------------------------------------
          // TOMBOL RESET FILTER & PENCARIAN
          // -------------------------------------------------------------------
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'Reset Filter',
            onPressed: () {
              _searchController.clear();
              itemProvider.resetFilter();
            },
          ),
        ],
      ),
      // -----------------------------------------------------------------------
      // [FITUR KEJUTAN 7] FLOATING ACTION BUTTON (SCROLL TO TOP)
      // Otomatis muncul jika user scroll ke bawah > 300px
      // Cara mematikan: ubah 'enableScrollToTop' di atas menjadi false
      // -----------------------------------------------------------------------
      floatingActionButton: (HomeScreen.enableScrollToTop && _showBackToTop)
          ? FloatingActionButton.small(
              tooltip: 'Kembali ke Atas',
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                );
              },
              child: const Icon(Icons.arrow_upward_rounded),
            )
          : null,
      body: Column(
        children: [
          // -------------------------------------------------------------------
          // 1. SEARCH BAR
          // -------------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari nama produk',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          itemProvider.setSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // 2. DYNAMIC FILTER CHIPS HORIZONTAL
          // [GANTI DISINI SAAT RESPONSI] Sesuaikan label dan status filter
          // -------------------------------------------------------------------
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                _buildFilterChip(
                  label: 'All',
                  statusValue: ApiConstants.statusAll,
                  isSelected:
                      itemProvider.selectedStatus == ApiConstants.statusAll,
                  onSelected: () =>
                      itemProvider.setStatusFilter(ApiConstants.statusAll),
                ),
                _buildFilterChip(
                  label: 'Beauty',
                  statusValue: ApiConstants.statusAlive,
                  isSelected:
                      itemProvider.selectedStatus == ApiConstants.statusAlive,
                  onSelected: () =>
                      itemProvider.setStatusFilter(ApiConstants.statusAlive),
                ),
                _buildFilterChip(
                  label: 'Fragrance',
                  statusValue: ApiConstants.statusDead,
                  isSelected:
                      itemProvider.selectedStatus == ApiConstants.statusDead,
                  onSelected: () =>
                      itemProvider.setStatusFilter(ApiConstants.statusDead),
                ),
                _buildFilterChip(
                  label: 'Furniture',
                  statusValue: ApiConstants.statusUnknown,
                  isSelected:
                      itemProvider.selectedStatus == ApiConstants.statusUnknown,
                  onSelected: () =>
                      itemProvider.setStatusFilter(ApiConstants.statusUnknown),
                ),
                _buildFilterChip(
                  label: 'Groceries',
                  statusValue: ApiConstants.statusGroceries,
                  isSelected:
                      itemProvider.selectedStatus ==
                      ApiConstants.statusGroceries,
                  onSelected: () => itemProvider.setStatusFilter(
                    ApiConstants.statusGroceries,
                  ),
                ),
              ],
            ),
          ),

          // -------------------------------------------------------------------
          // [FITUR KEJUTAN 10] BANNER RINGKASAN DATA (COUNTER BAR)
          // Menampilkan total item & filter aktif secara real-time
          // Cara mematikan: ubah 'enableSummaryBar' di atas menjadi false
          // -------------------------------------------------------------------
          if (HomeScreen.enableSummaryBar && itemProvider.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Menampilkan ${itemProvider.items.length} item',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary
                          .withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Filter: ${itemProvider.selectedStatus}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),

          // -------------------------------------------------------------------
          // 3. DAFTAR ITEM (LOADING, ERROR, EMPTY, ATAU GRID DATA)
          // -------------------------------------------------------------------
          Expanded(child: _buildContent(itemProvider)),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String statusValue,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        selectedColor: theme.colorScheme.primary.withAlpha(40),
        checkmarkColor: theme.colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? theme.colorScheme.primary : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildContent(ItemProvider provider) {
    // 1. Kondisi Loading Pertama Kali
    if (provider.isLoading) {
      return const LoadingStateWidget(message: 'Mengambil data produk...');
    }

    // 2. Kondisi Error
    if (provider.errorMessage != null && provider.items.isEmpty) {
      return ErrorStateWidget(
        message: provider.errorMessage!,
        onRetry: () => provider.fetchItems(),
      );
    }

    // 3. Kondisi Data Kosong (Search tidak ketemu / Filter kosong)
    if (provider.items.isEmpty) {
      return EmptyStateWidget(
        title: 'Karakter Tidak Ditemukan',
        message: 'Tidak ada karakter yang sesuai dengan pencarian atau filter.',
        actionLabel: 'Reset Filter',
        onAction: () {
          _searchController.clear();
          provider.resetFilter();
        },
      );
    }

    // 4. Kondisi Menampilkan Data (Pull-to-Refresh & Pagination)
    return RefreshIndicator(
      onRefresh: () => provider.fetchItems(),
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          // -------------------------------------------------------------------
          // [FITUR KEJUTAN 6] TAMPILAN KATALOG (GRID 2 KOLOM ATAU LIST 1 KOLOM)
          // -------------------------------------------------------------------
          if (_isGridView)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: provider.items.length,
              itemBuilder: (ctx, index) {
                final item = provider.items[index];
                return ItemCard(
                  item: item,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(item: item),
                      ),
                    );
                  },
                );
              },
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.items.length,
              separatorBuilder: (ctx, index) => const SizedBox(height: 8),
              itemBuilder: (ctx, index) {
                final item = provider.items[index];
                return Card(
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: item.image.isNotEmpty
                          ? Image.network(
                              item.image,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.image_not_supported_rounded,
                                      size: 24,
                                    ),
                                  ),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.image_not_supported_rounded,
                                size: 24,
                              ),
                            ),
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${item.species} • ${item.gender}'),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailScreen(item: item),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

          // Indikator Load More di bagian paling bawah
          if (provider.isLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          else if (provider.hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: () => provider.loadMoreItems(),
                  icon: const Icon(Icons.expand_more_rounded),
                  label: const Text('Muat Lebih Banyak'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
