import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/artikel_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/staff_auth_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/theme_service.dart';
import '../../../models/artikel_model.dart';
import '../../../models/staff_account_model.dart';
import '../../../widgets/hak_akses_logo.dart';
import '../../pengguna/beranda/widgets/full_page_sky_background.dart';
import '../../pengguna/beranda/widgets/header_sky_illustration.dart';
import '../../pengguna/detail/detail_artikel_page.dart';
import '../../pmik_superadmin/beranda/grafik_pengguna/grafik_pengguna_page.dart';
import '../../pmik_superadmin/beranda/kelola_artikel/daftar_artikel_admin_page.dart';
import '../../pmik_superadmin/beranda/kelola_resep_mpasi/daftar_resep_mpasi_admin_page.dart';
import '../../pmik_superadmin/beranda/notifikasi_superadmin_page.dart';
import '../../pmik_superadmin/beranda/permainan/permainan_admin_page.dart';
import '../../pmik_superadmin/riwayat_konsultasi/daftar_riwayat_konsultasi_admin_page.dart';
import 'data_anak/data_pasien_page.dart';
import '../konsultasi/konsultasi_pmik_admin_page.dart';
import '../profil_pmik_page.dart';

/// Halaman Beranda PMIK Admin PediaGrow.
///
/// Memiliki 6 menu:
/// 1. Rekapitulasi (Grafik Pengguna & Stunting)
/// 2. Data Pasien
/// 3. Daftar Resep MPASI
/// 4. Daftar Artikel Kesehatan
/// 5. Hak Akses (Terkunci)
/// 6. Permainan
class BerandaPmikPage extends StatefulWidget {
  const BerandaPmikPage({super.key});

  @override
  State<BerandaPmikPage> createState() => _BerandaPmikPageState();
}

class _BerandaPmikPageState extends State<BerandaPmikPage> {
  List<ArtikelModel> _latestArticles = [];
  bool _isLoadingArticles = true;
  final int _selectedIndex = 0; // Beranda aktif

  @override
  void initState() {
    super.initState();
    _loadLatestArticles();
    ArtikelService().articlesNotifier.addListener(_onArticlesUpdated);
  }

  @override
  void dispose() {
    ArtikelService().articlesNotifier.removeListener(_onArticlesUpdated);
    super.dispose();
  }

  void _onArticlesUpdated() {
    if (!mounted) return;
    final all = ArtikelService().currentArticles;
    final sorted = List<ArtikelModel>.from(all);
    sorted.sort((a, b) => (b.id ?? '').compareTo(a.id ?? ''));
    setState(() {
      _latestArticles = sorted.take(6).toList();
      _isLoadingArticles = false;
    });
  }

  Future<void> _loadLatestArticles() async {
    setState(() => _isLoadingArticles = true);
    try {
      final all = await ArtikelService().getAllArticles();
      final sorted = List<ArtikelModel>.from(all);
      sorted.sort((a, b) => (b.id ?? '').compareTo(a.id ?? ''));
      if (!mounted) return;
      setState(() {
        _latestArticles = sorted.take(6).toList();
        _isLoadingArticles = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _latestArticles = [];
        _isLoadingArticles = false;
      });
    }
  }

