import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/doctor_service.dart';
import '../../../../core/services/staff_auth_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../models/doctor_model.dart';
import '../../../../models/staff_account_model.dart';
import '../profil_superadmin_page.dart';
import '../../beranda/beranda_superadmin_page.dart';
import '../../konsultasi/konsultasi_superadmin_page.dart';
import '../../riwayat_konsultasi/daftar_riwayat_konsultasi_admin_page.dart';
import 'edit_dokter_akses_page.dart';
import 'hapus_dokter_akses_page.dart';
import 'tambah_dokter_akses_page.dart';
import '../../../dokter/jadwal/atur_jadwal_dokter_page.dart';

/// Halaman Daftar Dokter untuk Superadmin PediaGrow.
///
/// Fitur Utama Sesuai Desain Referensi:
/// 1. Header 56dp di atas layar:
///    - Tombol Back (12dp dari sisi kiri) dengan transisi animasi halus
///    - Judul "Daftar Dokter" (font Lato 20sp, bold/semi-bold, #000000)
///    - Tombol (+) di pojok kanan untuk navigasi ke Tambah Dokter
/// 2. Search Bar dinamis:
///    - Sudut rounded, background abu-abu muda, ikon pencarian, hint "Cari Dokter"
///    - Keyboard bawaan HP, filtering dinamis nama/spesialis dokter
/// 3. List Kartu Dokter:
///    - Foto/avatar dokter
///    - Nama dokter & Spesialisasi
///    - Tombol Hapus (sampah merah) & Tombol Edit (pensil biru) di kanan bawah kartu
///    - Dialog konfirmasi Hapus Data sesuai gambar referensi
/// 4. Scaffold.bottomNavigationBar permanen 4 menu:
///    - Beranda, Konsultasi, Riwayat Konsultasi, Profil
///    - Visual state aktif jelas pada Profil
class DaftarDokterAksesPage extends StatefulWidget {
  const DaftarDokterAksesPage({super.key});

  @override
  State<DaftarDokterAksesPage> createState() => _DaftarDokterAksesPageState();
}

class _DaftarDokterAksesPageState extends State<DaftarDokterAksesPage> {
  final DoctorService _doctorService = DoctorService();
  final StaffAuthService _staffAuthService = StaffAuthService();

  final TextEditingController _searchCtrl = TextEditingController();
  final Map<String, StaffAccount> _staffCache = {};
  bool _isLoadingStaff = false;
  String _searchQuery = '';

  final int _selectedNavIndex = 3; // Menu Profil aktif

  @override
  void initState() {
    super.initState();
    _doctorService.doctorsNotifier;
    _loadStaffAccounts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStaffAccounts() async {
    if (_isLoadingStaff) return;
    setState(() => _isLoadingStaff = true);
    try {
      final accounts = await _staffAuthService.getAllStaffAccounts();
      final map = <String, StaffAccount>{};
      for (final a in accounts) {
        if (a.role == StaffRole.dokter) {
          map[a.id] = a;
        }
      }
      if (mounted) {
        setState(() {
          _staffCache
            ..clear()
            ..addAll(map);
          _isLoadingStaff = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingStaff = false);
    }
  }

  void _navigateToTambah() async {
    final currentEmail =
        _staffAuthService.currentStaff?.email ?? StaffAuthService.defaultSuperadminEmail;

    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) =>
            TambahDokterAksesPage(createdByEmail: currentEmail),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );

    await _loadStaffAccounts();
  }

  void _navigateToEdit(DoctorModel doctor) async {
    final staff = _staffCache[doctor.staffAccountId];

    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) =>
            EditDokterAksesPage(doctor: doctor, staffAccount: staff),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );

