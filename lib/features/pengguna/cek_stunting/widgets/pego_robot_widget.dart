import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Pose karakter robot AI "PEGO"
enum PegoPose {
  idle,
  waving,
  scanning,
}

/// Widget Karakter Robot AI "Pego" — Maskot Resmi PediaGrow (Rig Artikulasi 3D HD)
///
/// Tersusun dari 4 lapisan 3D HD presisi + pelapis ekspresi wajah 60 FPS:
/// 1. Lengan kiri (`pego_left_arm.png`) — berayun selaras di bahu kiri
/// 2. Lengan kanan (`pego_right_arm.png`) — melambai "berdada-dada" bebas & natural di bahu kanan
/// 3. Badan & kaki (`pego_torso_legs.png`) — kokoh simetris dengan sabuk & kancing biru
/// 4. Kepala & visor bersih (`pego_head.png`) + ekspresi wajah 3D hidup (pipi merona, kedipan mata,
///    mata berbinar/melengkung bahagia `^ ^`, dan senyum tawa ceria terbuka).
class PegoRobotWidget extends StatelessWidget {
  static const double rigAspectRatio = 621.0 / 898.0;

  static const List<String> rigAssetPaths = [
    'assets/images/pego/pego_left_arm.png',
    'assets/images/pego/pego_right_arm.png',
    'assets/images/pego/pego_torso_legs.png',
    'assets/images/pego/pego_head.png',
  ];

  final double width;
  final double height;
  final String? customAssetPath;
  final PegoPose pose;
  final bool showRipples;
  final double ripplePhase;

  /// Sudut rotasi lengan kiri dalam radian
  final double leftArmAngle;

  /// Sudut rotasi lengan kanan (tangan melambai) dalam radian
  final double rightArmAngle;

  /// Sudut miring kepala penuh kasih/ceria dalam radian
  final double headAngle;

  /// Offset naik-turun kepala halus dalam pixel logis
  final double headBobY;

  /// Status lambaian tangan aktif
  final bool isWaving;

  /// Fase animasi gelombang lambaian tangan (0.0 .. 1.0)
  final double wavePhase;

  /// Tingkat antusias/excited ekspresi wajah (0.0 = ramah netral, 1.0 = sangat ceria)
  final double excitement;

  /// Faktor kedipan mata (0.0 = terbuka lebar, 1.0 = terpejam kedip)
  final double blinkFactor;

  /// Faktor mata melengkung bahagia `^ ^` (0.0 = mata kapsul berbinar, 1.0 = lengkung ceria)
  final double happySquintFactor;

  /// Faktor bukaan mulut tawa ceria (0.0 = senyum lengkung, 1.0 = senyum tawa terbuka)
  final double mouthOpenFactor;

  const PegoRobotWidget({
    super.key,
    this.width = 130,
    this.height = 170,
    this.customAssetPath,
    this.pose = PegoPose.waving,
    this.showRipples = true,
    this.ripplePhase = 0.0,
    this.leftArmAngle = 0.0,
    this.rightArmAngle = 0.0,
    this.headAngle = 0.0,
    this.headBobY = 0.0,
    this.isWaving = false,
    this.wavePhase = 0.0,
    this.excitement = 0.0,
    this.blinkFactor = 0.0,
    this.happySquintFactor = 0.0,
    this.mouthOpenFactor = 0.0,
  });

  /// Path aset maskot PEGO 3D HD fallback tunggal
  String get effectiveAssetPath {
    if (customAssetPath != null && customAssetPath!.isNotEmpty) {
      return customAssetPath!;
    }
    return 'assets/images/pego/pego_mascot_hd.png';
  }

