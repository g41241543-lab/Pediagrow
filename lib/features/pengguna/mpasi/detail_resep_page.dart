import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/storage_service.dart';
import '../../../models/resep_mpasi_model.dart';


/// Model data untuk Resep MPASI pada halaman detail.
/// Kompatibel dengan [ResepMpasiModel] dari database PMIK Superadmin.
class ResepMpasi {
  final String id;
  final String title;
  final String author;
  final String date;
  final String category;
  final String assetImage;
  final String? imageUrl;
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
    this.imageUrl,
    required this.energi,
    required this.lemak,
    required this.protein,
    required this.porsi,
    required this.bahan,
    this.bahanPelapis = const [],
    this.buah = const [],
    required this.caraMembuat,
  });

  /// Factory untuk konversi dari [ResepMpasiModel] data service PMIK Superadmin
  factory ResepMpasi.fromModel(ResepMpasiModel m) {
    return ResepMpasi(
      id: m.id?.toString() ?? '',
      title: m.judul,
      author: (m.penulis == null || m.penulis!.trim().isEmpty)
          ? 'Pego'
          : m.penulis!,
      date: m.tanggal,
      category: m.kategoriUsia,
      assetImage: m.assetImagePath ?? '',
      imageUrl: m.imageUrl,
      energi: m.energiKkal ?? 0,
      lemak: m.lemakGr ?? 0,
      protein: m.proteinGr ?? 0,
      porsi: m.porsi ?? 1,
      bahan: m.bahan,
      bahanPelapis: m.bahanPelapis,
      buah: m.buah,
      caraMembuat: m.caraMembuat,
    );
  }
}

/// Halaman "Detail Resep MPASI" PediaGrow.
///
/// Data resep bersumber secara dinamis dari [resepModel] atau [resep] yang
/// dikirim oleh halaman "Daftar Resep MPASI" (hasil query database yang diinput
/// oleh PMIK/Superadmin).
///
/// Fitur:
/// - Header FIXED (back button 12dp dari kiri + judul "Detail Resep")
/// - Gambar Resep proporsional (16:9), mendukung asset lokal & URL remote PMIK
/// - Metadata Tanggal, Judul, Penulis ("Ditulis oleh Pego" / "PMIK Superadmin")
/// - 4 Kartu Nutrisi (Energi, Protein, Lemak, Porsi)
/// - Daftar Bahan (Bullet list)
/// - Daftar Bahan Pelapis (opsional, jika ada)
/// - Rekomendasi Buah pendamping (opsional, jika ada)
/// - Langkah-langkah Cara Membuat (Numbered list rapi)
class DetailResepPage extends StatefulWidget {
  final ResepMpasi? resep;
  final ResepMpasiModel? resepModel;

  const DetailResepPage({
    super.key,
    this.resep,
    this.resepModel,
  });

  @override
  State<DetailResepPage> createState() => _DetailResepPageState();
}

class _DetailResepPageState extends State<DetailResepPage> {
  // Design Tokens PediaGrow — Diselaraskan 100% dengan Detail Artikel
  static const Color colorWhite = Color(0xFFFFFFFF);

  ResepMpasi? get _effectiveResep {
    if (widget.resepModel != null) {
      return ResepMpasi.fromModel(widget.resepModel!);
    }
    return widget.resep;
  }

  void _onBackPressed() {
    Navigator.of(context).maybePop();
  }

