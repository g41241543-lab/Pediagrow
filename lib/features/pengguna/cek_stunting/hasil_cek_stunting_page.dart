import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/notification_service.dart';
import '../beranda/beranda_page.dart';
import '../konsultasi/daftar_dokter_page.dart';
import '../profil/menu_profil_page.dart';
import '../riwayat_konsultasi/daftar_riwayat_page.dart';
import 'form_cek_stunting_page.dart';
import 'preview_hasil_cek_stunting_page.dart';

/// Halaman Hasil Cek Stunting PediaGrow.
///
/// Disusun secara mobile-first, compact, modern, dan responsif bebas overflow
/// sesuai rancangan antarmuka dan alur analisis data mining Random Forest & GridSearchCV.
class HasilCekStuntingPage extends StatelessWidget {
  final StuntingAnalysisResult result;
  final String namaAnak;
  final String jenisKelamin;
  final String usiaDeskripsi;
  final double beratBadanSekarang;
  final double tinggiBadanSekarang;
  final bool isAsiEksklusif;
  final String tanggalPemeriksaan;
  final String tanggalLahir;
  final String beratBadanLahir;
  final String tinggiBadanLahir;

  // Palet Warna Resmi PediaGrow Sesuai Desain Referensi
  static const Color colorPrimaryBlue = Color(0xFF3985E7);
  static const Color colorTealGreen = Color(0xFF3CC3A6);
  static const Color colorDangerRed = Color(0xFFB13535);
  static const Color colorAccentLime = Color(0xFFB2CC08);
  static const Color colorTextBlack = Color(0xFF000000);
  static const Color colorBorderGrey = Color(0xFFC5C5C5);
  static const Color colorReadOnlyBg = Color(0xFFF6F7F9);
  static const Color colorNavBarBg = Color(0xFFF2EDED);

  // Palet Warna Tombol ASI Sesuai Desain
  static const Color colorMintBg = Color(0xFFC7F9EB);
  static const Color colorMintBorder = Color(0xFF38D5B1);
  static const Color colorMintText = Color(0xFF0F766E);

  const HasilCekStuntingPage({
    super.key,
    required this.result,
    required this.namaAnak,
    required this.jenisKelamin,
    required this.usiaDeskripsi,
    required this.beratBadanSekarang,
    required this.tinggiBadanSekarang,
    required this.isAsiEksklusif,
    required this.tanggalPemeriksaan,
    this.tanggalLahir = '22/05/2025',
    this.beratBadanLahir = '2.9',
    this.tinggiBadanLahir = '50',
  });

