import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/soal_service.dart';
import '../../../../core/services/staff_auth_service.dart';
import '../../../../models/soal_model.dart';
import '../../../../models/staff_account_model.dart';
import '../../../../shared/widgets/illustration_forest_footer.dart';
import '../../../../shared/widgets/pedia_bottom_nav_bar.dart';
import '../../../pengguna/beranda/widgets/full_page_sky_background.dart';
import '../../../pengguna/beranda/widgets/header_sky_illustration.dart';
import '../../../pmik_admin/beranda/beranda_pmik_page.dart';
import '../beranda_superadmin_page.dart';
import 'edit_soal_permainan_page.dart';

/// Halaman Permainan untuk Admin (PMIK) & Superadmin — Bank Soal & CRUD.
///
/// Menampilkan seluruh 25 bank soal dalam kartu yang dapat ditambah, diedit, dan dihapus.
/// Dilengkapi chip status:
/// - "25 Soal di Bank"
/// - "10 Soal per Sesi"
/// - "Tersimpan di Database"
///
/// Background & Ilustrasi adaptif tema (Dark Mode / Light Mode):
/// - Header langit dinamis mengikuti mode tema aplikasi
/// - Footer menggunakan [IllustrationForestFooter] yang menyatu mulus dengan latar
class PermainanAdminPage extends StatefulWidget {
  const PermainanAdminPage({super.key});

  @override
  State<PermainanAdminPage> createState() => _PermainanAdminPageState();
}

