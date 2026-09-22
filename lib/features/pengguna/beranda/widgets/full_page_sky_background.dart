import 'package:flutter/material.dart';

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
    // Ambil ukuran dari constraints milik parent (LayoutBuilder), bukan dari
    // MediaQuery — supaya background ini otomatis mengikuti TINGGI TOTAL
    // konten (saat dipasang di dalam Stack yang tingginya ditentukan oleh
    // Column konten di dalam SingleChildScrollView), bukan cuma setinggi
    // satu layar HP.
    return LayoutBuilder(
      builder: (context, constraints) {
        final fallback = MediaQuery.of(context).size;
        final w = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : fallback.width;
        final h = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : fallback.height;
        return _buildSky(w, h);
      },
    );
  }

  Widget _buildSky(double w, double h) {
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

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // ─────────────────────────────────────────────────────────────
              // AWAN — 10 awan tersebar merata dari header sampai mendekati
              // ilustrasi footer (persentase dihitung dari TINGGI TOTAL
              // konten yang bisa di-scroll, otomatis menyesuaikan)
              // ─────────────────────────────────────────────────────────────

              // Awan A — kiri atas (area biru header)
              _cloud(
                left: -28 + driftSlow,
                top: 38 + floatY,
                w: 96,
                h: 40,
                opacity: 0.65,
                flipX: false,
              ),

              // Awan B — kanan atas (area biru, belakang matahari)
              _cloud(
                right: -20 + (-driftSlow * 0.6),
                top: 14 + (floatY * 0.7),
                w: 110,
                h: 44,
                opacity: 0.60,
                flipX: true,
              ),

              // Awan C — kiri, area transisi biru→putih
              _cloud(
                left: -24 + (driftMed * 0.8),
                top: h * 0.20 + (floatY * 0.5),
                w: 88,
                h: 36,
                opacity: 0.42,
                flipX: false,
              ),

              // Awan D — kanan, sejajar menu card
              _cloud(
                right: -18 + (-driftMed),
                top: h * 0.29 + floatY,
                w: 100,
                h: 40,
                opacity: 0.38,
                flipX: true,
              ),

              // Awan E — kiri, sejajar card PediaGrow
              _cloud(
                left: -30 + (driftSlow * 0.5),
                top: h * 0.38 + (floatY * 0.6),
                w: 82,
                h: 34,
                opacity: 0.36,
                flipX: true,
              ),

              // Awan F — kanan, sejajar Artikel Terbaru
              _cloud(
                right: -22 + (-driftMed * 0.7),
                top: h * 0.47 + floatY,
                w: 94,
                h: 38,
                opacity: 0.34,
                flipX: false,
              ),

              // Awan G — kiri, di antara artikel & video edukasi
              _cloud(
                left: -26 + (driftMed * 0.6),
                top: h * 0.56 + (floatY * 0.5),
                w: 90,
                h: 37,
                opacity: 0.32,
                flipX: false,
              ),

              // Awan H — kanan, sejajar Video Edukasi Anak
              _cloud(
                right: -20 + (-driftSlow * 0.4),
                top: h * 0.65 + floatY,
                w: 100,
                h: 41,
                opacity: 0.30,
                flipX: true,
              ),

              // Awan I — kiri, bawah section video
              _cloud(
                left: -28 + (driftSlow * 0.5),
                top: h * 0.74 + (floatY * 0.6),
                w: 86,
                h: 35,
                opacity: 0.28,
                flipX: true,
              ),

              // Awan J — kanan, paling bawah sebelum ilustrasi footer
              _cloud(
                right: -24 + (-driftMed * 0.6),
                top: h * 0.83 + floatY,
                w: 92,
                h: 38,
                opacity: 0.26,
                flipX: false,
              ),

              // ─────────────────────────────────────────────────────────────
              // BURUNG — 7 burung siluet terbang melintasi layar dari header
              // sampai mendekati ilustrasi footer
              // ─────────────────────────────────────────────────────────────

              // Burung 1 — pemimpin formasi (kiri ke kanan, area atas biru)
              Positioned(
                left: _bird1X.value * w,
                top: h * 0.08 + _bird1Y.value,
                child: _PageBird(
                  width: 20,
                  height: 10,
                  wingState: wing,
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.52),
                ),
              ),

              // Burung 2 — ekor formasi, sedikit di belakang burung 1
              Positioned(
                left: _bird1X.value * w - 24,
                top: h * 0.06 + _bird1Y.value * 0.8,
                child: _PageBird(
                  width: 14,
                  height: 7,
                  wingState: -wing * 0.85,
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.40),
                ),
              ),

              // Burung 3 — terbang dari kanan ke kiri (area menu card)
              Positioned(
                left: _bird2X.value * w,
                top: h * 0.17 + _bird2Y.value,
                child: _PageBird(
                  width: 15,
                  height: 7.5,
                  wingState: wing * 0.9,
                  color: const Color(0xFF3B5BA0).withValues(alpha: 0.34),
                ),
              ),

              // Burung 4 — kecil di kejauhan (sejajar PediaGrow)
              Positioned(
                left: _bird2X.value * w + 32,
                top: h * 0.33 + (_bird2Y.value * 0.5),
                child: _PageBird(
                  width: 11,
                  height: 5.5,
                  wingState: -wing * 0.75,
                  color: const Color(0xFF3B5BA0).withValues(alpha: 0.26),
                ),
              ),

              // Burung 5 — terbang kiri ke kanan (sejajar Artikel Terbaru)
              Positioned(
                left: _bird1X.value * w - 40,
                top: h * 0.50 + (_bird1Y.value * 0.7),
                child: _PageBird(
                  width: 16,
                  height: 8,
                  wingState: wing * 0.8,
                  color: const Color(0xFF3B5BA0).withValues(alpha: 0.30),
                ),
              ),

              // Burung 6 — terbang kanan ke kiri (sejajar Video Edukasi Anak)
              Positioned(
                left: _bird2X.value * w - 20,
                top: h * 0.68 + (_bird2Y.value * 0.8),
                child: _PageBird(
                  width: 13,
                  height: 6.5,
                  wingState: -wing * 0.7,
                  color: const Color(0xFF3B5BA0).withValues(alpha: 0.26),
                ),
              ),

              // Burung 7 — paling bawah, sebelum ilustrasi footer
              Positioned(
                left: _bird1X.value * w + 20,
                top: h * 0.86 + (_bird1Y.value * 0.6),
                child: _PageBird(
                  width: 12,
                  height: 6,
                  wingState: wing * 0.7,
                  color: const Color(0xFF3B5BA0).withValues(alpha: 0.22),
                ),
              ),
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
  }) {
    Widget cloud = CustomPaint(
      size: Size(w, h),
      painter: _SubtleCloudPainter(opacity: opacity),
    );
    if (flipX) cloud = Transform.flip(flipX: true, child: cloud);
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: cloud,
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
    final midX = w * 0.5;
    final bodyY = h * 0.65;
    final wingArchY = (h * 0.15) - (wingState * h * 0.32);

    final path = Path()
      ..moveTo(0, h * 0.48 + (wingState * h * 0.18))
      ..quadraticBezierTo(w * 0.22, wingArchY, midX, bodyY)
      ..quadraticBezierTo(
        w * 0.78,
        wingArchY,
        w,
        h * 0.48 + (wingState * h * 0.18),
      );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PageBirdPainter old) =>
      old.wingState != wingState || old.color != color;
}

