import 'package:flutter/material.dart';

/// Variasi siluet awan vektor bersih bergaya ilustrasi PNG forest.
enum ForestCloudVariant {
  /// Siluet 3-kubah asimetris klasik dengan ekor datar landai di kiri.
  asymmetric,

  /// Siluet 4-kubah memanjang bertingkat halus.
  elongated,

  /// Siluet 5-lobe mungil dan seimbang.
  compact,
}

/// Widget awan bergerak dengan gaya ilustrasi bersih khas footer PNG forest:
/// beralas datar horizontal (*flat horizon baseline*), kubah lengkung lapang,
/// dan shading two-tone tanpa blur kotor.
class ForestCloudWidget extends StatelessWidget {
  final double width;
  final double height;
  final bool isNight;
  final double opacity;
  final bool flipHorizontal;
  final bool isHeader;
  final ForestCloudVariant variant;

  const ForestCloudWidget({
    super.key,
    required this.width,
    required this.height,
    this.isNight = false,
    this.opacity = 1.0,
    this.flipHorizontal = false,
    this.isHeader = true,
    this.variant = ForestCloudVariant.asymmetric,
  });

  @override
  Widget build(BuildContext context) {
    Widget cloud = CustomPaint(
      size: Size(width, height),
      painter: ForestCloudPainter(
        isNight: isNight,
        opacity: opacity,
        isHeader: isHeader,
        variant: variant,
      ),
    );

    if (flipHorizontal) {
      cloud = Transform.flip(flipX: true, child: cloud);
    }

    return cloud;
  }
}

/// Painter bersama untuk menggambar awan bergaya ilustrasi vektor PNG forest.
class ForestCloudPainter extends CustomPainter {
  final bool isNight;
  final double opacity;
  final bool isHeader;
  final ForestCloudVariant variant;

  const ForestCloudPainter({
    required this.isNight,
    required this.opacity,
    this.isHeader = true,
    this.variant = ForestCloudVariant.asymmetric,
  });

