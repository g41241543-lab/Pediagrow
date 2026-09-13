import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Halaman Tentang Aplikasi PediaGrow.
class TentangAplikasiPage extends StatelessWidget {
  const TentangAplikasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header tetap di atas (56dp)
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.arrow_back,
                          color: Color(0xFF000000),
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tentang Aplikasi',
                      style: GoogleFonts.lato(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF000000),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 24.0,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECF6FF),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3985E7)
                                .withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.spa_rounded,
                              size: 48,
                              color: Color(0xFF3985E7),
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Pedia',
                            style: GoogleFonts.baloo2(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4B83D6),
                            ),
                          ),
                          TextSpan(
                            text: 'Grow',
                            style: GoogleFonts.baloo2(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3CC3A6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Versi 1.0.0 (Rilis Publik)',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildInfoCard(
                      title: 'Mengenal PediaGrow',
                      description:
                          'PediaGrow merupakan aplikasi kesehatan anak yang berfungsi untuk membantu para orangtua untuk memantau pertumbuhan anak secara mudah dan praktis.\n'
                          '\nPediaGrow\n'
                          'Pantau Pertumbuhan, Cegah Stunting Untuk Masa Depan\n',
                      icon: Icons.favorite_border_rounded,
                      iconColor: const Color(0xFFE11D48),
                    ),
                    const SizedBox(height: 14),

                    _buildInfoCard(
                      title: 'Menu PediaGrow',
                      description:
                          '• Deteksi & Cek Risiko Stunting Balita\n'
                          '• Grafik Pertumbuhan Anak\n'
                          '• Rekomendasi Menu Resep MPASI\n'
                          '• Artikel Kesehatan\n'
                          '• Konsultasi Online dengan Dokter\n'
                          '• Lokasi Fasyankes Terdekat'
                          '• Permainan\n',
                      icon: Icons.star_border_rounded,
                      iconColor: const Color(0xFFF59E0B),
                    ),
                    const SizedBox(height: 14),

                    _buildInfoCard(
                      title: 'Bantuan & Pengembang',
                      description:
                          'Memerlukan bantuan atau memiliki pertanyaan seputar aplikasi?\n\n'
                          'Instagram: @Pedia.Grow\n'
                          'Youtube: PediaGrow Official Channel\n'
                          'Email: support@pediagrow.id\n'
                          'Website: https://pediagrow.id\n'
                          'WhatsApp Layanan Pengguna: +62 812-3456-7890',
                      icon: Icons.support_agent_rounded,
                      iconColor: const Color(0xFF3985E7),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      '© 2026 PediaGrow. All rights reserved.\nPantau Pertumbuhan, Cegah Stunting Untuk Masa Depan.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF000000),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: GoogleFonts.lato(
              fontSize: 14,
              color: const Color(0xFF475569),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
