import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/storage_service.dart';
import '../../../models/artikel_model.dart';
import '../../../shared/widgets/article_rich_text_editor.dart';


/// Halaman Detail Artikel untuk menampilkan konten lengkap artikel kesehatan
/// yang dipilih pengguna dari [ArtikelKesehatanPage].
///
/// Fitur utama:
/// 1. Header tetap (56dp) dengan tombol back 12dp dari kiri dan judul "Detail Artikel" (Lato 20sp bold).
/// 2. Konten dinamis yang bersumber dari database/PMIK via [ArtikelModel].
/// 3. Hero image dengan sudut membulat modern (16–20dp) dan fallback placeholder otomatis jika gambar null/error.
/// 4. Tanggal publikasi ("26 Agustus 2026", Lato 16sp abu-abu).
/// 5. Judul artikel (Lato 18sp bold hitam).
/// 6. Nama penulis PMIK ("Ditulis oleh Pego").
/// 7. Bagian konten lengkap terstruktur (Deskripsi, Pengertian, dsb.) dengan tipografi nyaman dibaca.
/// 8. Konten lengkap terstruktur yang nyaman dibaca.
class DetailArtikelPage extends StatefulWidget {
  final ArtikelModel artikel;

  const DetailArtikelPage({
    super.key,
    required this.artikel,
  });

  @override
  State<DetailArtikelPage> createState() => _DetailArtikelPageState();
}

class _DetailArtikelPageState extends State<DetailArtikelPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.04, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onBackPressed() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final artikel = widget.artikel;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1014) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER TETAP (56dp)
            _buildHeader(context, isDark),

            // 2. KONTEN ARTIKEL SCROLLABLE
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Gambar Hero Utama
                        _buildArticleHeroImage(artikel, isDark),
                        const SizedBox(height: 16),

                        // Tanggal Publikasi (Lato 16sp abu-abu lembut)
                        Text(
                          artikel.tanggal,
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: isDark ? const Color(0xFF8696A0) : const Color(0xFF8E8E93),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Judul Artikel (Lato 18sp bold hitam)
                        Text(
                          artikel.judul,
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Nama Penulis PMIK
                        Text(
                          'Ditulis oleh ${artikel.penulis}',
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: isDark ? const Color(0xFF8696A0) : const Color(0xFF8E8E93),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Garis pemisah halus
                        Divider(
                          color: isDark ? const Color(0xFF2C363D) : const Color(0xFFF1F2F6),
                          thickness: 1,
                          height: 1,
                        ),
                        const SizedBox(height: 20),

                        // Bagian Deskripsi
                        if (artikel.deskripsi != null &&
                            artikel.deskripsi!.isNotEmpty) ...[
                          _buildSectionTitle('Deskripsi', isDark),
                          const SizedBox(height: 8),
                          _buildSectionParagraph(artikel.deskripsi!, isDark),
                          const SizedBox(height: 20),
                        ],

                        // Bagian Pengertian
                        if (artikel.pengertian != null &&
                            artikel.pengertian!.isNotEmpty) ...[
                          _buildSectionTitle('Pengertian', isDark),
                          const SizedBox(height: 8),
                          _buildSectionParagraph(artikel.pengertian!, isDark),
                          const SizedBox(height: 20),
                        ],

                        // Konten Tambahan / Isi Lengkap jika ada
                        if (artikel.isiLengkap.isNotEmpty) ...[
                          _buildSectionParagraph(artikel.isiLengkap, isDark),
                          const SizedBox(height: 20),
                        ],

                        // Padding bawah ekstra agar nyaman dibaca dan tidak mepet nav bar
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header 56dp dengan tombol kembali 12dp dari sisi kiri dan judul "Detail Artikel"
  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      height: 56,
      width: double.infinity,
      color: isDark ? const Color(0xFF0B1014) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tombol Back
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
              'Detail Artikel',
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

  /// Gambar Hero dengan proporsi modern dan placeholder fallback jika null/error
  Widget _buildArticleHeroImage(ArtikelModel artikel, bool isDark) {
    final displayImage = artikel.displayImage;

    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : const Color(0xFFF1F2F6),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0x0A000000),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: StorageService.buildImageWidget(
          displayImage,
          width: double.infinity,
          height: 230,
          fit: BoxFit.cover,
          placeholder: _buildPlaceholderImage(isDark),
          errorWidget: _buildPlaceholderImage(isDark),
        ),
      ),
    );
  }

  /// Placeholder abu-abu dengan icon picture ketika gambar null atau gagal dimuat
  Widget _buildPlaceholderImage(bool isDark) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: isDark ? const Color(0xFF1A2228) : const Color(0xFFEEEEEE),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 56,
              color: isDark ? const Color(0xFF667781) : const Color(0xFFBDBDBD),
            ),
            const SizedBox(height: 8),
            Text(
              'Tidak ada gambar',
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


  /// Judul Bagian (Subheading)
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

  /// Paragraf teks isi artikel dengan rendering format kaya (Bold, Italic, Underline)
  Widget _buildSectionParagraph(String content, bool isDark) {
    return FormattedArticleText(
      content: content,
      textAlign: TextAlign.justify,
      style: GoogleFonts.lato(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: isDark ? const Color(0xFFD1D7DB) : const Color(0xFF262626),
      ),
    );
  }
}
