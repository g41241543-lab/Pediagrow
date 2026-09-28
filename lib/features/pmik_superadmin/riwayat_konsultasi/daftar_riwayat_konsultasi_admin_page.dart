import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/doctor_service.dart';
import '../../../models/doctor_model.dart';
import '../../../models/riwayat_konsultasi_model.dart';
import '../beranda/beranda_superadmin_page.dart';
import '../konsultasi/konsultasi_superadmin_page.dart';
import '../profil/profil_superadmin_page.dart';
import 'detail_riwayat_konsultasi_admin_page.dart';

/// Halaman Daftar Riwayat Konsultasi untuk PMIK Superadmin.
///
/// Dibuat semirip mungkin dengan desain referensi resmi PediaGrow:
/// - Header 56dp dengan tombol kembali 12dp dari kiri dan judul 12dp dari tombol.
/// - Filter dropdown (Semua Dokter & Semua Status) di atas search bar.
/// - Search bar rounded "Cari nama pasien atau dokter....".
/// - Kartu riwayat konsultasi dengan avatar bayi berwarna (pink/biru) sesuai gender,
///   nama anak, status badge (Selesai/Dijadwalkan), nama dokter, tanggal, dan chevron.
/// - Banner informasi biru di bagian bawah list.
/// - Ilustrasi hutan di bagian paling bawah konten yang dapat di-scroll.
/// - Superadmin Bottom Navigation Bar dengan tab Riwayat Konsultasi (Index 2) aktif.
class DaftarRiwayatKonsultasiAdminPage extends StatefulWidget {
  const DaftarRiwayatKonsultasiAdminPage({super.key});

  @override
  State<DaftarRiwayatKonsultasiAdminPage> createState() =>
      _DaftarRiwayatKonsultasiAdminPageState();
}

