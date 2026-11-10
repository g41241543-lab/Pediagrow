import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/riwayat_konsultasi_model.dart';
import '../../../../shared/widgets/child_avatar.dart';

/// Widget Kartu Riwayat Konsultasi (Consultation Card) POV Pengguna.
///
/// Tampilan disamakan persis dengan kartu riwayat konsultasi di POV Dokter:
/// - Sudut rounded (16dp), border halus (#E2E8F0), soft shadow.
/// - Baris Atas: Avatar profil anak resmi (ChildAvatar) + Nama Anak & Usia + Badge Status Selesai (#DCFCE7 / #15803D).
/// - Divider pemisah tipis (#F1F5F9).
/// - Baris Informasi: Dokter penanggung jawab (ikon orang) dan Tanggal konsultasi (ikon kalender).
/// Widget Kartu Riwayat Konsultasi (Consultation Card) POV Pengguna.
///
/// Tampilan disamakan persis dengan kartu riwayat konsultasi di POV Dokter:
/// - Sudut rounded (16dp), border halus (#E2E8F0), soft shadow.
/// - Baris Atas: Avatar profil anak resmi (ChildAvatar) + Nama Anak & Usia + Badge Status Selesai (#DCFCE7 / #15803D).
/// - Divider pemisah tipis (#F1F5F9).
/// - Baris Informasi: Dokter penanggung jawab (ikon orang) dan Tanggal konsultasi (ikon kalender).
/// - Ringkasan Keluhan tercantum di bagian bawah berformat italic elegan.
/// - Interaktif: Efek hover & touch lift (terangkat -3dp), border highlight glow
///   aktif baik pada desktop maupun sentuhan layar HP (mode pengembang).
class RiwayatConsultationCard extends StatefulWidget {
  final RiwayatKonsultasiModel riwayat;
  final VoidCallback? onTap;

  const RiwayatConsultationCard({
    super.key,
    required this.riwayat,
    this.onTap,
  });

  @override
  State<RiwayatConsultationCard> createState() => _RiwayatConsultationCardState();
}

class _RiwayatConsultationCardState extends State<RiwayatConsultationCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isActive => _isHovered || _isPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGirl = widget.riwayat.childGender.toLowerCase() == 'perempuan' ||
        widget.riwayat.childGender.toLowerCase() == 'p' ||
        widget.riwayat.childGender.toLowerCase() == 'female';

    // Warna aksen konsisten dengan kartu Resume Medis (#2B7AE8 dan #BFDBFE)
    const primaryBlue = Color(0xFF2B7AE8);

    // Latar belakang card: berubah menjadi biru muda lembut saat disentuh/di-hover
    final cardBgColor = _isActive
        ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F7FF))
        : (isDark ? const Color(0xFF1A2228) : Colors.white);

    // Garis tepi (border): biru muda lembut (#BFDBFE) saat normal, dan menyala biru tajam saat aktif
    final borderColor = _isActive
        ? primaryBlue
        : (isDark ? const Color(0xFF2C363D) : const Color(0xFFBFDBFE));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (mounted) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _isHovered = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isActive ? -3.0 : 0.0, 0),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: borderColor,
            width: _isActive ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _isActive
                  ? primaryBlue.withValues(alpha: isDark ? 0.35 : 0.20)
                  : primaryBlue.withValues(alpha: isDark ? 0.25 : 0.08),
              blurRadius: _isActive ? 14.0 : 10.0,
              offset: _isActive ? const Offset(0, 5) : const Offset(0, 3),
            ),
            if (!_isActive)
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 6.0,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16.0),
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) {
              if (mounted) setState(() => _isPressed = true);
            },
            onTapUp: (_) {
              if (mounted) setState(() => _isPressed = false);
            },
            onTapCancel: () {
              if (mounted) setState(() => _isPressed = false);
            },
            onHover: (hovering) {
              if (mounted) setState(() => _isHovered = hovering);
            },
            mouseCursor: SystemMouseCursors.click,
            splashColor: primaryBlue.withValues(alpha: 0.12),
            highlightColor: primaryBlue.withValues(alpha: 0.08),
            hoverColor: primaryBlue.withValues(alpha: 0.04),
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
                          gender: widget.riwayat.childGender,
                          isGirl: isGirl,
                          size: 46.0,
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.riwayat.childName,
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
                                widget.riwayat.childAge,
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
                            widget.riwayat.status.isEmpty ? 'Selesai' : widget.riwayat.status,
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
                            widget.riwayat.doctorName,
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
                          widget.riwayat.formattedDate,
                          style: GoogleFonts.lato(
                            fontSize: 12.5,
                            color: isDark
                                ? const Color(0xFF8696A0)
                                : const Color(0xFF7F7F7F),
                          ),
                        ),
                      ],
                    ),

                    // Ringkasan Konsultasi atau Keluhan
                    if (widget.riwayat.summary.isNotEmpty) ...[
                      const SizedBox(height: 8.0),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 6.0,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'Ringkasan: ${widget.riwayat.summary}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: 12.0,
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF334155),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ] else if (widget.riwayat.complaint.isNotEmpty) ...[
                      const SizedBox(height: 8.0),
                      Text(
                        'Keluhan: ${widget.riwayat.complaint}',
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
