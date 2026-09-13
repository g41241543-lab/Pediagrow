import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/child_model.dart';
import '../../../models/doctor_model.dart';
import 'menunggu_persetujuan_page.dart';

/// Halaman Profil Dokter Spesialis Anak PediaGrow.
///
/// Menampilkan informasi lengkap dokter yang dipilih pengguna, mencakup:
/// - Header dengan tombol kembali & judul "Profil Dokter"
/// - Kartu identitas dokter (foto avatar, badge online, nama dokter, spesialisasi)
/// - Statistik dokter (tahun pengalaman, nomor STR, kepuasan pasien)
/// - Seksi tentang dokter & keahlian klinis
/// - Seksi tempat & jadwal konsultasi
/// - Tombol aksi utama di bagian bawah: "Chat Dokter" yang bernavigasi ke
///   halaman animasi [MenungguPersetujuanPage].
class ProfilDokterPage extends StatelessWidget {
  final DoctorModel doctor;
  final ChildModel? child;

  const ProfilDokterPage({
    super.key,
    required this.doctor,
    this.child,
  });

  // Design Tokens Resmi PediaGrow
  static const Color colorPrimaryBlue = Color(0xFF2A85FF);
  static const Color colorSoftBlue = Color(0xFFEBF5FF);
  static const Color colorTextPrimary = Color(0xFF1A202C);
  static const Color colorTextSecondary = Color(0xFF718096);
  static const Color colorBorder = Color(0xFFE2E8F0);
  static const Color colorOnlineGreen = Color(0xFF48BB78);
  static const Color colorAmberRating = Color(0xFFFFB020);

  void _onChatDokterPressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MenungguPersetujuanPage(
          doctor: doctor,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Tetap
            _buildHeader(context),

            // 2. Konten Scrollable
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Profil Utama Dokter
                    _buildDoctorMainCard(),
                    const SizedBox(height: 16),

                    // Baris 3 Statistik (Pengalaman, STR, Rating)
                    _buildDoctorStatsRow(),
                    const SizedBox(height: 20),

                    // Seksi: Tentang Dokter
                    _buildAboutSection(),
                    const SizedBox(height: 20),

                    // Seksi: Tempat & Jadwal Praktik
                    _buildScheduleSection(),
                    const SizedBox(height: 20),

                    // Informasi Konsultasi Medis
                    _buildMedicalNoticeCard(),
                  ],
                ),
              ),
            ),

            // 3. Tombol Fixed "Chat Dokter" di Bawah
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. HEADER TETAP (56dp)
  // ===========================================================================

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 56,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(context).maybePop(),
              child: const SizedBox(
                width: 38,
                height: 38,
                child: Center(
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: colorTextPrimary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Profil Dokter',
            style: GoogleFonts.lato(
              fontSize: 18.5,
              fontWeight: FontWeight.bold,
              color: colorTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. KARTU PROFIL UTAMA DOKTER
  // ===========================================================================

  Widget _buildDoctorMainCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorSoftBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Foto Dokter dengan Badge Online
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: doctor.assetImagePath != null &&
                          doctor.assetImagePath!.isNotEmpty
                      ? Image.asset(
                          doctor.assetImagePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            size: 40,
                            color: colorTextSecondary,
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 40,
                          color: colorTextSecondary,
                        ),
                ),
              ),
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colorOnlineGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Identitas Dokter
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
                  style: GoogleFonts.lato(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: colorTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  doctor.specialization,
                  style: GoogleFonts.lato(
                    fontSize: 13.5,
                    color: colorPrimaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.local_hospital_outlined,
                      size: 15,
                      color: colorTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        doctor.hospital ?? 'RSIA PediaCare & Klinisi Anak',
                        style: GoogleFonts.lato(
                          fontSize: 12.5,
                          color: colorTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. STATISTIK DOKTER
  // ===========================================================================

  Widget _buildDoctorStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            title: 'Pengalaman',
            value: '${doctor.experienceYears} Tahun',
            icon: Icons.work_history_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem(
            title: 'Penilaian',
            value: '4.9 / 5.0',
            icon: Icons.star_rounded,
            iconColor: colorAmberRating,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatItem(
            title: 'Pasien',
            value: '500+ Konsul',
            icon: Icons.groups_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: iconColor ?? colorPrimaryBlue),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.lato(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: colorTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.lato(
              fontSize: 11,
              color: colorTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. SEKSI TENTANG DOKTER
  // ===========================================================================

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tentang Dokter',
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${doctor.name} adalah dokter spesialis anak berpengalaman yang berfokus pada pemantauan tumbuh kembang anak, pencegahan stunting, pemenuhan nutrisi MPASI, serta penanganan infeksi anak umum. Beliau berkomitmen memberikan edukasi kesehatan terbaik bagi orang tua.',
          style: GoogleFonts.lato(
            fontSize: 13.5,
            color: const Color(0xFF4A5568),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 10),
        // Nomor STR
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 16,
                color: colorPrimaryBlue,
              ),
              const SizedBox(width: 6),
              Text(
                'No. STR: ${doctor.strNumber ?? "3511201402016252"}',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 5. TEMPAT & JADWAL KONSULTASI
  // ===========================================================================

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jadwal Konsultasi Online',
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorTextPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorBorder),
          ),
          child: Column(
            children: [
              _buildScheduleRow(
                'Senin - Jumat',
                '08.00 - 20.00 WIB',
                isActive: true,
              ),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              _buildScheduleRow(
                'Sabtu - Minggu',
                '09.00 - 17.00 WIB',
                isActive: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleRow(String day, String time, {required bool isActive}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 16,
              color: colorPrimaryBlue,
            ),
            const SizedBox(width: 8),
            Text(
              day,
              style: GoogleFonts.lato(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: colorTextPrimary,
              ),
            ),
          ],
        ),
        Text(
          time,
          style: GoogleFonts.lato(
            fontSize: 13,
            color: colorTextSecondary,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 6. CATATAN MEDIS
  // ===========================================================================

  Widget _buildMedicalNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFFD97706),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Konsultasi telemedicine ditujukan untuk edukasi, keluhan umum, dan pertolongan pertama si kecil.',
              style: GoogleFonts.lato(
                fontSize: 12,
                color: const Color(0xFF92400E),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 7. TOMBOL FIXED "CHAT DOKTER"
  // ===========================================================================

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: () => _onChatDokterPressed(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorPrimaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                'Chat Dokter',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
