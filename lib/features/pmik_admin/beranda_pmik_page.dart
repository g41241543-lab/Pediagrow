import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/artikel_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/staff_auth_service.dart';
import '../../core/services/storage_service.dart';
import '../../models/artikel_model.dart';
import '../../models/staff_account_model.dart';
import '../pengguna/beranda/widgets/full_page_sky_background.dart';
import '../pengguna/beranda/widgets/header_sky_illustration.dart';
import '../pengguna/detail/detail_artikel_page.dart';
import '../pmik_superadmin/beranda/rekapitulasi/rekapitulasi_stunting_page.dart';
import '../pmik_superadmin/beranda/kelola_artikel/daftar_artikel_admin_page.dart';
import '../pmik_superadmin/beranda/kelola_resep_mpasi/daftar_resep_mpasi_admin_page.dart';
import '../pmik_superadmin/beranda/permainan/permainan_admin_page.dart';
import '../pmik_superadmin/profil/hak_akses/hak_akses_page.dart';
import '../pmik_superadmin/riwayat_konsultasi/daftar_riwayat_konsultasi_admin_page.dart';
import '../../widgets/hak_akses_logo.dart';
import 'beranda/data_anak/data_pasien_page.dart';
import 'konsultasi/konsultasi_pmik_admin_page.dart';
import 'profil_pmik_page.dart';

/// Halaman Beranda PMIK Admin PediaGrow.
///
/// Tampilan disesuaikan untuk konteks PMIK Admin:
/// - Sapaan "Hai, [Nama]"
/// - Menu sesuai hak akses PMIK
/// - Artikel terbaru
class BerandaPmikPage extends StatefulWidget {
  const BerandaPmikPage({super.key});

  @override
  State<BerandaPmikPage> createState() => _BerandaPmikPageState();
}

class _BerandaPmikPageState extends State<BerandaPmikPage> {
  List<ArtikelModel> _latestArticles = [];
  bool _isLoadingArticles = true;
  final int _selectedIndex = 0;

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

  bool _canAccessFeature(String permissionKey) {
    final staff = StaffAuthService().currentStaff;
    if (staff == null) return true;
    return staff.hasPermission(permissionKey);
  }

