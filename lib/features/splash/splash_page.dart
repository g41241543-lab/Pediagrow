import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/auth_choice_page.dart';
import '../../core/services/session_service.dart';
import '../../core/services/user_service.dart';
import '../../core/services/child_service.dart';

/// Halaman Splash Screen PediaGrow dengan opening modern, elegan, luxury, dan futuristik.
///
/// Fitur & Rangkaian Animasi:
/// 1. Pembuka Atmosferik Luxury (Deep Sapphire -> Pristine Crystalline Dissolve):
///    - Gradien Deep Sapphire Navy (#0B192C -> #163864) dengan ambient pulse halus.
///    - Dissolve sinematik ke kanvas putih mutiara kristal (#F3F8FE -> #FFFFFF)
///      disertai gelombang aura cahaya melingkar lembut tanpa tepian kaku.
/// 2. Kemunculan Logo Bertahap Secara Halus & Elegan:
///    - Daun (kanan hijau #3CC3A6 & kiri biru #4B83D6) mekar dari bawah ke atas secara silky.
///    - Lengkungan orbit biru meluncur presisi dari atas.
///    - Siluet bayi beraksen hangat materialistis lembut di tengah.
///    - Bintang emas berkilau (twinkle & radiant sparkle gleam) dengan rotasi mikro.
/// 3. Transisi Logo Mandiri (Gambar 1) ke Brand Lockup PediaGrow:
///    - Jarak antara logo dan nama aplikasi PediaGrow diperlebar menjadi 52dp untuk pernapasan mewah.
///    - Posisi akhir logo bergeser ke -66dp sehingga seluruh komposisi (logo + teks + tagline)
///      berada tepat di tengah layar secara matematis sempurna.
///    - Sinkronisasi penuh sejak detik 0.66 tanpa hentakan layout (Stack-anchored geometric stability).
///    - Gelombang cincin energi holografik (Energy Ring Wave) memancar dari logo saat transisi.
///    - Typografi resmi "PediaGrow" (Baloo 2 Bold) muncul halus bersamaan dengan ekspansi tracking optik.
///    - Garis aksen laser presisi gradien mengembang horizontal mengapit tagline eksklusif.
/// 4. Kilatan Silau Presisi Mengikuti Kontur Logo & Teks:
///    - Menggunakan ShaderMask dengan BlendMode.srcIn sehingga kilatan cahaya
///      HANYA menyapu permukaan logo dan huruf, TANPA menciptakan kotak/garis di background.
/// 5. Transisi Mulus & Elegan Menuju AuthChoicePage:
///    - Menggunakan PageRouteBuilder dengan soft vertical drift (3% slide-up) dan fade yang anggun (650ms),
///      tanpa efek hero clash yang terbang menabrak logo, menghasilkan alur pembuka aplikasi yang tenang dan mewah.
class SplashPage extends StatefulWidget {
  /// Durasi total rangkaian animasi otomatis splash screen.
  final Duration animationDuration;

  /// Mengizinkan tap pada layar untuk skip langsung ke halaman tujuan.
  final bool enableTapToSkip;

