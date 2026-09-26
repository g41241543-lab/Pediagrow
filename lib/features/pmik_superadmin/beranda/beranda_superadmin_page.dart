import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/artikel_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../models/artikel_model.dart';
import '../../pengguna/beranda/widgets/full_page_sky_background.dart';
import '../../pengguna/beranda/widgets/header_sky_illustration.dart';
import '../../pengguna/detail/detail_artikel_page.dart';
import 'notifikasi_superadmin_page.dart';
import 'data_anak/data_pasien_page.dart';
import 'kelola_resep_mpasi/daftar_resep_mpasi_admin_page.dart';
import 'kelola_artikel/daftar_artikel_admin_page.dart';
import 'permainan/daftar_soal_permainan_page.dart';
import 'rekapitulasi/rekapitulasi_stunting_page.dart';
import 'grafik_pengguna/grafik_pengguna_page.dart';
import '../konsultasi/konsultasi_superadmin_page.dart';
import '../riwayat_konsultasi/daftar_riwayat_konsultasi_admin_page.dart';
import '../profil/profil_superadmin_page.dart';

/// Halaman Beranda PMIK Superadmin PediaGrow.
///
/// Tampilan identik dengan beranda pengguna (header biru seamless, animasi
/// langit, card menu, card slogan, artikel terbaru, ilustrasi footer, nav bar),
/// namun disesuaikan untuk konteks superadmin:
/// - Sapaan "Hai, Superadmin"
/// - Card superadmin (PeGo + ilustrasi dokter)
/// - 6 menu berbeda (Rekapitulasi, Data Pasien, Daftar Resep MPASI, dll.)
/// - Card slogan PeGo dengan teks sesuai desain superadmin
class BerandaSuperadminPage extends StatefulWidget {
  const BerandaSuperadminPage({super.key});

  @override
  State<BerandaSuperadminPage> createState() => _BerandaSuperadminPageState();
}

class _BerandaSuperadminPageState extends State<BerandaSuperadminPage> {
  List<ArtikelModel> _latestArticles = [];
  bool _isLoadingArticles = true;

  // Indeks nav bar (0 = Beranda aktif)
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
      _latestArticles = sorted.take(8).toList();
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
        _latestArticles = sorted.take(8).toList();
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
                // 1. Area Biru Seamless (Header + Card Superadmin)
                _buildSeamlessBlueArea(context),

                // 2. Konten Putih (Menu, Card Slogan, Artikel)
                _buildWhiteContentSection(context),

                const SizedBox(height: 20),

