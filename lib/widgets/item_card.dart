// ==============================================================================
// FILE: lib/widgets/item_card.dart
// PANDUAN: Kartu tampilan item (Karakter) untuk Grid/List di Home & Favorite.
// Dilengkapi penanda [GANTI DISINI SAAT RESPONSI] agar sangat mudah dimodifikasi
// ketika atribut API soal ujian berbeda (misal: Toko Online, Buku, Berita).
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/utils/app_helpers.dart';
import '../models/item_model.dart';
import '../providers/favorite_provider.dart';

class ItemCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback? onTap;

  const ItemCard({
    super.key,
    required this.item,
    this.onTap,
  });

  // Helper warna badge status karakter
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'alive':
        return const Color(0xFF2E7D32); // Hijau
      case 'dead':
        return const Color(0xFFD32F2F); // Merah
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favoriteProvider = context.watch<FavoriteProvider>();
    final isFav = favoriteProvider.isFavorite(item.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -----------------------------------------------------------------
            // 1. GAMBAR ITEM & TOMBOL FAVORIT
            // [GANTI DISINI SAAT RESPONSI] Jika key URL gambar berbeda (misal item.thumbnail)
            // -----------------------------------------------------------------
            Stack(
              children: [
                Hero(
                  tag: 'item_image_${item.id}',
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: item.image.isNotEmpty
                        ? Image.network(
                            item.image,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              color: Colors.grey.shade200,
                              // [GANTI ICON DISINI - FALLBACK JIKA GAMBAR ERROR / RUSAK]
                              // Umum: Icons.broken_image_rounded
                              // Makanan: Icons.restaurant_rounded
                              // Belanja: Icons.inventory_2_rounded
                              child: const Icon(
                                Icons.broken_image_rounded,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                            loadingBuilder: (ctx, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported_rounded, size: 48),
                          ),
                  ),
                ),

                // Tombol Favorite Melayang di Pojok Kanan Atas
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(100),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFav ? Colors.redAccent : Colors.white,
                        size: 20,
                      ),
                      onPressed: () async {
                        final added = await favoriteProvider.toggleFavorite(item);
                        if (context.mounted) {
                          AppHelpers.showSnackBar(
                            context,
                            added
                                ? '${item.name} ditambahkan ke Favorit'
                                : '${item.name} dihapus dari Favorit',
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),

            // -----------------------------------------------------------------
            // 2. INFORMASI TEKS ITEM PADA KARTU (CARD)
            // -----------------------------------------------------------------
            // Ganti bagian teks di bawah ini agar sesuai dengan data model baru:
            // - Karakter Rick & Morty : name, species, gender, status
            // - Produk Toko           : name/title, price, category
            // - Buku                  : title, author, year
            // - Berita                : title, source, publishedAt
            // -----------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // [GANTI DISINI 4A] Judul Utama Item
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // [GANTI DISINI 4B] Subjudul (Bisa diisi Harga / Kategori / Penulis)
                  // Contoh Produk Toko : Text('\$${item.gender} • ${item.species}')
                  Text(
                    '${item.species.isNotEmpty ? item.species : 'Spesies tidak diketahui'} • ${item.gender}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // [GANTI DISINI 4C] Badge Kategori / Status di Bagian Bawah Kartu
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(item.status).withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor(item.status).withAlpha(80),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getStatusColor(item.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(item.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
