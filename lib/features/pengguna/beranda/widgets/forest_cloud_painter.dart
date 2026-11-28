import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Variasi siluet awan vektor lembut bergaya ilustrasi PNG forest PediaGrow.
enum ForestCloudVariant {
  /// Siluet cumulus asimetris berlapis dengan ekor landai dan alas berombak lembut.
  asymmetric,

  /// Siluet cumulus memanjang dengan empat kubah bertingkat halus.
  elongated,

  /// Siluet 5-lobe mungil dan hangat.
  compact,

  /// Siluet awan tipis memanjang di ketinggian langit (high-altitude wisp).
  wispy,
}

/// Widget awan bergerak bergaya ilustrasi alami senada aset forest PNG PediaGrow:
/// gumpalan cumulus berlapis, alas berombak lembut, tepian berbaur halus,
/// dan pencahayaan konsisten dengan arah matahari/bulan.
class ForestCloudWidget extends StatelessWidget {
  final double width;
  final double height;
  final bool isNight;
  final double opacity;
  final bool flipHorizontal;
  final bool isHeader;
  final bool isHorizon;
  final ForestCloudVariant variant;

  const ForestCloudWidget({
    super.key,
    required this.width,
    required this.height,
    this.isNight = false,
    this.opacity = 1.0,
    this.flipHorizontal = false,
    this.isHeader = true,
    this.isHorizon = false,
    this.variant = ForestCloudVariant.asymmetric,
  });

  @override
  Widget build(BuildContext context) {
    // Flip diteruskan ke painter agar hanya siluet yang dicerminkan,
    // sementara arah cahaya matahari/bulan dan bayangan bawah tetap konsisten.
    return CustomPaint(
      size: Size(width, height),
      painter: ForestCloudPainter(
        isNight: isNight,
        opacity: opacity,
        isHeader: isHeader,
        isHorizon: isHorizon,
        variant: variant,
        flipHorizontal: flipHorizontal,
      ),
    );
  }
}

/// Painter bersama untuk menggambar awan berlapis lembut senada konsep visual PediaGrow.
class ForestCloudPainter extends CustomPainter {
  final bool isNight;
  final double opacity;
  final bool isHeader;
  final bool isHorizon;
  final ForestCloudVariant variant;
  final bool flipHorizontal;

  const ForestCloudPainter({
    required this.isNight,
    required this.opacity,
    this.isHeader = true,
    this.isHorizon = false,
    this.variant = ForestCloudVariant.asymmetric,
    this.flipHorizontal = false,
  });

