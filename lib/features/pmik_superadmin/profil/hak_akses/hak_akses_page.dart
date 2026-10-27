import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'daftar_dokter_akses_page.dart';
import 'daftar_pmik_akses_page.dart';

/// Halaman Hak Akses Superadmin.
///
/// Berfungsi untuk memilih dan mengatur hak akses akun:
/// 1. Dokter -> DaftarDokterAksesPage
/// 2. PMIK   -> DaftarPmikAksesPage
///
/// Memiliki header kustom 56dp dengan tombol back dan judul "Hak Akses".
class HakAksesPage extends StatelessWidget {
  final VoidCallback? onBackPressed;

  const HakAksesPage({
    super.key,
    this.onBackPressed,
  });

  void _handleBack(BuildContext context) {
    if (onBackPressed != null) {
      onBackPressed!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _navigateToDokter(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const DaftarDokterAksesPage(),
      ),
    );
  }

  void _navigateToPmik(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const DaftarPmikAksesPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0B1014) : Colors.white;
    final dividerColor = isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: _buildHeader(context, isDark),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          children: [
            // 1. Menu Hak Akses: Dokter
            _buildAccessTile(
              context: context,
              isDark: isDark,
              icon: Icons.medical_services_rounded,
              iconColor: const Color(0xFF0284C7),
              iconBgColor: isDark
                  ? const Color(0xFF0284C7).withValues(alpha: 0.2)
                  : const Color(0xFFE0F2FE),
              title: 'Dokter',
              onTap: () => _navigateToDokter(context),
            ),

            // Garis pembatas tipis
            Divider(
              height: 1.0,
              thickness: 1.0,
              color: dividerColor,
              indent: 16.0,
              endIndent: 16.0,
            ),

            // 2. Menu Hak Akses: PMIK
            _buildAccessTile(
              context: context,
              isDark: isDark,
              icon: Icons.badge_rounded,
              iconColor: const Color(0xFF38C1A2),
              iconBgColor: isDark
                  ? const Color(0xFF38C1A2).withValues(alpha: 0.2)
                  : const Color(0xFFE6F9F5),
              title: 'PMIK',
              onTap: () => _navigateToPmik(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final headerBg = isDark ? const Color(0xFF0B1014) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000);

    return Container(
      width: double.infinity,
      color: headerBg,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56.0,
          child: Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _handleBack(context),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 36.0,
                    height: 36.0,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.arrow_back,
                      size: 24.0,
                      color: textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    'Hak Akses',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
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

  Widget _buildAccessTile({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required VoidCallback onTap,
  }) {
    final titleColor = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014);
    final chevronBg = isDark ? const Color(0xFF1A2228) : const Color(0xFFE9EDEF);
    final chevronBorder = isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF);
    final chevronIconColor = isDark ? const Color(0xFF8696A0) : const Color(0xFF667781);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Row(
          children: [
            // Ikon berwarna dengan kontainer rounded di sisi kiri
            Container(
              width: 44.0,
              height: 44.0,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12.0),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 24.0,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 16.0),

            // Label menu
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
            ),

            // Indikator panah ke kanan dengan background lingkaran lembut
            Container(
              width: 30.0,
              height: 30.0,
              decoration: BoxDecoration(
                color: chevronBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: chevronBorder,
                  width: 0.8,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.chevron_right,
                size: 20.0,
                color: chevronIconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
