import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Halaman Splash Screen 8 Tahap PediaGrow.
///
/// Memenuhi spesifikasi transisi yang disempurnakan:
/// 1. Layar biru awal (#295EA3).
/// 2. Lingkaran putih 100x100 (#FFFFFF) jatuh dari tengah atas ke tengah layar
///    dengan efek tetesan air bouncing, lalu membesar memenuhi seluruh layar.
/// 3. Layar berubah menjadi putih bersih (#FFFFFF).
/// 4. Logo PediaGrow timbul di tengah secara berurutan tanpa delay & tanpa warna keabu-abuan:
///    a. Daun (daun kanan hijau #3CC3A6 & daun kiri biru #4B83D6)
///    b. Lingkaran biru di bagian atas (lengkungan orbit #4B83D6)
///    c. Bayi (#FFAC3D / #FFDCAD)
///    d. Bintang (#FFF619 / #FAFF00)
/// 5. Logo dihilangkan langsung dan digantikan tulisan nama aplikasi "PediaGrow"
///    (Baloo 2 Bold 50, "Pedia" #4B83D6, "Grow" #3CC3A6) di tengah layar.
/// 6. Tulisan "PediaGrow" bergerak naik ke atas (kecepatan 500 ms).
/// 7. Tagline (Lato regular 18), tombol Masuk, tombol Daftar Akun Baru (350x52, Lato bold 20),
///    dan ilustrasi keluarga muncul dari transparan hingga 100% terlihat.
/// 8. Tampilan 100% lengkap & compact untuk Android tanpa scroll. Klik tombol langsung
///    berpindah ke halaman selanjutnya tanpa popup pilihan role.
class SplashPage extends StatefulWidget {
  /// Callback saat tombol "Masuk" ditekan.
  final VoidCallback? onLoginPressed;

  /// Callback saat tombol "Daftar Akun Baru" ditekan.
  final VoidCallback? onRegisterPressed;

  /// Durasi total rangkaian animasi otomatis.
  final Duration animationDuration;

  /// Mengizinkan tap pada layar untuk mempercepat/skip langsung ke Tahap 8 (saat dev/testing).
  final bool enableTapToSkip;

  const SplashPage({
    super.key,
    this.onLoginPressed,
    this.onRegisterPressed,
    this.animationDuration = const Duration(milliseconds: 4400),
    this.enableTapToSkip = true,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  // Palet Warna Resmi PediaGrow
  static const Color colorPrimaryBlue = Color(
    0xFF295EA3,
  ); // Gambar 1 Background
  static const Color colorPediaBlue = Color(0xFF4B83D6); // Pedia & Left Leaf
  static const Color colorGrowGreen = Color(0xFF3CC3A6); // Grow & Right Leaf
  static const Color colorButtonPrimary = Color(0xFF3985E7); // Tombol Masuk
  static const Color colorTextDark = Color(0xFF1E293B); // Tagline text

  late AnimationController _controller;

  // Animasi Tahap 1 & 2: Lingkaran putih jatuh (droplet bounce) & expand
  late Animation<double> _dropAnim; // Dari atas ke tengah (bouncing)
  late Animation<double>
  _circleExpandAnim; // Dari ukuran 100 membesar ke seluruh layar

  // Animasi Tahap 4: Kemunculan logo bertahap (daun -> arch -> bayi -> bintang)
  late Animation<double> _logoLeavesAnim;
  late Animation<double> _logoArchAnim;
  late Animation<double> _logoBabyAnim;
  late Animation<double> _logoStarAnim;
  late Animation<double> _logoStarRotateAnim;

  // Animasi Tahap 5, 6, 7, 8
  late Animation<double> _titleSlideUpAnim; // Naik ke atas dalam 500ms
  late Animation<double>
  _finalContentFadeAnim; // Tagline, buttons, illustration fade in

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _initAnimations();
    _controller.forward();
  }

  void _initAnimations() {
    // -------------------------------------------------------------------------
    // 1. TAHAP 1 & 2: Tetesan Air Putih Jatuh (0.00 -> 0.16) & Membesar (0.16 -> 0.28)
    // -------------------------------------------------------------------------
    // Lingkaran 100x100 jatuh dari tengah atas ke tengah dengan kurva bouncing
    _dropAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.02, 0.16, curve: Curves.bounceOut),
    );

