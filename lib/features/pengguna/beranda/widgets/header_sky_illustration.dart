import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'forest_cloud_painter.dart';

/// Pilihan mode waktu langit pada header
enum SkyTimeMode {
  /// Mengikuti mode tema aplikasi / perangkat:
  /// - Light mode -> Matahari (day)
  /// - Dark mode  -> Bulan sabit (night)
  /// Aturan jam telah dihilangkan sepenuhnya.
  auto,

  /// Memaksa mode siang (matahari, burung, awan cerah)
  day,

  /// Memaksa mode malam (bulan sabit elegan, bintang berkelip, awan malam)
  night,
}

/// Widget ilustrasi pemandangan langit untuk Header Beranda
/// Menyediakan latar dinamis (siang / malam) dengan awan cumulus fluffy yang menyatu,
/// siluet burung terbang beranimasi lembut (sayap dan luncuran anggun),
/// matahari besar bercahaya / bulan sabit elegan, dan taburan bintang berkelip.
class HeaderSkyIllustration extends StatefulWidget {
  final SkyTimeMode mode;

  /// Apakah ingin merender gradasi langit utama di dalam widget ini
  final bool renderBackgroundGradient;

  const HeaderSkyIllustration({
    super.key,
    this.mode = SkyTimeMode.auto,
    this.renderBackgroundGradient = false,
  });

  /// Helper untuk mengecek apakah saat ini mode malam:
  /// - Jika [SkyTimeMode.auto], otomatis mengikuti apakah mode gelap (isDark) aktif.
  /// - Aturan jam perangkat (hour < 5 || hour >= 18) telah dihilangkan sepenuhnya.
  static bool checkIsNight([
    SkyTimeMode mode = SkyTimeMode.auto,
    bool isDark = false,
  ]) {
    if (mode == SkyTimeMode.day) return false;
    if (mode == SkyTimeMode.night) return true;
    return isDark;
  }

  /// Warna gradasi latar langit untuk siang hari (top to bottom):
  /// Biru langit cerah di atas yang meluruh secara bertahap dan menyatu mulus ke putih
  static const List<Color> dayGradientColors = [
    Color(0xFF5BA4F5), // 0.0:  Biru langit cerah di atas
    Color(0xFF4592F0), // 0.35: Biru tengah khas Pediagrow
    Color(0xFF6DA7F4), // 0.60: Biru transisi
    Color(0xFFB5D7FA), // 0.80: Biru pastel sangat lembut
    Color(0xFFEAF3FD), // 0.92: Biru keputihan
    Colors.white, // 1.0:  Putih murni 100% menyatu ke kartu & menu di bawahnya
  ];

  static const List<double> dayGradientStops = [
    0.0,
    0.35,
    0.60,
    0.80,
    0.92,
    1.0,
  ];

  /// Warna gradasi latar langit untuk malam hari (top to bottom):
  /// Midnight blue di atas yang meluruh lembut ke putih
  static const List<Color> nightGradientColors = [
    Color(0xFF0F172A), // 0.0:  Deep midnight blue
    Color(0xFF1E293B), // 0.35: Dark slate blue
    Color(0xFF1E3A8A), // 0.60: Indigo malam
    Color(0x5993C5FD), // 0.80: Soft sky glow
    Color(0xFFF1F5F9), // 0.92: Soft off-white
    Colors.white, // 1.0:  Putih murni 100% menyatu ke kartu & menu di bawahnya
  ];

  static const List<double> nightGradientStops = [
    0.0,
    0.35,
    0.60,
    0.80,
    0.92,
    1.0,
  ];

