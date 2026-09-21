import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/soal_model.dart';
import 'game_controller.dart';
import 'game_feedback_page.dart';
import 'game_mulai_page.dart';
import 'game_skor_akhir_page.dart';

/// Halaman Soal — menampilkan satu soal kuis sekaligus mengelola timer.
///
/// Parameter:
/// - [soalList]: daftar 10 soal unik putaran ini
/// - [currentIndex]: indeks soal yang sedang ditampilkan (0–9)
/// - [hasilSebelumnya]: akumulasi hasil soal-soal sebelumnya
///
/// Perilaku:
/// - Back button sistem dinonaktifkan via [PopScope].
/// - Timer hitung mundur 30 detik; jika habis → soal di-skip otomatis.
/// - Saat pengguna memilih jawaban → timer berhenti → navigasi ke Feedback.
class GameSoalPage extends StatefulWidget {
  final List<SoalModel> soalList;
  final int currentIndex;
  final List<HasilSoal> hasilSebelumnya;

  const GameSoalPage({
    super.key,
    required this.soalList,
    required this.currentIndex,
    required this.hasilSebelumnya,
  });

  @override
  State<GameSoalPage> createState() => _GameSoalPageState();
}

class _GameSoalPageState extends State<GameSoalPage> {
  late int _sisaDetik;
  Timer? _timer;
  bool _sudahJawab = false;

  SoalModel get _soalSekarang => widget.soalList[widget.currentIndex];
  int get _nomorSoal => widget.currentIndex + 1; // 1-based