  @override
  Widget build(BuildContext context) {
    // Pengguna telah melakukan cek stunting, tandai agar notifikasi pengingat otomatis terjadwal
    NotificationService().markStuntingCheckedThisMonth();

    final bool isNormal = result.status == StuntingStatus.normal;
    final String predictionText = isNormal ? 'TIDAK STUNTING' : 'STUNTING';
    final Color predictionBgColor = isNormal ? colorTealGreen : colorDangerRed;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Header Fixed 56 dp di bagian paling atas
            _buildFixedHeader(context),

            // 2. Konten Utama Scrollable agar bebas overflow pada layar kecil
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Judul Konten: "Hasil Analisis Stunting"
                    Text(
                      'Hasil Analisis Stunting',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorTextBlack,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Card Informasi Hasil Pemeriksaan (Struktur form_cek_stunting_page.dart)
                    _buildExaminationInfoCard(),

                    const SizedBox(height: 16),

                    // Warning / Information Box dengan Border Dashed #B2CC08
                    _buildWarningInformationBox(),

                    const SizedBox(height: 16),

                    // Card Hasil Prediksi Klasifikasi Random Forest
                    _buildPredictionResultCard(
                      predictionText: predictionText,
                      backgroundColor: predictionBgColor,
                    ),

                    const SizedBox(height: 16),

                    // Card Rekomendasi Pencegahan Stunting
                    _buildRecommendationCard(),

                    const SizedBox(height: 20),

                    // Dua Tombol Action Horizontal: Cetak Hasil & Selesai
                    _buildActionButtons(context),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Navigation Bar tetap di Scaffold.bottomNavigationBar
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  // ===========================================================================
  // 1. HEADER FIXED (56 DP)
  // ===========================================================================
  Widget _buildFixedHeader(BuildContext context) {
    return Container(
      height: 56,
      width: double.infinity,
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tombol kembali 12 dp dari sisi kiri layar
          const SizedBox(width: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(context).maybePop(),
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: Icon(
                    Icons.arrow_back,
                    color: colorTextBlack,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          // Judul "Cek Stunting" berjarak 12 dp setelah tombol kembali
          const SizedBox(width: 12),
          Text(
            'Cek Stunting',
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorTextBlack,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. CARD INFORMASI HASIL PEMERIKSAAN
  // ===========================================================================
  Widget _buildExaminationInfoCard() {
    // Format berat badan dan tinggi badan agar rapi tanpa trailing zero berlebih
    final String displayBeratSekarang = beratBadanSekarang % 1 == 0
        ? beratBadanSekarang.toInt().toString()
        : beratBadanSekarang.toStringAsFixed(1);

    final String displayTinggiSekarang = tinggiBadanSekarang % 1 == 0
        ? tinggiBadanSekarang.toInt().toString()
        : tinggiBadanSekarang.toStringAsFixed(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            spreadRadius: 1,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Nama Lengkap
          _buildFieldLabel('Nama Lengkap'),
          const SizedBox(height: 6),
          _buildReadOnlyField(namaAnak),
          const SizedBox(height: 10),

          // 2. Jenis Kelamin
          _buildFieldLabel('Jenis Kelamin'),
          const SizedBox(height: 6),
          _buildReadOnlyField(jenisKelamin),
          const SizedBox(height: 10),

          // 3. Tanggal Lahir
          _buildFieldLabel('Tanggal Lahir'),
          const SizedBox(height: 6),
          _buildReadOnlyField(tanggalLahir),
          const SizedBox(height: 10),

          // 4. Tanggal Cek Stunting
          _buildFieldLabel('Tanggal Cek Stunting'),
          const SizedBox(height: 6),
          _buildReadOnlyField(tanggalPemeriksaan),
          const SizedBox(height: 10),

          // 5. Berat Badan Saat Lahir
          _buildFieldLabel('Berat Badan Saat Lahir'),
          const SizedBox(height: 6),
          _buildReadOnlyField(beratBadanLahir),
          const SizedBox(height: 10),

          // 6. Tinggi Badan Saat Lahir
          _buildFieldLabel('Tinggi Badan Saat Lahir'),
          const SizedBox(height: 6),
          _buildReadOnlyField(tinggiBadanLahir),
          const SizedBox(height: 10),

          // 7. Berat Badan Sekarang
          _buildFieldLabel('Berat Badan Sekarang'),
          const SizedBox(height: 6),
          _buildReadOnlyField(displayBeratSekarang),
          const SizedBox(height: 10),

          // 8. Tinggi Badan Sekarang
          _buildFieldLabel('Tinggi Badan Sekarang'),
          const SizedBox(height: 6),
          _buildReadOnlyField(displayTinggiSekarang),
          const SizedBox(height: 12),

          // 9. Pertanyaan Pemberian ASI Penuh
          _buildFieldLabel(
            'Apakah hingga saat ini si kecil mendapatkan ASI secara penuh?',
          ),
          const SizedBox(height: 8),
          _buildAsiOptionButtons(isAsiEksklusif),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.lato(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: colorTextBlack,
      ),
    );
  }

  /// Field read-only modern berbentuk kapsul rounded dengan border grey lembut
  Widget _buildReadOnlyField(String value) {
    return Container(
      width: double.infinity,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: colorReadOnlyBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorBorderGrey,
          width: 1.0,
        ),
      ),
      child: Text(
        value,
        style: GoogleFonts.lato(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: colorTextBlack,
        ),
      ),
    );
  }

  /// Dua tombol opsi ASI Eksklusif (Tidak / Ya) dengan highlight dinamis
  Widget _buildAsiOptionButtons(bool isYaActive) {
    return Row(
      children: [
        // Tombol "Tidak"
        Expanded(
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: !isYaActive ? const Color(0xFFFFEBEE) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: !isYaActive ? colorDangerRed : colorBorderGrey,
                width: 1.0,
              ),
            ),
            child: Center(
              child: Text(
                'Tidak',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: !isYaActive ? colorDangerRed : colorTextBlack,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Tombol "Ya"
        Expanded(
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: isYaActive ? colorMintBg : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isYaActive ? colorMintBorder : colorBorderGrey,
                width: 1.2,
              ),
            ),
            child: Center(
              child: Text(
                'Ya',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isYaActive ? colorMintText : colorTextBlack,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 3. WARNING / INFORMATION BOX (BORDER DASHED #B2CC08)
  // ===========================================================================
  Widget _buildWarningInformationBox() {
    return CustomPaint(
      painter: DashedRectPainter(
        color: colorAccentLime,
        strokeWidth: 1.8,
        gap: 4.0,
        dashLength: 7.0,
        borderRadius: 14.0,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Text(
          'Hasil cek stunting tidak akurat 100%. Berdasarkan data anda, Pego berhasil memprediksi bahwa si kecil:',
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorTextBlack,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. CARD HASIL PREDIKSI (DYNAMIC RANDOM FOREST)
  // ===========================================================================
  Widget _buildPredictionResultCard({
    required String predictionText,
    required Color backgroundColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          predictionText,
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 5. CARD REKOMENDASI PENCEGAHAN STUNTING
  // ===========================================================================
  Widget _buildRecommendationCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card Biru #3985E7
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: colorPrimaryBlue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.assignment_turned_in_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Rekomendasi',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Body Card Putih dengan Rekomendasi Berpoin
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upaya yang bisa dilakukan untuk pencegahan stunting yaitu :',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorTextBlack,
                  ),
                ),
                const SizedBox(height: 8),
                _buildRecommendationBullet('Pemberian pola asuh yang tepat'),
                _buildRecommendationBullet('Memberikan MPASI yang optimal'),
                _buildRecommendationBullet('Mengobati penyakit yang dialami anak'),
                _buildRecommendationBullet('Perbaikan kebersihan lingkungan'),
                _buildRecommendationBullet('Menerapkan hidup bersih keluarga'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorTextBlack,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorTextBlack,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. ACTION BUTTONS: CETAK HASIL & SELESAI
  // ===========================================================================
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Tombol Cetak Hasil (Putih dengan Border #3985E7)
        Expanded(
          child: SizedBox(
            height: 40,
            child: OutlinedButton(
              onPressed: () {
                // Navigasi ke Halaman Preview & Cetak PDF tanpa menghapus HasilCekStuntingPage dari stack
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PreviewHasilCekStuntingPage(
                      result: result,
                      namaAnak: namaAnak,
                      jenisKelamin: jenisKelamin,
                      tanggalLahir: tanggalLahir,
                      tanggalPemeriksaan: tanggalPemeriksaan,
                      beratBadanLahir: beratBadanLahir,
                      tinggiBadanLahir: tinggiBadanLahir,
                      beratBadanSekarang: beratBadanSekarang,
                      tinggiBadanSekarang: tinggiBadanSekarang,
                      isAsiEksklusif: isAsiEksklusif,
                      usiaDeskripsi: usiaDeskripsi,
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: colorPrimaryBlue, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(
                'Cetak Hasil',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorPrimaryBlue,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Tombol Selesai (Background #3985E7)
        Expanded(
          child: SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: () {
                // Kembali ke Beranda dan bersihkan navigation stack agar halaman hasil tidak aktif lagi
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const BerandaPage()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorPrimaryBlue,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(
                'Selesai',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 7. NAVIGATION BAR (SCAFFOLD.BOTTOMNAVIGATIONBAR)
  // ===========================================================================
  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 68,
      decoration: const BoxDecoration(
        color: colorNavBarBg,
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context: context,
            icon: Icons.home_rounded,
            label: 'Beranda',
            onTap: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const BerandaPage()),
              (route) => false,
            ),
          ),
          _buildNavItem(
            context: context,
            icon: Icons.question_answer_rounded,
            label: 'Konsultasi',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DaftarDokterPage()),
            ),
          ),
          _buildNavItem(
            context: context,
            icon: Icons.manage_search_rounded,
            label: 'Riwayat Konsultasi',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DaftarRiwayatPage()),
            ),
          ),
          _buildNavItem(
            context: context,
            icon: Icons.person_outline_rounded,
            label: 'Profil',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MenuProfilPage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        height: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: const Color(0xFF9E9E9E)),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 11,
                color: const Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// CUSTOM PAINTER: DASHED ROUNDED RECTANGLE BORDER
// =============================================================================
class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  DashedRectPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.gap = 4.0,
    this.dashLength = 6.0,
    this.borderRadius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);
    final ui.PathMetric metric = path.computeMetrics().first;

    double distance = 0.0;
    while (distance < metric.length) {
      final double end = (distance + dashLength < metric.length)
          ? distance + dashLength
          : metric.length;
      canvas.drawPath(metric.extractPath(distance, end), paint);
      distance += dashLength + gap;
    }
  }

  @override
  bool shouldRepaint(covariant DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.borderRadius != borderRadius;
  }
}
