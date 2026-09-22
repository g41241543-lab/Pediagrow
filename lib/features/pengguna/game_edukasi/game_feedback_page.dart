import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/soal_model.dart';
import 'game_soal_page.dart';
import 'game_skor_akhir_page.dart';

/// Halaman Feedback Jawaban.
///
/// Muncul setelah pengguna memilih jawaban (tidak muncul jika di-skip).
/// Menampilkan:
/// - Background biru gradasi Figma yang SAMA PERSIS dengan halaman Soal
/// - Progress bar pada header persisten (posisi tetap, placeholder timer 38dp)
/// - Kartu soal (putih, read-only)
/// - Tombol Benar/Salah dengan state warna hasil
/// - Bar status "Jawaban Benar" (hijau) / "Jawaban Salah" (merah)
/// - Kartu Penjelasan (putih)
/// - Tombol "Lanjut" atau "Lihat Skor" (putih kontras di atas background biru)
///
/// [REVISI 6]: Background biru konsisten penuh sepanjang kuis.
/// [REVISI 7]: Header & progress bar dengan layout tetap dan placeholder timer.
class GameFeedbackPage extends StatelessWidget {
  final List<SoalModel> soalList;
  final int currentIndex;

  /// Pilihan pengguna: true = "Benar", false = "Salah"
  final bool pilihanPengguna;

  /// Apakah pilihan pengguna sesuai dengan jawaban_benar soal
  final bool isBenar;

  final List<HasilSoal> hasilSebelumnya;
  final VoidCallback? onLanjut;

  const GameFeedbackPage({
    super.key,
    required this.soalList,
    required this.currentIndex,
    required this.pilihanPengguna,
    required this.isBenar,
    required this.hasilSebelumnya,
    this.onLanjut,
  });

  SoalModel get _soal => soalList[currentIndex];
  int get _nomorSoal => currentIndex + 1;
  bool get _isLast => currentIndex >= soalList.length - 1;

