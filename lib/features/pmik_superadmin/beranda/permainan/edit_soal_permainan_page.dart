import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/soal_service.dart';
import '../../../../models/soal_model.dart';
import '../../../pengguna/beranda/widgets/full_page_sky_background.dart';
import '../../../pengguna/beranda/widgets/header_sky_illustration.dart';

/// Halaman Edit Soal untuk Superadmin.
///
/// Dibuka dari ikon edit pada [PermainanAdminPage].
/// Background identik dengan Beranda Superadmin:
/// - Scaffold background putih
/// - Full-page animasi awan dan burung melayang ([FullPageSkyBackground])
/// - Area biru langit seamless di bagian header ([HeaderSkyIllustration])
/// - Ilustrasi pemandangan bukit hijau di bagian footer
///
/// Mengembalikan [SoalModel] yang sudah diperbarui via [Navigator.pop]
/// jika simpan berhasil, atau `null` jika dibatalkan.
class EditSoalPermainanPage extends StatefulWidget {
  /// Data soal yang akan diedit (sudah terisi dari database).
  final SoalModel soal;

  const EditSoalPermainanPage({super.key, required this.soal});

  @override
  State<EditSoalPermainanPage> createState() => _EditSoalPermainanPageState();
}

class _EditSoalPermainanPageState extends State<EditSoalPermainanPage> {
  // ──────────────────────────────────────────────────────────────────
  // CONTROLLERS & FOCUS NODES
  // ──────────────────────────────────────────────────────────────────
  late final TextEditingController _pertanyaanCtrl;
  late final TextEditingController _penjelasanCtrl;
  final FocusNode _pertanyaanFocus = FocusNode();
  final FocusNode _penjelasanFocus = FocusNode();

  // ScrollController agar bisa scroll ke error/kolom aktif
  final ScrollController _scrollCtrl = ScrollController();

  // Keys untuk scroll ke field error
  final GlobalKey _pertanyaanKey = GlobalKey();
  final GlobalKey _penjelasanKey = GlobalKey();

  // ──────────────────────────────────────────────────────────────────
  // STATE
  // ──────────────────────────────────────────────────────────────────
  late bool _jawabanBenar;
  bool _isSaving = false;
  String? _errorPertanyaan;
  String? _errorPenjelasan;

  @override
  void initState() {
    super.initState();
    _pertanyaanCtrl = TextEditingController(text: widget.soal.pertanyaan);
    _penjelasanCtrl = TextEditingController(text: widget.soal.penjelasan);
    _jawabanBenar = widget.soal.jawabanBenar;
  }