  /// Konversi titik pixel rig `(px, py)` pada kanvas `621 x 898` ke `Alignment` Flutter
  static Alignment _rigAlignment(double px, double py) {
    return Alignment(
      (px / 621.0) * 2.0 - 1.0,
      (py / 898.0) * 2.0 - 1.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool useCustomSingleAsset =
        customAssetPath != null && customAssetPath!.isNotEmpty;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. Riak bayangan lembut di tanah (jika diaktifkan)
          if (showRipples)
            Positioned(
              bottom: 0,
              child: CustomPaint(
                size: Size(width, 24),
                painter: _PegoGroundRipplePainter(phase: ripplePhase),
              ),
            ),

          // 2. Maskot PEGO 3D HD
          if (useCustomSingleAsset)
            Image.asset(
              effectiveAssetPath,
              width: width,
              height: height,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) =>
                  _buildCustomPainter(),
            )
          else
            _buildArticulatedRig(),
        ],
      ),
    );
  }

  /// Merakit 4 layer PNG 3D HD + kanvas ekspresi wajah animasi pada rasio aspek tepat
  Widget _buildArticulatedRig() {
    return Center(
      child: AspectRatio(
        aspectRatio: rigAspectRatio,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Layer 1: Lengan Kiri (di belakang badan, berputar mulus di sendi bahu kiri)
            Positioned.fill(
              child: Transform.rotate(
                angle: leftArmAngle,
                alignment: _rigAlignment(201.0, 582.0),
                child: Image.asset(
                  'assets/images/pego/pego_left_arm.png',
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Layer 2: Lengan Kanan Melambai ("Berdada-dada", di belakang badan, pivot bahu kanan)
            Positioned.fill(
              child: Transform.rotate(
                angle: rightArmAngle,
                alignment: _rigAlignment(423.0, 576.0),
                child: Image.asset(
                  'assets/images/pego/pego_right_arm.png',
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Layer 3: Badan, Sabuk & Kaki
            Positioned.fill(
              child: Image.asset(
                'assets/images/pego/pego_torso_legs.png',
                fit: BoxFit.contain,
                gaplessPlayback: true,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, _, _) => _buildCustomPainter(),
              ),
            ),

            // Layer 4: Kepala + Visor 3D + Ekspresi Wajah Animasi
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(0, headBobY),
                child: Transform.rotate(
                  angle: headAngle,
                  alignment: _rigAlignment(310.0, 548.0),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/pego/pego_head.png',
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                      CustomPaint(
                        painter: _PegoAnimatedFacePainter(
                          excitement: excitement,
                          blinkFactor: blinkFactor,
                          happySquintFactor: happySquintFactor,
                          mouthOpenFactor: mouthOpenFactor,
                          gazeShiftX: math.sin(wavePhase * 2 * math.pi) * 0.008,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fallback CustomPainter presisi dengan skema warna 100% identik
  Widget _buildCustomPainter() {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _PegoUserMascotPainter(
          showRipples: showRipples,
          ripplePhase: ripplePhase,
          leftArmAngle: leftArmAngle,
          rightArmAngle: rightArmAngle,
          pose: pose,
          isWaving: isWaving,
          wavePhase: wavePhase,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Pelapis Ekspresi Wajah 3D Animasi (Hidup, Ramah & Excited)
// ─────────────────────────────────────────────────────────────────
class _PegoAnimatedFacePainter extends CustomPainter {
  final double excitement;
  final double blinkFactor;
  final double happySquintFactor;
  final double mouthOpenFactor;
  final double gazeShiftX;

  const _PegoAnimatedFacePainter({
    required this.excitement,
    required this.blinkFactor,
    required this.happySquintFactor,
    required this.mouthOpenFactor,
    this.gazeShiftX = 0.0,
  });

  static const Color _eyeDark = Color(0xFF283342);
  static const Color _eyeHighlight = Color(0xFF475569);
  static const Color _cheekCoral = Color(0xFFFF6E8D);
  static const Color _mouthDark = Color(0xFF26303D);
  static const Color _tonguePink = Color(0xFFFF6B8B);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Pipi merona hangat (muncul saat excited/ceria)
    final double blushAlpha = (0.14 + 0.34 * excitement).clamp(0.0, 0.50);
    if (blushAlpha > 0.02) {
      _drawBlush(canvas, Offset(w * 0.285, h * 0.452), w * 0.072, h * 0.030, blushAlpha);
      _drawBlush(canvas, Offset(w * 0.713, h * 0.452), w * 0.072, h * 0.030, blushAlpha);
    }

    // 2. Mata kiri & kanan (transisi mulus antara mata kapsul 3D berbinar & lengkung bahagia `^ ^`)
    _drawAnimatedEye(
      canvas,
      center: Offset(w * (0.351 + gazeShiftX), h * 0.372),
      eyeW: w * 0.102,
      eyeH: h * 0.138,
    );
    _drawAnimatedEye(
      canvas,
      center: Offset(w * (0.647 + gazeShiftX), h * 0.372),
      eyeW: w * 0.102,
      eyeH: h * 0.138,
    );

    // 3. Mulut (dari senyum lengkung hangat ke tawa ceria terbuka)
    _drawAnimatedMouth(
      canvas,
      center: Offset(w * 0.499, h * 0.494),
      baseW: w * 0.186,
      baseH: h * 0.058,
    );
  }

  void _drawBlush(
    Canvas canvas,
    Offset center,
    double rx,
    double ry,
    double alpha,
  ) {
    final Rect rect = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);
    final Paint paint = Paint()
      ..shader = RadialGradient(
        colors: [
          _cheekCoral.withValues(alpha: alpha),
          _cheekCoral.withValues(alpha: 0.0),
        ],
      ).createShader(rect);
    canvas.drawOval(rect, paint);
  }

  void _drawAnimatedEye(
    Canvas canvas, {
    required Offset center,
    required double eyeW,
    required double eyeH,
  }) {
    if (happySquintFactor > 0.55) {
      // Mata melengkung ceria (`^ ^` bahagia) saat puncak tawa/antusias
      final double morph = ((happySquintFactor - 0.55) / 0.45).clamp(0.0, 1.0);
      final double arcW = eyeW * (1.05 + 0.12 * morph);
      final double arcH = eyeH * (0.30 + 0.10 * morph);

      final Paint arcPaint = Paint()
        ..color = _eyeDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = eyeW * 0.24
        ..strokeCap = StrokeCap.round;

      final Path happyPath = Path()
        ..moveTo(center.dx - arcW * 0.52, center.dy + arcH * 0.30)
        ..quadraticBezierTo(
          center.dx,
          center.dy - arcH * 0.95,
          center.dx + arcW * 0.52,
          center.dy + arcH * 0.30,
        );
      canvas.drawPath(happyPath, arcPaint);

      // Kilau kecil di lengkung mata ceria
      final Paint glossPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.32 * morph)
        ..style = PaintingStyle.stroke
        ..strokeWidth = eyeW * 0.06
        ..strokeCap = StrokeCap.round;
      final Path glossArc = Path()
        ..moveTo(center.dx - arcW * 0.28, center.dy - arcH * 0.14)
        ..quadraticBezierTo(
          center.dx - arcW * 0.05,
          center.dy - arcH * 0.42,
          center.dx + arcW * 0.15,
          center.dy - arcH * 0.25,
        );
      canvas.drawPath(glossArc, glossPaint);
      return;
    }

    // Mata kapsul 3D glossy dengan skala kedipan + pelebaran antusias
    final double squintScale = 1.0 - (happySquintFactor / 0.55) * 0.65;
    final double blinkScale = 1.0 - blinkFactor * 0.90;
    final double exciteBoost = 1.0 + excitement * 0.07;

    final double curW = eyeW * exciteBoost * (1.0 + blinkFactor * 0.10);
    final double curH = (eyeH * exciteBoost * blinkScale * squintScale)
        .clamp(eyeW * 0.20, eyeH * 1.15);

    final Rect eyeRect = Rect.fromCenter(center: center, width: curW, height: curH);
    final RRect rrect = RRect.fromRectAndRadius(
      eyeRect,
      Radius.circular(curW * 0.48),
    );

    // Bayangan lembut visor di sekeliling mata kapsul
    canvas.drawRRect(
      rrect.shift(Offset(0, curW * 0.05)),
      Paint()..color = Colors.black.withValues(alpha: 0.10),
    );

    // Badan mata 3D dengan gradasi kilau atas-kiri ke gelap
    final Paint bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [_eyeHighlight, _eyeDark, Color(0xFF1A222D)],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(eyeRect);
    canvas.drawRRect(rrect, bodyPaint);

    // Pantulan cahaya 3D berbinar (hanya saat mata terbuka)
    if (curH > eyeW * 0.45) {
      final double catchAlpha = (0.72 + 0.25 * excitement).clamp(0.0, 1.0);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx - curW * 0.18, center.dy - curH * 0.22),
          width: curW * 0.24,
          height: curH * 0.18,
        ),
        Paint()..color = Colors.white.withValues(alpha: catchAlpha),
      );
      if (excitement > 0.20) {
        canvas.drawCircle(
          Offset(center.dx + curW * 0.16, center.dy + curH * 0.20),
          curW * (0.07 + 0.03 * excitement),
          Paint()..color = Colors.white.withValues(alpha: 0.75 * excitement),
        );
      }
    }
  }

  void _drawAnimatedMouth(
    Canvas canvas, {
    required Offset center,
    required double baseW,
    required double baseH,
  }) {
    final double open = mouthOpenFactor.clamp(0.0, 1.0);
    final double curW = baseW * (1.0 + 0.14 * excitement + 0.06 * open);

    if (open <= 0.12) {
      // Senyum garis lengkung 3D ramah & optimis
      final double curveDepth = baseH * (0.62 + 0.25 * excitement);
      final Path smilePath = Path()
        ..moveTo(center.dx - curW * 0.5, center.dy - curveDepth * 0.22)
        ..quadraticBezierTo(
          center.dx,
          center.dy + curveDepth * 0.92,
          center.dx + curW * 0.5,
          center.dy - curveDepth * 0.22,
        );

      canvas.drawPath(
        smilePath,
        Paint()
          ..color = _mouthDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = baseW * 0.115
          ..strokeCap = StrokeCap.round,
      );
      return;
    }

    // Senyum tawa terbuka D-shape ceria dengan lidah pink hangat
    final double openDepth = baseH * (0.85 + 0.85 * open);
    final double topY = center.dy - baseH * 0.18;

    final Path dMouth = Path()
      ..moveTo(center.dx - curW * 0.5, topY)
      ..quadraticBezierTo(center.dx, topY + baseH * 0.12, center.dx + curW * 0.5, topY)
      ..quadraticBezierTo(center.dx + curW * 0.45, topY + openDepth, center.dx, topY + openDepth)
      ..quadraticBezierTo(center.dx - curW * 0.45, topY + openDepth, center.dx - curW * 0.5, topY)
      ..close();

    // Bayangan tipis bibir
    canvas.drawPath(
      dMouth.shift(Offset(0, baseW * 0.015)),
      Paint()..color = Colors.black.withValues(alpha: 0.10),
    );
    canvas.drawPath(dMouth, Paint()..color = _mouthDark);

    // Lidah merah muda lembut di bagian bawah mulut terbuka
    canvas.save();
    canvas.clipPath(dMouth);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, topY + openDepth * 0.88),
        width: curW * 0.62,
        height: openDepth * 0.65,
      ),
      Paint()..color = _tonguePink,
    );
    canvas.restore();

    // Garis tepi senyum rapi
    canvas.drawPath(
      dMouth,
      Paint()
        ..color = _mouthDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = baseW * 0.045
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PegoAnimatedFacePainter oldDelegate) {
    return oldDelegate.excitement != excitement ||
        oldDelegate.blinkFactor != blinkFactor ||
        oldDelegate.happySquintFactor != happySquintFactor ||
        oldDelegate.mouthOpenFactor != mouthOpenFactor ||
        oldDelegate.gazeShiftX != gazeShiftX;
  }
}

// ─────────────────────────────────────────────────────────────────
// Riak bayangan lembut di tanah / portal
// ─────────────────────────────────────────────────────────────────
class _PegoGroundRipplePainter extends CustomPainter {
  final double phase;

  _PegoGroundRipplePainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2.0;
    final cy = size.height / 2.0;
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = Colors.black.withValues(alpha: 0.18);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: size.width * 0.52,
        height: size.height * 0.42,
      ),
      paint,
    );

    final rippleScale = 1.0 + (phase * 0.20);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.2;
    paint.color = const Color(0xFF0D72F8).withValues(alpha: 0.20 * (1.0 - phase));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: size.width * 0.62 * rippleScale,
        height: size.height * 0.48 * rippleScale,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _PegoGroundRipplePainter oldDelegate) =>
      oldDelegate.phase != phase;
}

// ─────────────────────────────────────────────────────────────────
// Fallback Painter Maskot PEGO (Skema Warna & Anatomi 1:1)
// ─────────────────────────────────────────────────────────────────
class _PegoUserMascotPainter extends CustomPainter {
  final bool showRipples;
  final double ripplePhase;
  final double leftArmAngle;
  final double rightArmAngle;
  final PegoPose pose;
  final bool isWaving;
  final double wavePhase;

  _PegoUserMascotPainter({
    required this.showRipples,
    required this.ripplePhase,
    required this.leftArmAngle,
    required this.rightArmAngle,
    required this.pose,
    required this.isWaving,
    required this.wavePhase,
  });

  static const Color pegoPeriwinkle = Color(0xFF91ADD2);
  static const Color pegoElectricBlue = Color(0xFF0D72F8);
  static const Color pegoDarkSlate = Color(0xFF2D3748);
  static const Color pegoWhite = Color(0xFFFFFFFF);
  static const Color pegoSpecular = Color(0xFFE2E8F0);

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.height / 190.0;
    canvas.save();
    canvas.scale(scale, scale);

    final cx = (size.width / scale) / 2.0;

    _drawLegs(canvas, cx);
    _drawBody(canvas, cx);
    _drawLeftArm(canvas, cx);
    _drawRightArm(canvas, cx);
    _drawHelmetAndEars(canvas, cx);
    _drawFace(canvas, cx);
    _drawAntennae(canvas, cx);

    canvas.restore();
  }

  void _drawLegs(Canvas canvas, double cx) {
    final legPaint = Paint()..color = pegoElectricBlue;
    final leftLeg = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 18, 148, 14, 30),
      const Radius.circular(7),
    );
    final rightLeg = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx + 4, 148, 14, 30),
      const Radius.circular(7),
    );
    canvas.drawRRect(leftLeg, legPaint);
    canvas.drawRRect(rightLeg, legPaint);
  }

  void _drawBody(Canvas canvas, double cx) {
    final bodyPaint = Paint()..color = pegoPeriwinkle;
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 24, 102, 48, 48),
      const Radius.circular(18),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    final beltPaint = Paint()..color = pegoDarkSlate;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 24, 126, 48, 10),
        const Radius.circular(3),
      ),
      beltPaint,
    );

    final bucklePaint = Paint()..color = pegoElectricBlue;
    canvas.drawCircle(Offset(cx, 131), 7.5, bucklePaint);
    canvas.drawCircle(Offset(cx - 1.5, 129.5), 2.2, Paint()..color = pegoWhite);
  }

  void _drawLeftArm(Canvas canvas, double cx) {
    final armPaint = Paint()..color = pegoElectricBlue;
    final leftArm = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 32, 110, 13, 26),
      const Radius.circular(7),
    );
    canvas.drawRRect(leftArm, armPaint);
  }

  void _drawRightArm(Canvas canvas, double cx) {
    final pivot = Offset(cx + 20, 114);
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);

    double angle = -0.55;
    if (isWaving) {
      angle += math.sin(wavePhase * 2 * math.pi) * 0.28;
    } else if (rightArmAngle != 0) {
      angle += rightArmAngle;
    }

    canvas.rotate(angle);

    final armPaint = Paint()..color = pegoElectricBlue;
    final rightArm = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-6, -26, 13, 28),
      const Radius.circular(7),
    );
    canvas.drawRRect(rightArm, armPaint);
    canvas.drawCircle(const Offset(-4, -18), 3.5, armPaint);

    canvas.restore();
  }

  void _drawHelmetAndEars(Canvas canvas, double cx) {
    final earPaint = Paint()..color = pegoElectricBlue;
    canvas.drawCircle(Offset(cx - 42, 68), 16, earPaint);
    canvas.drawCircle(Offset(cx + 42, 68), 16, earPaint);

    final helmetPaint = Paint()..color = pegoPeriwinkle;
    canvas.drawCircle(Offset(cx, 68), 38, helmetPaint);

    final glossPaint = Paint()
      ..color = pegoSpecular.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, 68), radius: 32),
      -math.pi * 0.85,
      math.pi * 0.35,
      false,
      glossPaint,
    );
  }

  void _drawFace(Canvas canvas, double cx) {
    final ringPaint = Paint()
      ..color = pegoElectricBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawCircle(Offset(cx, 70), 28, ringPaint);

    final visorPaint = Paint()..color = pegoWhite;
    canvas.drawCircle(Offset(cx, 70), 27, visorPaint);

    final eyePaint = Paint()..color = pegoDarkSlate;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 10, 68), width: 9, height: 16),
        const Radius.circular(4.5),
      ),
      eyePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 10, 68), width: 9, height: 16),
        const Radius.circular(4.5),
      ),
      eyePaint,
    );

    final catchlight = Paint()..color = pegoWhite;
    canvas.drawCircle(Offset(cx - 11.5, 65), 1.6, catchlight);
    canvas.drawCircle(Offset(cx + 8.5, 65), 1.6, catchlight);

    final smilePaint = Paint()
      ..color = pegoDarkSlate
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final smilePath = Path()
      ..moveTo(cx - 7, 78)
      ..quadraticBezierTo(cx, 84, cx + 7, 78);
    canvas.drawPath(smilePath, smilePaint);
  }

  void _drawAntennae(Canvas canvas, double cx) {
    final stickPaint = Paint()
      ..color = pegoElectricBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final ballPaint = Paint()..color = pegoElectricBlue;

    canvas.drawLine(Offset(cx - 16, 38), Offset(cx - 24, 22), stickPaint);
    canvas.drawCircle(Offset(cx - 24, 22), 5.5, ballPaint);

    canvas.drawLine(Offset(cx + 16, 38), Offset(cx + 24, 22), stickPaint);
    canvas.drawCircle(Offset(cx + 24, 22), 5.5, ballPaint);
  }

  @override
  bool shouldRepaint(covariant _PegoUserMascotPainter oldDelegate) => true;
}

