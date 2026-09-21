import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/auth_choice_page.dart';

/// Halaman Splash Screen PediaGrow.
///
/// Memenuhi rangkaian animasi splash screen:
/// 1. Layar biru awal (#295EA3).
/// 2. Lingkaran putih 100x100 (#FFFFFF) jatuh dari tengah atas ke tengah layar
///    dengan efek tetesan air bouncing, lalu membesar memenuhi seluruh layar.
/// 3. Layar berubah menjadi putih bersih (#FFFFFF).
/// 4. Logo PediaGrow timbul di tengah secara berurutan tanpa delay & tanpa warna keabu-abuan:
///    a. Daun (daun kanan hijau #3CC3A6 & daun kiri biru #4B83D6)
///    b. Lingkaran biru di bagian atas (lengkungan orbit #4B83D6)
///    c. Bayi (#FFAC3D / #FFDCAD)
///    d. Bintang (#FFF619 / #FAFF00)
/// 5. Logo dihilangkan dan digantikan tulisan nama aplikasi "PediaGrow"
///    (Baloo 2 Bold 50, "Pedia" #4B83D6, "Grow" #3CC3A6) di tengah layar.
/// 6. Setelah rangkaian selesai (atau di-tap untuk skip), otomatis berpindah ke [AuthChoicePage].
class SplashPage extends StatefulWidget {
  /// Durasi total rangkaian animasi otomatis splash screen.
  final Duration animationDuration;

  /// Mengizinkan tap pada layar untuk skip langsung ke halaman AuthChoicePage.
  final bool enableTapToSkip;

