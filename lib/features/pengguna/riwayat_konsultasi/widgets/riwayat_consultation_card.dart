import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/riwayat_konsultasi_model.dart';
import '../../../../shared/widgets/child_avatar.dart';
import '../../../../shared/widgets/hover_lift.dart';

/// Widget Kartu Riwayat Konsultasi (Consultation Card) POV Pengguna.
///
/// Tampilan disamakan persis dengan kartu riwayat konsultasi di POV Dokter:
/// - Sudut rounded (16dp), border halus (#E2E8F0), soft shadow.
/// - Baris Atas: Avatar profil anak resmi (ChildAvatar) + Nama Anak & Usia + Badge Status Selesai (#DCFCE7 / #15803D).
/// - Divider pemisah tipis (#F1F5F9).
/// - Baris Informasi: Dokter penanggung jawab (ikon orang) dan Tanggal konsultasi (ikon kalender).
/// - Ringkasan Keluhan tercantum di bagian bawah berformat italic elegan.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGirl = riwayat.childGender.toLowerCase() == 'perempuan' ||
        riwayat.childGender.toLowerCase() == 'p' ||
        riwayat.childGender.toLowerCase() == 'female';

    return HoverLift(
      borderRadius: BorderRadius.circular(16.0),
      cursor: SystemMouseCursors.click,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2228) : Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8.0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16.0),
          child: InkWell(
            onTap: onTap,
            mouseCursor: SystemMouseCursors.click,
            hoverColor: isDark
                ? const Color(0x33FFFFFF)
                : const Color(0x1F000000),
            splashColor: const Color(0xFF72A9F4).withValues(alpha: 0.12),
            highlightColor: const Color(0xFF72A9F4).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris Atas: Avatar + Nama & Usia + Badge Status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar Anak Profil Resmi
                      ChildAvatar(
                        gender: riwayat.childGender,
                        isGirl: isGirl,
                        size: 46.0,
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              riwayat.childName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lato(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFFE9EDEF)
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 3.0),
                            Text(
                              riwayat.childAge,
                              style: GoogleFonts.lato(
                                fontSize: 12.5,
                                color: isDark
                                    ? const Color(0xFF8696A0)
                                    : const Color(0xFF7F7F7F),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF064E3B).withValues(alpha: 0.4)
                              : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          riwayat.status.isEmpty ? 'Selesai' : riwayat.status,
                          style: GoogleFonts.lato(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  Divider(
                    height: 1.0,
                    thickness: 1.0,
                    color: isDark
                        ? const Color(0xFF2C363D)
                        : const Color(0xFFF1F5F9),
                  ),
                  const SizedBox(height: 10.0),

                  // Dokter & Tanggal
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 15.0,
                        color: isDark
                            ? const Color(0xFF8696A0)
                            : const Color(0xFF7F7F7F),
                      ),
                      const SizedBox(width: 6.0),
                      Expanded(
                        child: Text(
                          riwayat.doctorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: 13.0,
                            color: isDark
                                ? const Color(0xFF8696A0)
                                : const Color(0xFF7F7F7F),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14.0,
                        color: isDark
                            ? const Color(0xFF8696A0)
                            : const Color(0xFF7F7F7F),
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        riwayat.formattedDate,
                        style: GoogleFonts.lato(
                          fontSize: 12.5,
                          color: isDark
                              ? const Color(0xFF8696A0)
                              : const Color(0xFF7F7F7F),
                        ),
                      ),
                    ],
                  ),

                  // Ringkasan / Keluhan jika ada
                  if (riwayat.complaint.isNotEmpty) ...[
                    const SizedBox(height: 8.0),
                    Text(
                      'Keluhan: ${riwayat.complaint}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 12.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF475569),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