class _SubtleCloudPainter extends CustomPainter {
  final double opacity;
  const _SubtleCloudPainter({required this.opacity});

  Path _silhouette(double w, double h) {
    Path union(List<Path> parts) {
      Path r = parts.first;
      for (final p in parts.skip(1)) {
        r = Path.combine(PathOperation.union, r, p);
      }
      return r;
    }

    // Gumpalan dasar (badan awan, agak rata di bawah — seperti kumulus asli)
    return union([
      Path()..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.05, h * 0.46, w * 0.90, h * 0.42),
          Radius.circular(h * 0.21),
        ),
      ),
      Path()..addOval(Rect.fromLTWH(w * 0.00, h * 0.30, w * 0.28, h * 0.48)),
      Path()..addOval(Rect.fromLTWH(w * 0.14, h * 0.15, w * 0.30, h * 0.52)),
      Path()..addOval(Rect.fromLTWH(w * 0.28, h * 0.02, w * 0.30, h * 0.62)),
      Path()..addOval(Rect.fromLTWH(w * 0.44, h * 0.08, w * 0.26, h * 0.56)),
      Path()..addOval(Rect.fromLTWH(w * 0.58, h * 0.17, w * 0.28, h * 0.50)),
      Path()..addOval(Rect.fromLTWH(w * 0.76, h * 0.28, w * 0.22, h * 0.42)),
      // Puff kecil tambahan di atas — memberi tekstur bergerombol seperti awan asli
      Path()..addOval(Rect.fromLTWH(w * 0.10, h * 0.34, w * 0.14, h * 0.22)),
      Path()..addOval(Rect.fromLTWH(w * 0.38, h * 0.00, w * 0.16, h * 0.20)),
      Path()..addOval(Rect.fromLTWH(w * 0.66, h * 0.10, w * 0.14, h * 0.20)),
      Path()..addOval(Rect.fromLTWH(w * 0.86, h * 0.36, w * 0.10, h * 0.18)),
    ]);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sil = _silhouette(w, h);
    final a = opacity.clamp(0.0, 1.0);

    // Warna dasar awan — biru-putih lembut (bukan putih murni) supaya tetap
    // terlihat di atas background putih tanpa "nabrak"/menyatu, sekaligus
    // senada dengan tone biru header & card di beranda.
    const cloudTint = Color(
      0xFFD3E6FA,
    ); // biru-putih pastel, cukup kontras di atas putih
    final fillPaint = Paint()
      ..color = cloudTint.withValues(alpha: a)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.012);

    canvas.drawPath(sil, fillPaint);

    // Highlight tipis HANYA di bagian atas awan (efek tersinari matahari),
    // supaya tint dasar di bagian tengah/bawah tetap terasa & tidak "hilang".
    canvas.save();
    canvas.clipPath(sil);
    canvas.clipRect(Rect.fromLTWH(0, 0, w, h * 0.42));
    canvas.drawPath(
      sil,
      Paint()
        ..color = Colors.white.withValues(alpha: (a * 0.6).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.02),
    );
    canvas.restore();

    // Shading bawah awan — biru keabu-abuan lembut, senada dengan tint dasar,
    // memberi kesan volume tanpa membuat awan jadi mencolok di atas card.
    canvas.save();
    canvas.clipPath(sil);
    final sr = Rect.fromLTWH(0, h * 0.40, w, h * 0.60);
    canvas.drawRect(
      sr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF9FC0E8).withValues(alpha: 0.0),
            const Color(0xFF9FC0E8)
                .withValues(alpha: (0.30 * a + 0.10).clamp(0.0, 1.0)),
          ],
        ).createShader(sr),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SubtleCloudPainter old) =>
      old.opacity != opacity;
}