  // ──────────────────────────────────────────────────────────────────
  // NAVIGASI
  // ──────────────────────────────────────────────────────────────────
  void _lanjut(BuildContext context) {
    if (onLanjut != null) {
      onLanjut!();
      return;
    }

    final hasilBaru = List<HasilSoal>.from(hasilSebelumnya)
      ..add(HasilSoal(soal: _soal, pilihanPengguna: pilihanPengguna));

    if (_isLast) {
      Navigator.of(context).pushReplacement(
        _FadeSlideRoute(
          builder: (_) => GameSkorAkhirPage(
            soalList: soalList,
            hasilList: hasilBaru,
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        _FadeSlideRoute(
          builder: (_) => GameSoalPage(
            soalList: soalList,
            currentIndex: currentIndex + 1,
            hasilSebelumnya: hasilBaru,
          ),
        ),
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // nonaktifkan back selama kuis
      child: Scaffold(
        body: Stack(
          children: [
            // ── Background Gradient Biru (Figma) ──────────────────
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

            // ── Dekorasi Figma (bintik & lingkaran putih) ─────────
            const Positioned.fill(
              child: IgnorePointer(child: _FeedbackBgDecoration()),
            ),

            // ── Konten Utama ──────────────────────────────────────
            SafeArea(
              top: false,
              bottom: false,
              child: Column(
                children: [
                  // ── Persistent Header & Progress Bar ─────────────
                  _buildProgressArea(),

                  // ── Konten scrollable (Kartu & Tombol) ───────────
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 20),
                      child: Column(
                        children: [
                          // Kartu soal (putih)
                          _buildKartuSoal(),

                          const SizedBox(height: 16),

                          // Tombol jawaban dengan state hasil warna
                          _buildTombolHasil(),

                          const SizedBox(height: 16),

                          // Bar status Benar / Salah
                          _buildBarStatus(),

                          const SizedBox(height: 16),

                          // Kartu penjelasan (putih)
                          _buildKartuPenjelasan(),

                          const SizedBox(height: 24),

                          // Tombol Lanjut / Lihat Skor
                          _buildTombolLanjut(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AREA PROGRESS HEADER PERSISTEN ─────────────────────────────
  // [REVISI 7]: Layout dan koordinat Y persis sama dengan GameSoalPage,
  // dengan placeholder timer setinggi 38dp sehingga bar tidak bergeser.
  Widget _buildProgressArea() {
    final double progress = _nomorSoal / soalList.length;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
      ),
      padding: const EdgeInsets.only(
          top: 56, left: 16, right: 16, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nomor Soal
          Row(
            children: [
              Text(
                'Soal $_nomorSoal / ${soalList.length}',
                style: GoogleFonts.lato(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress Bar kuning
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: progress, end: progress),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFFFD600),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // [REVISI 7]: Placeholder tak terlihat setinggi 38dp pengganti timer pill
          // Menjamin posisi progress bar di atasnya tidak bergeser sama sekali.
          const SizedBox(
            height: 38,
            child: Center(
              child: SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  // ── KARTU SOAL (read-only, kartu putih di atas background biru) ──
  Widget _buildKartuSoal() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Soal $_nomorSoal dari ${soalList.length}',
            style: GoogleFonts.lato(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7F7F7F),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _soal.pertanyaan,
            style: GoogleFonts.lato(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFECF6FF),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              _soal.kategori,
              style: GoogleFonts.lato(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3985E7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TOMBOL JAWABAN (state warna hasil) ─────────────────────────
  Widget _buildTombolHasil() {
    final Color warnaTombolBenar = _colorForTombol(pilihan: true);
    final Color warnaTombolSalah = _colorForTombol(pilihan: false);

    return Row(
      children: [
        Expanded(
          child: _TombolHasilWidget(
            label: 'Benar',
            icon: Icons.check_rounded,
            bgColor: warnaTombolBenar,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _TombolHasilWidget(
            label: 'Salah',
            icon: Icons.close_rounded,
            bgColor: warnaTombolSalah,
          ),
        ),
      ],
    );
  }

  /// Mengembalikan warna background tombol berdasarkan pilihan pengguna.
  Color _colorForTombol({required bool pilihan}) {
    if (pilihanPengguna == pilihan) {
      return isBenar
          ? const Color(0xFF10B981) // hijau → sama dengan pernyataan Jawaban Benar
          : const Color(0xFFEF4444); // merah → salah
    }
    return const Color(0xFFECF6FF); // netral terang
  }

  // ── BAR STATUS (Jawaban Benar / Jawaban Salah) ──────────────────
  Widget _buildBarStatus() {
    final Color bgColor = isBenar
        ? const Color(0xFF10B981) // hijau
        : const Color(0xFFEF4444); // merah

    final String label = isBenar ? '✓  Jawaban Benar' : '✗  Jawaban Salah';

    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.lato(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  // ── KARTU PENJELASAN (kartu putih di atas background biru) ─────
  Widget _buildKartuPenjelasan() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Color(0xFF3985E7),
              ),
              const SizedBox(width: 6),
              Text(
                'Penjelasan',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3985E7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _soal.penjelasan,
            style: GoogleFonts.lato(
              fontSize: 14,
              height: 1.6,
              color: const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  // ── TOMBOL LANJUT / LIHAT SKOR (Putih kontras) ─────────────────
  Widget _buildTombolLanjut(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () => _lanjut(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF3985E7),
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isLast ? 'Lihat Skor' : 'Lanjut',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3985E7),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              _isLast ? Icons.emoji_events_rounded : Icons.arrow_forward_rounded,
              size: 18,
              color: const Color(0xFF3985E7),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// WIDGET TOMBOL HASIL (non-interaktif, hanya tampilan state warna)
// ════════════════════════════════════════════════════════════════════
class _TombolHasilWidget extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;

  const _TombolHasilWidget({
    required this.label,
    required this.icon,
    required this.bgColor,
  });

  bool get _isHighlighted =>
      bgColor == const Color(0xFF3985E7) ||
      bgColor == const Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(17),
        boxShadow: _isHighlighted
            ? [
                BoxShadow(
                  color: bgColor.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: _isHighlighted ? Colors.white : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _isHighlighted ? Colors.white : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// DEKORASI BACKGROUND FEEDBACK (Figma - sama persis dengan Soal)
// ════════════════════════════════════════════════════════════════════
class _FeedbackBgDecoration extends StatelessWidget {
  const _FeedbackBgDecoration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _FeedbackBgPainter());
  }
}

class _FeedbackBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Lingkaran semi-transparan kanan atas
    canvas.drawCircle(
      Offset(size.width + 30, -30),
      120,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );
    // Lingkaran kiri atas
    canvas.drawCircle(
      Offset(-40, size.height * 0.15),
      90,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..style = PaintingStyle.fill,
    );
    // Bintik kecil area atas
    final rnd = Random(77);
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 30; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width,
            rnd.nextDouble() * size.height * 0.40),
        rnd.nextDouble() * 3 + 1,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ════════════════════════════════════════════════════════════════════
// CUSTOM PAGE ROUTE — Fade + Slide halus (easeInOut, 300ms)
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
