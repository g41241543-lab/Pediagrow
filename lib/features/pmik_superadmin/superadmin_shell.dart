import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/local_push_service.dart';
import '../../core/services/staff_auth_service.dart';
import 'beranda/beranda_superadmin_page.dart';
import 'konsultasi/konsultasi_superadmin_page.dart';
import 'riwayat_konsultasi/daftar_riwayat_konsultasi_admin_page.dart';
import 'profil/profil_superadmin_page.dart';
import '../../shared/widgets/pedia_bottom_nav_bar.dart';

/// Shell permanen untuk role Superadmin PediaGrow.
///
/// Arsitektur:
/// - Navbar dan SafeArea bawah ditangani oleh shell ini (SATU tempat).
/// - Body berisi [IndexedStack] yang mempertahankan state tiap tab tanpa rebuild.
/// - Tidak ada transisi cross-fade antar tab — pergantian dilakukan secara instan.
/// - Ilustrasi/background tiap halaman tetap statis (tidak ikut transisi).
///
/// Setiap halaman tab dikirimkan parameter [inShell: true] agar tidak merender
/// bottomNavigationBar sendiri — sehingga tidak ada navbar ganda.
class SuperadminShell extends StatefulWidget {
  /// Tab awal saat shell pertama kali dibuka (default 0 = Beranda).
  final int initialIndex;

  const SuperadminShell({super.key, this.initialIndex = 0});

  @override
  State<SuperadminShell> createState() => _SuperadminShellState();
}

class _SuperadminShellState extends State<SuperadminShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }



  // ── Permission check ────────────────────────────────────────────────────────

  bool _canAccess(String permissionKey) {
    final staff = StaffAuthService().currentStaff;
    if (staff == null) return true;
    return staff.hasPermission(permissionKey);
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;

    // Permission guard: Konsultasi & Profil
    if (index == 1 && !_canAccess('konsultasi')) {
      LocalPushService().show(
        title: 'Akses Terbatas',
        body: 'Akses fitur "Konsultasi" dinonaktifkan oleh Superadmin.',
        targetRole: PushRole.superadmin,
      );
      return;
    }
    if (index == 3 && !_canAccess('profil')) {
      LocalPushService().show(
        title: 'Akses Terbatas',
        body: 'Akses fitur "Profil" dinonaktifkan oleh Superadmin.',
        targetRole: PushRole.superadmin,
      );
      return;
    }

    setState(() => _currentIndex = index);
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack mempertahankan state tiap tab — tidak ada rebuild
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          BerandaSuperadminPage(inShell: true),
          KonsultasiSuperadminPage(inShell: true),
          DaftarRiwayatKonsultasiAdminPage(inShell: true),
          ProfilSuperadminPage(inShell: true),
        ],
      ),
      bottomNavigationBar: PediaBottomNavBar(
        selectedIndex: _currentIndex,
        onNavTap: _onNavTap,
      ),
    );
  }
}