  const SplashPage({
    super.key,
    this.animationDuration = const Duration(milliseconds: 2800),
    this.enableTapToSkip = true,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  // Palet Warna Resmi PediaGrow
  static const Color colorPrimaryBlue = Color(0xFF295EA3);
  static const Color colorDeepSapphireTop = Color(0xFF0B192C);
  static const Color colorDeepSapphireBottom = Color(0xFF163864);
  static const Color colorPediaBlue = Color(0xFF4B83D6); // Pedia & Left Leaf
  static const Color colorGrowGreen = Color(0xFF3CC3A6); // Grow & Right Leaf
  static const Color colorGoldStar = Color(0xFFFFC837);

  late AnimationController _controller;

  // 1. Tahap Pembuka: Atmospheric Deep Sapphire ke Pristine Crystalline Dissolve
  late Animation<double> _initialGlowPulseAnim;
  late Animation<double> _whiteCanvasFadeAnim;
  late Animation<double> _waveProgressAnim;

  // 2. Tahap Logo Elegan Bertahap (Daun -> Orbit -> Bayi -> Bintang)
  late Animation<double> _logoLeavesScaleAnim;
  late Animation<double> _logoLeavesFadeAnim;
  late Animation<double> _logoArchScaleAnim;
  late Animation<double> _logoArchFadeAnim;
  late Animation<double> _logoBabyScaleAnim;
  late Animation<double> _logoBabyFadeAnim;
  late Animation<double> _logoStarScaleAnim;
  late Animation<double> _logoStarRotateAnim;
  late Animation<double> _logoStarSparkleAnim;
  late Animation<double> _haloGlowAnim;

  // 3. Transisi Futuristik & Mulus ke Brand Lockup
  late Animation<double> _energyRingAnim;
  late Animation<double> _logoOffsetYAnim;
  late Animation<double> _titleFadeAnim;
  late Animation<double> _titleSlideAnim;
  late Animation<double> _titleTrackingAnim;
  late Animation<double> _taglineFadeAnim;
  late Animation<double> _taglineWidthAnim;

  // 4. Kilatan Cahaya Presisi Mengikuti Kontur Logo & Teks
  late Animation<double> _sheenAnim;

  // 5. Tahap Aksen Bawah (Footer & Minimalist Bar)
  late Animation<double> _footerFadeAnim;

  bool _hasNavigated = false;
  SessionDestination _resolvedDestination = const SessionDestination(
    page: AuthChoicePage(),
  );

  @override
  void initState() {
    super.initState();

    // Evaluasi destinasi session sedini mungkin
    SessionService().getInitialDestination().then((dest) {
      if (mounted) {
        _resolvedDestination = dest;
      }
    });

    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _initAnimations();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNextScreen();
      }
    });

    _controller.forward();

