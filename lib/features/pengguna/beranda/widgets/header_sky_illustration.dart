import 'dart:math' as math;

import 'package:flutter/material.dart';

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

          // Awan 2 — Sudut Kiri Atas (di belakang sapaan "Hai, Susanti")
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, _) {
              return Positioned(
                top: 8 - (_cloudFloat.value * 0.5),
                left: -20 - (_cloudDrift.value * 0.5),
                child: _CumulusCloud(
                  width: 78,
                  height: 32,
                  isNight: isNight,
                  opacity: isNight ? 0.35 : 0.55,
                  flipHorizontal: true,
                ),
              );
            },
          ),

          // Awan 4 — Kiri Tengah (di belakang teks "Profil Anak", lembut & tipis)
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, _) {
              return Positioned(
                top: 96 + (_cloudFloat.value * 0.5),
                left: -15 + (_cloudDrift.value * 0.4),
                child: _CumulusCloud(
                  width: 82,
                  height: 34,
                  isNight: isNight,
                  opacity: isNight ? 0.22 : 0.38,
                  flipHorizontal: false,
                ),
              );
            },
          ),

          // Awan 5 — Kanan Bawah (di belakang sisi kanan kartu, transisi lembut)
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, _) {
              return Positioned(
                bottom: 12 + (_cloudFloat.value * 0.4),
                right: 16 + (_cloudDrift.value * 0.5),
                child: _CumulusCloud(
                  width: 90,
                  height: 38,
                  isNight: isNight,
                  opacity: isNight ? 0.20 : 0.35,
                  flipHorizontal: true,
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

            // SILUET BURUNG-BURUNG TERBANG (Siang hari: meluncur tenang dengan kepakan sayap alami)
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

                return Stack(
                  children: [
                    // Burung 1 (Pemimpin formasi)
                    Positioned(
                      top: 18 + (_birdWingFlap.value * 1.5) + flightWave,
                      right: 145 + flightOffset,
                      child: _FlyingBird(
                        width: 16,
                        height: 8.5,
                        wingState: _birdWingFlap.value,
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.38),
                      ),
                    ),
                    // Burung 2 (Mengikuti di belakang-atas burung 1)
                    Positioned(
                      top: 12 - (_birdWingFlap.value * 1.2) + (flightWave * 0.8),
                      right: 172 + (flightOffset * 0.9),
                      child: _FlyingBird(
                        width: 12.5,
                        height: 6.5,
                        wingState: -_birdWingFlap.value * 0.9,
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.30),
                      ),
                    ),
                    // Burung 3 (Burung kecil yang meluncur di langit tengah)
                    Positioned(
                      top: 66 + (_birdWingFlap.value * 1.0) - (flightWave * 0.7),
                      left: 175 - (flightOffset * 0.8),
                      child: _FlyingBird(
                        width: 13.5,
                        height: 7.0,
                        wingState: _birdWingFlap.value * 0.85,
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.26),
                      ),
                    ),
                    // Burung 4 (Burung mungil di kejauhan)
                    Positioned(
                      top: 42 + (_birdWingFlap.value * 0.8) + (flightWave * 0.5),
                      right: 215 + (flightOffset * 0.7),
                      child: _FlyingBird(
                        width: 10.0,
                        height: 5.5,
                        wingState: -_birdWingFlap.value * 0.8,
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.20),
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

            // TABURAN BINTANG BERKELIP (Malam hari / Dark Mode: berkilau anggun di langit terbuka)
            AnimatedBuilder(
              animation: _starController,
              builder: (context, _) {
                return Stack(
                  children: [
                    // Bintang 1 (Bintang senja terang, dekat bulan)
                    Positioned(
                      top: 24,
                      right: 124,
                      child: _TwinklingStar(size: 8.5, opacity: _starPulse.value),
                    ),
                    // Bintang 2 (Bintang mungil di atas-kanan bulan)
                    Positioned(
                      top: 12,
                      right: 42,
                      child: _TwinklingStar(
                        size: 5.5,
                        opacity: (1.35 - _starPulse.value).clamp(0.2, 1.0),
                      ),
                    ),
                    // Bintang 3 (Di langit tengah, lembut)
                    Positioned(
                      top: 46,
                      right: 148,
                      child: _TwinklingStar(
                        size: 6.5,
                        opacity: _starPulse.value * 0.85,
                      ),
                    ),
                    // Bintang 4 (Di dekat transisi sapaan kiri)
                    Positioned(
                      top: 32,
                      left: 175,
                      child: _TwinklingStar(
                        size: 6.0,
                        opacity: (1.2 - _starPulse.value).clamp(0.25, 0.95),
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

          // Awan 1 — Sudut Kanan Atas (tepi luar kanan)
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, _) {
              return Positioned(
                top: 2 + (_cloudFloat.value * 0.6),
                right: -24 + _cloudDrift.value,
                child: _CumulusCloud(
                  width: 86,
                  height: 36,
                  isNight: isNight,
                  opacity: isNight ? 0.28 : 0.60,
                  flipHorizontal: false,
                ),
              );
            },
          ),

          // Awan 3 — Tengah Atas (antara sapaan dan matahari)
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, _) {
              return Positioned(
                top: 48 - (_cloudFloat.value * 0.4),
                right: -10 + (_cloudDrift.value * 0.6),
                child: _CumulusCloud(
                  width: 74,
                  height: 32,
                  isNight: isNight,
                  opacity: isNight ? 0.26 : 0.50,
                  flipHorizontal: true,
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
// 1. MATAHARI BESAR BERCAHAYA (ENLARGED SUN)
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

    // 1. Multi-layered Ambient Glow (Pendaran cahaya luar yang hangat dan luas)
    final outerAura = Paint()
      ..color = const Color(0xFFFFE082).withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(center, rCore * 1.95, outerAura);

    final midAura = Paint()
      ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.42)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, rCore * 1.50, midAura);

    // 2. Pancaran sinar matahari bergantian (12 Sinar: 6 Utama Panjang & 6 Sekunder Pendek)
    const numRays = 12;
    for (int i = 0; i < numRays; i++) {
      final isLong = (i % 2 == 0);
      final rayPaint = Paint()
        ..color = isLong
            ? const Color(0xFFFFCA28).withValues(alpha: 0.88)
            : const Color(0xFFFFE082).withValues(alpha: 0.68)
        ..strokeWidth = isLong ? 3.0 : 2.2
        ..strokeCap = StrokeCap.round;

      final innerRayR = rCore * 1.16;
      final outerRayR = isLong ? (rCore * 1.70) : (rCore * 1.46);

      final angle = rotateAngle + (i * 2 * math.pi) / numRays;
      final x1 = cx + innerRayR * math.cos(angle);
      final y1 = cy + innerRayR * math.sin(angle);
      final x2 = cx + outerRayR * math.cos(angle);
      final y2 = cy + outerRayR * math.sin(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), rayPaint);
    }

    // 3. Inti matahari dengan gradient hangat (Putih Inti -> Kuning Cerah -> Oranye Keemasan)
    const coreGradient = RadialGradient(
      colors: [
        Color(0xFFFFFFFF), // 0.0: Highlight putih di tengah
        Color(0xFFFFF176), // 0.45: Kuning cerah matahari
        Color(0xFFFFD54F), // 0.80: Kuning emas hangat
        Color(0xFFFFB300), // 1.0: Emas oranye di tepi untuk kedalaman 3D
      ],
      stops: [0.0, 0.45, 0.80, 1.0],
    );

    final corePaint = Paint()
      ..shader = coreGradient.createShader(
        Rect.fromCircle(center: center, radius: rCore),
      );

    canvas.drawCircle(center, rCore, corePaint);

    // 4. Specular gloss lengkung halus di kuadran kiri-atas inti matahari
    final glossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    final glossCenter = Offset(cx - rCore * 0.32, cy - rCore * 0.32);
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: rCore)));
    canvas.drawCircle(glossCenter, rCore * 0.42, glossPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EnlargedSunPainter oldDelegate) =>
      oldDelegate.rotateAngle != rotateAngle;
}

// =====================================================================
// 2. BULAN SABIT ELEGAN (CRESCENT MOON)
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

    // 1. Pendaran lembut cahaya bulan (Silver Moonlight + Warm Lunar Glow)
    final outerGlow = Paint()
      ..color = const Color(0xFF93C5FD).withValues(alpha: 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(center, size.width * 0.42, outerGlow);

    final innerGlow = Paint()
      ..color = const Color(0xFFFEF3C7).withValues(alpha: 0.32)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas.drawCircle(center, size.width * 0.32, innerGlow);

    // 2. Bentuk Bulan Sabit Matematika Presisi (Boolean Difference Mask)
    // Menghasilkan kurva sabit yang anggun dan ujung tanduk yang meruncing mulus sempurna
    final rOuter = size.width * 0.30;
    final outerPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: rOuter));

    final rInner = rOuter * 0.90;
    // Offset cekungan lingkaran pemotong ke arah atas-kiri
    final innerCenter = Offset(
      center.dx - rOuter * 0.40,
      center.dy - rOuter * 0.18,
    );
    final innerPath = Path()
      ..addOval(Rect.fromCircle(center: innerCenter, radius: rInner));

    final crescentPath = Path.combine(
      PathOperation.difference,
      outerPath,
      innerPath,
    );

    // 3. Gradient warna bulan sabit (Perak Luminous -> Krem Hangat -> Emas Lembut)
    const moonGradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Color(0xFFFFFFFF), // Highlight kristal terang di punggung sabit
        Color(0xFFFFFDE7), // Krem gading hangat
        Color(0xFFFEF9C3), // Emas moonlight pastel lembut
        Color(0xFFFDE68A), // Emas madu hangat di sisi dalam
      ],
      stops: [0.0, 0.32, 0.68, 1.0],
    );

    final moonPaint = Paint()
      ..shader = moonGradient.createShader(
        Rect.fromCircle(center: center, radius: rOuter),
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(crescentPath, moonPaint);

    // 4. Highlight tepi kurva luar (Specular Rim Light)
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.save();
    canvas.clipPath(crescentPath);
    canvas.drawOval(Rect.fromCircle(center: center, radius: rOuter), rimPaint);

    // 5. Aksen kawah bulan halus transparan untuk tekstur ilustratif elegan
    final craterPaint = Paint()
      ..color = const Color(0xFFE2E8F0).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
    canvas.drawCircle(
      Offset(center.dx + rOuter * 0.28, center.dy + rOuter * 0.20),
      rOuter * 0.12,
      craterPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + rOuter * 0.12, center.dy - rOuter * 0.24),
      rOuter * 0.09,
      craterPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =====================================================================
// 3. BINTANG BERKELIP (TWINKLING STAR)
// =====================================================================
class _TwinklingStar extends StatelessWidget {
  final double size;
  final double opacity;

  const _TwinklingStar({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _StarPainter()),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);

    // Pendaran lembut bintang
    final glow = Paint()
      ..color = const Color(0xFFFEF08A).withValues(alpha: 0.65)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawCircle(center, size.width * 0.38, glow);

    // Bentuk kilau 4-titik elegan (Diamond sparkle)
    final starPath = Path();
    starPath.moveTo(cx, 0);
    starPath.quadraticBezierTo(cx, cy, size.width, cy);
    starPath.quadraticBezierTo(cx, cy, cx, size.height);
    starPath.quadraticBezierTo(cx, cy, 0, cy);
    starPath.quadraticBezierTo(cx, cy, cx, 0);

    final starPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawPath(starPath, starPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =====================================================================
// 4. AWAN CUMULUS FLUFFY (SATU SILUET UTUH, TANPA SEAM ANTAR-GUNDUKAN)
// =====================================================================
class _CumulusCloud extends StatelessWidget {
  final double width;
  final double height;
  final bool isNight;
  final double opacity;
  final bool flipHorizontal;

  const _CumulusCloud({
    required this.width,
    required this.height,
    required this.isNight,
    this.opacity = 0.35,
    this.flipHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget cloud = CustomPaint(
      size: Size(width, height),
      painter: _CumulusCloudPainter(isNight: isNight, opacity: opacity),
    );

    if (flipHorizontal) {
      cloud = Transform.flip(flipX: true, child: cloud);
    }

    return cloud;
  }
}

class _CumulusCloudPainter extends CustomPainter {
  final bool isNight;
  final double opacity;

  const _CumulusCloudPainter({required this.isNight, required this.opacity});

  Path _buildCloudSilhouette(double w, double h) {
    Path union(List<Path> parts) {
      Path result = parts.first;
      for (final p in parts.skip(1)) {
        result = Path.combine(PathOperation.union, result, p);
      }
      return result;
    }

    return union([
      Path()..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.06, h * 0.44, w * 0.88, h * 0.46),
          Radius.circular(h * 0.23),
        ),
      ),
      Path()..addOval(Rect.fromLTWH(w * 0.02, h * 0.30, w * 0.30, h * 0.48)),
      Path()..addOval(Rect.fromLTWH(w * 0.18, h * 0.16, w * 0.32, h * 0.52)),
      Path()..addOval(Rect.fromLTWH(w * 0.33, h * 0.05, w * 0.36, h * 0.62)),
      Path()..addOval(Rect.fromLTWH(w * 0.57, h * 0.18, w * 0.29, h * 0.50)),
      Path()..addOval(Rect.fromLTWH(w * 0.74, h * 0.32, w * 0.22, h * 0.40)),
    ]);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final baseColor = isNight ? const Color(0xFFD1D7DB) : Colors.white;
    final shadowColor = isNight
        ? const Color(0xFF8696A0)
        : const Color(0xFFCFE0F5);

    final silhouette = _buildCloudSilhouette(w, h);
    final solidOpacity = (opacity + 0.32).clamp(0.0, 1.0);

    // Body utama — satu fill solid siluet gabungan
    final bodyPaint = Paint()
      ..color = baseColor.withValues(alpha: solidOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawPath(silhouette, bodyPaint);

    // Shading & highlight di-clip persis ke dalam siluet
    canvas.save();
    canvas.clipPath(silhouette);

    // Shading lembut di bagian bawah
    final shadowRect = Rect.fromLTWH(0, h * 0.42, w, h * 0.58);
    canvas.drawRect(
      shadowRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            shadowColor.withValues(alpha: 0.0),
            shadowColor.withValues(alpha: 0.30),
          ],
        ).createShader(shadowRect),
    );

    // Highlight lembut di puncak awan
    final highlightRect = Rect.fromLTWH(w * 0.28, 0, w * 0.44, h * 0.5);
    canvas.drawRect(
      highlightRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(highlightRect),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CumulusCloudPainter oldDelegate) =>
      oldDelegate.isNight != isNight || oldDelegate.opacity != opacity;
}

// =====================================================================
// 5. SILUET BURUNG TERBANG (FLYING BIRD WITH SMOOTH WINGS)
// =====================================================================
class _FlyingBird extends StatelessWidget {
  final double width;
  final double height;
  final double wingState;
  final Color color;

  const _FlyingBird({
    required this.width,
    required this.height,
    required this.wingState,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _BirdPainter(wingState: wingState, color: color),
      ),
    );
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
    final midX = w * 0.5;
    final bodyY = h * 0.65;

    // Flap offset: sayap melengkung lembut saat mengepak
    final wingArchY = (h * 0.15) - (wingState * h * 0.35);

    final path = Path();
    // Sayap kiri: dari ujung melengkung anggun ke tubuh tengah
    path.moveTo(0, h * 0.45 + (wingState * h * 0.2));
    path.quadraticBezierTo(w * 0.22, wingArchY, midX, bodyY);

    // Sayap kanan: dari tubuh tengah melengkung ke ujung kanan
    path.quadraticBezierTo(
      w * 0.78,
      wingArchY,
      w,
      h * 0.45 + (wingState * h * 0.2),
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BirdPainter oldDelegate) =>
      oldDelegate.wingState != wingState || oldDelegate.color != color;
}
