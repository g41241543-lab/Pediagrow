import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/soal_service.dart';
import '../../../../core/services/staff_auth_service.dart';
import '../../../../models/soal_model.dart';
import '../../../../models/staff_account_model.dart';
import '../../../../shared/widgets/pedia_bottom_nav_bar.dart';
import '../../../pengguna/beranda/widgets/full_page_sky_background.dart';
import '../../../pengguna/beranda/widgets/header_sky_illustration.dart';
import '../../../pmik_admin/beranda/beranda_pmik_page.dart';
import '../beranda_superadmin_page.dart';
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
    with TickerProviderStateMixin {
  // ── THEME GETTERS (DARK MODE SUPPORT) ──────────────────────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _scaffoldBg => _isDark ? const Color(0xFF0B1014) : Colors.white;
  Color get _cardBg => _isDark ? const Color(0xFF1A2228) : Colors.white;
  Color get _borderColor => _isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF);
  Color get _textBlack => _isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014);
  Color get _textGrey => _isDark ? const Color(0xFF8696A0) : const Color(0xFF667781);

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

  // Shimmer pulse animation untuk skeleton loading frame pertama
  late AnimationController _skeletonController;
  late Animation<double> _skeletonOpacity;

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

    _skeletonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _skeletonOpacity = Tween<double>(begin: 0.45, end: 0.90).animate(
      CurvedAnimation(parent: _skeletonController, curve: Curves.easeInOut),
    );

    // Stale-While-Revalidate:
    // Cek cache memory terlebih dahulu. Jika sudah ada, render 0 ms!
    final cached = SoalService.cachedSoal;
    if (cached != null && cached.isNotEmpty) {
      _soalList = cached.take(10).toList();
      _isLoading = false;
      _syncInBackground();
    } else {
      _loadSoalFast();
    }
  }

  @override
  void dispose() {
    _notifController.dispose();
    _skeletonController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────
  // LOAD DATA CEPAT (STALE-WHILE-REVALIDATE)
  // ──────────────────────────────────────────────────────────────────

  /// Memuat data instan dari cache / asset lokal (< 25 ms)
  /// lalu menjalankan sinkronisasi latar belakang tanpa memblokir UI.
  Future<void> _loadSoalFast() async {
    setState(() {
      _isLoading = _soalList.isEmpty;
      _errorMsg = null;
    });

    try {
      // 1. Ambil data awal secepat kilat (0 - 25 ms)
      final initial = await SoalService.loadInitialSoal();
      if (!mounted) return;

      if (initial.isNotEmpty) {
        setState(() {
          _soalList = initial.take(10).toList();
          _isLoading = false;
        });
      }

      // 2. Sinkronisasi data server secara halus di latar belakang
      await _syncInBackground();
    } catch (e) {
      if (!mounted) return;
      if (_soalList.isEmpty) {
        setState(() {
          _errorMsg = 'Gagal memuat soal: ';
          _isLoading = false;
        });
      }
    }
  }

  /// Sinkronisasi dengan database di latar belakang
  Future<void> _syncInBackground() async {
    try {
      final updated = await SoalService.syncInBackground();
      if (!mounted || updated == null || updated.isEmpty) return;

      final top10 = updated.take(10).toList();
      if (!_isListEqual(_soalList, top10)) {
        setState(() {
          _soalList = top10;
          _isLoading = false;
        });
      }
    } catch (_) {}
  }

  bool _isListEqual(List<SoalModel> a, List<SoalModel> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].pertanyaan != b[i].pertanyaan ||
          a[i].jawabanBenar != b[i].jawabanBenar ||
          a[i].penjelasan != b[i].penjelasan) {
        return false;
      }
    }
    return true;
  }

  /// Fungsi refresh manual untuk tombol "Coba Lagi"
  Future<void> _loadSoal() async {
    await _loadSoalFast();
  }
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
      // Perbarui kartu soal langsung di list & cache
      SoalService.updateCache(result);
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

  void _navigateBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      final staff = StaffAuthService().currentStaff;
      if (staff?.role == StaffRole.admin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BerandaPmikPage()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BerandaSuperadminPage()),
        );
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _navigateBack();
      },
      child: Scaffold(
        backgroundColor: _scaffoldBg,
        resizeToAvoidBottomInset: false,
        bottomNavigationBar: const PediaBottomNavBar(selectedIndex: -1),
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
                      _buildSkeletonLoading()
                    else if (_errorMsg != null && _soalList.isEmpty)
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
                          onTap: _navigateBack,
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
  // SKELETON LOADING (LANGSUNG TAMPIL DI FRAME PERTAMA TANPA SCREEN KOSONG)
  // ──────────────────────────────────────────────────────────────────
  Widget _buildSkeletonLoading() {
    return AnimatedBuilder(
      animation: _skeletonOpacity,
      builder: (context, child) {
        return Opacity(
          opacity: _skeletonOpacity.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Header Skeleton: Avatar Otak
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFBFDBFE),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.psychology_rounded,
                        size: 48,
                        color: Color(0xFF93C5FD),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Bar Judul
                    Container(
                      width: 220,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Bar Subjudul
                    Container(
                      width: 280,
                      height: 13,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 200,
                      height: 13,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Chip Skeleton
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 110,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0EDFD),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 150,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(
                  color: Color(0xFFE9EDEF),
                  thickness: 1,
                ),
              ),
              const SizedBox(height: 16),
              // Label "Daftar Soal" skeleton
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  width: 120,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 3 Kartu Soal Skeleton
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: List.generate(3, (index) => _buildSkeletonCard()),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9EDEF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0EDFD),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 180,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 90,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              Container(
                width: 70,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  // ──────────────────────────────────────────────────────────────────
  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildKuisInfo(),
        const SizedBox(height: 24),
        // Garis pemisah horizontal tipis abu-abu muda (#E2E8F0)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(
            color: _borderColor,
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
                  color: _textBlack,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _isDark
                      ? const Color(0xFF2C363D)
                      : const Color(0xFFE9EDEF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_soalList.length}',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _isDark
                        ? const Color(0xFFE9EDEF)
                        : const Color(0xFF667781),
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
                      color: _cardBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isDark
                            ? const Color(0xFF2C363D)
                            : const Color(0xFFBFDBFE),
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
                        border: Border.all(color: _cardBg, width: 2),
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
                color: _textBlack,
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
                color: _textGrey,
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
                    color: _isDark
                        ? const Color(0xFF1E3A5F)
                        : const Color(0xFFE0EDFD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 14,
                        color: _isDark
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF2B7AE8),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${_soalList.length} Soal Aktif',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _isDark
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF2B7AE8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isDark
                        ? const Color(0xFF14532D)
                        : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.storage_rounded,
                        size: 14,
                        color: _isDark
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Tersimpan di Database',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _isDark
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFF16A34A),
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
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: _isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
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
                  color: _textGrey,
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
                    color: _isDark
                        ? const Color(0xFF3B2D14)
                        : const Color(0xFFFEF3C7),
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
              color: _textBlack,
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
              color: Color(0xFF8696A0),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMsg ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: _textGrey,
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
