import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../beranda/beranda_page.dart';
import '../konsultasi/daftar_dokter_page.dart';
import '../profil/menu_profil_page.dart';
import '../riwayat_konsultasi/daftar_riwayat_page.dart';

/// Model sederhana untuk data Resep MPASI.
/// Nantinya dapat diganti dengan model dari backend PMIK/Superadmin.
class ResepMpasi {
  final String id;
  final String title;
  final String author;
  final String date;
  final String category;
  final String assetImage;
  final double energi;
  final double lemak;
  final double protein;
  final int porsi;
  final List<String> bahan;
  final List<String> bahanPelapis;
  final List<String> buah;
  final List<String> caraMembuat;

  const ResepMpasi({
    required this.id,
    required this.title,
    required this.author,
    required this.date,
    required this.category,
    required this.assetImage,
    required this.energi,
    required this.lemak,
    required this.protein,
    required this.porsi,
    required this.bahan,
    this.bahanPelapis = const [],
    this.buah = const [],
    required this.caraMembuat,
  });
}

/// Halaman "Detail Resep MPASI" PediaGrow.
///
/// Data resep bersumber sepenuhnya dari [widget.resep] yang dikirim oleh
/// halaman "Daftar Resep MPASI" (hasil query ke SQLite lokal yang dikelola
/// PMIK/Superadmin). Halaman ini TIDAK memiliki dummy data hardcoded
/// sebagai sumber data utama — konsisten dengan daftar_resep_page.dart.
///
/// Jika [widget.resep] null (mis. halaman dibuka tanpa data resep yang
/// valid), halaman menampilkan empty state alih-alih data palsu.
///
/// Struktur scrolling:
/// - Header FIXED (back button + judul "Detail Resep")
/// - Konten resep SCROLLABLE (gambar, tanggal, judul, penulis, nutrisi, bahan, cara membuat)
/// - Bottom Navigation FIXED
class DetailResepPage extends StatefulWidget {
  final ResepMpasi? resep;

  const DetailResepPage({super.key, this.resep});

  @override
  State<DetailResepPage> createState() => _DetailResepPageState();
}

class _DetailResepPageState extends State<DetailResepPage> {
  // Design Tokens PediaGrow (konsisten dengan daftar_resep_page.dart)
  static const Color colorPrimaryBlue = Color(0xFF2A85FF);
  static const Color colorSoftBlue = Color(0xFFEBF5FF);
  static const Color colorWhite = Color(0xFFFFFFFF);
  static const Color colorTextPrimary = Color(0xFF1A202C);
  // Design tokens resmi — abu tua & abu muda
  static const Color colorGreyDark = Color(0xFF7F7F7F); // abu tua
  static const Color colorGreyLight = Color(0xFFC5C5C5); // abu muda

  // Alias agar konsisten dengan pemakaian sebelumnya di file ini
  static const Color colorTextSecondary = colorGreyDark;
  static const Color colorTextMuted = colorGreyDark;
  static const Color colorSearchBg = Color(0xFFF1F5F9);
  static const Color colorBorder = colorGreyLight;

  void _onBackPressed() {
    Navigator.of(context).maybePop();
  }

  // ===========================================================================
  // BUILD METHOD UTAMA
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final resep = widget.resep;

