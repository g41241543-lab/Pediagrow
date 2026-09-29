import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/services/staff_auth_service.dart';
import '../../../models/staff_account_model.dart';
import '../../pengguna/beranda/widgets/full_page_sky_background.dart';
import '../../pengguna/beranda/widgets/header_sky_illustration.dart';
import '../../pmik_superadmin/beranda/data_anak/data_pasien_page.dart';
import '../../pmik_superadmin/beranda/grafik_pengguna/grafik_pengguna_page.dart';
import '../../pmik_superadmin/beranda/notifikasi_superadmin_page.dart';
import '../../pmik_superadmin/beranda/rekapitulasi/rekapitulasi_stunting_page.dart';
import '../../pmik_superadmin/konsultasi/konsultasi_superadmin_page.dart';
import '../../pmik_superadmin/riwayat_konsultasi/daftar_riwayat_konsultasi_admin_page.dart';
import '../profil_dokter_page.dart';

/// Halaman Beranda Dokter PediaGrow.
///
/// Tampilan disesuaikan persis dengan beranda superadmin dan desain referensi dokter:
/// - Sapaan "Hai, dokter" / "Hai, dr. [Nama]"
/// - Card PeGo + Ilustrasi dokter
/// - 6 Menu Grid (Ukuran, bentuk, penataan sama dengan superadmin):
///   * Rekapitulasi (Aktif)
///   * Data Pasien (Aktif)
///   * Daftar Resep MPASI (Abu-abu, dinonaktifkan / bukan ranah dokter)
///   * Daftar Artikel Kesehatan (Abu-abu, dinonaktifkan / bukan ranah dokter)
///   * Grafik Pengguna (Aktif)
///   * Permainan (Abu-abu, dinonaktifkan / bukan ranah dokter)
/// - Card Slogan PeGo dengan ilustrasi dokter duduk di depan komputer
/// - Ilustrasi landscape footer (daun hijau)
/// - Navigation Bar 4 tab (#F2EDED)
class BerandaDokterPage extends StatefulWidget {
  const BerandaDokterPage({super.key});

  @override
  State<BerandaDokterPage> createState() => _BerandaDokterPageState();
}

class _BerandaDokterPageState extends State<BerandaDokterPage> {
  // Indeks nav bar (0 = Beranda aktif)
  final int _selectedIndex = 0;

