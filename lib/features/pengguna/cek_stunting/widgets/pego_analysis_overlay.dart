import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pego_robot_widget.dart';

/// State urutan alur animasi sinematik Pego & Lubang Abu Gelap
enum PegoAnimationState {
  idle,
  whiteFadeIn,        // 1. Overlay putih fade in
  holeExpanding,      // 2. Lubang abu gelap membesar sempurna (Pego masih di dalam lubang)
  pegoEmerging,       // 3. Setelah lubang membesar sempurna, Pego keluar dari dalam lubang
  analyzingAndWaving, // 4. Pego keluar dengan suasana riang, berdada-dada selama prediksi backend
  pegoEnteringHole,   // 5. Prediksi selesai -> Pego masuk kembali ke dalam lubang abu gelap
  holeCollapsing,     // 6. Pego sudah masuk 100% -> Lubang abu gelap menciut sampai hilang
  whiteFadeOut,       // 7. Overlay putih fade out
  completed,          // 8. Selesai -> Tampilkan hasil
}

/// Overlay Animasi Pego & Lubang Abu Gelap (Simetris, Terkonsep, Mulus)
///
/// Mengimplementasikan alur presisi dengan portal clipping 2.5D sejati:
/// 1. Maskot PEGO 3D HD sesuai referensi resmi pengguna
/// 2. Lubang abu gelap (#484747) membesar simetris hingga sempurna
/// 3. Pego benar-benar muncul naik *dari dalam* lubang (terpotong rapi di bibir lubang)
/// 4. Pego berdada-dada riang & halus selama backend memproses Random Forest
/// 5. Prediksi selesai -> Pego turun masuk kembali *ke dalam* lubang hingga tak terlihat
/// 6. Lubang abu gelap menciut simetris menjadi kecil lalu menghilang mulus
class PegoAnalysisOverlay extends StatefulWidget {
  final bool isVisible;
  final String? customPegoAsset;
  final VoidCallback? onAnimationFinished;

  const PegoAnalysisOverlay({
    super.key,
    required this.isVisible,
    this.customPegoAsset,
    this.onAnimationFinished,
  });

  @override
  State<PegoAnalysisOverlay> createState() => PegoAnalysisOverlayState();
}

