import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../beranda/beranda_superadmin_page.dart';
import '../riwayat_konsultasi/daftar_riwayat_konsultasi_admin_page.dart';
import '../profil/profil_superadmin_page.dart';

// ─── Palette ─────────────────────────────────────────────────────────────────
const Color _colorNavBg = Color(0xFFF2EDED);
const Color _colorPrimaryBlue = Color(0xFF4A90D9);
const Color _colorTextBlack = Color(0xFF1E293B);
const Color _colorLabelGrey = Color(0xFF64748B);
const Color _colorCardBg = Color(0xFFFFFFFF);

/// Model ringan untuk menampilkan data konsultasi di halaman superadmin.
class _KonsultasiItem {
  final String id;
  final String childName;
  final String childAge;
  final String childGender; // 'male' | 'female'
  final String doctorName;
  final String status; // 'berlangsung' | 'menunggu_konfirmasi'
  final bool awaitsPayment; // hanya berlaku untuk tab berlangsung

  const _KonsultasiItem({
    required this.id,
    required this.childName,
    required this.childAge,
    required this.childGender,
    required this.doctorName,
    required this.status,
    this.awaitsPayment = false,
  });
}

// ─── Mock data (mirip screenshot desain) ─────────────────────────────────────
final List<_KonsultasiItem> _mockBerlangsung = [
  const _KonsultasiItem(
    id: 'k1',
    childName: 'Devaro Ramadhan',
    childAge: '1 tahun 2 bulan 13 hari',
    childGender: 'male',
    doctorName: 'dr. Ahmad Nuri, Sp. A',
    status: 'berlangsung',
  ),
  const _KonsultasiItem(
    id: 'k2',
    childName: 'Arfa Zivano Kayfan',
    childAge: '0 tahun 4 bulan 23 hari',
    childGender: 'male',
    doctorName: 'dr. Ririn Esterina, Sp.A',
    status: 'berlangsung',
  ),
  const _KonsultasiItem(
    id: 'k3',
    childName: 'Naya Seiza Putri',
    childAge: '0 tahun 8 bulan 20 hari',
    childGender: 'female',
    doctorName: 'dr. Ririn Esterina, Sp.A',
    status: 'berlangsung',
    awaitsPayment: true,
  ),
  const _KonsultasiItem(
    id: 'k4',
    childName: 'Zafran Aditya',
    childAge: '0 tahun 9 bulan 26 hari',
    childGender: 'male',
    doctorName: 'dr. B. Gebyar Tri Baskoro, Sp.A',
    status: 'berlangsung',
  ),
  const _KonsultasiItem(
    id: 'k5',
    childName: 'Aisha Arunika Zahra',
    childAge: '0 tahun 5 bulan 0 hari',
    childGender: 'female',
    doctorName: 'dr. Ririn Esterina, Sp.A',
    status: 'berlangsung',
  ),
];

final List<_KonsultasiItem> _mockMenunggu = [
  const _KonsultasiItem(
    id: 'm1',
    childName: 'Amara Adiratna',
    childAge: '1 tahun 2 bulan 10 hari',
    childGender: 'female',
    doctorName: 'dr. M. Ali Shodikin, Sp.A, M.Kes',
    status: 'menunggu_konfirmasi',
  ),
  const _KonsultasiItem(
    id: 'm2',
    childName: 'Kaia Anastasya',
    childAge: '1 tahun 3 bulan 3 hari',
    childGender: 'female',
    doctorName: 'dr. Ririn Esterina, Sp.A',
    status: 'menunggu_konfirmasi',
  ),
  const _KonsultasiItem(
    id: 'm3',
    childName: 'Zafran Aditya',
    childAge: '0 tahun 9 bulan 26 hari',
    childGender: 'male',
    doctorName: 'dr. B. Gebyar Tri Baskoro, Sp.A',
    status: 'menunggu_konfirmasi',
  ),
  const _KonsultasiItem(
    id: 'm4',
    childName: 'Arlo Gavindra',
    childAge: '0 tahun 11 bulan 21 hari',
    childGender: 'male',
    doctorName: 'dr. Devina Marchita I. S., Sp.A',
    status: 'menunggu_konfirmasi',
  ),
  const _KonsultasiItem(
    id: 'm5',
    childName: 'Amara Adiratna',
    childAge: '1 tahun 10 bulan 09 hari',
    childGender: 'female',
    doctorName: 'dr. B. Gebyar Tri Baskoro, Sp.A',
    status: 'menunggu_konfirmasi',
  ),
  const _KonsultasiItem(
    id: 'm6',
    childName: 'Zalvian Sadewa',
    childAge: '0 tahun 9 bulan 26 hari',
    childGender: 'male',
    doctorName: 'dr. Ahmad Nuri, Sp. A',
    status: 'menunggu_konfirmasi',
  ),
  const _KonsultasiItem(
    id: 'm7',
    childName: 'Mahesa Putra',
    childAge: '1 tahun 1 bulan 16 hari',
    childGender: 'male',
    doctorName: 'dr. Ririn Esterina, Sp.A',
    status: 'menunggu_konfirmasi',
  ),
];

// ─── Page ─────────────────────────────────────────────────────────────────────