  /// Membangun siluet kurva Bezier kontinu dengan kubah cumulus organik
  /// dan alas berombak lembut (tidak kaku datar).
  static Path buildSilhouette(double w, double h, ForestCloudVariant variant) {
    final path = Path();
    switch (variant) {
      case ForestCloudVariant.asymmetric:
        path.moveTo(w * 0.06, h * 0.84);
        path.cubicTo(w * 0.00, h * 0.81, w * 0.01, h * 0.62, w * 0.14, h * 0.62);
        path.cubicTo(w * 0.16, h * 0.39, w * 0.29, h * 0.35, w * 0.35, h * 0.45);
        path.cubicTo(w * 0.38, h * 0.09, w * 0.63, h * 0.08, w * 0.66, h * 0.42);
        path.cubicTo(w * 0.73, h * 0.28, w * 0.86, h * 0.36, w * 0.87, h * 0.62);
        path.cubicTo(w * 0.96, h * 0.63, w * 1.00, h * 0.81, w * 0.92, h * 0.85);
        // Alas berombak lembut mengikuti kontur gumpalan
        path.cubicTo(w * 0.74, h * 0.91, w * 0.62, h * 0.85, w * 0.49, h * 0.89);
        path.cubicTo(w * 0.34, h * 0.92, w * 0.20, h * 0.87, w * 0.06, h * 0.84);
        break;

      case ForestCloudVariant.elongated:
        path.moveTo(w * 0.05, h * 0.84);
        path.cubicTo(w * 0.00, h * 0.82, w * 0.02, h * 0.67, w * 0.14, h * 0.66);
        path.cubicTo(w * 0.15, h * 0.50, w * 0.24, h * 0.45, w * 0.28, h * 0.50);
        path.cubicTo(w * 0.30, h * 0.30, w * 0.40, h * 0.30, w * 0.43, h * 0.40);
        path.cubicTo(w * 0.46, h * 0.12, w * 0.61, h * 0.13, w * 0.63, h * 0.36);
        path.cubicTo(w * 0.70, h * 0.27, w * 0.78, h * 0.36, w * 0.79, h * 0.52);
        path.cubicTo(w * 0.84, h * 0.46, w * 0.90, h * 0.55, w * 0.90, h * 0.67);
        path.cubicTo(w * 0.97, h * 0.68, w * 1.00, h * 0.82, w * 0.93, h * 0.85);
        path.cubicTo(w * 0.74, h * 0.90, w * 0.56, h * 0.86, w * 0.42, h * 0.89);
        path.cubicTo(w * 0.26, h * 0.91, w * 0.15, h * 0.86, w * 0.05, h * 0.84);
        break;

      case ForestCloudVariant.compact:
        path.moveTo(w * 0.07, h * 0.84);
        path.cubicTo(w * 0.00, h * 0.82, w * 0.03, h * 0.61, w * 0.16, h * 0.60);
        path.cubicTo(w * 0.18, h * 0.42, w * 0.27, h * 0.39, w * 0.31, h * 0.45);
        path.cubicTo(w * 0.33, h * 0.16, w * 0.56, h * 0.14, w * 0.60, h * 0.36);
        path.cubicTo(w * 0.69, h * 0.26, w * 0.81, h * 0.36, w * 0.82, h * 0.55);
        path.cubicTo(w * 0.92, h * 0.54, w * 0.99, h * 0.79, w * 0.91, h * 0.84);
        path.cubicTo(w * 0.72, h * 0.90, w * 0.55, h * 0.88, w * 0.44, h * 0.90);
        path.cubicTo(w * 0.28, h * 0.91, w * 0.16, h * 0.87, w * 0.07, h * 0.84);
        break;

      case ForestCloudVariant.wispy:
        path.moveTo(w * 0.03, h * 0.76);
        path.cubicTo(w * 0.00, h * 0.73, w * 0.05, h * 0.60, w * 0.17, h * 0.61);
        path.cubicTo(w * 0.22, h * 0.43, w * 0.35, h * 0.42, w * 0.40, h * 0.50);
        path.cubicTo(w * 0.45, h * 0.26, w * 0.63, h * 0.25, w * 0.68, h * 0.48);
        path.cubicTo(w * 0.75, h * 0.41, w * 0.84, h * 0.49, w * 0.85, h * 0.62);
        path.cubicTo(w * 0.95, h * 0.62, w * 1.00, h * 0.74, w * 0.95, h * 0.78);
        path.quadraticBezierTo(w * 0.50, h * 0.84, w * 0.03, h * 0.76);
        break;
    }
    path.close();
    return path;
  }

  /// Membangun gumpalan cumulus lapis depan yang menumpuk lembut di bagian bawah awan
  /// (terinspirasi langsung dari awan berlapis pada aset `beranda_landscape_footer_fiks.png`).
  static Path _buildForegroundPuff(double w, double h, ForestCloudVariant variant) {
    final p = Path();
    switch (variant) {
      case ForestCloudVariant.asymmetric:
        p.moveTo(w * 0.12, h * 0.94);
        p.cubicTo(w * 0.13, h * 0.62, w * 0.28, h * 0.58, w * 0.34, h * 0.68);
        p.cubicTo(w * 0.38, h * 0.43, w * 0.59, h * 0.43, w * 0.63, h * 0.65);
        p.cubicTo(w * 0.70, h * 0.58, w * 0.81, h * 0.66, w * 0.83, h * 0.94);
        p.close();
        break;

      case ForestCloudVariant.elongated:
        p.moveTo(w * 0.18, h * 0.94);
        p.cubicTo(w * 0.20, h * 0.64, w * 0.32, h * 0.58, w * 0.38, h * 0.67);
        p.cubicTo(w * 0.43, h * 0.46, w * 0.61, h * 0.46, w * 0.65, h * 0.66);
        p.cubicTo(w * 0.72, h * 0.58, w * 0.83, h * 0.65, w * 0.85, h * 0.94);
        p.close();
        break;

      case ForestCloudVariant.compact:
        p.moveTo(w * 0.16, h * 0.94);
        p.cubicTo(w * 0.18, h * 0.61, w * 0.32, h * 0.55, w * 0.38, h * 0.64);
        p.cubicTo(w * 0.44, h * 0.44, w * 0.65, h * 0.45, w * 0.69, h * 0.66);
        p.cubicTo(w * 0.75, h * 0.62, w * 0.84, h * 0.70, w * 0.85, h * 0.94);
        p.close();
        break;

      case ForestCloudVariant.wispy:
        return p;
    }
    return p;
  }