    await _loadStaffAccounts();
  }

  void _confirmDelete(DoctorModel doctor) {
    HapusDokterAksesPage.show(
      context,
      doctor: doctor,
      onDeleted: () {
        _loadStaffAccounts();
      },
    );
  }

  void _onBottomNavTap(int index) {
    if (index == _selectedNavIndex) return;

    final Widget destination = switch (index) {
      0 => const BerandaSuperadminPage(),
      1 => const KonsultasiSuperadminPage(),
      2 => const DaftarRiwayatKonsultasiAdminPage(),
      _ => const ProfilSuperadminPage(),
    };

    final route = PageRouteBuilder(
      pageBuilder: (_, _, _) => destination,
      transitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (_, animation, _, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );

    if (index == 0) {
      Navigator.of(context).pushAndRemoveUntil(route, (route) => false);
    } else {
      Navigator.of(context).pushReplacement(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0B1014) : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: _buildHeader(context, isDark),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // SEARCH BAR (Cari Dokter)
            _buildSearchBar(isDark),

            // DAFTAR KARTU DOKTER
            Expanded(
              child: ValueListenableBuilder<List<DoctorModel>>(
                valueListenable: _doctorService.doctorsNotifier,
                builder: (context, allDoctors, _) {
                  if (_isLoadingStaff && allDoctors.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF3985E7),
                      ),
                    );
                  }

                  // Filter pencarian dinamis
                  final filteredDoctors = allDoctors.where((doc) {
                    if (_searchQuery.isEmpty) return true;
                    final q = _searchQuery.toLowerCase();
                    final matchName = doc.name.toLowerCase().contains(q);
                    final matchSpec =
                        doc.specialization.toLowerCase().contains(q);
                    final matchPlaces = doc.placesOfPractice
                        .any((p) => p.toLowerCase().contains(q));
                    return matchName || matchSpec || matchPlaces;
                  }).toList();

                  if (filteredDoctors.isEmpty) {
                    return _buildEmptyState(isDark);
                  }

                  return RefreshIndicator(
                    color: const Color(0xFF3985E7),
                    onRefresh: _loadStaffAccounts,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 10.0,
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredDoctors.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 14.0),
                      itemBuilder: (context, index) {
                        final doctor = filteredDoctors[index];
                        final staff = _staffCache[doctor.staffAccountId];
                        return _buildDokterCard(doctor, staff, isDark);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(isDark),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER 56DP
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context, bool isDark) {
    final headerBg = isDark ? const Color(0xFF0B1014) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000);

    return Container(
      width: double.infinity,
      color: headerBg,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56.0,
          child: Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Tombol Back di 12dp dari kiri
                GestureDetector(
                  onTap: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder: (_, _, _) =>
                              const ProfilSuperadminPage(),
                          transitionsBuilder: (_, a, _, c) =>
                              FadeTransition(opacity: a, child: c),
                        ),
                      );
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 36.0,
                    height: 36.0,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.arrow_back,
                      size: 24.0,
                      color: textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),

                // Judul "Daftar Dokter"
                Expanded(
                  child: Text(
                    'Daftar Dokter',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),

                // Tombol (+) Tambah Dokter di kanan atas
                GestureDetector(
                  onTap: _navigateToTambah,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 36.0,
                    height: 36.0,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 28.0,
                      color: Color(0xFF3985E7),
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

  // ---------------------------------------------------------------------------
  // SEARCH BAR
  // ---------------------------------------------------------------------------
  Widget _buildSearchBar(bool isDark) {
    final searchBg = isDark ? const Color(0xFF1A2228) : const Color(0xFFE9EDEF);
    final searchBorder = isDark ? const Color(0xFF2C363D) : Colors.transparent;
    final textColor = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: Container(
        height: 46.0,
        decoration: BoxDecoration(
          color: searchBg,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: searchBorder),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (val) {
            setState(() {
              _searchQuery = val.trim();
            });
          },
          style: GoogleFonts.lato(
            fontSize: 14.0,
            color: textColor,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Cari Dokter',
            hintStyle: GoogleFonts.lato(
              fontSize: 14.0,
              color: const Color(0xFF8696A0),
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF8696A0),
              size: 22.0,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF8696A0),
                      size: 20.0,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 12.0,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // KARTU DOKTER
  // ---------------------------------------------------------------------------
  Widget _buildDokterCard(DoctorModel doctor, StaffAccount? staff, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1A2228) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF);
    final nameColor = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000);
    final specColor = isDark ? const Color(0xFF8696A0) : const Color(0xFF667781);
    final dividerColor = isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0x0A000000),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bagian Atas: Avatar + Nama + Spesialisasi
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar Bulat
                Container(
                  width: 58.0,
                  height: 58.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: borderColor,
                      width: 1.2,
                    ),
                    color: isDark ? const Color(0xFF242E35) : const Color(0xFFF8FAFC),
                  ),
                  child: ClipOval(
                    child: _buildDoctorAvatar(doctor, isDark),
                  ),
                ),
                const SizedBox(width: 14.0),

                // Nama & Spesialisasi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: nameColor,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        doctor.specialization.isNotEmpty
                            ? doctor.specialization
                            : 'Spesialis Anak',
                        style: GoogleFonts.lato(
                          fontSize: 13.0,
                          color: specColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Garis Pemisah
          Divider(
            height: 1.0,
            thickness: 0.8,
            color: dividerColor,
          ),

          // Bagian Bawah: Aksi Hapus (Sampah) & Edit (Pensil)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                // Tombol Kelola Jadwal Praktik (Biru Medis #0284C7)
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AturJadwalDokterPage(
                          dokterId: doctor.id,
                          doctorName: doctor.name,
                          isSuperadmin: true,
                        ),
                      ),
                    );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 36.0,
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0284C7).withValues(alpha: 0.15)
                          : const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF0284C7).withValues(alpha: 0.3)
                            : const Color(0xFFBAE6FD),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 16.0,
                          color: Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 5.0),
                        Text(
                          'Jadwal Praktik',
                          style: GoogleFonts.lato(
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0284C7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Tombol Hapus (Merah)
                GestureDetector(
                  onTap: () => _confirmDelete(doctor),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 36.0,
                    height: 36.0,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                            : const Color(0xFFFECACA),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 20.0,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),

                // Tombol Edit (Biru)
                GestureDetector(
                  onTap: () => _navigateToEdit(doctor),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 36.0,
                    height: 36.0,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF3985E7).withValues(alpha: 0.15)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF3985E7).withValues(alpha: 0.3)
                            : const Color(0xFFBFDBFE),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 20.0,
                      color: Color(0xFF3985E7),
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

  Widget _buildDoctorAvatar(DoctorModel doctor, bool isDark) {
    final avatar = doctor.avatarUrl ?? doctor.assetImagePath;
    return StorageService.buildImageWidget(
      avatar,
      fit: BoxFit.cover,
      width: 58.0,
      height: 58.0,
      errorWidget: _buildAvatarFallback(isDark),
    );
  }

  Widget _buildAvatarFallback(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF242E35) : const Color(0xFFEFF6FF),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_rounded,
        size: 34.0,
        color: Color(0xFF3985E7),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final titleColor = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014);
    final subtitleColor = isDark ? const Color(0xFF8696A0) : const Color(0xFF667781);
    final circleBg = isDark ? const Color(0xFF1A2228) : const Color(0xFFEFF6FF);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72.0,
              height: 72.0,
              decoration: BoxDecoration(
                color: circleBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medical_services_outlined,
                size: 36.0,
                color: Color(0xFF3985E7),
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Dokter tidak ditemukan'
                  : 'Belum ada data dokter',
              style: GoogleFonts.lato(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Coba gunakan kata kunci pencarian yang lain.'
                  : 'Klik tombol (+) di pojok kanan atas untuk menambahkan dokter baru.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 13.0,
                color: subtitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM NAVIGATION BAR
  // ---------------------------------------------------------------------------
  Widget _buildBottomNavigationBar(bool isDark) {
    final navItems = [
      const _BottomNavItemData(icon: Icons.home_rounded, label: 'Beranda'),
      const _BottomNavItemData(
        icon: Icons.question_answer_rounded,
        label: 'Konsultasi',
      ),
      const _BottomNavItemData(
        icon: Icons.manage_search_rounded,
        label: 'Riwayat Konsultasi',
      ),
      const _BottomNavItemData(
        icon: Icons.person_rounded,
        label: 'Profil',
      ),
    ];

    final barBg = isDark ? const Color(0xFF1A2228) : const Color(0xFFF2EDED);
    final activeCircleBg = isDark ? const Color(0xFF2C363D) : Colors.white;
    final activeTextColor = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228);
    final inactiveColor = isDark ? const Color(0xFF8696A0) : const Color(0xFF9E9E9E);

    return Container(
      width: double.infinity,
      height: 68.0,
      decoration: BoxDecoration(
        color: barBg,
        boxShadow: const [
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
                          decoration: BoxDecoration(
                            color: activeCircleBg,
                            shape: BoxShape.circle,
                            boxShadow: const [
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
                                color: activeTextColor,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Icon(
                          item.icon,
                          size: 24.0,
                          color: inactiveColor,
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
                                color: inactiveColor,
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

class _BottomNavItemData {
  final IconData icon;
  final String label;

  const _BottomNavItemData({
    required this.icon,
    required this.label,
  });
}