  void _navigateTo(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                                  final isDr = name
                                          .toLowerCase()
                                          .startsWith('dr.') ||
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
                        ValueListenableBuilder<int>(
                          valueListenable:
                              NotificationService().unreadCountNotifier,
                          builder: (context, unreadCount, _) {
                            return GestureDetector(
                              onTap: () =>
                                  _navigateTo(const NotifikasiSuperadminPage()),
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
                                      color: Color(0xFF1E293B),
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
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
                const SizedBox(height: 4),
                Text(
                  'Melayani Sepenuh Hati,\nMencegah Stunting Sedini Mungkin',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF334155),
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
            child: _buildPeGoSloganCard(),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 6 CARD MENU DOKTER
  // Tata letak, ukuran, bentuk persis sama dengan Superadmin:
  // 3 kolom x 2 baris, corner radius 10.
  // Menu non-ranah dokter: Resep MPASI, Artikel Kesehatan, Permainan
  // berwarna abu-abu (#CBD5E1) dan tidak dapat diklik.
  // =========================================================================
  Widget _build6MenuGrid(BuildContext context) {
    return Column(
      children: [
        // Baris 1: Rekapitulasi (Aktif), Data Pasien (Aktif), Daftar Resep MPASI (Abu-abu / Disabled)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildMenuItem(
                title: 'Rekapitulasi',
                customIcon: _buildRekapitulasiLogo(),
                blobColor: const Color(0xFFD97706),
                isDisabled: false,
                onTap: () => _navigateTo(const RekapitulasiStuntingPage()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                title: 'Data\nPasien',
                imageAsset: 'assets/images/data_pasien_logo.png',
                blobColor: const Color(0xFF3CC3A6),
                isDisabled: false,
                onTap: () => _navigateTo(const DataPasienPage()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                title: 'Daftar Resep\nMPASI',
                imageAsset: 'assets/images/resep_mpasi_logo.png',
                blobColor: Colors.transparent,
                isDisabled: true,
                onTap: null, // Dokter tidak dapat mengklik
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Baris 2: Daftar Artikel Kesehatan (Abu-abu / Disabled), Grafik Pengguna (Aktif), Permainan (Abu-abu / Disabled)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildMenuItem(
                title: 'Daftar Artikel\nKesehatan',
                imageAsset: 'assets/images/artikel_kesehatan_logo.png',
                blobColor: Colors.transparent,
                isDisabled: true,
                applyGreyscale: true,
                onTap: null, // Dokter tidak dapat mengklik
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                title: 'Grafik\nPengguna',
                imageAsset: 'assets/images/grafik_pengguna_logo.png',
                blobColor: const Color(0xFF2563EB),
                isDisabled: false,
                onTap: () => _navigateTo(const GrafikPenggunaPage()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                title: 'Permainan\n',
                imageAsset: 'assets/images/permainan_logo.png',
                blobColor: Colors.transparent,
                logoOffsetX: 5,
                isDisabled: true,
                applyGreyscale: true,
                onTap: null, // Dokter tidak dapat mengklik
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Logo Rekapitulasi: binder/catatan kuning berklip persis sesuai desain referensi
  Widget _buildRekapitulasiLogo() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFF8CF47),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE2B025),
          width: 1.2,
        ),
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
                color: const Color(0xFF64748B),
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

  Widget _buildMenuItem({
    required String title,
    required VoidCallback? onTap,
    required Color blobColor,
    String? imageAsset,
    IconData? icon,
    Color? iconColor,
    Widget? customIcon,
    double cardInset = 6,
    double imageSize = 40,
    double logoOffsetX = 0,
    bool isDisabled = false,
    bool applyGreyscale = false,
  }) {
    Widget iconWidget = customIcon ??
        (imageAsset != null
            ? Image.asset(
                imageAsset,
                height: imageSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  icon ?? Icons.widgets_rounded,
                  size: imageSize,
                  color: iconColor ?? const Color(0xFF3985E7),
                ),
              )
            : Icon(
                icon ?? Icons.widgets_rounded,
                size: imageSize,
                color: iconColor ?? const Color(0xFF3985E7),
              ));

    // Jika dinonaktifkan dengan efek greyscale
    if (isDisabled && applyGreyscale) {
      iconWidget = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: iconWidget,
      );
    }

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
                  // Abu-abu seperti gambar jika bukan ranah dokter (#CBD5E1), atau biru muda (#ECF6FF) jika aktif
                  color: isDisabled
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFFECF6FF),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: isDisabled
                          ? Colors.black.withValues(alpha: 0.04)
                          : const Color(0xFF3985E7).withValues(alpha: 0.06),
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
                      // Dekorasi blob tematik (hanya jika aktif)
                      if (!isDisabled) _buildTileDecoration(blobColor),

                      // Icon, gambar, atau custom widget
                      Center(
                        child: Transform.translate(
                          offset: Offset(logoOffsetX, 0),
                          child: iconWidget,
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
              fontSize: 14,
              fontWeight: isDisabled ? FontWeight.normal : FontWeight.bold,
              color: isDisabled
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF000000),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTileDecoration(Color blobColor) {
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
                color: blobColor.withValues(alpha: 0.09),
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
                color: blobColor.withValues(alpha: 0.06),
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
  // Teks deskripsi disesuaikan dengan referensi desain
  // =========================================================================
  Widget _buildPeGoSloganCard() {
    return Container(
      width: double.infinity,
      height: 115,
      decoration: BoxDecoration(
        color: const Color(0xFFECF6FF),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3985E7).withValues(alpha: 0.07),
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
                    color: const Color(0xFF334155),
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
    return SizedBox(
      width: double.infinity,
      child: Image.asset(
        'assets/images/beranda_landscape_footer_fiks.png',
        width: double.infinity,
        fit: BoxFit.fitWidth,
        alignment: Alignment.bottomCenter,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 80,
          color: const Color(0xFFD1FAE5),
          alignment: Alignment.center,
          child: const Icon(
            Icons.park_outlined,
            size: 44,
            color: Color(0xFF34D399),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // NAVIGATION BAR — 4 tab: Beranda, Konsultasi, Riwayat Konsultasi, Profil
  // Warna #F2EDED, tinggi 68dp (Persis Superadmin)
  // =========================================================================
  Widget _buildFixedNavBar() {
    final navItems = [
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
            final isSelected = i == _selectedIndex;
            final item = navItems[i];

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

  void _onNavTap(int index) {
    if (index == _selectedIndex) return;
    switch (index) {
      case 0:
        // Beranda aktif
        break;
      case 1:
        _navigateTo(const KonsultasiSuperadminPage());
        break;
      case 2:
        _navigateTo(const DaftarRiwayatKonsultasiAdminPage());
        break;
      case 3:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfilDokterPage()),
        );
        break;
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
