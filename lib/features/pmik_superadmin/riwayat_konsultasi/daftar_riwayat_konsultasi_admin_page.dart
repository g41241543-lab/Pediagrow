import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/doctor_service.dart';
import '../../../core/services/staff_auth_service.dart';
import '../../../models/doctor_model.dart';
import '../../../models/staff_account_model.dart';
import '../../../shared/widgets/child_avatar.dart';
import '../../../shared/widgets/hover_lift.dart';
import '../../dokter/beranda/beranda_dokter_page.dart';
import '../../dokter/konsultasi/konsultasi_dokter_page.dart';
import '../../dokter/profil_dokter_page.dart';
import '../../pmik_admin/beranda/beranda_pmik_page.dart';
import '../../pmik_admin/konsultasi/konsultasi_pmik_admin_page.dart';
import '../../pmik_admin/profil_pmik_page.dart';
import '../beranda/beranda_superadmin_page.dart';
import '../konsultasi/konsultasi_superadmin_page.dart';
import '../profil/profil_superadmin_page.dart';
import '../../pengguna/beranda/beranda_page.dart';
import '../../pengguna/konsultasi/daftar_dokter_page.dart';
import '../../pengguna/profil/menu_profil_page.dart';
import 'detail_riwayat_konsultasi_admin_page.dart';
import 'riwayat_konsultasi_admin_model.dart';
import 'riwayat_konsultasi_admin_service.dart';

/// Halaman Daftar Riwayat Konsultasi untuk PMIK Superadmin dan Dokter.
///
/// Fitur:
/// - Header 56dp dari atas layar dengan tombol back (12dp dari tepi kiri) dan judul sejajar (jarak 12dp)
/// - Keterangan data di bagian ATAS
/// - Kolom pencarian real-time berdampingan dengan tombol Filter berdesain elegan
/// - Filter dokter interaktif via Modal Bottom Sheet (default menampilkan semua dokter)
/// - Seluruh konsultasi yang ditampilkan hanya yang berstatus Selesai
/// - Kartu riwayat konsultasi dengan avatar profil anak resmi
/// - Bottom Navigation Bar 4 menu persis seperti di Beranda
///
/// Jika [filterByDoctorName] diisi (mode dokter), halaman otomatis memfilter
/// hanya konsultasi yang ditangani dokter tersebut; tombol filter dokter disembunyikan.
class DaftarRiwayatKonsultasiAdminPage extends StatefulWidget {
  /// Nama dokter yang sedang login — jika diisi, tampilan hanya menampilkan
  /// riwayat konsultasi milik dokter tersebut tanpa tombol filter dokter.
  final String? filterByDoctorName;

  const DaftarRiwayatKonsultasiAdminPage({
    super.key,
    this.filterByDoctorName,
  });

  @override
  State<DaftarRiwayatKonsultasiAdminPage> createState() =>
      _DaftarRiwayatKonsultasiAdminPageState();
}

