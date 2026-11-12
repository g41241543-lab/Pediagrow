import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'forest_cloud_painter.dart';

/// Widget latar belakang full-page dengan animasi awan dan burung yang natural.
///
/// Ditempatkan di belakang semua konten beranda menggunakan [IgnorePointer]
/// sehingga tidak menghalangi interaksi pada menu atau card.
///
/// Awan bergerak perlahan dari kanan ke kiri dan kembali (drift).
/// Burung terbang melintasi layar dengan kepakan sayap alami.
class FullPageSkyBackground extends StatefulWidget {
  const FullPageSkyBackground({super.key});

  @override
  State<FullPageSkyBackground> createState() => _FullPageSkyBackgroundState();
}

class _FullPageSkyBackgroundState extends State<FullPageSkyBackground>
    with TickerProviderStateMixin {
  late final AnimationController _cloudSlowCtrl;
  late final AnimationController _cloudMedCtrl;
  late final AnimationController _bird1Ctrl;
  late final AnimationController _bird2Ctrl;
  late final AnimationController _wingCtrl;

  late final Animation<double> _cloudSlowX;
  late final Animation<double> _cloudMedX;
  late final Animation<double> _cloudSlowY;
  late final Animation<double> _bird1X;
  late final Animation<double> _bird1Y;
  late final Animation<double> _bird2X;
  late final Animation<double> _bird2Y;
  late final Animation<double> _wingFlap;

  @override
  void initState() {
    super.initState();

    _cloudSlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat(reverse: true);

    _cloudMedCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    )..repeat(reverse: true);

    _cloudSlowX = Tween<double>(begin: -22.0, end: 22.0).animate(
      CurvedAnimation(parent: _cloudSlowCtrl, curve: Curves.easeInOutSine),
    );

    _cloudMedX = Tween<double>(begin: -14.0, end: 14.0).animate(
      CurvedAnimation(parent: _cloudMedCtrl, curve: Curves.easeInOutSine),
    );

    _cloudSlowY = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _cloudSlowCtrl, curve: Curves.easeInOutQuad),
    );

    _bird1Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 35),
    )..repeat(reverse: true);

    _bird2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat(reverse: true);

    _bird1X = Tween<double>(
      begin: -0.15,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _bird1Ctrl, curve: Curves.easeInOutSine));

    _bird1Y = Tween<double>(
      begin: -5.0,
      end: 5.0,
    ).animate(CurvedAnimation(parent: _bird1Ctrl, curve: Curves.easeInOutSine));

    _bird2X = Tween<double>(
      begin: 1.10,
      end: -0.10,
    ).animate(CurvedAnimation(parent: _bird2Ctrl, curve: Curves.easeInOutSine));

    _bird2Y = Tween<double>(begin: -4.0, end: 6.0).animate(
      CurvedAnimation(parent: _bird2Ctrl, curve: Curves.easeInOutCubic),
    );

    _wingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _wingFlap = Tween<double>(
      begin: -0.8,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _wingCtrl, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _cloudSlowCtrl.dispose();
    _cloudMedCtrl.dispose();
    _bird1Ctrl.dispose();
    _bird2Ctrl.dispose();
    _wingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fallback = MediaQuery.of(context).size;
        final w = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : fallback.width;
        final h = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : fallback.height;
        return _buildSky(w, h, isDark);
      },
    );
  }

  Widget _buildSky(double w, double h, bool isDark) {
    const footerAspectRatio = 768.0 / 1376.0;
    final footerH = w * footerAspectRatio;
    final footerTop = math.max(0.0, h - footerH);
    final transitionLead = math.min(126.0, footerTop * 0.45);
    final transitionTop = math.max(0.0, footerTop - transitionLead);
    final transitionHeight = math.max(1.0, h - transitionTop);
    final joinStop = ((footerTop - transitionTop) / transitionHeight).clamp(
      0.12,
      0.72,
    );
    final deepStop =
        ((footerTop + footerH * 0.24 - transitionTop) / transitionHeight).clamp(
          joinStop + 0.08,
          0.96,
        );
    final showHorizon = footerTop > 180.0;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _cloudSlowCtrl,
          _cloudMedCtrl,
          _bird1Ctrl,
          _bird2Ctrl,
          _wingCtrl,
        ]),
        builder: (context, _) {
          final driftSlow = _cloudSlowX.value;
          final driftMed = _cloudMedX.value;
          final floatY = _cloudSlowY.value;
          final wing = _wingFlap.value;

          final birdColor1 = const Color(0xFF1E3A8A).withValues(alpha: 0.48);
          final birdColor2 = const Color(0xFF1E3A8A).withValues(alpha: 0.36);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Lapisan dasar halaman menyatu mulus dengan ujung bawah gradien header
              Positioned.fill(
                child: ColoredBox(
                  color: isDark ? const Color(0xFF0B1014) : Colors.white,
                ),
              ),

              // Gradasi atmosfer transisi langit -> tepi atas ilustrasi PNG forest
              if (showHorizon)
                Positioned(
                  left: 0,
                  right: 0,
                  top: transitionTop,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDark
                            ? const [
                                Color(0x000B1014),
                                Color(0xFF091221),
                                Color(0xFF06122B),
                                Color(0xFF04112C),
                                Color(0xFF051636),
                                Color(0xFF05193A),
                              ]
                            : const [
                                Color(0x00FFFFFF),
                                Color(0xD8F2FBFE),
                                Color(0xFFDCF6FA),
                                Color(0xFFCBF2F4),
                                Color(0xFFC2F1EC),
                                Color(0xFFC9F3E9),
                              ],
                        stops: [
                          0.0,
                          joinStop * 0.45,
                          joinStop * 0.88,
                          joinStop,
                          deepStop,
                          1.0,
                        ],
                      ),
                    ),
                  ),
                ),

              // Panorama awan horizon di ruang terbuka di atas forest PNG (tanpa menyentuh card)
              if (showHorizon) ...[
                // Horizon 1 — Kiri atas cakrawala
                _cloud(
                  left: 10 + (driftSlow * 0.55),
                  top: footerTop - 84 + (floatY * 0.50),
                  w: 108,
                  h: 37,
                  opacity: isDark ? 0.42 : 0.58,
                  flipX: false,
                  isDark: isDark,
                  useSkyPalette: true,
                  variant: ForestCloudVariant.asymmetric,
                ),

                // Horizon 2 — Kanan penyeimbang cakrawala
                _cloud(
                  right: 12 + (-driftMed * 0.60),
                  top: footerTop - 68 - (floatY * 0.40),
                  w: 112,
                  h: 38,
                  opacity: isDark ? 0.44 : 0.60,
                  flipX: true,
                  isDark: isDark,
                  useSkyPalette: true,
                  variant: ForestCloudVariant.asymmetric,
                ),

                // Horizon 3 — Awan jauh bagian tengah atas
                _cloud(
                  left: (w * 0.43) + (driftSlow * 0.40),
                  top: footerTop - 86 + (floatY * 0.35),
                  w: 72,
                  h: 26,
                  opacity: isDark ? 0.26 : 0.42,
                  flipX: true,
                  isDark: isDark,
                  useSkyPalette: true,
                  variant: ForestCloudVariant.compact,
                ),

                // Horizon 4 — Awan rendah lembah kiri-tengah menyatu ke gradien forest PNG
                _cloud(
                  left: (w * 0.16) + (driftMed * 0.45),
                  top: footerTop - 32 + (floatY * 0.30),
                  w: 118,
                  h: 34,
                  opacity: isDark ? 0.34 : 0.48,
                  flipX: false,
                  isDark: isDark,
                  useSkyPalette: true,
                  variant: ForestCloudVariant.elongated,
                ),

                // Horizon 5 — Kabut awan kanan-rendah membaur lembut ke balik ShaderMask forest PNG
                _cloud(
                  right: (w * 0.08) - (driftSlow * 0.35),
                  top: footerTop - 18 + (floatY * 0.25),
                  w: 94,
                  h: 28,
                  opacity: isDark ? 0.28 : 0.42,
                  flipX: true,
                  isDark: isDark,
                  useSkyPalette: true,
                  variant: ForestCloudVariant.elongated,
                ),
              ],

              // Siluet burung melintas di cakrawala terbuka di atas pucuk hutan (hanya mode siang)
              if (!isDark && showHorizon) ...[
                Positioned(
                  left: _bird1X.value * w,
                  top: footerTop - 74 + _bird1Y.value,
                  child: _PageBird(
                    width: 18,
                    height: 9,
                    wingState: wing,
                    color: birdColor1,
                  ),
                ),
                Positioned(
                  left: _bird1X.value * w - 24,
                  top: footerTop - 82 + (_bird1Y.value * 0.8),
                  child: _PageBird(
                    width: 13,
                    height: 6.5,
                    wingState: -wing * 0.85,
                    color: birdColor2,
                  ),
                ),
                Positioned(
                  left: _bird2X.value * w - 16,
                  top: footerTop - 42 + (_bird2Y.value * 0.7),
                  child: _PageBird(
                    width: 13,
                    height: 6.5,
                    wingState: -wing * 0.7,
                    color: birdColor2,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Positioned _cloud({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double w,
    required double h,
    required double opacity,
    required bool flipX,
    required bool isDark,
    bool useSkyPalette = false,
    ForestCloudVariant variant = ForestCloudVariant.asymmetric,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: ForestCloudWidget(
        width: w,
        height: h,
        isNight: isDark,
        opacity: opacity,
        flipHorizontal: flipX,
        isHeader: useSkyPalette,
        variant: variant,
      ),
    );
  }
}

class _PageBird extends StatelessWidget {
  final double width;
  final double height;
  final double wingState;
  final Color color;

  const _PageBird({
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
        painter: _PageBirdPainter(wingState: wingState, color: color),
      ),
    );
  }
}

class _PageBirdPainter extends CustomPainter {
  final double wingState;
  final Color color;

  const _PageBirdPainter({required this.wingState, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;

    final tipY = h * 0.36 + (wingState * h * 0.34);
    final elbowY = h * 0.26 + (wingState * h * 0.18);

    final path = Path();
    // Paruh & kepala halus
    path.moveTo(cx, h * 0.22);

    // Sayap kiri: Bahu -> Siku -> Ujung sayap meruncing
    path.quadraticBezierTo(cx - w * 0.10, h * 0.28, cx - w * 0.26, elbowY);
    path.quadraticBezierTo(cx - w * 0.38, tipY - h * 0.06, 0, tipY);
    path.quadraticBezierTo(
      cx - w * 0.32,
      tipY + h * 0.22,
      cx - w * 0.07,
      h * 0.58,
    );

    // Ekor kipas stabil
    path.lineTo(cx - w * 0.05, h * 0.78);
    path.quadraticBezierTo(cx, h * 0.90, cx + w * 0.05, h * 0.78);

    // Sayap kanan
    path.lineTo(cx + w * 0.07, h * 0.58);
    path.quadraticBezierTo(
      cx + w * 0.32,
      tipY + h * 0.22,
      w,
      tipY,
    );
    path.quadraticBezierTo(cx + w * 0.38, tipY - h * 0.06, cx + w * 0.26, elbowY);
    path.quadraticBezierTo(cx + w * 0.10, h * 0.28, cx, h * 0.22);
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _PageBirdPainter old) =>
      old.wingState != wingState || old.color != color;
}