  /// Warna gradasi latar langit siang hari saat MODE GELAP aktif:
  /// Tetap biru langit cerah di atas (matahari tetap terlihat cerah di langit siang),
  /// lalu bertransisi mulus ke hitam pekat (#0B1014) tanpa ada putih tersisa.
  static const List<Color> dayGradientColorsDark = [
    Color(0xFF5BA4F5), // 0.0:  Biru langit cerah di atas
    Color(0xFF3B82F6), // 0.30: Biru cerah
    Color(0xFF1D4ED8), // 0.55: Biru transisi medium
    Color(0xFF1E3A8A), // 0.75: Biru tua pekat
    Color(0xFF0D1520), // 0.88: Biru malam sangat gelap menuju hitam
    Color(0xFF0B1014), // 1.0:  Hitam pekat menyatu sempurna ke background gelap
  ];

  /// Warna gradasi latar langit malam hari saat MODE GELAP aktif:
  /// Midnight blue elegan di atas meluruh mulus secara konsisten ke latar #0B1014,
  /// tanpa ada bagian yang lebih gelap atau melompat lebih terang.
  static const List<Color> nightGradientColorsDark = [
    Color(0xFF15222E), // 0.0:  Midnight navy lembut di atas
    Color(0xFF111B24), // 0.35: Slate malam gelap
    Color(0xFF0E151C), // 0.60: Transisi halus meluruh
    Color(0xFF0C1217), // 0.80: Mendekati latar gelap
    Color(0xFF0B1014), // 0.92: Latar gelap WhatsApp
    Color(0xFF0B1014), // 1.0:  Berakhir tepat di #0B1014
  ];

  /// Helper untuk mengambil list warna gradasi langit sesuai waktu dan tema
  static List<Color> getGradientColors({
    required bool isNight,
    required bool isDark,
  }) {
    if (isDark) {
      return isNight ? nightGradientColorsDark : dayGradientColorsDark;
    } else {
      return isNight ? nightGradientColors : dayGradientColors;
    }
  }

  static List<double> getGradientStops({
    required bool isNight,
    required bool isDark,
  }) {
    return isNight ? nightGradientStops : dayGradientStops;
  }

  @override
  State<HeaderSkyIllustration> createState() => _HeaderSkyIllustrationState();
}

