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

  const IllustrationForestFooter({
    super.key,
    this.height,
    this.fit = BoxFit.fitWidth,
    this.withClouds = true,
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
      duration: const Duration(seconds: 32),
    );

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );

    final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (!isTest) {
      _driftCtrl?.repeat(reverse: true);
      _floatCtrl?.repeat(reverse: true);
    }

    _driftSlow = Tween<double>(begin: -14.0, end: 14.0).animate(
      CurvedAnimation(parent: _driftCtrl!, curve: Curves.easeInOutSine),
    );
    _driftMed = Tween<double>(begin: 12.0, end: -12.0).animate(
      CurvedAnimation(parent: _driftCtrl!, curve: Curves.easeInOutSine),
    );
    _floatY = Tween<double>(begin: -3.5, end: 3.5).animate(
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
    const skyLead = 64.0;
    final totalH = imageH + skyLead;

    return IgnorePointer(
      child: SizedBox(
        width: double.infinity,
        height: totalH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Gradasi atmosfer langit menyatu ke pucuk pohon
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? const [
                            Color(0x000B1014),
                            Color(0xD0091221),
                            Color(0xFF06122B),
                            Color(0xFF04112C),
                            Color(0xFF051636),
                            Color(0xFF05193A),
                          ]
                        : const [
                            Color(0x00FFFFFF),
                            Color(0xC8F2FBFE),
                            Color(0xFFDCF6FA),
                            Color(0xFFCBF2F4),
                            Color(0xFFC2F1EC),
                            Color(0xFFC9F3E9),
                          ],
                    stops: const [
                      0.0,
                      0.22,
                      0.45,
                      0.62,
                      0.82,
                      1.0,
                    ],
                  ),
                ),
              ),
            ),

            // 2. Awan-awan horizon melayang
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
                        left: 12 + (driftSlow * 0.55),
                        top: 8 + (floatY * 0.50),
                        child: ForestCloudWidget(
                          width: 96,
                          height: 33,
                          isNight: isDark,
                          opacity: isDark ? 0.42 : 0.58,
                          flipHorizontal: false,
                          isHeader: true,
                          variant: ForestCloudVariant.asymmetric,
                        ),
                      ),

                      // Horizon 2 — Kanan penyeimbang cakrawala
                      Positioned(
                        right: 14 + (-driftMed * 0.60),
                        top: 18 - (floatY * 0.40),
                        child: ForestCloudWidget(
                          width: 104,
                          height: 35,
                          isNight: isDark,
                          opacity: isDark ? 0.44 : 0.60,
                          flipHorizontal: true,
                          isHeader: true,
                          variant: ForestCloudVariant.asymmetric,
                        ),
                      ),

                      // Horizon 3 — Awan lembah tengah menyatu ke pucuk pohon
                      Positioned(
                        left: (w * 0.20) + (driftMed * 0.45),
                        top: skyLead - 18 + (floatY * 0.30),
                        child: ForestCloudWidget(
                          width: 116,
                          height: 33,
                          isNight: isDark,
                          opacity: isDark ? 0.34 : 0.48,
                          flipHorizontal: false,
                          isHeader: true,
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
