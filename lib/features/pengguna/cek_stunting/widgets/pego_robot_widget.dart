import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Widget Karakter Robot AI "Pego" — sesuai referensi gambar PediaGrow
///
/// Spesifikasi visual:
/// - Kepala BESAR berbentuk lingkaran dominan, berwarna biru terang
/// - Wajah abu-abu bulat besar di tengah kepala dengan mata oval hitam & senyum
/// - Dua lingkaran besar telinga/headphone di kedua sisi kepala
/// - Dua antena tipis tegak lurus ke atas dengan ujung bola kecil
/// - Tubuh kecil biru bulat di bawah kepala
/// - Sabuk hitam bulat (lingkaran/tombol) di tengah dada
/// - Lengan pendek di kedua sisi tubuh, bisa melambaikan (via [leftArmAngle])
/// - Kaki pendek biru bulat
/// - Efek riak konsentris opsional di kaki
class PegoRobotWidget extends StatelessWidget {
  final double width;
  final double height;
  final String? customAssetPath;
  final bool showRipples;
  final double ripplePhase;

  /// Sudut rotasi lengan kiri dalam radian (positif = ke atas/melambaikan)
  /// 0 = posisi default, π/2 = tegak lurus ke atas (melambaikan)
  final double leftArmAngle;

  /// Sudut rotasi lengan kanan dalam radian (negatif = ke atas)
  final double rightArmAngle;

  const PegoRobotWidget({
    super.key,
    this.width = 130,
    this.height = 170,
    this.customAssetPath,
    this.showRipples = true,
    this.ripplePhase = 0.0,
    this.leftArmAngle = 0.0,
    this.rightArmAngle = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    if (customAssetPath != null && customAssetPath!.isNotEmpty) {
      return Image.asset(
        customAssetPath!,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildCustomPainter(),
      );
    }
    return _buildCustomPainter();
  }

  Widget _buildCustomPainter() {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _PegoRobotPainter(
          showRipples: showRipples,
          ripplePhase: ripplePhase,
          leftArmAngle: leftArmAngle,
          rightArmAngle: rightArmAngle,
        ),
      ),
    );
  }
}

class _PegoRobotPainter extends CustomPainter {
  final bool showRipples;
  final double ripplePhase;
  final double leftArmAngle;
  final double rightArmAngle;

  _PegoRobotPainter({
    required this.showRipples,
    required this.ripplePhase,
    required this.leftArmAngle,
    required this.rightArmAngle,
  });

  // Palet Warna Robot Pego — sesuai referensi gambar
  static const Color pegoBlue = Color(0xFF2B7AE8);       // Biru cerah utama
  static const Color pegoFaceGrey = Color(0xFFCDD1D6);   // Abu-abu wajah
  static const Color pegoWhite = Color(0xFFFFFFFF);      // Putih
  static const Color pegoDark = Color(0xFF1A1A2E);       // Hitam gelap mata
  static const Color pegoBeltDark = Color(0xFF111827);   // Sabuk hitam

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.height / 190.0;
    canvas.save();
    canvas.scale(scale, scale);

    final cx = (size.width / scale) / 2.0;

