import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/child_service.dart';
import '../../../models/child_model.dart';
import 'notifikasi_page.dart';
import '../../../core/services/notification_service.dart';
import '../profil_anak/tambah_anak_page.dart';
import '../cek_stunting/pilih_anak_page.dart';
import '../grafik_pertumbuhan/pilih_anak_grafik_page.dart';
import '../mpasi/daftar_resep_page.dart';
import '../artikel/artikel_kesehatan_page.dart';
import '../fasyankes/lokasi_fasyankes_page.dart';
import '../game_edukasi/game_mulai_page.dart';
import '../konsultasi/daftar_dokter_page.dart';
import '../riwayat_konsultasi/daftar_riwayat_page.dart';
import '../profil/menu_profil_page.dart';
import '../profil/profil_ibu_page.dart';
import '../../../core/services/artikel_service.dart';
import '../../../models/artikel_model.dart';
import '../detail/detail_artikel_page.dart';
import '../../../core/services/youtube_service.dart';
import '../../../models/youtube_video_model.dart';
import 'widgets/youtube_player_sheet.dart';
import '../../../shared/widgets/pedia_banner.dart';

/// Halaman Beranda Pengguna PediaGrow.
///
/// Ditampilkan setelah login berhasil untuk pengguna yang BELUM memiliki profil anak.
/// Halaman scrollable secara penuh dengan Navigation Bar tetap (fixed di Scaffold).
class BerandaPage extends StatefulWidget {
  final bool showAddSuccessSnackbar;
  final bool showLengkapiProfilBanner;

  const BerandaPage({
    super.key,
    this.showAddSuccessSnackbar = false,
    this.showLengkapiProfilBanner = false,
  });

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage>
    with SingleTickerProviderStateMixin {
  int _selectedNavIndex = 0;

  late AnimationController _ellipseController;
  late Animation<double> _ellipsePulse;
  late Animation<double> _cloudDrift;
  late Animation<double> _cloudFloat;
  late Animation<double> _sunPulse;
  late Animation<double> _sunRotate;

  List<ArtikelModel> _latestArticles = [];
  bool _isLoadingArticles = true;

  List<YoutubeVideoModel> _educationalVideos = [];
  bool _isLoadingVideos = true;

  // Banner Notifikasi Lengkapi Profil Ibu
  bool _isLengkapiProfilBannerVisible = false;
  Timer? _lengkapiProfilTimer;

  @override
  void initState() {
    super.initState();

    if (widget.showLengkapiProfilBanner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerLengkapiProfilBanner();
      });
    }

