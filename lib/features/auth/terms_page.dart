import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Halaman Syarat & Ketentuan PediaGrow.
///
/// Header TETAP BERADA PADA POSISI ATAS (56dp):
/// - Button back terletak 12dp dari pinggir kiri layar.
/// - Nama halaman terletak 12dp setelah button back.
/// Konten dapat di-scroll secara independen tanpa menggeser header.
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0B1014) : Colors.white;
    final headerBg = isDark ? const Color(0xFF1A2228) : Colors.white;
    final titleColor =
        isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228);
    final headerTitleColor =
        isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000);
    final textColor =
        isDark ? const Color(0xFF8696A0) : const Color(0xFF667781);
    final sectionContentColor =
        isDark ? const Color(0xFFD1D7DB) : const Color(0xFF667781);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // -----------------------------------------------------------------
            // HEADER TETAP BERADA PADA POSISI ATAS (56dp)
            // -----------------------------------------------------------------
            _buildFixedHeader(context, isDark, headerBg, headerTitleColor),

            // -----------------------------------------------------------------
            // KONTEN SYARAT & KETENTUAN YANG DAPAT DI-SCROLL
            // -----------------------------------------------------------------
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Syarat & Ketentuan Penggunaan PediaGrow',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Selamat datang di aplikasi PediaGrow. Dengan mendaftar dan menggunakan aplikasi ini, Anda menyetujui syarat dan ketentuan berikut:',
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        height: 1.5,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      title: '1. Akun Pengguna',
                      content:
                          'Anda wajib memberikan informasi yang akurat dan lengkap saat mendaftar. Keamanan akun dan kata sandi menjadi tanggung jawab pribadi Anda.',
                      titleColor: titleColor,
                      contentColor: sectionContentColor,
                    ),
                    _buildSection(
                      title: '2. Privasi & Data Anak',
                      content:
                          'Data tumbuh kembang anak yang Anda masukkan dilindungi dan digunakan semata-mata untuk keperluan pemantauan status gizi dan pencegahan stunting.',
                      titleColor: titleColor,
                      contentColor: sectionContentColor,
                    ),
                    _buildSection(
                      title: '3. Layanan Konsultasi & Edukasi',
                      content:
                          'Informasi dalam aplikasi ini ditujukan sebagai panduan edukasi awal dan pemantauan berkala, bukan pengganti rujukan medis darurat dokter spesialis.',
                      titleColor: titleColor,
                      contentColor: sectionContentColor,
                    ),
                    _buildSection(
                      title: '4. Perubahan Ketentuan',
                      content:
                          'Tim PediaGrow berhak memperbarui syarat dan ketentuan ini sewaktu-waktu demi peningkatan layanan dan keamanan sistem aplikasi.',
                      titleColor: titleColor,
                      contentColor: sectionContentColor,
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3985E7),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            'Saya Mengerti',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header yang TETAP BERADA PADA POSISI ATAS (56dp) saat konten di-scroll.
  Widget _buildFixedHeader(BuildContext context, bool isDark, Color headerBg,
      Color headerTitleColor) {
    return Container(
      height: 56.0,
      color: headerBg,
      padding: const EdgeInsets.only(left: 12.0, right: 12.0),
      child: Row(
        children: [
          // Button back terletak 12dp dari pinggir kiri layar
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Icon(Icons.arrow_back, color: headerTitleColor, size: 24),
            ),
          ),
          // Nama halaman terletak 12dp setelah button back
          const SizedBox(width: 12.0),
          Text(
            'Syarat & Ketentuan',
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: headerTitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required Color titleColor,
    required Color contentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.lato(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: GoogleFonts.lato(
              fontSize: 14,
              height: 1.4,
              color: contentColor,
            ),
          ),
        ],
      ),
    );
  }
}
