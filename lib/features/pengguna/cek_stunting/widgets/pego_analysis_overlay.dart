import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pego_robot_widget.dart';

/// State urutan animasi micro-interaction Pego
enum PegoAnimationState {
  idle,
  whiteFadeIn,
  blackHoleAppearing,
  pegoEmergence,
  analyzing,
  pegoReturning,
  blackHoleCollapsing,
  whiteFadeOut,
  completed,
}

/// Overlay Animasi Pego & Black Hole
///
/// Menyajikan transisi sinematik:
/// 1. White fade 60% opacity masuk
/// 2. Black hole elips #484747 muncul dengan scale & opacity
/// 3. Pego keluar dari black hole dengan spring animation (~1600ms)
/// 4. Pego melambaikan tangan + dada-dada selama 1600ms (analyzing)
/// 5. Teks "Pego sedang menganalisis..." looping dots
/// 6. Pego kembali ke dalam black hole (reverse)
/// 7. Black hole mengecil dan lenyap
/// 8. White fade keluar → tampil hasil
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
  // Konstanta
  // ────────────────────────────────────────────────
  static const Color colorBlackHole = Color(0xFF484747);
  static const Color colorAnalyzingText = Color(0xFF7F7F7F);

  // White fade 60% opacity (0x99 = 153/255 ≈ 60%)
  static const Color colorWhiteFade = Color(0x99FFFFFF);

  // ────────────────────────────────────────────────
  // State & Controllers
  // ────────────────────────────────────────────────
  PegoAnimationState _currentState = PegoAnimationState.idle;
  bool _isPegoWaving = false;

  late AnimationController _fadeController;
  late AnimationController _blackHoleController;
  late AnimationController _pegoSpringController;
  late AnimationController _dotsController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _blackHoleScaleAnimation;
  late Animation<double> _blackHoleOpacityAnimation;
  late Animation<double> _pegoTranslationAnimation;
  late Animation<double> _pegoScaleAnimation;
  late Animation<double> _pegoOpacityAnimation;
  late Animation<double> _pegoWobbleAnimation;

  // Looping dots teks
  int _dotCount = 1;

  @override
  void initState() {
    super.initState();

    // 1. White Fade (300ms)
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // 2. Black Hole (400ms) — lebih kecil dari sebelumnya
    _blackHoleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _blackHoleScaleAnimation = CurvedAnimation(
      parent: _blackHoleController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );
    _blackHoleOpacityAnimation = CurvedAnimation(
      parent: _blackHoleController,
      curve: Curves.easeIn,
    );

    // 3. Pego Spring (~1600ms)
    _pegoSpringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    final springCurve = CurvedAnimation(
      parent: _pegoSpringController,
      curve: const _PegoSpringCurve(damping: 0.72, frequency: 1.15),
      reverseCurve: Curves.easeInOutCubic,
    );

    _pegoTranslationAnimation =
        Tween<double>(begin: 70.0, end: 0.0).animate(springCurve);

    _pegoScaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _pegoSpringController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _pegoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pegoSpringController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
        reverseCurve: Curves.easeOut,
      ),
    );

    _pegoWobbleAnimation = Tween<double>(begin: -0.08, end: 0.0).animate(
      CurvedAnimation(
        parent: _pegoSpringController,
        curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
      ),
    );

    // 4. Looping Dots (setiap 450ms ganti jumlah titik)
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) {
            setState(() {
              _dotCount = (_dotCount % 3) + 1;
            });
            _dotsController.forward(from: 0.0);
          }
        }
      });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _blackHoleController.dispose();
    _pegoSpringController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  /// Jalankan sekuens animasi lengkap secara presisi
  Future<void> runSequence({
    required Future<void> Function() performAnalysisTask,
  }) async {
    if (!mounted) return;

    // 1. White Fade 60% masuk
    setState(() => _currentState = PegoAnimationState.whiteFadeIn);
    await _fadeController.forward();

    // 2. Black Hole muncul
    if (!mounted) return;
    setState(() => _currentState = PegoAnimationState.blackHoleAppearing);
    await _blackHoleController.forward();

    // 3. Pego Emergence (~1600ms)
    if (!mounted) return;
    setState(() {
      _currentState = PegoAnimationState.pegoEmergence;
      _isPegoWaving = false;
    });
    _dotsController.forward();
    await _pegoSpringController.forward();

    // 4. Pego Analyzing — melambaikan tangan + dada-dada selama 1600ms
    if (!mounted) return;
    setState(() {
      _currentState = PegoAnimationState.analyzing;
      _isPegoWaving = true; // aktifkan animasi lambaian
    });

    // Minimum display 1600ms agar tangan sempat melambaikan, sembari task jalan
    final minDelay = Future.delayed(const Duration(milliseconds: 1600));
    await Future.wait([performAnalysisTask(), minDelay]);

    // 5. Pego Returning ke black hole
    if (!mounted) return;
    setState(() {
      _currentState = PegoAnimationState.pegoReturning;
      _isPegoWaving = false;
    });
    await _pegoSpringController.reverse(from: 1.0);

    // 6. Black Hole Collapsing
    if (!mounted) return;
    setState(() => _currentState = PegoAnimationState.blackHoleCollapsing);
    await _blackHoleController.reverse(from: 1.0);

    // 7. White Fade Out
    if (!mounted) return;
    setState(() => _currentState = PegoAnimationState.whiteFadeOut);
    _dotsController.stop();
    await _fadeController.reverse(from: 1.0);

    if (!mounted) return;
    setState(() => _currentState = PegoAnimationState.completed);
    widget.onAnimationFinished?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible && _currentState == PegoAnimationState.idle) {
      return const SizedBox.shrink();
    }

    final String dotString = '.' * _dotCount;

    return Stack(
      children: [
        // ── White Overlay 60% ──────────────────────────────────────────
        FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: colorWhiteFade,
          ),
        ),

        // ── Pusat Animasi Pego ─────────────────────────────────────────
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 220,
                height: 210,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // A. Black Hole Elips — lebih kecil
                    Positioned(
                      bottom: 20,
                      child: ScaleTransition(
                        scale: _blackHoleScaleAnimation,
                        child: FadeTransition(
                          opacity: _blackHoleOpacityAnimation,
                          child: Container(
                            // Ukuran dikecilkan dari 190×64 → 120×36
                            width: 120,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colorBlackHole,
                              borderRadius: const BorderRadius.all(
                                Radius.elliptical(120, 36),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.30),
                                  blurRadius: 14,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // B. Robot Pego
                    Positioned(
                      bottom: 26,
                      child: AnimatedBuilder(
                        animation: _pegoSpringController,
                        builder: (context, child) {
                          final isEmergingOrReturning =
                              _currentState == PegoAnimationState.pegoEmergence ||
                              _currentState == PegoAnimationState.pegoReturning;
                          final isAnalyzing =
                              _currentState == PegoAnimationState.analyzing;

                          final double currentOpacity = isEmergingOrReturning
                              ? _pegoOpacityAnimation.value.clamp(0.0, 1.0)
                              : (isAnalyzing ? 1.0 : 0.0);

                          return Transform.translate(
                            offset: Offset(
                              0,
                              isEmergingOrReturning
                                  ? _pegoTranslationAnimation.value
                                  : 0,
                            ),
                            child: Transform.rotate(
                              angle: isEmergingOrReturning
                                  ? _pegoWobbleAnimation.value
                                  : 0,
                              child: Transform.scale(
                                scale: isEmergingOrReturning
                                    ? _pegoScaleAnimation.value
                                    : (isAnalyzing ? 1.0 : 0.3),
                                child: Opacity(
                                  opacity: currentOpacity,
                                  child: child,
                                ),
                              ),
                            ),
                          );
                        },
                        child: PegoAnimatingWidget(
                          width: 120,
                          height: 155,
                          isWaving: _isPegoWaving,
                          showRipples: false,
                          customAssetPath: widget.customPegoAsset,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // C. Teks "Pego sedang menganalisis..." dengan looping dots
              FadeTransition(
                opacity: _blackHoleOpacityAnimation,
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
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colorAnalyzingText,
                          ),
                        ),
                        Text(
                          dotString,
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: colorAnalyzingText,
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
      ],
    );
  }
}

/// Custom Curve berdasarkan fisika pegas (spring physics)
class _PegoSpringCurve extends Curve {
  final double damping;
  final double frequency;

  const _PegoSpringCurve({this.damping = 0.75, this.frequency = 1.2});

  @override
  double transformInternal(double t) {
    final double decay = -damping * 5.0 * t;
    final double rad = frequency * math.pi * 2.0 * t;
    return 1.0 - (math.exp(decay) * math.cos(rad));
  }
}
