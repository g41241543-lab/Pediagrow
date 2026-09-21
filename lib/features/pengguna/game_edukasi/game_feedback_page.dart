import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/soal_model.dart';
import 'game_soal_page.dart';
import 'game_skor_akhir_page.dart';

/// Halaman Feedback Jawaban.
///
/// Muncul setelah pengguna memilih jawaban (tidak muncul jika di-skip).
/// Menampilkan:
/// - Progress bar sesuai posisi soal saat ini
/// - Kartu soal yang sama (read-only)
/// - Tombol Benar/Salah dengan state warna hasil
/// - Bar status "Jawaban Benar" (hijau) / "Jawaban Salah" (merah)
/// - Kartu Penjelasan
/// - Tombol "Lanjut" atau "Lihat Skor"
class GameFeedbackPage extends StatelessWidget {
  final List<SoalModel> soalList;
  final int currentIndex;

  /// Pilihan pengguna: true = "Benar", false = "Salah"
  final bool pilihanPengguna;

  /// Apakah pilihan pengguna sesuai dengan jawaban_benar soal
  final bool isBenar;

  final List<HasilSoal> hasilSebelumnya;

  const GameFeedbackPage({
    super.key,
    required this.soalList,
    required this.currentIndex,
    required this.pilihanPengguna,
    required this.isBenar,
    required this.hasilSebelumnya,
  });

  SoalModel get _soal => soalList[currentIndex];
  int get _nomorSoal => currentIndex + 1;
  bool get _isLast => currentIndex >= soalList.length - 1;

  // ──────────────────────────────────────────────────────────────────
  // NAVIGASI
  // ──────────────────────────────────────────────────────────────────
  void _lanjut(BuildContext context) {
    final hasilBaru = List<HasilSoal>.from(hasilSebelumnya)
      ..add(HasilSoal(soal: _soal, pilihanPengguna: pilihanPengguna));

    if (_isLast) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GameSkorAkhirPage(
            soalList: soalList,
            hasilList: hasilBaru,
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
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
        backgroundColor: const Color(0xFFF0F6FF),
        body: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            children: [
              // ── Progress Bar (posisi soal saat ini) ──────────────
              _buildProgressArea(),

              // ── Konten scrollable ─────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 20),
                  child: Column(
                    children: [
                      // Kartu soal (sama seperti di GameSoalPage)
                      _buildKartuSoal(),

                      const SizedBox(height: 16),

                      // Tombol jawaban dengan state hasil warna
                      _buildTombolHasil(),

                      const SizedBox(height: 16),

                      // Bar status Benar / Salah
                      _buildBarStatus(),

                      const SizedBox(height: 16),

                      // Kartu penjelasan
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
      ),
    );
  }

  // ── AREA PROGRESS ──────────────────────────────────────────────
  Widget _buildProgressArea() {
    final progress = _nomorSoal / soalList.length;
    return Container(
      color: const Color(0xFFF0F6FF),
      padding: const EdgeInsets.only(
          top: 56, left: 16, right: 16, bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          backgroundColor: const Color(0xFFE2E8F0),
          valueColor: const AlwaysStoppedAnimation<Color>(
            Color(0xFFFFD600),
          ),
        ),
      ),
    );
  }

  // ── KARTU SOAL (read-only, sama kontennya) ──────────────────────
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
    // Menentukan warna masing-masing tombol
    // Tombol "Benar": dipilih dan benar → biru; dipilih dan salah → merah
    // Tombol "Salah": dipilih dan benar → biru; dipilih dan salah → merah
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

  /// Mengembalikan warna background tombol berdasarkan apakah tombol ini
  /// dipilih pengguna dan apakah pilihannya benar.
  Color _colorForTombol({required bool pilihan}) {
    if (pilihanPengguna == pilihan) {
      // Tombol ini yang dipilih pengguna
      return isBenar
          ? const Color(0xFF3985E7) // biru → benar
          : const Color(0xFFEF4444); // merah → salah
    }
    // Tombol yang tidak dipilih → abu netral
    return const Color(0xFFE2E8F0);
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

  // ── KARTU PENJELASAN ─────────────────────────────────────────────
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

  // ── TOMBOL LANJUT / LIHAT SKOR ──────────────────────────────────
  Widget _buildTombolLanjut(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () => _lanjut(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3985E7),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: Text(
          _isLast ? 'Lihat Skor' : 'Lanjut',
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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