class _HeaderSkyIllustrationState extends State<HeaderSkyIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _rotationController;
  late final AnimationController _birdWingController;
  late final AnimationController _birdFlightController;
  late final AnimationController _starController;

  late final Animation<double> _cloudDrift;
  late final Animation<double> _cloudFloat;
  late final Animation<double> _sunPulse;
  late final Animation<double> _birdWingFlap;
  late final Animation<double> _starPulse;

  @override
  void initState() {
    super.initState();

    // 1. Controller mengapung awan (4.5 detik, bolak-balik lembut & tenang)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat(reverse: true);

    _cloudDrift = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    _cloudFloat = Tween<double>(begin: -3.5, end: 3.5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutQuad),
    );

    _sunPulse = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    // 2. Controller rotasi lambat pendaran sinar matahari (24 detik)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    // 3. Controller kepakan sayap burung (1400ms per siklus, kepakan rileks dan alami)
    _birdWingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _birdWingFlap = Tween<double>(begin: -0.85, end: 0.85).animate(
      CurvedAnimation(parent: _birdWingController, curve: Curves.easeInOutSine),
    );

    // 4. Controller terbang meluncur burung (25 detik siklus bolak-balik lembut horizontal)
    _birdFlightController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat(reverse: true);

    // 5. Controller bintang berkelip (2200ms per siklus)
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _starPulse = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _starController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _rotationController.dispose();
    _birdWingController.dispose();
    _birdFlightController.dispose();
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Mengikuti aturan tema: jika Light Mode -> matahari (day), jika Dark Mode -> bulan (night)
    final isNight = widget.mode == SkyTimeMode.night ||
        (widget.mode == SkyTimeMode.auto && isDark);
    final topSafe = MediaQuery.paddingOf(context).top;

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background gradient jika diaktifkan di dalam widget
          if (widget.renderBackgroundGradient)
            Positioned.fill(
              child: DecoratedBox(
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
              ),
            ),

          // -----------------------------------------------------------
          // LAYER 1: AWAN LATAR BELAKANG (Di belakang Matahari/Bulan)
          // -----------------------------------------------------------

          // Awan 1 — Sudut Kiri Atas lembut (bingkai langit atas tanpa mengganggu teks sapaan)
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, _) {
              return Positioned(
                top: (topSafe * 0.15) + 2 - (_cloudFloat.value * 0.45),
                left: -26 - (_cloudDrift.value * 0.45),
                child: ForestCloudWidget(
                  width: 72,
                  height: 29,
                  isNight: isNight,
                  opacity: isNight ? 0.34 : 0.40,
                  flipHorizontal: true,
                  isHeader: true,
                  variant: ForestCloudVariant.asymmetric,
                ),
              );
            },
          ),

          // Awan 2 — Bahu Kiri Matahari/Bulan (kedalaman langit tengah-kanan)
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, _) {
              return Positioned(
                top: (topSafe * 0.25) + 14 + (_cloudFloat.value * 0.4),
                right: 112 - (_cloudDrift.value * 0.5),
                child: ForestCloudWidget(
                  width: 68,
                  height: 27,
                  isNight: isNight,
                  opacity: isNight ? 0.36 : 0.44,
                  flipHorizontal: true,
                  isHeader: true,
                  variant: ForestCloudVariant.compact,
                ),
              );
            },
          ),

          // -----------------------------------------------------------
          // LAYER 2: ELEMEN CELESTIAL UTAMA: MATAHARI (LIGHT) ATAU BULAN & BINTANG (DARK)
          // -----------------------------------------------------------
          if (!isNight) ...[
            // MATAHARI (Ukuran proporsional 82x82, memancarkan kehangatan ramah & cerah)
            AnimatedBuilder(
              animation: _floatController,
              builder: (context, _) {
                return Positioned(
                  top: 10 + (_cloudFloat.value * 0.4),
                  right: 52 + (_cloudDrift.value * 0.3),
                  child: AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, _) {
                      return _EnlargedSun(
                        pulseValue: _sunPulse.value,
                        rotateAngle: _rotationController.value * 2 * math.pi,
                      );
                    },
                  ),
                );
              },
            ),

            // SILUET BURUNG-BURUNG TERBANG (Siang hari: formasi kawanan alami dengan kepakan & luncuran anggun)
            AnimatedBuilder(
              animation: Listenable.merge([
                _birdWingController,
                _birdFlightController,
              ]),
              builder: (context, _) {
                final flightOffset =
                    (_birdFlightController.value - 0.5) * 36.0;
                final flightWave =
                    math.sin(_birdFlightController.value * math.pi * 2) * 3.5;

                // Fasa kepakan individual agar kawanan tidak mengepak kaku secara serempak
                final flap1 = _birdWingFlap.value;
                final flap2 = math.sin((_birdWingController.value + 0.28) * math.pi * 2);
                final flap3 = math.sin((_birdWingController.value + 0.62) * math.pi * 2);
                final flap4 = math.sin((_birdWingController.value + 0.82) * math.pi * 2);

                return Stack(
                  children: [
                    // Burung 1 (Pemimpin formasi — siluet aerodinamis tegap & dinamis)
                    Positioned(
                      top: 18 + (flap1 * 1.5) + flightWave,
                      right: 145 + flightOffset,
                      child: _FlyingBird(
                        width: 18.0,
                        height: 9.5,
                        wingState: flap1,
                        tiltAngle: -0.05 + (flap1 * 0.04),
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.42),
                      ),
                    ),
                    // Burung 2 (Mengikuti di belakang-atas burung 1)
                    Positioned(
                      top: 12 - (flap2 * 1.2) + (flightWave * 0.8),
                      right: 172 + (flightOffset * 0.9),
                      child: _FlyingBird(
                        width: 14.0,
                        height: 7.5,
                        wingState: flap2,
                        tiltAngle: 0.04 - (flap2 * 0.03),
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.32),
                      ),
                    ),
                    // Burung 3 (Burung yang meluncur di langit tengah)
                    Positioned(
                      top: 66 + (flap3 * 1.0) - (flightWave * 0.7),
                      left: 175 - (flightOffset * 0.8),
                      child: _FlyingBird(
                        width: 15.0,
                        height: 8.0,
                        wingState: flap3,
                        tiltAngle: -0.03,
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.28),
                      ),
                    ),
                    // Burung 4 (Burung mungil di kejauhan)
                    Positioned(
                      top: 42 + (flap4 * 0.8) + (flightWave * 0.5),
                      right: 215 + (flightOffset * 0.7),
                      child: _FlyingBird(
                        width: 11.0,
                        height: 6.0,
                        wingState: flap4,
                        tiltAngle: 0.02,
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.22),
                      ),
                    ),
                  ],
                );
              },
            ),
          ] else ...[
            // BULAN SABIT ELEGAN (Malam hari / Dark Mode: kurva presisi anggun & berpendar)
            AnimatedBuilder(
              animation: _floatController,
              builder: (context, _) {
                return Positioned(
                  top: 10 + (_cloudFloat.value * 0.4),
                  right: 52 + (_cloudDrift.value * 0.3),
                  child: _CrescentMoon(pulseValue: _sunPulse.value),
                );
              },
            ),

            // TABURAN BINTANG BERKELIP (Malam hari / Dark Mode: berkilau anggun dengan kilau kristal)
            AnimatedBuilder(
              animation: _starController,
              builder: (context, _) {
                final p = _starPulse.value;
                return Stack(
                  children: [
                    // Bintang 1 (Bintang senja terang, dekat bulan)
                    Positioned(
                      top: 24,
                      right: 124,
                      child: _TwinklingStar(
                        size: 9.0,
                        opacity: p,
                        rotation: 0.1,
                      ),
                    ),
                    // Bintang 2 (Bintang mungil di atas-kanan bulan)
                    Positioned(
                      top: 12,
                      right: 42,
                      child: _TwinklingStar(
                        size: 6.0,
                        opacity: (1.35 - p).clamp(0.2, 1.0),
                        rotation: -0.15,
                      ),
                    ),
                    // Bintang 3 (Di langit tengah, lembut)
                    Positioned(
                      top: 46,
                      right: 148,
                      child: _TwinklingStar(
                        size: 7.0,
                        opacity: p * 0.88,
                        rotation: 0.22,
                      ),
                    ),
                    // Bintang 4 (Di dekat transisi sapaan kiri)
                    Positioned(
                      top: 32,
                      left: 175,
                      child: _TwinklingStar(
                        size: 6.5,
                        opacity: (1.2 - p).clamp(0.25, 0.95),
                        rotation: -0.2,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],

          // -----------------------------------------------------------
          // LAYER 3: AWAN MENGAPUNG DEPAN (Drifting lembut tanpa menutupi wajah Bulan/Matahari)
          // -----------------------------------------------------------

          // Awan 3 — Sudut Kanan Atas (bingkai luar sebelah kanan Matahari/Bulan)
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, _) {
              return Positioned(
                top: (topSafe * 0.20) + 4 + (_cloudFloat.value * 0.55),
                right: -24 + _cloudDrift.value,
                child: ForestCloudWidget(
                  width: 84,
                  height: 33,
                  isNight: isNight,
                  opacity: isNight ? 0.44 : 0.56,
                  flipHorizontal: false,
                  isHeader: true,
                  variant: ForestCloudVariant.asymmetric,
                ),
              );
            },
          ),

          // Awan 4 — Saku Langit Kanan (ruang terbuka di samping "Profil Anak" & di atas kartu)
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, _) {
              return Positioned(
                top: (topSafe * 0.85) + 58 - (_cloudFloat.value * 0.4),
                right: 18 + (_cloudDrift.value * 0.6),
                child: ForestCloudWidget(
                  width: 108,
                  height: 38,
                  isNight: isNight,
                  opacity: isNight ? 0.46 : 0.62,
                  flipHorizontal: true,
                  isHeader: true,
                  variant: ForestCloudVariant.elongated,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// 1. MATAHARI BESAR BERCAHAYA (ENLARGED SUN WITH TAPERED ORGANIC RAYS)
// =====================================================================
class _EnlargedSun extends StatelessWidget {
  final double pulseValue;
  final double rotateAngle;

  const _EnlargedSun({required this.pulseValue, required this.rotateAngle});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: pulseValue,
      child: SizedBox(
        width: 82,
        height: 82,
        child: CustomPaint(
          painter: _EnlargedSunPainter(rotateAngle: rotateAngle),
        ),
      ),
    );
  }
}

class _EnlargedSunPainter extends CustomPainter {
  final double rotateAngle;

  const _EnlargedSunPainter({required this.rotateAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final rCore = size.width * 0.23;

    // 1. Multi-layered Ambient Solar Glow (Pendaran kehangatan fajar & siang hari)
    // 1a. Lapisan terluar: pendaran lembut luas (Golden Sunrise Ambience)
    final outerAura = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawCircle(center, rCore * 2.35, outerAura);

    // 1b. Lapisan tengah: korona emas hangat (Warm Corona Bloom)
    final midAura = Paint()
      ..color = const Color(0xFFFFE082).withValues(alpha: 0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(center, rCore * 1.80, midAura);

    // 1c. Lapisan dalam: pendaran putih-krem cerah (Radiant Inner Core Aura)
    final innerAura = Paint()
      ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.48)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, rCore * 1.35, innerAura);

    // 2. Sinar Matahari Organik Meruncing (12 Tapered Organic Rays)
    // Mengganti garis kaku dengan kelopak sinar meruncing yang anggun dan memudar ke luar
    const numRays = 12;
    for (int i = 0; i < numRays; i++) {
      final isLong = (i % 2 == 0);
      final rInner = rCore * 1.15;
      final rOuter = isLong ? (rCore * 1.82) : (rCore * 1.52);
      final rMid = (rInner + rOuter) * 0.52;

      final angle = rotateAngle + (i * 2 * math.pi) / numRays;
      final spanBase = isLong ? 0.075 : 0.052;
      final spanMid = spanBase * 1.18;

      final rayPath = Path();
      final p1 = Offset(
        cx + rInner * math.cos(angle - spanBase),
        cy + rInner * math.sin(angle - spanBase),
      );
      final p2 = Offset(
        cx + rMid * math.cos(angle - spanMid),
        cy + rMid * math.sin(angle - spanMid),
      );
      final pTip = Offset(
        cx + rOuter * math.cos(angle),
        cy + rOuter * math.sin(angle),
      );
      final p3 = Offset(
        cx + rMid * math.cos(angle + spanMid),
        cy + rMid * math.sin(angle + spanMid),
      );
      final p4 = Offset(
        cx + rInner * math.cos(angle + spanBase),
        cy + rInner * math.sin(angle + spanBase),
      );

      rayPath.moveTo(p1.dx, p1.dy);
      rayPath.quadraticBezierTo(p2.dx, p2.dy, pTip.dx, pTip.dy);
      rayPath.quadraticBezierTo(p3.dx, p3.dy, p4.dx, p4.dy);
      rayPath.close();

      final rayPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment(math.cos(angle), math.sin(angle)),
          end: Alignment(-math.cos(angle), -math.sin(angle)),
          colors: [
            (isLong ? const Color(0xFFFFB300) : const Color(0xFFFFCA28))
                .withValues(alpha: isLong ? 0.90 : 0.72),
            const Color(0xFFFFE082).withValues(alpha: isLong ? 0.65 : 0.45),
            const Color(0xFFFFF9C4).withValues(alpha: 0.10),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: rOuter))
        ..style = PaintingStyle.fill;

      canvas.drawPath(rayPath, rayPaint);
    }

    // 3. Inti Matahari 3D Spherical (5-Stop Radial Shading yang Mewah & Ceria)
    const coreGradient = RadialGradient(
      center: Alignment(-0.25, -0.25),
      colors: [
        Color(0xFFFFFFFF), // 0.00: Sorotan kristal putih di pusat
        Color(0xFFFFF9C4), // 0.28: Krem terang bercahaya
        Color(0xFFFFEE58), // 0.60: Kuning cerah matahari khas anak-anak
        Color(0xFFFFCA28), // 0.84: Emas hangat
        Color(0xFFFF9800), // 1.00: Nuansa oranye fajar di tepi memberi kedalaman bola 3D
      ],
      stops: [0.0, 0.28, 0.60, 0.84, 1.0],
    );

    final corePaint = Paint()
      ..shader = coreGradient.createShader(
        Rect.fromCircle(center: center, radius: rCore),
      );
    canvas.drawCircle(center, rCore, corePaint);

    // 4. Gloss specular lengkung halus di kuadran kiri-atas inti matahari
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: rCore)));
    final glossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.42)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    final glossCenter = Offset(cx - rCore * 0.35, cy - rCore * 0.35);
    canvas.drawCircle(glossCenter, rCore * 0.50, glossPaint);
    canvas.restore();

    // 5. Partikel Debu Surya / Sparkle Emas Mikro di sekeliling matahari
    for (int j = 0; j < 3; j++) {
      final sAngle = rotateAngle * 1.5 + (j * (2 * math.pi / 3));
      final sR = rCore * 1.36;
      final sx = cx + sR * math.cos(sAngle);
      final sy = cy + sR * math.sin(sAngle);
      final sSize = 4.0 + (j * 0.8);

      final sparkPath = Path();
      sparkPath.moveTo(sx, sy - sSize * 0.5);
      sparkPath.quadraticBezierTo(sx, sy, sx + sSize * 0.5, sy);
      sparkPath.quadraticBezierTo(sx, sy, sx, sy + sSize * 0.5);
      sparkPath.quadraticBezierTo(sx, sy, sx - sSize * 0.5, sy);
      sparkPath.quadraticBezierTo(sx, sy, sx, sy - sSize * 0.5);
      sparkPath.close();

      canvas.drawPath(
        sparkPath,
        Paint()
          ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.60)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EnlargedSunPainter oldDelegate) =>
      oldDelegate.rotateAngle != rotateAngle;
}

