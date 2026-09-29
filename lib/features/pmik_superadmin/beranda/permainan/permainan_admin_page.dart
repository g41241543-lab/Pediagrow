import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/soal_service.dart';
import '../../../../models/soal_model.dart';
import '../../../pengguna/beranda/widgets/full_page_sky_background.dart';
import '../../../pengguna/beranda/widgets/header_sky_illustration.dart';
import 'edit_soal_permainan_page.dart';

/// Halaman Permainan untuk Superadmin — Daftar Soal.
///
/// Menampilkan seluruh bank soal dalam kartu putih yang dapat diedit.
/// Background identik dengan Beranda Superadmin:
/// - Scaffold background putih
/// - Full-page animasi awan dan burung melayang ([FullPageSkyBackground])
/// - Area biru langit seamless di bagian header ([HeaderSkyIllustration])
/// - Ilustrasi pemandangan bukit hijau di bagian footer
///
/// Navigasi:
/// - Tombol back → kembali ke halaman sebelumnya (beranda superadmin).
/// - Ikon edit pada kartu → buka [EditSoalPermainanPage].
/// - Setelah edit berhasil → kartu soal diperbarui langsung + notifikasi sukses.
class PermainanAdminPage extends StatefulWidget {
  const PermainanAdminPage({super.key});

  @override
  State<PermainanAdminPage> createState() => _PermainanAdminPageState();
}

