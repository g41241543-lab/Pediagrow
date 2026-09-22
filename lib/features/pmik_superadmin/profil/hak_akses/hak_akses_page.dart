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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: _buildHeader(context),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          children: [
            // 1. Menu Hak Akses: Dokter
            _buildAccessTile(
              context: context,
              icon: Icons.medical_information_outlined,
              title: 'Dokter',
              onTap: () => _navigateToDokter(context),
            ),

            // Garis pembatas tipis
            const Divider(
              height: 1.0,
              thickness: 1.0,
              color: Color(0xFFF1F5F9),
              indent: 16.0,
              endIndent: 16.0,
            ),

            // 2. Menu Hak Akses: PMIK
            _buildAccessTile(
              context: context,
              icon: Icons.badge_outlined,
              title: 'PMIK',
              onTap: () => _navigateToPmik(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
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
                    'Hak Akses',
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

  Widget _buildAccessTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Row(
          children: [
            // Ikon outline di sisi kiri
            Icon(
              icon,
              size: 28.0,
              color: const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 16.0),

            // Label menu
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),

            // Indikator panah ke kanan dengan background lingkaran lembut
            Container(
              width: 30.0,
              height: 30.0,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 0.8,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.chevron_right,
                size: 20.0,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
