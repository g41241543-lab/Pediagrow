import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/notification_service.dart';
import '../../../models/child_model.dart';
import '../konsultasi/daftar_dokter_page.dart';
import '../konsultasi/formulir_konsultasi_page.dart';
import '../profil/menu_profil_page.dart';
import '../riwayat_konsultasi/daftar_riwayat_page.dart';
import 'form_cek_stunting_page.dart';

/// Halaman Hasil Lengkap Cek Stunting PediaGrow.
///
/// Menyajikan diagnosis komprehensif berdasarkan klasifikasi Random Forest &
/// GridSearchCV, rincian Z-score standar WHO, interpretasi medis, serta
/// rekomendasi gizi dan opsi konsultasi dokter langsung.
class HasilCekStuntingPage extends StatelessWidget {
  final StuntingAnalysisResult result;
  final String namaAnak;
  final String jenisKelamin;
  final String usiaDeskripsi;
  final double beratBadanSekarang;
  final double tinggiBadanSekarang;
  final bool isAsiEksklusif;
  final String tanggalPemeriksaan;

  static const Color colorPrimaryBlue = Color(0xFF4B83D6);
  static const Color colorDangerRed = Color(0xFFB13535);
  static const Color colorTextBlack = Color(0xFF000000);
  static const Color colorBorderGrey = Color(0xFFC5C5C5);
  static const Color colorReadOnlyBg = Color(0xFFF6F7F9);
  static const Color colorNavBarBg = Color(0xFFF2EDED);

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
  });

  @override
  Widget build(BuildContext context) {
    // Pengguna telah melakukan cek stunting bulan ini, hentikan notifikasi pengingat otomatis
    NotificationService().markStuntingCheckedThisMonth();

    final isNormal = result.status == StuntingStatus.normal;
    final statusColor = isNormal ? const Color(0xFF2E7D32) : colorDangerRed;
    final statusBgColor =
        isNormal ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Header Tetap 56dp
            _buildFixedHeader(context),

            // 2. Konten Scrollable
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),

                    // Badge AI / Data Mining Tag
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colorPrimaryBlue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.psychology_alt_rounded,
                              color: colorPrimaryBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Data Mining: Algoritma Klasifikasi Random Forest & GridSearchCV',
                                style: GoogleFonts.lato(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: colorPrimaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Card Status Utama
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isNormal
                                        ? Icons.check_circle_rounded
                                        : Icons.warning_rounded,
                                    color: statusColor,
                                    size: 34,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Status Pertumbuhan',
                                        style: GoogleFonts.lato(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        result.statusLabel,
                                        style: GoogleFonts.lato(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              result.description,
                              style: GoogleFonts.lato(
                                fontSize: 13,
                                color: Colors.black87,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Akurasi Model: ${(result.confidenceProbability * 100).toStringAsFixed(1)}%',
                                  style: GoogleFonts.lato(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Z-Score (TB/U): ${result.zScoreHeightForAge.toStringAsFixed(2)} SD',
                                  style: GoogleFonts.lato(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Card Ringkasan Profil Anak
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorBorderGrey),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informasi Si Kecil',
                              style: GoogleFonts.lato(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: colorTextBlack,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow('Nama Lengkap', namaAnak),
                            _buildInfoRow('Jenis Kelamin', jenisKelamin),
                            _buildInfoRow('Umur Saat Pengecekan', usiaDeskripsi),
                            _buildInfoRow(
                                'Tanggal Pengecekan', tanggalPemeriksaan),
                            _buildInfoRow('Berat Badan Saat Ini',
                                '$beratBadanSekarang kg'),
                            _buildInfoRow('Tinggi Badan Saat Ini',
                                '$tinggiBadanSekarang cm'),
                            _buildInfoRow('ASI Eksklusif Penuh',
                                isAsiEksklusif ? 'Ya' : 'Tidak'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Card Rekomendasi Medis & Gizi
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorBorderGrey),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.lightbulb_outline_rounded,
                                    color: Color(0xFFF59E0B), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Rekomendasi Tindak Lanjut',
                                  style: GoogleFonts.lato(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: colorTextBlack,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...result.recommendations.map(
                              (rec) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                    Expanded(
                                      child: Text(
                                        rec,
                                        style: GoogleFonts.lato(
                                          fontSize: 13,
                                          color: Colors.black87,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Tombol Aksi: Konsultasi Dokter & Selesai
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          if (!isNormal) ...[
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FormulirKonsultasiPage(
                                        child: ChildModel(
                                          id: 'child-1',
                                          name: namaAnak,
                                          gender: jenisKelamin,
                                          ageDescription: usiaDeskripsi,
                                          weightKg: beratBadanSekarang,
                                          heightCm: tinggiBadanSekarang,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorDangerRed,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                icon: const Icon(Icons.medical_services_outlined,
                                    color: Colors.white, size: 20),
                                label: Text(
                                  'Konsultasi Dokter Sekarang',
                                  style: GoogleFonts.lato(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context)
                                    .popUntil((route) => route.isFirst);
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: colorPrimaryBlue),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: Text(
                                'Kembali ke Beranda',
                                style: GoogleFonts.lato(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorPrimaryBlue,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Footer Landscape Illustration
                    SizedBox(
                      width: double.infinity,
                      child: Image.asset(
                        'assets/images/beranda_landscape_footer.jpg',
                        fit: BoxFit.fitWidth,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(height: 60),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildFixedHeader(BuildContext context) {
    return Container(
      height: 56,
      width: double.infinity,
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
                  child: Icon(Icons.arrow_back, color: colorTextBlack, size: 24),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Detail Hasil Cek Stunting',
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

  Widget _buildInfoRow(String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.lato(fontSize: 13, color: Colors.grey.shade700),
          ),
          Text(
            val,
            style: GoogleFonts.lato(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: colorTextBlack,
            ),
          ),
        ],
      ),
    );
  }

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
            icon: Icons.home_outlined,
            label: 'Beranda',
            onTap: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
          _buildNavItem(
            context: context,
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Konsultasi',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DaftarDokterPage()),
            ),
          ),
          _buildNavItem(
            context: context,
            icon: Icons.assignment_outlined,
            label: 'Riwayat Konsultasi',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DaftarRiwayatPage()),
            ),
          ),
          _buildNavItem(
            context: context,
            icon: Icons.person_outline_rounded,
            label: 'Profil Ibu',
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