// =====================================================================
// 2. BULAN SABIT ELEGAN (CRESCENT MOON WITH LUNAR HALO & CRATERS)
// =====================================================================
class _CrescentMoon extends StatelessWidget {
  final double pulseValue;

  const _CrescentMoon({required this.pulseValue});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: pulseValue,
      child: SizedBox(
        width: 76,
        height: 76,
        child: CustomPaint(painter: _CrescentMoonPainter()),
      ),
    );
  }
}

class _CrescentMoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);

    // 1. Pendaran Lembut Multi-Stage Cahaya Bulan (Dreamy Celestial & Lunar Glow)
    // 1a. Lapisan terluar: pendaran lembut lavender-malam (Deep Midnight Halo)
    final outerHalo = Paint()
      ..color = const Color(0xFF818CF8).withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, size.width * 0.46, outerHalo);

    // 1b. Lapisan tengah: pendaran perak-biru (Azure Moonlight Radiance)
    final midGlow = Paint()
      ..color = const Color(0xFF93C5FD).withValues(alpha: 0.26)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, size.width * 0.36, midGlow);

    // 1c. Lapisan dalam: kehangatan cahaya bulan gading (Warm Lunar Corona)
    final innerCorona = Paint()
      ..color = const Color(0xFFFEF3C7).withValues(alpha: 0.40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, size.width * 0.27, innerCorona);

    // 2. Bentuk Bulan Sabit Matematika Presisi (Golden Ratio Crescent)
    final rOuter = size.width * 0.31;
    final outerPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: rOuter));

    final rInner = rOuter * 0.91;
    final innerCenter = Offset(
      center.dx - rOuter * 0.38,
      center.dy - rOuter * 0.16,
    );
    final innerPath = Path()
      ..addOval(Rect.fromCircle(center: innerCenter, radius: rInner));

    final crescentPath = Path.combine(
      PathOperation.difference,
      outerPath,
      innerPath,
    );

    // 3. Gradient Warna Bulan Sabit (Kristal Perak Luminous -> Krem Gading -> Emas Madu)
    const moonGradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Color(0xFFFFFFFF), // Sorotan kristal putih di punggung lengkungan
        Color(0xFFFFFDE7), // Krem gading hangat
        Color(0xFFFEF08A), // Emas moonlight pastel lembut
        Color(0xFFFBBF24), // Emas madu hangat di bayang-dalam
      ],
      stops: [0.0, 0.26, 0.65, 1.0],
    );

    final moonPaint = Paint()
      ..shader = moonGradient.createShader(
        Rect.fromCircle(center: center, radius: rOuter),
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(crescentPath, moonPaint);

    // 4. Highlight Tepi Kurva Luar (Specular Rim Light yang Lembut)
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.save();
    canvas.clipPath(crescentPath);
    canvas.drawOval(Rect.fromCircle(center: center, radius: rOuter), rimPaint);

    // 5. Kawah Bulan Ilustratif Berdimensi (3 Stylized Storybook Craters)
    void drawCrater(Offset pos, double r) {
      // Dasar kawah yang berbayang lembut
      final shadow = Paint()
        ..color = const Color(0xFF334155).withValues(alpha: 0.16)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);
      canvas.drawCircle(pos, r, shadow);

      // Bibir kawah atas yang memantulkan cahaya
      final rim = Paint()
        ..color = Colors.white.withValues(alpha: 0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawArc(
        Rect.fromCircle(center: pos, radius: r),
        math.pi * 1.1,
        math.pi * 0.8,
        false,
        rim,
      );
    }

    drawCrater(Offset(center.dx + rOuter * 0.26, center.dy + rOuter * 0.18), rOuter * 0.13);
    drawCrater(Offset(center.dx + rOuter * 0.14, center.dy - rOuter * 0.22), rOuter * 0.09);
    drawCrater(Offset(center.dx + rOuter * 0.04, center.dy + rOuter * 0.42), rOuter * 0.08);

    canvas.restore();

    // 6. Bintang Mungil Pendamping yang Menggantung di Puncak Sabit
    final starX = center.dx - rOuter * 0.35;
    final starY = center.dy - rOuter * 0.65;
    const sSize = 5.0;
    final starPath = Path();
    starPath.moveTo(starX, starY - sSize * 0.5);
    starPath.quadraticBezierTo(starX, starY, starX + sSize * 0.5, starY);
    starPath.quadraticBezierTo(starX, starY, starX, starY + sSize * 0.5);
    starPath.quadraticBezierTo(starX, starY, starX - sSize * 0.5, starY);
    starPath.quadraticBezierTo(starX, starY, starX, starY - sSize * 0.5);
    starPath.close();

    canvas.drawCircle(
      Offset(starX, starY),
      sSize * 0.7,
      Paint()
        ..color = const Color(0xFFFEF08A).withValues(alpha: 0.60)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    canvas.drawPath(
      starPath,
      Paint()..color = Colors.white..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =====================================================================
// 3. BINTANG BERKELIP (TWINKLING STAR WITH DIAMOND SPARKLE)
// =====================================================================
class _TwinklingStar extends StatelessWidget {
  final double size;
  final double opacity;
  final double rotation;

  const _TwinklingStar({
    required this.size,
    required this.opacity,
    this.rotation = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget star = Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _StarPainter()),
      ),
    );

    if (rotation != 0.0) {
      star = Transform.rotate(angle: rotation, child: star);
    }

    return star;
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);

    // 1. Pendaran lembut bintang (Warm Celestial Bloom)
    final glow = Paint()
      ..color = const Color(0xFFFEF08A).withValues(alpha: 0.62)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.8);
    canvas.drawCircle(center, size.width * 0.40, glow);

    // 2. Kilau Berlian Anamorfik (Vertical Sparkle Lens Flare)
    final pinch = size.width * 0.14;
    final starPath = Path()
      ..moveTo(cx, 0)
      ..quadraticBezierTo(cx + pinch, cy - pinch, size.width, cy)
      ..quadraticBezierTo(cx + pinch, cy + pinch, cx, size.height)
      ..quadraticBezierTo(cx - pinch, cy + pinch, 0, cy)
      ..quadraticBezierTo(cx - pinch, cy - pinch, cx, 0)
      ..close();

    final starPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(starPath, starPaint);

    // 3. Inti kristal berkilau di tengah
    canvas.drawCircle(center, size.width * 0.16, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Awan kini dirender via [ForestCloudWidget] di forest_cloud_painter.dart agar senada dengan PNG forest.

// =====================================================================
// 5. SILUET BURUNG TERBANG (AERODYNAMIC SILHOUETTE WITH FLAP & GLIDE)
// =====================================================================
class _FlyingBird extends StatelessWidget {
  final double width;
  final double height;
  final double wingState;
  final Color color;
  final double tiltAngle;

  const _FlyingBird({
    required this.width,
    required this.height,
    required this.wingState,
    required this.color,
    this.tiltAngle = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget bird = SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _BirdPainter(wingState: wingState, color: color),
      ),
    );

    if (tiltAngle != 0.0) {
      bird = Transform.rotate(angle: tiltAngle, child: bird);
    }

    return bird;
  }
}

class _BirdPainter extends CustomPainter {
  final double wingState;
  final Color color;

  const _BirdPainter({required this.wingState, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;

    // Menghitung posisi lengkung sayap berdasarkan wingState (-1.0 sayap atas, +1.0 sayap bawah)
    final tipY = h * 0.36 + (wingState * h * 0.34);
    final elbowY = h * 0.26 + (wingState * h * 0.18);

    final path = Path();
    // Paruh & Kepala halus
    path.moveTo(cx, h * 0.22);

    // Sayap kiri: Bahu -> Siku (Elbow) -> Ujung Sayap (Tip)
    path.quadraticBezierTo(cx - w * 0.10, h * 0.28, cx - w * 0.26, elbowY);
    path.quadraticBezierTo(cx - w * 0.38, tipY - h * 0.06, 0, tipY);

    // Tepi belakang sayap kiri (Trailing edge dengan kontur bulu sekunder yang meruncing aerodinamis)
    path.quadraticBezierTo(
      cx - w * 0.32,
      tipY + h * 0.22,
      cx - w * 0.07,
      h * 0.58,
    );

    // Pinggul kiri ke ujung ekor kipas (Tail fan)
    path.lineTo(cx - w * 0.05, h * 0.78);
    path.quadraticBezierTo(cx, h * 0.90, cx + w * 0.05, h * 0.78);

    // Pinggul kanan
    path.lineTo(cx + w * 0.07, h * 0.58);

    // Tepi belakang sayap kanan
    path.quadraticBezierTo(
      cx + w * 0.32,
      tipY + h * 0.22,
      w,
      tipY,
    );

    // Sayap kanan: Ujung Sayap -> Siku -> Bahu -> Kepala
    path.quadraticBezierTo(cx + w * 0.38, tipY - h * 0.06, cx + w * 0.26, elbowY);
    path.quadraticBezierTo(cx + w * 0.10, h * 0.28, cx, h * 0.22);
    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BirdPainter oldDelegate) =>
      oldDelegate.wingState != wingState || oldDelegate.color != color;
}