class _DaftarRiwayatKonsultasiAdminPageState
    extends State<DaftarRiwayatKonsultasiAdminPage> {
  // ─── Color Palette ─────────────────────────────────────────────────────────
  static const Color _colorNavBg = Color(0xFFF2EDED);
  static const Color _colorSecondaryGrey = Color(0xFF7F7F7F);
  static const Color _colorBorderLight = Color(0xFFC5C5C5);
  static const Color _colorTextBlack = Color(0xFF1E293B);
  static const Color _colorActiveBlue = Color(0xFF72A9F4);
  static const Color _colorInactiveNav = Color(0xFF9E9E9E);
  static const Color _colorFilterAccent = Color(0xFF72A9F4); // Biru primer resmi aplikasi PediaGrow
  static const Color _colorFilterLightBg = Color(0xFFEFF6FF);
  static const Color _colorFilterLightBorder = Color(0xFFBFDBFE);

  static const int _selectedNavIndex = 2; // Riwayat Konsultasi aktif

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterDoctor = 'Semua Dokter';
  String _selectedDoctorChild = 'Semua';

  late final Stream<List<RiwayatKonsultasiAdminItem>> _streamRiwayat;
  List<DoctorModel> _doctorList = [];

  /// Nama dokter efektif: jika di-pass via widget dipakai, jika tidak namun yang login adalah role dokter, ambil nama dari StaffAuthService
  String? get _effectiveDoctorName {
    if (widget.filterByDoctorName != null &&
        widget.filterByDoctorName!.trim().isNotEmpty) {
      return widget.filterByDoctorName!.trim();
    }
    final staff = StaffAuthService().currentStaff;
    if (staff != null &&
        staff.role == StaffRole.dokter &&
        staff.name.trim().isNotEmpty) {
      final doc = DoctorService().findDoctorForStaff(staff);
      return doc?.name ?? staff.name.trim();
    }
    return null;
  }

  /// ID dokter yang sedang login (jika role dokter)
  String? get _effectiveDoctorId {
    final staff = StaffAuthService().currentStaff;
    if (staff != null && staff.role == StaffRole.dokter) {
      final doc = DoctorService().findDoctorForStaff(staff);
      return doc?.id ?? staff.id;
    }
    return null;
  }

  /// true jika halaman ini dipakai untuk role dokter (filter by doctor)
  bool get _isDoctorMode => _effectiveDoctorName != null || _effectiveDoctorId != null;

  @override
  void initState() {
    super.initState();
    _streamRiwayat = RiwayatKonsultasiAdminService().streamRiwayatKonsultasi();
    DoctorService().doctorsNotifier.addListener(_onDoctorsUpdated);
    _doctorList = List.from(DoctorService().currentDoctors);

    _searchController.addListener(() {
      if (_searchQuery != _searchController.text) {
        setState(() => _searchQuery = _searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    DoctorService().doctorsNotifier.removeListener(_onDoctorsUpdated);
    super.dispose();
  }

  void _onDoctorsUpdated() {
    if (!mounted) return;
    setState(() => _doctorList = List.from(DoctorService().currentDoctors));
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      final staff = StaffAuthService().currentStaff;
      final isDokter = staff?.role == StaffRole.dokter;
      final isPmik = staff?.role == StaffRole.admin;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => isDokter
              ? const BerandaDokterPage()
              : isPmik
                  ? const BerandaPmikPage()
                  : staff == null
                      ? const BerandaPage()
                      : const BerandaSuperadminPage(),
        ),
        (route) => false,
      );
    }
  }

  void _onBottomNavTap(int index) {
    if (index == _selectedNavIndex) return;

    final staff = StaffAuthService().currentStaff;
    final isDokter = staff?.role == StaffRole.dokter;
    final isPmik = staff?.role == StaffRole.admin;

    Widget targetPage;
    switch (index) {
      case 0:
        targetPage = isDokter
            ? const BerandaDokterPage()
            : isPmik
                ? const BerandaPmikPage()
                : staff == null
                    ? const BerandaPage()
                    : const BerandaSuperadminPage();
        break;
      case 1:
        targetPage = isDokter
            ? const KonsultasiDokterPage()
            : isPmik
                ? const KonsultasiPmikAdminPage()
                : staff == null
                    ? const DaftarDokterPage()
                    : const KonsultasiSuperadminPage();
        break;
      case 2:
        return;
      case 3:
        targetPage = isDokter
            ? const ProfilDokterPage()
            : isPmik
                ? const ProfilPmikPage()
                : staff == null
                    ? const MenuProfilPage()
                    : const ProfilSuperadminPage();
        break;
      default:
        return;
    }

    if (index == 0) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => targetPage,
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 200),
        ),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => targetPage,
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 200),
        ),
      );
    }
  }

  List<RiwayatKonsultasiAdminItem> _applyFilters(
      List<RiwayatKonsultasiAdminItem> all) {
    // Sesuai ketentuan: hanya menampilkan yang selesai
    return all.where((item) {
      if (!item.isCompleted) {
        return false;
      }

      // Mode Dokter: filter otomatis hanya konsultasi yang ditangani dokter login
      // (cocokkan via doctorId atau nama dokter)
      if (_isDoctorMode) {
        final matchesId = _effectiveDoctorId != null &&
            item.doctorId.isNotEmpty &&
            (item.doctorId == _effectiveDoctorId ||
                item.doctorId == StaffAuthService().currentStaff?.id);
        final matchesName = _effectiveDoctorName != null &&
            _isDoctorNameMatch(item.doctorName, _effectiveDoctorName!);

        if (!matchesId && !matchesName) {
          return false;
        }
        if (_selectedDoctorChild != 'Semua') {
          if (item.childName.trim().toLowerCase() !=
              _selectedDoctorChild.trim().toLowerCase()) {
            return false;
          }
        }
      } else {
        // Mode Admin/Superadmin: Filter Dokter jika dipilih selain 'Semua Dokter'
        if (_filterDoctor != 'Semua Dokter') {
          if (item.doctorName.toLowerCase() != _filterDoctor.toLowerCase()) {
            return false;
          }
        }
      }

      // Pencarian kata kunci nama pasien
      // (mode dokter: hanya cari nama pasien; mode admin: cari nama pasien atau dokter)
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase().trim();
        final matchChild = item.childName.toLowerCase().contains(query);
        final matchDoctor = _isDoctorMode
            ? false
            : item.doctorName.toLowerCase().contains(query);
        final matchComplaint = item.complaint.toLowerCase().contains(query);
        if (!matchChild && !matchDoctor && !matchComplaint) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Fuzzy match nama dokter — mencocokkan kata kunci utama nama (strip gelar)
  bool _isDoctorNameMatch(String doctorName, String loggedInName) {
    if (loggedInName.isEmpty) return true;

    String extractKey(String name) {
      return name
          .toLowerCase()
          .replaceAll('dr.', '')
          .replaceAll('dr', '')
          .replaceAll('sp.a', '')
          .replaceAll('spa', '')
          .replaceAll('m.kes', '')
          .replaceAll('mkes', '')
          .replaceAll(',', '')
          .replaceAll('.', '')
          .trim();
    }

    final targetKey = extractKey(doctorName);
    final loggedInKey = extractKey(loggedInName);

    if (targetKey.isEmpty || loggedInKey.isEmpty) return true;

    final targetWords =
        targetKey.split(' ').where((w) => w.length >= 3).toList();
    final loggedInWords =
        loggedInKey.split(' ').where((w) => w.length >= 3).toList();

    for (final tw in targetWords) {
      for (final lw in loggedInWords) {
        if (tw.contains(lw) || lw.contains(tw)) return true;
      }
    }

    return targetKey.contains(loggedInKey) || loggedInKey.contains(targetKey);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: StreamBuilder<List<RiwayatKonsultasiAdminItem>>(
          stream: _streamRiwayat,
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData;
            final hasError = snapshot.hasError;
            final allData = snapshot.data ?? [];
            final filtered = _applyFilters(allData);

            // Kumpulkan daftar nama anak yang ditangani dokter ini (untuk filter kapsul mirip MPASI)
            final List<String> doctorHandledChildren = [];
            if (_isDoctorMode) {
              for (final item in allData) {
                if (!item.isCompleted) continue;
                final matchesId = _effectiveDoctorId != null &&
                    item.doctorId.isNotEmpty &&
                    (item.doctorId == _effectiveDoctorId ||
                        item.doctorId == StaffAuthService().currentStaff?.id);
                final matchesName = _effectiveDoctorName != null &&
                    _isDoctorNameMatch(item.doctorName, _effectiveDoctorName!);
                if (!matchesId && !matchesName) continue;
                final name = item.childName.trim();
                if (name.isNotEmpty && !doctorHandledChildren.contains(name)) {
                  doctorHandledChildren.add(name);
                }
              }
            }

            // Kumpulkan daftar opsi nama dokter untuk modal filter (mode admin/superadmin)
            final Set<String> doctorOptions = {'Semua Dokter'};
            for (final d in _doctorList) {
              doctorOptions.add(d.name);
            }
            for (final item in allData) {
              if (item.doctorName.isNotEmpty) doctorOptions.add(item.doctorName);
            }
            if (!doctorOptions.contains(_filterDoctor)) {
              _filterDoctor = 'Semua Dokter';
            }

            return Column(
              children: [
                // ─── HEADER (56dp dari atas layar) ───────────────────────────
                _buildHeader(),

                // ─── KONTEN SCROLLABLE ──────────────────────────────────────────
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 10.0),

                                    // 1. Search Bar & Filter Kapsul (mode dokter: bentuk searchbar dan filter sama seperti pengguna / resep MPASI)
                                    _isDoctorMode
                                        ? _buildDoctorSearchBarAndFilter(
                                            doctorHandledChildren)
                                        : _buildSearchAndFilterRow(
                                            doctorOptions.toList()),

                                    // 2. Chip status dokter aktif (mode admin saja)
                                    if (!_isDoctorMode &&
                                        _filterDoctor != 'Semua Dokter') ...[
                                      _buildActiveDoctorFilterChip(),
                                      const SizedBox(height: 6.0),
                                    ],
                                    const SizedBox(height: 8.0),

                                    // 3. Status State: Loading, Error, Empty, atau Daftar Kartu
                                    if (isLoading)
                                      _buildLoadingState()
                                    else if (hasError)
                                      _buildErrorState(
                                          snapshot.error.toString())
                                    else if (filtered.isEmpty)
                                      _buildEmptyState()
                                    else
                                      _buildConsultationList(filtered),

                                    const SizedBox(height: 14.0),

                                    // 4. Banner Keterangan di BAGIAN BAWAH
                                    _isDoctorMode
                                        ? _buildDoctorInfoBanner()
                                        : _buildInfoBanner(),
                                    const SizedBox(height: 16.0),
                                  ],
                                ),
                              ),

                              _buildFooterIllustration(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  // ─── HEADER ─────────────────────────────────────────────────────────────────
  /// Header diletakkan 56dp dari atas layar, berisi tombol back berjarak 12dp
  /// dari tepi kiri layar, dan judul halaman di sebelah kanannya berjarak 12dp.
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.only(top: 56.0, bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.only(left: 12.0, right: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20.0),
              child: InkWell(
                onTap: _handleBack,
                borderRadius: BorderRadius.circular(20.0),
                hoverColor: const Color(0x12000000),
                mouseCursor: SystemMouseCursors.click,
                child: const SizedBox(
                  width: 36.0,
                  height: 36.0,
                  child: Icon(
                    Icons.arrow_back,
                    size: 24.0,
                    color: _colorTextBlack,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                'Riwayat Konsultasi',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lato(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: _colorTextBlack,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BANNER INFORMASI DI BAGIAN ATAS (MODE ADMIN/SUPERADMIN) ─────────────────
  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2.0),
            child: Icon(
              Icons.info_outline_rounded,
              size: 20.0,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              'Data menampilkan seluruh konsultasi dari seluruh dokter dan pasien.',
              style: GoogleFonts.lato(
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E40AF),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BANNER INFORMASI DI BAGIAN ATAS (MODE DOKTER) ────────────────────────────
  Widget _buildDoctorInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2.0),
            child: Icon(
              Icons.assignment_ind_outlined,
              size: 20.0,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              'Menampilkan riwayat konsultasi yang telah Anda tangani.',
              style: GoogleFonts.lato(
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E40AF),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BARIS SEARCH BAR & TOMBOL FILTER ESTETIK ──────────────────────────────
  Widget _buildSearchAndFilterRow(List<String> doctorOptions) {
    final bool isFilterActive = _filterDoctor != 'Semua Dokter';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Search Bar (Expanded)
        Expanded(
          child: _buildSearchBar(),
        ),
        const SizedBox(width: 10.0),

        // 2. Tombol Filter
        HoverLift(
          lift: 2.0,
          cursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(14.0),
          child: Container(
            height: 48.0,
            decoration: BoxDecoration(
              color: isFilterActive ? _colorFilterLightBg : Colors.white,
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(
                color: isFilterActive ? _colorFilterAccent : _colorBorderLight,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4.0,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14.0),
              child: InkWell(
                onTap: () => _showDoctorFilterSheet(doctorOptions),
                borderRadius: BorderRadius.circular(14.0),
                hoverColor: isFilterActive
                    ? const Color(0xFFDBEAFE)
                    : const Color(0xFFEFF6FF),
                splashColor: _colorFilterAccent.withValues(alpha: 0.15),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Ikon corong filter
                      _FilterFunnelSparkleIcon(
                        size: 20.0,
                        color: _colorFilterAccent,
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        'Filter',
                        style: GoogleFonts.lato(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: _colorFilterAccent,
                        ),
                      ),
                      if (isFilterActive) ...[
                        const SizedBox(width: 5.0),
                        Container(
                          width: 6.0,
                          height: 6.0,
                          decoration: const BoxDecoration(
                            color: _colorFilterAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── CHIP INDIKATOR FILTER DOKTER AKTIF ─────────────────────────────────────
  Widget _buildActiveDoctorFilterChip() {
    if (_filterDoctor == 'Semua Dokter') return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            decoration: BoxDecoration(
              color: _colorFilterLightBg,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: _colorFilterLightBorder, width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.medical_services_outlined,
                  size: 13.0,
                  color: _colorFilterAccent,
                ),
                const SizedBox(width: 6.0),
                Text(
                  'Dokter: $_filterDoctor',
                  style: GoogleFonts.lato(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: _colorFilterAccent,
                  ),
                ),
                const SizedBox(width: 6.0),
                GestureDetector(
                  onTap: () {
                    setState(() => _filterDoctor = 'Semua Dokter');
                  },
                  behavior: HitTestBehavior.opaque,
                  child: const Icon(
                    Icons.close_rounded,
                    size: 15.0,
                    color: _colorFilterAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── SEARCH BAR & FILTER KHUSUS DOKTER (IDENTIK DENGAN PENGGUNA / RESEP MPASI) ─────
  Widget _buildDoctorSearchBarAndFilter(List<String> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Search Bar kapsul mirip Pengguna / Resep MPASI
        Container(
          height: 48.0,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F7),
            borderRadius: BorderRadius.circular(20.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_rounded,
                size: 22.0,
                color: Color(0xFF9E9E9E),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.lato(
                    fontSize: 14.5,
                    color: _colorTextBlack,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari riwayat konsultasi pasien...',
                    hintStyle: GoogleFonts.lato(
                      fontSize: 14.0,
                      color: const Color(0xFF9E9E9E),
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18.0,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10.0),

        // 2. Filter Kapsul Anak yang Ditangani Dokter (1 halaman menampilkan 3 filter pas, bisa digeser menyamping jika >3)
        Builder(
          builder: (context) {
            final availableWidth = MediaQuery.of(context).size.width - 32.0;
            // 2 jarak celah antar 3 filter @ 8dp (total 16)
            final chipWidth = (availableWidth - 16.0) / 3;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildDoctorChildChip(
                    label: 'Semua',
                    isSelected: _selectedDoctorChild == 'Semua',
                    onTap: () => setState(() => _selectedDoctorChild = 'Semua'),
                    width: chipWidth,
                  ),
                  ...children.map((childName) {
                    final isSelected = _selectedDoctorChild == childName;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: _buildDoctorChildChip(
                        label: childName,
                        isSelected: isSelected,
                        onTap: () => setState(() => _selectedDoctorChild = childName),
                        width: chipWidth,
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDoctorChildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required double width,
  }) {
    return _HoverDoctorChildChip(
      label: label,
      isSelected: isSelected,
      onTap: onTap,
      width: width,
    );
  }

  // ─── SEARCH BAR (mode admin: cari pasien atau dokter) ────────────────────
  Widget _buildSearchBar({String? hintText}) {
    final hint = hintText ??
        (_isDoctorMode ? 'Cari nama pasien...' : 'Cari nama pasien atau dokter...');
    return Container(
      height: 48.0,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: _colorBorderLight, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4.0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.lato(
          fontSize: 14.0,
          color: _colorTextBlack,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.lato(
            fontSize: 13.5,
            color: _colorSecondaryGrey,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: _colorSecondaryGrey,
            size: 22.0,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: _colorSecondaryGrey,
                    size: 18.0,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 13.0,
            horizontal: 14.0,
          ),
        ),
      ),
    );
  }

  // ─── MODAL BOTTOM SHEET PILIH DOKTER ────────────────────────────────────────
  void _showDoctorFilterSheet(List<String> doctorOptions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 42.0,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(3.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18.0),

                    // Header Sheet
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const _FilterFunnelSparkleIcon(
                              size: 20.0,
                              color: _colorFilterAccent,
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              'Filter Dokter',
                              style: GoogleFonts.lato(
                                fontSize: 17.0,
                                fontWeight: FontWeight.bold,
                                color: _colorTextBlack,
                              ),
                            ),
                          ],
                        ),
                        if (_filterDoctor != 'Semua Dokter')
                          TextButton(
                            onPressed: () {
                              setState(() => _filterDoctor = 'Semua Dokter');
                              Navigator.of(ctx).pop();
                            },
                            child: Text(
                              'Reset Filter',
                              style: GoogleFonts.lato(
                                fontSize: 13.0,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Pilih dokter untuk memfilter riwayat konsultasi pasien:',
                      style: GoogleFonts.lato(
                        fontSize: 13.0,
                        color: _colorSecondaryGrey,
                      ),
                    ),
                    const SizedBox(height: 14.0),
                    const Divider(height: 1.0, thickness: 1.0, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 10.0),

                    // Daftar Dokter
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: doctorOptions.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1.0,
                          thickness: 1.0,
                          color: Color(0xFFF8FAFC),
                        ),
                        itemBuilder: (context, index) {
                          final docName = doctorOptions[index];
                          final isSelected = docName == _filterDoctor;

                          return Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12.0),
                            child: InkWell(
                              onTap: () {
                                setState(() => _filterDoctor = docName);
                                Navigator.of(ctx).pop();
                              },
                              borderRadius: BorderRadius.circular(12.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 12.0,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _colorFilterLightBg
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38.0,
                                      height: 38.0,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? _colorFilterAccent.withValues(alpha: 0.15)
                                            : const Color(0xFFF1F5F9),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        docName == 'Semua Dokter'
                                            ? Icons.people_outline_rounded
                                            : Icons.person_rounded,
                                        size: 20.0,
                                        color: isSelected
                                            ? _colorFilterAccent
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(width: 12.0),
                                    Expanded(
                                      child: Text(
                                        docName,
                                        style: GoogleFonts.lato(
                                          fontSize: 14.0,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? _colorFilterAccent
                                              : _colorTextBlack,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 20.0,
                                        color: _colorFilterAccent,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── DAFTAR KARTU KONSULTASI ──────────────────────────────────────────────
  Widget _buildConsultationList(List<RiwayatKonsultasiAdminItem> items) {
    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _buildConsultationCard(items[i]),
          if (i < items.length - 1) const SizedBox(height: 12.0),
        ],
      ],
    );
  }

  // ─── KARTU KONSULTASI SESUAI DESAIN ─────────────────────────────────────────
  Widget _buildConsultationCard(RiwayatKonsultasiAdminItem item) {
    final ageText = item.calculatedAge;

    return HoverLift(
      borderRadius: BorderRadius.circular(16.0),
      cursor: SystemMouseCursors.click,
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DetailRiwayatKonsultasiAdminPage(item: item),
              ),
            );
          },
          hoverColor: const Color(0xFFF1F5F9),
          splashColor: const Color(0xFF72A9F4).withValues(alpha: 0.12),
          highlightColor: const Color(0xFF72A9F4).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris Atas: Avatar + Nama & Usia + Badge Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar Anak Profil Resmi
                    ChildAvatar(
                      gender: item.childGender,
                      isGirl: item.isGirl,
                      size: 46.0,
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.childName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lato(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: _colorTextBlack,
                            ),
                          ),
                          const SizedBox(height: 3.0),
                          Text(
                            ageText,
                            style: GoogleFonts.lato(
                              fontSize: 12.5,
                              color: _colorSecondaryGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    _buildStatusBadge(item.status),
                  ],
                ),
                const SizedBox(height: 12.0),
                const Divider(height: 1.0, thickness: 1.0, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10.0),

                // Dokter & Tanggal
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 15.0,
                      color: _colorSecondaryGrey,
                    ),
                    const SizedBox(width: 6.0),
                    Expanded(
                      child: Text(
                        item.doctorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          fontSize: 13.0,
                          color: _colorSecondaryGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14.0,
                      color: _colorSecondaryGrey,
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      item.formattedDate,
                      style: GoogleFonts.lato(
                        fontSize: 12.5,
                        color: _colorSecondaryGrey,
                      ),
                    ),
                  ],
                ),

                // Ringkasan jika ada
                if (item.complaint.isNotEmpty) ...[
                  const SizedBox(height: 8.0),
                  Text(
                    'Keluhan: ${item.complaint}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                      fontSize: 12.5,
                      color: const Color(0xFF475569),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ));
  }

  // ─── STATUS BADGE ─────────────────────────────────────────────────────────
  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        'Selesai',
        style: GoogleFonts.lato(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF15803D),
        ),
      ),
    );
  }

  // ─── EMPTY STATE ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            Container(
              width: 72.0,
              height: 72.0,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 36.0,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'Belum Ada Riwayat Konsultasi',
              style: GoogleFonts.lato(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: _colorTextBlack,
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              _filterDoctor != 'Semua Dokter'
                  ? 'Tidak ada riwayat selesai bersama $_filterDoctor.'
                  : 'Seluruh riwayat konsultasi yang selesai akan tercatat di sini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 13.0,
                color: _colorSecondaryGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── LOADING STATE ────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 50.0),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_colorActiveBlue),
        ),
      ),
    );
  }

  // ─── ERROR STATE ──────────────────────────────────────────────────────────
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 40.0, color: Color(0xFFEF4444)),
            const SizedBox(height: 12.0),
            Text(
              'Gagal memuat data riwayat',
              style: GoogleFonts.lato(
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
                color: _colorTextBlack,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 12.0,
                color: _colorSecondaryGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── FOOTER ILLUSTRATION ──────────────────────────────────────────────────
  Widget _buildFooterIllustration() {
    return SizedBox(
      width: double.infinity,
      child: Image.asset(
        'assets/images/beranda_landscape_footer_fiks.png',
        width: double.infinity,
        fit: BoxFit.fitWidth,
        alignment: Alignment.bottomCenter,
        errorBuilder: (context, error, stackTrace) =>
            const SizedBox(height: 20.0),
      ),
    );
  }

  // ─── BOTTOM NAVIGATION BAR (IDENTIK DENGAN BERANDA) ─────────────────────────
  Widget _buildBottomNavigationBar() {
    const navItems = [
      _NavData(icon: Icons.home_rounded, label: 'Beranda'),
      _NavData(icon: Icons.question_answer_rounded, label: 'Konsultasi'),
      _NavData(icon: Icons.manage_search_rounded, label: 'Riwayat Konsultasi'),
      _NavData(icon: Icons.person_rounded, label: 'Profil'),
    ];

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _colorNavBg,
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 8.0,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(navItems.length, (i) {
              final isSelected = i == _selectedNavIndex;
              final item = navItems[i];

              return Expanded(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _onBottomNavTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        // Lingkaran putih timbul di belakang ikon aktif biru
                        Container(
                          width: 32.0,
                          height: 32.0,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 4.0,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            item.icon,
                            size: 19.0,
                            color: _colorActiveBlue,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                fontSize: 10.5,
                                fontWeight: FontWeight.normal,
                                color: _colorTextBlack,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Icon(
                          item.icon,
                          size: 21.0,
                          color: _colorInactiveNav,
                        ),
                        const SizedBox(height: 3.0),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lato(
                                fontSize: 10.5,
                                fontWeight: FontWeight.normal,
                                color: _colorInactiveNav,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
          ),
        ),
      ),
    );
  }
}

// ─── WIDGET IKON CORONG FILTER DENGAN SPARKLE (SESUAI SLIDE 2) ───────────────
class _FilterFunnelSparkleIcon extends StatelessWidget {
  final double size;
  final Color color;

  const _FilterFunnelSparkleIcon({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _FilterSparklePainter(color: color),
    );
  }
}

class _FilterSparklePainter extends CustomPainter {
  final Color color;

  const _FilterSparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // 1. Corong Filter (Funnel)
    final funnelPath = Path();
    // Garis horizontal atas
    funnelPath.moveTo(w * 0.15, h * 0.26);
    funnelPath.lineTo(w * 0.55, h * 0.26);
    // Garis miring kanan turun
    funnelPath.lineTo(w * 0.44, h * 0.48);
    // Garis vertikal tabung corong ke bawah
    funnelPath.lineTo(w * 0.44, h * 0.82);

    canvas.drawPath(funnelPath, strokePaint);

    // Garis aksen kecil di kanan tabung corong (seperti pada slide 2)
    canvas.drawLine(
      Offset(w * 0.62, h * 0.46),
      Offset(w * 0.62, h * 0.64),
      strokePaint,
    );

    // 2. Bintang Sparkle 4 Sudut (Diamond Star) di kanan atas
    final starCenterX = w * 0.76;
    final starCenterY = h * 0.28;
    final starRadius = w * 0.18;

    final starPath = Path();
    starPath.moveTo(starCenterX, starCenterY - starRadius);
    starPath.quadraticBezierTo(
      starCenterX,
      starCenterY,
      starCenterX + starRadius,
      starCenterY,
    );
    starPath.quadraticBezierTo(
      starCenterX,
      starCenterY,
      starCenterX,
      starCenterY + starRadius,
    );
    starPath.quadraticBezierTo(
      starCenterX,
      starCenterY,
      starCenterX - starRadius,
      starCenterY,
    );
    starPath.quadraticBezierTo(
      starCenterX,
      starCenterY,
      starCenterX,
      starCenterY - starRadius,
    );
    starPath.close();

    canvas.drawPath(starPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _FilterSparklePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _NavData {
  final IconData icon;
  final String label;
  const _NavData({required this.icon, required this.label});
}

class _HoverDoctorChildChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double width;

  const _HoverDoctorChildChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.width,
  });

  @override
  State<_HoverDoctorChildChip> createState() => _HoverDoctorChildChipState();
}

class _HoverDoctorChildChipState extends State<_HoverDoctorChildChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;

    if (widget.isSelected) {
      bgColor = const Color(0xFFEFF6FF);
      borderColor = const Color(0xFF3985E7);
    } else {
      if (_hovered) {
        bgColor = const Color(0xFFF1F5F9);
        borderColor = const Color(0xFFCBD5E1);
      } else {
        bgColor = Colors.white;
        borderColor = const Color(0xFFE2E8F0);
      }
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.width,
          padding: const EdgeInsets.symmetric(
            horizontal: 8.0,
            vertical: 7.0,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: borderColor,
              width: 1.2,
            ),
          ),
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 13.0,
              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
              color: widget.isSelected
                  ? const Color(0xFF3985E7)
                  : const Color(0xFF7F7F7F),
            ),
          ),
        ),
      ),
    );
  }
}