    // Setelah jatuh ke tengah, lingkaran bergerak membesar memenuhi layar
    _circleExpandAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.17, 0.28, curve: Curves.easeInOutCubic),
    );

    // -------------------------------------------------------------------------
    // 2. TAHAP 4: Logo Timbul Bertahap per Elemen (0.32 -> 0.58)
    // -------------------------------------------------------------------------
    // Elemen 1: Daun (Hijau & Biru) muncul pertama
    _logoLeavesAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.32, 0.39, curve: Curves.easeOutBack),
    );

    // Elemen 2: Lingkaran biru di bagian atas (lengkungan orbit) muncul kedua
    _logoArchAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.39, 0.46, curve: Curves.easeOutBack),
    );

    // Elemen 3: Bayi muncul ketiga
    _logoBabyAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.46, 0.53, curve: Curves.easeOutBack),
    );

    // Elemen 4: Bintang muncul terakhir dengan efek pop & twinkle
    _logoStarAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.53, 0.60, curve: Curves.easeOutBack),
    );

    _logoStarRotateAnim = Tween<double>(begin: -0.4, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.53, 0.60, curve: Curves.easeOut),
      ),
    );

    // -------------------------------------------------------------------------
    // 3. TAHAP 6: Tulisan "PediaGrow" naik ke atas (durasi 500ms: 0.68 -> 0.79)
    // -------------------------------------------------------------------------
    _titleSlideUpAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.68, 0.79, curve: Curves.easeInOutCubic),
    );

    // -------------------------------------------------------------------------
    // 4. TAHAP 7 -> 8: Tagline, Button Masuk, Button Daftar, dan Ilustrasi (0.79 -> 0.95)
    // -------------------------------------------------------------------------
    _finalContentFadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.79, 0.94, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _skipToEnd() {
    if (widget.enableTapToSkip && !_controller.isCompleted) {
      _controller.animateTo(1.0, duration: const Duration(milliseconds: 250));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    return GestureDetector(
      onTap: _skipToEnd,
      child: Scaffold(
        backgroundColor: colorPrimaryBlue, // Layar Biru #295EA3 (Tahap 1)
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;

            // Apakah background sudah menjadi putih penuh?
            final isWhiteBg = _circleExpandAnim.value >= 0.98;

            // Apakah logo sedang aktif ditampilkan? (Tahap 4: t in 0.30 .. 0.64)
            final showLogo = t >= 0.30 && t < 0.64;

            // Apakah teks PediaGrow sudah muncul? (Tahap 5, 6, 7, 8: t >= 0.64)
            final showTitle = t >= 0.64;

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
                  // Background putih bersih penuh
                  const Positioned.fill(child: ColoredBox(color: Colors.white)),

                // -------------------------------------------------------------
                // 4. Logo PediaGrow Bertahap di Tengah (Tahap 4)
                // -------------------------------------------------------------
                if (showLogo) Center(child: _buildStaggeredLogo(size)),

                // -------------------------------------------------------------
                // 5, 6, 7, 8: Teks PediaGrow, Tagline, Tombol & Ilustrasi
                // -------------------------------------------------------------
                if (showTitle)
                  Positioned.fill(
                    child: _buildMainContent(
                      size: size,
                      topPadding: topPadding,
                      bottomPadding: bottomPadding,
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
  /// 2. Lingkaran biru di bagian atas
  /// 3. Bayi
  /// 4. Bintang
  ///
  /// Tanpa delay, tanpa filter keabu-abuan, warna 100% tajam dan jernih.
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

  /// Membangun konten utama sesuai acuan penempatan baru:
  /// 1. Letak logo/judul PediaGrow : dari kiri +- 94 dp, dari atas +- 135 dp, lebar +- 228 dp, tinggi +- 33 dp
  /// 2. Letak tagline : dari kiri +- 84 dp, dari atas +- 225 dp, lebar +- 261 dp, tinggi +- 33 dp
  /// 3. Letak tombol Masuk : dari kiri +- 27 dp, dari atas +- 335 dp, lebar +- 350-370 dp, tinggi +- 51-52 dp
  /// 4. Letak tombol Daftar Akun Baru : dari kiri +- 27 dp, dari atas +- 406 dp, lebar +- 350-370 dp, tinggi +- 51-52 dp
  /// 5. Letak ilustrasi keluarga : dari kiri +- 0 dp, dari atas +- 600 dp, lebar +- 412 dp, tinggi +- 292 dp
  Widget _buildMainContent({
    required Size size,
    required double topPadding,
    required double bottomPadding,
  }) {
    final screenW = size.width;
    final screenH = size.height;

    // Skala vertikal adaptif agar compact pada HP Android berlayar pendek (< 800dp)
    // dan pas tepat pada acuan penempatan dp di layar standar (~892dp - 915dp)
    final bool isCompact = screenH < 780;
    final double vScale = isCompact ? (screenH / 840.0) : 1.0;

    // Posisi awal judul di tengah layar (Tahap 5)
    final double centerTitleY = (screenH / 2) - 30;

    // Posisi akhir judul (Tahap 6, 7, 8): diturunkan ke acuan +- 135 dp
    final double targetTitleY = math.max(topPadding + 20.0, 135.0 * vScale);

    // Perhitungan posisi Y saat ini (animasi naik 500 ms)
    final double currentTitleY = Tween<double>(
      begin: centerTitleY,
      end: targetTitleY,
    ).evaluate(_titleSlideUpAnim);

    // Posisi Y elemen berikutnya mengikuti judul yang diturunkan:
    final double taglineY =
        currentTitleY + (90.0 * vScale); // +- 225 dp (135 + 90)
    final double masukY = currentTitleY + (200.0 * vScale); // +- 335 dp
    final double daftarY = currentTitleY + (271.0 * vScale); // +- 406 dp

    // Lebar tombol responsif (target 350 dp, aman di layar kecil)
    final double buttonWidth = math.min(350.0, screenW - 32.0);

    return Stack(
      children: [
        // ---------------------------------------------------------------------
        // 5. ILUSTRASI KELUARGA DI BAGIAN BAWAH
        // ---------------------------------------------------------------------
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Opacity(
            opacity: _finalContentFadeAnim.value,
            child: _buildFamilyIllustration(size, vScale),
          ),
        ),

        // ---------------------------------------------------------------------
        // 1. JUDUL PEDIA GROW (Baloo 2 Bold 50, "Pedia" #4B83D6, "Grow" #3CC3A6)
        // ---------------------------------------------------------------------
        Positioned(
          top: currentTitleY,
          left: 0,
          right: 0,
          child: Center(
            child: SizedBox(
              width: math.min(screenW - 32, 260.0),
              child: _buildPediaGrowTitle(isCompact ? 44.0 : 50.0),
            ),
          ),
        ),

        // ---------------------------------------------------------------------
        // 2. TAGLINE DI BAWAH JUDUL (Lato Regular 18)
        // ---------------------------------------------------------------------
        Positioned(
          top: taglineY,
          left: 0,
          right: 0,
          child: Opacity(
            opacity: _finalContentFadeAnim.value,
            child: Center(
              child: SizedBox(
                width: math.min(screenW - 32, 280.0),
                child: Text(
                  'Pantau Pertumbuhan, Cegah Stunting\nUntuk Masa Depan',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: isCompact ? 15.5 : 18.0,
                    fontWeight: FontWeight.normal,
                    height: 1.35,
                    color: colorTextDark,
                  ),
                ),
              ),
            ),
          ),
        ),

        // ---------------------------------------------------------------------
        // 3. TOMBOL MASUK (350x52, #3985E7, Lato Bold 20 Putih)
        // ---------------------------------------------------------------------
        Positioned(
          top: masukY,
          left: 0,
          right: 0,
          child: Opacity(
            opacity: _finalContentFadeAnim.value,
            child: Center(
              child: _buildPrimaryButton(
                text: 'Masuk',
                width: buttonWidth,
                height: 52.0,
                backgroundColor: colorButtonPrimary,
                textColor: Colors.white,
                onPressed: _controller.isCompleted
                    ? (widget.onLoginPressed ?? _defaultLoginAction)
                    : null,
              ),
            ),
          ),
        ),

        // ---------------------------------------------------------------------
        // 4. TOMBOL DAFTAR AKUN BARU (350x52, Putih border #3985E7, Lato Bold 20)
        // ---------------------------------------------------------------------
        Positioned(
          top: daftarY,
          left: 0,
          right: 0,
          child: Opacity(
            opacity: _finalContentFadeAnim.value,
            child: Center(
              child: _buildSecondaryButton(
                text: 'Daftar Akun Baru',
                width: buttonWidth,
                height: 52.0,
                borderColor: colorButtonPrimary,
                textColor: colorButtonPrimary,
                backgroundColor: Colors.white,
                onPressed: _controller.isCompleted
                    ? (widget.onRegisterPressed ?? _defaultRegisterAction)
                    : null,
              ),
            ),
          ),
        ),
      ],
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

  /// Tombol Masuk (dimensi 350x52, font Lato bold 20, warna #3985E7).
  Widget _buildPrimaryButton({
    required String text,
    required double width,
    required double height,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shadowColor: backgroundColor.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  /// Tombol Daftar Akun Baru (dimensi 350x52, font Lato bold 20, stroke #3985E7).
  Widget _buildSecondaryButton({
    required String text,
    required double width,
    required double height,
    required Color borderColor,
    required Color textColor,
    required Color backgroundColor,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          side: BorderSide(color: borderColor, width: 1.8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  /// Ilustrasi Keluarga di bagian bawah layar (lebar 412, tinggi +- 292 dp).
  Widget _buildFamilyIllustration(Size size, double vScale) {
    final double illustH = math.min(292.0 * vScale, size.height * 0.35);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Image.asset(
        'assets/images/family_illustration.png',
        width: size.width,
        height: illustH,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/design_reference/splash_screen/8.png',
            width: size.width,
            height: illustH,
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action Handlers (Langsung navigasi tanpa popup pemilihan role)
  // ---------------------------------------------------------------------------

  void _defaultLoginAction() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Membuka halaman Masuk...'),
        backgroundColor: colorButtonPrimary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _defaultRegisterAction() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Membuka halaman Pendaftaran Akun Baru...'),
        backgroundColor: colorButtonPrimary,
        duration: Duration(seconds: 2),
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

    // Radius awal lingkaran putih = 50 (diameter 100)
    const initialRadius = 50.0;

    if (expandProgress <= 0.0) {
      // Tahap 1 & 2a: Lingkaran jatuh dari atas ke tengah
      // Posisi Y awal: -initialRadius (di luar layar atas)
      // Posisi Y akhir: centerY (tengah layar)
      final startY = -initialRadius;
      final currentY = startY + (centerY - startY) * dropProgress;

      canvas.drawCircle(Offset(centerX, currentY), initialRadius, paint);
    } else {
      // Tahap 2b: Lingkaran di tengah membesar untuk memenuhi seluruh layar
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
