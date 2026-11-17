// ==============================================================================
// FILE: lib/screens/detail/detail_screen.dart
// PANDUAN: Halaman Detail Item & Fitur Kejutan 2 (Catatan Pribadi Hive).
// 1. Menampilkan atribut detail item lengkap (Hero image, status, origin, dll)
// 2. Tombol Favorite sinkron dengan FavoriteProvider + SnackBar
// 3. CRUD Catatan / Ulasan Pribadi per Item ke Hive Box ('notesBox')
//    menggunakan key unik 'username_itemId'.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_helpers.dart';
import '../../models/item_model.dart';
import '../../models/note_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../services/hive_service.dart';
import '../../widgets/custom_text_field.dart';

class DetailScreen extends StatefulWidget {
  // ---------------------------------------------------------------------------
  // [CONFIG FITUR KEJUTAN 8: SALIN & BAGIKAN KE CLIPBOARD]
  // Ubah 'enableShareButton' menjadi false untuk mematikan tombol ini dari UI
  // ---------------------------------------------------------------------------
  static const bool enableShareButton = true;

  final ItemModel item;

  const DetailScreen({super.key, required this.item});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  // Controller form catatan
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  double _rating = 5.0;

  // State catatan aktif yang dimuat dari Hive
  NoteModel? _existingNote;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadNoteFromHive();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // CRUD HIVE: KEY GENERATOR ('username_itemId')
  // ---------------------------------------------------------------------------
  String _getNoteKey() {
    final authProvider = context.read<AuthProvider>();
    final username = authProvider.currentUser?.username ?? 'guest';
    return '${username}_${widget.item.id}';
  }

