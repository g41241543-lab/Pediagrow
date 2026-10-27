import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/staff_auth_service.dart';
import '../../models/staff_account_model.dart';
import '../../features/dokter/beranda/beranda_dokter_page.dart';
import '../../features/dokter/konsultasi/konsultasi_dokter_page.dart';
import '../../features/dokter/profil_dokter_page.dart';
import '../../features/pengguna/beranda/beranda_page.dart';
import '../../features/pengguna/konsultasi/daftar_dokter_page.dart';
import '../../features/pengguna/profil/menu_profil_page.dart';
import '../../features/pengguna/riwayat_konsultasi/daftar_riwayat_page.dart';
import '../../features/pmik_admin/beranda/beranda_pmik_page.dart';
import '../../features/pmik_admin/konsultasi/konsultasi_pmik_admin_page.dart';
import '../../features/pmik_admin/profil_pmik_page.dart';
import '../../features/pmik_superadmin/superadmin_shell.dart';
import '../../features/pmik_superadmin/riwayat_konsultasi/daftar_riwayat_konsultasi_admin_page.dart';

/// Navigation Bar terpusat dan reusable untuk aplikasi PediaGrow.
///
/// Menyediakan 4 menu navigasi konsisten:
/// - Index 0: Beranda (Icons.home_rounded)
/// - Index 1: Konsultasi (Icons.question_answer_rounded)
/// - Index 2: Riwayat Konsultasi (Icons.manage_search_rounded)
/// - Index 3: Profil (Icons.person_rounded)
///
/// Mempertahankan warna background #F2EDED, tinggi 68dp, serta efek lingkaran putih
/// timbul dengan ikon biru #72A9F4 untuk menu yang sedang aktif.
/// Jika `selectedIndex` bernilai `-1`, maka animasi lingkaran aktif dihilangkan.
class PediaBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onNavTap;

  const PediaBottomNavBar({
    super.key,
    required this.selectedIndex,
    this.onNavTap,
  });

  void _defaultNavigate(BuildContext context, int index) {
    if (index == selectedIndex) return;

    if (onNavTap != null) {
      onNavTap!(index);
      return;
    }

    final staff = StaffAuthService().currentStaff;
    Widget targetPage;
    bool removeUntil = false;

    if (staff != null) {
      if (staff.role == StaffRole.dokter) {
        switch (index) {
          case 0:
            targetPage = const BerandaDokterPage();
            removeUntil = true;
            break;
          case 1:
            targetPage = const KonsultasiDokterPage();
            break;
          case 2:
            targetPage = const DaftarRiwayatKonsultasiAdminPage();
            break;
          case 3:
            targetPage = const ProfilDokterPage();
            break;
          default:
            return;
        }
      } else if (staff.role == StaffRole.admin) {
        switch (index) {
          case 0:
            targetPage = const BerandaPmikPage();
            removeUntil = true;
            break;
          case 1:
            targetPage = const KonsultasiPmikAdminPage();
            break;
          case 2:
            targetPage = const DaftarRiwayatKonsultasiAdminPage();
            break;
          case 3:
            targetPage = const ProfilPmikPage();
            break;
          default:
            return;
        }
      } else if (staff.role == StaffRole.superadmin) {
        // Superadmin: semua tab diarahkan kembali ke SuperadminShell dengan
        // initialIndex yang sesuai — shell mengelola state tab.
        targetPage = SuperadminShell(initialIndex: index);
        removeUntil = true;
      } else {
        switch (index) {
          case 0:
            targetPage = const BerandaPage();
            removeUntil = true;
            break;
          case 1:
            targetPage = const DaftarDokterPage();
            break;
          case 2:
            targetPage = const DaftarRiwayatPage();
            break;
          case 3:
            targetPage = const MenuProfilPage();
            break;
          default:
            return;
        }
      }
    } else {
      switch (index) {
        case 0:
          targetPage = const BerandaPage();
          removeUntil = true;
          break;
        case 1:
          targetPage = const DaftarDokterPage();
          break;
        case 2:
          targetPage = const DaftarRiwayatPage();
          break;
        case 3:
          targetPage = const MenuProfilPage();
          break;
        default:
          return;
      }
    }

    if (removeUntil) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => targetPage,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => targetPage,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const navItems = [
      _NavData(icon: Icons.home_rounded, label: 'Beranda'),
      _NavData(icon: Icons.question_answer_rounded, label: 'Konsultasi'),
      _NavData(icon: Icons.manage_search_rounded, label: 'Riwayat Konsultasi'),
      _NavData(icon: Icons.person_rounded, label: 'Profil'),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? const Color(0xFF1A2228) : const Color(0xFFF2EDED);
    final activeCircleBg = isDark ? const Color(0xFF2C363D) : Colors.white;
    final activeLabelColor = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228);
    final inactiveColor = isDark ? const Color(0xFF667781) : const Color(0xFF9E9E9E);

    return Container(
      width: double.infinity,
      height: 68,
      decoration: BoxDecoration(
        color: navBg,
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 8,
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
            final isSelected = i == selectedIndex;
            final item = navItems[i];

            return Expanded(
              child: GestureDetector(
                onTap: () => _defaultNavigate(context, i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: 68,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        // State aktif: lingkaran dengan icon biru #72A9F4
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: activeCircleBg,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            item.icon,
                            size: 22,
                            color: const Color(0xFF72A9F4),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                fontSize: 11,
                                fontWeight: FontWeight.normal,
                                color: activeLabelColor,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // State tidak aktif: icon & label abu-abu
                        Icon(
                          item.icon,
                          size: 24,
                          color: inactiveColor,
                        ),
                        const SizedBox(height: 3),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lato(
                                fontSize: 11,
                                fontWeight: FontWeight.normal,
                                color: inactiveColor,
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

class _NavData {
  final IconData icon;
  final String label;

  const _NavData({required this.icon, required this.label});
}
