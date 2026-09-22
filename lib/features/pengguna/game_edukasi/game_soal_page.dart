import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/soal_model.dart';
import 'game_controller.dart';
import 'game_mulai_page.dart';
import 'game_skor_akhir_page.dart';

/// Halaman Soal — mengelola satu sesi kuis dari Soal 1 hingga Soal 10.
///
/// [REVISI 6]: Background biru gradasi konsisten penuh sepanjang kuis
/// (Mulai → Soal → Feedback Jawaban).
///
/// [REVISI 7]: Progress bar kuning beserta header atas dijadikan elemen PERSISTEN
/// di luar area konten yang bertransisi (Column tetap).
/// - Posisi Y progress bar terkunci dengan fixed padding dari atas layar.
/// - Timer pill hanya muncul saat Soal (hitung mundur).
/// - Saat Feedback Jawaban, timer pill digantikan placeholder tak terlihat
///   setinggi 38dp sehingga progress bar di atasnya TIDAK BERGESER sama sekali.
/// - Satu-satunya animasi pada progress bar adalah perubahan width/fill-nya
///   (TweenAnimationBuilder) ketika berpindah antar soal.
/// - Area konten (kartu soal, tombol jawaban, feedback panel) bertransisi
///   secara halus menggunakan AnimatedSwitcher tanpa me-render ulang header.
class GameSoalPage extends StatefulWidget {
  final List<SoalModel> soalList;
  final int currentIndex;
  final List<HasilSoal> hasilSebelumnya;

  const GameSoalPage({
    super.key,
    required this.soalList,
    this.currentIndex = 0,
    this.hasilSebelumnya = const [],
  });

  @override
  State<GameSoalPage> createState() => _GameSoalPageState();
}

class _GameSoalPageState extends State<GameSoalPage> {
  late int _currentIndex;
  late List<HasilSoal> _hasilList;
  late int _sisaDetik;
  Timer? _timer;

  // State tampilan kuis
  bool _isShowingFeedback = false;
  bool? _pilihanPengguna;
  bool _isBenar = false;
  late double _previousProgress;

  SoalModel get _soalSekarang => widget.soalList[_currentIndex];
  int get _nomorSoal => _currentIndex + 1; // 1-based
  bool get _isLast => _currentIndex >= widget.soalList.length - 1;

  // ──────────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ──────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _hasilList = List<HasilSoal>.from(widget.hasilSebelumnya);
    _sisaDetik = GameController.detikPerSoal;
    _previousProgress =
        _currentIndex == 0 ? 0.0 : (_currentIndex / widget.soalList.length);
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
    _timer?.cancel();
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
    if (_isShowingFeedback) return;
    _timer?.cancel();

    // Soal di-skip: tambahkan hasil dengan pilihanPengguna = null
    _hasilList.add(HasilSoal(soal: _soalSekarang, pilihanPengguna: null));

