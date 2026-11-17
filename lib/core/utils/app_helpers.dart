// ==============================================================================
// FILE: lib/core/utils/app_helpers.dart
// PANDUAN: Kumpulan fungsi pembantu (Helper) untuk UI seperti SnackBar,
// Dialog Konfirmasi, dan Format Teks agar kode screen tetap ringkas dan bersih.
// ==============================================================================

import 'package:flutter/material.dart';

class AppHelpers {
  // ---------------------------------------------------------------------------
  // 1. HELPER SNACKBAR
  // Menampilkan pesan mengambang di bawah layar (sukses atau error).
  // ---------------------------------------------------------------------------
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Sembunyikan SnackBar sebelumnya jika ada
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError
            ? const Color(0xFFE53935) // Merah untuk error
            : const Color(0xFF2E7D32), // Hijau untuk sukses/info
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: duration,
        action: action,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. HELPER DIALOG KONFIRMASI
  // Menampilkan popup dialog Ya/Tidak (misal: Konfirmasi Logout atau Hapus).
  // ---------------------------------------------------------------------------
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Ya',
    String cancelText = 'Batal',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            style: isDestructive
                ? ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                  )
                : null,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}

