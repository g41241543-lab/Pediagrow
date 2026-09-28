import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/child_model.dart';
import '../../../../models/user_model.dart';
import '../../../../shared/widgets/illustration_forest_footer.dart';

import '../beranda_superadmin_page.dart';
import '../../konsultasi/konsultasi_superadmin_page.dart';
import '../../riwayat_konsultasi/daftar_riwayat_konsultasi_admin_page.dart';
import '../../profil/profil_superadmin_page.dart';

/// Halaman Detail Pengguna & Anak untuk POV Superadmin.
/// Menampilkan data profil orang tua (pengguna) dan data klinis/tumbuh kembang anak.
class DetailPenggunaPage extends StatelessWidget {
  final UserModel user;
  final ChildModel? child;

  const DetailPenggunaPage({
    super.key,
    required this.user,
    this.child,
  });

  /// Handler navigasi bottom bar superadmin.
  /// Menggunakan FadeTransition (200ms) agar animasi konsisten dengan beranda → profil.
  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const BerandaSuperadminPage(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 200),
          ),
          (route) => false,
        );
        break;
      case 1:
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const KonsultasiSuperadminPage(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 200),
          ),
        );
        break;
      case 2:
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const DaftarRiwayatKonsultasiAdminPage(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 200),
          ),
        );
        break;
      case 3:
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const ProfilSuperadminPage(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 200),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header Fixed 56dp
            Container(
              width: double.infinity,
              height: 56,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.arrow_back,
                        color: Color(0xFF000000),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Detail Pasien',
                      style: GoogleFonts.lato(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF000000),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Konten Scrollable
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Card Profil Orang Tua / Pengguna
                                  _buildSectionCard(
                                    title: 'Data Orang Tua (Pengguna)',
                                    icon: Icons.person_outline_rounded,
                                    children: [
                                      _buildInfoRow('Nama Lengkap', user.name),
                                      _buildInfoRow(
                                        'Email',
                                        user.email.isNotEmpty ? user.email : '-',
                                      ),
                                      if (user.phone != null && user.phone!.isNotEmpty)
                                        _buildInfoRow('Nomor Telepon', user.phone!),
                                      if (user.city != null && user.city!.isNotEmpty)
                                        _buildInfoRow(
                                          'Kota / Domisili',
                                          '${user.city ?? ''}, ${user.province ?? ''}'.trim(),
                                        ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Card Profil Anak
                                  if (child != null)
                                    _buildSectionCard(
                                      title: 'Data Profil Anak',
                                      icon: Icons.child_care_rounded,
                                      children: [
                                        _buildInfoRow('Nama Anak', child!.name),
                                        _buildInfoRow('Jenis Kelamin', child!.gender),
                                        _buildInfoRow(
                                          'Usia',
                                          child!.ageDescription.isNotEmpty
                                              ? child!.ageDescription
                                              : '-',
                                        ),
                                        if (child!.birthDate != null)
                                          _buildInfoRow(
                                            'Tanggal Lahir',
                                            '${child!.birthDate!.day}/${child!.birthDate!.month}/${child!.birthDate!.year}',
                                          ),
                                        if (child!.weightKg != null)
                                          _buildInfoRow(
                                            'Berat Badan Saat Ini',
                                            '${child!.weightKg} kg',
                                          ),
                                        if (child!.heightCm != null)
                                          _buildInfoRow(
                                            'Tinggi / Panjang Badan',
                                            '${child!.heightCm} cm',
                                          ),
                                        if (child!.birthWeightKg != null)
                                          _buildInfoRow(
                                            'Berat Lahir',
                                            '${child!.birthWeightKg} kg',
                                          ),
                                        if (child!.birthHeightCm != null)
                                          _buildInfoRow(
                                            'Panjang Lahir',
                                            '${child!.birthHeightCm} cm',
                                          ),
                                      ],
                                    )
                                  else
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.info_outline_rounded,
                                            size: 40,
                                            color: Color(0xFF94A3B8),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Belum Ada Data Anak',
                                            style: GoogleFonts.lato(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Pengguna ini belum mendaftarkan data profil anak di aplikasi.',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.lato(
                                              fontSize: 13,
                                              color: const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const Spacer(),
                            const SizedBox(height: 20),

                            // Ilustrasi Landscape Pepohonan konsisten tanpa ruang scroll di bawahnya
                            const IllustrationForestFooter(fit: BoxFit.fitWidth),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildSuperadminNavBar(context),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2B7AE8).withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B7AE8).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF2B7AE8)),
              ),
              const SizedBox(width: 10),
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
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // ===========================================================================
  // BOTTOM NAVIGATION BAR SUPERADMIN
  // Identik dengan beranda_superadmin_page.dart — warna #F2EDED, tinggi 68dp,
  // bulatan putih + ikon biru #72A9F4 untuk item aktif, abu-abu untuk tidak aktif.
  // Tidak ada item yang aktif (halaman detail bukan salah satu dari 4 tab utama).
  // ===========================================================================
  Widget _buildSuperadminNavBar(BuildContext context) {
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
        color: Color(0xFFF2EDED),
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
            // Detail Page tidak termasuk salah satu dari 4 tab utama
            const isSelected = false;
            final item = navItems[i];

            return Expanded(
              child: GestureDetector(
                onTap: () => _onNavTap(context, i),
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

// =============================================================================
// Helper class data item navigasi bottom bar
// =============================================================================
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