  // ---------------------------------------------------------------------------
  // 1. READ: MEMUAT CATATAN DARI HIVE BOX
  // ---------------------------------------------------------------------------
  void _loadNoteFromHive() {
    final noteKey = _getNoteKey();

    // CARA KERJA: Ambil raw Map dari notesBox menggunakan key 'username_itemId'
    final rawData = HiveService.notesBox.get(noteKey);

    if (rawData != null) {
      final note = NoteModel.fromMap(rawData as Map);
      setState(() {
        _existingNote = note;
        _titleController.text = note.title;
        _contentController.text = note.content;
        _rating = note.rating;
        _isEditing = false;
      });
    } else {
      setState(() {
        _existingNote = null;
        _titleController.clear();
        _contentController.clear();
        _rating = 5.0;
        _isEditing = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // 2. CREATE & UPDATE: SIMPAN / PERBARUI CATATAN KE HIVE
  // ---------------------------------------------------------------------------
  Future<void> _saveNoteToHive() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      AppHelpers.showSnackBar(
        context,
        'Judul dan isi catatan tidak boleh kosong.',
        isError: true,
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final username = authProvider.currentUser?.username ?? 'guest';
    final noteKey = _getNoteKey();

    final note = NoteModel(
      id: noteKey,
      username: username,
      itemId: widget.item.id,
      title: title,
      content: content,
      rating: _rating,
      createdAt: _existingNote?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // CARA KERJA: Simpan ke Hive Box dalam bentuk Map/JSON
    await HiveService.notesBox.put(noteKey, note.toJson());

    if (!mounted) return;

    AppHelpers.showSnackBar(
      context,
      _existingNote == null
          ? 'Catatan pribadi berhasil disimpan!'
          : 'Catatan pribadi berhasil diperbarui!',
    );

    _loadNoteFromHive();
  }

  // ---------------------------------------------------------------------------
  // 3. DELETE: HAPUS CATATAN DARI HIVE
  // ---------------------------------------------------------------------------
  Future<void> _deleteNoteFromHive() async {
    final confirm = await AppHelpers.showConfirmDialog(
      context,
      title: 'Hapus Catatan',
      message: 'Apakah Anda yakin ingin menghapus catatan pribadi ini?',
      confirmText: 'Hapus',
      isDestructive: true,
    );

    if (confirm && mounted) {
      final noteKey = _getNoteKey();
      // CARA KERJA: Hapus dari Hive Box berdasarkan key
      await HiveService.notesBox.delete(noteKey);

      if (!mounted) return;

      AppHelpers.showSnackBar(context, 'Catatan berhasil dihapus.');
      _loadNoteFromHive();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'alive':
        return const Color(0xFF2E7D32);
      case 'dead':
        return const Color(0xFFD32F2F);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favoriteProvider = context.watch<FavoriteProvider>();
    final isFav = favoriteProvider.isFavorite(widget.item.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.name),
        actions: [
          // -------------------------------------------------------------------
          // [FITUR KEJUTAN 8: SALIN & BAGIKAN INFO KE CLIPBOARD]
          // -------------------------------------------------------------------
          if (DetailScreen.enableShareButton)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Bagikan / Salin Info',
              onPressed: () {
                final textToShare = '''
${widget.item.name}
Status: ${widget.item.status}
Spesies: ${widget.item.species}
Gender: ${widget.item.gender}
Asal: ${widget.item.origin}
''';
                Clipboard.setData(ClipboardData(text: textToShare.trim()));
                AppHelpers.showSnackBar(
                  context,
                  'Info ${widget.item.name} berhasil disalin ke clipboard!',
                );
              },
            ),

          // -------------------------------------------------------------------
          // TOMBOL FAVORITE DI APPBAR
          // -------------------------------------------------------------------
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? Colors.redAccent : null,
            ),
            tooltip: isFav ? 'Hapus dari Favorit' : 'Tambah ke Favorit',
            onPressed: () async {
              final added = await favoriteProvider.toggleFavorite(widget.item);
              if (context.mounted) {
                AppHelpers.showSnackBar(
                  context,
                  added
                      ? '${widget.item.name} ditambahkan ke Favorit'
                      : '${widget.item.name} dihapus dari Favorit',
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          // -------------------------------------------------------------------
          // 1. HEADER GAMBAR UTAMA DENGAN HERO ANIMASI
          // [GANTI DISINI SAAT RESPONSI] Jika key gambar API soal berbeda
          // -------------------------------------------------------------------
          Hero(
            tag: 'item_image_${widget.item.id}',
            child: AspectRatio(
              aspectRatio: 16 / 11,
              child: widget.item.image.isNotEmpty
                  ? Image.network(
                      widget.item.image,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image_rounded, size: 64),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported_rounded, size: 64),
                    ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -------------------------------------------------------------
                // 2. JUDUL & BADGE STATUS
                // -------------------------------------------------------------
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.item.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(widget.item.status).withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _getStatusColor(widget.item.status).withAlpha(80),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getStatusColor(widget.item.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.item.status,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(widget.item.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // -------------------------------------------------------------
                // [GANTI DISINI 5] INFORMASI DETAIL ITEM (KARTU INFORMASI)
                // -------------------------------------------------------------
                // Ubah baris-baris informasi di bawah ini sesuai atribut model barumu:
                // Kamu bisa menambah baris baru, mengubah ikon & label, atau menghapusnya.
                //
                // CONTOH JIKA SOAL PRODUK TOKO:
                // _buildDetailRow(
                //   icon: Icons.attach_money_rounded,
                //   label: 'Harga',
                //   value: '\$${widget.item.gender}', // atau widget.item.price
                // ),
                // const Divider(height: 20),
                // _buildDetailRow(
                //   icon: Icons.category_rounded,
                //   label: 'Kategori',
                //   value: widget.item.status, // atau widget.item.category
                // ),
                // -------------------------------------------------------------
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // [GANTI ICON DISINI - BARIS 1]
                        // Makanan: Icons.category_rounded / Icons.fastfood_rounded (Kategori / Jenis)
                        // Belanja: Icons.category_rounded (Kategori Produk)
                        // Buku:    Icons.person_rounded / Icons.history_edu_rounded (Penulis)
                        _buildDetailRow(
                          icon: Icons.fingerprint_rounded,
                          label: 'Spesies',
                          value: widget.item.species.isNotEmpty
                              ? widget.item.species
                              : 'Tidak diketahui',
                        ),
                        const Divider(height: 20),

                        // [GANTI ICON DISINI - BARIS 2]
                        // Makanan: Icons.attach_money_rounded / Icons.payments_rounded (Harga / Kisaran)
                        // Belanja: Icons.attach_money_rounded / Icons.price_change_rounded (Harga)
                        // Buku:    Icons.calendar_month_rounded (Tahun Terbit)
                        _buildDetailRow(
                          icon: Icons.wc_rounded,
                          label: 'Gender',
                          value: widget.item.gender.isNotEmpty
                              ? widget.item.gender
                              : 'Tidak diketahui',
                        ),
                        const Divider(height: 20),

                        // [GANTI ICON DISINI - BARIS 3]
                        // Makanan: Icons.star_rounded / Icons.grade_rounded (Rating Restoran / Masakan)
                        // Belanja: Icons.star_rounded / Icons.inventory_2_rounded (Stok / Rating)
                        // Buku:    Icons.pages_rounded / Icons.import_contacts_rounded (Jumlah Halaman)
                        _buildDetailRow(
                          icon: Icons.public_rounded,
                          label: 'Asal (Origin)',
                          value: widget.item.origin.isNotEmpty
                              ? widget.item.origin
                              : 'Tidak diketahui',
                        ),
                        const Divider(height: 20),

                        // [GANTI ICON DISINI - BARIS 4]
                        // Makanan: Icons.location_on_rounded / Icons.place_rounded (Alamat / Kota Resto)
                        // Belanja: Icons.local_shipping_rounded (Pengiriman / Toko)
                        // Buku:    Icons.business_rounded (Penerbit)
                        _buildDetailRow(
                          icon: Icons.location_on_rounded,
                          label: 'Lokasi Terakhir',
                          value: widget.item.location.isNotEmpty
                              ? widget.item.location
                              : 'Tidak diketahui',
                        ),
                        const Divider(height: 20),

                        // [GANTI ICON DISINI - BARIS 5]
                        // Makanan: Icons.restaurant_menu_rounded (Daftar Menu Tersedia)
                        // Belanja: Icons.sell_rounded (Tag / Promo)
                        // Film:    Icons.tv_rounded / Icons.theaters_rounded (Episode / Durasi)
                        _buildDetailRow(
                          icon: Icons.tv_rounded,
                          label: 'Jumlah Episode',
                          value: '${widget.item.episode.length} Episode',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // -------------------------------------------------------------
                // [GANTI DISINI 6] BOX DESKRIPSI (DESCRIPTION DARI API)
                // -------------------------------------------------------------
                // Menampilkan teks deskripsi panjang / sinopsis / overview dari API.
                // Box ini otomatis tampil jika ada field description/desc/overview/synopsis.
                // -------------------------------------------------------------
                if (widget.item.description.isNotEmpty) ...[
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
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        widget.item.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // -------------------------------------------------------------
                // 4. FITUR KEJUTAN 2: CATATAN / REVIEW PRIBADI (HIVE CRUD)
                // -------------------------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Catatan Pribadi',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_existingNote != null && !_isEditing)
                      TextButton.icon(
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Edit'),
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Tampilkan Catatan yang Tersimpan ATAU Form Input
                if (_existingNote != null && !_isEditing)
                  _buildExistingNoteCard()
                else
                  _buildNoteFormCard(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  /// Tampilan Catatan yang sudah tersimpan di Hive
  Widget _buildExistingNoteCard() {
    final theme = Theme.of(context);
    final note = _existingNote!;

    return Card(
      color: theme.colorScheme.primary.withAlpha(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < note.rating.round()
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 18,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              note.content,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Tersimpan di Hive (${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year})',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                  tooltip: 'Hapus Catatan',
                  onPressed: _deleteNoteFromHive,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Form Input Tambah / Edit Catatan Hive
  Widget _buildNoteFormCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(
              controller: _titleController,
              labelText: 'Judul Catatan / Ulasan',
              hintText: 'Contoh: Karakter Favorit / Kesan Pertama',
              prefixIcon: Icons.title_rounded,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _contentController,
              labelText: 'Isi Catatan',
              hintText: 'Tuliskan catatan atau pendapat Anda mengenai karakter ini...',
              prefixIcon: Icons.notes_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            // Rating Slider
            Row(
              children: [
                const Text('Rating: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Slider(
                    value: _rating,
                    min: 1.0,
                    max: 5.0,
                    divisions: 4,
                    label: _rating.toString(),
                    onChanged: (val) {
                      setState(() {
                        _rating = val;
                      });
                    },
                  ),
                ),
                Text(
                  '${_rating.toInt()} ⭐',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_isEditing) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                        });
                      },
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveNoteToHive,
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: Text(_isEditing ? 'Perbarui' : 'Simpan Catatan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
