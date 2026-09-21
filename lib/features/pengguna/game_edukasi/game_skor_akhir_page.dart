import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/soal_model.dart';
import '../../../shared/widgets/illustration_forest_footer.dart';
import 'game_controller.dart';
import 'game_mulai_page.dart';

/// Halaman Skor Akhir — muncul sekali setelah semua 10 soal selesai.
///
/// Menampilkan:
/// - Ikon medali/bintang di lingkaran
/// - Judul "Kuis Selesai" + ringkasan skor + poin
/// - Daftar rincian 10 soal scrollable (kartu putih)
/// - Tombol "Ulangi Kuis" (outline) dan "Selesai" (solid)
/// - Ilustrasi footer hutan
class GameSkorAkhirPage extends StatelessWidget {
  final List<SoalModel> soalList;
  final List<HasilSoal> hasilList;

  const GameSkorAkhirPage({
    super.key,
    required this.soalList,
    required this.hasilList,
  });

  int get _jumlahBenar => GameController.hitungJumlahBenar(hasilList);
  int get _totalPoin => GameController.hitungTotalPoin(hasilList);
  int get _totalSoal => soalList.length;

  // ──────────────────────────────────────────────────────────────────
  // NAVIGASI
  // ──────────────────────────────────────────────────────────────────
  void _ulangiKuis(BuildContext context) {
    // Pop semua halaman kuis, kembali ke GameMulaiPage
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const GameMulaiPage()),
      (route) => route.isFirst,
    );
  }

  void _selesai(BuildContext context) {
    // Kembali ke Beranda (pop semua)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ──────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
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

            // ── Dekorasi Figma ───────────────────────────────────
            const Positioned.fill(
              child: IgnorePointer(child: _SkorBgDecoration()),
            ),

            // ── Konten ───────────────────────────────────────────
            SafeArea(
              top: false,
              bottom: false,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // ── Header safe area top ────────────────────
                        const SizedBox(height: 56),

                        // ── Ikon Medali ────────────────────────────
                        _buildMedaliSection(),

                        const SizedBox(height: 28),

                        // ── Kartu Skor Ringkasan ────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _buildKartuSkorRingkasan(),
                        ),

                        const SizedBox(height: 24),

                        // ── Label "Rincian Soal" ───────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Rincian Soal',
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final hasil = hasilList[index];
                          return Padding(
                            padding: EdgeInsets.only(
                                bottom: index == hasilList.length - 1 ? 0 : 10),
                            child: _buildItemSoal(index + 1, hasil),
                          );
                        },
                        childCount: hasilList.length,
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 28),

                        // ── Dua Tombol Berdampingan ──────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _buildTombolBawah(context),
                        ),

                        const SizedBox(height: 20),

                        // ── Ilustrasi Footer ─────────────────────────
                        const IllustrationForestFooter(fit: BoxFit.fitWidth),
                      ],
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



  // ── MEDALI SECTION ─────────────────────────────────────────────
  Widget _buildMedaliSection() {
    final Color medaliColor = _getMedaliColor();

    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: medaliColor.withValues(alpha: 0.20),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 2.5,
            ),
          ),
          child: Icon(
            _getMedaliIcon(),
            size: 54,
            color: medaliColor,
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Kuis Selesai!',
          style: GoogleFonts.lato(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          _getPesan(),
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.85),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Color _getMedaliColor() {
    final pct = _jumlahBenar / _totalSoal;
    if (pct >= 0.8) return const Color(0xFFFFB300); // emas
    if (pct >= 0.5) return const Color(0xFF3985E7); // biru
    return const Color(0xFF94A3B8); // abu
  }

  IconData _getMedaliIcon() {
    final pct = _jumlahBenar / _totalSoal;
    if (pct >= 0.8) return Icons.emoji_events_rounded;
    if (pct >= 0.5) return Icons.star_rounded;
    return Icons.military_tech_rounded;
  }

  String _getPesan() {
    final pct = _jumlahBenar / _totalSoal;
    if (pct >= 0.8) return 'Luar biasa! Kamu sangat paham\ntentang tumbuh kembang anak! 🌟';
    if (pct >= 0.5) return 'Bagus! Terus belajar untuk menjadi\norang tua yang lebih hebat!';
    return 'Jangan menyerah! Coba lagi untuk\nmeningkatkan pemahamanmu.';
  }

  // ── KARTU SKOR RINGKASAN ────────────────────────────────────────
  Widget _buildKartuSkorRingkasan() {
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSkorItem(
            icon: Icons.check_circle_rounded,
            iconColor: const Color(0xFF10B981),
            value: '$_jumlahBenar dari $_totalSoal',
            label: 'Soal Benar',
          ),
          Container(
            height: 48,
            width: 1,
            color: const Color(0xFFE2E8F0),
          ),
          _buildSkorItem(
            icon: Icons.stars_rounded,
            iconColor: const Color(0xFFFFB300),
            value: '$_totalPoin poin',
            label: 'Total Poin',
          ),
        ],
      ),
    );
  }

  Widget _buildSkorItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 28, color: iconColor),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 12,
            color: const Color(0xFF7F7F7F),
          ),
        ),
      ],
    );
  }

  // ── ITEM SOAL DALAM DAFTAR ──────────────────────────────────────
  Widget _buildItemSoal(int nomorSoal, HasilSoal hasil) {
    final bool isSkip = hasil.diSkip;
    final bool isBenar = hasil.benar;

    Color iconColor;
    IconData iconData;
    String statusLabel;
    Color statusColor;

    if (isSkip) {
      iconColor = const Color(0xFF7F7F7F);
      iconData = Icons.remove_circle_outline_rounded;
      statusLabel = 'Tidak Dijawab';
      statusColor = const Color(0xFF7F7F7F);
    } else if (isBenar) {
      iconColor = const Color(0xFF10B981);
      iconData = Icons.check_circle_rounded;
      statusLabel = 'Benar';
      statusColor = const Color(0xFF10B981);
    } else {
      iconColor = const Color(0xFFEF4444);
      iconData = Icons.cancel_rounded;
      statusLabel = 'Salah';
      statusColor = const Color(0xFFEF4444);
    }

    final String jawabanBenarLabel =
        hasil.soal.jawabanBenar ? 'Benar' : 'Salah';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ikon status
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(iconData, size: 22, color: iconColor),
          ),

          const SizedBox(width: 12),

          // Konten
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nomor soal + label status
                Row(
                  children: [
                    Text(
                      'Soal $nomorSoal',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7F7F7F),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Pertanyaan
                Text(
                  hasil.soal.pertanyaan,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0F172A),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                // "Jawaban Benar: [nilai]"
                Text(
                  'Jawaban Benar : $jawabanBenarLabel',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3985E7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── DUA TOMBOL BAWAH ───────────────────────────────────────────
  Widget _buildTombolBawah(BuildContext context) {
    return Row(
      children: [
        // Tombol Ulangi Kuis (outline putih)
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: () => _ulangiKuis(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(
                  color: Colors.white,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: Text(
                'Ulangi Kuis',
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Tombol Selesai (solid putih)
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () => _selesai(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF3985E7),
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: Text(
                'Selesai',
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3985E7),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// DEKORASI BACKGROUND SKOR AKHIR (Figma)
// ════════════════════════════════════════════════════════════════════
class _SkorBgDecoration extends StatelessWidget {
  const _SkorBgDecoration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SkorBgPainter());
  }
}

class _SkorBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Lingkaran besar kanan atas
    canvas.drawCircle(
      Offset(size.width + 50, -50),
      150,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );
    // Lingkaran sedang kiri tengah-atas
    canvas.drawCircle(
      Offset(-60, size.height * 0.20),
      110,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.07)
        ..style = PaintingStyle.fill,
    );
    // Ring kanan bawah
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.55),
      65,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Bintik kecil area atas
    final rnd = Random(99);
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 35; i++) {
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