  const SplashPage({
    super.key,
    this.animationDuration = const Duration(milliseconds: 3800),
    this.enableTapToSkip = true,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  // Palet Warna Resmi PediaGrow
  static const Color colorPrimaryBlue = Color(0xFF295EA3); // Gambar 1 Background
  static const Color colorPediaBlue = Color(0xFF4B83D6); // Pedia & Left Leaf
  static const Color colorGrowGreen = Color(0xFF3CC3A6); // Grow & Right Leaf

  late AnimationController _controller;

  // Animasi Tahap 1 & 2: Lingkaran putih jatuh (droplet bounce) & expand
  late Animation<double> _dropAnim; // Dari atas ke tengah (bouncing)
  late Animation<double> _circleExpandAnim; // Dari ukuran 100 membesar ke seluruh layar

  // Animasi Tahap 4: Kemunculan logo bertahap (daun -> arch -> bayi -> bintang)
  late Animation<double> _logoLeavesAnim;
  late Animation<double> _logoArchAnim;
  late Animation<double> _logoBabyAnim;
  late Animation<double> _logoStarAnim;
  late Animation<double> _logoStarRotateAnim;

  // Animasi Tahap 5: Logo fade out & tulisan nama aplikasi "PediaGrow" muncul di tengah
  late Animation<double> _logoFadeOutAnim;
  late Animation<double> _titleFadeInAnim;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _initAnimations();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToAuthChoice();
      }
    });

    _controller.forward();
  }

  void _initAnimations() {
    // -------------------------------------------------------------------------
    // 1. TAHAP 1 & 2: Tetesan Air Putih Jatuh (0.00 -> 0.18) & Membesar (0.19 -> 0.32)
    // -------------------------------------------------------------------------
    _dropAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.02, 0.18, curve: Curves.bounceOut),
    );

    _circleExpandAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.19, 0.32, curve: Curves.easeInOutCubic),
    );

    // -------------------------------------------------------------------------
    // 2. TAHAP 4: Logo Timbul Bertahap per Elemen (0.35 -> 0.65)
    // -------------------------------------------------------------------------
    _logoLeavesAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.43, curve: Curves.easeOutBack),
    );

    _logoArchAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.43, 0.51, curve: Curves.easeOutBack),
    );

    _logoBabyAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.51, 0.59, curve: Curves.easeOutBack),
    );

    _logoStarAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.59, 0.67, curve: Curves.easeOutBack),
    );

    _logoStarRotateAnim = Tween<double>(begin: -0.4, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.59, 0.67, curve: Curves.easeOut),
      ),
    );

    // -------------------------------------------------------------------------
    // 3. TAHAP 5: Logo digantikan nama aplikasi "PediaGrow" di tengah (0.69 -> 0.85)
    // -------------------------------------------------------------------------
    _logoFadeOutAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.69, 0.75, curve: Curves.easeIn),
    );

    _titleFadeInAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.75, 0.88, curve: Curves.easeOutCubic),
    );
  }

  void _navigateToAuthChoice() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AuthChoicePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }


  void _skipToEnd() {
    if (widget.enableTapToSkip && !_hasNavigated) {
      _navigateToAuthChoice();
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

    return GestureDetector(
      onTap: _skipToEnd,
      child: Scaffold(
        backgroundColor: colorPrimaryBlue, // Layar Biru #295EA3 (Tahap 1)
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;

            // Background putih bersih penuh setelah lingkaran membesar
            final isWhiteBg = _circleExpandAnim.value >= 0.98;

            // Tampilkan logo bertahap di tengah (t antara 0.35 s.d 0.75)
            final showLogo = t >= 0.35 && t < 0.75;

            // Tampilkan judul PediaGrow di tengah layar (t >= 0.75)
            final showTitle = t >= 0.75;

            return Stack(
              children: [
                // -------------------------------------------------------------
                // 1 & 2 & 3: Circle Drop & Reveal (Lingkaran Putih #FFFFFF)
                // -------------------------------------------------------------
                if (!isWhiteBg)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DropletRevealPainter(
                        dropProgress: _dropAnim.value,
                        expandProgress: _circleExpandAnim.value,
                        circleColor: Colors.white,
                      ),
                    ),
                  )
                else
                  const Positioned.fill(child: ColoredBox(color: Colors.white)),

                // -------------------------------------------------------------
                // 4. Logo PediaGrow Bertahap di Tengah (Tahap 4)
                // -------------------------------------------------------------
                if (showLogo)
                  Center(
                    child: Opacity(
                      opacity: 1.0 - _logoFadeOutAnim.value,
                      child: _buildStaggeredLogo(size),
                    ),
                  ),

                // -------------------------------------------------------------
                // 5. Teks PediaGrow di Tengah Layar (Tahap 5)
                // -------------------------------------------------------------
                if (showTitle)
                  Center(
                    child: Opacity(
                      opacity: _titleFadeInAnim.value,
                      child: SizedBox(
                        width: math.min(size.width - 32, 260.0),
                        child: _buildPediaGrowTitle(50.0),
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

  /// Logo PediaGrow yang muncul secara bertahap per-elemen:
  /// 1. Daun
  /// 2. Lingkaran biru di bagian atas (orbit arch)
  /// 3. Bayi
  /// 4. Bintang
  Widget _buildStaggeredLogo(Size size) {
    final logoSize = math.min(size.width * 0.44, 195.0);

    return SizedBox(
      width: logoSize,
      height: logoSize,
      child: Stack(
        children: [
          // 1. Daun (Daun kanan hijau #3CC3A6 & Daun kiri biru #4B83D6)
          if (_logoLeavesAnim.value > 0.0)
            Positioned.fill(
              child: Transform.scale(
                scale: _logoLeavesAnim.value,
                alignment: Alignment.bottomCenter,
                child: Image.asset(
                  'assets/images/logo_leaves.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),

          // 2. Lingkaran biru di bagian atas (lengkungan orbit & node)
          if (_logoArchAnim.value > 0.0)
            Positioned.fill(
              child: Transform.scale(
                scale: _logoArchAnim.value,
                alignment: Alignment.topCenter,
                child: Image.asset(
                  'assets/images/logo_arch.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),

          // 3. Bayi (#FFAC3D / #FFDCAD)
          if (_logoBabyAnim.value > 0.0)
            Positioned.fill(
              child: Transform.scale(
                scale: _logoBabyAnim.value,
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/logo_baby.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),

          // 4. Bintang (#FFF619 / #FAFF00) dengan efek pop & twinkle
          if (_logoStarAnim.value > 0.0)
            Positioned.fill(
              child: Transform.rotate(
                angle: _logoStarRotateAnim.value,
                alignment: const Alignment(0.65, -0.65),
                child: Transform.scale(
                  scale: _logoStarAnim.value,
                  alignment: const Alignment(0.65, -0.65),
                  child: Image.asset(
                    'assets/images/logo_star.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Teks "PediaGrow" menggunakan font Baloo 2 Bold 50 dengan 2 warna resmi.
  Widget _buildPediaGrowTitle(double fontSize) {
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
              letterSpacing: -0.5,
            ),
          ),
          TextSpan(
            text: 'Grow',
            style: GoogleFonts.baloo2(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: colorGrowGreen, // #3CC3A6
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter untuk animasi:
/// 1. Tetesan lingkaran putih 100x100 jatuh dari tengah atas ke tengah (bouncing)
/// 2. Lingkaran putih membesar dari tengah hingga memenuhi seluruh layar
class _DropletRevealPainter extends CustomPainter {
  final double dropProgress; // 0.0 -> 1.0 (jatuh ke tengah)
  final double expandProgress; // 0.0 -> 1.0 (membesar ke seluruh layar)
  final Color circleColor;

  _DropletRevealPainter({
    required this.dropProgress,
    required this.expandProgress,
    required this.circleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = circleColor
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    const initialRadius = 50.0;

    if (expandProgress <= 0.0) {
      final startY = -initialRadius;
      final currentY = startY + (centerY - startY) * dropProgress;

      canvas.drawCircle(Offset(centerX, currentY), initialRadius, paint);
    } else {
      final maxRadius = math.sqrt(
        (size.width * size.width) + (size.height * size.height),
      );

      final currentRadius =
          initialRadius + (maxRadius - initialRadius) * expandProgress;

      canvas.drawCircle(Offset(centerX, centerY), currentRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DropletRevealPainter oldDelegate) {
    return oldDelegate.dropProgress != dropProgress ||
        oldDelegate.expandProgress != expandProgress ||
        oldDelegate.circleColor != circleColor;
  }
}
