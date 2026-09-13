import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/riwayat_konsultasi_model.dart';
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
    return Scaffold(
      backgroundColor: Colors.white,
      // Header tetap di paling atas (tidak ikut ter-scroll)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: RiwayatHeader(
          title: 'Detail Konsultasi',
          onBackPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // Konten utama scrollable untuk kenyamanan di seluruh ukuran layar
      body: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Profil Dokter (Foto di kiri, Nama & Spesialis di kanan)
              _buildDoctorProfileSection(),

              const SizedBox(height: 24.0),

              // 2. Baris Informasi Konsultasi (Nama anak, Tanggal, Status)
              _buildInfoRow(
                icon: Icons.person_outline,
                iconColor: const Color(0xFF3985E7),
                iconBgColor: const Color(0xFFEBF5FF),
                label: 'Nama anak',
                valueWidget: Text(
                  riwayat.childName,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.lato(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF000000),
                  ),
                ),
              ),

              const Divider(
                height: 24.0,
                thickness: 0.8,
                color: Color(0xFFC5C5C5),
              ),

              _buildInfoRow(
                icon: Icons.calendar_today_outlined,
                iconColor: const Color(0xFFF59E0B),
                iconBgColor: const Color(0xFFFEF3C7),
                label: 'Tanggal Konsultasi',
                valueWidget: Text(
                  riwayat.formattedDate,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.lato(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF000000),
                  ),
                ),
              ),

              const Divider(
                height: 24.0,
                thickness: 0.8,
                color: Color(0xFFC5C5C5),
              ),

              _buildInfoRow(
                icon: Icons.check,
                iconColor: const Color(0xFF33CCA6),
                iconBgColor: const Color(0xFFE6F9F5),
                label: 'Status Konsultasi',
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

              // 3. Section Keluhan
              Text(
                'Keluhan',
                style: GoogleFonts.lato(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF000000),
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
                  color: const Color(0xFF000000),
                  height: 1.45,
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Divider(
                  height: 1.0,
                  thickness: 0.8,
                  color: Color(0xFFC5C5C5),
                ),
              ),

              // 4. Section Ringkasan Konsultasi
              Text(
                'Ringkasan Konsultasi',
                style: GoogleFonts.lato(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                riwayat.summary,
                style: GoogleFonts.lato(
                  fontSize: 15.0,
                  fontWeight: FontWeight.normal,
                  color: const Color(0xFF000000),
                  height: 1.45,
                ),
              ),

              // Spacing ekstra di bawah agar tidak mepet navigation bar
              const SizedBox(height: 36.0),
            ],
          ),
        ),
      ),
      // Bottom Navigation Bar permanen di bawah layar
      bottomNavigationBar: const PediaBottomNavBar(
        selectedIndex: 2,
      ),
    );
  }

  /// Profil dokter bagian atas
  Widget _buildDoctorProfileSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar Dokter
        _buildDoctorAvatar(),

        const SizedBox(width: 16.0),

        // Nama dan Spesialisasi Dokter
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                riwayat.doctorName,
                style: GoogleFonts.lato(
                  fontSize: 17.0,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF000000),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                riwayat.doctorSpecialization,
                style: GoogleFonts.lato(
                  fontSize: 16.0,
                  fontWeight: FontWeight.normal,
                  color: const Color(0xFF7F7F7F),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Avatar dokter dengan ukuran responsif (60dp)
  Widget _buildDoctorAvatar() {
    const double size = 60.0;

    if (riwayat.doctorPhoto != null && riwayat.doctorPhoto!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.asset(
            riwayat.doctorPhoto!,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                _buildFallbackAvatar(size),
          ),
        ),
      );
    }

    return _buildFallbackAvatar(size);
  }

  Widget _buildFallbackAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          size: 34.0,
          color: Color(0xFF72A9F4),
        ),
      ),
    );
  }

  /// Baris informasi dengan ikon berwarna tematik, label, dan widget nilai fleksibel
  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required Widget valueWidget,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Container ikon dengan warna tematik dan latar lembut
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

        // Label (misal "Nama anak", "Tanggal Konsultasi", "Status Konsultasi")
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 16.0,
            fontWeight: FontWeight.normal,
            color: const Color(0xFF7F7F7F),
          ),
        ),

        const SizedBox(width: 8.0),

        // Nilai informasi di sebelah kanan (fleksibel)
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
