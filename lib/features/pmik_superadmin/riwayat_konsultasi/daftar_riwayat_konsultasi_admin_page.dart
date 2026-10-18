import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/doctor_service.dart';
import '../../../core/services/staff_auth_service.dart';
import '../../../models/doctor_model.dart';
import '../../../models/staff_account_model.dart';
import '../../../shared/widgets/child_avatar.dart';
import '../../dokter/beranda/beranda_dokter_page.dart';
import '../../dokter/konsultasi/konsultasi_dokter_page.dart';
import '../../dokter/profil_dokter_page.dart';
import '../../pmik_admin/beranda/beranda_pmik_page.dart';
import '../../pmik_admin/konsultasi/konsultasi_pmik_admin_page.dart';
import '../../pmik_admin/profil_pmik_page.dart';
import '../beranda/beranda_superadmin_page.dart';
import '../konsultasi/konsultasi_superadmin_page.dart';
import '../profil/profil_superadmin_page.dart';
import 'detail_riwayat_konsultasi_admin_page.dart';
import 'riwayat_konsultasi_admin_model.dart';
import 'riwayat_konsultasi_admin_service.dart';

/// Halaman Daftar Riwayat Konsultasi untuk PMIK Superadmin.
///
/// Fitur:
/// - Header 56dp dari atas layar dengan tombol back dan judul tebal
/// - Filter dropdown "Semua Dokter" & "Semua Status"
/// - Kolom pencarian real-time nama pasien atau dokter
/// - Daftar kartu riwayat konsultasi dengan avatar wajah anak dinamis
/// - Banner info di bagian bawah
/// - Bottom Navigation Bar 4 menu (Beranda, Konsultasi, Riwayat Konsultasi, Profil) aktif
class DaftarRiwayatKonsultasiAdminPage extends StatefulWidget {
  const DaftarRiwayatKonsultasiAdminPage({super.key});

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
  static const Color _colorChipBg = Color(0xFFF3F4F6);
  static const Color _colorTextBlack = Color(0xFF000000);
  static const int _selectedNavIndex = 2; // Riwayat Konsultasi

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterDoctor = 'Semua Dokter';
  String _filterStatus = 'Semua Status';

  List<DoctorModel> _doctorList = [];

  static const List<String> _statusOptions = [
    'Semua Status',
    'Dijadwalkan',
    'Selesai',
  ];

  @override
  void initState() {
    super.initState();
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
                : const BerandaSuperadminPage();
        break;
      case 1:
        targetPage = isDokter
            ? const KonsultasiDokterPage()
            : isPmik
                ? const KonsultasiPmikAdminPage()
                : const KonsultasiSuperadminPage();
        break;
      case 3:
        targetPage = isDokter
            ? const ProfilDokterPage()
            : isPmik
                ? const ProfilPmikPage()
                : const ProfilSuperadminPage();
        break;
      default:
        return;
    }

