import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/soal_model.dart';
import 'widgets/game_forest_silhouette_footer.dart';
import 'game_controller.dart';
import 'game_soal_page.dart';

/// Halaman Start Kuis — titik masuk fitur Permainan.
///
/// Menampilkan info kuis (10 soal, 30 detik/soal, 250 poin maks),
/// dan tombol "Mulai Kuis" yang men-generate 10 soal unik secara acak.
/// Background: gradient biru dengan elemen dekoratif sesuai desain Figma.
///
/// Semua elemen (ikon, badge, judul, deskripsi, statistik) ditampilkan
/// LANGSUNG di atas background biru — tanpa card/container putih pembungkus.
/// Ilustrasi siluet hutan dipasang fixed di bagian bawah layar (tidak scroll).
class GameMulaiPage extends StatefulWidget {
  const GameMulaiPage({super.key});

  @override
  State<GameMulaiPage> createState() => _GameMulaiPageState();
}

class _GameMulaiPageState extends State<GameMulaiPage> {
  bool _isLoading = false;

  // ──────────────────────────────────────────────────────────────────
  // ACTION: Mulai Kuis
  // ──────────────────────────────────────────────────────────────────
  Future<void> _mulaiKuis() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final List<SoalModel> soalList =
          await GameController.generatePutaranBaru();

      if (!mounted) return;
      Navigator.of(context).push(
        _FadeSlideRoute(
          builder: (_) => GameSoalPage(
            soalList: soalList,
            currentIndex: 0,
            hasilSebelumnya: const [],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat soal: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background Gradient Biru (Figma) ──────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF5B9BF5),
                    Color(0xFF6FA8E8),
                  ],
                ),
              ),
            ),
          ),

          // ── Dekorasi Figma: lingkaran & bintik ────────────────────
          const Positioned.fill(
            child: IgnorePointer(child: _FigmaDecoration()),
          ),

          // ── Ilustrasi siluet hutan: FIXED di bagian bawah ─────────
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: GameForestSilhouetteFooter(height: 160),
            ),
          ),

          // ── Konten utama (scrollable, tidak mempengaruhi ilustrasi)
          SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      // Padding bottom agar konten tidak tertutup ilustrasi
                      padding: const EdgeInsets.only(bottom: 180),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          _buildKuisInfoDirect(),
                          const SizedBox(height: 36),
                          _buildMulaiButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // HEADER
  // ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 56.0, bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.only(left: 12.0, right: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Permainan',
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // INFO KUIS — LANGSUNG DI ATAS BACKGROUND BIRU (tanpa card putih)
  // ──────────────────────────────────────────────────────────────────
  Widget _buildKuisInfoDirect() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // ── Ikon Otak dalam Lingkaran ─────────────────────────────
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.40),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.psychology_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 18),

          // ── Pill Kategori ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.40),
                width: 1,
              ),
            ),
            child: Text(
              'Kuis Parenting',
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Judul Kuis ────────────────────────────────────────────
          Text(
            'Tumbuh Kembang Anak',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 10),

          // ── Deskripsi ─────────────────────────────────────────────
          Text(
            '10 soal benar salah seputar tumbuh kembang\nsi kecil. Yuk uji seberapa paham kamu!',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 14,
              height: 1.6,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),

          const SizedBox(height: 28),

          // ── Divider tipis semi-transparan ─────────────────────────
          Divider(
            color: Colors.white.withValues(alpha: 0.25),
            thickness: 1,
          ),

          const SizedBox(height: 22),

          // ── 3 Statistik Berdampingan ──────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('10', 'Soal'),
              _buildVerticalDivider(),
              _buildStatItem('30 detik', 'Per soal'),
              _buildVerticalDivider(),
              _buildStatItem('250 poin', 'Maksimal'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.70),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 36,
      width: 1,
      color: Colors.white.withValues(alpha: 0.25),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // TOMBOL MULAI KUIS
  // ──────────────────────────────────────────────────────────────────
  Widget _buildMulaiButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _mulaiKuis,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF3985E7),
            disabledBackgroundColor: Colors.white.withValues(alpha: 0.6),
            elevation: 6,
            shadowColor: Colors.black.withValues(alpha: 0.25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF3985E7),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      size: 22,
                      color: Color(0xFF3985E7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Mulai Kuis',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3985E7),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// DEKORASI FIGMA: Lingkaran semi-transparan & bintik kecil
// ════════════════════════════════════════════════════════════════════
class _FigmaDecoration extends StatelessWidget {
  const _FigmaDecoration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FigmaDecorationPainter(),
    );
  }
}

class _FigmaDecorationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // ── Lingkaran besar kanan atas ─────────────────────────────────
    final paintCircle1 = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width + 40, -40), 140, paintCircle1);

    // ── Lingkaran sedang kiri atas ─────────────────────────────────
    final paintCircle2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(-50, size.height * 0.18), 100, paintCircle2);

    // ── Lingkaran kecil kanan tengah ───────────────────────────────
    final paintCircle3 = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(size.width * 0.88, size.height * 0.45), 60, paintCircle3);

    // ── Ring (outline) kiri bawah ──────────────────────────────────
    final paintRing = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.65), 55, paintRing);

    // ── Bintik-bintik kecil di area atas ──────────────────────────
    final paintDot = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;
    final rnd = Random(42);
    for (int i = 0; i < 45; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height * 0.55;
      final r = rnd.nextDouble() * 3.5 + 1.5;
      canvas.drawCircle(Offset(x, y), r, paintDot);
    }

    // ── Garis lengkung dekoratif ───────────────────────────────────
    final paintArc = Paint()
      ..color = Colors.white.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path1 = Path()
      ..moveTo(0, size.height * 0.38)
      ..quadraticBezierTo(
          size.width * 0.5, size.height * 0.28, size.width, size.height * 0.40);
    canvas.drawPath(path1, paintArc);

    final path2 = Path()
      ..moveTo(0, size.height * 0.30)
      ..quadraticBezierTo(
          size.width * 0.5, size.height * 0.20, size.width, size.height * 0.32);
    canvas.drawPath(path2, paintArc);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ════════════════════════════════════════════════════════════════════
// CUSTOM PAGE ROUTE — Fade + Slide halus (shared dengan game_soal_page)
// ════════════════════════════════════════════════════════════════════
class _FadeSlideRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;

  _FadeSlideRoute({required this.builder})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}
