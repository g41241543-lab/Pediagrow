import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/doctor_service.dart';
import '../../../core/services/staff_auth_service.dart';
import '../../../models/staff_account_model.dart';
import '../../../shared/widgets/child_avatar.dart';
import '../../../shared/widgets/hover_lift.dart';
import '../../../shared/widgets/illustration_forest_footer.dart';
import '../../../shared/widgets/pedia_bottom_nav_bar.dart';
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

  /// Ketika [inShell] true, halaman berjalan di dalam [SuperadminShell]:
  /// - bottomNavigationBar tidak dirender (navbar milik shell).
  /// - _onBottomNavTap tidak melakukan push/replace (shell yang mengelola tab).
  final bool inShell;

  const DaftarRiwayatKonsultasiAdminPage({
    super.key,
    this.filterByDoctorName,
    this.inShell = false,
  });

  @override
  State<DaftarRiwayatKonsultasiAdminPage> createState() =>
      _DaftarRiwayatKonsultasiAdminPageState();
}

class _DaftarRiwayatKonsultasiAdminPageState
    extends State<DaftarRiwayatKonsultasiAdminPage> {
  // ─── Color Palette ─────────────────────────────────────────────────────────
  static const Color _colorSecondaryGrey = Color(0xFF7F7F7F);
  static const Color _colorTextBlack = Color(0xFF1E293B);
  static const Color _colorActiveBlue = Color(0xFF72A9F4);
  static const int _selectedNavIndex = 2; // Riwayat Konsultasi aktif

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late final Stream<List<RiwayatKonsultasiAdminItem>> _streamRiwayat;

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

    _searchController.addListener(() {
      if (_searchQuery != _searchController.text) {
        setState(() => _searchQuery = _searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    // Ketika berjalan di dalam shell, navigasi tab dikelola oleh SuperadminShell.
    if (widget.inShell) return;
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

            return Column(
              children: [
                // ─── HEADER (56dp dari atas layar) ───────────────────────────
                _buildHeader(),

                // ─── KONTEN SCROLLABLE ──────────────────────────────────────────
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: Column(
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

                                      // Search Bar (setelah search langsung daftar card)
                                      _buildSearchBar(),

                                      const SizedBox(height: 12.0),

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

                                      const SizedBox(height: 16.0),
                                    ],
                                  ),
                                ),

                                const Spacer(),

                                _buildFooterIllustration(),
                              ],
                            ),
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
        bottomNavigationBar: widget.inShell ? null : _buildBottomNavigationBar(),
      ),
    );
  }

  // ─── HEADER ─────────────────────────────────────────────────────────────────
  /// Header diletakkan 56dp dari atas layar fisik, tanpa tombol back,
  /// dengan padding kiri 16dp (konsisten antara Pengguna, Admin/Superadmin, dan Dokter).
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.only(top: 56.0, bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
    );
  }


  // ─── SEARCH BAR (IDENTIK DENGAN PENGGUNA) ──────────────────────────────────
  Widget _buildSearchBar({String? hintText}) {
    final hint = hintText ??
        (_isDoctorMode ? 'Cari riwayat konsultasi pasien...' : 'Cari nama pasien atau dokter...');
    return Container(
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
                hintText: hint,
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
              'Seluruh riwayat konsultasi yang selesai akan tercatat di sini.',
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
    return const IllustrationForestFooter(fit: BoxFit.fitWidth);
  }

  // ─── BOTTOM NAVIGATION BAR (IDENTIK DENGAN BERANDA) ─────────────────────────
  Widget _buildBottomNavigationBar() {
    return PediaBottomNavBar(
      selectedIndex: 2,
      onNavTap: _onBottomNavTap,
    );
  }
}
