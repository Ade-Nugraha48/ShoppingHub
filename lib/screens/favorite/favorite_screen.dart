// ==============================================================================
// FILE: lib/screens/favorite/favorite_screen.dart
// PANDUAN: Halaman Daftar Favorit (Tab 2).
// Menampilkan item yang tersimpan di SharedPreferences (via FavoriteProvider).
// Memiliki fitur:
// 1. Swipe-to-Delete (Dismissible) dengan latar belakang merah.
// 2. Tombol UNDO pada SnackBar untuk membatalkan penghapusan secara instan.
// 3. Sinkronisasi otomatis dengan ikon hati di HomeScreen.
// 4. EmptyStateWidget jika belum ada item favorit.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/app_helpers.dart';
import '../../models/item_model.dart';
import '../../providers/favorite_provider.dart';
import '../../widgets/state_widgets.dart';
import '../detail/detail_screen.dart';

class FavoriteScreen extends StatelessWidget {
  // ---------------------------------------------------------------------------
  // [CONFIG FITUR KEJUTAN 9: HAPUS SEMUA FAVORIT]
  // Ubah 'enableClearAllFavorites' menjadi false untuk menonaktifkan tombol ini dari UI
  // ---------------------------------------------------------------------------
  static const bool enableClearAllFavorites = true;

  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = context.watch<FavoriteProvider>();
    final favorites = favoriteProvider.favorites;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Karakter Favorit'),
        actions: [
          // -------------------------------------------------------------------
          // [FITUR KEJUTAN 9: TOMBOL HAPUS SEMUA FAVORIT]
          // Menghapus seluruh data favorit dengan popup konfirmasi dialog
          // -------------------------------------------------------------------
          if (enableClearAllFavorites && favorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Hapus Semua Favorit',
              onPressed: () async {
                final confirm = await AppHelpers.showConfirmDialog(
                  context,
                  title: 'Hapus Semua Favorit?',
                  message:
                      'Semua ${favorites.length} karakter favorit akan dihapus dari penyimpanan.',
                  confirmText: 'Hapus Semua',
                  cancelText: 'Batal',
                  isDestructive: true,
                );

                if (confirm == true) {
                  await favoriteProvider.clearAllFavorites();
                  if (context.mounted) {
                    AppHelpers.showSnackBar(
                      context,
                      'Semua favorit berhasil dihapus.',
                    );
                  }
                }
              },
            ),

          if (favorites.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Badge(
                  label: Text('${favorites.length}'),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: favorites.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.favorite_border_rounded,
              title: 'Belum Ada Favorit',
              message: 'Tandai karakter favorit Anda dengan menekan ikon hati di halaman utama.',
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final item = favorites[index];

                return Dismissible(
                  // Key unik wajib untuk Dismissible
                  key: ValueKey('fav_${item.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F), // Merah
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Hapus',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.delete_sweep_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                  onDismissed: (direction) {
                    final ItemModel deletedItem = item;
                    final int deletedIndex = index;

                    // Hapus dari state & SharedPreferences
                    favoriteProvider.removeFavorite(deletedItem.id);

                    // Tampilkan SnackBar dengan tombol UNDO
                    AppHelpers.showSnackBar(
                      context,
                      '${deletedItem.name} dihapus dari favorit',
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'UNDO',
                        textColor: Colors.yellowAccent,
                        onPressed: () {
                          // Batalkan penghapusan & sisipkan kembali
                          favoriteProvider.insertFavorite(
                            deletedIndex,
                            deletedItem,
                          );
                        },
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: item.image.isNotEmpty
                            ? Image.network(
                                item.image,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Container(
                                  width: 56,
                                  height: 56,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.broken_image_rounded),
                                ),
                              )
                            : Container(
                                width: 56,
                                height: 56,
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.image_not_supported_rounded,
                                ),
                              ),
                      ),
                      title: Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('${item.species} • ${item.gender}'),
                          const SizedBox(height: 4),
                          Text(
                            'Kategori: ${item.status}',
                            style: TextStyle(
                              fontSize: 12,
                              color: item.isAlive
                                  ? const Color(0xFF2E7D32)
                                  : (item.isDead ? Colors.red : Colors.grey),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(item: item),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
