import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/riwayat_konsultasi_model.dart';
import '../../../shared/widgets/doctor_live_avatar.dart';
import '../../../shared/widgets/pedia_bottom_nav_bar.dart';
import 'widgets/riwayat_header.dart';

/// Halaman Detail Konsultasi Pengguna PediaGrow.
///
/// Menampilkan rincian konsultasi yang dipilih dari kartu riwayat:
/// 1. Custom Header (56dp) "Detail Konsultasi" dengan tombol kembali.
/// 2. Profil dokter (foto avatar, nama dokter 17sp bold, spesialisasi 16sp #7F7F7F).
/// 3. Information rows dipisahkan divider #C5C5C5:
///    - Nama anak (icon profil, label 16sp #7F7F7F, nilai 16sp bold #000000)
///    - Tanggal Konsultasi (icon kalender, label 16sp #7F7F7F, nilai 16sp bold #000000)
///    - Status Konsultasi (icon checklist, label 16sp #7F7F7F, badge #33CCA6 "Selesai")
/// 4. Section Keluhan (Judul 16sp bold, isi 15sp regular, divider #C5C5C5).
/// 5. Section Ringkasan Konsultasi (Judul 16sp bold, resume dokter 15sp regular).
/// 6. Bottom Navigation Bar tetap di Scaffold.bottomNavigationBar dengan menu Riwayat aktif.
class DetailKonsultasiPage extends StatelessWidget {
  final RiwayatKonsultasiModel riwayat;

  const DetailKonsultasiPage({
    super.key,
    required this.riwayat,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1014) : Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: RiwayatHeader(
          title: 'Detail Konsultasi',
          showBackButton: true,
          showNotification: false,
          onBackPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDoctorProfileSection(isDark),
              const SizedBox(height: 24.0),
              _buildInfoRow(
                icon: Icons.person_outline,
                iconColor: const Color(0xFF3985E7),
                iconBgColor: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEBF5FF),
                label: 'Nama anak',
                labelColor: isDark ? const Color(0xFF8696A0) : const Color(0xFF7F7F7F),
                valueWidget: Text(
                  riwayat.childName,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.lato(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
                  ),
                ),
              ),
              Divider(
                height: 24.0,
                thickness: 0.8,
                color: isDark ? const Color(0xFF2C363D) : const Color(0xFFC5C5C5),
              ),
              _buildInfoRow(
                icon: Icons.calendar_today_outlined,
                iconColor: const Color(0xFFF59E0B),
                iconBgColor: isDark ? const Color(0xFF3D2B00) : const Color(0xFFFEF3C7),
                label: 'Tanggal Konsultasi',
                labelColor: isDark ? const Color(0xFF8696A0) : const Color(0xFF7F7F7F),
                valueWidget: Text(
                  riwayat.formattedDate,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.lato(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
                  ),
                ),
              ),
              Divider(
                height: 24.0,
                thickness: 0.8,
                color: isDark ? const Color(0xFF2C363D) : const Color(0xFFC5C5C5),
              ),
              _buildInfoRow(
                icon: Icons.check,
                iconColor: const Color(0xFF33CCA6),
                iconBgColor: isDark ? const Color(0xFF0D3B30) : const Color(0xFFE6F9F5),
                label: 'Status Konsultasi',
                labelColor: isDark ? const Color(0xFF8696A0) : const Color(0xFF7F7F7F),
                valueWidget: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF33CCA6),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Text(
                    riwayat.status,
                    style: GoogleFonts.lato(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26.0),
              Text(
                'Keluhan',
                style: GoogleFonts.lato(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                riwayat.fullComplaint.isNotEmpty
                    ? riwayat.fullComplaint
                    : riwayat.complaint,
                style: GoogleFonts.lato(
                  fontSize: 15.0,
                  fontWeight: FontWeight.normal,
                  color: isDark ? const Color(0xFFD1D7DB) : const Color(0xFF000000),
                  height: 1.45,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Divider(
                  height: 1.0,
                  thickness: 0.8,
                  color: isDark ? const Color(0xFF2C363D) : const Color(0xFFC5C5C5),
                ),
              ),
              Text(
                'Ringkasan Konsultasi',
                style: GoogleFonts.lato(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                riwayat.summary.trim().isNotEmpty
                    ? riwayat.summary
                    : '-',
                style: GoogleFonts.lato(
                  fontSize: 15.0,
                  fontWeight: FontWeight.normal,
<<<<<<< HEAD
                  color: isDark ? const Color(0xFFD1D7DB) : const Color(0xFF000000),
=======
                  color: riwayat.summary.trim().isNotEmpty
                      ? const Color(0xFF000000)
                      : const Color(0xFF9E9E9E),
                  fontStyle: riwayat.summary.trim().isEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
>>>>>>> 289e71df0313336a1855296b39040c36eaa51608
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 36.0),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PediaBottomNavBar(
        selectedIndex: 2,
      ),
    );
  }

  /// Profil dokter bagian atas
  Widget _buildDoctorProfileSection(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildDoctorAvatar(),
        const SizedBox(width: 16.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                riwayat.doctorName,
                style: GoogleFonts.lato(
                  fontSize: 17.0,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                riwayat.doctorSpecialization,
                style: GoogleFonts.lato(
                  fontSize: 16.0,
                  fontWeight: FontWeight.normal,
                  color: isDark ? const Color(0xFF8696A0) : const Color(0xFF7F7F7F),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Avatar dokter responsif dan real-time: terhubung langsung dengan koleksi doctors di Firestore.
  Widget _buildDoctorAvatar() {
    return DoctorLiveAvatar(
      doctorId: riwayat.doctorId,
      doctorName: riwayat.doctorName,
      fallbackPhoto: riwayat.doctorPhoto,
      size: 60.0,
      shape: BoxShape.circle,
    );
  }

  /// Baris informasi dengan ikon berwarna tematik, label, dan widget nilai fleksibel
  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required Widget valueWidget,
    Color? labelColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32.0,
          height: 32.0,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(8.0),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18.0,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12.0),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 16.0,
            fontWeight: FontWeight.normal,
            color: labelColor ?? const Color(0xFF7F7F7F),
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: valueWidget,
          ),
        ),
      ],
    );
  }
}
