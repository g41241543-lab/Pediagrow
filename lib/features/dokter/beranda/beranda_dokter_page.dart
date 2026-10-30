import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/doctor_service.dart';
import '../../../core/services/local_push_service.dart';
import '../../../core/services/staff_auth_service.dart';
import '../../../core/services/superadmin_notification_service.dart';
import '../../../core/services/theme_service.dart';
import '../../../models/staff_account_model.dart';
import '../../../models/superadmin_notification_model.dart';
import '../../pengguna/artikel/artikel_kesehatan_page.dart';
import '../../pengguna/beranda/widgets/full_page_sky_background.dart';
import '../../pengguna/beranda/widgets/header_sky_illustration.dart';
import '../../pengguna/mpasi/daftar_resep_page.dart';
import '../../pmik_superadmin/beranda/grafik_pengguna/grafik_pengguna_page.dart';
import '../../pmik_superadmin/beranda/notifikasi_superadmin_page.dart';
import 'data_pasien/data_pasien_page.dart';
import '../jadwal/atur_jadwal_dokter_page.dart';
import '../../../shared/widgets/illustration_forest_footer.dart';
import '../../../shared/widgets/pedia_bottom_nav_bar.dart';

/// Halaman Beranda Dokter PediaGrow.
///
/// Memiliki 6 Menu Grid:
/// 1. Rekapitulasi (berisi grafik pengguna dan grafik stunting) -> [GrafikPenggunaPage]
/// 2. Data Pasien -> [DataPasienPage]
/// 3. Jadwal Praktik -> [AturJadwalDokterPage]
/// 4. Resep MPASI (read-only tanpa CRUD) -> [DaftarResepPage]
/// 5. Daftar Artikel Kesehatan (read-only tanpa CRUD) -> [ArtikelKesehatanPage]
/// 6. Permainan (hak akses terkunci sesuai role pmik_superadmin)
///
/// Navigation Bar 4 tab (#F2EDED, tinggi 68dp):
/// Beranda, Konsultasi, Riwayat Konsultasi, Profil.
class BerandaDokterPage extends StatefulWidget {
  const BerandaDokterPage({super.key});

  @override
  State<BerandaDokterPage> createState() => _BerandaDokterPageState();
}