class _DaftarRiwayatKonsultasiAdminPageState
    extends State<DaftarRiwayatKonsultasiAdminPage> {
  static const Color _colorPrimaryBlue = Color(0xFF3985E7);
  static const Color _colorNavBg = Color(0xFFF2EDED);
  static const int _selectedNavIndex = 2;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterDoctor = 'Semua Dokter';
  String _filterStatus = 'Semua Status';
  List<DoctorModel> _doctorList = [];

  final List<RiwayatKonsultasiModel> _allRiwayat =
      RiwayatKonsultasiModel.mockMultiList;

  static const List<String> _statusOptions = [
    'Semua Status',
    'Selesai',
    'Dijadwalkan',
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

  List<RiwayatKonsultasiModel> get _filteredRiwayat {
    return _allRiwayat.where((r) {
      if (_filterDoctor != 'Semua Dokter' && r.doctorName != _filterDoctor) {
        return false;
      }
      if (_filterStatus != 'Semua Status' && r.status != _filterStatus) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!r.childName.toLowerCase().contains(q) &&
            !r.doctorName.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _navigateToDetail(RiwayatKonsultasiModel riwayat) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DetailRiwayatKonsultasiAdminPage(riwayat: riwayat),
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

  void _onBottomNavTap(int index) {
    if (index == _selectedNavIndex) return;
    Widget targetPage;
    switch (index) {
      case 0:
        targetPage = const BerandaSuperadminPage();
        break;
      case 1:
        targetPage = const KonsultasiSuperadminPage();
        break;
      case 3:
        targetPage = const ProfilSuperadminPage();
        break;
      default:
        return;
    }
    final isLeft = index < _selectedNavIndex;
    final beginOffset = Offset(isLeft ? -0.25 : 0.25, 0.0);
    final route = PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => targetPage,
      transitionsBuilder: (_, animation, __, child) {
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRiwayat;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: _buildHeader(),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12.0),
                      // 1. Filter Dropdown Row (Semua Dokter & Semua Status)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildFilterRow(),
                      ),
                      const SizedBox(height: 12.0),
                      // 2. Search Bar Real-Time
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildSearchBar(),
                      ),
                      const SizedBox(height: 16.0),
                      // 3. Daftar Kartu Riwayat Konsultasi
                      if (filtered.isEmpty)
                        _buildEmptyState()
                      else
                        _buildRiwayatList(filtered),
                      const SizedBox(height: 14.0),
                      // 4. Banner Info
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildInfoBanner(),
                      ),
                      const SizedBox(height: 24.0),
                      const Spacer(),
                      // 5. Ilustrasi Lanskap Hutan di Bawah Konten Scroll
                      _buildFooterIllustration(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56.0,
          child: Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const BerandaSuperadminPage(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 36.0,
                    height: 36.0,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_back,
                      size: 24.0,
                      color: Color(0xFF000000),
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
                      color: const Color(0xFF000000),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── SEARCH BAR ───────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      height: 44.0,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.0),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
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
            color: const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 22.0,
            color: Color(0xFF94A3B8),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Icon(
                    Icons.close,
                    size: 18.0,
                    color: Color(0xFF94A3B8),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
        ),
      ),
    );
  }

  // ─── FILTER ROW ───────────────────────────────────────────────────────────
  Widget _buildFilterRow() {
    final doctorOptions = <String>['Semua Dokter'];
    for (final doc in _doctorList) {
      if (!doctorOptions.contains(doc.name)) doctorOptions.add(doc.name);
    }
    for (final r in _allRiwayat) {
      if (!doctorOptions.contains(r.doctorName)) doctorOptions.add(r.doctorName);
    }
    if (!doctorOptions.contains(_filterDoctor)) _filterDoctor = 'Semua Dokter';

    return Row(
      children: [
        Expanded(
          child: _buildDropdownPill(
            value: _filterDoctor,
            items: doctorOptions,
            onChanged: (val) {
              if (val != null) setState(() => _filterDoctor = val);
            },
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: _buildDropdownPill(
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

  Widget _buildDropdownPill({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 40.0,
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20.0,
            color: Color(0xFF4A4A4A),
          ),
          style: GoogleFonts.lato(
            fontSize: 13.0,
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.w500,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                      fontSize: 13.0,
                      color: item == value
                          ? _colorPrimaryBlue
                          : const Color(0xFF1E293B),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ─── RIWAYAT LIST ─────────────────────────────────────────────────────────
  Widget _buildRiwayatList(List<RiwayatKonsultasiModel> items) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12.0),
      itemBuilder: (context, index) => _buildConsultationCard(items[index]),
    );
  }

  Widget _buildConsultationCard(RiwayatKonsultasiModel r) {
    final isSelesai = r.status.toLowerCase().contains('selesai');
    final isGirl = r.childGender == 'female';

    return GestureDetector(
      onTap: () => _navigateToDetail(r),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 10.0,
              offset: Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar Bayi Cantik & Skalabel
            Container(
              width: 50.0,
              height: 50.0,
              decoration: BoxDecoration(
                color: isGirl
                    ? const Color(0xFFFFD6D9)
                    : const Color(0xFFD0E8FD),
                shape: BoxShape.circle,
              ),
              child: CustomPaint(
                painter: _BabyFacePainter(isGirl: isGirl),
              ),
            ),
            const SizedBox(width: 14.0),
            // Kolom Informasi Pasien, Status, Dokter, & Jadwal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris 1: Nama Anak & Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          r.childName,
                          style: GoogleFonts.lato(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: isSelesai
                              ? const Color(0xFF33CCA6)
                              : const Color(0xFFFFCD38),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          r.status,
                          style: GoogleFonts.lato(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  // Baris 2: Nama Dokter
                  Text(
                    r.doctorName,
                    style: GoogleFonts.lato(
                      fontSize: 13.0,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8.0),
                  // Baris 3: Ikon Kalender & Tanggal
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14.0,
                        color: Color(0xFF1E293B),
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        r.formattedDate,
                        style: GoogleFonts.lato(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            // Ikon Chevron kanan
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

  // ─── EMPTY STATE ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    final isSearch = _searchQuery.isNotEmpty ||
        _filterDoctor != 'Semua Dokter' ||
        _filterStatus != 'Semua Status';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80.0,
            height: 80.0,
            decoration: const BoxDecoration(
              color: Color(0xFFEBF5FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.folder_off_outlined,
              size: 44.0,
              color: Color(0xFF72A9F4),
            ),
          ),
          const SizedBox(height: 14.0),
          Text(
            isSearch
                ? 'Tidak ada riwayat konsultasi yang sesuai.'
                : 'Belum ada riwayat konsultasi.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 15.0,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ─── INFO BANNER ──────────────────────────────────────────────────────────
  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF5FF),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: _colorPrimaryBlue.withOpacity(0.35),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 20.0,
            color: _colorPrimaryBlue,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              'Data menampilkan seluruh konsultasi dari seluruh dokter dan pasien.',
              style: GoogleFonts.lato(
                fontSize: 13.0,
                color: _colorPrimaryBlue,
                height: 1.4,
              ),
            ),
          ),
        ],
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

  // ─── SUPERADMIN BOTTOM NAVIGATION BAR ─────────────────────────────────────
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
                            color: const Color(0xFF72A9F4),
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
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Icon(
                          item.icon,
                          size: 24.0,
                          color: const Color(0xFF9E9E9E),
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
                                color: const Color(0xFF9E9E9E),
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

/// Custom painter untuk menggambar kartun wajah bayi lucu dan presisi
class _BabyFacePainter extends CustomPainter {
  final bool isGirl;
  const _BabyFacePainter({this.isGirl = true});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final strokePaint = Paint()
      ..color = const Color(0xFF222222)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = const Color(0xFF222222)
      ..style = PaintingStyle.fill;

    final blushPaint = Paint()
      ..color = const Color(0xFFFF8FA3).withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final cx = w * 0.5;
    final cy = h * 0.52;
    final r = w * 0.36;

    // Lingkaran kepala
    final headRect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    canvas.drawArc(headRect, 0, 3.14159 * 2, false, strokePaint);

    // Poni rambut
    final hairPath = Path();
    hairPath.moveTo(cx - r * 0.85, cy - r * 0.3);
    hairPath.quadraticBezierTo(cx - r * 0.35, cy - r * 0.9, cx, cy - r * 0.4);
    hairPath.quadraticBezierTo(
      cx + r * 0.35,
      cy - r * 0.9,
      cx + r * 0.85,
      cy - r * 0.3,
    );
    canvas.drawPath(hairPath, strokePaint);

    // Mata
    canvas.drawCircle(
      Offset(cx - r * 0.38, cy - r * 0.05),
      w * 0.045,
      fillPaint,
    );
    canvas.drawCircle(
      Offset(cx + r * 0.38, cy - r * 0.05),
      w * 0.045,
      fillPaint,
    );

    // Pipi kemerahan
    canvas.drawCircle(
      Offset(cx - r * 0.55, cy + r * 0.15),
      w * 0.065,
      blushPaint,
    );
    canvas.drawCircle(
      Offset(cx + r * 0.55, cy + r * 0.15),
      w * 0.065,
      blushPaint,
    );

    // Senyuman
    final smilePath = Path();
    smilePath.moveTo(cx - r * 0.35, cy + r * 0.18);
    smilePath.quadraticBezierTo(cx, cy + r * 0.62, cx + r * 0.35, cy + r * 0.18);
    canvas.drawPath(smilePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