  @override
  void dispose() {
    _pertanyaanCtrl.dispose();
    _penjelasanCtrl.dispose();
    _pertanyaanFocus.dispose();
    _penjelasanFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────
  // SIMPAN PERUBAHAN
  // ──────────────────────────────────────────────────────────────────
  Future<void> _simpanPerubahan() async {
    // Tutup keyboard
    FocusScope.of(context).unfocus();

    // Validasi
    final pertanyaan = _pertanyaanCtrl.text.trim();
    final penjelasan = _penjelasanCtrl.text.trim();

    setState(() {
      _errorPertanyaan = pertanyaan.isEmpty ? 'Soal wajib diisi' : null;
      _errorPenjelasan = penjelasan.isEmpty ? 'Penjelasan wajib diisi' : null;
    });

    // Scroll ke error pertama jika ada
    if (_errorPertanyaan != null) {
      _scrollToKey(_pertanyaanKey);
      return;
    }
    if (_errorPenjelasan != null) {
      _scrollToKey(_penjelasanKey);
      return;
    }

    // Loading state
    setState(() => _isSaving = true);

    final berhasil = await SoalService.updateSoal(
      id: widget.soal.id,
      pertanyaan: pertanyaan,
      jawabanBenar: _jawabanBenar,
      penjelasan: penjelasan,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (berhasil) {
      // Kembalikan soal yang sudah diperbarui ke halaman sebelumnya
      final soalBaru = SoalModel(
        id: widget.soal.id,
        kategori: widget.soal.kategori,
        pertanyaan: pertanyaan,
        jawabanBenar: _jawabanBenar,
        penjelasan: penjelasan,
      );
      Navigator.of(context).pop(soalBaru);
    } else {
      // Tampilkan snackbar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyimpan soal, coba lagi',
            style: GoogleFonts.lato(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _scrollToKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      alignment: 0.1,
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          controller: _scrollCtrl,
          physics: const ClampingScrollPhysics(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // LAYER 0 — Background animasi awan & burung (full-page)
              const Positioned.fill(child: FullPageSkyBackground()),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Area Biru Seamless (Header + Ilustrasi Langit)
                  _buildSeamlessBlueArea(context),

                  // 2. Konten Form
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Kartu 1: Soal + Kunci Jawaban
                        _buildKartuSoal(),

                        const SizedBox(height: 16),

                        // Pill Label "Deskripsi Jawaban"
                        _buildPillLabel(),

                        const SizedBox(height: 16),

                        // Kartu 2: Penjelasan
                        _buildKartuPenjelasan(),

                        const SizedBox(height: 28),

                        // Dua tombol: Batal & Simpan
                        _buildTombolRow(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 3. Ilustrasi Footer (persis Beranda)
                  _buildFooterIllustration(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // 1. AREA BIRU SEAMLESS (Header + HeaderSkyIllustration)
  // ──────────────────────────────────────────────────────────────────
  Widget _buildSeamlessBlueArea(BuildContext context) {
    final isNight = HeaderSkyIllustration.checkIsNight(SkyTimeMode.auto);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isNight
              ? HeaderSkyIllustration.nightGradientColors
              : HeaderSkyIllustration.dayGradientColors,
          stops: isNight
              ? HeaderSkyIllustration.nightGradientStops
              : HeaderSkyIllustration.dayGradientStops,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Ilustrasi Langit (matahari/bulan, awan cumulus, burung)
          const Positioned.fill(
            child: HeaderSkyIllustration(
              mode: SkyTimeMode.auto,
              renderBackgroundGradient: false,
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Back Button + "Edit Soal" (tinggi 56dp)
              SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 56,
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Edit Soal',
                              style: GoogleFonts.lato(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                            Text(
                              'Soal #${widget.soal.id} • ${widget.soal.kategori}',
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // KARTU 1 — SOAL + JAWABAN BENAR
  // ──────────────────────────────────────────────────────────────────
  Widget _buildKartuSoal() {
    return Container(
      key: _pertanyaanKey,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label field
            Text(
              'Tuliskan Soal',
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),

            const SizedBox(height: 10),

            // Text field multi-baris
            _buildDashedTextField(
              controller: _pertanyaanCtrl,
              focusNode: _pertanyaanFocus,
              hintText: 'Masukkan teks soal...',
              textInputAction: TextInputAction.next,
              onEditingComplete: () {
                _pertanyaanFocus.unfocus();
                FocusScope.of(context).requestFocus(_penjelasanFocus);
              },
              onChanged: (_) {
                if (_errorPertanyaan != null) {
                  setState(() => _errorPertanyaan = null);
                }
              },
            ),

            // Pesan error
            if (_errorPertanyaan != null) ...[
              const SizedBox(height: 6),
              Text(
                _errorPertanyaan!,
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Label kunci jawaban
            Text(
              'Tentukan Kunci Jawaban',
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),

            const SizedBox(height: 12),

            // Radio pills Benar / Salah
            Row(
              children: [
                Expanded(child: _buildRadioPill(true, 'Benar')),
                const SizedBox(width: 12),
                Expanded(child: _buildRadioPill(false, 'Salah')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioPill(bool value, String label) {
    final bool isSelected = _jawabanBenar == value;
    return GestureDetector(
      onTap: () => setState(() => _jawabanBenar = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEFF6FF)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2B7AE8)
                : const Color(0xFFCBD5E1),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Radio circle
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2B7AE8)
                      : const Color(0xFF94A3B8),
                  width: 1.5,
                ),
                color: Colors.white,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF2B7AE8),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF2B7AE8)
                    : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // PILL LABEL DESKRIPSI
  // ──────────────────────────────────────────────────────────────────
  Widget _buildPillLabel() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          'Deskripsi Jawaban Benar / Salah',
          style: GoogleFonts.lato(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // KARTU 2 — PENJELASAN
  // ──────────────────────────────────────────────────────────────────
  Widget _buildKartuPenjelasan() {
    return Container(
      key: _penjelasanKey,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Penjelasan Edukasi',
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),

            const SizedBox(height: 10),

            _buildDashedTextField(
              controller: _penjelasanCtrl,
              focusNode: _penjelasanFocus,
              hintText: 'Masukkan penjelasan jawaban...',
              textInputAction: TextInputAction.done,
              onEditingComplete: () {
                _penjelasanFocus.unfocus();
              },
              onChanged: (_) {
                if (_errorPenjelasan != null) {
                  setState(() => _errorPenjelasan = null);
                }
              },
            ),

            if (_errorPenjelasan != null) ...[
              const SizedBox(height: 6),
              Text(
                _errorPenjelasan!,
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],

            const SizedBox(height: 8),

            Text(
              'Penjelasan ini akan ditampilkan kepada pengguna setelah menjawab soal',
              style: GoogleFonts.lato(
                fontSize: 11,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // TEXT FIELD PUTUS-PUTUS
  // ──────────────────────────────────────────────────────────────────
  Widget _buildDashedTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required TextInputAction textInputAction,
    required VoidCallback onEditingComplete,
    required ValueChanged<String> onChanged,
  }) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          minLines: 3,
          maxLines: null,
          textInputAction: textInputAction,
          onEditingComplete: onEditingComplete,
          onChanged: onChanged,
          style: GoogleFonts.lato(
            fontSize: 14,
            color: const Color(0xFF1E293B),
            height: 1.5,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.lato(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          keyboardType: TextInputType.multiline,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // TOMBOL ROW (Batal & Simpan Perubahan)
  // ──────────────────────────────────────────────────────────────────
  Widget _buildTombolRow() {
    return Row(
      children: [
        // Batal
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF475569),
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Batal',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Simpan Perubahan
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _simpanPerubahan,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B7AE8),
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    const Color(0xFF2B7AE8).withValues(alpha: 0.6),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Simpan Perubahan',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // 3. ILUSTRASI FOOTER (Sama persis dengan Beranda Superadmin)
  // ──────────────────────────────────────────────────────────────────
  Widget _buildFooterIllustration() {
    return SizedBox(
      width: double.infinity,
      child: Image.asset(
        'assets/images/beranda_landscape_footer_fiks.png',
        width: double.infinity,
        fit: BoxFit.fitWidth,
        alignment: Alignment.bottomCenter,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 100,
          color: const Color(0xFFD1FAE5),
          alignment: Alignment.center,
          child: const Icon(
            Icons.park_outlined,
            size: 44,
            color: Color(0xFF34D399),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// PAINTER: border putus-putus untuk text field
// ════════════════════════════════════════════════════════════════════
class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    const strokeWidth = 1.2;
    const radius = 8.0;

    final paint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final start = distance;
        final end = (distance + dashWidth).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(start, end), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
