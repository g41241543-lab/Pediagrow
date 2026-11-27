import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../features/pengguna/beranda/widgets/forest_cloud_painter.dart';

/// Widget reusable untuk menampilkan ilustrasi pemandangan lanskap hutan,
/// rumput, gunung, dan tenda sebagai penutup footer halaman (misalnya di Beranda,
/// Grafik Pertumbuhan, Resep MPASI, dan Menu Profil).
///
/// Mendukung awan horizon yang melayang lembut serta gradasi atmosferik langit-ke-hutan
/// agar menyatu secara mulus pada seluruh halaman tanpa membutuhkan latar langit penuh.
///
/// Menggunakan aset terpusat: `assets/images/beranda_landscape_footer_fiks.png`
/// dan `beranda_landscape_footer_dark.png`.
class IllustrationForestFooter extends StatefulWidget {
  /// Tinggi kustom opsional, jika null akan mengikuti rasio lebar layar (fitWidth)
  final double? height;

  /// Penyesuaian box fit gambar
  final BoxFit fit;

  /// Menampilkan awan horizon melayang dan gradasi atmosfer di atas pucuk hutan.
  /// Default `true` agar seluruh halaman otomatis mendapatkan transisi awan yang menyatu.
  /// Set `false` jika halaman sudah menggunakan [FullPageSkyBackground].
  final bool withClouds;

  /// Warna latar belakang atas tempat gradasi langit footer berbaur secara halus.
  /// Jika null, otomatis mengikuti latar standar (`Colors.white` / `#0B1014`).
  /// Berguna untuk halaman berlatar warna khusus seperti biru kuis Permainan.
  final Color? backgroundBlendColor;

  const IllustrationForestFooter({
    super.key,
    this.height,
    this.fit = BoxFit.fitWidth,
    this.withClouds = true,
    this.backgroundBlendColor,
  });

  @override
  State<IllustrationForestFooter> createState() =>
      _IllustrationForestFooterState();
}