  static Path _mirrorHorizontally(Path path, double w) {
    final matrix = Float64List.fromList([
      -1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      w, 0, 0, 1,
    ]);
    return path.transform(matrix);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    var silhouette = buildSilhouette(w, h, variant);
    var frontPuff = _buildForegroundPuff(w, h, variant);
    if (flipHorizontal) {
      silhouette = _mirrorHorizontally(silhouette, w);
      if (variant != ForestCloudVariant.wispy) {
        frontPuff = _mirrorHorizontally(frontPuff, w);
      }
    }

    final effectiveOpacity = isHeader
        ? (isHorizon ? (opacity * 1.18).clamp(0.0, 0.94) : (opacity * 1.06).clamp(0.0, 0.94))
        : (isNight ? (opacity * 0.42).clamp(0.0, 1.0) : (opacity * 0.85).clamp(0.0, 1.0));

    final Color topColor;
    final Color midColor;
    final Color baseTintColor;
    final Color bottomShadowColor;
    final Color puffTopColor;
    final Color puffCreaseShadow;

    if (isHeader) {
      if (isNight) {
        topColor = const Color(0xFF3E6396).withValues(alpha: effectiveOpacity);
        midColor = const Color(0xFF284570).withValues(alpha: effectiveOpacity);
        baseTintColor = const Color(0xFF182D50).withValues(alpha: effectiveOpacity);
        bottomShadowColor = const Color(0xFF10203B).withValues(alpha: (effectiveOpacity * 0.42).clamp(0.0, 1.0));
        puffTopColor = const Color(0xFF4F77AE).withValues(alpha: (effectiveOpacity * 0.52).clamp(0.0, 1.0));
        puffCreaseShadow = const Color(0xFF132542).withValues(alpha: (effectiveOpacity * 0.34).clamp(0.0, 1.0));
      } else if (isHorizon) {
        // Awan horizon di atas latar langit pastel terang: puncak putih jernih & perut biru-cyan lembut
        topColor = const Color(0xFFFFFFFF).withValues(alpha: effectiveOpacity);
        midColor = const Color(0xFFF2FBFF).withValues(alpha: effectiveOpacity);
        baseTintColor = const Color(0xFFC2E8FA).withValues(alpha: effectiveOpacity);
        bottomShadowColor = const Color(0xFF9AD5F5).withValues(alpha: (effectiveOpacity * 0.42).clamp(0.0, 1.0));
        puffTopColor = Colors.white.withValues(alpha: (effectiveOpacity * 0.88).clamp(0.0, 1.0));
        puffCreaseShadow = const Color(0xFF8ECDF0).withValues(alpha: (effectiveOpacity * 0.24).clamp(0.0, 1.0));
      } else {
        topColor = const Color(0xFFFFFFFF).withValues(alpha: effectiveOpacity);
        midColor = const Color(0xFFF3FAFF).withValues(alpha: effectiveOpacity);
        baseTintColor = const Color(0xFFD0ECFC).withValues(alpha: effectiveOpacity);
        bottomShadowColor = const Color(0xFFAAD8F5).withValues(alpha: (effectiveOpacity * 0.34).clamp(0.0, 1.0));
        puffTopColor = Colors.white.withValues(alpha: (effectiveOpacity * 0.78).clamp(0.0, 1.0));
        puffCreaseShadow = const Color(0xFF9ED4F5).withValues(alpha: (effectiveOpacity * 0.20).clamp(0.0, 1.0));
      }
    } else {
      if (isNight) {
        topColor = const Color(0xFF344D6B).withValues(alpha: effectiveOpacity);
        midColor = const Color(0xFF23364D).withValues(alpha: effectiveOpacity);
        baseTintColor = const Color(0xFF162436).withValues(alpha: effectiveOpacity);
        bottomShadowColor = const Color(0xFF0E1826).withValues(alpha: (effectiveOpacity * 0.35).clamp(0.0, 1.0));
        puffTopColor = const Color(0xFF456387).withValues(alpha: (effectiveOpacity * 0.45).clamp(0.0, 1.0));
        puffCreaseShadow = const Color(0xFF111C2B).withValues(alpha: (effectiveOpacity * 0.28).clamp(0.0, 1.0));
      } else {
        topColor = const Color(0xFFF3F9FF).withValues(alpha: effectiveOpacity);
        midColor = const Color(0xFFDFF0FD).withValues(alpha: effectiveOpacity);
        baseTintColor = const Color(0xFFC2E1FA).withValues(alpha: effectiveOpacity);
        bottomShadowColor = const Color(0xFF9ECAF5).withValues(alpha: (effectiveOpacity * 0.28).clamp(0.0, 1.0));
        puffTopColor = Colors.white.withValues(alpha: (effectiveOpacity * 0.65).clamp(0.0, 1.0));
        puffCreaseShadow = const Color(0xFF9ACAF4).withValues(alpha: (effectiveOpacity * 0.18).clamp(0.0, 1.0));
      }
    }

    final bounds = Rect.fromLTWH(0, 0, w, h);
    final edgeBlur = variant == ForestCloudVariant.wispy ? 2.4 : 1.5;

    // 1. Feather atmosferik halus di tepi luar agar menyatu alami tanpa terkesan blur kotor
    canvas.drawPath(
      silhouette,
      Paint()
        ..color = topColor.withValues(alpha: (topColor.a * 0.20).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, edgeBlur)
        ..isAntiAlias = true,
    );

    // 2. Badan utama awan dengan gradasi volumetrik lembut
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(0.18, -1.0),
        end: const Alignment(-0.14, 1.0),
        colors: [topColor, midColor, baseTintColor],
        stops: const [0.0, 0.54, 1.0],
      ).createShader(bounds)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawPath(silhouette, bodyPaint);