    // Muat data pengguna dan anak di background sambil animasi berjalan
    _initUserInBackground();
  }

  Future<void> _initUserInBackground() async {
    try {
      await UserService().init();
      ChildService().loadChildrenForCurrentUser();
    } catch (_) {}
  }

  void _initAnimations() {
    // -------------------------------------------------------------------------
    // 1. TAHAP 1: Pembuka Luxury Atmospheric Dissolve (0.00 -> 0.28)
    // -------------------------------------------------------------------------
    _initialGlowPulseAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.00, 0.16, curve: Curves.easeInOut),
    );

    _whiteCanvasFadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.08, 0.26, curve: Curves.easeInOutCubic),
    );

    _waveProgressAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.08, 0.30, curve: Curves.easeOutCubic),
    );

    // -------------------------------------------------------------------------
    // 2. TAHAP 2: Kemunculan Logo Bertahap Per-Elemen (0.24 -> 0.64)
    // -------------------------------------------------------------------------
    // a. Daun (0.24 -> 0.40)
    _logoLeavesScaleAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.24, 0.40, curve: Curves.easeOutCubic),
      ),
    );
    _logoLeavesFadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.24, 0.36, curve: Curves.easeIn),
    );

    // b. Orbit Arch (0.34 -> 0.48)
    _logoArchScaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.34, 0.48, curve: Curves.easeOutCubic),
      ),
    );
    _logoArchFadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.34, 0.44, curve: Curves.easeIn),
    );

    // c. Bayi (0.42 -> 0.56)
    _logoBabyScaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.42, 0.56, curve: Curves.easeOutBack),
      ),
    );
    _logoBabyFadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.42, 0.50, curve: Curves.easeIn),
    );

    // d. Bintang Emas Berkilau (0.50 -> 0.64)
    _logoStarScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.50, 0.64, curve: Curves.easeOutBack),
      ),
    );
    _logoStarRotateAnim = Tween<double>(begin: -0.3, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.50, 0.64, curve: Curves.easeOut),
      ),
    );
    _logoStarSparkleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.52, 0.66, curve: Curves.easeInOut),
      ),
    );

    // Halo Glow di belakang emblem (0.46 -> 0.68)
    _haloGlowAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.46, 0.68, curve: Curves.easeInOut),
    );

    // -------------------------------------------------------------------------
    // 3. TAHAP 3: Transisi Futuristik & Mulus (Gambar 1 -> Gambar 2) (0.66 -> 0.84)
    // -------------------------------------------------------------------------
    // Gelombang cincin energi holografik memancar saat transisi dimulai
    _energyRingAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 0.77, curve: Curves.easeOutQuart),
    );

    // Logo bergeser naik ke -66dp agar seluruh lockup berada di tengah layar secara simetris
    _logoOffsetYAnim = Tween<double>(begin: 0.0, end: -66.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.66, 0.84, curve: Curves.easeInOutCubic),
      ),
    );

    // Judul PediaGrow muncul naik selaras dengan logo sejak awal transisi (0.66)
    _titleFadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.66, 0.82, curve: Curves.easeOutCubic),
    );
    _titleSlideAnim = Tween<double>(begin: 12.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.66, 0.82, curve: Curves.easeOutCubic),
      ),
    );
    _titleTrackingAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.66, 0.84, curve: Curves.easeOutCubic),
    );

    // Tagline & Garis Aksen Laser Presisi
    _taglineFadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.72, 0.86, curve: Curves.easeOutCubic),
    );
    _taglineWidthAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.72, 0.86, curve: Curves.easeOutCubic),
    );

    // -------------------------------------------------------------------------
    // 4. TAHAP 4: Kilatan Cahaya Presisi Mengikuti Bentuk Logo (0.84 -> 0.95)
    // -------------------------------------------------------------------------
    _sheenAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.84, 0.95, curve: Curves.easeInOutCubic),
      ),
    );

    // 5. Footer & aksen bawah (0.80 -> 0.92)
    _footerFadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.80, 0.92, curve: Curves.easeIn),
    );
  }

  void _navigateToNextScreen() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    _doNavigate(_resolvedDestination);
  }

  void _doNavigate(SessionDestination destination) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 650),
        pageBuilder: (context, animation, secondaryAnimation) =>
            destination.page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnim = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );

          // Masuk dengan transisi fade & slide up lembut (3.5% ketinggian layar)
          return FadeTransition(
            opacity: curvedAnim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.035),
                end: Offset.zero,
              ).animate(curvedAnim),
              child: child,
            ),
          );
        },
      ),
    );

    if (destination.expiredMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SessionService.showExpiredNotice(destination.expiredMessage!);
      });
    }
  }

  void _skipToEnd() {
    if (widget.enableTapToSkip && !_hasNavigated) {
      _navigateToNextScreen();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoSize = math.min(size.width * 0.40, 172.0);

    return GestureDetector(
      onTap: _skipToEnd,
      child: Scaffold(
        backgroundColor: colorDeepSapphireTop,
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;

            return Stack(
              fit: StackFit.expand,
              children: [
                // -------------------------------------------------------------
                // 1. LATAR BELAKANG: Deep Sapphire Gradient (Awal)
                // -------------------------------------------------------------
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorDeepSapphireTop,
                          colorPrimaryBlue,
                          colorDeepSapphireBottom,
                        ],
                      ),
                    ),
                  ),
                ),

                // Lingkaran cahaya pembuka awal di tengah (pulsing glow ring)
                if (t < 0.28)
                  Center(
                    child: Container(
                      width: 90 + (_initialGlowPulseAnim.value * 24),
                      height: 90 + (_initialGlowPulseAnim.value * 24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(
                              alpha: (1.0 - _initialGlowPulseAnim.value) * 0.4,
                            ),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                          BoxShadow(
                            color: colorGrowGreen.withValues(
                              alpha: (1.0 - _initialGlowPulseAnim.value) * 0.3,
                            ),
                            blurRadius: 50,
                            spreadRadius: 18,
                          ),
                        ],
                      ),
                    ),
                  ),

                // -------------------------------------------------------------
                // 2. DISSOLVE KE KANVAS PUTIH MUTIARA KRISTAL (Smooth & Seamless)
                // -------------------------------------------------------------
                if (_whiteCanvasFadeAnim.value > 0.0)
                  Positioned.fill(
                    child: Opacity(
                      opacity: _whiteCanvasFadeAnim.value,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          gradient: RadialGradient(
                            center: Alignment(0, -0.10),
                            radius: 0.95,
                            colors: [
                              Color(0xFFF3F8FE), // Soft crystalline blue
                              Colors.white,
                            ],
                            stops: [0.0, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Gelombang aura cahaya lembut melingkar saat transisi latar
                if (_waveProgressAnim.value > 0.0 && _waveProgressAnim.value < 1.0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _SoftAuraWavePainter(
                          progress: _waveProgressAnim.value,
                        ),
                      ),
                    ),
                  ),

                // -------------------------------------------------------------
                // 3. AMBIENT HALO GLOW DI BELAKANG EMBLEM
                // -------------------------------------------------------------
                if (t >= 0.24 && _haloGlowAnim.value > 0.0)
                  Center(
                    child: Transform.translate(
                      offset: Offset(0, _logoOffsetYAnim.value),
                      child: Container(
                        width: logoSize * 1.55,
                        height: logoSize * 1.55,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              colorGrowGreen.withValues(
                                alpha: 0.16 * _haloGlowAnim.value,
                              ),
                              colorPediaBlue.withValues(
                                alpha: 0.08 * _haloGlowAnim.value,
                              ),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                // -------------------------------------------------------------
                // 4. GELOMBANG CINCIN ENERGI HOLOGRAFIK (Transisi Futuristik)
                // -------------------------------------------------------------
                if (_energyRingAnim.value > 0.0 && _energyRingAnim.value < 1.0)
                  Center(
                    child: Transform.translate(
                      offset: Offset(0, _logoOffsetYAnim.value),
                      child: CustomPaint(
                        size: Size(logoSize * 2.2, logoSize * 2.2),
                        painter: _EnergyRingPainter(
                          progress: _energyRingAnim.value,
                        ),
                      ),
                    ),
                  ),

                // -------------------------------------------------------------
                // 5. BRAND HERO CONTENT (Transisi Kontinu Bebas Jump)
                // -------------------------------------------------------------
                if (t >= 0.24)
                  Center(
                    child: _buildBrandIdentity(logoSize),
                  ),

                // -------------------------------------------------------------
                // 6. AKSEN FOOTER MINIMALIS LUXURY
                // -------------------------------------------------------------
                if (_footerFadeAnim.value > 0.0)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Opacity(
                        opacity: _footerFadeAnim.value,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 22.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Garis aksen mikro bergradien
                              Container(
                                width: 36,
                                height: 3,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(1.5),
                                  gradient: const LinearGradient(
                                    colors: [
                                      colorPediaBlue,
                                      colorGrowGreen,
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'PediaGrow • Aplikasi Tumbuh Kembang Anak',
                                style: GoogleFonts.lato(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF94A3B8),
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Membangun keseluruhan identitas brand dengan kontinuitas geometris mutlak:
  /// - Logo diposisikan di tengah saat Gambar 1.
  /// - Saat bertransisi ke Gambar 2, logo meluncur mulus ke atas (-66dp).
  /// - Jarak antara bagian bawah logo dan judul PediaGrow diperlebar menjadi 52dp (+52dp)
  ///   sehingga logo dan nama aplikasi bernapas lega, tidak berdekatan.
  /// - Dilapisi kilatan presisi menggunakan ShaderMask (BlendMode.srcIn)
  ///   sehingga hanya menyapu piksel logo dan huruf (anti kotak).
  Widget _buildBrandIdentity(double logoSize) {
    // Konten visual utama (Base Tree)
    final Widget brandContent = Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // A. EMBLEM LOGO DENGAN ELEMEN BERTAHAP
        Transform.translate(
          offset: Offset(0, _logoOffsetYAnim.value),
          child: _buildLayeredLogo(logoSize),
        ),

        // B. TYPOGRAPHY PEDIAGROW & TAGLINE
        // Diberi jarak yang lega: (logoSize / 2) + 52.0 dp dari pusat logo
        Transform.translate(
          offset: Offset(
            0,
            _logoOffsetYAnim.value + (logoSize / 2) + 52.0 + _titleSlideAnim.value,
          ),
          child: Opacity(
            opacity: _titleFadeAnim.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Judul PediaGrow
                _buildPediaGrowTitle(46.0),

                const SizedBox(height: 12.0),

                // Tagline Futuristik dengan garis laser yang mengembang horizontal
                Opacity(
                  opacity: _taglineFadeAnim.value,
                  child: _buildFuturisticTagline(),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    final bool isSheenActive = _sheenAnim.value > 0.0 && _sheenAnim.value < 1.0;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Pohon widget utama
        brandContent,

        // Kilatan kilau presisi: hanya muncul di atas piksel logo dan teks
        if (isSheenActive)
          Positioned.fill(
            child: IgnorePointer(
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) {
                  final sweep = _sheenAnim.value; // 0.0 -> 1.0
                  final xPos = -1.2 + (sweep * 3.4);
                  return LinearGradient(
                    begin: Alignment(xPos - 0.45, -1.0),
                    end: Alignment(xPos + 0.45, 1.0),
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.75),
                      Colors.transparent,
                    ],
                    stops: const [0.25, 0.50, 0.75],
                  ).createShader(bounds);
                },
                child: brandContent,
              ),
            ),
          ),
      ],
    );
  }

  /// Membangun logo berlapis yang muncul bertahap per-elemen secara halus:
  /// 1. Daun
  /// 2. Lengkungan Orbit Biru
  /// 3. Bayi
  /// 4. Bintang Emas dengan Sparkle
  Widget _buildLayeredLogo(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Daun (Daun kanan hijau #3CC3A6 & Daun kiri biru #4B83D6)
          if (_logoLeavesFadeAnim.value > 0.0)
            Positioned.fill(
              child: Opacity(
                opacity: _logoLeavesFadeAnim.value,
                child: Transform.scale(
                  scale: _logoLeavesScaleAnim.value,
                  alignment: Alignment.bottomCenter,
                  child: Image.asset(
                    'assets/images/logo_leaves.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

          // 2. Lengkungan orbit biru di bagian atas
          if (_logoArchFadeAnim.value > 0.0)
            Positioned.fill(
              child: Opacity(
                opacity: _logoArchFadeAnim.value,
                child: Transform.scale(
                  scale: _logoArchScaleAnim.value,
                  alignment: Alignment.topCenter,
                  child: Image.asset(
                    'assets/images/logo_arch.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

          // 3. Bayi (#FFAC3D / #FFDCAD)
          if (_logoBabyFadeAnim.value > 0.0)
            Positioned.fill(
              child: Opacity(
                opacity: _logoBabyFadeAnim.value,
                child: Transform.scale(
                  scale: _logoBabyScaleAnim.value,
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/logo_baby.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

          // 4. Bintang (#FFF619 / #FAFF00) dengan efek pop halus, rotasi & sparkle gleam
          if (_logoStarScaleAnim.value > 0.0)
            Positioned.fill(
              child: Transform.rotate(
                angle: _logoStarRotateAnim.value,
                alignment: const Alignment(0.65, -0.65),
                child: Transform.scale(
                  scale: _logoStarScaleAnim.value,
                  alignment: const Alignment(0.65, -0.65),
                  child: Image.asset(
                    'assets/images/logo_star.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

          // Sparkle Gleam hangat pada posisi bintang
          if (_logoStarSparkleAnim.value > 0.0)
            Align(
              alignment: const Alignment(0.65, -0.65),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorGoldStar.withValues(
                        alpha: 0.7 * _logoStarSparkleAnim.value,
                      ),
                      blurRadius: 18,
                      spreadRadius: 6,
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(
                        alpha: 0.9 * _logoStarSparkleAnim.value,
                      ),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Teks resmi "PediaGrow" menggunakan font Baloo 2 Bold dengan animasi tracking optik futuristik.
  Widget _buildPediaGrowTitle(double fontSize) {
    // Animasi optical tracking dari -1.0 ke -0.2
    final double tracking = -1.0 + (0.8 * _titleTrackingAnim.value);

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Pedia',
            style: GoogleFonts.baloo2(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: colorPediaBlue, // #4B83D6
              letterSpacing: tracking,
              height: 1.1,
            ),
          ),
          TextSpan(
            text: 'Grow',
            style: GoogleFonts.baloo2(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: colorGrowGreen, // #3CC3A6
              letterSpacing: tracking,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  /// Tagline futuristik dengan garis laser presisi yang mengembang horizontal secara halus.
  Widget _buildFuturisticTagline() {
    final double lineWidth = 24.0 * _taglineWidthAnim.value;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Garis laser kiri
        Container(
          width: lineWidth,
          height: 1.5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                colorPediaBlue.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
        if (lineWidth > 3) const SizedBox(width: 8),
        Text(
          'PEDIATRIC HEALTH & GROWTH',
          style: GoogleFonts.lato(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF64748B),
            letterSpacing: 2.6,
          ),
        ),
        if (lineWidth > 3) const SizedBox(width: 8),
        // Garis laser kanan
        Container(
          width: lineWidth,
          height: 1.5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            gradient: LinearGradient(
              colors: [
                colorGrowGreen.withValues(alpha: 0.8),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// CustomPainter untuk cincin gelombang energi holografik (Energy Ring Wave)
/// yang memancar saat transisi dari logo mandiri ke lockup nama aplikasi.
class _EnergyRingPainter extends CustomPainter {
  final double progress; // 0.0 -> 1.0

  _EnergyRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final initialRadius = size.width * 0.28;
    final maxRadius = size.width * 0.65;
    final currentRadius =
        initialRadius + (maxRadius - initialRadius) * progress;
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    // Cincin energi cyan-sapphire dengan sweep gradient dan blur halus
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * (1.0 - progress)
      ..shader = SweepGradient(
        colors: [
          const Color(0xFF4B83D6).withValues(alpha: alpha * 0.45),
          const Color(0xFF3CC3A6).withValues(alpha: alpha * 0.60),
          const Color(0xFFFFC837).withValues(alpha: alpha * 0.40),
          const Color(0xFF4B83D6).withValues(alpha: alpha * 0.45),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: currentRadius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    canvas.drawCircle(center, currentRadius, paint);
  }

  @override
  bool shouldRepaint(covariant _EnergyRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// CustomPainter untuk gelombang aura cahaya lembut (soft aura wave)
/// yang meluas tanpa tepi garis tegas saat transisi latar belakang.
class _SoftAuraWavePainter extends CustomPainter {
  final double progress; // 0.0 -> 1.0

  _SoftAuraWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius =
        math.sqrt((size.width * size.width) + (size.height * size.height)) *
        0.58;
    final currentRadius = maxRadius * progress;
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    // Aura difus lembut dengan blur besar agar tidak membentuk garis batas
    final wavePaint = Paint()
      ..color = const Color(0xFF3CC3A6).withValues(alpha: alpha * 0.24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40.0);

    canvas.drawCircle(center, currentRadius, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _SoftAuraWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