    // Gambar dari belakang ke depan:
    // 1. Ripple rings di tanah
    if (showRipples) {
      _drawRipples(canvas, cx, 182.0);
    }
    // 2. Kaki
    _drawLegs(canvas, cx);
    // 3. Tubuh
    _drawBody(canvas, cx);
    // 4. Lengan (di atas tubuh, di bawah kepala)
    _drawLeftArm(canvas, cx, leftArmAngle);
    _drawRightArm(canvas, cx, rightArmAngle);
    // 5. Telinga/Headphone (lingkaran besar di samping kepala)
    _drawEars(canvas, cx);
    // 6. Kepala (lingkaran besar, gambar di atas telinga agar menutupi tepi)
    _drawHead(canvas, cx);
    // 7. Wajah (mata, senyum) di atas kepala
    _drawFace(canvas, cx);
    // 8. Antena di atas kepala
    _drawAntennas(canvas, cx);

    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────────────
  // RIPPLE RINGS (bayangan elips di tanah)
  // ─────────────────────────────────────────────────────────────────
  void _drawRipples(Canvas canvas, double cx, double cy) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final colors = [
      Colors.black.withValues(alpha: 0.20),
      Colors.black.withValues(alpha: 0.12),
      Colors.black.withValues(alpha: 0.06),
    ];
    final widths = [42.0, 56.0, 70.0];
    for (int i = 0; i < 3; i++) {
      paint.color = colors[i];
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: widths[i], height: widths[i] * 0.28),
        paint,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // KAKI
  // ─────────────────────────────────────────────────────────────────
  void _drawLegs(Canvas canvas, double cx) {
    final paint = Paint()
      ..color = pegoBlue
      ..style = PaintingStyle.fill;

    // Kaki kiri
    final leftLeg = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 18, 148, 13, 34),
      const Radius.circular(7),
    );
    canvas.drawRRect(leftLeg, paint);

    // Kaki kanan
    final rightLeg = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx + 5, 148, 13, 34),
      const Radius.circular(7),
    );
    canvas.drawRRect(rightLeg, paint);
  }

  // ─────────────────────────────────────────────────────────────────
  // TUBUH — lebih kecil dari kepala, berbentuk bulat/oval
  // ─────────────────────────────────────────────────────────────────
  void _drawBody(Canvas canvas, double cx) {
    final bodyPaint = Paint()
      ..color = pegoBlue
      ..style = PaintingStyle.fill;

    // Badan utama
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 22, 106, 44, 46),
      const Radius.circular(18),
    );
    canvas.drawRRect(bodyRRect, bodyPaint);

    // Sabuk / tombol lingkaran hitam di tengah dada
    final beltPaint = Paint()
      ..color = pegoBeltDark
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, 132), 10, beltPaint);

    // Kilau kecil di tengah sabuk
    final gleamPaint = Paint()
      ..color = pegoBlue.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 2.5, 129.5), 4, gleamPaint);
  }

  // ─────────────────────────────────────────────────────────────────
  // LENGAN KIRI — titik pivot di bahu kiri
  // ─────────────────────────────────────────────────────────────────
  void _drawLeftArm(Canvas canvas, double cx, double angle) {
    final pivotX = cx - 22.0;
    final pivotY = 114.0;

    canvas.save();
    canvas.translate(pivotX, pivotY);
    canvas.rotate(angle);
    canvas.translate(-pivotX, -pivotY);

    final paint = Paint()
      ..color = pegoBlue
      ..style = PaintingStyle.fill;

    final arm = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 35, 112, 14, 28),
      const Radius.circular(7),
    );
    canvas.drawRRect(arm, paint);
    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────────────
  // LENGAN KANAN — titik pivot di bahu kanan
  // ─────────────────────────────────────────────────────────────────
  void _drawRightArm(Canvas canvas, double cx, double angle) {
    final pivotX = cx + 22.0;
    final pivotY = 114.0;

    canvas.save();
    canvas.translate(pivotX, pivotY);
    canvas.rotate(angle);
    canvas.translate(-pivotX, -pivotY);

    final paint = Paint()
      ..color = pegoBlue
      ..style = PaintingStyle.fill;

    final arm = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx + 21, 112, 14, 28),
      const Radius.circular(7),
    );
    canvas.drawRRect(arm, paint);
    canvas.restore();
  }

  // ─────────────────────────────────────────────────────────────────
  // TELINGA / HEADPHONE — lingkaran besar di sisi kepala
  // ─────────────────────────────────────────────────────────────────
  void _drawEars(Canvas canvas, double cx) {
    final outerPaint = Paint()
      ..color = pegoBlue
      ..style = PaintingStyle.fill;

    // Lingkaran telinga kiri
    canvas.drawCircle(Offset(cx - 42, 70), 18, outerPaint);
    // Lingkaran telinga kanan
    canvas.drawCircle(Offset(cx + 42, 70), 18, outerPaint);
  }

  // ─────────────────────────────────────────────────────────────────
  // KEPALA — lingkaran besar, mendominasi karakter
  // ─────────────────────────────────────────────────────────────────
  void _drawHead(Canvas canvas, double cx) {
    // Lingkaran kepala biru
    final headPaint = Paint()
      ..color = pegoBlue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, 67), 36, headPaint);

    // Wajah abu-abu besar — lingkaran putih/abu di tengah
    final facePaint = Paint()
      ..color = pegoFaceGrey
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, 70), 28, facePaint);
  }

  // ─────────────────────────────────────────────────────────────────
  // WAJAH — mata oval hitam & senyum
  // ─────────────────────────────────────────────────────────────────
  void _drawFace(Canvas canvas, double cx) {
    final eyePaint = Paint()
      ..color = pegoDark
      ..style = PaintingStyle.fill;

    // Mata kiri
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 10, 67), width: 10, height: 14),
      eyePaint,
    );
    // Mata kanan
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 10, 67), width: 10, height: 14),
      eyePaint,
    );

    // Kilau putih di sudut atas mata
    final gleamPaint = Paint()
      ..color = pegoWhite
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 8.5, 63.5), 2.2, gleamPaint);
    canvas.drawCircle(Offset(cx + 11.5, 63.5), 2.2, gleamPaint);

    // Senyum lengkung ramah
    final smilePaint = Paint()
      ..color = pegoDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final smilePath = Path()
      ..moveTo(cx - 9, 79)
      ..quadraticBezierTo(cx, 87, cx + 9, 79);
    canvas.drawPath(smilePath, smilePaint);
  }

  // ─────────────────────────────────────────────────────────────────
  // ANTENA — dua antena tipis tegak lurus ke atas
  // ─────────────────────────────────────────────────────────────────
  void _drawAntennas(Canvas canvas, double cx) {
    final stickPaint = Paint()
      ..color = pegoBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final ballPaint = Paint()
      ..color = pegoBlue
      ..style = PaintingStyle.fill;

    // Antena kiri (tegak/sedikit condong kiri)
    final leftTopX = cx - 14.0;
    final leftTopY = 20.0;
    canvas.drawLine(Offset(cx - 8, 34), Offset(leftTopX, leftTopY), stickPaint);
    canvas.drawCircle(Offset(leftTopX, leftTopY), 5, ballPaint);

    // Antena kanan (tegak/sedikit condong kanan)
    final rightTopX = cx + 14.0;
    final rightTopY = 20.0;
    canvas.drawLine(Offset(cx + 8, 34), Offset(rightTopX, rightTopY), stickPaint);
    canvas.drawCircle(Offset(rightTopX, rightTopY), 5, ballPaint);
  }

  @override
  bool shouldRepaint(covariant _PegoRobotPainter oldDelegate) {
    return oldDelegate.showRipples != showRipples ||
        oldDelegate.ripplePhase != ripplePhase ||
        oldDelegate.leftArmAngle != leftArmAngle ||
        oldDelegate.rightArmAngle != rightArmAngle;
  }
}

