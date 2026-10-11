import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/resume_medis_model.dart';
import '../beranda/beranda_superadmin_page.dart';
import '../konsultasi/konsultasi_superadmin_page.dart';
import '../profil/profil_superadmin_page.dart';

/// Halaman Detail Riwayat Konsultasi untuk PMIK Superadmin.
///
/// Menampilkan detail lengkap dari resume medis:
/// - Data anak (nama, umur saat konsultasi)
/// - Info konsultasi (dokter, tanggal, status)
/// - Keluhan lengkap
/// - Ringkasan konsultasi
/// - Asesmen dokter & rekomendasi
/// - Resep/suplemen
class DetailRiwayatKonsultasiAdminPage extends StatelessWidget {
  final ResumeMedisModel resume;

  const DetailRiwayatKonsultasiAdminPage({
    super.key,
    required this.resume,
  });

  static const Color _colorPrimaryBlue = Color(0xFF3985E7);
  static const Color _colorNavBg = Color(0xFFF2EDED);
  static const int _selectedNavIndex = 2;

  void _onBottomNavTap(BuildContext context, int index) {
    if (index == _selectedNavIndex) {
      Navigator.of(context).pop();
      return;
    }
    Widget targetPage;
    switch (index) {
      case 0:
        targetPage = const BerandaSuperadminPage();
        break;
      case 1:
        targetPage = const KonsultasiSuperadminPage();
        break;
      case 3:
        targetPage = const ProfilSuperadminPage();
        break;
      default:
        return;
    }
    final isLeft = index < _selectedNavIndex;
    final beginOffset = Offset(isLeft ? -0.25 : 0.25, 0.0);
    final route = PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, _, _) => targetPage,
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
    if (index == 0) {
      Navigator.of(context).pushAndRemoveUntil(route, (r) => false);
    } else {
      Navigator.of(context).pushReplacement(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: _buildHeader(context),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 14.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Kartu Data Anak
                            _buildPatientCard(),
                            const SizedBox(height: 16.0),

                            // 2. Kartu Info Konsultasi
                            _buildConsultationInfoCard(),
                            const SizedBox(height: 20.0),

                            // 3. Keluhan
                            _buildSectionLabel('Keluhan'),
                            const SizedBox(height: 6.0),
                            _buildSectionText(
                              resume.complaint.isNotEmpty
                                  ? resume.complaint
                                  : '-',
                            ),
                            const SizedBox(height: 20.0),

                            // 4. Ringkasan Konsultasi
                            _buildSectionLabel('Ringkasan Konsultasi'),
                            const SizedBox(height: 6.0),
                            _buildSectionText(
                              resume.summary.isNotEmpty ? resume.summary : '-',
                            ),
                            const SizedBox(height: 20.0),

                            // 5. Asesmen Dokter
                            if (resume.doctorAssessment.isNotEmpty) ...[
                              _buildSectionLabel('Asesmen Dokter'),
                              const SizedBox(height: 6.0),
                              _buildSectionText(resume.doctorAssessment),
                              const SizedBox(height: 20.0),
                            ],

                            // 6. Rekomendasi
                            if (resume.recommendations.isNotEmpty) ...[
                              _buildSectionLabel('Rekomendasi'),
                              const SizedBox(height: 6.0),
                              _buildRecommendations(resume.recommendations),
                              const SizedBox(height: 20.0),
                            ],

                            // 7. Resep / Suplemen
                            _buildSectionLabel('Resep / Suplemen'),
                            const SizedBox(height: 6.0),
                            _buildSectionText(
                              resume.prescription.isNotEmpty
                                  ? resume.prescription
                                  : '-',
                            ),
                            const SizedBox(height: 20.0),

                            // 8. Banner Mode Nonaktif
                            _buildReadOnlyBanner(),
                            const SizedBox(height: 16.0),
                          ],
                        ),
                      ),
                      const Spacer(),
                      _buildFooterIllustration(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56.0,
          child: Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 36.0,
                    height: 36.0,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_back,
                      size: 24.0,
                      color: Color(0xFF000000),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    'Detail Riwayat Konsultasi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF000000),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── KARTU DATA ANAK ──────────────────────────────────────────────────────
  Widget _buildPatientCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 10.0,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar dengan inisial
          Container(
            width: 52.0,
            height: 52.0,
            decoration: BoxDecoration(
              color: _avatarColor(resume.childName),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(resume.childName),
              style: GoogleFonts.lato(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14.0),
          // Nama & Umur
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  resume.childName,
                  style: GoogleFonts.lato(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                if (resume.childAgeAtConsultation.isNotEmpty) ...[
                  const SizedBox(height: 3.0),
                  Text(
                    resume.childAgeAtConsultation,
                    style: GoogleFonts.lato(
                      fontSize: 13.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── KARTU INFO KONSULTASI ────────────────────────────────────────────────
  Widget _buildConsultationInfoCard() {
    final isSelesai = resume.status.toLowerCase().contains('selesai');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FE),
        borderRadius: BorderRadius.circular(14.0),
      ),
      child: Column(
        children: [
          // Dokter
          _buildInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Dokter',
            value: resume.doctorName,
          ),
          const SizedBox(height: 12.0),
          // Spesialisasi
          if (resume.doctorSpecialization.isNotEmpty)
            _buildInfoRow(
              icon: Icons.local_hospital_outlined,
              label: 'Spesialisasi',
              value: resume.doctorSpecialization,
            ),
          if (resume.doctorSpecialization.isNotEmpty)
            const SizedBox(height: 12.0),
          // Tanggal Konsultasi
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Tanggal',
            value: resume.consultationDate,
          ),
          if (resume.consultationTime.isNotEmpty) ...[
            const SizedBox(height: 12.0),
            _buildInfoRow(
              icon: Icons.access_time_outlined,
              label: 'Waktu',
              value: resume.consultationTime,
            ),
          ],
          const SizedBox(height: 14.0),
          // Status
          Row(
            children: [
              const Icon(
                Icons.assignment_outlined,
                size: 19.0,
                color: Color(0xFF7E8B9B),
              ),
              const SizedBox(width: 8.0),
              Text(
                'Status',
                style: GoogleFonts.lato(
                  fontSize: 14.0,
                  color: const Color(0xFF7E8B9B),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: isSelesai
                      ? const Color(0xFF33CCA6)
                      : const Color(0xFFFFCD38),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  resume.status,
                  style: GoogleFonts.lato(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 19.0, color: const Color(0xFF7E8B9B)),
        const SizedBox(width: 8.0),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 14.0,
            color: const Color(0xFF7E8B9B),
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.lato(
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  // ─── SECTION HELPERS ──────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.lato(
        fontSize: 14.5,
        color: const Color(0xFF64748B),
        fontWeight: FontWeight.normal,
      ),
    );
  }

  Widget _buildSectionText(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Text(
        text,
        style: GoogleFonts.lato(
          fontSize: 14.0,
          color: const Color(0xFF1E293B),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildRecommendations(List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: idx < items.length - 1 ? 8.0 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6.0,
                  height: 6.0,
                  margin: const EdgeInsets.only(top: 6.0, right: 10.0),
                  decoration: const BoxDecoration(
                    color: Color(0xFF3985E7),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.lato(
                      fontSize: 14.0,
                      color: const Color(0xFF1E293B),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── READ-ONLY BANNER ─────────────────────────────────────────────────────
  Widget _buildReadOnlyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF5FF),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: _colorPrimaryBlue.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 24.0,
            color: _colorPrimaryBlue,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              'Mode nonaktif. Anda tidak dapat membalas atau mengubah riwayat konsultasi.',
              style: GoogleFonts.lato(
                fontSize: 13.5,
                color: _colorPrimaryBlue,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── FOOTER ILLUSTRATION ──────────────────────────────────────────────────
  Widget _buildFooterIllustration() {
    return SizedBox(
      width: double.infinity,
      child: Image.asset(
        'assets/images/beranda_landscape_footer_fiks.png',
        width: double.infinity,
        fit: BoxFit.fitWidth,
        alignment: Alignment.bottomCenter,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 100,
          color: const Color(0xFFD1FAE5),
          alignment: Alignment.center,
          child: const Icon(
            Icons.park_outlined,
            size: 44,
            color: Color(0xFF34D399),
          ),
        ),
      ),
    );
  }

  // ─── SUPERADMIN BOTTOM NAVIGATION BAR ─────────────────────────────────────
  Widget _buildBottomNavigationBar(BuildContext context) {
    const navItems = [
      _NavItem(icon: Icons.home_rounded, label: 'Beranda'),
      _NavItem(icon: Icons.question_answer_rounded, label: 'Konsultasi'),
      _NavItem(icon: Icons.manage_search_rounded, label: 'Riwayat Konsultasi'),
      _NavItem(icon: Icons.person_rounded, label: 'Profil'),
    ];

    return Container(
      width: double.infinity,
      height: 68.0,
      decoration: const BoxDecoration(
        color: _colorNavBg,
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 8.0,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(navItems.length, (i) {
            final isSelected = i == _selectedNavIndex;
            final item = navItems[i];
            return Expanded(
              child: GestureDetector(
                onTap: () => _onBottomNavTap(context, i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: 68.0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        Container(
                          width: 36.0,
                          height: 36.0,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 4.0,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            item.icon,
                            size: 22.0,
                            color: const Color(0xFF72A9F4),
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                fontSize: 11.0,
                                fontWeight: FontWeight.normal,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Icon(
                          item.icon,
                          size: 24.0,
                          color: const Color(0xFF9E9E9E),
                        ),
                        const SizedBox(height: 3.0),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lato(
                                fontSize: 11.0,
                                fontWeight: FontWeight.normal,
                                color: const Color(0xFF9E9E9E),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Warna avatar berdasarkan huruf pertama nama
  Color _avatarColor(String name) {
    const colors = [
      Color(0xFF72A9F4),
      Color(0xFFFF8FA3),
      Color(0xFF34D399),
      Color(0xFFFBBF24),
      Color(0xFFA78BFA),
      Color(0xFFF87171),
      Color(0xFF60A5FA),
      Color(0xFF4ADE80),
    ];
    final idx = name.isEmpty ? 0 : name.codeUnitAt(0) % colors.length;
    return colors[idx];
  }

  /// Inisial 2 huruf dari nama
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