  void _handleMenuTap({
    required String permissionKey,
    required String featureName,
    required VoidCallback onAllowed,
  }) {
    if (_canAccessFeature(permissionKey)) {
      onAllowed();
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Akses fitur "$featureName" dinonaktifkan oleh Superadmin.',
                  style: GoogleFonts.lato(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
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
            const Positioned.fill(child: FullPageSkyBackground()),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSeamlessBlueArea(context),
                _buildWhiteContentSection(context),
                const SizedBox(height: 20),
                _buildFooterIllustration(),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildFixedNavBar(),
    );
  }

  // ─── BLUE AREA ────────────────────────────────────────────────────────────
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
              SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ValueListenableBuilder<StaffAccount?>(
                            valueListenable:
                                StaffAuthService().currentStaffNotifier,
                            builder: (context, staff, _) {
                              final name = staff?.name.trim() ?? 'PMIK';
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
                              onTap: () {},
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
        final name = staff?.name.trim() ?? 'PMIK';
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

  // ─── WHITE CONTENT ────────────────────────────────────────────────────────
  Widget _buildWhiteContentSection(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _build6MenuGrid(context),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Artikel Terbaru',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0B1014),
                  ),
                ),
                const SizedBox(height: 12),
                _buildArticleList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 6 CARD MENU PMIK ADMIN
  // =========================================================================
  Widget _build6MenuGrid(BuildContext context) {
    return ValueListenableBuilder<StaffAccount?>(
      valueListenable: StaffAuthService().currentStaffNotifier,
      builder: (context, staff, _) {
        final canRekap = _canAccessFeature('rekapitulasi');
        final canPasien = _canAccessFeature('data_pasien');
        final canResep = _canAccessFeature('daftar_resep_mpasi');
        final canArtikel = _canAccessFeature('daftar_artikel_kesehatan');
        final canHakAkses = _canAccessFeature('hak_akses');
        final canPermainan = _canAccessFeature('permainan');

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
                    isLocked: !canRekap,
                    onTap: () => _handleMenuTap(
                      permissionKey: 'rekapitulasi',
                      featureName: 'Rekapitulasi',
                      onAllowed: () =>
                          _navigateTo(const RekapitulasiStuntingPage()),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMenuItem(
                    title: 'Data\nPasien',
                    imageAsset: 'assets/images/data_pasien_logo.png',
                    blobColor: const Color(0xFF3CC3A6),
                    isLocked: !canPasien,
                    onTap: () => _handleMenuTap(
                      permissionKey: 'data_pasien',
                      featureName: 'Data Pasien',
                      onAllowed: () => _navigateTo(const DataPasienPage()),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMenuItem(
                    title: 'Daftar Resep\nMPASI',
                    imageAsset: 'assets/images/resep_mpasi_logo.png',
                    blobColor: const Color(0xFF10B981),
                    isLocked: !canResep,
                    onTap: () => _handleMenuTap(
                      permissionKey: 'daftar_resep_mpasi',
                      featureName: 'Daftar Resep MPASI',
                      onAllowed: () =>
                          _navigateTo(const DaftarResepMpasiAdminPage()),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Baris 2: Daftar Artikel Kesehatan, Kelola Hak Akses, Permainan
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildMenuItem(
                    title: 'Daftar Artikel\nKesehatan',
                    imageAsset: 'assets/images/artikel_kesehatan_logo.png',
                    blobColor: const Color(0xFF6366F1),
                    isLocked: !canArtikel,
                    onTap: () => _handleMenuTap(
                      permissionKey: 'daftar_artikel_kesehatan',
                      featureName: 'Daftar Artikel Kesehatan',
                      onAllowed: () =>
                          _navigateTo(const DaftarArtikelAdminPage()),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMenuItem(
                    title: 'Kelola\nHak Akses',
                    customIcon: HakAksesLogo(isDisabled: !canHakAkses),
                    blobColor: const Color(0xFF0284C7),
                    isLocked: !canHakAkses,
                    onTap: () => _handleMenuTap(
                      permissionKey: 'hak_akses',
                      featureName: 'Kelola Hak Akses',
                      onAllowed: () => _navigateTo(const HakAksesPage()),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMenuItem(
                    title: 'Permainan\n',
                    imageAsset: 'assets/images/permainan_logo.png',
                    blobColor: const Color(0xFFF59E0B),
                    logoOffsetX: 5,
                    isLocked: !canPermainan,
                    onTap: () => _handleMenuTap(
                      permissionKey: 'permainan',
                      featureName: 'Permainan',
                      onAllowed: () => _navigateTo(const PermainanAdminPage()),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
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
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFFECF6FF),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3985E7).withValues(alpha: 0.06),
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
                      Opacity(
                        opacity: isLocked ? 0.35 : 1.0,
                        child: _buildTileDecoration(blobColor),
                      ),
                      Center(
                        child: Opacity(
                          opacity: isLocked ? 0.45 : 1.0,
                          child: Transform.translate(
                            offset: Offset(logoOffsetX, 0),
                            child:
                                customIcon ??
                                (imageAsset != null
                                    ? Image.asset(
                                        imageAsset,
                                        height: imageSize,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, _, _) => Icon(
                                          icon ?? Icons.widgets_rounded,
                                          size: imageSize,
                                          color:
                                              iconColor ??
                                              const Color(0xFF3985E7),
                                        ),
                                      )
                                    : Icon(
                                        icon ?? Icons.widgets_rounded,
                                        size: imageSize,
                                        color:
                                            iconColor ??
                                            const Color(0xFF3985E7),
                                      )),
                          ),
                        ),
                      ),
                      if (isLocked)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(3.5),
                            decoration: const BoxDecoration(
                              color: Color(0xFF667781),
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
                  ? const Color(0xFF8696A0)
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

  Widget _buildArticleList() {
    if (_isLoadingArticles) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3985E7)),
      );
    }
    if (_latestArticles.isEmpty) {
      return Center(
        child: Text(
          'Belum ada artikel.',
          style: GoogleFonts.lato(color: const Color(0xFF8696A0)),
        ),
      );
    }
    return Column(
      children: _latestArticles
          .map((artikel) => _buildArticleCard(artikel))
          .toList(),
    );
  }

  Widget _buildArticleCard(ArtikelModel artikel) {
    return GestureDetector(
      onTap: () => _navigateTo(DetailArtikelPage(artikel: artikel)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE9EDEF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: StorageService.buildImageWidget(
                artikel.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorWidget: _buildArticleImagePlaceholder(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artikel.judul,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0B1014),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artikel.kategori,
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: const Color(0xFF3985E7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFD1D7DB),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleImagePlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.article_rounded,
        color: Color(0xFF3985E7),
        size: 28,
      ),
    );
  }

  Widget _buildFooterIllustration() {
    return SizedBox(
      height: 80,
      child: Center(
        child: Text(
          '© PediaGrow — Bersama Cegah Stunting',
          style: GoogleFonts.lato(fontSize: 12, color: const Color(0xFF8696A0)),
        ),
      ),
    );
  }

  // ─── BOTTOM NAV ───────────────────────────────────────────────────────────
  Widget _buildFixedNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE9EDEF), width: 1.0)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8.0,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Beranda'),
              _buildNavItem(1, Icons.chat_bubble_outline_rounded, 'Konsultasi'),
              _buildNavItem(
                2,
                Icons.receipt_long_rounded,
                'Riwayat\nKonsultasi',
              ),
              _buildNavItem(3, Icons.person_rounded, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = index == _selectedIndex;
    return GestureDetector(
      onTap: () {
        if (index == _selectedIndex) return;
        if (index == 1) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const KonsultasiPmikAdminPage()),
          );
        } else if (index == 2) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const DaftarRiwayatKonsultasiAdminPage(),
            ),
          );
        } else if (index == 3) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ProfilPmikPage()),
          );
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? const Color(0xFF3985E7)
                  : const Color(0xFF8696A0),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.lato(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF3985E7)
                    : const Color(0xFF8696A0),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
