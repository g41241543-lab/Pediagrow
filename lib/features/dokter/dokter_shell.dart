import 'package:flutter/material.dart';

import 'beranda/beranda_dokter_page.dart';
import 'konsultasi/konsultasi_dokter_page.dart';
import 'profil_dokter_page.dart';
import '../pmik_superadmin/riwayat_konsultasi/daftar_riwayat_konsultasi_admin_page.dart';
import '../../shared/widgets/pedia_bottom_nav_bar.dart';

/// Shell permanen untuk role Dokter PediaGrow.
///
/// Arsitektur:
/// - Navbar dan SafeArea bawah ditangani oleh shell ini secara terpusat (SATU tempat).
/// - Body berisi [IndexedStack] yang mempertahankan state tiap tab tanpa rebuild.
/// - Tidak ada transisi cross-fade antar tab — pergantian dilakukan secara instan (0 ms).
/// - Ilustrasi/background tiap halaman tetap terisolasi dan tidak tembus ke halaman lain.
///
/// Setiap halaman tab dikirimkan parameter [inShell: true] agar tidak merender
/// bottomNavigationBar sendiri — sehingga navbar tidak berkedip dan tidak ada navbar ganda.
class DokterShell extends StatefulWidget {
  /// Tab awal saat shell pertama kali dibuka (default 0 = Beranda).
  final int initialIndex;

  const DokterShell({super.key, this.initialIndex = 0});

  @override
  State<DokterShell> createState() => _DokterShellState();
}

class _DokterShellState extends State<DokterShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1014) : Colors.white,
      // IndexedStack mempertahankan state tiap tab — tidak ada rebuild, instan 0 ms
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          BerandaDokterPage(inShell: true),
          KonsultasiDokterPage(inShell: true),
          DaftarRiwayatKonsultasiAdminPage(inShell: true),
          ProfilDokterPage(inShell: true),
        ],
      ),
      bottomNavigationBar: PediaBottomNavBar(
        selectedIndex: _currentIndex,
        onNavTap: _onNavTap,
      ),
    );
  }
}