  // ===========================================================================
  // BUILD METHOD UTAMA
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resep = _effectiveResep;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1014) : colorWhite,
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER FIXED (Back Button + Judul "Detail Resep")
            _buildHeader(isDark),

            // 2. KONTEN RESEP — SCROLLABLE jika ada data, EMPTY STATE jika tidak
            Expanded(
              child: resep == null
                  ? _buildEmptyState(isDark)
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _buildRecipeContent(resep, isDark),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. HEADER FIXED — tinggi 56dp
  //    Back Button 12dp dari pinggir layar + Judul "Detail Resep" (Lato 20 bold)
  // ===========================================================================

  Widget _buildHeader(bool isDark) {
    return Container(
      height: 56,
      width: double.infinity,
      color: isDark ? const Color(0xFF0B1014) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tombol Kembali
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _onBackPressed,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.arrow_back,
                  size: 24,
                  color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Judul Halaman
          Expanded(
            child: Text(
              'Detail Resep',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // EMPTY STATE — ditampilkan jika resep tidak ditemukan / belum tersedia
  // ===========================================================================

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant_menu_outlined,
              size: 52,
              color: isDark ? const Color(0xFF667781) : const Color(0xFFBDBDBD),
            ),
            const SizedBox(height: 14),
            Text(
              'Data resep tidak ditemukan',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Silakan kembali ke daftar resep\ndan pilih resep yang tersedia.',
              style: GoogleFonts.lato(
                fontSize: 13,
                color: isDark ? const Color(0xFF8696A0) : const Color(0xFF8E8E93),
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
  //    Padding horizontal 20dp konsisten dengan Detail Artikel
  // ===========================================================================

  Widget _buildRecipeContent(ResepMpasi resep, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gambar Resep Hero Utama
        _buildRecipeImage(resep, isDark),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tanggal Publikasi (Lato 16sp abu-abu lembut)
              Text(
                resep.date,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: isDark ? const Color(0xFF8696A0) : const Color(0xFF8E8E93),
                ),
              ),
              const SizedBox(height: 6),

              // Judul Resep (Lato 18sp bold)
              Text(
                resep.title,
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),

              // Penulis PMIK
              Text(
                'Ditulis oleh ${resep.author}',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isDark ? const Color(0xFF8696A0) : const Color(0xFF8E8E93),
                ),
              ),
              const SizedBox(height: 16),

              // Informasi Nutrisi
              _buildNutritionInfo(resep, isDark),
              const SizedBox(height: 20),

              // Garis pemisah halus
              Divider(
                color: isDark ? const Color(0xFF2C363D) : const Color(0xFFF1F2F6),
                thickness: 1,
                height: 1,
              ),
              const SizedBox(height: 20),

              // Bagian Bahan
              if (resep.bahan.isNotEmpty) ...[
                _buildSectionTitle('Bahan', isDark),
                const SizedBox(height: 8),
                _buildBulletList(resep.bahan, isDark),
                const SizedBox(height: 20),
              ],

              // Bagian Bahan Pelapis (opsional jika ada)
              if (resep.bahanPelapis.isNotEmpty) ...[
                _buildSectionTitle('Bahan Pelapis', isDark),
                const SizedBox(height: 8),
                _buildBulletList(resep.bahanPelapis, isDark),
                const SizedBox(height: 20),
              ],

              // Bagian Buah (opsional jika ada)
              if (resep.buah.isNotEmpty) ...[
                _buildSectionTitle('Buah', isDark),
                const SizedBox(height: 8),
                _buildBulletList(resep.buah, isDark),
                const SizedBox(height: 20),
              ],

              // Cara Membuat
              if (resep.caraMembuat.isNotEmpty) ...[
                _buildSectionTitle('Cara Membuat', isDark),
                const SizedBox(height: 8),
                _buildNumberedList(resep.caraMembuat, isDark),
                const SizedBox(height: 24),
              ],

              // Padding ekstra bawah agar nyaman dibaca
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  // Gambar Resep — sudut membulat modern 18dp sesuai Detail Artikel
  Widget _buildRecipeImage(ResepMpasi resep, bool isDark) {
    // Prioritaskan imageUrl (Firebase) atas assetImage (lokal/bawaan)
    final imagePath =
        (resep.imageUrl != null && resep.imageUrl!.isNotEmpty)
            ? resep.imageUrl!
            : resep.assetImage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2228) : const Color(0xFFF1F2F6),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: StorageService.buildImageWidget(
              imagePath,
              width: double.infinity,
              fit: BoxFit.cover,
              errorWidget: _buildImagePlaceholder(isDark),
            ),
          ),
        ),
      ),
    );
  }

  // Placeholder abu-abu terang sesuai detail artikel
  Widget _buildImagePlaceholder(bool isDark) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: isDark ? const Color(0xFF1A2228) : const Color(0xFFEEEEEE),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              size: 52,
              color: isDark ? const Color(0xFF667781) : const Color(0xFFBDBDBD),
            ),
            const SizedBox(height: 8),
            Text(
              'Tidak ada gambar resep',
              style: GoogleFonts.lato(
                fontSize: 13,
                color: isDark ? const Color(0xFF8696A0) : const Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Informasi Nutrisi — 2 kolom (Energi+Protein | Lemak+Porsi) dengan latar #F1F2F6
  Widget _buildNutritionInfo(ResepMpasi resep, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : const Color(0xFFF1F2F6),
        borderRadius: BorderRadius.circular(14),
        border: isDark ? Border.all(color: const Color(0xFF2C363D)) : null,
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
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                _buildNutritionItem(
                  icon: Icons.science_outlined,
                  iconColor: const Color(0xFF00B087),
                  label: 'Protein',
                  value: '${resep.protein} gr',
                  isDark: isDark,
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 64,
            color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF),
          ),
          Expanded(
            child: Column(
              children: [
                _buildNutritionItem(
                  icon: Icons.opacity_outlined,
                  iconColor: const Color(0xFF4DA3FF),
                  label: 'Lemak',
                  value: '${resep.lemak} gr',
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                _buildNutritionItem(
                  icon: Icons.restaurant_outlined,
                  iconColor: const Color(0xFFFF6B6B),
                  label: 'Porsi',
                  value: '${resep.porsi} porsi',
                  isDark: isDark,
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
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
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
                    color: isDark ? const Color(0xFF8696A0) : const Color(0xFF8E8E93),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.lato(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
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
  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
      ),
    );
  }

  // Daftar dengan bullet point
  Widget _buildBulletList(List<String> items, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 10),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFFD1D7DB) : const Color(0xFF262626),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: isDark ? const Color(0xFFD1D7DB) : const Color(0xFF262626),
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Daftar dengan nomor urut
  Widget _buildNumberedList(List<String> items, bool isDark) {
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
                width: 24,
                child: Text(
                  '$index.',
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF262626),
                    height: 1.6,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: isDark ? const Color(0xFFD1D7DB) : const Color(0xFF262626),
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

}