  void _navigateTo(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _showLockedMenuNotice(String featureName) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Akses fitur "$featureName" hanya dapat diakses oleh Superadmin.',
                style: GoogleFonts.lato(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeService.lightTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        body: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(overscroll: false),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Background animasi langit
                const Positioned.fill(child: FullPageSkyBackground()),

                // Konten Utama
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Area Biru Seamless
                    _buildSeamlessBlueArea(context),

                    // 2. Konten Putih
                    _buildWhiteContentSection(context),

                    const SizedBox(height: 20),

                    // 3. Ilustrasi Landscape Footer
                    _buildFooterIllustration(),
                  ],
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
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
              // Header: Sapaan PMIK + Notifikasi
              SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ValueListenableBuilder<StaffAccount?>(
                            valueListenable:
                                StaffAuthService().currentStaffNotifier,
                            builder: (context, staff, _) {
                              final rawName = staff?.name.trim() ?? '';
                              final name = rawName.isNotEmpty
                                  ? rawName
                                  : 'Admin PMIK';
                              return Text(
                                'Hai, $name',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.lato(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
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
              const SizedBox(height: 28),

              // Card PMIK
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildPmikCard(context),
              ),
              const SizedBox(height: 38),
            ],
          ),
        ],
      ),
    );
  }

  // ─── PMIK CARD ────────────────────────────────────────────────────────────
  Widget _buildPmikCard(BuildContext context) {
    return ValueListenableBuilder<StaffAccount?>(
      valueListenable: StaffAuthService().currentStaffNotifier,
      builder: (context, staff, _) {
        final name = staff?.name.trim() ?? 'PMIK Admin';
        final roleLabel = staff?.pmikRoleDisplay ?? 'PMIK Admin';
        return Container(
          width: double.infinity,
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text(
                            roleLabel,
                            style: GoogleFonts.lato(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0B1014),
                      ),
                    ),
                    Text(
                      'Melayani Sepenuh Hati,\nMencegah Stunting Sedini Mungkin',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: const Color(0xFF667781),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.local_hospital_rounded,
                size: 60,
                color: Color(0xFF0891B2),
              ),
            ],
          ),
        );
      },
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

          const SizedBox(height: 24),

          // Artikel Terbaru
          _buildLatestArticlesSection(context),
        ],
      ),
    );
  }

  // =========================================================================
  // 6 CARD MENU PMIK ADMIN
  // 1. Rekapitulasi
  // 2. Data Pasien
  // 3. Daftar Resep MPASI
  // 4. Daftar Artikel Kesehatan
  // 5. Kelola Hak Akses (Terkunci)
  // 6. Permainan
  // =========================================================================
  Widget _build6MenuGrid(BuildContext context) {
    return Column(
      children: [
        // Baris 1: Rekapitulasi, Data Pasien, Daftar Resep MPASI
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildMenuItem(
                title: 'Rekapitulasi',
                customIcon: _buildRekapitulasiLogo(),
                blobColor: const Color(0xFFD97706),
                isLocked: false,
                onTap: () =>
                    _navigateTo(const GrafikPenggunaPage(initialTab: 0)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
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
                title: 'Daftar Resep\nMPASI',
                imageAsset: 'assets/images/resep_mpasi_logo.png',
                blobColor: const Color(0xFF10B981),
                isLocked: false,
                onTap: () => _navigateTo(const DaftarResepMpasiAdminPage()),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Baris 2: Daftar Artikel Kesehatan, Kelola Hak Akses (Terkunci), Permainan
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildMenuItem(
                title: 'Daftar Artikel\nKesehatan',
                imageAsset: 'assets/images/artikel_kesehatan_logo.png',
                blobColor: const Color(0xFF6366F1),
                isLocked: false,
                onTap: () => _navigateTo(const DaftarArtikelAdminPage()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                title: 'Kelola\nHak Akses',
                customIcon: const HakAksesLogo(isDisabled: true),
                blobColor: const Color(0xFF0284C7),
                isLocked: true,
                onTap: () => _showLockedMenuNotice('Kelola Hak Akses'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                title: 'Permainan\n',
                imageAsset: 'assets/images/permainan_logo.png',
                blobColor: const Color(0xFFF59E0B),
                logoOffsetX: 5,
                isLocked: false,
                onTap: () => _navigateTo(const PermainanAdminPage()),
              ),
            ),
          ],
        ),
      ],
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
          // Klip binder metalik
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
                  color: isLocked
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFFECF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: isLocked
                      ? Border.all(color: const Color(0xFFCBD5E1), width: 1.0)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: isLocked
                          ? const Color(0x0A000000)
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
                      // Dekorasi sudut tematik
                      _buildTileDecoration(blobColor, isLocked: isLocked),

                      // Icon / Logo
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

                      // Badge Gembok jika fitur terkunci
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
              fontSize: 14,
              fontWeight: isLocked ? FontWeight.normal : FontWeight.bold,
              color: isLocked
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF000000),
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
  // CARD SLOGAN PeGo PMIK
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
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                'Pe',
                style: GoogleFonts.baloo2(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4B83D6),
                ),
              ),
              Text(
                'Go',
                style: GoogleFonts.baloo2(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3CC3A6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Layanan Rekam Medis Terpadu & Pemantauan Tumbuh Kembang Anak',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lato(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2B7AE8),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // ARTIKEL TERBARU
  // =========================================================================
  Widget _buildLatestArticlesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Artikel Terbaru',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              GestureDetector(
                onTap: () => _navigateTo(const DaftarArtikelAdminPage()),
                child: Text(
                  'Lihat Semua',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3985E7),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingArticles)
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF3985E7)),
            ),
          )
        else if (_latestArticles.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Text(
              'Belum ada artikel terbaru.',
              style: GoogleFonts.lato(color: const Color(0xFF94A3B8)),
            ),
          )
        else
          SizedBox(
            height: 180,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _latestArticles.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final artikel = _latestArticles[index];
                return GestureDetector(
                  onTap: () => _navigateTo(DetailArtikelPage(artikel: artikel)),
                  child: Container(
                    width: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: StorageService.buildImageWidget(
                            artikel.displayImage ?? artikel.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorWidget: Container(
                              color: const Color(0xFFF1F5F9),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.article_rounded,
                                size: 36,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            artikel.judul,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // =========================================================================
  // 3. ILUSTRASI FOOTER
  // =========================================================================
  Widget _buildFooterIllustration() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      child: Image.asset(
        'assets/images/beranda_landscape_footer_fiks.png',
        width: double.infinity,
        fit: BoxFit.fitWidth,
        alignment: Alignment.bottomCenter,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 100,
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
  // Warna #F2EDED, tinggi 68dp
  // =========================================================================
  Widget _buildBottomNavigationBar() {
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

  void _replaceWithFade(Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 200),
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
        _replaceWithFade(const KonsultasiPmikAdminPage());
        break;
      case 2:
        _replaceWithFade(const DaftarRiwayatKonsultasiAdminPage());
        break;
      case 3:
        _replaceWithFade(const ProfilPmikPage());
        break;
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
