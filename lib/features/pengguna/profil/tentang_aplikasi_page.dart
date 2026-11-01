import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/staff_account_model.dart';

/// Halaman Tentang Aplikasi PediaGrow.
/// Menyesuaikan konten informasi sesuai dengan peran pengguna/staf.
class TentangAplikasiPage extends StatelessWidget {
  final StaffRole? staffRole;

  const TentangAplikasiPage({
    super.key,
    this.staffRole,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0B1014) : Colors.white;
    final titleColor = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000);
    final subtitleColor = isDark ? const Color(0xFF8696A0) : const Color(0xFF667781);
    final versionBg = isDark ? const Color(0xFF1A2228) : const Color(0xFFE9EDEF);
    final versionText = isDark ? const Color(0xFF8696A0) : const Color(0xFF667781);
    final logoBg = isDark ? const Color(0xFF1E3A5F) : const Color(0xFFECF6FF);

    return Scaffold(
      backgroundColor: bgColor,
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
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.arrow_back,
                          color: titleColor,
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
                        color: titleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(overscroll: false),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
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
                        color: logoBg,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3985E7).withValues(alpha: 0.12),
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
                        color: versionBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getVersionBadgeText(),
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: versionText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildInfoCard(
                      context: context,
                      isDark: isDark,
                      title: _getAboutTitle(),
                      description: _getAboutDescription(),
                      icon: Icons.favorite_border_rounded,
                      iconColor: const Color(0xFFE11D48),
                    ),
                    const SizedBox(height: 14),

                    _buildInfoCard(
                      context: context,
                      isDark: isDark,
                      title: _getMenuTitle(),
                      description: _getMenuDescription(),
                      icon: Icons.star_border_rounded,
                      iconColor: const Color(0xFFF59E0B),
                    ),
                    const SizedBox(height: 14),

                    _buildInfoCard(
                      context: context,
                      isDark: isDark,
                      title: _getSupportTitle(),
                      description: _getSupportDescription(),
                      icon: Icons.support_agent_rounded,
                      iconColor: const Color(0xFF3985E7),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      '© 2026 PediaGrow. All rights reserved.\nPantau Pertumbuhan, Cegah Stunting Untuk Masa Depan.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: subtitleColor,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getVersionBadgeText() {
    switch (staffRole) {
      case StaffRole.dokter:
        return 'Versi 1.0.0 (Portal Dokter)';
      case StaffRole.admin:
        return 'Versi 1.0.0 (Portal PMIK Admin)';
      case StaffRole.superadmin:
        return 'Versi 1.0.0 (Portal Superadmin)';
      case null:
        return 'Versi 1.0.0 (Rilis Publik)';
    }
  }

  String _getAboutTitle() {
    switch (staffRole) {
      case StaffRole.dokter:
        return 'Mengenal PediaGrow Dokter';
      case StaffRole.admin:
        return 'Mengenal PediaGrow PMIK';
      case StaffRole.superadmin:
        return 'Mengenal PediaGrow Superadmin';
      case null:
        return 'Mengenal PediaGrow';
    }
  }

  String _getAboutDescription() {
    switch (staffRole) {
      case StaffRole.dokter:
        return 'PediaGrow untuk Dokter mendukung dokter spesialis anak dan tenaga medis dalam memberikan layanan telemedisin profesional, memantau riwayat rekam medis pasien, serta mengatur jadwal praktik secara fleksibel.\n\nPediaGrow\nPantau Pertumbuhan, Cegah Stunting Untuk Masa Depan\n';
      case StaffRole.admin:
        return 'PediaGrow untuk PMIK (Perekam Medis & Informasi Kesehatan) memfasilitasi integrasi rekam medis pasien, pemantauan data tumbuh kembang anak, dan tata kelola informasi gizi balita.\n\nPediaGrow\nPantau Pertumbuhan, Cegah Stunting Untuk Masa Depan\n';
      case StaffRole.superadmin:
        return 'Portal Superadmin PediaGrow menyediakan pusat kendali penuh tata kelola akun, pengaturan hak akses dokter & staf PMIK, serta pengawasan menyeluruh modul data kesehatan anak.\n\nPediaGrow\nPantau Pertumbuhan, Cegah Stunting Untuk Masa Depan\n';
      case null:
        return 'PediaGrow merupakan aplikasi kesehatan anak yang berfungsi untuk membantu para orangtua untuk memantau pertumbuhan anak secara mudah dan praktis.\n\nPediaGrow\nPantau Pertumbuhan, Cegah Stunting Untuk Masa Depan\n';
    }
  }