class _BerandaDokterPageState extends State<BerandaDokterPage> {
  void _navigateTo(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _openAturJadwalDokter() {
    final staff = StaffAuthService().currentStaff;
    String? targetDoctorId;
    String? targetDoctorName;

    if (staff != null) {
      targetDoctorName = staff.name;
      final doc = DoctorService().findDoctorForStaff(staff);
      if (doc != null) {
        targetDoctorId = doc.id;
        targetDoctorName = doc.name;
      } else {
        targetDoctorId = staff.id;
      }
    }

    _navigateTo(
      AturJadwalDokterPage(
        dokterId: targetDoctorId,
        doctorName: targetDoctorName,
        isSuperadmin: false,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark(context);
    return Scaffold(
      backgroundColor: isDark ? ThemeService.darkBg : Colors.white,
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // LAYER 0 — Background animasi awan & burung (full-page)
            const Positioned.fill(child: FullPageSkyBackground()),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Area Biru Seamless (Header + Card Dokter PeGo)
                _buildSeamlessBlueArea(context),

                // 2. Konten Putih (6 Menu Grid + Card Slogan PeGo)
                _buildWhiteContentSection(context),

                const SizedBox(height: 20),

                // 3. Ilustrasi Footer (Daun)
                _buildFooterIllustration(),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildFixedNavBar(),
    );
  }

  // =========================================================================
  // 1. AREA BIRU SEAMLESS
  // =========================================================================
  Widget _buildSeamlessBlueArea(BuildContext context) {
    final isNight = HeaderSkyIllustration.checkIsNight(SkyTimeMode.auto);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isNight
              ? HeaderSkyIllustration.nightGradientColors
              : HeaderSkyIllustration.dayGradientColors,
          stops: isNight
              ? HeaderSkyIllustration.nightGradientStops
              : HeaderSkyIllustration.dayGradientStops,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Ilustrasi Langit
          const Positioned.fill(
            child: HeaderSkyIllustration(
              mode: SkyTimeMode.auto,
              renderBackgroundGradient: false,
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Sapaan + Lingkaran Notifikasi
              SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Sapaan Dinamis sesuai Akun Dokter
                        Expanded(
                          child: ValueListenableBuilder<StaffAccount?>(
                            valueListenable:
                                StaffAuthService().currentStaffNotifier,
                            builder: (context, staff, _) {
                              String greeting = 'Hai, dokter';
                              if (staff != null) {
                                final name = staff.name.trim();
                                if (name.isNotEmpty &&
                                    name.toLowerCase() != 'dokter' &&
                                    name.toLowerCase() != 'superadmin') {
                                  final isDr =
                                      name.toLowerCase().startsWith('dr.') ||
                                      name.toLowerCase().startsWith('dr ');
                                  greeting =
                                      'Hai, ${isDr ? name : 'dr. $name'}';
                                }
                              }
                              return Text(
                                greeting,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.lato(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                        const Spacer(),

                        // Lingkaran Notifikasi dengan badge angka
                        ValueListenableBuilder<List<SuperadminNotificationItem>>(
                          valueListenable:
                              SuperadminNotificationService().notificationsNotifier,
                          builder: (context, _, _) {
                            final unreadCount = SuperadminNotificationService()
                                .getUnreadCountForRole(PushRole.dokter);
                            return GestureDetector(
                              onTap: () =>
                                  _navigateTo(const NotifikasiSuperadminPage(role: PushRole.dokter)),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 31,
                                    height: 31,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x1F000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.notifications_none_rounded,
                                      color: Color(0xFF1A2228),
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          unreadCount > 9
                                              ? '9+'
                                              : '$unreadCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            height: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Jarak ke card
              const SizedBox(height: 36),

              // Card Dokter (PeGo + Ilustrasi Dokter)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildDokterCard(context),
              ),

              const SizedBox(height: 38),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // CARD DOKTER
  // Dimensi: lebar penuh, height 120, warna #FFFFFF, corner radius 15
  // Kiri: Teks PeGo + tagline; Kanan: Ilustrasi dokter
  // =========================================================================
  Widget _buildDokterCard(BuildContext context) {
    final isDark = ThemeService.isDark(context);
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: isDark ? ThemeService.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: isDark ? Border.all(color: ThemeService.darkBorder) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Teks kiri: PeGo + tagline
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Pe',
                            style: GoogleFonts.baloo2(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4B83D6),
                            ),
                          ),
                          TextSpan(
                            text: 'Go',
                            style: GoogleFonts.baloo2(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3CC3A6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder<StaffAccount?>(
                      valueListenable: StaffAuthService().currentStaffNotifier,
                      builder: (context, staff, _) {
                        final roleText = (staff?.isDokter == true ||
                                staff?.role == StaffRole.dokter)
                            ? 'Dokter'
                            : (staff?.role.label ?? 'Dokter');
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                                : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
                                  : const Color(0xFFBFDBFE),
                            ),
                          ),
                          child: Text(
                            roleText,
                            style: GoogleFonts.lato(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFF93C5FD)
                                  : const Color(0xFF2563EB),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Melayani Sepenuh Hati,\nMencegah Stunting Sedini Mungkin',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: isDark
                        ? ThemeService.darkTextSecondary
                        : const Color(0xFF2C363D),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          // Ilustrasi dokter (kanan)
          SizedBox(
            width: 90,
            height: 100,
            child: Image.asset(
              'assets/images/dokter_superadmin_card.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.medical_services_rounded,
                size: 60,
                color: Color(0xFF3985E7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. KONTEN PUTIH
  // =========================================================================
  Widget _buildWhiteContentSection(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(top: 24, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 6 Card Menu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _build6MenuGrid(context),
          ),

          const SizedBox(height: 24),

          // Card Slogan PeGo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildPeGoSloganCard(context),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 6 CARD MENU DOKTER
  // 1. Rekapitulasi (Grafik Pengguna & Grafik Stunting)
  // 2. Data Pasien
  // 3. Jadwal Praktik
  // 4. Resep MPASI (Read-only, seperti pada role pengguna)
  // 5. Daftar Artikel Kesehatan (Read-only, seperti pada role pengguna)
  // 6. Permainan (Terkunci dengan gembok seperti role pmik_superadmin)
  // =========================================================================
  Widget _build6MenuGrid(BuildContext context) {
    return Column(
      children: [
        // Baris 1: Rekapitulasi, Data Pasien, Jadwal Praktik (semua aktif)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildMenuItem(
                context: context,
                title: 'Rekapitulasi',
                customIcon: _buildRekapitulasiLogo(),
                blobColor: const Color(0xFFD97706),
                isLocked: false,
                onTap: () =>
                    _navigateTo(const GrafikPenggunaPage(initialTab: 1)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                context: context,
                title: 'Data\nPasien',
                imageAsset: 'assets/images/data_pasien_logo.png',
                blobColor: const Color(0xFF3CC3A6),
                isLocked: false,
                onTap: () => _navigateTo(const DataPasienPage()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                context: context,
                title: 'Jadwal\nPraktik',
                customIcon: _buildJadwalPraktikLogo(),
                blobColor: const Color(0xFF0284C7),
                isLocked: false,
                onTap: _openAturJadwalDokter,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Baris 2: Resep MPASI, Daftar Artikel Kesehatan, Permainan (terkunci)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildMenuItem(
                context: context,
                title: 'Resep\nMPASI',
                imageAsset: 'assets/images/resep_mpasi_logo.png',
                blobColor: const Color(0xFFF97316),
                isLocked: false,
                onTap: () => _navigateTo(const DaftarResepPage()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                context: context,
                title: 'Daftar Artikel\nKesehatan',
                imageAsset: 'assets/images/artikel_kesehatan_logo.png',
                blobColor: const Color(0xFF10B981),
                isLocked: false,
                onTap: () => _navigateTo(const ArtikelKesehatanPage()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                context: context,
                title: 'Permainan\n',
                imageAsset: 'assets/images/permainan_logo.png',
                blobColor: const Color(0xFFF59E0B),
                logoOffsetX: 5,
                isLocked: true,
                onTap: () => _showLockedMenuNotice('Permainan'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showLockedMenuNotice(String featureName) {
    LocalPushService().show(
      title: 'Akses Terbatas',
      body: 'Akses fitur "$featureName" dinonaktifkan untuk role Dokter.',
      targetRole: PushRole.dokter,
    );
  }

  /// Logo Jadwal Praktik: kotak biru dengan ikon kalender
  Widget _buildJadwalPraktikLogo() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF0284C7),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.calendar_month_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  /// Logo Rekapitulasi: binder/catatan kuning berklip
  Widget _buildRekapitulasiLogo() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFF8CF47),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2B025), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Klip binder metalik di pojok kiri atas
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: const Color(0xFF667781),
                borderRadius: BorderRadius.circular(2.5),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 3.5,
                height: 3.5,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          // Garis-garis catatan
          Positioned(
            top: 8,
            left: 17,
            right: 6,
            child: Container(
              height: 2.5,
              decoration: BoxDecoration(
                color: const Color(0xFFB48316).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
          Positioned(
            top: 15,
            left: 8,
            right: 6,
            child: Container(
              height: 2.5,
              decoration: BoxDecoration(
                color: const Color(0xFFB48316).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
          Positioned(
            top: 22,
            left: 8,
            right: 12,
            child: Container(
              height: 2.5,
              decoration: BoxDecoration(
                color: const Color(0xFFB48316).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Isi ikon/gambar untuk satu tile menu (tanpa efek terkunci).
  Widget _buildTileContent({
    required String? imageAsset,
    required IconData? icon,
    required Color? iconColor,
    required Widget? customIcon,
    required double imageSize,
    required Color fallbackColor,
  }) {
    if (customIcon != null) return customIcon;

    if (imageAsset != null) {
      return Image.asset(
        imageAsset,
        height: imageSize,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(
          icon ?? Icons.widgets_rounded,
          size: imageSize,
          color: iconColor ?? fallbackColor,
        ),
      );
    }

    return Icon(
      icon ?? Icons.widgets_rounded,
      size: imageSize,
      color: iconColor ?? fallbackColor,
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
    required Color blobColor,
    String? imageAsset,
    IconData? icon,
    Color? iconColor,
    Widget? customIcon,
    double cardInset = 6,
    double imageSize = 40,
    double logoOffsetX = 0,
    bool isLocked = false,
  }) {
    final isDark = ThemeService.isDark(context);
    final Widget baseContent = _buildTileContent(
      imageAsset: imageAsset,
      icon: icon,
      iconColor: iconColor,
      customIcon: customIcon,
      imageSize: imageSize,
      fallbackColor: isLocked
          ? const Color(0xFF94A3B8)
          : const Color(0xFF3985E7),
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: cardInset),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? (isLocked ? const Color(0xFF141C22) : ThemeService.darkCard)
                      : (isLocked
                          ? const Color(0xFFD1D7DB)
                          : const Color(0xFFECF6FF)),
                  borderRadius: BorderRadius.circular(10),
                  border: isDark
                      ? Border.all(color: ThemeService.darkBorder)
                      : (isLocked
                          ? Border.all(
                              color: const Color(0xFFCBD5E1),
                              width: 1.0,
                            )
                          : null),
                  boxShadow: [
                    BoxShadow(
                      color: isLocked
                          ? const Color(0x0A000000)
                          : const Color(0xFF3985E7).withValues(alpha: isDark ? 0.02 : 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Dekorasi sudut tematik
                      _buildTileDecoration(blobColor, isLocked: isLocked),

                      // Icon / gambar / custom widget (greyscale jika terkunci)
                      Center(
                        child: Transform.translate(
                          offset: Offset(logoOffsetX, 0),
                          child: isLocked
                              ? ColorFiltered(
                                  colorFilter: const ColorFilter.matrix(
                                    <double>[
                                      0.2126, 0.7152, 0.0722, 0, 0, //
                                      0.2126, 0.7152, 0.0722, 0, 0, //
                                      0.2126, 0.7152, 0.0722, 0, 0, //
                                      0, 0, 0, 0.65, 0, //
                                    ],
                                  ),
                                  child: baseContent,
                                )
                              : baseContent,
                        ),
                      ),

                      // Badge gembok jika fitur dinonaktifkan
                      if (isLocked)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(3.5),
                            decoration: const BoxDecoration(
                              color: Color(0xFF64748B),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontWeight: isLocked ? FontWeight.normal : FontWeight.bold,
              color: isDark
                  ? (isLocked
                      ? ThemeService.darkTextMuted
                      : ThemeService.darkTextPrimary)
                  : (isLocked
                      ? const Color(0xFF8696A0)
                      : const Color(0xFF000000)),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTileDecoration(Color blobColor, {bool isLocked = false}) {
    final effectiveColor = isLocked ? const Color(0xFF94A3B8) : blobColor;
    final topAlpha = isLocked ? 0.28 : 0.09;
    final bottomAlpha = isLocked ? 0.22 : 0.06;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: effectiveColor.withValues(alpha: topAlpha),
              ),
            ),
          ),
          Positioned(
            bottom: -10,
            left: -8,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: effectiveColor.withValues(alpha: bottomAlpha),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // CARD SLOGAN PeGo DOKTER
  // Dimensi: height 115, color #ECF6FF, corner radius 10
  // =========================================================================
  Widget _buildPeGoSloganCard(BuildContext context) {
    final isDark = ThemeService.isDark(context);
    return Container(
      width: double.infinity,
      height: 115,
      decoration: BoxDecoration(
        color: isDark ? ThemeService.darkCard : const Color(0xFFECF6FF),
        borderRadius: BorderRadius.circular(10),
        border: isDark ? Border.all(color: ThemeService.darkBorder) : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3985E7).withValues(alpha: isDark ? 0.02 : 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ilustrasi dokter duduk di depan komputer
          SizedBox(
            width: 84,
            height: 94,
            child: Image.asset(
              'assets/images/dokter_komputer_slogan.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.computer_rounded,
                size: 50,
                color: Color(0xFF3985E7),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Teks PeGo & deskripsi dokter
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Pe',
                        style: GoogleFonts.baloo2(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4B83D6),
                        ),
                      ),
                      TextSpan(
                        text: 'Go',
                        style: GoogleFonts.baloo2(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3CC3A6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pego merupakan pendukung aplikasi PediaGrow untuk dokter, PMIK dan admin yang mengelola',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: isDark
                        ? ThemeService.darkTextSecondary
                        : const Color(0xFF2C363D),
                    height: 1.3,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // ILUSTRASI FOOTER (Full-Bleed, daun hijau bawah)
  // =========================================================================
  Widget _buildFooterIllustration() {
    return const IllustrationForestFooter(fit: BoxFit.fitWidth);
  }

  // =========================================================================
  // NAVIGATION BAR — 4 tab: Beranda, Konsultasi, Riwayat Konsultasi, Profil
  // =========================================================================
  Widget _buildFixedNavBar() {
    return const PediaBottomNavBar(selectedIndex: 0);
  }
}