class _IllustrationForestFooterState extends State<IllustrationForestFooter>
    with TickerProviderStateMixin {
  AnimationController? _driftCtrl;
  AnimationController? _floatCtrl;
  Animation<double>? _driftSlow;
  Animation<double>? _driftMed;
  Animation<double>? _floatY;

  @override
  void initState() {
    super.initState();
    if (widget.withClouds) {
      _initAnim();
    }
  }

  void _initAnim() {
    _driftCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 42),
    );

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );

    final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (!isTest) {
      _driftCtrl?.repeat(reverse: true);
      _floatCtrl?.repeat(reverse: true);
    }

    _driftSlow = Tween<double>(begin: -9.0, end: 9.0).animate(
      CurvedAnimation(parent: _driftCtrl!, curve: Curves.easeInOutSine),
    );
    _driftMed = Tween<double>(begin: 7.0, end: -7.0).animate(
      CurvedAnimation(parent: _driftCtrl!, curve: Curves.easeInOutSine),
    );
    _floatY = Tween<double>(begin: -2.2, end: 2.2).animate(
      CurvedAnimation(parent: _floatCtrl!, curve: Curves.easeInOutSine),
    );
  }

  @override
  void didUpdateWidget(IllustrationForestFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.withClouds && _driftCtrl == null) {
      _initAnim();
    } else if (!widget.withClouds && _driftCtrl != null) {
      _driftCtrl?.dispose();
      _floatCtrl?.dispose();
      _driftCtrl = null;
      _floatCtrl = null;
    }
  }

  @override
  void dispose() {
    _driftCtrl?.dispose();
    _floatCtrl?.dispose();
    super.dispose();
  }

  LinearGradient _buildSkyGradient({
    required bool isDark,
    required double joinStop,
    required double deepStop,
  }) {
    final baseTop = widget.backgroundBlendColor ??
        (isDark ? const Color(0xFF0B1014) : Colors.white);
    final stops = [
      0.0,
      joinStop * 0.42,
      joinStop * 0.85,
      joinStop,
      deepStop,
      1.0,
    ];

    if (isDark) {
      final mid1 = widget.backgroundBlendColor != null
          ? Color.lerp(baseTop, const Color(0xFF091221), 0.60)!
              .withValues(alpha: 0.72)
          : const Color(0xC4091221);
      final mid2 = widget.backgroundBlendColor != null
          ? Color.lerp(baseTop, const Color(0xFF06122B), 0.86)!
              .withValues(alpha: 0.92)
          : const Color(0xF006122B);

      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          baseTop.withValues(alpha: 0.0),
          mid1,
          mid2,
          const Color(0xFF04112C),
          const Color(0xFF051636),
          const Color(0xFF05193A),
        ],
        stops: stops,
      );
    }

    final isCustomTint = widget.backgroundBlendColor != null &&
        widget.backgroundBlendColor != Colors.white &&
        widget.backgroundBlendColor != const Color(0xFFF8FAFC);

    final mid1 = isCustomTint
        ? Color.lerp(baseTop, const Color(0xFF9CD4F4), 0.48)!
            .withValues(alpha: 0.66)
        : const Color(0xA8EEF9FD);
    final mid2 = isCustomTint
        ? Color.lerp(baseTop, const Color(0xFFDCF6FA), 0.78)!
            .withValues(alpha: 0.92)
        : const Color(0xEBDCF6FA);

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        baseTop.withValues(alpha: 0.0),
        mid1,
        mid2,
        const Color(0xFFCBF2F4),
        const Color(0xFFC2F1EC),
        const Color(0xFFC9F3E9),
      ],
      stops: stops,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!widget.withClouds || (widget.height != null && widget.height! < 60)) {
      return SizedBox(
        width: double.infinity,
        height: widget.height,
        child: _buildRawImage(context, isDark, widget.height),
      );
    }

    final w = MediaQuery.sizeOf(context).width;
    const footerAspect = 768.0 / 1376.0;
    final imageH = widget.height ?? (w * footerAspect);
    const skyLead = 96.0;
    final totalH = imageH + skyLead;
    final joinStop = (skyLead / totalH).clamp(0.12, 0.72);
    final deepStop = ((skyLead + imageH * 0.24) / totalH).clamp(
      joinStop + 0.08,
      0.96,
    );

    return IgnorePointer(
      child: SizedBox(
        width: double.infinity,
        height: totalH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Gradasi atmosfer langit menyatu mulus ke tepi atas ilustrasi forest
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _buildSkyGradient(
                    isDark: isDark,
                    joinStop: joinStop,
                    deepStop: deepStop,
                  ),
                ),
              ),
            ),

            // 2. Awan-awan horizon melayang lembut (lebih tenang dari Beranda agar Beranda tetap istimewa)
            if (_driftCtrl != null && _floatCtrl != null)
              AnimatedBuilder(
                animation: Listenable.merge([_driftCtrl!, _floatCtrl!]),
                builder: (context, _) {
                  final driftSlow = _driftSlow?.value ?? 0.0;
                  final driftMed = _driftMed?.value ?? 0.0;
                  final floatY = _floatY?.value ?? 0.0;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Horizon 1 — Kiri atas cakrawala
                      Positioned(
                        left: 14 + (driftSlow * 0.50),
                        top: 22 + (floatY * 0.45),
                        child: ForestCloudWidget(
                          width: 98,
                          height: 34,
                          isNight: isDark,
                          opacity: isDark ? 0.44 : 0.68,
                          flipHorizontal: false,
                          isHeader: true,
                          isHorizon: true,
                          variant: ForestCloudVariant.asymmetric,
                        ),
                      ),

                      // Horizon 2 — Kanan penyeimbang cakrawala
                      Positioned(
                        right: 16 + (-driftMed * 0.55),
                        top: 34 - (floatY * 0.38),
                        child: ForestCloudWidget(
                          width: 104,
                          height: 36,
                          isNight: isDark,
                          opacity: isDark ? 0.46 : 0.70,
                          flipHorizontal: true,
                          isHeader: true,
                          isHorizon: true,
                          variant: ForestCloudVariant.asymmetric,
                        ),
                      ),

                      // Horizon 3 — Kabut awan lembut di lembah tengah menyatu ke pucuk pohon
                      Positioned(
                        left: (w * 0.18) + (driftMed * 0.40),
                        top: skyLead - 24 + (floatY * 0.25),
                        child: ForestCloudWidget(
                          width: 112,
                          height: 33,
                          isNight: isDark,
                          opacity: isDark ? 0.36 : 0.56,
                          flipHorizontal: false,
                          isHeader: true,
                          isHorizon: true,
                          variant: ForestCloudVariant.elongated,
                        ),
                      ),
                    ],
                  );
                },
              ),

            // 3. Gambar PNG Forest dengan ShaderMask fade pada bagian atasnya
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: imageH,
              child: _buildRawImage(context, isDark, imageH),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRawImage(
    BuildContext context,
    bool isDark,
    double? targetHeight,
  ) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Color(0x33000000),
            Color(0x88000000),
            Colors.black,
          ],
          stops: [0.0, 0.05, 0.12, 0.22],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: Image.asset(
        isDark
            ? 'assets/images/beranda_landscape_footer_dark.png'
            : 'assets/images/beranda_landscape_footer_fiks.png',
        width: double.infinity,
        height: targetHeight,
        fit: widget.fit,
        alignment: Alignment.bottomCenter,
        errorBuilder: (context, error, stackTrace) => Container(
          height: targetHeight ?? 100,
          color: isDark ? const Color(0xFF1A2228) : const Color(0xFFD1FAE5),
          alignment: Alignment.center,
          child: Icon(
            Icons.park_outlined,
            size: 44,
            color: isDark ? const Color(0xFF10B981) : const Color(0xFF34D399),
          ),
        ),
      ),
    );
  }
}
