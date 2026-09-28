import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/riwayat_konsultasi_model.dart';
import '../beranda/beranda_superadmin_page.dart';
import '../konsultasi/konsultasi_superadmin_page.dart';
import '../profil/profil_superadmin_page.dart';

/// Halaman Detail Riwayat Konsultasi untuk PMIK Superadmin.
///
/// Dibuat semirip mungkin dengan desain referensi resmi PediaGrow:
/// - Header 56dp dengan tombol kembali 12dp dari kiri, judul "Detail Riwayat Konsultasi" 12dp dari tombol.
/// - Kartu info pasien (avatar kartun bayi, nama anak, umur anak).
/// - Kartu info konsultasi berlatar biru muda (Dokter, Tanggal Konsultasi, Status Konsultasi dengan badge).
/// - Seksi Keluhan.
/// - Seksi Ringkasan Konsultasi.
/// - Banner peringatan Mode Nonaktif (read-only).
/// - Ilustrasi lanskap hutan di bagian paling bawah scroll.
/// - Superadmin Bottom Navigation Bar dengan tab Riwayat Konsultasi (Index 2) aktif.
class DetailRiwayatKonsultasiAdminPage extends StatelessWidget {
  final RiwayatKonsultasiModel riwayat;

  const DetailRiwayatKonsultasiAdminPage({
    super.key,
    required this.riwayat,
  });

  static const Color _colorPrimaryBlue = Color(0xFF3985E7);
  static const Color _colorNavBg = Color(0xFFF2EDED);
  static const int _selectedNavIndex = 2;

  void _onBottomNavTap(BuildContext context, int index) {
    if (index == _selectedNavIndex) return;
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
      pageBuilder: (_, __, ___) => targetPage,
      transitionsBuilder: (_, animation, __, child) {
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
                            // 1. Kartu Info Pasien
                            _buildPatientCard(),
                            const SizedBox(height: 16.0),

                            // 2. Kartu Info Konsultasi (Latar Biru Muda)
                            _buildConsultationInfoCard(),
                            const SizedBox(height: 20.0),

                            // 3. Seksi Keluhan
                            Text(
                              'Keluhan',
                              style: GoogleFonts.lato(
                                fontSize: 14.5,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            Text(
                              riwayat.fullComplaint.isNotEmpty
                                  ? riwayat.fullComplaint
                                  : riwayat.complaint,
                              style: GoogleFonts.lato(
                                fontSize: 14.5,
                                color: const Color(0xFF1E293B),
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 20.0),

                            // 4. Seksi Ringkasan Konsultasi
                            Text(
                              'Ringkasan Konsultasi',
                              style: GoogleFonts.lato(
                                fontSize: 14.5,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            Text(
                              riwayat.summary,
                              style: GoogleFonts.lato(
                                fontSize: 14.5,
                                color: const Color(0xFF1E293B),
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 20.0),

                            // 5. Banner Mode Nonaktif
                            _buildReadOnlyBanner(),
                            const SizedBox(height: 16.0),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // 6. Ilustrasi Lanskap Hutan
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

  // ─── PATIENT CARD ─────────────────────────────────────────────────────────
  Widget _buildPatientCard() {
    final isGirl = riwayat.childGender == 'female';

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
          // Avatar Bayi
          Container(
            width: 52.0,
            height: 52.0,
            decoration: BoxDecoration(
              color: isGirl
                  ? const Color(0xFFFFD6D9)
                  : const Color(0xFFD0E8FD),
              shape: BoxShape.circle,
            ),
            child: CustomPaint(
              painter: _BabyFacePainter(isGirl: isGirl),
            ),
          ),
          const SizedBox(width: 14.0),
          // Nama & Umur Pasien
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  riwayat.childName,
                  style: GoogleFonts.lato(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 3.0),
                Text(
                  riwayat.childAge,
                  style: GoogleFonts.lato(
                    fontSize: 13.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── CONSULTATION INFO CARD (ICE BLUE) ─────────────────────────────────────
  Widget _buildConsultationInfoCard() {
    final isSelesai = riwayat.status.toLowerCase().contains('selesai');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FE),
        borderRadius: BorderRadius.circular(14.0),
      ),
      child: Column(
        children: [
          // Baris 1: Dokter
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 20.0,
                color: Color(0xFF7E8B9B),
              ),
              const SizedBox(width: 8.0),
              Text(
                'Dokter',
                style: GoogleFonts.lato(
                  fontSize: 14.0,
                  color: const Color(0xFF7E8B9B),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  riwayat.doctorName,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.lato(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),

          // Baris 2: Tanggal Konsultasi
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 18.0,
                color: Color(0xFF7E8B9B),
              ),
              const SizedBox(width: 8.0),
              Text(
                'Tanggal Konsultasi',
                style: GoogleFonts.lato(
                  fontSize: 14.0,
                  color: const Color(0xFF7E8B9B),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  riwayat.formattedDate,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.lato(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),

          // Baris 3: Status Konsultasi
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.assignment_outlined,
                size: 19.0,
                color: Color(0xFF7E8B9B),
              ),
              const SizedBox(width: 8.0),
              Text(
                'Status Konsultasi',
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
                  riwayat.status,
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

  // ─── READ-ONLY BANNER ─────────────────────────────────────────────────────
  Widget _buildReadOnlyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF5FF),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: _colorPrimaryBlue.withOpacity(0.4),
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
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

/// Custom painter untuk menggambar kartun wajah bayi lucu dan presisi
class _BabyFacePainter extends CustomPainter {
  final bool isGirl;
  const _BabyFacePainter({this.isGirl = true});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final strokePaint = Paint()
      ..color = const Color(0xFF222222)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = const Color(0xFF222222)
      ..style = PaintingStyle.fill;

    final blushPaint = Paint()
      ..color = const Color(0xFFFF8FA3).withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final cx = w * 0.5;
    final cy = h * 0.52;
    final r = w * 0.36;

    // Lingkaran kepala
    final headRect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    canvas.drawArc(headRect, 0, 3.14159 * 2, false, strokePaint);

    // Poni rambut
    final hairPath = Path();
    hairPath.moveTo(cx - r * 0.85, cy - r * 0.3);
    hairPath.quadraticBezierTo(cx - r * 0.35, cy - r * 0.9, cx, cy - r * 0.4);
    hairPath.quadraticBezierTo(
      cx + r * 0.35,
      cy - r * 0.9,
      cx + r * 0.85,
      cy - r * 0.3,
    );
    canvas.drawPath(hairPath, strokePaint);

    // Mata
    canvas.drawCircle(
      Offset(cx - r * 0.38, cy - r * 0.05),
      w * 0.045,
      fillPaint,
    );
    canvas.drawCircle(
      Offset(cx + r * 0.38, cy - r * 0.05),
      w * 0.045,
      fillPaint,
    );

    // Pipi kemerahan
    canvas.drawCircle(
      Offset(cx - r * 0.55, cy + r * 0.15),
      w * 0.065,
      blushPaint,
    );
    canvas.drawCircle(
      Offset(cx + r * 0.55, cy + r * 0.15),
      w * 0.065,
      blushPaint,
    );

    // Senyuman
    final smilePath = Path();
    smilePath.moveTo(cx - r * 0.35, cy + r * 0.18);
    smilePath.quadraticBezierTo(cx, cy + r * 0.62, cx + r * 0.35, cy + r * 0.18);
    canvas.drawPath(smilePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