class _PermainanAdminPageState extends State<PermainanAdminPage>
    with SingleTickerProviderStateMixin {
  // ──────────────────────────────────────────────────────────────────
  // STATE
  // ──────────────────────────────────────────────────────────────────
  List<SoalModel> _soalList = [];
  bool _isLoading = true;
  String? _errorMsg;

  // Notifikasi sukses
  bool _showSuccessBar = false;
  late AnimationController _notifController;
  late Animation<Offset> _notifSlide;

  @override
  void initState() {
    super.initState();
    _notifController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _notifSlide = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _notifController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));
    _loadSoal();
  }

  @override
  void dispose() {
    _notifController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────
  // LOAD DATA
  // ──────────────────────────────────────────────────────────────────
  Future<void> _loadSoal() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final soal = await SoalService.getAllSoal();
      if (!mounted) return;
      setState(() {
        // Revisi S-1: Tampilkan hanya 10 soal pertama (ID 1–10).
        // Soal 11–20 tetap ada di database, tidak dihapus.
        // Untuk mengaktifkan kembali, ubah batas di sini.
        _soalList = soal.take(10).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'Gagal memuat soal: $e';
        _isLoading = false;
      });
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // NAVIGASI KE EDIT SOAL
  // ──────────────────────────────────────────────────────────────────
  Future<void> _bukaEditSoal(int index) async {
    final soal = _soalList[index];
    final result = await Navigator.of(context).push<SoalModel>(
      _FadeSlideRoute(
        builder: (_) => EditSoalPermainanPage(soal: soal),
      ),
    );

    if (!mounted) return;
    if (result != null) {
      // Perbarui kartu soal langsung di list
      setState(() {
        _soalList[index] = result;
      });
      _tampilkanNotifSukses();
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // NOTIFIKASI SUKSES
  // ──────────────────────────────────────────────────────────────────
  Future<void> _tampilkanNotifSukses() async {
    setState(() => _showSuccessBar = true);
    _notifController.forward(from: 0);
    await Future.delayed(const Duration(seconds: 3));
    if (mounted && _showSuccessBar) {
      _tutupNotif();
    }
  }

  Future<void> _tutupNotif() async {
    await _notifController.reverse();
    if (mounted) setState(() => _showSuccessBar = false);
  }

  // ──────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── Konten Scrollable dengan Background Langit Beranda ─────
          SingleChildScrollView(
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

                    // 2. Konten Utama
                    if (_isLoading)
                      const SizedBox(
                        height: 350,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF3985E7),
                          ),
                        ),
                      )
                    else if (_errorMsg != null)
                      _buildError()
                    else
                      _buildContentSection(),

                    const SizedBox(height: 24),

                    // 3. Ilustrasi Landscape Footer (persis Beranda)
                    _buildFooterIllustration(),
                  ],
                ),
              ],
            ),
          ),

          // ── Notifikasi sukses (slide dari atas) ───────────────────
          if (_showSuccessBar) _buildSuccessBar(),
        ],
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
              // Header: Back Button + "Permainan" (tinggi 56dp)
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
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // 2. KONTEN UTAMA
  // ──────────────────────────────────────────────────────────────────
  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildKuisInfo(),
        const SizedBox(height: 24),
        // Garis pemisah horizontal tipis abu-abu muda (#E2E8F0)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(
            color: Color(0xFFE2E8F0),
            thickness: 1,
          ),
        ),
        const SizedBox(height: 16),
        // Bagian Label "Daftar Soal"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(
                'Daftar Soal',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_soalList.length}',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Kartu-kartu soal yang disusun secara vertikal (jarak 12dp)
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: _soalList.length,
          separatorBuilder: (_, idx) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildSoalCard(index);
          },
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // INFO KUIS (Ikon otak, judul, subjudul, chip informasi status)
  // ──────────────────────────────────────────────────────────────────
  Widget _buildKuisInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Center(
        child: Column(
          children: [
            // 1. Ikon permainan: gambar otak dalam lingkaran putih diameter 88dp
            //    dengan border biru muda, dan badge hijau bulat diameter 28dp
            //    dengan ikon checklist putih di pojok kanan bawah
            SizedBox(
              width: 88,
              height: 88,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFBFDBFE),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2B7AE8).withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.psychology_rounded,
                      size: 48,
                      color: Color(0xFF2B7AE8),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Judul "Kuis Edukasi PediaGrow" (Lato Bold 20sp, #1E293B)
            Text(
              'Kuis Edukasi PediaGrow',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
                letterSpacing: -0.2,
              ),
            ),

            const SizedBox(height: 6),

            // 3. Subjudul "Kelola pertanyaan dan kunci jawaban kuis stunting untuk edukasi pengguna" (Lato Regular 13sp, #64748B)
            Text(
              'Kelola pertanyaan dan kunci jawaban kuis stunting untuk edukasi pengguna',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: const Color(0xFF64748B),
                height: 1.45,
              ),
            ),

            const SizedBox(height: 14),

            // 4. Chip informasi status: "10 Soal Aktif" (#E0EDFD / #2B7AE8) & "Tersimpan di Database" (#DCFCE7 / #16A34A)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0EDFD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.quiz_outlined,
                        size: 14,
                        color: Color(0xFF2B7AE8),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${_soalList.length} Soal Aktif',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2B7AE8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.storage_rounded,
                        size: 14,
                        color: Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Tersimpan di Database',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // KARTU SOAL
  // Background putih (#FFFFFF), border radius 16dp, border tipis (#E2E8F0), padding 16dp
  // ──────────────────────────────────────────────────────────────────
  Widget _buildSoalCard(int index) {
    final soal = _soalList[index];
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Label "Soal N" + tombol edit (pensil #F59E0B di kotak #FEF3C7 32x32)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Soal ${index + 1}',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: const Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _bukaEditSoal(index),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Teks pertanyaan: font Lato SemiBold 14sp warna #1E293B
          Text(
            soal.pertanyaan,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
              height: 1.45,
            ),
          ),
        ],
      ),
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

  // ──────────────────────────────────────────────────────────────────
  // ERROR STATE
  // ──────────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMsg ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadSoal,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3985E7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // NOTIFIKASI SUKSES BAR
  // ──────────────────────────────────────────────────────────────────
  Widget _buildSuccessBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SlideTransition(
            position: _notifSlide,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Berhasil Memperbarui Soal',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _tutupNotif,
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// CUSTOM PAGE ROUTE — Fade + Slide halus
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