/// Halaman Konsultasi untuk Superadmin.
///
/// Menampilkan dua tab:
/// - "Sedang Berlangsung" — daftar konsultasi aktif.
/// - "Menunggu Konfirmasi" — daftar permintaan yang belum dikonfirmasi dokter.
///
/// Superadmin hanya bisa melihat data; tombol Tolak/Terima dan Masuk Ruang
/// Chat tidak aktif bagi superadmin — sesuai ketentuan akses.
class KonsultasiSuperadminPage extends StatefulWidget {
  const KonsultasiSuperadminPage({super.key});

  @override
  State<KonsultasiSuperadminPage> createState() =>
      _KonsultasiSuperadminPageState();
}

class _KonsultasiSuperadminPageState extends State<KonsultasiSuperadminPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Indeks nav bar: 1 = Konsultasi (aktif)
  final int _selectedNavIndex = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Navigation ────────────────────────────────────────────────────────────
  void _onBottomNavTap(int index) {
    if (index == _selectedNavIndex) return;
    Widget targetPage;
    switch (index) {
      case 0:
        targetPage = const BerandaSuperadminPage();
        break;
      case 2:
        targetPage = const DaftarRiwayatKonsultasiAdminPage();
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

  /// Superadmin tidak boleh masuk ruang obrolan — tampilkan sheet terkunci.
  void _showLockedChatSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 36,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ruang Obrolan Terkunci',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _colorTextBlack,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Ruang obrolan konsultasi antara dokter dan orang tua pasien hanya dapat diakses oleh dokter yang menangani. Superadmin tidak memiliki akses ke percakapan ini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 13,
                color: _colorLabelGrey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Tutup',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _colorPrimaryBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: _buildHeader(),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // Tab bar
            _buildTabBar(),
            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBerlangsungTab(),
                  _buildMenungguKonfirmasiTab(),
                ],
              ),
            ),
          ],
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Konsultasi',
                style: GoogleFonts.lato(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: _colorTextBlack,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── TAB BAR ──────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        // Garis biru selebar penuh tiap tab (seperti di halaman detail anak)
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: _colorPrimaryBlue, width: 3),
        ),
        // Garis abu-abu tipis di sepanjang bawah tab bar
        dividerColor: const Color(0xFFE2E8F0),
        dividerHeight: 1,
        labelPadding: EdgeInsets.zero,
        labelStyle: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.lato(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelColor: _colorTextBlack,
        unselectedLabelColor: _colorLabelGrey,
        tabs: const [
          Tab(height: 48, text: 'Sedang Berlangsung'),
          Tab(height: 48, text: 'Menunggu Konfirmasi'),
        ],
      ),
    );
  }

  // ─── TAB 1: SEDANG BERLANGSUNG ────────────────────────────────────────────
  Widget _buildBerlangsungTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  ..._mockBerlangsung.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: _buildBerlangsungCard(item),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Spacer(),
                  _buildFooterIllustration(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBerlangsungCard(_KonsultasiItem item) {
    return Container(
      decoration: BoxDecoration(
        color: _colorCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Baris atas: avatar + nama + usia (+ badge jika ada)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                _buildAvatarBubble(item.childGender, 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.childName,
                              style: GoogleFonts.lato(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _colorTextBlack,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.childAge,
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: _colorLabelGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Divider
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          // Baris bawah: dokter + tombol
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.doctorName,
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: _colorLabelGrey,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _showLockedChatSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _colorPrimaryBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Masuk Ruang Chat',
                      style: GoogleFonts.lato(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 2: MENUNGGU KONFIRMASI ───────────────────────────────────────────
  Widget _buildMenungguKonfirmasiTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Info banner
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildInfoBanner(),
                  ),
                  const SizedBox(height: 10),
                  ..._mockMenunggu.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: _buildMenungguCard(item),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Spacer(),
                  _buildFooterIllustration(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF5FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _colorPrimaryBlue.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 20,
            color: _colorPrimaryBlue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Untuk memastikan keputusan diambil oleh pihak yang bertanggung jawab, '
              'permintaan konsultasi hanya dapat ditolak dan diterima oleh dokter yang menangani.',
              style: GoogleFonts.lato(
                fontSize: 12.5,
                color: _colorPrimaryBlue,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenungguCard(_KonsultasiItem item) {
    return Container(
      decoration: BoxDecoration(
        color: _colorCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Baris atas: avatar + nama + usia + badge
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                _buildAvatarBubble(item.childGender, 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.childName,
                              style: GoogleFonts.lato(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _colorTextBlack,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFFDE68A),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Menunggu Dokter',
                              style: GoogleFonts.lato(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.childAge,
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: _colorLabelGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Divider
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          // Baris bawah: dokter + tombol Tolak/Terima (disabled utk superadmin)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.doctorName,
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: _colorLabelGrey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildDisabledActionButton('Tolak'),
                const SizedBox(width: 8),
                _buildDisabledActionButton('Terima'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledActionButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.lato(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  // ─── AVATAR BUBBLE ────────────────────────────────────────────────────────
  Widget _buildAvatarBubble(String gender, double size) {
    final isMale = gender == 'male';
    final bgColor = isMale ? const Color(0xFFDBEAFE) : const Color(0xFFFFE4E6);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: CustomPaint(painter: _BabyFacePainter(isGirl: !isMale)),
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

  // ─── BOTTOM NAVIGATION BAR ────────────────────────────────────────────────
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

// ─── Helper types ─────────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

/// Painter wajah bayi lucu — sama dengan painter di riwayat konsultasi.
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
    smilePath.quadraticBezierTo(
      cx,
      cy + r * 0.62,
      cx + r * 0.35,
      cy + r * 0.18,
    );
    canvas.drawPath(smilePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