  String _getMenuTitle() {
    switch (staffRole) {
      case StaffRole.dokter:
        return 'Fitur Utama Dokter';
      case StaffRole.admin:
        return 'Fitur Utama PMIK';
      case StaffRole.superadmin:
        return 'Fitur Utama Superadmin';
      case null:
        return 'Menu PediaGrow';
    }
  }

  String _getMenuDescription() {
    switch (staffRole) {
      case StaffRole.dokter:
        return '• Layanan Telekonsultasi Online Balita\n'
            '• Pengaturan Jadwal Praktik & Sesi Kerja\n'
            '• Riwayat Konsultasi & Catatan Medis Pasien\n'
            '• Monitoring Data Pasien Anak\n';
      case StaffRole.admin:
        return '• Rekam Medis & Riwayat Konsultasi\n'
            '• Pengelolaan Resep Menu MPASI\n'
            '• Monitoring Data Pasien & Deteksi Stunting\n'
            '• Pengawasan Layanan Fasilitas Kesehatan\n';
      case StaffRole.superadmin:
        return '• Manajemen Hak Akses Dokter & PMIK\n'
            '• Pengelolaan Konten Resep MPASI & Artikel\n'
            '• Pengawasan Rekam Medis & Notifikasi Sistem\n'
            '• Monitoring Menyeluruh Ekosistem PediaGrow\n';
      case null:
        return '• Deteksi & Cek Risiko Stunting Balita\n'
            '• Grafik Pertumbuhan Anak\n'
            '• Rekomendasi Menu Resep MPASI\n'
            '• Artikel Kesehatan\n'
            '• Konsultasi Online dengan Dokter\n'
            '• Lokasi Fasyankes Terdekat\n'
            '• Permainan Edukasi\n';
    }
  }

  String _getSupportTitle() {
    switch (staffRole) {
      case StaffRole.dokter:
        return 'Bantuan & Layanan Dokter';
      case StaffRole.admin:
        return 'Bantuan & Layanan PMIK';
      case StaffRole.superadmin:
        return 'Bantuan & Administrasi Sistem';
      case null:
        return 'Bantuan & Pengembang';
    }
  }

  String _getSupportDescription() {
    switch (staffRole) {
      case StaffRole.dokter:
        return 'Memerlukan bantuan teknis atau koordinasi operasional?\n\n'
            'Email: dokter@pediagrow.id\n'
            'WhatsApp Layanan Tenaga Medis: +62 812-3456-7890\n'
            'Website: https://pediagrow.id';
      case StaffRole.admin:
        return 'Memerlukan koordinasi teknis data rekam medis?\n\n'
            'Email: pmik@pediagrow.id\n'
            'WhatsApp Layanan Staf: +62 812-3456-7890\n'
            'Website: https://pediagrow.id';
      case StaffRole.superadmin:
        return 'Memerlukan koordinasi teknis pengembang sistem?\n\n'
            'Email: admin@pediagrow.id\n'
            'WhatsApp Admin Utama: +62 812-3456-7890\n'
            'Website: https://pediagrow.id';
      case null:
        return 'Memerlukan bantuan atau memiliki pertanyaan seputar aplikasi?\n\n'
            'Instagram: @Pedia.Grow\n'
            'Youtube: PediaGrow Official Channel\n'
            'Email: support@pediagrow.id\n'
            'Website: https://pediagrow.id\n'
            'WhatsApp Layanan Pengguna: +62 812-3456-7890';
    }
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF),
        ),
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
                  color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: GoogleFonts.lato(
              fontSize: 14,
              color: isDark ? const Color(0xFF8696A0) : const Color(0xFF4A5568),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