// ─────────────────────────────────────────────────────────────────
// Widget Pego dengan Animasi Lambaian Tangan Natural & Ekspresi Ceria
// ─────────────────────────────────────────────────────────────────

/// Widget Pego yang beranimasi lambaian tangan riang ("berdada-dada") dan ekspresi hidup
class PegoAnimatingWidget extends StatefulWidget {
  final double width;
  final double height;
  final bool isWaving;
  final PegoPose pose;
  final bool showRipples;
  final String? customAssetPath;
  final bool isAnalyzing;
  final bool gentleMode;

  const PegoAnimatingWidget({
    super.key,
    this.width = 130,
    this.height = 170,
    this.isWaving = false,
    this.pose = PegoPose.waving,
    this.showRipples = true,
    this.customAssetPath,
    this.isAnalyzing = false,
    this.gentleMode = false,
  });

  @override
  State<PegoAnimatingWidget> createState() => _PegoAnimatingWidgetState();
}

class _PegoAnimatingWidgetState extends State<PegoAnimatingWidget>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _expressionController;
  late AnimationController _blendController;
  late Animation<double> _blendAnimation;

  @override
  void initState() {
    super.initState();
    // Siklus kontinu lambaian tangan alami (~780ms untuk analisis, ~1650ms untuk pose ceria beranda)
    _waveController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.gentleMode ? 1650 : 780),
    );

    // Siklus ekspresi wajah alami (kedip, mata bahagia `^ ^`, senyum tawa terbuka)
    _expressionController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.gentleMode ? 2800 : 1750),
    );

    // Transisi mulus intensitas lambaian & antusiasme (0 = netral tegak, 1 = riang penuh)
    _blendController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _blendAnimation = CurvedAnimation(
      parent: _blendController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    if (widget.isWaving || widget.isAnalyzing) {
      _waveController.repeat();
      _expressionController.repeat();
      if (widget.gentleMode) {
        _blendController.value = 1.0;
      } else {
        _blendController.forward();
      }
    }
  }

  @override
  void didUpdateWidget(covariant PegoAnimatingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool shouldAnimate = widget.isWaving || widget.isAnalyzing;
    final bool wasAnimating = oldWidget.isWaving || oldWidget.isAnalyzing;

    if (shouldAnimate && !wasAnimating) {
      if (!_waveController.isAnimating) {
        _waveController.repeat();
      }
      if (!_expressionController.isAnimating) {
        _expressionController.repeat();
      }
      _blendController.forward();
    } else if (!shouldAnimate && wasAnimating) {
      _blendController.reverse().then((_) {
        if (mounted && !(widget.isWaving || widget.isAnalyzing)) {
          _waveController.stop();
          _waveController.value = 0.0;
          _expressionController.stop();
          _expressionController.value = 0.0;
        }
      });
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _expressionController.dispose();
    _blendController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _waveController,
        _expressionController,
        _blendController,
      ]),
      builder: (context, child) {
        final double blend = _blendAnimation.value;
        final double theta = _waveController.value * 2.0 * math.pi;
        final double exprT = _expressionController.value;

        // 1. Lambaian tangan kanan natural dengan sedikit kurva harmonik kedua (hangat & energik)
        // Berkisar ~ -0.40 rad (naik mendekati pipi) hingga +0.34 rad (ayun keluar)
        final double armWaveRaw =
            math.sin(theta) + 0.14 * math.sin(2.0 * theta - 0.4);
        final double rightArmAngle = widget.gentleMode
            ? blend * (-0.12 + armWaveRaw * 0.24)
            : blend * armWaveRaw * 0.36;

        // 2. Ayunan imbangan lembut pada lengan kiri (terangkat ramah saat gentleMode)
        final double leftArmAngle = widget.gentleMode
            ? blend * (0.24 + math.sin(theta + 0.5) * 0.12)
            : blend * math.sin(theta + 0.5) * 0.16;

        // 3. Kepala miring penuh ekspresi berlawanan arah lambaian + anggukan kecil ceria
        final double headAngle = widget.gentleMode
            ? blend * (-0.055 - math.sin(theta - 0.45) * 0.045)
            : -blend * math.sin(theta - 0.45) * 0.075;
        final double doubleBeat = (1.0 - math.cos(theta * 2.0)) * 0.5;
        final double headBobY =
            -blend * doubleBeat * (widget.gentleMode ? 1.4 : 2.2);

        // 4. Goyangan tubuh ringan + lompatan riang + squash & stretch organik
        final double bodySway = blend *
            math.sin(theta - 0.25) *
            (widget.gentleMode ? 0.025 : 0.036);
        final double bounceOffset =
            -blend * doubleBeat * (widget.gentleMode ? 2.8 : 7.5);
        final double squashWave = math.cos(theta * 2.0);
        final double scaleX = 1.0 + (blend * squashWave * 0.024);
        final double scaleY = 1.0 - (blend * squashWave * 0.020);

        // 5. Koreografi ekspresi wajah (kedipan cepat natural + senyum tawa ceria + mata `^ ^`)
        // Kedipan singkat pada t = 0.10..0.18
        double blinkFactor = 0.0;
        if (exprT >= 0.10 && exprT <= 0.18) {
          final double bp = (exprT - 0.10) / 0.08;
          blinkFactor = math.sin(bp * math.pi);
        }

        // Mata melengkung bahagia `^ ^` pada puncak antusias t = 0.36..0.72
        double happySquintFactor = 0.0;
        if (exprT >= 0.36 && exprT <= 0.72) {
          final double hp = (exprT - 0.36) / 0.36;
          happySquintFactor = math.sin(hp * math.pi);
        }
        happySquintFactor *= blend;

        // Mulut terbuka tertawa ceria (berdenyut lembut mengikuti lompatan riang)
        final double mouthOpenFactor =
            (blend * (0.68 + 0.32 * math.sin(exprT * math.pi))).clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(0, bounceOffset),
          child: Transform.rotate(
            angle: bodySway,
            alignment: Alignment.bottomCenter,
            child: Transform.scale(
              scaleX: scaleX,
              scaleY: scaleY,
              alignment: Alignment.bottomCenter,
              child: PegoRobotWidget(
                width: widget.width,
                height: widget.height,
                customAssetPath: widget.customAssetPath,
                pose: widget.pose,
                showRipples: widget.showRipples,
                ripplePhase: _waveController.value,
                isWaving: (widget.isWaving || widget.isAnalyzing) && blend > 0.05,
                wavePhase: _waveController.value,
                leftArmAngle: leftArmAngle,
                rightArmAngle: rightArmAngle,
                headAngle: headAngle,
                headBobY: headBobY,
                excitement: blend,
                blinkFactor: blinkFactor,
                happySquintFactor: happySquintFactor,
                mouthOpenFactor: mouthOpenFactor,
              ),
            ),
          ),
        );
      },
    );
  }
}