// ─────────────────────────────────────────────────────────────────
// Widget Pego dengan animasi lambaian tangan + napas naik-turun
// ─────────────────────────────────────────────────────────────────

/// Widget Pego yang beranimasi (melambaikan tangan + bouncing ringan)
class PegoAnimatingWidget extends StatefulWidget {
  final double width;
  final double height;
  final bool isWaving;     // true: melambaikan tangan (selama analyzing)
  final bool showRipples;
  final String? customAssetPath;

  const PegoAnimatingWidget({
    super.key,
    this.width = 130,
    this.height = 170,
    this.isWaving = false,
    this.showRipples = true,
    this.customAssetPath,
  });

  @override
  State<PegoAnimatingWidget> createState() => _PegoAnimatingWidgetState();
}

class _PegoAnimatingWidgetState extends State<PegoAnimatingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _rightWaveAnim;
  late Animation<double> _leftWaveAnim;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    // Lengan kanan melambaikan tangan ke atas ("dada-dada")
    _rightWaveAnim = Tween<double>(begin: 1.95, end: 2.55).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    // Lengan kiri bergoyang ceria
    _leftWaveAnim = Tween<double>(begin: -0.2, end: 0.05).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    // Bounce ringan naik-turun seperti bernapas gembira
    _bounceAnim = Tween<double>(begin: 0.0, end: -4.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    if (widget.isWaving) {
      _waveController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PegoAnimatingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWaving && !oldWidget.isWaving) {
      _waveController.repeat(reverse: true);
    } else if (!widget.isWaving && oldWidget.isWaving) {
      _waveController.stop();
      _waveController.reset();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, widget.isWaving ? _bounceAnim.value : 0.0),
          child: PegoRobotWidget(
            width: widget.width,
            height: widget.height,
            customAssetPath: widget.customAssetPath,
            showRipples: widget.showRipples,
            leftArmAngle: widget.isWaving ? _leftWaveAnim.value : 0.0,
            rightArmAngle: widget.isWaving ? _rightWaveAnim.value : 0.0,
          ),
        );
      },
    );
  }
}
