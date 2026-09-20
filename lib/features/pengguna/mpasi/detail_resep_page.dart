import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  // Design Tokens PediaGrow
  static const Color colorPrimaryBlue = Color(0xFF2A85FF);
  static const Color colorSoftBlue = Color(0xFFEBF5FF);
  static const Color colorWhite = Color(0xFFFFFFFF);
  static const Color colorTextPrimary = Color(0xFF1A202C);
  static const Color colorGreyDark = Color(0xFF7F7F7F); // Abu tua
  static const Color colorGreyLight = Color(0xFFC5C5C5); // Abu muda

  static const Color colorTextSecondary = colorGreyDark;
  static const Color colorTextMuted = colorGreyDark;
  static const Color colorSearchBg = Color(0xFFF1F5F9);
  static const Color colorBorder = colorGreyLight;

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
    final resep = _effectiveResep;

    return Scaffold(
      backgroundColor: colorWhite,
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
  // 1. HEADER FIXED — tinggi 56dp
  //    Back Button 12dp dari pinggir layar + Judul "Detail Resep"
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
          // Judul "Detail Resep"
          Expanded(
            child: Text(
              'Detail Resep',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorTextPrimary,
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

              // Tanggal (Lato 16sp abu-abu lembut sesuai detail artikel)
              Text(
                resep.date,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: colorTextMuted,
                ),
              ),
              const SizedBox(height: 6),

              // Judul Resep (Lato 18sp bold hitam sesuai detail artikel)
              Text(
                resep.title,
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorTextPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),

              // Penulis (Lato 14sp abu-abu sesuai detail artikel)
              Text(
                'Ditulis oleh ${resep.author}',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colorTextMuted,
                ),
              ),
              const SizedBox(height: 16),

              // Informasi Nutrisi
              _buildNutritionInfo(resep),
              const SizedBox(height: 20),

              // Divider tipis
              const Divider(color: colorBorder, thickness: 1, height: 1),
              const SizedBox(height: 16),

              // Bagian Bahan
              if (resep.bahan.isNotEmpty) ...[
                _buildSectionTitle('Bahan'),
                const SizedBox(height: 8),
                _buildBulletList(resep.bahan),
                const SizedBox(height: 16),
              ],

              // Bagian Bahan Pelapis (opsional jika ada)
              if (resep.bahanPelapis.isNotEmpty) ...[
                _buildSectionTitle('Bahan Pelapis'),
                const SizedBox(height: 8),
                _buildBulletList(resep.bahanPelapis),
                const SizedBox(height: 16),
              ],

              // Bagian Buah (opsional jika ada)
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

  // Gambar Resep — mendukung asset lokal maupun remote URL dari PMIK Superadmin
  Widget _buildRecipeImage(ResepMpasi resep) {
    final imagePath =
        resep.assetImage.isNotEmpty ? resep.assetImage : (resep.imageUrl ?? '');
    final isNetwork =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: imagePath.isEmpty
              ? _buildImagePlaceholder()
              : isNetwork
                  ? Image.network(
                      imagePath,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildImagePlaceholder(),
                    )
                  : Image.asset(
                      imagePath,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildImagePlaceholder(),
                    ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: colorSoftBlue,
      child: const Center(
        child: Icon(
          Icons.restaurant_menu_rounded,
          color: colorPrimaryBlue,
          size: 48,
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

  // Judul section (Bahan, Bahan Pelapis, Buah, Cara Membuat - Lato 16sp bold sesuai detail artikel)
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: colorTextPrimary,
      ),
    );
  }

  // Daftar dengan bullet point (lingkaran kecil - Lato 15sp sesuai detail artikel)
  Widget _buildBulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: colorTextSecondary,
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

  // Daftar dengan nomor urut (1. 2. 3. ... - Lato 15sp sesuai detail artikel)
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
                width: 24,
                child: Text(
                  '$index.',
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorTextSecondary,
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
                    color: colorTextSecondary,
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