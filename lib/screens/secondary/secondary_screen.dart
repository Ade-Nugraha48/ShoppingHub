// ==============================================================================
// FILE: lib/screens/secondary/secondary_screen.dart
// PANDUAN: Halaman Tab Ketiga (Secondary List Screen).
// Pada template default ini menampilkan daftar Episode dari '/episode'.
// Saat ujian responsi, jika diminta menampilkan data kedua (misal: Berita, Kategori,
// Ulasan, atau Produk Terkait), ganti pemanggilan API & widget di file ini.
// ==============================================================================

import 'package:flutter/material.dart';
import '../../models/secondary_model.dart';
import '../../services/api_service.dart';
import '../../widgets/state_widgets.dart';
import 'secondary_detail_screen.dart';

class SecondaryScreen extends StatefulWidget {
  final ApiService? apiService;

  const SecondaryScreen({super.key, this.apiService});

  @override
  State<SecondaryScreen> createState() => _SecondaryScreenState();
}

class _SecondaryScreenState extends State<SecondaryScreen> {
  late final ApiService _apiService;

  List<SecondaryModel> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _fetchSecondaryData();
  }

  // ---------------------------------------------------------------------------
  // FETCH DATA ENDPOINT KEDUA
  // [GANTI DISINI SAAT RESPONSI] Ganti method ApiService jika endpoint sekunder berbeda
  // ---------------------------------------------------------------------------
  Future<void> _fetchSecondaryData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getSecondaryItems(page: 1);
      setState(() {
        _items = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        // [GANTI DISINI SAAT RESPONSI] Judul halaman tab kedua
        title: const Text('Daftar Episode'),
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    // 1. Kondisi Loading
    if (_isLoading) {
      return const LoadingStateWidget(message: 'Memuat daftar episode...');
    }

    // 2. Kondisi Error
    if (_errorMessage != null && _items.isEmpty) {
      return ErrorStateWidget(
        message: _errorMessage!,
        onRetry: _fetchSecondaryData,
      );
    }

    // 3. Kondisi Kosong
    if (_items.isEmpty) {
      return EmptyStateWidget(
        title: 'Episode Kosong',
        message: 'Tidak ada data episode yang dapat dimuat.',
        actionLabel: 'Muat Ulang',
        onAction: _fetchSecondaryData,
      );
    }

    // 4. Kondisi Menampilkan Data (Pull-to-Refresh)
    return RefreshIndicator(
      onRefresh: _fetchSecondaryData,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _items.length,
        separatorBuilder: (ctx, i) => const SizedBox(height: 8),
        itemBuilder: (ctx, index) {
          final episode = _items[index];

          // [GANTI DISINI SAAT RESPONSI] Sesuaikan kartu tampilan item sekunder
          return Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              // ---------------------------------------------------------------
              // [GANTI DISINI SAAT RESPONSI - LEADING KIRI (KOTAK/GAMBAR)]
              // ---------------------------------------------------------------
              // 1. Gambar dari API (URL):
              //    Gunakan: Image.network(episode.image, width: 48, height: 48, fit: BoxFit.cover)
              //
              // 2. Gambar Aset Lokal:
              //    Gunakan: Image.asset('assets/images/logo.png', width: 48, height: 48)
              //
              // 3. Bentuk Lingkaran:
              //    Gunakan: CircleAvatar(backgroundImage: NetworkImage(episode.image))
              // ---------------------------------------------------------------
              leading: episode.image.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        episode.image,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          // [GANTI ICON DISINI - FALLBACK GAMBAR TAB 3]
                          // Makanan: Icons.fastfood_rounded / Icons.restaurant_rounded
                          // Belanja: Icons.inventory_2_rounded / Icons.category_rounded
                          // Buku:    Icons.menu_book_rounded / Icons.book_rounded
                          child: const Icon(Icons.movie_creation_outlined, size: 24),
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        episode.episode.isNotEmpty ? episode.episode : '#${episode.id}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
              title: Text(
                episode.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    // [GANTI ICON DISINI - SUBTITLE DETAIL TAB 3]
                    // Tanggal: Icons.calendar_today_rounded
                    // Harga:   Icons.attach_money_rounded / Icons.payments_rounded
                    // Kategori: Icons.label_outline_rounded
                    const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    // Gunakan Expanded + TextOverflow.ellipsis untuk mencegah pixel overflow di layar kecil
                    Expanded(
                      child: Text(
                        episode.airDate.isNotEmpty ? episode.airDate : '-',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${episode.characters.length} Karakter',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                ],
              ),
              // ---------------------------------------------------------------
              // [NAVIGASI KE DETAIL SEKUNDER]
              // Klik item untuk membuka halaman rincian SecondaryDetailScreen
              // ---------------------------------------------------------------
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SecondaryDetailScreen(item: episode),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
