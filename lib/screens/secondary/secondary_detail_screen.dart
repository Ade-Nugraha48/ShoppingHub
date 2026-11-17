// ==============================================================================
// FILE: lib/screens/secondary/secondary_detail_screen.dart
// PANDUAN: Halaman Detail untuk Tab Ketiga (Secondary Item Detail).
// Menampilkan rincian data ketika sebuah item di Tab 3 (Secondary Screen) diklik.
// Contoh default: Detail Episode (nama, kode episode, tanggal rilis, karakter).
// Saat responsi, sesuaikan tampilan dengan data sekunder yang diminta soal.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/secondary_model.dart';

class SecondaryDetailScreen extends StatelessWidget {
  // [CONFIG FITUR KEJUTAN 8] Ubah ke false jika ingin mematikan tombol share
  static const bool enableShareButton = true;

  final SecondaryModel item;

  const SecondaryDetailScreen({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        // [GANTI DISINI SAAT RESPONSI] Judul halaman detail sekunder
        title: Text(item.name.isNotEmpty ? item.name : 'Detail Item'),
        actions: [
          if (enableShareButton)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Bagikan / Salin Info',
              onPressed: () {
                final text = '''
${item.name}
Kode / Kategori: ${item.episode}
Tanggal: ${item.airDate}
''';
                Clipboard.setData(ClipboardData(text: text.trim()));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Info ${item.name} berhasil disalin!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // -----------------------------------------------------------------
            // 1. HEADER GAMBAR ATAU BADGE BESAR
            // -----------------------------------------------------------------
            _buildHeader(theme),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // -----------------------------------------------------------
                  // 2. JUDUL & BADGE KATEGORI
                  // -----------------------------------------------------------
                  Text(
                    item.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (item.episode.isNotEmpty)
                        Chip(
                          // [GANTI ICON DISINI - CHIP KODE/KATEGORI TAB 3]
                          // Makanan: Icons.fastfood_rounded / Icons.menu_book_rounded
                          // Belanja: Icons.category_rounded / Icons.sell_rounded
                          // Buku:    Icons.person_pin_rounded (Penulis) / Icons.bookmark_rounded
                          avatar: const Icon(Icons.tv_rounded, size: 16),
                          label: Text(item.episode),
                          backgroundColor: theme.colorScheme.primary.withAlpha(30),
                        ),
                      if (item.airDate.isNotEmpty)
                        Chip(
                          // [GANTI ICON DISINI - CHIP TANGGAL/HARGA TAB 3]
                          // Tanggal: Icons.calendar_today_rounded
                          // Harga:   Icons.attach_money_rounded / Icons.payments_rounded
                          avatar: const Icon(Icons.calendar_today_rounded, size: 16),
                          label: Text(item.airDate),
                          backgroundColor: Colors.grey.withAlpha(30),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // -----------------------------------------------------------
                  // 3. BOX DESKRIPSI (OTOMATIS MUNCUL JIKA ADA DESKRIPSI)
                  // -----------------------------------------------------------
                  if (item.description.isNotEmpty) ...[
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Deskripsi',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Text(
                              item.description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // -----------------------------------------------------------
                  // 4. KARTU INFORMASI LENGKAP (SPESIFIKASI / ATRIBUT)
                  // -----------------------------------------------------------
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informasi Rinci',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(height: 20),

                          _buildDetailRow(
                            icon: Icons.numbers_rounded,
                            label: 'ID',
                            value: '#${item.id}',
                            theme: theme,
                          ),
                          const Divider(height: 16),

                          _buildDetailRow(
                            icon: Icons.label_outline_rounded,
                            label: 'Nama / Judul',
                            value: item.name,
                            theme: theme,
                          ),
                          const Divider(height: 16),

                          if (item.episode.isNotEmpty) ...[
                            _buildDetailRow(
                              icon: Icons.video_collection_outlined,
                              label: 'Kode / Kategori',
                              value: item.episode,
                              theme: theme,
                            ),
                            const Divider(height: 16),
                          ],

                          if (item.airDate.isNotEmpty) ...[
                            _buildDetailRow(
                              icon: Icons.event_available_rounded,
                              label: 'Tanggal Rilis',
                              value: item.airDate,
                              theme: theme,
                            ),
                            const Divider(height: 16),
                          ],

                          _buildDetailRow(
                            icon: Icons.people_outline_rounded,
                            label: 'Total Terkait',
                            value: '${item.characters.length} Item',
                            theme: theme,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // -----------------------------------------------------------
                  // 5. DAFTAR TERKAIT (MISAL KARAKTER / URLS)
                  // -----------------------------------------------------------
                  if (item.characters.isNotEmpty) ...[
                    Text(
                      'Daftar Terkait (${item.characters.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.characters.take(15).map((url) {
                        final idPart = url.split('/').lastWhere(
                              (s) => s.isNotEmpty,
                              orElse: () => '',
                            );
                        return Chip(
                          label: Text(
                            idPart.isNotEmpty ? 'Item #$idPart' : url,
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                    ),
                    if (item.characters.length > 15)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '+ ${item.characters.length - 15} item lainnya',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGET HEADER GAMBAR / BADGE
  // ---------------------------------------------------------------------------
  Widget _buildHeader(ThemeData theme) {
    if (item.image.isNotEmpty) {
      return SizedBox(
        height: 220,
        width: double.infinity,
        child: Image.network(
          item.image,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderHeader(theme),
        ),
      );
    }
    return _buildPlaceholderHeader(theme);
  }

  Widget _buildPlaceholderHeader(ThemeData theme) {
    return Container(
      height: 160,
      width: double.infinity,
      color: theme.colorScheme.primary.withAlpha(25),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // [GANTI ICON DISINI - LOGO BESAR HEADER DETAIL TAB 3]
          // Makanan: Icons.restaurant_rounded / Icons.fastfood_rounded / Icons.lunch_dining_rounded
          // Belanja: Icons.inventory_2_rounded / Icons.storefront_rounded / Icons.shopping_bag_rounded
          // Buku:    Icons.menu_book_rounded / Icons.auto_stories_rounded / Icons.library_books_rounded
          Icon(
            Icons.movie_filter_rounded,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 10),
          Text(
            item.episode.isNotEmpty ? item.episode : '#${item.id}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER BARIS DETAIL (LABEL KIRI, VALUE KANAN)
  // ---------------------------------------------------------------------------
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '-',
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
