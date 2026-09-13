import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/pengguna/beranda/beranda_page.dart';
import '../../features/pengguna/konsultasi/daftar_dokter_page.dart';
import '../../features/pengguna/profil/menu_profil_page.dart';
import '../../features/pengguna/riwayat_konsultasi/daftar_riwayat_page.dart';

/// Navigation Bar terpusat dan reusable untuk aplikasi PediaGrow.
///
/// Menyediakan 4 menu navigasi konsisten:
/// - Index 0: Beranda (Icons.home_rounded)
/// - Index 1: Konsultasi (Icons.question_answer_rounded)
/// - Index 2: Riwayat Konsultasi (Icons.manage_search_rounded)
/// - Index 3: Profil Ibu (Icons.person_outline_rounded)
///
/// Mempertahankan warna background #F2EDED, tinggi 68dp, serta efek lingkaran putih
/// timbul dengan ikon biru #72A9F4 untuk menu yang sedang aktif.
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

    Widget targetPage;
    bool removeUntil = false;

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
      _NavData(icon: Icons.person_outline_rounded, label: 'Profil Ibu'),
    ];

    return Container(
      width: double.infinity,
      height: 68,
      decoration: const BoxDecoration(
        color: Color(0xFFF2EDED),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(navItems.length, (i) {
          final isSelected = i == selectedIndex;
          final item = navItems[i];

          return GestureDetector(
            onTap: () => _defaultNavigate(context, i),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 80,
              height: 68,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    // State aktif: lingkaran putih dengan icon biru #72A9F4
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
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
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // State tidak aktif: icon & label abu-abu #9E9E9E
                    Icon(
                      item.icon,
                      size: 24,
                      color: const Color(0xFF9E9E9E),
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
                            color: const Color(0xFF9E9E9E),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavData {
  final IconData icon;
  final String label;

  const _NavData({required this.icon, required this.label});
}