class _PermainanAdminPageState extends State<PermainanAdminPage>
    with TickerProviderStateMixin {
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _scaffoldBg => _isDark ? const Color(0xFF0B1014) : Colors.white;
  Color get _cardBg => _isDark ? const Color(0xFF1A2228) : Colors.white;
  Color get _borderColor => _isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF);
  Color get _textBlack => _isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014);
  Color get _textGrey => _isDark ? const Color(0xFF8696A0) : const Color(0xFF667781);

  List<SoalModel> _soalList = [];
  bool _isLoading = true;
  String? _errorMsg;

  // Notifikasi status bar
  bool _showNotifBar = false;
  String _notifMessage = 'Berhasil Memperbarui Soal';
  bool _isNotifError = false;
  late AnimationController _notifController;
  late Animation<Offset> _notifSlide;

  // Shimmer pulse animation untuk skeleton loading
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

    // Stale-While-Revalidate: Muat instan dari cache lokal (seluruh soal bank)
    final cached = SoalService.cachedSoal;
    if (cached != null && cached.isNotEmpty) {
      _soalList = List<SoalModel>.from(cached);
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
  // DATA LOADING
  // ──────────────────────────────────────────────────────────────────
  Future<void> _loadSoalFast() async {
    setState(() {
      _isLoading = _soalList.isEmpty;
      _errorMsg = null;
    });

    try {
      final initial = await SoalService.getAllSoal();
      if (!mounted) return;

      if (initial.isNotEmpty) {
        setState(() {
          _soalList = List<SoalModel>.from(initial);
          _isLoading = false;
        });
      }
      await _syncInBackground();
    } catch (e) {
      if (!mounted) return;
      if (_soalList.isEmpty) {
        setState(() {
          _errorMsg = 'Gagal memuat bank soal: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _syncInBackground() async {
    try {
      final updated = await SoalService.syncInBackground();
      if (!mounted || updated == null || updated.isEmpty) return;

      if (!_isListEqual(_soalList, updated)) {
        setState(() {
          _soalList = List<SoalModel>.from(updated);
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
          a[i].penjelasan != b[i].penjelasan ||
          a[i].isActive != b[i].isActive ||
          a[i].perluTinjauan != b[i].perluTinjauan) {
        return false;
      }
    }
    return true;
  }

  // ──────────────────────────────────────────────────────────────────
  // CRUD ACTIONS
  // ──────────────────────────────────────────────────────────────────

  /// Buka form untuk menambah soal baru
  Future<void> _bukaTambahSoal() async {
    final result = await Navigator.of(context).push<SoalModel>(
      _FadeSlideRoute(
        builder: (_) => const EditSoalPermainanPage(soal: null),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _soalList.add(result);
    });
    _tampilkanNotif('Berhasil Menambahkan Soal Baru', isError: false);
  }

  /// Buka form untuk mengedit soal yang sudah ada
  Future<void> _bukaEditSoal(int index) async {
    final soal = _soalList[index];
    final result = await Navigator.of(context).push<SoalModel>(
      _FadeSlideRoute(
        builder: (_) => EditSoalPermainanPage(soal: soal),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _soalList[index] = result;
    });
    _tampilkanNotif('Berhasil Memperbarui Soal', isError: false);
  }

  /// Konfirmasi dan hapus soal dari bank soal
  Future<void> _konfirmasiHapusSoal(int index) async {
    // Validasi batas minimum: tidak boleh < 10 soal
    if (_soalList.length <= 10) {
      _tampilkanDialogPeringatanMinimum();
      return;
    }

    final soal = _soalList[index];

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Soal?',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            color: _textBlack,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus Soal #${soal.id} dari Bank Soal?\n\nTindakan ini tidak dapat dibatalkan.',
          style: GoogleFonts.lato(
            fontSize: 14,
            color: _textGrey,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Batal',
              style: GoogleFonts.lato(
                color: _textGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.lato(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (konfirmasi != true || !mounted) return;

    final result = await SoalService.hapusSoal(soal.id);

    if (!mounted) return;
    if (result.success) {
      setState(() {
        _soalList.removeAt(index);
      });
      _tampilkanNotif(result.message, isError: false);
    } else {
      _tampilkanNotif(result.message, isError: true);
    }
  }

  /// Dialog saat admin mencoba menghapus padahal bank soal sudah sisa 10
  void _tampilkanDialogPeringatanMinimum() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tidak Dapat Dihapus',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.bold,
                  color: _textBlack,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Bank soal tidak dapat dikurangi lagi karena jumlah soal saat ini adalah 10.\n\nSatu sesi kuis anak di role User membutuhkan tepat 10 soal unik. Silakan tambahkan soal baru terlebih dahulu sebelum menghapus soal ini.',
          style: GoogleFonts.lato(
            fontSize: 14,
            color: _textGrey,
            height: 1.5,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B7AE8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // NOTIFIKASI SUKSES / GAGAL
  // ──────────────────────────────────────────────────────────────────
  Future<void> _tampilkanNotif(String pesan, {required bool isError}) async {
    setState(() {
      _notifMessage = pesan;
      _isNotifError = isError;
      _showNotifBar = true;
    });
    _notifController.forward(from: 0);
    await Future.delayed(const Duration(seconds: 3));
    if (mounted && _showNotifBar) {
      _tutupNotif();
    }
  }

  Future<void> _tutupNotif() async {
    await _notifController.reverse();
    if (mounted) setState(() => _showNotifBar = false);
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
            SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned.fill(child: FullPageSkyBackground()),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Area Biru Seamless (Adaptif Tema)
                      _buildSeamlessBlueArea(context),

                      // 2. Konten Utama
                      if (_isLoading)
                        _buildSkeletonLoading()
                      else if (_errorMsg != null && _soalList.isEmpty)
                        _buildError()
                      else
                        _buildContentSection(),

                      const SizedBox(height: 24),

                      // 3. Ilustrasi Landscape Footer (Adaptif Tema)
                      const IllustrationForestFooter(fit: BoxFit.fitWidth),
                    ],
                  ),
                ],
              ),
            ),

            // ── Perisai status bar ──────────────────────────────────────
            // Blok solid di atas konten yang di-scroll agar badge/teks
            // kartu tidak tampil menimpa jam & ikon di area status bar.
            // Tingginya = tinggi status bar dari MediaQuery (safe area atas).
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: MediaQuery.of(context).padding.top,
                color: _isDark
                    ? HeaderSkyIllustration.nightGradientColors.first
                    : HeaderSkyIllustration.dayGradientColors.first,
              ),
            ),

            if (_showNotifBar) _buildNotifBar(),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // 1. AREA BIRU SEAMLESS HEADER (ADAPTIF DARK/LIGHT MODE)
  // ──────────────────────────────────────────────────────────────────
  Widget _buildSeamlessBlueArea(BuildContext context) {
    final skyMode = _isDark ? SkyTimeMode.night : SkyTimeMode.day;
    final isNight = _isDark;

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
          Positioned.fill(
            child: HeaderSkyIllustration(
              mode: skyMode,
              renderBackgroundGradient: false,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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
                        Expanded(
                          child: Text(
                            'Permainan',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lato(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
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

        // Info Kuis & Chip status
        _buildKuisInfo(),

        const SizedBox(height: 16),

        // Tombol Tambah Soal
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _bukaTambahSoal,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              label: Text(
                'Tambah Soal Baru',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B7AE8),
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Garis pemisah
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(color: _borderColor, thickness: 1),
        ),

        const SizedBox(height: 16),

        // Label "Daftar Soal" + Counter
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

        // Seluruh 25 Kartu Soal
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
  // INFO KUIS (Ikon, Judul, Chip Informasi Baru)
  // ──────────────────────────────────────────────────────────────────
  Widget _buildKuisInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Center(
        child: Column(
          children: [
            // Ikon Otak + Checklist Badge
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

            // Judul
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

            // Subjudul
            Text(
              'Kelola bank pertanyaan dan kunci jawaban kuis stunting untuk edukasi pengguna',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: _textGrey,
                height: 1.45,
              ),
            ),

            const SizedBox(height: 14),

            // 3 CHIP STATUS:
            // 1. "25 Soal di Bank"
            // 2. "10 Soal per Sesi"
            // 3. "Tersimpan di Database"
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                // Chip 1: Soal di Bank
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        '${_soalList.length} Soal di Bank',
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

                // Chip 2: Soal per Sesi
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isDark
                        ? const Color(0xFF2A2B4A)
                        : const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.replay_rounded,
                        size: 14,
                        color: _isDark
                            ? const Color(0xFFA78BFA)
                            : const Color(0xFF7C3AED),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '10 Soal per Sesi',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _isDark
                              ? const Color(0xFFA78BFA)
                              : const Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  ),
                ),

                // Chip 3: Tersimpan di Database
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
  // KARTU SOAL (DENGAN TOMBOL EDIT & HAPUS, SERTA BADGE PERLU TINJAUAN)
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
          // ── Baris atas: label "Soal N • Kategori" + tombol edit & hapus ──
          // Menggunakan Expanded pada teks agar tidak pernah overflow pada
          // kategori panjang ("Imunisasi & Kesehatan", "Tumbuh Kembang", dll.).
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Teks "Soal N • Kategori" — mengambil ruang sisa, truncate jika panjang
              Expanded(
                child: Text(
                  'Soal ${index + 1} • ${soal.kategori}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textGrey,
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // Tombol Edit — area sentuh ergonomis 40x40px (visual 32x32)
              GestureDetector(
                onTap: () => _bukaEditSoal(index),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
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
                ),
              ),

              // Tombol Hapus — area sentuh ergonomis 40x40px (visual 32x32)
              GestureDetector(
                onTap: () => _konfirmasiHapusSoal(index),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _isDark
                            ? const Color(0xFF381A1A)
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Baris kedua: badge "Perlu Tinjauan" (jika ada) ──
          // Dipisah ke baris sendiri sehingga tidak pernah berkompetisi
          // dengan tombol edit/hapus dan tidak menyebabkan overflow.
          if (soal.perluTinjauan) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _isDark
                        ? const Color(0xFF3B2D14)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.rate_review_outlined,
                        size: 11,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Perlu Tinjauan',
                        style: GoogleFonts.lato(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),

          // Teks Pernyataan Soal
          Text(
            soal.pertanyaan,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textBlack,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 10),

          // Pill Kunci Jawaban
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: soal.jawabanBenar
                      ? (_isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7))
                      : (_isDark ? const Color(0xFF381A1A) : const Color(0xFFFEE2E2)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Kunci: ${soal.jawabanBenar ? "BENAR" : "SALAH"}',
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: soal.jawabanBenar
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // SKELETON LOADING
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
                    Container(
                      width: 220,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 280,
                      height: 13,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: List.generate(4, (index) => _buildSkeletonCard()),
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
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
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
              _errorMsg ?? 'Terjadi kesalahan memuat soal',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: _textGrey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadSoalFast,
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
  // NOTIFIKASI BAR
  // ──────────────────────────────────────────────────────────────────
  Widget _buildNotifBar() {
    final bgColor = _isNotifError ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    final iconData = _isNotifError ? Icons.error_outline_rounded : Icons.check_circle_rounded;

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: bgColor,
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
                  Icon(iconData, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _notifMessage,
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
// TRANSISI HALUS UNTUK ROUTE
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