  // ──────────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ──────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _sisaDetik = GameController.detikPerSoal;
    _mulaiTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────
  // TIMER
  // ──────────────────────────────────────────────────────────────────
  void _mulaiTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _sisaDetik--;
      });
      if (_sisaDetik <= 0) {
        t.cancel();
        _onTimerHabis();
      }
    });
  }

  void _onTimerHabis() {
    if (_sudahJawab) return;
    _sudahJawab = true;

    // Soal di-skip: tambahkan hasil dengan pilihanPengguna = null
    final hasilBaru = List<HasilSoal>.from(widget.hasilSebelumnya)
      ..add(HasilSoal(soal: _soalSekarang, pilihanPengguna: null));

    _navigasiBerikutnya(hasilBaru);
  }

  // ──────────────────────────────────────────────────────────────────
  // JAWAB
  // ──────────────────────────────────────────────────────────────────
  void _pilihJawaban(bool pilihanBenar) {
    if (_sudahJawab) return;
    _sudahJawab = true;
    _timer?.cancel();

    HapticFeedback.lightImpact();

    final bool isBenar = pilihanBenar == _soalSekarang.jawabanBenar;

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameFeedbackPage(
          soalList: widget.soalList,
          currentIndex: widget.currentIndex,
          pilihanPengguna: pilihanBenar,
          isBenar: isBenar,
          hasilSebelumnya: widget.hasilSebelumnya,
        ),
      ),
    );
  }

  void _navigasiBerikutnya(List<HasilSoal> hasilBaru) {
    if (!mounted) return;

    final bool isLast =
        widget.currentIndex >= widget.soalList.length - 1;

    if (isLast) {
      // Soal terakhir → Skor Akhir
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GameSkorAkhirPage(
            soalList: widget.soalList,
            hasilList: hasilBaru,
          ),
        ),
      );
    } else {
      // Soal berikutnya
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GameSoalPage(
            soalList: widget.soalList,
            currentIndex: widget.currentIndex + 1,
            hasilSebelumnya: hasilBaru,
          ),
        ),
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // HELPER: format timer
  // ──────────────────────────────────────────────────────────────────
  String get _timerLabel {
    final menit = _sisaDetik ~/ 60;
    final detik = _sisaDetik % 60;
    return '${menit.toString().padLeft(2, '0')}:${detik.toString().padLeft(2, '0')}';
  }

  double get _progressValue =>
      _nomorSoal / widget.soalList.length;

  Color get _timerColor =>
      _sisaDetik <= 10 ? const Color(0xFFEF4444) : const Color(0xFF3985E7);

  // ──────────────────────────────────────────────────────────────────
  // KONFIRMASI KELUAR: back button → kembali ke GameMulaiPage
  // ──────────────────────────────────────────────────────────────────
  void _konfirmasiKeluar(BuildContext context) {
    _timer?.cancel();
    // Langsung kembali ke GameMulaiPage tanpa dialog, hapus semua progress
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const GameMulaiPage()),
      (route) => route.isFirst,
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _konfirmasiKeluar(context);
        }
      },
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
                      Color(0xFF5BA4F5),
                      Color(0xFF4592F0),
                      Color(0xFF2872E5),
                    ],
                  ),
                ),
              ),
            ),

            // ── Dekorasi Figma ────────────────────────────────────
            const Positioned.fill(
              child: IgnorePointer(child: _SoalBgDecoration()),
            ),

            // ── Konten ────────────────────────────────────────────
            SafeArea(
              top: false,
              bottom: false,
              child: Column(
                children: [
                  // ── Progress Bar & Timer ──────────────────────
                  _buildProgressArea(),

                  // ── Kartu Soal & Tombol Jawaban ───────────────
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 20),
                      child: Column(
                        children: [
                          _buildKartuSoal(),
                          const SizedBox(height: 20),
                          _buildTombolJawaban(),
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

  // ── AREA PROGRESS & TIMER ─────────────────────────────────────────
  Widget _buildProgressArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
      ),
      padding: const EdgeInsets.only(
          top: 56, left: 16, right: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nomor soal
          Row(
            children: [
              Text(
                'Soal $_nomorSoal / ${widget.soalList.length}',
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
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progressValue,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFFD600),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Pill Timer
          Align(
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 7),
              decoration: BoxDecoration(
                color: _sisaDetik <= 10
                    ? const Color(0xFFFEF2F2)
                    : Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: _timerColor.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _timerColor.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_rounded,
                    size: 16,
                    color: _timerColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _timerLabel,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _timerColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── KARTU SOAL ─────────────────────────────────────────────────
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
          // Nomor soal kontinu
          Text(
            'Soal $_nomorSoal dari ${widget.soalList.length}',
            style: GoogleFonts.lato(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7F7F7F),
            ),
          ),

          const SizedBox(height: 14),

          // Teks pertanyaan
          Text(
            _soalSekarang.pertanyaan,
            style: GoogleFonts.lato(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
              height: 1.55,
            ),
          ),

          const SizedBox(height: 16),

          // Chip kategori kecil
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFECF6FF),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              _soalSekarang.kategori,
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

  // ── TOMBOL JAWABAN ─────────────────────────────────────────────
  Widget _buildTombolJawaban() {
    return Row(
      children: [
        // Tombol BENAR
        Expanded(
          child: _TombolJawaban(
            label: 'Benar',
            icon: Icons.check_rounded,
            onTap: () => _pilihJawaban(true),
          ),
        ),
        const SizedBox(width: 16),
        // Tombol SALAH
        Expanded(
          child: _TombolJawaban(
            label: 'Salah',
            icon: Icons.close_rounded,
            onTap: () => _pilihJawaban(false),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// WIDGET TOMBOL JAWABAN (default state: biru muda)
// ════════════════════════════════════════════════════════════════════
class _TombolJawaban extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _TombolJawaban({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_TombolJawaban> createState() => _TombolJawabanState();
}

class _TombolJawabanState extends State<_TombolJawaban> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: _pressed
                ? const Color(0xFF3985E7)
                : const Color(0xFFECF6FF),
            borderRadius: BorderRadius.circular(17),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3985E7).withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: _pressed
                    ? Colors.white
                    : const Color(0xFF3985E7),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _pressed
                      ? Colors.white
                      : const Color(0xFF3985E7),
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
// DEKORASI BACKGROUND SOAL (Figma)
// ════════════════════════════════════════════════════════════════════
class _SoalBgDecoration extends StatelessWidget {
  const _SoalBgDecoration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SoalBgPainter());
  }
}

class _SoalBgPainter extends CustomPainter {
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