class PegoAnalysisOverlayState extends State<PegoAnalysisOverlay>
    with TickerProviderStateMixin {
  // ────────────────────────────────────────────────
  // Konstanta Desain & Geometri Portal
  // ────────────────────────────────────────────────
  static const Color colorHoleDarkGrey = Color(0xFF484747);
  static const Color colorHoleDeepCenter = Color(0xFF2E2D2D);
  static const Color colorHoleRim = Color(0xFF3A3939);
  static const Color colorAnalyzingText = Color(0xFF475569);

  /// White fade 85% opacity
  static const Color colorWhiteFade = Color(0xD9FFFFFF);

  static const double _stageSize = 240.0;
  static const double _holeWidth = 158.0;
  static const double _holeHeight = 46.0;
  static const double _holeBottom = 16.0;
  static const double _holeCenterY = _stageSize - _holeBottom - (_holeHeight / 2.0); // 201.0

  static const double _pegoWidth = 132.0;
  static const double _pegoHeight = 164.0;
  static const double _pegoRestingBottom = 30.0; // Kaki berada pas di bagian dalam lubang

  /// Jarak vertikal masuk ke dalam lubang (190dp membawa ujung antena di bawah bibir lubang)
  static const double _hiddenDepthY = 190.0;

  // ────────────────────────────────────────────────
  // State & Controllers
  // ────────────────────────────────────────────────
  PegoAnimationState _currentState = PegoAnimationState.idle;
  bool _isPrecached = false;

  late AnimationController _fadeController;
  late AnimationController _holeController;
  late AnimationController _pegoMovementController;
  late AnimationController _dotsController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _holeScaleAnimation;
  late Animation<double> _holeOpacityAnimation;

  late Animation<double> _pegoEmergeYAnimation;
  late Animation<double> _pegoEnterYAnimation;
  late Animation<double> _pegoStretchYAnimation;
  late Animation<double> _pegoStretchXAnimation;

  final ValueNotifier<int> _dotCountNotifier = ValueNotifier<int>(1);

  @override
  void initState() {
    super.initState();

    // 1. Overlay Putih Fade In/Out
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 240),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // 2. Lubang Abu Gelap Membesar & Menciut Simetris (tidak pernah negatif/terbalik)
    _holeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 360),
    );
    _holeScaleAnimation = CurvedAnimation(
      parent: _holeController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    _holeOpacityAnimation = CurvedAnimation(
      parent: _holeController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      reverseCurve: const Interval(0.45, 1.0, curve: Curves.easeIn),
    );

    // 3. Gerakan Pego Keluar dari Lubang & Masuk Kembali ke Lubang
    _pegoMovementController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 580),
      reverseDuration: const Duration(milliseconds: 520),
    );

    // Kurva keluar: meluncur naik dari dalam lubang (+190) ke atas (0) dengan pantulan pegas halus
    _pegoEmergeYAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: _hiddenDepthY, end: -10.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 68,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -10.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 32,
      ),
    ]).animate(_pegoMovementController);

    // Kurva masuk: ancang-ancang ringan ke atas (-8) lalu meluncur mulus ke dalam lubang (+190)
    // Catatan: saat reverse(), controller bergerak 1.0 -> 0.0
    _pegoEnterYAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: _hiddenDepthY, end: -8.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 78,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -8.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 22,
      ),
    ]).animate(_pegoMovementController);

    // Squash & stretch organik saat meluncur keluar/masuk (tanpa mengecilkan badan jadi semut)
    _pegoStretchYAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.06, end: 1.06),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.06, end: 0.96)
            .chain(CurveTween(curve: Curves.easeOutSine)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.96, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 30,
      ),
    ]).animate(_pegoMovementController);

    _pegoStretchXAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.94, end: 0.94),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.94, end: 1.04)
            .chain(CurveTween(curve: Curves.easeOutSine)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.04, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 30,
      ),
    ]).animate(_pegoMovementController);

    // 4. Looping Dots teks (memakai ValueNotifier agar tidak rebuild seluruh overlay)
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          _dotCountNotifier.value = (_dotCountNotifier.value % 3) + 1;
          _dotsController.forward(from: 0.0);
        }
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isPrecached) {
      _isPrecached = true;
      if (widget.customPegoAsset != null && widget.customPegoAsset!.isNotEmpty) {
        precacheImage(AssetImage(widget.customPegoAsset!), context)
            .catchError((_) {});
      } else {
        for (final path in PegoRobotWidget.rigAssetPaths) {
          precacheImage(AssetImage(path), context).catchError((_) {});
        }
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _holeController.dispose();
    _pegoMovementController.dispose();
    _dotsController.dispose();
    _dotCountNotifier.dispose();
    super.dispose();
  }

  /// Jalankan urutan animasi sesuai 5 poin spesifikasi pengguna
  Future<void> runSequence({
    required Future<void> Function() performAnalysisTask,
  }) async {
    if (!mounted) return;

    // Reset state awal sebelum mulai
    _holeController.value = 0.0;
    _pegoMovementController.value = 0.0;
    _dotCountNotifier.value = 1;

    // ── TAHAP 1: Overlay Putih Masuk ─────────────────────────────────────
    setState(() => _currentState = PegoAnimationState.whiteFadeIn);
    await _fadeController.forward();

    // ── TAHAP 2: Lubang Abu Gelap Membesar Sempurna (Pego Belum Muncul) ──
    if (!mounted) return;
    setState(() => _currentState = PegoAnimationState.holeExpanding);
    _dotsController.forward(from: 0.0);
    await _holeController.forward();

    // Jeda singkat 60ms agar pengguna melihat lubang terbuka penuh sebelum Pego keluar
    await Future.delayed(const Duration(milliseconds: 60));

    // ── TAHAP 3: Pego Keluar dari Dalam Lubang Setelah Membesar Sempurna ─
    if (!mounted) return;
    setState(() => _currentState = PegoAnimationState.pegoEmerging);
    await _pegoMovementController.forward(from: 0.0);

    // ── TAHAP 4: Pego Berdada-dada Riang selama Backend Prediksi ──────────
    if (!mounted) return;
    setState(() => _currentState = PegoAnimationState.analyzingAndWaving);

    // Waktu tunggu minimal 1800ms agar animasi lambaian tangan riang dinikmati
    final minWaveDuration = Future.delayed(const Duration(milliseconds: 1800));
    await Future.wait([performAnalysisTask(), minWaveDuration]);

    // ── TAHAP 5: Prediksi Selesai -> Pego Masuk Kembali ke Lubang Abu ──────
    if (!mounted) return;
    setState(() => _currentState = PegoAnimationState.pegoEnteringHole);
    // Beri sedikit waktu (100ms) agar goyangan Pego tegak mulus sebelum meluncur masuk
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    await _pegoMovementController.reverse(from: 1.0);

    // ── TAHAP 6: Lubang Abu Gelap Menciut Menjadi Kecil Sampai Hilang ─────
    if (!mounted) return;
    setState(() => _currentState = PegoAnimationState.holeCollapsing);
    _dotsController.stop();
    await _holeController.reverse(from: 1.0);

    // ── TAHAP 7: Overlay Putih Fade Out ──────────────────────────────────
    if (!mounted) return;
    setState(() => _currentState = PegoAnimationState.whiteFadeOut);
    await _fadeController.reverse(from: 1.0);

    // ── TAHAP 8: Selesai -> Munculkan Bottom Sheet Hasil ─────────────────
    if (!mounted) return;
    setState(() => _currentState = PegoAnimationState.completed);
    widget.onAnimationFinished?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible &&
        (_currentState == PegoAnimationState.idle ||
            _currentState == PegoAnimationState.completed)) {
      return const SizedBox.shrink();
    }

    // Apakah Pego sedang aktif di dalam/di atas lubang (bukan fase sebelum lubang terbuka)
    final bool isPegoActiveStage =
        _currentState == PegoAnimationState.pegoEmerging ||
        _currentState == PegoAnimationState.analyzingAndWaving ||
        _currentState == PegoAnimationState.pegoEnteringHole;

    // Pego mulai melambaikan tangan riang begitu mencapai puncak / sedang menganalisis
    final bool isWavingActive =
        _currentState == PegoAnimationState.analyzingAndWaving;

    return Stack(
      children: [
        // ── A. White Overlay 85% ──────────────────────────────────────────
        FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: colorWhiteFade,
          ),
        ),

        // ── B. Arena Animasi Pego & Lubang Abu Gelap (Simetris & Portal 2.5D)
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: _stageSize,
                height: _stageSize,
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _holeController,
                    _pegoMovementController,
                  ]),
                  builder: (context, pegoChild) {
                    final double holeScale =
                        _holeScaleAnimation.value.clamp(0.0, 1.15);
                    final double holeOpacity =
                        _holeOpacityAnimation.value.clamp(0.0, 1.0);

                    // Hitung posisi Y Pego sesuai fase keluar atau masuk
                    double translationY = _hiddenDepthY;
                    double stretchX = 1.0;
                    double stretchY = 1.0;

                    if (isPegoActiveStage) {
                      if (_currentState == PegoAnimationState.pegoEnteringHole) {
                        translationY = _pegoEnterYAnimation.value;
                      } else {
                        translationY = _pegoEmergeYAnimation.value;
                      }
                      stretchX = _pegoStretchXAnimation.value;
                      stretchY = _pegoStretchYAnimation.value;
                    }

                    return Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // 1. Lubang Abu Gelap (Lapisan Belakang & Kedalaman Dalam)
                        Positioned(
                          bottom: _holeBottom,
                          child: Opacity(
                            opacity: holeOpacity,
                            child: Transform.scale(
                              scale: holeScale,
                              alignment: Alignment.center,
                              child: Container(
                                width: _holeWidth,
                                height: _holeHeight,
                                decoration: BoxDecoration(
                                  gradient: const RadialGradient(
                                    center: Alignment(0.0, -0.15),
                                    radius: 0.85,
                                    colors: [
                                      colorHoleDeepCenter,
                                      colorHoleDarkGrey,
                                    ],
                                    stops: [0.35, 1.0],
                                  ),
                                  borderRadius: const BorderRadius.all(
                                    Radius.elliptical(_holeWidth, _holeHeight),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.24),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 2. Pego Terpotong Rapi oleh Bibir Lubang (_PortalHoleClipper)
                        Positioned.fill(
                          child: ClipPath(
                            clipper: _PortalHoleClipper(
                              holeCenterY: _holeCenterY,
                              holeWidth: _holeWidth * holeScale,
                              holeHeight: _holeHeight * holeScale,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  bottom: _pegoRestingBottom,
                                  child: Transform.translate(
                                    offset: Offset(0, translationY),
                                    child: Transform.scale(
                                      scaleX: stretchX,
                                      scaleY: stretchY,
                                      alignment: Alignment.bottomCenter,
                                      child: pegoChild,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 3. Bibir Depan Lubang (Menegaskan efek 3D Pego di dalam lubang)
                        if (holeScale > 0.02)
                          Positioned(
                            bottom: _holeBottom,
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: holeOpacity,
                                child: Transform.scale(
                                  scale: holeScale,
                                  alignment: Alignment.center,
                                  child: CustomPaint(
                                    size: const Size(_holeWidth, _holeHeight),
                                    painter: _PortalFrontRimPainter(
                                      rimColor: colorHoleRim,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                  child: PegoAnimatingWidget(
                    width: _pegoWidth,
                    height: _pegoHeight,
                    isWaving: isWavingActive,
                    pose: PegoPose.waving,
                    isAnalyzing: _currentState ==
                        PegoAnimationState.analyzingAndWaving,
                    showRipples: false,
                    customAssetPath: widget.customPegoAsset,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── C. Teks "Pego sedang menganalisis..." dengan Looping Dots ──
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Pego sedang menganalisis',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorAnalyzingText,
                            letterSpacing: 0.2,
                          ),
                        ),
                        ValueListenableBuilder<int>(
                          valueListenable: _dotCountNotifier,
                          builder: (context, count, _) {
                            return SizedBox(
                              width: 24,
                              child: Text(
                                '.' * count,
                                style: GoogleFonts.lato(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorHoleDarkGrey,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Clipper portal 2.5D:
/// Mengizinkan area penuh di atas garis tengah lubang + bagian dalam lengkungan
/// bawah elips lubang, dan memotong 100% area di luar/bawah bibir lubang sehingga
/// Pego terlihat benar-benar masuk dan keluar dari dalam lubang.
class _PortalHoleClipper extends CustomClipper<Path> {
  final double holeCenterY;
  final double holeWidth;
  final double holeHeight;

  _PortalHoleClipper({
    required this.holeCenterY,
    required this.holeWidth,
    required this.holeHeight,
  });

  @override
  Path getClip(Size size) {
    if (holeWidth <= 1.0 || holeHeight <= 1.0) {
      return Path();
    }

    final double cx = size.width / 2.0;
    final double left = cx - (holeWidth / 2.0);
    final double right = cx + (holeWidth / 2.0);
    final double top = holeCenterY - (holeHeight / 2.0);

    final Path path = Path()
      ..moveTo(-40.0, -80.0)
      ..lineTo(size.width + 40.0, -80.0)
      ..lineTo(size.width + 40.0, holeCenterY)
      ..lineTo(right, holeCenterY)
      ..arcTo(
        Rect.fromLTWH(left, top, holeWidth, holeHeight),
        0.0,
        math.pi,
        false,
      )
      ..lineTo(-40.0, holeCenterY)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant _PortalHoleClipper oldClipper) {
    return oldClipper.holeCenterY != holeCenterY ||
        oldClipper.holeWidth != holeWidth ||
        oldClipper.holeHeight != holeHeight;
  }
}

/// Menggambar bibir depan tipis di lengkungan bawah elips lubang agar batas keluar-masuk
/// Pego tampak rapi, simetris, dan berdimensi 3D.
class _PortalFrontRimPainter extends CustomPainter {
  final Color rimColor;

  _PortalFrontRimPainter({required this.rimColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint rimPaint = Paint()
      ..color = rimColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0.06, math.pi - 0.12, false, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _PortalFrontRimPainter oldDelegate) =>
      oldDelegate.rimColor != rimColor;
}
