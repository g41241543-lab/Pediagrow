import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Halaman Syarat & Ketentuan PediaGrow.
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Syarat & Ketentuan',
          style: GoogleFonts.lato(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
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
                content:
                    'Anda wajib memberikan informasi yang akurat dan lengkap saat mendaftar. Keamanan akun dan kata sandi menjadi tanggung jawab pribadi Anda.',
              ),
              _buildSection(
                title: '2. Privasi & Data Anak',
                content:
                    'Data tumbuh kembang anak yang Anda masukkan dilindungi dan digunakan semata-mata untuk keperluan pemantauan status gizi dan pencegahan stunting.',
              ),
              _buildSection(
                title: '3. Layanan Konsultasi & Edukasi',
                content:
                    'Informasi dalam aplikasi ini ditujukan sebagai panduan edukasi awal dan pemantauan berkala, bukan pengganti rujukan medis darurat dokter spesialis.',
              ),
              _buildSection(
                title: '4. Perubahan Ketentuan',
                content:
                    'Tim PediaGrow berhak memperbarui syarat dan ketentuan ini sewaktu-waktu demi peningkatan layanan dan keamanan sistem aplikasi.',
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
