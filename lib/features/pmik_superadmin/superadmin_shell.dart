import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/local_push_service.dart';
import '../../core/services/staff_auth_service.dart';
import '../../models/staff_account_model.dart';
import 'beranda/beranda_superadmin_page.dart';
import 'konsultasi/konsultasi_superadmin_page.dart';
import 'riwayat_konsultasi/daftar_riwayat_konsultasi_admin_page.dart';
import 'profil/profil_superadmin_page.dart';

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

  // ── Tab definitions ─────────────────────────────────────────────────────────

  static const _navItems = [
    _NavItem(icon: Icons.home_rounded, label: 'Beranda'),
    _NavItem(icon: Icons.question_answer_rounded, label: 'Konsultasi'),
    _NavItem(icon: Icons.manage_search_rounded, label: 'Riwayat Konsultasi'),
    _NavItem(icon: Icons.person_rounded, label: 'Profil'),
  ];

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
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
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
          children: List.generate(_navItems.length, (i) {
            final isSelected = i == _currentIndex;
            final item = _navItems[i];

            return Expanded(
              child: GestureDetector(
                onTap: () => _onNavTap(i),
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
                                color: const Color(0xFF1A2228),
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
