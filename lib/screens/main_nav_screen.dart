// ==============================================================================
// FILE: lib/screens/main_nav_screen.dart
// PANDUAN: Kerangka navigasi utama aplikasi dengan 4 Tab Bottom Navigation Bar:
// 1. Home (Katalog Karakter / Item Utama)
// 2. Favorites (Daftar Favorit Tersimpan + Dismissible Undo)
// 3. Episodes (Katalog Endpoint Sekunder)
// 4. Profile (Profil Akun, Dark Mode Switch, Edit Profil, & Logout)
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/favorite_provider.dart';
import 'favorite/favorite_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'secondary/secondary_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  // ---------------------------------------------------------------------------
  // [GANTI DISINI SAAT RESPONSI - OPSI TAB NAVIGASI]
  // Jika soal ujian hanya meminta 3 tab (misal tanpa tab Episodes / Tab 3),
  // hapus baris `SecondaryScreen()` di sini dan hapus item Episodes di `destinations` bawah.
  // ---------------------------------------------------------------------------
  final List<Widget> _pages = const [
    HomeScreen(),
    FavoriteScreen(),
    // SecondaryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = context.watch<FavoriteProvider>();

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        // ---------------------------------------------------------------------
        // [GANTI DISINI SAAT RESPONSI] IKON & LABEL BOTTOM NAVIGATION BAR
        // Lihat panduan daftar icon lengkap di: docs/PANDUAN_GANTI_ICON_TEMA.md
        // ---------------------------------------------------------------------
        destinations: [
          // TAB 1: HOME / ENTITAS UTAMA
          // Contoh Tema Makanan: Icons.restaurant_outlined / Icons.restaurant_rounded (label: 'Resto' / 'Kuliner')
          // Contoh Tema Belanja: Icons.storefront_outlined / Icons.storefront_rounded (label: 'Shop' / 'Produk')
          // Contoh Tema Buku:    Icons.menu_book_outlined / Icons.menu_book_rounded (label: 'Buku')
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Home',
          ),

          // TAB 2: FAVORIT
          // Biasanya tetap Icons.favorite_outline & Icons.favorite_rounded untuk semua tema.
          // Bisa diganti Icons.bookmark_border & Icons.bookmark jika tema artikel/buku.
          NavigationDestination(
            icon: Badge(
              isLabelVisible: favoriteProvider.count > 0,
              label: Text('${favoriteProvider.count}'),
              child: const Icon(Icons.shopping_cart_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: favoriteProvider.count > 0,
              label: Text('${favoriteProvider.count}'),
              child: const Icon(Icons.shopping_cart_rounded),
            ),
            label: 'Wishlist',
          ),

          // TAB 3: SEKUNDER / ENDPOINT KEDUA
          // [SANGAT SERING DIUBAH] Sesuaikan dengan endpoint kedua dari soal ujian:
          // Contoh Tema Makanan: Icons.fastfood_outlined / Icons.fastfood_rounded (label: 'Menu' / 'Kategori')
          // Contoh Tema Belanja: Icons.category_outlined / Icons.category_rounded (label: 'Kategori')
          // Contoh Tema TV/Film: Icons.tv_outlined / Icons.tv_rounded (label: 'Episodes')
          // Contoh Tema Buku:    Icons.person_pin_outlined / Icons.person_pin_rounded (label: 'Penulis')
          // const NavigationDestination(
          //   icon: Icon(Icons.tv_outlined),
          //   selectedIcon: Icon(Icons.tv_rounded),
          //   label: 'Episodes',
          // ),

          // TAB 4: PROFIL
          // Umumnya tetap Icons.person_outline / Icons.person_rounded untuk semua tema.
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
