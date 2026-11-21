import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/artikel_service.dart';
import '../../../core/services/local_push_service.dart';
import '../../../core/services/staff_auth_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/superadmin_notification_service.dart';
import '../../../core/services/theme_service.dart';
import '../../../models/artikel_model.dart';
import '../../../models/staff_account_model.dart';
import '../../../models/superadmin_notification_model.dart';
import '../../../widgets/hak_akses_logo.dart';
import '../../pengguna/beranda/widgets/full_page_sky_background.dart';
import '../../pengguna/beranda/widgets/header_sky_illustration.dart';
import '../../pengguna/detail/detail_artikel_page.dart';
import '../../pmik_superadmin/beranda/grafik_pengguna/grafik_pengguna_page.dart';
import '../../pmik_superadmin/beranda/kelola_artikel/daftar_artikel_admin_page.dart';
import '../../pmik_superadmin/beranda/kelola_resep_mpasi/daftar_resep_mpasi_admin_page.dart';
import '../../pmik_superadmin/beranda/notifikasi_superadmin_page.dart';
import '../../pmik_superadmin/beranda/permainan/permainan_admin_page.dart';
import 'data_anak/data_pasien_page.dart';
import '../../../shared/widgets/illustration_forest_footer.dart';
import '../../../shared/widgets/pedia_bottom_nav_bar.dart';

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
    LocalPushService().show(
      title: 'Akses Terbatas',
      body: 'Akses fitur "$featureName" hanya dapat diakses oleh Superadmin.',
      targetRole: PushRole.pmik,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDark(context);
    return Scaffold(
      backgroundColor: isDark ? ThemeService.darkBg : Colors.white,
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

                  const SizedBox(
                    height: 92,
                  ), // Ruang langit terbuka agar awan horizon bergradasi lembut ke ilustrasi hutan

                  // 3. Ilustrasi Landscape Footer
                  _buildFooterIllustration(),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // =========================================================================
  // 1. AREA BIRU SEAMLESS
  // =========================================================================
  Widget _buildSeamlessBlueArea(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNight = HeaderSkyIllustration.checkIsNight(SkyTimeMode.auto, isDark);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: HeaderSkyIllustration.getGradientColors(
            isNight: isNight,
            isDark: isDark,
          ),
          stops: HeaderSkyIllustration.getGradientStops(
            isNight: isNight,
            isDark: isDark,
          ),
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
                        ValueListenableBuilder<List<SuperadminNotificationItem>>(
                          valueListenable:
                              SuperadminNotificationService().notificationsNotifier,
                          builder: (context, _, _) {
                            final unreadCount = SuperadminNotificationService()
                                .getUnreadCountForRole(PushRole.pmik);
                            return GestureDetector(
                              onTap: () =>
                                  _navigateTo(const NotifikasiSuperadminPage(role: PushRole.pmik)),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
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
                                      size: 22,
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
    final isDark = ThemeService.isDark(context);
    return ValueListenableBuilder<StaffAccount?>(
      valueListenable: StaffAuthService().currentStaffNotifier,
      builder: (context, staff, _) {
        final name = staff?.name.trim() ?? 'PMIK Admin';
        final roleLabel = staff?.pmikRoleDisplay ?? 'PMIK Admin';
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF1D252C),
                      const Color(0xFF171E24),
                    ]
                  : [
                      const Color(0xFFEAF4FF),
                      const Color(0xFFD4EBFE),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2C363D)
                  : const Color(0xFFCCE4FB),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Micro Sparkle (✦) di Sudut Kanan Atas
                Positioned(
                  top: 12,
                  right: 14,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 8.5,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.30)
                        : Colors.white.withValues(alpha: 0.95),
                  ),
                ),
                Padding(
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
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF4B83D6),
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Go',
                                        style: GoogleFonts.baloo2(
                                          fontSize: 22,
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
                                    color: isDark
                                        ? const Color(0xFF1E3A8A)
                                            .withValues(alpha: 0.3)
                                        : Colors.white.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF3B82F6)
                                              .withValues(alpha: 0.5)
                                          : const Color(0xFFBFDBFE),
                                    ),
                                  ),
                                  child: Text(
                                    roleLabel,
                                    style: GoogleFonts.lato(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? const Color(0xFF93C5FD)
                                          : const Color(0xFF2563EB),
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
                                color: isDark
                                    ? ThemeService.darkTextPrimary
                                    : const Color(0xFF0B1014),
                              ),
                            ),
                            Text(
                              'Melayani Sepenuh Hati,\nMencegah Stunting Sedini Mungkin',
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                color: isDark
                                    ? ThemeService.darkTextSecondary
                                    : const Color(0xFF475569),
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
                ),
              ],
            ),
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
                context: context,
                title: 'Rekapitulasi',
                imageAsset: 'assets/images/rekapitulasi_logo.png',
                blobColor: const Color(0xFFD97706),
                isLocked: false,
                onTap: () =>
                    _navigateTo(const GrafikPenggunaPage(initialTab: 0)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                context: context,
                title: 'Data\nAnak',
                imageAsset: 'assets/images/data_anak_logo.png',
                blobColor: const Color(0xFF3CC3A6),
                isLocked: false,
                onTap: () => _navigateTo(const DataPasienPage()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                context: context,
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
                context: context,
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
                context: context,
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
                context: context,
                title: 'Permainan\n',
                imageAsset: 'assets/images/permainan_logo.png',
                blobColor: const Color(0xFFF59E0B),
                logoOffsetX: 0,
                isLocked: false,
                onTap: () => _navigateTo(const PermainanAdminPage()),
              ),
            ),
          ],
        ),
      ],
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
    if (imageAsset != null) {
      return Image.asset(
        imageAsset,
        width: imageSize,
        height: imageSize,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            customIcon ??
            Icon(
              icon ?? Icons.widgets_rounded,
              size: imageSize,
              color: iconColor ?? fallbackColor,
            ),
      );
    }

    if (customIcon != null) return customIcon;

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
    double cardInset = 0,
    double imageSize = 56,
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
          // Card Menu: Flat Modern Squircle (Rata, Elegan, Selaras dengan Card Lainnya)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: cardInset),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: isLocked
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF141C22),
                                  const Color(0xFF0F151A),
                                ]
                              : [
                                  const Color(0xFFE2E8F0),
                                  const Color(0xFFCBD5E1),
                                ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF1D252C),
                                  const Color(0xFF171E24),
                                ]
                              : [
                                  const Color(0xFFEAF4FF),
                                  const Color(0xFFD4EBFE),
                                ],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isLocked
                        ? (isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFF94A3B8))
                        : (isDark
                            ? const Color(0xFF2C363D)
                            : const Color(0xFFCCE4FB)),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                          alpha: isDark ? (isLocked ? 0.08 : 0.18) : (isLocked ? 0.02 : 0.03)),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      if (!isLocked) ...[
                        // Layer 1: Gelembung Lembut di Sudut Kanan Atas (Tampak Jelas & Rapi)
                        Positioned(
                          top: -14,
                          right: -14,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.035)
                                  : Colors.white.withValues(alpha: 0.45),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.white.withValues(alpha: 0.65),
                                width: 1.0,
                              ),
                            ),
                          ),
                        ),

                        // Layer 2: Gelembung Lembut di Sudut Kiri Bawah (Tampak Jelas & Rapi)
                        Positioned(
                          bottom: -16,
                          left: -14,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.025)
                                  : Colors.white.withValues(alpha: 0.35),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.white.withValues(alpha: 0.55),
                                width: 1.0,
                              ),
                            ),
                          ),
                        ),

                        // Layer 3: Micro Sparkles (✦) Bintang Kontras & Berkilau Jelas
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Icon(
                            Icons.auto_awesome,
                            size: 8.5,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.30)
                                : Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Icon(
                            Icons.auto_awesome,
                            size: 6.5,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],

                      // Layer 6: Icon / Logo
                      Center(
                        child: Transform.translate(
                          offset: Offset(logoOffsetX, 0),
                          child: isLocked
                              ? ColorFiltered(
                                  colorFilter: const ColorFilter.matrix(
                                    <double>[
                                      0.2126, 0.7152, 0.0722, 0, 0,
                                      0.2126, 0.7152, 0.0722, 0, 0,
                                      0.2126, 0.7152, 0.0722, 0, 0,
                                      0, 0, 0, 0.65, 0,
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
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
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
              fontWeight: FontWeight.normal,
              color: isDark
                  ? (isLocked
                      ? ThemeService.darkTextMuted
                      : ThemeService.darkTextPrimary)
                  : (isLocked
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF000000)),
              height: 1.25,
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
    final isDark = ThemeService.isDark(context);
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
                  color: isDark
                      ? ThemeService.darkTextPrimary
                      : const Color(0xFF0F172A),
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
              style: GoogleFonts.lato(
                color: isDark
                    ? ThemeService.darkTextSecondary
                    : const Color(0xFF94A3B8),
              ),
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
                      color: isDark ? ThemeService.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: isDark
                          ? Border.all(color: ThemeService.darkBorder)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
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
                              color: isDark
                                  ? const Color(0xFF2C363D)
                                  : const Color(0xFFF1F5F9),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.article_rounded,
                                size: 36,
                                color: isDark
                                    ? ThemeService.darkTextSecondary
                                    : const Color(0xFF94A3B8),
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
                              color: isDark
                                  ? ThemeService.darkTextPrimary
                                  : const Color(0xFF0F172A),
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
    return const IllustrationForestFooter(
      fit: BoxFit.fitWidth,
      withClouds: false,
    );
  }

  // =========================================================================
  // NAVIGATION BAR — 4 tab: Beranda, Konsultasi, Riwayat Konsultasi, Profil
  // =========================================================================
  Widget _buildBottomNavigationBar() {
    return const PediaBottomNavBar(selectedIndex: 0);
  }
}
