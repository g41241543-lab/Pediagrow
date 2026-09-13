import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/riwayat_konsultasi_model.dart';

/// Widget Kartu Riwayat Konsultasi (Consultation Card).
///
/// Fitur dan Spesifikasi Tampilan:
/// - Background putih (#FFFFFF), sudut rounded (12dp), dan soft elevation shadow.
/// - Sisi kiri: Foto/profil dokter dengan ukuran proporsional (52dp).
/// - Sisi kanan: Nama dokter (Lato 16sp bold #000000), "Anak : [nama anak]" (Lato 14sp #7F7F7F),
///   dan "Keluhan : [keluhan]" (Lato 14sp #7F7F7F, flexible multi-line wrap tanpa overflow).
/// - Divider pemisah warna #C5C5C5 (ketebalan 0.8dp).
/// - Bagian bawah: Badge status "Selesai" (background #33CCA6, teks putih #FFFFFF Lato 12sp)
///   dan ikon kalender + tanggal konsultasi (Lato 13sp bold #000000).
/// - Tappable dengan respon sentuhan yang rapi.
class RiwayatConsultationCard extends StatelessWidget {
  final RiwayatKonsultasiModel riwayat;
  final VoidCallback? onTap;

  const RiwayatConsultationCard({
    super.key,
    required this.riwayat,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10.0,
            spreadRadius: 0,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Informasi Utama Dokter & Pasien
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Foto Dokter
                    _buildDoctorAvatar(),

                    const SizedBox(width: 14.0),

                    // Detail Nama, Anak, dan Keluhan
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nama Dokter
                          Text(
                            riwayat.doctorName,
                            style: GoogleFonts.lato(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF000000),
                              letterSpacing: -0.2,
                            ),
                          ),

                          const SizedBox(height: 3.0),

                          // Nama Anak
                          Text(
                            'Anak : ${riwayat.childName}',
                            style: GoogleFonts.lato(
                              fontSize: 14.0,
                              fontWeight: FontWeight.normal,
                              color: const Color(0xFF7F7F7F),
                            ),
                          ),

                          const SizedBox(height: 3.0),

                          // Keluhan Pasien (Fleksibel & wrapping otomatis)
                          Text(
                            'Keluhan : ${riwayat.complaint}',
                            style: GoogleFonts.lato(
                              fontSize: 14.0,
                              fontWeight: FontWeight.normal,
                              color: const Color(0xFF7F7F7F),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // 2. Divider Pemisah Berwarna #C5C5C5
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(
                    height: 1.0,
                    thickness: 0.8,
                    color: Color(0xFFC5C5C5),
                  ),
                ),

                // 3. Status Badge & Tanggal Konsultasi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Badge Status (misalnya "Selesai")
                    Container(
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

                    const SizedBox(width: 8.0),

                    // Ikon Kalender & Tanggal Konsultasi
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16.0,
                            color: Color(0xFF000000),
                          ),
                          const SizedBox(width: 6.0),
                          Flexible(
                            child: Text(
                              riwayat.formattedDate,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lato(
                                fontSize: 13.0,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF000000),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Avatar dokter responsif dengan dukungan asset maupun network image
  Widget _buildDoctorAvatar() {
    const double size = 52.0;

    if (riwayat.doctorPhoto != null && riwayat.doctorPhoto!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.asset(
          riwayat.doctorPhoto!,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(size),
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
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          size: 30.0,
          color: Color(0xFF72A9F4),
        ),
      ),
    );
  }
}