    if (widget.showAddSuccessSnackbar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PediaBanner.showSuccess(
          context,
          message: 'Profil anak berhasil ditambahkan',
        );
      });
    }

    _ellipseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _ellipsePulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _ellipseController, curve: Curves.easeInOut),
    );

    _cloudDrift = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _ellipseController, curve: Curves.easeInOut),
    );
    _cloudFloat = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _ellipseController, curve: Curves.easeInOutSine),
    );

    _sunPulse = Tween<double>(begin: 0.93, end: 1.07).animate(
      CurvedAnimation(parent: _ellipseController, curve: Curves.easeInOutSine),
    );
    _sunRotate = Tween<double>(begin: -0.06, end: 0.06).animate(
      CurvedAnimation(parent: _ellipseController, curve: Curves.easeInOut),
    );

    _loadLatestArticles();
    _loadEducationalVideos();
    ArtikelService().articlesNotifier.addListener(_onArticlesUpdated);
  }

  @override
  void dispose() {
    _lengkapiProfilTimer?.cancel();
    ArtikelService().articlesNotifier.removeListener(_onArticlesUpdated);
    _ellipseController.dispose();
    super.dispose();
  }

  void _triggerLengkapiProfilBanner() {
    _lengkapiProfilTimer?.cancel();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        _isLengkapiProfilBannerVisible = true;
      });

      // Otomatis disembunyikan setelah 1 menit jika tidak diinteraksi
      _lengkapiProfilTimer = Timer(const Duration(minutes: 1), () {
        _hideLengkapiProfilBanner();
      });
    });
  }

  void _hideLengkapiProfilBanner() {
    _lengkapiProfilTimer?.cancel();
    if (mounted && _isLengkapiProfilBannerVisible) {
      setState(() {
        _isLengkapiProfilBannerVisible = false;
      });
    }
  }

  void _onArticlesUpdated() {
    if (!mounted) return;
    final all = ArtikelService().currentArticles;
    final sorted = List<ArtikelModel>.from(all);
    sorted.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
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
      sorted.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
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

  Future<void> _loadEducationalVideos() async {
    setState(() => _isLoadingVideos = true);
    try {
      final videos = await YoutubeService().getEducationalVideos();
      if (!mounted) return;
      setState(() {
        _educationalVideos = videos;
        _isLoadingVideos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _educationalVideos = YoutubeVideoModel.curatedFallbackVideos;
        _isLoadingVideos = false;
      });
    }
  }

  void _navigateTo(Widget page) {
    if (page is PilihAnakPage) {
      PilihAnakPage.show(context, children: page.children);
      return;
    }
    if (page is PilihAnakGrafikPage) {
      PilihAnakGrafikPage.show(context, children: page.children);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _onNavTap(int index) {
    if (index == _selectedNavIndex) return;
    switch (index) {
      case 0:
        setState(() => _selectedNavIndex = 0);
        break;
      case 1:
        _navigateTo(const DaftarDokterPage());
        break;
      case 2:
        _navigateTo(const DaftarRiwayatPage());
        break;
      case 3:
        _navigateTo(const MenuProfilPage());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -------------------------------------------------------------
                // 1. AREA BIRU SEAMLESS (Header + "Profil Anak" + Card MomDad)
                //    Satu container gradient menerus dari paling atas layar
                // -------------------------------------------------------------
                _buildSeamlessBlueArea(context),

                // -------------------------------------------------------------
                // 2. KONTEN PUTIH (6 Card Menu & Card PediaGrow)
                // -------------------------------------------------------------
                _buildWhiteContentSection(context),

                const SizedBox(height: 20), // jarak kecil sebelum ilustrasi footer
                // -------------------------------------------------------------
                // 3. ILUSTRASI PENUTUP FOOTER (Full-Bleed, Menempel ke Nav Bar)
                // -------------------------------------------------------------
                _buildFooterIllustration(),
              ],
            ),
          ),

          // -----------------------------------------------------------------
          // 4. FLOATING NOTIFIKASI POP-UP LENGKAPI PROFIL IBU
          // -----------------------------------------------------------------
          _buildLengkapiProfilBanner(),
        ],
      ),
      // Navigation Bar tetap di posisi Scaffold
      bottomNavigationBar: _buildFixedNavBar(),
    );
  }

  // -------------------------------------------------------------------------
  // NOTIFIKASI POP-UP "Silahkan lengkapi profil ibu"
  // Bentuk dan penempatan persis seperti notif berhasil ubah kata sandi,
  // dengan tombol '>' di sebelah kanan yang mengarah ke Profil Ibu saat dipencet.
  // -------------------------------------------------------------------------
  Widget _buildLengkapiProfilBanner() {
    final topPadding = MediaQuery.of(context).padding.top;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      top: _isLengkapiProfilBannerVisible ? (topPadding + 62.0) : -80.0,
      left: 16.0,
      right: 16.0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isLengkapiProfilBannerVisible ? 1.0 : 0.0,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF3985E7),
            borderRadius: BorderRadius.circular(17),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3985E7).withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _hideLengkapiProfilBanner();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProfilIbuPage(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(17),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Silahkan lengkapi profil ibu',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFFFFF),
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        size: 26,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===================================================================
  // 1. AREA BIRU SEAMLESS
  // Gradient menerus dari atas layar (termasuk Safe Area).
  // Total tinggi sekitar 270-290dp.
  // ===================================================================
  Widget _buildSeamlessBlueArea(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5BA4F5), // Biru lebih terang di kiri-atas
            Color(0xFF4592F0),
            Color(0xFF2872E5), // Biru lebih pekat di kanan-bawah
          ],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // -----------------------------------------------------------
          // DIRECT NON-POSITIONED CHILD PERTAMA: Column konten utama
          // Memberi constraint ukuran alami tanpa loose constraint issue
          // -----------------------------------------------------------
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Safe area top + Header (56dp)
              SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // "Hai, Susanti" (Lato Bold 24, #FFFFFF)
                        Text(
                          'Hai, Susanti',
                          style: GoogleFonts.lato(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        // Lingkaran Notifikasi (31×31, #FFFFFF, 12dp dari kanan) + badge angka
                        ValueListenableBuilder<int>(
                          valueListenable:
                              NotificationService().unreadCountNotifier,
                          builder: (context, unreadCount, _) {
                            return GestureDetector(
                              onTap: () => _navigateTo(const NotifikasiPage()),
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
                                  // Badge angka notifikasi belum dibaca
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

              const SizedBox(height: 10),

              // Tulisan "Profil Anak" (Lato Regular 20, #FFFFFF)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  'Profil Anak',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    color: Colors.white,
                  ),
                ),
              ),

              // Jarak margin-top dari teks "Profil Anak" ke card: 16dp
              const SizedBox(height: 16),

              // Card MomDad atau Kartu Biodata Anak Real-Time
              ValueListenableBuilder<List<ChildModel>>(
                valueListenable: ChildService().childrenNotifier,
                builder: (context, children, _) {
                  if (children.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildMomDadCard(context),
                    );
                  }
                  return _buildChildrenHorizontalList(context, children);
                },
              ),

              // Jarak ±20-30dp dari bottom card MomDad ke batas transisi biru→putih
              const SizedBox(height: 24),
            ],
          ),

          // -----------------------------------------------------------
          // DEKORASI: 2 Elips Blur di Kiri Atas
          // -----------------------------------------------------------
          AnimatedBuilder(
            animation: _ellipsePulse,
            builder: (context, child) {
              final scale = _ellipsePulse.value;
              return Positioned(
                top: -45 * scale,
                left: -45 * scale,
                child: IgnorePointer(
                  child: _BlurredEllipse(
                    width: 175 * scale,
                    height: 175 * scale,
                    color: Colors.white.withValues(alpha: 0.05),
                    blurSigma: 22,
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _ellipsePulse,
            builder: (context, child) {
              final scale = _ellipsePulse.value;
              return Positioned(
                top: -15 * scale,
                left: -15 * scale,
                child: IgnorePointer(
                  child: _BlurredEllipse(
                    width: 115 * scale,
                    height: 115 * scale,
                    color: Colors.white.withValues(alpha: 0.10),
                    blurSigma: 14,
                  ),
                ),
              );
            },
          ),

          // -----------------------------------------------------------
          // DEKORASI MATAHARI DENGAN ANIMASI LEMBUT (Decorative Sun)
          // -----------------------------------------------------------
          AnimatedBuilder(
            animation: _ellipseController,
            builder: (context, child) {
              return Positioned(
                top: 8 + (_cloudFloat.value * 0.7),
                right: 48 + (_cloudDrift.value * 0.4),
                child: IgnorePointer(
                  child: _DecorativeSun(
                    pulseValue: _sunPulse.value,
                    rotateValue: _sunRotate.value,
                  ),
                ),
              );
            },
          ),

          // -----------------------------------------------------------
          // DEKORASI AWAN BERGERAK / MENGAPUNG LEMBUT (Cloud Animations)
          // -----------------------------------------------------------
          // Awan 1 di Kanan Atas (di samping/belakang ikon notifikasi & matahari)
          AnimatedBuilder(
            animation: _ellipseController,
            builder: (context, child) {
              return Positioned(
                top: 26 + _cloudFloat.value,
                right: -10 + _cloudDrift.value,
                child: IgnorePointer(
                  child: _PuffyCloud(
                    width: 95,
                    height: 44,
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
              );
            },
          ),
          // Awan 2 di Tengah Kiri (di bawah sapaan "Hai, Susanti")
          AnimatedBuilder(
            animation: _ellipseController,
            builder: (context, child) {
              return Positioned(
                top: 65 - _cloudFloat.value,
                left: 125 - (_cloudDrift.value * 0.75),
                child: IgnorePointer(
                  child: _PuffyCloud(
                    width: 72,
                    height: 32,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
              );
            },
          ),
          // Awan 3 di Kiri Bawah (mengapung di belakang header Profil Anak)
          AnimatedBuilder(
            animation: _ellipseController,
            builder: (context, child) {
              return Positioned(
                top: 105 + (_cloudFloat.value * 0.5),
                left: -12 + (_cloudDrift.value * 0.6),
                child: IgnorePointer(
                  child: _PuffyCloud(
                    width: 80,
                    height: 36,
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
              );
            },
          ),
          // Awan 4 di Kanan Bawah (mengapung lembut di belakang kartu)
          AnimatedBuilder(
            animation: _ellipseController,
            builder: (context, child) {
              return Positioned(
                bottom: 8 + (_cloudFloat.value * 0.6),
                right: 25 + (_cloudDrift.value * 0.5),
                child: IgnorePointer(
                  child: _PuffyCloud(
                    width: 88,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // CARD MOMDAD (Belum Punya Profil Anak)
  // Dimensi: lebar penuh sejajar margin 12dp x height 120, warna #FFFFFF, corner radius 15
  // ===================================================================
  Widget _buildMomDadCard(BuildContext context) {
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ilustrasi Bayi Tidur di Atas Awan
          SizedBox(
            width: 72,
            height: 72,
            child: Image.asset(
              'assets/images/baby_cloud_illustration.jpg',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.child_friendly_rounded,
                size: 54,
                color: Color(0xFF3985E7),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Teks Informasi & Tombol Tambah Anak
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Mom Dad belum punya profil anak" (Lato Regular 15, #7F7F7F)
                Text(
                  'Mom and Dad belum punya profil anak',
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF7F7F7F),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Tombol "+ Tambah Anak" (width 232 x height 35, radius 10, #3985E7)
                GestureDetector(
                  onTap: () => _navigateTo(const TambahAnakPage()),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 232),
                    height: 35,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3985E7),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3985E7)
                              .withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '+ Tambah Anak',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // KARTU BIODATA ANAK (Real-Time saat sudah ada profil anak)
  // Horizontal Scrollable Cards sesuai desain:
  // - Margin kanan kiri list: 16 dp
  // - Jika perempuan: Banner & avatar berwarna soft pink/peach (#FDE8E4 / #FFDFD9)
  // - Jika laki-laki: Banner & avatar berwarna soft sky blue (#DDF0FF / #CFE8FF)
  // - Jumlah kartu sesuai jumlah profil anak pengguna
  // - Card terakhir adalah card "Tambah Profil Anak"
  // ===================================================================
  Widget _buildChildrenHorizontalList(
    BuildContext context,
    List<ChildModel> children,
  ) {
    final activeChild = ChildService().activeChild ?? children.first;

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: children.length + 1, // semua anak + 1 card tambah anak
        separatorBuilder: (_, __) => const SizedBox(width: 14.0),
        itemBuilder: (context, index) {
          if (index < children.length) {
            final child = children[index];
            final isActive = child.id == activeChild.id;
            return _buildChildCard(context, child, isActive);
          } else {
            return _buildAddChildCard(context);
          }
        },
      ),
    );
  }

  /// Kartu profil per anak (Pink untuk Perempuan, Biru untuk Laki-laki)
  Widget _buildChildCard(
    BuildContext context,
    ChildModel child,
    bool isActive,
  ) {
    final hasPhoto =
        child.photoUrl != null &&
        child.photoUrl!.isNotEmpty &&
        File(child.photoUrl!).existsSync();
    final isMale = child.gender.toLowerCase().contains('laki');

    // Warna Banner & Avatar berdasarkan Jenis Kelamin
    final bannerColor = isMale
        ? const Color(0xFFDDF0FF)
        : const Color(0xFFFDE8E4);
    final avatarBgColor = isMale
        ? const Color(0xFFCFE8FF)
        : const Color(0xFFFFDFD9);

    return Container(
      width: 200,
      height: 128,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isActive
            ? Border.all(
                color: isMale
                    ? const Color(0xFF60A5FA)
                    : const Color(0xFFF472B6),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ChildService().setActiveChild(child);
            },
            child: Stack(
              children: [
                // 1. Top Colored Banner (Pink/Peach untuk Perempuan, Sky Blue untuk Laki-laki)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      color: bannerColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                    ),
                  ),
                ),

                // 2. Avatar Anak (Posisi kiri atas, overlapping banner & white card)
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: avatarBgColor,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: hasPhoto
                          ? Image.file(File(child.photoUrl!), fit: BoxFit.cover)
                          : Image.asset(
                              'assets/images/default_baby_avatar.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const CustomPaint(
                                painter: _BabyFacePainter(
                                  outlineColor: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),

                // 3. Nama Anak, Usia, dan Tombol Panah Kanan
                Positioned(
                  left: 14,
                  right: 12,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nama Anak
                      Text(
                        child.name,
                        style: GoogleFonts.lato(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // Baris Usia & Tombol Chevron Kanan
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              _formatChildAge(child),
                              style: GoogleFonts.lato(
                                fontSize: 12.5,
                                fontWeight: FontWeight.normal,
                                color: const Color(0xFF334155),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFCBD5E1),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Card untuk menambahkan profil anak baru di akhir list
  Widget _buildAddChildCard(BuildContext context) {
    return Container(
      width: 160,
      height: 128,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateTo(const TambahAnakPage()),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEBF5FF),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tambah Profil\nAnak',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Memformat deskripsi usia anak agar ringkas (misal: "1 tahun 3 bulan", "0 tahun 4 bulan")
  String _formatChildAge(ChildModel child) {
    if (child.birthDate != null) {
      final now = DateTime.now();
      final birth = child.birthDate!;
      int years = now.year - birth.year;
      int months = now.month - birth.month;
      int days = now.day - birth.day;

      if (days < 0) {
        months -= 1;
      }
      if (months < 0) {
        years -= 1;
        months += 12;
      }

      if (years >= 0 && months >= 0) {
        return '$years tahun $months bulan';
      }
    }

    final desc = child.ageDescription;
    final match = RegExp(r'(\d+\s*tahun\s*\d+\s*bulan)').firstMatch(desc);
    if (match != null) {
      return match.group(1)!;
    }
    return desc;
  }

  // ===================================================================
  // 2. KONTEN PUTIH (6 Card Menu, Card PediaGrow, Artikel, Video Edukasi)
  // Margin 12dp dari sisi kiri & kanan layar
  // ===================================================================
  Widget _buildWhiteContentSection(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 24, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 6 Card Menu (lebar penuh sejajar margin 12dp)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _build6MenuGrid(context),
          ),

          const SizedBox(height: 24),

          // Card PediaGrow (lebar penuh identik dengan Card MomDad & Menu, margin 12dp)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildPediaGrowCard(),
          ),

          const SizedBox(height: 24),

          // 3. Section Artikel Terbaru (Horizontal Scroll Carousel)
          _buildLatestArticlesSection(context),

          const SizedBox(height: 24),

          // 4. Section Video Edukasi Anak (YouTube Carousel)
          _buildEducationalVideosSection(context),
        ],
      ),
    );
  }

  // ===================================================================
  // 6 CARD MENU
  // Warna #ECF6FF, dimensi 3 kolom sejajar presisi, corner radius 10
  // ===================================================================
  Widget _build6MenuGrid(BuildContext context) {
    return Column(
      children: [
        // Baris 1: Cek Stunting, Grafik Pertumbuhan, Resep MPASI
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildMenuItem(
                title: 'Cek\nStunting',
                imageAsset: 'assets/images/cek_stunting_logo.png',
                onTap: () => _navigateTo(const PilihAnakPage()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                title: 'Grafik\nPertumbuhan',
                imageAsset: 'assets/images/grafik_pertumbuhan_logo.png',
                onTap: () => _navigateTo(const PilihAnakGrafikPage()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                title: 'Resep\nMPASI',
                imageAsset: 'assets/images/resep_mpasi_logo.png',
                onTap: () => _navigateTo(const DaftarResepPage()),
                logoOffsetX: 2,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Baris 2: Artikel Kesehatan, Lokasi Fasyankes, Permainan
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildMenuItem(
                title: 'Artikel\nKesehatan',
                imageAsset: 'assets/images/artikel_kesehatan_logo.png',
                onTap: () => _navigateTo(const ArtikelKesehatanPage()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                title: 'Lokasi\nFasyankes',
                imageAsset: 'assets/images/lokasi_fasyankes_logo.png',
                onTap: () => _navigateTo(const LokasiFasyankesPage()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                title: 'Permainan\n',
                imageAsset: 'assets/images/permainan_logo.png',
                onTap: () => _navigateTo(const GameMulaiPage()),
                logoOffsetX: 5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required String title,
    required String imageAsset,
    required VoidCallback onTap,
    double cardInset =
        6, // seberapa "dikecilkan" card-nya (kiri-kanan dalam kolom)
    double imageSize = 40, // ukuran logo, dikecilkan mengikuti card
    double logoOffsetX = 0, // geser logo ke kanan/kiri kalau logo tidak center
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Menu: dikecilkan via padding horizontal, tetap kotak (1:1)
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
                      // Dekorasi ilustrasi/pola blob tematik halus di belakang icon
                      _buildThematicTileDecoration(title),

                      // Logo Icon Menu Utama
                      Center(
                        child: Transform.translate(
                          offset: Offset(logoOffsetX, 0),
                          child: Image.asset(
                            imageAsset,
                            height: imageSize,
                            fit: BoxFit.contain,
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
          // Judul Menu (Lato Regular 14, #000000)
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

  // ===================================================================
  // CARD PEDIAGROW
  // Warna #ECF6FF, dimensi lebar penuh (margin 12dp) x height 115, corner radius 10
  // Sisi kiri: ilustrasi bayi pediagrow
  // Sisi kanan: "PediaGrow" + Tagline
  // ===================================================================
  Widget _buildPediaGrowCard() {
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
          // Ilustrasi Bayi PediaGrow (gambar 7)
          SizedBox(
            width: 84,
            height: 94,
            child: Image.asset(
              'assets/images/bayi_pediagrow_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.child_care_rounded,
                size: 50,
                color: Color(0xFF3985E7),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Teks PediaGrow & Tagline
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Pedia" (#4B83D6) & "Grow" (#3CC3A6) Baloo 2 Bold 18
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Pedia',
                        style: GoogleFonts.baloo2(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4B83D6),
                        ),
                      ),
                      TextSpan(
                        text: 'Grow',
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
                // Tagline "Pantau Pertumbuhan, Cegah Stunting untuk Masa Depan" (Lato Regular 16, #000000)
                Text(
                  'Pantau Pertumbuhan,\nCegah Stunting untuk Masa Depan',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF000000),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // 3. SECTION ARTIKEL TERBARU (Horizontal Scroll Carousel)
  // Menampilkan artikel kesehatan terbaru dari ArtikelService
  // ===================================================================
  Widget _buildLatestArticlesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section: Judul & Tombol "Lihat Selengkapnya"
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
                onTap: () => _navigateTo(const ArtikelKesehatanPage()),
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
                        'Lihat Selengkapnya',
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

        // Carousel Horizontal Kartu Artikel
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

  /// Kartu item artikel kesehatan dalam carousel
  Widget _buildArticleCard(BuildContext context, ArtikelModel artikel) {
    final hasImage =
        artikel.displayImage != null && artikel.displayImage!.isNotEmpty;
    final isAsset = artikel.isAssetImage;
    final categoryText = artikel.subKategori.isNotEmpty
        ? artikel.subKategori.first
        : artikel.kategori;

    // Estimasi waktu baca
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
              // Thumbnail Gambar Artikel
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
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildFallbackArticleImage(),
                              )
                            : Image.network(
                                artikel.displayImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildFallbackArticleImage(),
                              ))
                      : _buildFallbackArticleImage(),
                ),
              ),

              // Info Teks Artikel
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
                          // Tag Kategori & Estimasi Waktu Baca
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
                          // Judul Artikel
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
                      // Tanggal Publikasi
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

  // ===================================================================
  // 4. SECTION VIDEO EDUKASI ANAK (YouTube Carousel)
  // Menampilkan video edukasi anak (Cocomelon / animasi edukatif)
  // ===================================================================
  Widget _buildEducationalVideosSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section: Ikon YouTube & Judul
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0000).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.play_circle_filled_rounded,
                  color: Color(0xFFFF0000),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Video Edukasi Anak',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Carousel Horizontal Kartu Video
        SizedBox(
          height: 205,
          child: _isLoadingVideos
              ? _buildVideoSkeletonList()
              : _educationalVideos.isEmpty
              ? _buildEmptyVideoState()
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _educationalVideos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final video = _educationalVideos[index];
                    return _buildVideoCard(context, video);
                  },
                ),
        ),
      ],
    );
  }

  /// Kartu item video YouTube
  Widget _buildVideoCard(BuildContext context, YoutubeVideoModel video) {
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
          onTap: () => YoutubePlayerSheet.show(context, video),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail Video + Play Overlay + Durasi
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 110,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        video.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFE2E8F0),
                          child: const Center(
                            child: Icon(
                              Icons.videocam_rounded,
                              color: Color(0xFF94A3B8),
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                      // Tombol Play Overlay di Tengah
                      Center(
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.55),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      // Pill Durasi di Sudut Kanan Bawah
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            video.duration,
                            style: GoogleFonts.lato(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Info Teks Video
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(9.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        video.title,
                        style: GoogleFonts.lato(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 11,
                            color: Color(0xFF3985E7),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              video.channelTitle,
                              style: GoogleFonts.lato(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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

  Widget _buildVideoSkeletonList() {
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
              height: 110,
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
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 80,
                    height: 12,
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

  Widget _buildEmptyVideoState() {
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
          'Belum ada video edukasi saat ini',
          style: GoogleFonts.lato(fontSize: 13, color: const Color(0xFF64748B)),
        ),
      ),
    );
  }

  /// Dekorasi pola/blob tematik di dalam tile menu sesuai kategori
  Widget _buildThematicTileDecoration(String title) {
    final cleanTitle = title.replaceAll('\n', ' ').trim().toLowerCase();

    Color blobColor = const Color(0xFF3985E7).withValues(alpha: 0.08);
    Widget deco;

    if (cleanTitle.contains('stunting')) {
      // Aksen perisai & lingkaran kesehatan
      blobColor = const Color(0xFF3B82F6).withValues(alpha: 0.09);
      deco = Stack(
        children: [
          Positioned(
            top: -12,
            right: -12,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: blobColor,
              ),
            ),
          ),
          Positioned(
            bottom: -8,
            left: -8,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: blobColor.withValues(alpha: 0.06),
              ),
            ),
          ),
        ],
      );
    } else if (cleanTitle.contains('grafik')) {
      // Aksen kurva pertumbuhan
      blobColor = const Color(0xFF2563EB).withValues(alpha: 0.09);
      deco = Stack(
        children: [
          Positioned(
            bottom: -15,
            right: -10,
            child: Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: blobColor,
              ),
            ),
          ),
          Positioned(
            top: -6,
            left: -6,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: blobColor.withValues(alpha: 0.05),
              ),
            ),
          ),
        ],
      );
    } else if (cleanTitle.contains('mpasi')) {
      // Aksen mangkuk bernutrisi organik
      blobColor = const Color(0xFF10B981).withValues(alpha: 0.08);
      deco = Stack(
        children: [
          Positioned(
            top: -10,
            left: -10,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(30),
                ),
                color: blobColor,
              ),
            ),
          ),
          Positioned(
            bottom: -10,
            right: -8,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: blobColor.withValues(alpha: 0.06),
              ),
            ),
          ),
        ],
      );
    } else if (cleanTitle.contains('artikel')) {
      // Aksen lembaran dokumen bacaan
      blobColor = const Color(0xFF6366F1).withValues(alpha: 0.08);
      deco = Stack(
        children: [
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                ),
                color: blobColor,
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: blobColor.withValues(alpha: 0.05),
              ),
            ),
          ),
        ],
      );
    } else if (cleanTitle.contains('fasyankes')) {
      // Aksen radar lingkaran fasyankes
      blobColor = const Color(0xFF0EA5E9).withValues(alpha: 0.09);
      deco = Stack(
        children: [
          Positioned(
            top: -15,
            left: -15,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: blobColor,
              ),
            ),
          ),
          Positioned(
            bottom: -6,
            right: -6,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: blobColor.withValues(alpha: 0.05),
              ),
            ),
          ),
        ],
      );
    } else {
      // Permainan: Aksen ceria sparkle & bintang
      blobColor = const Color(0xFFF59E0B).withValues(alpha: 0.09);
      deco = Stack(
        children: [
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: blobColor,
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
      );
    }

    return IgnorePointer(child: deco);
  }

  // ===================================================================
  // 3. ILUSTRASI FOOTER FULL-BLEED
  // 100% width layar, tanpa margin/padding, menempel langsung ke Nav Bar
  // ===================================================================
  Widget _buildFooterIllustration() {
    return SizedBox(
      width: double.infinity,
      child: Image.asset(
        'assets/images/beranda_landscape_footer.jpg',
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

  // ===================================================================
  // 4. NAVIGATION BAR (Fixed di Scaffold)
  // Warna #F2EDED, tinggi 68dp (range 65-70dp)
  // Beranda aktif: bulatan putih dengan ikon biru #72A9F4 di dalamnya
  // ===================================================================
  Widget _buildFixedNavBar() {
    final navItems = [
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
          final isSelected = i == _selectedNavIndex;
          final item = navItems[i];

          return GestureDetector(
            onTap: () => _onNavTap(i),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 80,
              height: 68,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected) ...[
                    // State aktif: lingkaran putih dengan icon biru #72A9F4
                    Container(
                      width: 38,
                      height: 38,
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
                        size: 24,
                        color: const Color(0xFF72A9F4),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ] else ...[
                    // State tidak aktif: icon & label abu-abu #9E9E9E
                    Icon(item.icon, size: 24, color: const Color(0xFF9E9E9E)),
                    const SizedBox(height: 3),
                    Text(
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

// =====================================================================
// DATA MODELS & HELPER WIDGETS
// =====================================================================

class _NavData {
  final IconData icon;
  final String label;

  const _NavData({required this.icon, required this.label});
}

/// Widget elips dekoratif dengan efek Gaussian blur
class _BlurredEllipse extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double blurSigma;

  const _BlurredEllipse({
    required this.width,
    required this.height,
    required this.color,
    required this.blurSigma,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _BlurredEllipsePainter(color: color, blurSigma: blurSigma),
    );
  }
}

class _BlurredEllipsePainter extends CustomPainter {
  final Color color;
  final double blurSigma;

  const _BlurredEllipsePainter({required this.color, required this.blurSigma});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
    canvas.drawOval(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _BlurredEllipsePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.blurSigma != blurSigma;
}

/// CustomPainter untuk menggambar ilustrasi wajah bayi seperti pada desain kartu
class _BabyFacePainter extends CustomPainter {
  final Color outlineColor;
  const _BabyFacePainter({this.outlineColor = const Color(0xFF1E293B)});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.32;

    // Telinga Kiri & Kanan
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx - r - 2, cy + 1), radius: 5),
      math.pi / 2,
      math.pi,
      false,
      stroke,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx + r + 2, cy + 1), radius: 5),
      -math.pi / 2,
      math.pi,
      false,
      stroke,
    );

    // Bentuk Kepala / Lingkaran Wajah
    canvas.drawCircle(Offset(cx, cy + 1), r, stroke);

    // Rambut / Poni Bayi
    final hairPath = Path();
    hairPath.moveTo(cx - r * 0.85, cy - r * 0.2);
    hairPath.quadraticBezierTo(cx - r * 0.4, cy - r * 0.9, cx, cy - r * 0.3);
    hairPath.quadraticBezierTo(
      cx + r * 0.4,
      cy - r * 0.9,
      cx + r * 0.85,
      cy - r * 0.2,
    );
    hairPath.quadraticBezierTo(cx + r * 0.5, cy - r * 1.15, cx, cy - r * 1.05);
    hairPath.quadraticBezierTo(
      cx - r * 0.5,
      cy - r * 1.15,
      cx - r * 0.85,
      cy - r * 0.2,
    );
    hairPath.close();
    canvas.drawPath(hairPath, fill);

    // Mata Kiri & Kanan
    canvas.drawCircle(Offset(cx - 7, cy), 2.2, fill);
    canvas.drawCircle(Offset(cx + 7, cy), 2.2, fill);

    // Hidung
    final nosePath = Path();
    nosePath.moveTo(cx - 1.5, cy + 3.5);
    nosePath.quadraticBezierTo(cx, cy + 5, cx + 1.5, cy + 3.5);
    canvas.drawPath(nosePath, stroke..strokeWidth = 1.8);

    // Senyuman
    final smilePath = Path();
    smilePath.moveTo(cx - 5.5, cy + 7);
    smilePath.quadraticBezierTo(cx, cy + 11.5, cx + 5.5, cy + 7);
    canvas.drawPath(smilePath, stroke..strokeWidth = 2.0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget awan puffy dekoratif dengan efek lembut dan mengapung
class _PuffyCloud extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const _PuffyCloud({
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _PuffyCloudPainter(color: color),
    );
  }
}

class _PuffyCloudPainter extends CustomPainter {
  final Color color;
  const _PuffyCloudPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.height * 0.18);

    final w = size.width;
    final h = size.height;

    // Badan awan utama (ellips bawah)
    canvas.drawOval(Rect.fromLTWH(w * 0.1, h * 0.45, w * 0.8, h * 0.5), paint);

    // Gundukan kiri
    canvas.drawOval(
      Rect.fromLTWH(w * 0.05, h * 0.18, w * 0.38, h * 0.5),
      paint,
    );

    // Gundukan tengah (lebih tinggi)
    canvas.drawOval(
      Rect.fromLTWH(w * 0.28, h * 0.0, w * 0.44, h * 0.58),
      paint,
    );

    // Gundukan kanan
    canvas.drawOval(
      Rect.fromLTWH(w * 0.55, h * 0.15, w * 0.38, h * 0.50),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _PuffyCloudPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Widget matahari dekoratif dengan pendaran cahaya lembut dan animasi pulsing
class _DecorativeSun extends StatelessWidget {
  final double pulseValue;
  final double rotateValue;

  const _DecorativeSun({required this.pulseValue, required this.rotateValue});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotateValue,
      child: Transform.scale(
        scale: pulseValue,
        child: SizedBox(
          width: 58,
          height: 58,
          child: CustomPaint(painter: _SunPainter()),
        ),
      ),
    );
  }
}

class _SunPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);

    // 1. Halo pendaran luar (Glow effect lembut)
    final glowPaint = Paint()
      ..color = const Color(0xFFFFF7C2).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, size.width * 0.44, glowPaint);

    // 2. Pancaran sinar matahari lembut (8 rays)
    final rayPaint = Paint()
      ..color = const Color(0xFFFFE082).withValues(alpha: 0.65)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    const numRays = 8;
    final innerRayR = size.width * 0.32;
    final outerRayR = size.width * 0.45;

    for (int i = 0; i < numRays; i++) {
      final angle = (i * 2 * math.pi) / numRays;
      final x1 = cx + innerRayR * math.cos(angle);
      final y1 = cy + innerRayR * math.sin(angle);
      final x2 = cx + outerRayR * math.cos(angle);
      final y2 = cy + outerRayR * math.sin(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), rayPaint);
    }

    // 3. Inti matahari dengan gradient hangat
    const coreGradient = RadialGradient(
      colors: [Color(0xFFFFFDE7), Color(0xFFFFF176), Color(0xFFFFB74D)],
      stops: [0.0, 0.65, 1.0],
    );

    final corePaint = Paint()
      ..shader = coreGradient.createShader(
        Rect.fromCircle(center: center, radius: size.width * 0.26),
      );

    canvas.drawCircle(center, size.width * 0.26, corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