  /// Membangun siluet kurva Bezier kontinu dengan alas datar horizontal
  /// sesuai proporsi awan pada aset forest PNG.
  static Path buildSilhouette(double w, double h, ForestCloudVariant variant) {
    final path = Path();
    switch (variant) {
      case ForestCloudVariant.asymmetric:
        // Kiri bawah datar -> ekor kiri -> kubah kiri -> puncak utama -> kubah kanan -> ujung kanan datar
        path.moveTo(w * 0.04, h * 0.87);
        path.cubicTo(w * -0.01, h * 0.86, w * 0.02, h * 0.68, w * 0.14, h * 0.70);
        path.cubicTo(w * 0.16, h * 0.44, w * 0.29, h * 0.41, w * 0.33, h * 0.51);
        path.cubicTo(w * 0.35, h * 0.12, w * 0.63, h * 0.12, w * 0.65, h * 0.46);
        path.cubicTo(w * 0.71, h * 0.28, w * 0.85, h * 0.37, w * 0.86, h * 0.66);
        path.cubicTo(w * 0.95, h * 0.65, w * 1.00, h * 0.85, w * 0.93, h * 0.87);
        path.quadraticBezierTo(w * 0.50, h * 0.885, w * 0.04, h * 0.87);
        break;

      case ForestCloudVariant.elongated:
        path.moveTo(w * 0.04, h * 0.87);
        path.cubicTo(w * -0.01, h * 0.86, w * 0.02, h * 0.73, w * 0.14, h * 0.72);
        path.cubicTo(w * 0.14, h * 0.57, w * 0.23, h * 0.51, w * 0.26, h * 0.56);
        path.cubicTo(w * 0.27, h * 0.34, w * 0.37, h * 0.35, w * 0.40, h * 0.44);
        path.cubicTo(w * 0.42, h * 0.13, w * 0.59, h * 0.14, w * 0.60, h * 0.37);
        path.cubicTo(w * 0.67, h * 0.26, w * 0.76, h * 0.36, w * 0.76, h * 0.54);
        path.cubicTo(w * 0.81, h * 0.46, w * 0.88, h * 0.55, w * 0.88, h * 0.68);
        path.cubicTo(w * 0.96, h * 0.69, w * 0.99, h * 0.85, w * 0.94, h * 0.87);
        path.quadraticBezierTo(w * 0.50, h * 0.885, w * 0.04, h * 0.87);
        break;

      case ForestCloudVariant.compact:
        path.moveTo(w * 0.05, h * 0.86);
        path.cubicTo(w * 0.00, h * 0.85, w * 0.04, h * 0.67, w * 0.15, h * 0.67);
        path.cubicTo(w * 0.15, h * 0.50, w * 0.24, h * 0.47, w * 0.27, h * 0.51);
        path.cubicTo(w * 0.26, h * 0.26, w * 0.38, h * 0.27, w * 0.41, h * 0.40);
        path.cubicTo(w * 0.43, h * 0.14, w * 0.61, h * 0.15, w * 0.62, h * 0.35);
        path.cubicTo(w * 0.71, h * 0.27, w * 0.79, h * 0.41, w * 0.79, h * 0.56);
        path.cubicTo(w * 0.89, h * 0.54, w * 0.99, h * 0.83, w * 0.93, h * 0.86);
        path.quadraticBezierTo(w * 0.50, h * 0.875, w * 0.05, h * 0.86);
        break;
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final silhouette = buildSilhouette(w, h, variant);

    final effectiveOpacity = isHeader
        ? (opacity + 0.32).clamp(0.0, 1.0)
        : (isNight ? (opacity * 0.38).clamp(0.0, 1.0) : opacity.clamp(0.0, 1.0));

    final Color bodyColor;
    final Color shadowColor;
    final Color highlightColor;

    if (isHeader) {
      if (isNight) {
        // Mengikuti palet awan malam pada beranda_landscape_footer_dark.png
        bodyColor = const Color(0xFF25406B).withValues(alpha: effectiveOpacity);
        shadowColor = const Color(0xFF172B4B).withValues(alpha: effectiveOpacity);
        highlightColor = const Color(0xFF3E6396).withValues(alpha: (effectiveOpacity * 0.80).clamp(0.0, 1.0));
      } else {
        // Mengikuti palet awan siang bersih pada beranda_landscape_footer_fiks.png
        bodyColor = const Color(0xFFF9FDFF).withValues(alpha: effectiveOpacity);
        shadowColor = const Color(0xFFD0EFFB).withValues(alpha: effectiveOpacity);
        highlightColor = Colors.white.withValues(alpha: effectiveOpacity);
      }
    } else {
      if (isNight) {
        bodyColor = const Color(0xFF23364D).withValues(alpha: effectiveOpacity);
        shadowColor = const Color(0xFF162436).withValues(alpha: effectiveOpacity);
        highlightColor = const Color(0xFF344D6B).withValues(alpha: (effectiveOpacity * 0.75).clamp(0.0, 1.0));
      } else {
        // Untuk latar putih scroll beranda agar awan lembut tetap terlihat jernih
        bodyColor = const Color(0xFFD8ECFC).withValues(alpha: effectiveOpacity);
        shadowColor = const Color(0xFFBEDCFA).withValues(alpha: effectiveOpacity);
        highlightColor = const Color(0xFFF3F9FF).withValues(alpha: effectiveOpacity);
      }
    }

    // 1. Badan utama awan yang bersih & tajam tanpa blur
    canvas.drawPath(
      silhouette,
      Paint()
        ..color = bodyColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    canvas.save();
    canvas.clipPath(silhouette);

    // 2. Pita bayangan melengkung khas vektor forest di alas datar & sisi kanan bawah
    final shadowBand = Path()
      ..moveTo(0, h * 0.84)
      ..cubicTo(
        w * 0.36, h * 0.83,
        w * 0.68, h * 0.77,
        w * 0.94, h * 0.56,
      )
      ..lineTo(w, h * 0.56)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(
      shadowBand,
      Paint()
        ..color = shadowColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    // 3. Sorotan sabit lembut hanya pada puncak kubah atas (tidak mengenai alas datar)
    final shifted = silhouette.shift(Offset(w * 0.010, h * 0.052));
    final topCrescent = Path.combine(PathOperation.difference, silhouette, shifted);
    canvas.clipRect(Rect.fromLTWH(0, 0, w, h * 0.74));
    canvas.drawPath(
      topCrescent,
      Paint()
        ..color = highlightColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ForestCloudPainter oldDelegate) =>
      oldDelegate.isNight != isNight ||
      oldDelegate.opacity != opacity ||
      oldDelegate.isHeader != isHeader ||
      oldDelegate.variant != variant;
}