    // 3. Kedalaman berlapis khas ilustrasi awan PediaGrow
    canvas.save();
    canvas.clipPath(silhouette);

    // 3a. Sorotan kontur puncak kubah atas
    final litRim = Path.combine(
      PathOperation.difference,
      silhouette,
      silhouette.shift(Offset(-w * 0.012, h * 0.12)),
    );
    canvas.drawPath(
      litRim,
      Paint()
        ..color = puffTopColor.withValues(alpha: (puffTopColor.a * 0.45).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
        ..isAntiAlias = true,
    );

    // 3b. Lapisan gumpalan depan (foreground cumulus tuft) seperti pada aset footer PNG
    if (variant != ForestCloudVariant.wispy) {
      // Bayangan lipatan halus antara gumpalan belakang & depan
      canvas.drawPath(
        frontPuff.shift(Offset(0, -h * 0.045)),
        Paint()
          ..color = puffCreaseShadow
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.2)
          ..isAntiAlias = true,
      );

      // Gumpalan depan cerah yang membaur lembut ke alas
      final puffRect = Rect.fromLTWH(0, h * 0.38, w, h * 0.62);
      canvas.drawPath(
        frontPuff,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              puffTopColor,
              puffTopColor.withValues(alpha: (puffTopColor.a * 0.30).clamp(0.0, 1.0)),
              puffTopColor.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.58, 1.0],
          ).createShader(puffRect)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
    }

    // 3c. Gradasi bayangan bawah yang lembut & grounding
    final bottomFadeRect = Rect.fromLTWH(0, h * 0.58, w, h * 0.42);
    canvas.drawRect(
      bottomFadeRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            bottomShadowColor.withValues(alpha: 0.0),
            bottomShadowColor,
          ],
          stops: const [0.0, 1.0],
        ).createShader(bottomFadeRect),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ForestCloudPainter oldDelegate) =>
      oldDelegate.isNight != isNight ||
      oldDelegate.opacity != opacity ||
      oldDelegate.isHeader != isHeader ||
      oldDelegate.isHorizon != isHorizon ||
      oldDelegate.variant != variant ||
      oldDelegate.flipHorizontal != flipHorizontal;
}