    if (_isLast) {
      _keSkorAkhir();
    } else {
      setState(() {
        _previousProgress = (_currentIndex + 1) / widget.soalList.length;
        _currentIndex++;
        _sisaDetik = GameController.detikPerSoal;
        _isShowingFeedback = false;
        _pilihanPengguna = null;
      });
      _mulaiTimer();
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // USER ACTION: PILIH JAWABAN
  // ──────────────────────────────────────────────────────────────────
  void _pilihJawaban(bool pilihanBenar) {
    if (_isShowingFeedback) return;
    _timer?.cancel();
    HapticFeedback.lightImpact();

    final bool isBenar = pilihanBenar == _soalSekarang.jawabanBenar;

    setState(() {
      _isShowingFeedback = true;
      _pilihanPengguna = pilihanBenar;
      _isBenar = isBenar;
    });
  }

  // ──────────────────────────────────────────────────────────────────
  // USER ACTION: LANJUT KE SOAL BERIKUTNYA / LIHAT SKOR
  // ──────────────────────────────────────────────────────────────────
  void _onLanjut() {
    // Catat hasil jawaban soal ini
    _hasilList.add(HasilSoal(
      soal: _soalSekarang,
      pilihanPengguna: _pilihanPengguna,
    ));

    if (_isLast) {
      _keSkorAkhir();
    } else {
      setState(() {
        _previousProgress = (_currentIndex + 1) / widget.soalList.length;
        _currentIndex++;
        _isShowingFeedback = false;
        _pilihanPengguna = null;
        _sisaDetik = GameController.detikPerSoal;
      });
      _mulaiTimer();
    }
  }

  void _keSkorAkhir() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      _FadeSlideRoute(
        builder: (_) => GameSkorAkhirPage(
          soalList: widget.soalList,
          hasilList: _hasilList,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // HELPER TIMER & PROGRESS
  // ──────────────────────────────────────────────────────────────────
  String get _timerLabel {
    final menit = _sisaDetik ~/ 60;
    final detik = _sisaDetik % 60;
    return '${menit.toString().padLeft(2, '0')}:${detik.toString().padLeft(2, '0')}';
  }

  double get _targetProgress => _nomorSoal / widget.soalList.length;

  Color get _timerColor =>
      _sisaDetik <= 10 ? const Color(0xFFEF4444) : const Color(0xFF3985E7);

  // ──────────────────────────────────────────────────────────────────
  // KONFIRMASI KELUAR
  // ──────────────────────────────────────────────────────────────────
  void _konfirmasiKeluar(BuildContext context) {
    _timer?.cancel();
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
            // ── Background Gradient Biru Figma (Konsisten Sepanjang Kuis) ──
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

            // ── Dekorasi Figma (bintik & lingkaran putih) ───────────
            const Positioned.fill(
              child: IgnorePointer(child: _SoalBgDecoration()),
            ),

            // ── Layout Struktur Utama ──────────────────────────────
            SafeArea(
              top: false,
              bottom: false,
              child: Column(
                children: [
                  // ── [REVISI 7] PERSISTENT HEADER (TIDAK IKUT TRANSIISI) ──
                  // Posisi Y tetap, progress bar kuning di luar AnimatedSwitcher
                  _buildPersistentHeader(),

                  // ── KONTEN DINAMIS BERTRANSIISI (Kartu Soal / Feedback) ──
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 0.02),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _isShowingFeedback
                          ? _buildFeedbackContent(
                              key: ValueKey('feedback_$_currentIndex'))
                          : _buildSoalContent(
                              key: ValueKey('soal_$_currentIndex')),
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

  // ── [REVISI 7] HEADER & PROGRESS BAR PERSISTEN ───────────────────────
  Widget _buildPersistentHeader() {
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

          // [REVISI 3 & REVISI 7]: Progress Bar Kuning Animasi Lebar
          // Wadah bar tidak pernah berpindah posisi, hanya nilai lebarnya yang berubah
          TweenAnimationBuilder<double>(
            key: const ValueKey('persistent_linear_progress'),
            tween: Tween<double>(
              begin: _previousProgress,
              end: _targetProgress,
            ),
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

          // [REVISI 7]: Pill Timer / Placeholder Area
          // Tinggi tetap 38dp: HANYA muncul saat Soal (hitung mundur),
          // otomatis hilang saat Feedback Jawaban (waktu berhenti).
          // Placeholder tak terlihat setinggi 38dp menjamin progress bar di atasnya
          // TIDAK BERGESER sama sekali.
          SizedBox(
            height: 38,
            child: Center(
              child: _isShowingFeedback
                  ? const SizedBox.shrink()
                  : AnimatedContainer(
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
          ),
        ],
      ),
    );
  }

  // ── KONTEN SOAL ────────────────────────────────────────────────────
  Widget _buildSoalContent({required Key key}) {
    return LayoutBuilder(
      key: key,
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    // Ruang atas lebih ramping (flex: 2) sehingga posisi kartu dan tombol
                    // terangkat sedikit (agak naik) dan terlihat pas/center di layar HP
                    const Spacer(flex: 2),
                    _buildKartuSoal(),
                    const SizedBox(height: 20),
                    _buildTombolJawaban(),
                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── KONTEN FEEDBACK ────────────────────────────────────────────────
  Widget _buildFeedbackContent({required Key key}) {
    return SingleChildScrollView(
      key: key,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
      child: Column(
        children: [
          // Kartu soal (putih, read-only)
          _buildKartuSoal(),

          const SizedBox(height: 16),

          // Tombol hasil (state warna jawaban)
          _buildTombolHasil(),

          const SizedBox(height: 16),

          // Bar status "✓ Jawaban Benar" / "✗ Jawaban Salah"
          _buildBarStatus(),

          const SizedBox(height: 16),

          // Kartu penjelasan (putih)
          _buildKartuPenjelasan(),

          const SizedBox(height: 24),

          // Tombol Lanjut / Lihat Skor (putih kontras)
          _buildTombolLanjut(),
        ],
      ),
    );
  }

  // ── KARTU SOAL (Putih) ─────────────────────────────────────────────
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
            'Soal $_nomorSoal dari ${widget.soalList.length}',
            style: GoogleFonts.lato(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7F7F7F),
            ),
          ),
          const SizedBox(height: 14),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  // ── TOMBOL JAWABAN (Mode Soal: Interaktif) ──────────────────────────
  Widget _buildTombolJawaban() {
    return Row(
      children: [
        Expanded(
          child: _TombolJawaban(
            label: 'Benar',
            icon: Icons.check_rounded,
            onTap: () => _pilihJawaban(true),
          ),
        ),
        const SizedBox(width: 16),
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

  // ── TOMBOL HASIL (Mode Feedback: State Warna) ──────────────────────
  Widget _buildTombolHasil() {
    final Color warnaBenar = _colorForTombolHasil(pilihan: true);
    final Color warnaSalah = _colorForTombolHasil(pilihan: false);

    return Row(
      children: [
        Expanded(
          child: _TombolHasilBadge(
            label: 'Benar',
            icon: Icons.check_rounded,
            bgColor: warnaBenar,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _TombolHasilBadge(
            label: 'Salah',
            icon: Icons.close_rounded,
            bgColor: warnaSalah,
          ),
        ),
      ],
    );
  }

  Color _colorForTombolHasil({required bool pilihan}) {
    if (_pilihanPengguna == pilihan) {
      return _isBenar
          ? const Color(0xFF10B981) // Hijau, sama dengan pernyataan Jawaban Benar
          : const Color(0xFFEF4444); // Merah, sama dengan pernyataan Jawaban Salah
    }
    return const Color(0xFFECF6FF); // Netral terang
  }

  // ── BAR STATUS (Mode Feedback) ─────────────────────────────────────
  Widget _buildBarStatus() {
    final Color bgColor = _isBenar
        ? const Color(0xFF10B981) // Hijau
        : const Color(0xFFEF4444); // Merah
    final String label = _isBenar ? '✓  Jawaban Benar' : '✗  Jawaban Salah';

    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.30),
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

  // ── KARTU PENJELASAN (Mode Feedback) ──────────────────────────────
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
            _soalSekarang.penjelasan,
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

  // ── TOMBOL LANJUT / LIHAT SKOR (Mode Feedback) ─────────────────────
  Widget _buildTombolLanjut() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _onLanjut,
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
// WIDGET TOMBOL JAWABAN (Interaktif dengan feedback tap)
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
                color: _pressed ? Colors.white : const Color(0xFF3985E7),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _pressed ? Colors.white : const Color(0xFF3985E7),
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
// WIDGET TOMBOL HASIL (Non-interaktif untuk Feedback)
// ════════════════════════════════════════════════════════════════════
class _TombolHasilBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;

  const _TombolHasilBadge({
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