                // 3. Ilustrasi Footer
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
                        // "Hai, Superadmin" (Lato Bold 24, #FFFFFF)
                        Text(
                          'Hai, Superadmin',
                          style: GoogleFonts.lato(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

              // Jarak dari header ke card superadmin disamakan dengan jarak di beranda pengguna
              // (SizedBox 10 + teks Profil Anak 24 + SizedBox 16 = 50dp),
              // sehingga tinggi total area biru gradasi menjadi 250dp (+ SafeArea.top),
              // identik persis dengan beranda pengguna.
              const SizedBox(height: 50),

              // Card Superadmin (PeGo + Ilustrasi Dokter)
              // Margin horizontal 16.0 identik dengan Card MomDad di beranda pengguna
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildSuperadminCard(context),
              ),

              // Jarak dari bottom card ke batas transisi biru→putih: 24dp (identik dengan beranda pengguna)
              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // CARD SUPERADMIN
  // Dimensi: lebar penuh, height 120, warna #FFFFFF, corner radius 15
  // Kiri: Teks PeGo + tagline; Kanan: Ilustrasi dokter
  // =========================================================================
  Widget _buildSuperadminCard(BuildContext context) {
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
                // "PeGo" (Baloo2 Bold, biru teal)
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
          // 6 Card Menu Superadmin
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

          // Artikel Terbaru (Horizontal Carousel)
          _buildLatestArticlesSection(context),
        ],
      ),
    );
  }

  // =========================================================================
  // 6 CARD MENU SUPERADMIN
  // Warna #ECF6FF, 3 kolom x 2 baris, corner radius 10
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
                onTap: () => _navigateTo(const RekapitulasiStuntingPage()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                title: 'Data\nPasien',
                imageAsset: 'assets/images/data_pasien_logo.png',
                blobColor: const Color(0xFF3CC3A6),
                onTap: () => _navigateTo(const DataPasienPage()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                title: 'Daftar Resep\nMPASI',
                imageAsset: 'assets/images/resep_mpasi_logo.png',
                blobColor: const Color(0xFF10B981),
                onTap: () => _navigateTo(const DaftarResepMpasiAdminPage()),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Baris 2: Daftar Artikel Kesehatan, Grafik Pengguna, Permainan
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildMenuItem(
                title: 'Daftar Artikel\nKesehatan',
                imageAsset: 'assets/images/artikel_kesehatan_logo.png',
                blobColor: const Color(0xFF6366F1),
                onTap: () => _navigateTo(const DaftarArtikelAdminPage()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                title: 'Grafik\nPengguna',
                imageAsset: 'assets/images/grafik_pengguna_logo.png',
                blobColor: const Color(0xFF2563EB),
                onTap: () => _navigateTo(const GrafikPenggunaPage()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                title: 'Permainan\n',
                imageAsset: 'assets/images/permainan_logo.png',
                blobColor: const Color(0xFFF59E0B),
                logoOffsetX: 5,
                onTap: () => _navigateTo(const DaftarSoalPermainanPage()),
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
    required VoidCallback onTap,
    required Color blobColor,
    String? imageAsset,
    IconData? icon,
    Color? iconColor,
    Widget? customIcon,
    double cardInset = 6,
    double imageSize = 40,
    double logoOffsetX = 0,
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
                  color: const Color(0xFFECF6FF),
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
                      // Dekorasi blob tematik
                      _buildTileDecoration(blobColor),

                      // Icon, gambar, atau custom widget
                      Center(
                        child: Transform.translate(
                          offset: Offset(logoOffsetX, 0),
                          child: customIcon ??
                              (imageAsset != null
                                  ? Image.asset(
                                      imageAsset,
                                      height: imageSize,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Icon(
                                        icon ?? Icons.widgets_rounded,
                                        size: imageSize,
                                        color: iconColor ??
                                            const Color(0xFF3985E7),
                                      ),
                                    )
                                  : Icon(
                                      icon ?? Icons.widgets_rounded,
                                      size: imageSize,
                                      color: iconColor ??
                                          const Color(0xFF3985E7),
                                    )),
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
              color: const Color(0xFF000000),
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
  // CARD SLOGAN PeGo SUPERADMIN
  // Identik dimensi dengan card PediaGrow pengguna (height 115, color #ECF6FF)
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
          // Ilustrasi dokter duduk
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
          // Teks PeGo & deskripsi superadmin
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
  // SECTION ARTIKEL TERBARU (Horizontal Carousel)
  // Identik dengan beranda pengguna
  // =========================================================================
  Widget _buildLatestArticlesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Artikel Terbaru',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: () => _navigateTo(const DaftarArtikelAdminPage()),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Selengkapnya',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3985E7),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Color(0xFF3985E7),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        SizedBox(
          height: 205,
          child: _isLoadingArticles
              ? _buildArticleSkeletonList()
              : _latestArticles.isEmpty
              ? _buildEmptyArticleState()
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _latestArticles.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final artikel = _latestArticles[index];
                    return _buildArticleCard(context, artikel);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildArticleCard(BuildContext context, ArtikelModel artikel) {
    final hasImage =
        artikel.displayImage != null && artikel.displayImage!.isNotEmpty;
    final isAsset = artikel.isAssetImage;
    final categoryText = artikel.subKategori.isNotEmpty
        ? artikel.subKategori.first
        : artikel.kategori;

    final wordCount = '${artikel.deskripsi ?? ''} ${artikel.pengertian ?? ''}'
        .trim()
        .split(RegExp(r'\s+'))
        .length;
    final readTimeMinutes = math.max(2, (wordCount / 50).ceil());

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _navigateTo(DetailArtikelPage(artikel: artikel)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 102,
                  child: hasImage
                      ? (isAsset
                            ? Image.asset(
                                artikel.displayImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildFallbackArticleImage(),
                              )
                            : Image.network(
                                artikel.displayImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildFallbackArticleImage(),
                              ))
                      : _buildFallbackArticleImage(),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECF6FF),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    categoryText,
                                    style: GoogleFonts.lato(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2563EB),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 11,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$readTimeMinutes mnt',
                                    style: GoogleFonts.lato(
                                      fontSize: 10.5,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            artikel.judul,
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Text(
                        artikel.tanggal,
                        style: GoogleFonts.lato(
                          fontSize: 10.5,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArticleSkeletonList() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(width: 14),
      itemBuilder: (_, __) => Container(
        width: 220,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              height: 102,
              decoration: const BoxDecoration(
                color: Color(0xFFE2E8F0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 65,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyArticleState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(
          'Belum ada artikel terbaru saat ini',
          style: GoogleFonts.lato(fontSize: 13, color: const Color(0xFF64748B)),
        ),
      ),
    );
  }

  Widget _buildFallbackArticleImage() {
    return Container(
      color: const Color(0xFFEBF5FF),
      alignment: Alignment.center,
      child: const Icon(
        Icons.article_rounded,
        size: 38,
        color: Color(0xFF3985E7),
      ),
    );
  }

  // =========================================================================
  // ILUSTRASI FOOTER (Full-Bleed, identik dengan beranda pengguna)
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
        // Sudah di Beranda
        break;
      case 1:
        _navigateTo(const KonsultasiSuperadminPage());
        break;
      case 2:
        _navigateTo(const DaftarRiwayatKonsultasiAdminPage());
        break;
      case 3:
        _navigateTo(const ProfilSuperadminPage());
        break;
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