    final isLeft = index < _selectedNavIndex;
    final beginOffset = Offset(isLeft ? -0.25 : 0.25, 0.0);
    final route = PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) => targetPage,
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );

    if (index == 0) {
      Navigator.of(context).pushAndRemoveUntil(route, (r) => false);
    } else {
      Navigator.of(context).pushReplacement(route);
    }
  }

  void _navigateToDetail(RiwayatKonsultasiAdminItem item) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DetailRiwayatKonsultasiAdminPage(item: item),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0.0),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  List<RiwayatKonsultasiAdminItem> _applyFilters(
      List<RiwayatKonsultasiAdminItem> all) {
    return all.where((item) {
      // 1. Filter Dokter
      if (_filterDoctor != 'Semua Dokter' &&
          item.doctorName.toLowerCase() != _filterDoctor.toLowerCase()) {
        return false;
      }
      // 2. Filter Status
      if (_filterStatus != 'Semua Status' &&
          item.status.toLowerCase() != _filterStatus.toLowerCase()) {
        return false;
      }
      // 3. Pencarian Nama Pasien atau Dokter
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchPatient = item.childName.toLowerCase().contains(q);
        final matchDoctor = item.doctorName.toLowerCase().contains(q);
        if (!matchPatient && !matchDoctor) {
          return false;
        }
      }
      return true;
    }).toList();
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
          stream: RiwayatKonsultasiAdminService().streamRiwayatKonsultasi(),
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData;
            final hasError = snapshot.hasError;
            final allData = snapshot.data ?? [];
            final filtered = _applyFilters(allData);

            // Kumpulkan opsi nama dokter untuk dropdown
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

                // ─── KONTEN SCROLLABLE (Padding horizontal 16dp) ────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 14.0),

                        // 1. Dua Dropdown Chip (Semua Dokter & Semua Status)
                        _buildFilterRow(doctorOptions.toList()),
                        const SizedBox(height: 14.0),

                        // 2. Kolom Pencarian
                        _buildSearchBar(),
                        const SizedBox(height: 18.0),

                        // 3. Status State: Loading, Error, Empty, atau Daftar Kartu
                        if (isLoading)
                          _buildLoadingState()
                        else if (hasError)
                          _buildErrorState(snapshot.error.toString())
                        else if (filtered.isEmpty)
                          _buildEmptyState()
                        else
                          _buildConsultationList(filtered),

                        const SizedBox(height: 18.0),

                        // 4. Banner Info di Bawah Daftar
                        _buildInfoBanner(),
                        const SizedBox(height: 24.0),
                      ],
                    ),
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
            GestureDetector(
              onTap: _handleBack,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 32.0,
                height: 32.0,
                child: Icon(
                  Icons.arrow_back,
                  size: 24.0,
                  color: _colorTextBlack,
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

  // ─── FILTER ROW (DROPDOWN CHIPS) ──────────────────────────────────────────
  Widget _buildFilterRow(List<String> doctorOptions) {
    return Row(
      children: [
        // Dropdown Semua Dokter
        Expanded(
          child: _buildDropdownChip(
            value: doctorOptions.contains(_filterDoctor)
                ? _filterDoctor
                : 'Semua Dokter',
            items: doctorOptions,
            onChanged: (val) {
              if (val != null) setState(() => _filterDoctor = val);
            },
          ),
        ),
        const SizedBox(width: 12.0),
        // Dropdown Semua Status
        Expanded(
          child: _buildDropdownChip(
            value: _filterStatus,
            items: _statusOptions,
            onChanged: (val) {
              if (val != null) setState(() => _filterStatus = val);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownChip({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 38.0,
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      decoration: BoxDecoration(
        color: _colorChipBg,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: _colorBorderLight, width: 1.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20.0,
            color: _colorSecondaryGrey,
          ),
          style: GoogleFonts.lato(
            fontSize: 13.0,
            color: _colorSecondaryGrey,
            fontWeight: FontWeight.w500,
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lato(
                  fontSize: 13.0,
                  color: item == value
                      ? const Color(0xFF1E293B)
                      : _colorSecondaryGrey,
                  fontWeight:
                      item == value ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ─── SEARCH BAR ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      height: 44.0,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: _colorBorderLight, width: 1.0),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.lato(
          fontSize: 14.0,
          color: const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          hintText: 'Cari nama pasien atau dokter....',
          hintStyle: GoogleFonts.lato(
            fontSize: 13.5,
            color: _colorSecondaryGrey,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 22.0,
            color: _colorSecondaryGrey,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18.0,
                    color: _colorSecondaryGrey,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
        ),
      ),
    );
  }

  // ─── DAFTAR KARTU KONSULTASI ───────────────────────────────────────────────
  Widget _buildConsultationList(List<RiwayatKonsultasiAdminItem> items) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14.0),
      itemBuilder: (context, index) {
        return _buildConsultationCard(items[index]);
      },
    );
  }

  Widget _buildConsultationCard(RiwayatKonsultasiAdminItem item) {
    final isGirl = item.isGirl;
    final isSelesai = item.status.toLowerCase().contains('selesai');

    return GestureDetector(
      onTap: () => _navigateToDetail(item),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 10.0,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ─── Avatar Anak Resmi PediaGrow ──────────────────────────────
            ChildAvatar(
              gender: item.childGender,
              isGirl: isGirl,
              size: 48.0,
              backgroundColor:
                  isGirl ? const Color(0xFFFFD1D6) : const Color(0xFFBBE4FF),
            ),
            const SizedBox(width: 14.0),

            // ─── Detail Pasien & Dokter ──────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris Nama Pasien & Badge Status di pojok kanan atas
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          item.childName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: _colorTextBlack,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      _buildStatusBadge(isSelesai),
                    ],
                  ),
                  const SizedBox(height: 4.0),

                  // Nama Dokter
                  Text(
                    item.doctorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                      fontSize: 13.0,
                      color: _colorSecondaryGrey,
                    ),
                  ),
                  const SizedBox(height: 8.0),

                  // Tanggal Konsultasi
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 15.0,
                        color: _colorSecondaryGrey,
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        item.formattedDate,
                        style: GoogleFonts.lato(
                          fontSize: 13.0,
                          color: _colorSecondaryGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),

            // ─── Chevron Kanan ───────────────────────────────────────────
            const Icon(
              Icons.chevron_right_rounded,
              size: 24.0,
              color: Color(0xFF4A4A4A),
            ),
          ],
        ),
      ),
    );
  }

  /// Badge Status Konsultasi:
  /// - "Dijadwalkan": Latar kuning dan teks oranye
  /// - "Selesai": Latar hijau tosca dan teks putih
  Widget _buildStatusBadge(bool isSelesai) {
    if (isSelesai) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFF33CCA6),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Text(
          'Selesai',
          style: GoogleFonts.lato(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEEA0),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Text(
          'Dijadwalkan',
          style: GoogleFonts.lato(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFE67E00),
          ),
        ),
      );
    }
  }

  // ─── INFO BANNER ────────────────────────────────────────────────────────────
  /// Banner berlatar biru muda dengan border dan teks biru, serta ikon info di kiri
  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FD),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: const Color(0xFF72A9F4),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 22.0,
            color: Color(0xFF3985E7),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              'Data menampilkan seluruh konsultasi dari seluruh dokter dan pasien.',
              style: GoogleFonts.lato(
                fontSize: 13.5,
                color: const Color(0xFF2B7CD6),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── LOADING STATE ──────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60.0),
      child: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF3985E7),
        ),
      ),
    );
  }

  // ─── ERROR STATE ────────────────────────────────────────────────────────────
  Widget _buildErrorState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48.0,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(height: 12.0),
          Text(
            'Gagal memuat riwayat konsultasi.',
            style: GoogleFonts.lato(
              fontSize: 15.0,
              fontWeight: FontWeight.bold,
              color: _colorTextBlack,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            'Silakan periksa koneksi internet Anda atau coba lagi.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 13.0,
              color: _colorSecondaryGrey,
            ),
          ),
        ],
      ),
    );
  }

  // ─── EMPTY STATE ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    final isFiltered = _searchQuery.isNotEmpty ||
        _filterDoctor != 'Semua Dokter' ||
        _filterStatus != 'Semua Status';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 24.0),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76.0,
            height: 76.0,
            decoration: const BoxDecoration(
              color: Color(0xFFEBF5FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              size: 40.0,
              color: Color(0xFF72A9F4),
            ),
          ),
          const SizedBox(height: 14.0),
          Text(
            isFiltered
                ? 'Tidak ada riwayat konsultasi yang sesuai.'
                : 'Belum ada riwayat konsultasi.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 15.0,
              color: _colorSecondaryGrey,
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM NAVIGATION BAR (4 MENU) ─────────────────────────────────────────
  Widget _buildBottomNavigationBar() {
    const navItems = [
      _NavItem(icon: Icons.home_rounded, label: 'Beranda'),
      _NavItem(icon: Icons.question_answer_rounded, label: 'Konsultasi'),
      _NavItem(icon: Icons.manage_search_rounded, label: 'Riwayat Konsultasi'),
      _NavItem(icon: Icons.person_rounded, label: 'Profil'),
    ];

    return Container(
      width: double.infinity,
      height: 68.0,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(navItems.length, (i) {
            final isSelected = i == _selectedNavIndex;
            final item = navItems[i];
            return Expanded(
              child: GestureDetector(
                onTap: () => _onBottomNavTap(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: 68.0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        // Lingkaran sorot di belakang ikon
                        Container(
                          width: 36.0,
                          height: 36.0,
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
                            size: 22.0,
                            color: _colorTextBlack,
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
                                fontSize: 11.0,
                                fontWeight: FontWeight.normal,
                                color: _colorTextBlack,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Icon(
                          item.icon,
                          size: 24.0,
                          color: _colorTextBlack,
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
                                fontSize: 11.0,
                                fontWeight: FontWeight.normal,
                                color: _colorTextBlack,
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
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
