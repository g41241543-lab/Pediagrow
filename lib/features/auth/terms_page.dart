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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // -----------------------------------------------------------------
            // HEADER TETAP BERADA PADA POSISI ATAS (56dp)
            // -----------------------------------------------------------------
            _buildFixedHeader(context),

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
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Selamat datang di aplikasi PediaGrow. Dengan mendaftar dan menggunakan aplikasi ini, Anda menyetujui syarat dan ketentuan berikut:',
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        height: 1.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      title: '1. Akun Pengguna',
                      content: 'Anda wajib memberikan informasi yang akurat dan lengkap saat mendaftar. Keamanan akun dan kata sandi menjadi tanggung jawab pribadi Anda.',
                    ),
                    _buildSection(
                      title: '2. Privasi & Data Anak',
                      content: 'Data tumbuh kembang anak yang Anda masukkan dilindungi dan digunakan semata-mata untuk keperluan pemantauan status gizi dan pencegahan stunting.',
                    ),
                    _buildSection(
                      title: '3. Layanan Konsultasi & Edukasi',
                      content: 'Informasi dalam aplikasi ini ditujukan sebagai panduan edukasi awal dan pemantauan berkala, bukan pengganti rujukan medis darurat dokter spesialis.',
                    ),
                    _buildSection(
                      title: '4. Perubahan Ketentuan',
                      content: 'Tim PediaGrow berhak memperbarui syarat dan ketentuan ini sewaktu-waktu demi peningkatan layanan dan keamanan sistem aplikasi.',
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
  Widget _buildFixedHeader(BuildContext context) {
    return Container(
      height: 56.0,
      color: Colors.white,
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
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Icon(Icons.arrow_back, color: Color(0xFF000000), size: 24),
            ),
          ),
          // Nama halaman terletak 12dp setelah button back
          const SizedBox(width: 12.0),
          Text(
            'Syarat & Ketentuan',
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF000000),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
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
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: GoogleFonts.lato(
              fontSize: 14,
              height: 1.4,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