    return Scaffold(
      backgroundColor: colorWhite,
      // Bottom navigation fixed di Scaffold.bottomNavigationBar
      bottomNavigationBar: _buildBottomNavigation(),
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER FIXED (Back Button + Judul "Detail Resep")
            _buildHeader(),

            // 2. KONTEN RESEP — SCROLLABLE jika ada data, EMPTY STATE jika tidak
            Expanded(
              child: resep == null
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _buildRecipeContent(resep),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. HEADER FIXED — tinggi PERSIS 56dp
  //    Back Button 12dp dari kiri layar + Judul "Detail Resep" 12dp setelahnya
  // ===========================================================================

  Widget _buildHeader() {
    return Container(
      height: 56,
      width: double.infinity,
      color: colorWhite,
      padding: const EdgeInsets.only(left: 12, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tombol back
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _onBackPressed,
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: colorTextPrimary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Judul "Detail Resep" berjarak 12dp dari tombol back
          Text(
            'Detail Resep',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // EMPTY STATE — ditampilkan jika resep tidak ditemukan / belum tersedia
  // ===========================================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.restaurant_menu_outlined,
              size: 52,
              color: Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 14),
            Text(
              'Data resep tidak ditemukan',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorTextMuted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Silakan kembali ke daftar resep\ndan pilih resep yang tersedia.',
              style: GoogleFonts.lato(
                fontSize: 13,
                color: colorTextMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. KONTEN RESEP (Scrollable — gambar, tanggal, judul, nutrisi, bahan, cara)
  // ===========================================================================

  Widget _buildRecipeContent(ResepMpasi resep) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gambar Resep full-width dengan border radius
        _buildRecipeImage(resep),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Tanggal
              Text(
                resep.date,
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: colorTextMuted,
                ),
              ),
              const SizedBox(height: 6),

              // Judul Resep
              Text(
                resep.title,
                style: GoogleFonts.lato(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: colorTextPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),

              // Penulis
              Text(
                'Ditulis oleh ${resep.author}',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: colorTextMuted,
                ),
              ),
              const SizedBox(height: 16),

              // Informasi Nutrisi
              _buildNutritionInfo(resep),
              const SizedBox(height: 20),

              // Divider tipis
              Divider(color: colorBorder, thickness: 1, height: 1),
              const SizedBox(height: 16),

              // Bagian Bahan
              if (resep.bahan.isNotEmpty) ...[
                _buildSectionTitle('Bahan'),
                const SizedBox(height: 8),
                _buildBulletList(resep.bahan),
                const SizedBox(height: 16),
              ],

              // Bagian Bahan Pelapis
              if (resep.bahanPelapis.isNotEmpty) ...[
                _buildSectionTitle('Bahan Pelapis'),
                const SizedBox(height: 8),
                _buildBulletList(resep.bahanPelapis),
                const SizedBox(height: 16),
              ],

              // Bagian Buah
              if (resep.buah.isNotEmpty) ...[
                _buildSectionTitle('Buah'),
                const SizedBox(height: 8),
                _buildBulletList(resep.buah),
                const SizedBox(height: 16),
              ],

              // Cara Membuat
              if (resep.caraMembuat.isNotEmpty) ...[
                _buildSectionTitle('Cara Membuat'),
                const SizedBox(height: 8),
                _buildNumberedList(resep.caraMembuat),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Gambar Resep — full width dengan margin horizontal dan border radius
  Widget _buildRecipeImage(ResepMpasi resep) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.asset(
            resep.assetImage,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: colorSoftBlue,
              child: const Center(
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  color: colorPrimaryBlue,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Informasi Nutrisi — 2 kolom (Energi+Protein | Lemak+Porsi)
  Widget _buildNutritionInfo(ResepMpasi resep) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: BoxDecoration(
        color: colorSearchBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                _buildNutritionItem(
                  icon: Icons.local_fire_department_outlined,
                  iconColor: const Color(0xFFFF8C00),
                  label: 'Energi',
                  value: '${resep.energi.toStringAsFixed(0)} kkal',
                ),
                const SizedBox(height: 14),
                _buildNutritionItem(
                  icon: Icons.science_outlined,
                  iconColor: const Color(0xFF00B087),
                  label: 'Protein',
                  value: '${resep.protein} gr',
                ),
              ],
            ),
          ),
          Container(width: 1, height: 64, color: colorBorder),
          Expanded(
            child: Column(
              children: [
                _buildNutritionItem(
                  icon: Icons.opacity_outlined,
                  iconColor: const Color(0xFF4DA3FF),
                  label: 'Lemak',
                  value: '${resep.lemak} gr',
                ),
                const SizedBox(height: 14),
                _buildNutritionItem(
                  icon: Icons.restaurant_outlined,
                  iconColor: const Color(0xFFFF6B6B),
                  label: 'Porsi',
                  value: '${resep.porsi} porsi',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: colorTextMuted,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colorTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Judul section (Bahan, Bahan Pelapis, Buah, Cara Membuat)
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.lato(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: colorTextPrimary,
      ),
    );
  }

  // Daftar dengan bullet point (lingkaran kecil)
  Widget _buildBulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 8),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: colorTextSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: colorTextSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Daftar dengan nomor urut (1. 2. 3. ...)
  Widget _buildNumberedList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final item = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                child: Text(
                  '$index.',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorTextSecondary,
                    height: 1.5,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: colorTextSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // BOTTOM NAVIGATION BAR FIXED (4 Menu)
  // Diletakkan di Scaffold.bottomNavigationBar agar selalu fixed di bawah.
  // ===========================================================================

  Widget _buildBottomNavigation() {
    return Container(
      height: 58,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: colorWhite,
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. Beranda
          _buildNavItem(
            icon: Icons.home_outlined,
            label: 'Beranda',
            isActive: false,
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          // 2. Konsultasi
          _buildNavItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Konsultasi',
            isActive: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DaftarDokterPage(),
                ),
              );
            },
          ),
          // 3. Riwayat Konsultasi
          _buildNavItem(
            icon: Icons.assignment_outlined,
            label: 'Riwayat Konsultasi',
            isActive: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DaftarRiwayatPage(),
                ),
              );
            },
          ),
          // 4. Profil Ibu
          _buildNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profil Ibu',
            isActive: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MenuProfilPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final color = isActive ? colorPrimaryBlue : colorTextMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 75,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 10.5,
                  color: color,
                  fontWeight:
                      isActive ? FontWeight.bold : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}