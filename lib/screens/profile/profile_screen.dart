// ==============================================================================
// FILE: lib/screens/profile/profile_screen.dart
// PANDUAN: Halaman Profil Pengguna (Tab 4).
// Menampilkan:
// 1. Informasi akun user aktif dari Hive 'usersBox' (termasuk foto profil)
// 2. Fitur ganti foto profil (Galeri, Kamera, Avatar Preset, & URL Foto)
// 3. Kartu statistik ringkas (Total Favorit & Total Catatan Pribadi)
// 4. Fitur Kejutan 1: Edit Profil & Ganti Password (Update Hive)
// 5. Fitur Pilihan Warna Tema Utama (Palet Warna Aksen SharedPreferences)
// 6. Fitur Kejutan 5: Switch Dark Mode / Light Mode (SharedPreferences)
// 7. Tombol Logout dengan Dialog Konfirmasi
// ==============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_helpers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/hive_service.dart';
import '../../widgets/custom_text_field.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ---------------------------------------------------------------------------
  // HELPER UNTUK MENAMPILKAN GAMBAR PROFIL (URL vs FILE LOKAL)
  // ---------------------------------------------------------------------------
  ImageProvider? _getProfileImageProvider(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) return null;
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return NetworkImage(imagePath);
    }
    final file = File(imagePath);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // FITUR PILIH FOTO PROFIL (GALERI, KAMERA, PRESET, & URL)
  // ---------------------------------------------------------------------------
  void _showProfilePhotoPicker() {
    final authProvider = context.read<AuthProvider>();
    final urlController = TextEditingController();

    // 5 Preset Avatar Rick & Morty yang langsung siap pakai
    final presetAvatars = [
      {'name': 'Rick', 'url': 'https://rickandmortyapi.com/api/character/avatar/1.jpeg'},
      {'name': 'Morty', 'url': 'https://rickandmortyapi.com/api/character/avatar/2.jpeg'},
      {'name': 'Summer', 'url': 'https://rickandmortyapi.com/api/character/avatar/3.jpeg'},
      {'name': 'Beth', 'url': 'https://rickandmortyapi.com/api/character/avatar/4.jpeg'},
      {'name': 'Jerry', 'url': 'https://rickandmortyapi.com/api/character/avatar/5.jpeg'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pilih Foto Profil',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tombol Pilih dari Galeri & Kamera
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Galeri HP'),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        try {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 800,
                            maxHeight: 800,
                            imageQuality: 85,
                          );
                          if (picked != null && mounted) {
                            await authProvider.updateProfileImage(picked.path);
                            if (mounted) {
                              AppHelpers.showSnackBar(
                                context,
                                'Foto profil berhasil diperbarui dari Galeri!',
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            AppHelpers.showSnackBar(
                              context,
                              'Gagal mengambil gambar dari galeri: $e',
                              isError: true,
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Kamera'),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        try {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(
                            source: ImageSource.camera,
                            maxWidth: 800,
                            maxHeight: 800,
                            imageQuality: 85,
                          );
                          if (picked != null && mounted) {
                            await authProvider.updateProfileImage(picked.path);
                            if (mounted) {
                              AppHelpers.showSnackBar(
                                context,
                                'Foto profil berhasil diambil dari Kamera!',
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            AppHelpers.showSnackBar(
                              context,
                              'Gagal membuka kamera: $e',
                              isError: true,
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Pilihan Avatar Karakter Siap Pakai
              const Text(
                'Atau Pilih Avatar Karakter:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: presetAvatars.length,
                  separatorBuilder: (c, i) => const SizedBox(width: 14),
                  itemBuilder: (itemCtx, index) {
                    final avatar = presetAvatars[index];
                    return InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        await authProvider.updateProfileImage(avatar['url']!);
                        if (!mounted) return;
                        AppHelpers.showSnackBar(
                          context,
                          'Foto profil diubah ke avatar ${avatar['name']}!',
                        );
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(avatar['url']!),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            avatar['name']!,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Masukkan URL Gambar Manual
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: urlController,
                      labelText: 'URL Gambar Online',
                      hintText: 'https://...',
                      prefixIcon: Icons.link_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (urlController.text.trim().isNotEmpty) {
                        Navigator.pop(ctx);
                        await authProvider.updateProfileImage(urlController.text.trim());
                        if (mounted) {
                          AppHelpers.showSnackBar(
                            context,
                            'Foto profil berhasil diperbarui dari URL!',
                          );
                        }
                      }
                    },
                    child: const Text('Gunakan'),
                  ),
                ],
              ),

              // Tombol Hapus Foto Profil jika sedang ada foto
              if (authProvider.currentUser?.profileImage.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  label: const Text(
                    'Hapus Foto Profil',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await authProvider.updateProfileImage('');
                    if (mounted) {
                      AppHelpers.showSnackBar(context, 'Foto profil dihapus.');
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FITUR KEJUTAN 1: MODAL DIALOG EDIT PROFIL & GANTI PASSWORD
  // Memperbarui fullName, email, dan password user aktif di Hive 'usersBox'
  // ---------------------------------------------------------------------------
  void _showEditProfileDialog() {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: currentUser.fullName);
    final emailController = TextEditingController(text: currentUser.email);
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Profil & Password',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Edit Nama Lengkap
                CustomTextField(
                  controller: nameController,
                  labelText: 'Nama Lengkap',
                  prefixIcon: Icons.person_outline,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama lengkap tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Edit Email
                CustomTextField(
                  controller: emailController,
                  labelText: 'Email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),

                // Ganti Password Baru (Opsional)
                CustomTextField(
                  controller: passwordController,
                  labelText: 'Password Baru (Kosongkan jika tidak diubah)',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: (val) {
                    if (val != null && val.isNotEmpty && val.length < 4) {
                      return 'Password baru minimal 4 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Konfirmasi Password Baru
                CustomTextField(
                  controller: confirmPasswordController,
                  labelText: 'Konfirmasi Password Baru',
                  prefixIcon: Icons.lock_reset_outlined,
                  isPassword: true,
                  validator: (val) {
                    if (passwordController.text.isNotEmpty &&
                        val != passwordController.text) {
                      return 'Konfirmasi password tidak cocok';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Tombol Simpan Perubahan
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_rounded, size: 20),
                  label: const Text('Simpan Perubahan'),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final success = await authProvider.updateProfile(
                      fullName: nameController.text,
                      email: emailController.text,
                      newPassword: passwordController.text.isNotEmpty
                          ? passwordController.text
                          : null,
                    );

                    if (ctx.mounted && mounted) {
                      Navigator.pop(ctx);
                      AppHelpers.showSnackBar(
                        context,
                        success
                            ? 'Profil berhasil diperbarui di Hive!'
                            : 'Gagal memperbarui profil.',
                        isError: !success,
                      );
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final favoriteProvider = context.watch<FavoriteProvider>();
    final currentUser = authProvider.currentUser;

    // Hitung catatan milik user ini dari Hive
    final userNotesCount = currentUser != null
        ? HiveService.getUserNotes(currentUser.username).length
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit Profil',
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // -------------------------------------------------------------------
          // 1. KARTU INFORMASI AKUN UTAMA + FOTO PROFIL INTERAKTIF
          // -------------------------------------------------------------------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: theme.colorScheme.primary.withAlpha(40),
                        backgroundImage: _getProfileImageProvider(currentUser?.profileImage),
                        child: (currentUser?.profileImage.isEmpty ?? true)
                            ? Text(
                                (currentUser?.fullName.isNotEmpty == true)
                                    ? currentUser!.fullName[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Material(
                          color: theme.colorScheme.primary,
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _showProfilePhotoPicker,
                            child: const Padding(
                              padding: EdgeInsets.all(7.0),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentUser?.fullName ?? 'Nama Pengguna',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${currentUser?.username ?? 'username'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  if (currentUser?.email.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      currentUser!.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Tersimpan di Hive NoSQL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // -------------------------------------------------------------------
          // 2. KARTU STATISTIK RINGKAS
          // -------------------------------------------------------------------
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          '${favoriteProvider.count}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Item Favorit',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.notes_rounded, color: theme.colorScheme.primary, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          '$userNotesCount',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Catatan Pribadi',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // -------------------------------------------------------------------
          // 3. FITUR KEJUTAN 1: PINTASAN EDIT PROFIL
          // -------------------------------------------------------------------
          Card(
            child: ListTile(
              leading: Icon(Icons.manage_accounts_rounded, color: theme.colorScheme.primary),
              title: const Text('Edit Profil & Password'),
              subtitle: const Text('Update data user langsung ke Hive'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _showEditProfileDialog,
            ),
          ),
          const SizedBox(height: 12),

          // -------------------------------------------------------------------
          // 4. FITUR PILIH WARNA TEMA UTAMA (SHARED PREFERENCES)
          // -------------------------------------------------------------------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.palette_rounded, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          const Text(
                            'Warna Tema Utama',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: themeProvider.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(40),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pilih warna aksen aplikasi:',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: AppTheme.presetColors.map((preset) {
                        final color = preset['color'] as Color;
                        final isSelected =
                            themeProvider.primaryColor.toARGB32() == color.toARGB32();
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: InkWell(
                            onTap: () => themeProvider.setPrimaryColor(color),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: color.withAlpha(120),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // -------------------------------------------------------------------
          // 5. FITUR KEJUTAN 5: PENGATURAN DARK MODE (SHARED PREFERENCES)
          // -------------------------------------------------------------------
          Card(
            child: SwitchListTile(
              secondary: Icon(
                themeProvider.isDarkMode
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: themeProvider.isDarkMode ? Colors.amber : Colors.orange,
              ),
              title: const Text('Mode Gelap (Dark Mode)'),
              subtitle: const Text('Tersimpan di SharedPreferences'),
              value: themeProvider.isDarkMode,
              onChanged: (val) {
                themeProvider.toggleTheme(val);
              },
            ),
          ),
          const SizedBox(height: 24),

          // -------------------------------------------------------------------
          // 6. TOMBOL LOGOUT DENGAN KONFIRMASI
          // -------------------------------------------------------------------
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('KELUAR DARI AKUN'),
            onPressed: () async {
              final confirm = await AppHelpers.showConfirmDialog(
                context,
                title: 'Konfirmasi Logout',
                message: 'Apakah Anda yakin ingin keluar dari akun ini?',
                confirmText: 'Keluar',
                isDestructive: true,
              );

              if (confirm && context.mounted) {
                await authProvider.logout();
                if (context.mounted) {
                  AppHelpers.showSnackBar(context, 'Berhasil keluar dari akun.');
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
