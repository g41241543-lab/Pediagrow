import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/doctor_service.dart';
import '../../../../core/services/staff_auth_service.dart';
import '../../../../models/doctor_model.dart';
import '../../../../models/staff_account_model.dart';
import '../profil_superadmin_page.dart';
import '../../beranda/beranda_superadmin_page.dart';
import '../../konsultasi/konsultasi_superadmin_page.dart';
import '../../riwayat_konsultasi/daftar_riwayat_konsultasi_admin_page.dart';
import 'edit_dokter_akses_page.dart';
import 'hapus_dokter_akses_page.dart';
import 'tambah_dokter_akses_page.dart';

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
        transitionsBuilder: (_, animation, __, child) {
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
        transitionsBuilder: (_, animation, __, child) {
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
      pageBuilder: (_, __, ___) => destination,
      transitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (_, animation, __, child) {
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: _buildHeader(context),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // SEARCH BAR (Cari Dokter)
            _buildSearchBar(),

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
                    return _buildEmptyState();
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
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 14.0),
                      itemBuilder: (context, index) {
                        final doctor = filteredDoctors[index];
                        final staff = _staffCache[doctor.staffAccountId];
                        return _buildDokterCard(doctor, staff);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER 56DP
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
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
                          pageBuilder: (_, __, ___) =>
                              const ProfilSuperadminPage(),
                          transitionsBuilder: (_, a, __, c) =>
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
                    child: const Icon(
                      Icons.arrow_back,
                      size: 24.0,
                      color: Color(0xFF000000),
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
                      color: const Color(0xFF000000),
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
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: Container(
        height: 46.0,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12.0),
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
            color: const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Cari Dokter',
            hintStyle: GoogleFonts.lato(
              fontSize: 14.0,
              color: const Color(0xFF94A3B8),
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF94A3B8),
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
                      color: Color(0xFF94A3B8),
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
  Widget _buildDokterCard(DoctorModel doctor, StaffAccount? staff) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8.0,
            offset: Offset(0, 2),
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
                      color: const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                    color: const Color(0xFFF8FAFC),
                  ),
                  child: ClipOval(
                    child: _buildDoctorAvatar(doctor),
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
                          color: const Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        doctor.specialization.isNotEmpty
                            ? doctor.specialization
                            : 'Spesialis Anak',
                        style: GoogleFonts.lato(
                          fontSize: 13.0,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Garis Pemisah
          const Divider(
            height: 1.0,
            thickness: 0.8,
            color: Color(0xFFF1F5F9),
          ),

          // Bagian Bawah: Aksi Hapus (Sampah) & Edit (Pensil)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Tombol Hapus (Merah)
                GestureDetector(
                  onTap: () => _confirmDelete(doctor),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 36.0,
                    height: 36.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: const Color(0xFFFECACA)),
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
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
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

  Widget _buildDoctorAvatar(DoctorModel doctor) {
    final avatar = doctor.avatarUrl ?? doctor.assetImagePath;
    if (avatar != null && avatar.isNotEmpty) {
      if (File(avatar).existsSync()) {
        return Image.file(
          File(avatar),
          fit: BoxFit.cover,
          width: 58.0,
          height: 58.0,
        );
      }
      if (avatar.startsWith('http')) {
        return Image.network(
          avatar,
          fit: BoxFit.cover,
          width: 58.0,
          height: 58.0,
          errorBuilder: (_, __, ___) => _buildAvatarFallback(),
        );
      }
      if (avatar.startsWith('assets/')) {
        return Image.asset(
          avatar,
          fit: BoxFit.cover,
          width: 58.0,
          height: 58.0,
          errorBuilder: (_, __, ___) => _buildAvatarFallback(),
        );
      }
    }
    return _buildAvatarFallback();
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: const Color(0xFFEFF6FF),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_rounded,
        size: 34.0,
        color: Color(0xFF3985E7),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72.0,
              height: 72.0,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
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
                color: const Color(0xFF0F172A),
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
                color: const Color(0xFF64748B),
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
  Widget _buildBottomNavigationBar() {
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

    return Container(
      width: double.infinity,
      height: 68.0,
      decoration: const BoxDecoration(
        color: Color(0xFFF2EDED),
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

class _BottomNavItemData {
  final IconData icon;
  final String label;

  const _BottomNavItemData({
    required this.icon,
    required this.label,
  });
}
