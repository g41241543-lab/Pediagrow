import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../shared/widgets/hover_lift.dart';
import '../../beranda/notifikasi_page.dart';

/// Custom Header terstandarisasi untuk halaman Riwayat Konsultasi dan Detail Konsultasi.
///
/// Spesifikasi Desain:
/// - Tinggi tepat 56dp (tidak termasuk status bar / SafeArea top).
/// - Pada halaman utama [DaftarRiwayatPage]:
///   - Tanpa tombol back (showBackButton: false).
///   - Judul berjarak 16dp dari sisi kiri (Lato Bold 20, #000000).
///   - Tombol notifikasi lonceng (31×31, #FFFFFF, shadow, badge angka merah) di sisi kanan (12dp dari kanan),
///     identik dengan tampilan pada halaman Profil Ibu.
/// - Pada halaman [DetailKonsultasiPage]:
///   - Menampilkan tombol kembali 12dp dari sisi kiri (showBackButton: true).
class RiwayatHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final bool showBackButton;
  final bool showNotification;

  const RiwayatHeader({
    super.key,
    required this.title,
    this.onBackPressed,
    this.showBackButton = false,
    this.showNotification = true,
  });

  void _navigateToNotification(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const NotifikasiPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF0B1014) : Colors.white,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56.0,
          child: Padding(
            padding: EdgeInsets.only(
              left: showBackButton ? 12.0 : 16.0,
              right: 12.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (showBackButton) ...[
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20.0),
                    child: InkWell(
                      onTap: () {
                        if (onBackPressed != null) {
                          onBackPressed!();
                        } else {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(20.0),
                      hoverColor: isDark ? Colors.white12 : const Color(0x12000000),
                      mouseCursor: SystemMouseCursors.click,
                      child: Container(
                        width: 36.0,
                        height: 36.0,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.arrow_back,
                          size: 24.0,
                          color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                ],
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (showNotification)
                  ValueListenableBuilder<int>(
                    valueListenable: NotificationService().unreadCountNotifier,
                    builder: (context, unreadCount, _) {
                      return HoverLift(
                        lift: 2.0,
                        cursor: SystemMouseCursors.click,
                        borderRadius: BorderRadius.circular(16.0),
                        child: GestureDetector(
                          onTap: () => _navigateToNotification(context),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 31,
                                height: 31,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1A2228) : Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x1F000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.notifications_none_rounded,
                                  color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228),
                                  size: 19,
                                ),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE53E3E),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF0B1014) : Colors.white,
                                        width: 1,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      unreadCount > 99 ? '99+' : '$unreadCount',
                                      style: GoogleFonts.lato(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                else
                  const SizedBox(width: 4.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
