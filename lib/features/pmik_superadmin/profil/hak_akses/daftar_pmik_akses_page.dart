import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/staff_auth_service.dart';
import '../../../../models/doctor_permissions.dart';
import '../../../../models/staff_account_model.dart';
import '../profil_superadmin_page.dart';
import '../../beranda/beranda_superadmin_page.dart';
import '../../konsultasi/konsultasi_superadmin_page.dart';
import '../../riwayat_konsultasi/daftar_riwayat_konsultasi_admin_page.dart';
import 'edit_pmik_akses_page.dart';
import 'hapus_pmik_akses_page.dart';
import 'tambah_pmik_akses_page.dart';

/// Halaman Daftar PMIK untuk Superadmin PediaGrow.
///
/// Fitur Utama Sesuai Desain Referensi:
/// 1. Header 56dp di atas layar:
///    - Tombol Back (12dp dari sisi kiri) dengan transisi animasi halus
///    - Judul "Daftar PMIK" (font Lato 20sp, bold/semi-bold, #000000)
///    - Tombol (+) di pojok kanan untuk navigasi ke Tambah PMIK
/// 2. Search Bar dinamis:
///    - Sudut rounded, background abu-abu muda, ikon pencarian, hint "Cari PMIK"
///    - Keyboard bawaan HP, filtering dinamis nama/email PMIK
/// 3. List Kartu PMIK:
///    - Foto/avatar PMIK
///    - Nama PMIK & Label "PMIK"
///    - Tombol Hapus (sampah merah) & Tombol Edit (pensil biru) di kanan bawah kartu
///    - Dialog konfirmasi Hapus Data sesuai gambar referensi
/// 4. Scaffold.bottomNavigationBar permanen 4 menu:
///    - Beranda, Konsultasi, Riwayat Konsultasi, Profil
///    - Visual state aktif jelas pada Profil
class DaftarPmikAksesPage extends StatefulWidget {
  const DaftarPmikAksesPage({super.key});

  @override
  State<DaftarPmikAksesPage> createState() => _DaftarPmikAksesPageState();
}

class _DaftarPmikAksesPageState extends State<DaftarPmikAksesPage> {
  final StaffAuthService _staffAuthService = StaffAuthService();

  final TextEditingController _searchCtrl = TextEditingController();
  final List<StaffAccount> _pmikList = [];
  bool _isLoading = false;
  String _searchQuery = '';

  final int _selectedNavIndex = 3; // Menu Profil aktif

  @override
  void initState() {
    super.initState();
    _loadPmikAccounts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPmikAccounts() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final accounts = await _staffAuthService.getAllStaffAccounts();
      final pmiks = accounts.where((a) => a.role == StaffRole.admin).toList();

      // Jika di Firestore belum ada akun PMIK sama sekali, sediakan mock / seed
      // yang persis dengan 4 nama di gambar referensi pengguna
      if (pmiks.isEmpty) {
        final currentEmail = _staffAuthService.currentStaff?.email ??
            StaffAuthService.defaultSuperadminEmail;
        await _seedDefaultPmik(currentEmail);
        final seeded = await _staffAuthService.getAllStaffAccounts();
        pmiks.addAll(seeded.where((a) => a.role == StaffRole.admin));
      }

      if (mounted) {
        setState(() {
          _pmikList
            ..clear()
            ..addAll(pmiks);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Menanamkan 4 data PMIK dari gambar referensi jika database masih kosong
  Future<void> _seedDefaultPmik(String createdBy) async {
    final mockData = [
      {
        'name': 'Anita Setyowati, S.Tr.RMIK',
        'email': 'anita.pmik@pediagrow.com',
        'experience': '7 tahun',
        'str': '3511201402012222',
        'birthDate': '16/07/2006',
        'education': 'DIV - Manajemen Informasi Kesehatan',
        'hak_akses': true,
      },
      {
        'name': 'Zaskia Putri R. P, S.Tr. RMIK',
        'email': 'zaskia.pmik@pediagrow.com',
        'experience': '5 tahun',
        'str': '3511201402013333',
        'birthDate': '20/05/1998',
        'education': 'DIV - Manajemen Informasi Kesehatan',
        'hak_akses': false,
      },
      {
        'name': 'Reny Diah Pujastuti, S.Tr. RMIK',
        'email': 'reny.pmik@pediagrow.com',
        'experience': '6 tahun',
        'str': '3511201402014444',
        'birthDate': '12/11/1997',
        'education': 'DIV - Manajemen Informasi Kesehatan',
        'hak_akses': false,
      },
      {
        'name': 'Nastiti Dwi Lestari, S.Tr. RMIK',
        'email': 'nastiti.pmik@pediagrow.com',
        'experience': '4 tahun',
        'str': '3511201402015555',
        'birthDate': '04/08/1999',
        'education': 'DIV - Manajemen Informasi Kesehatan',
        'hak_akses': false,
      },
    ];

    for (final item in mockData) {
      final perms = Map<String, bool>.from(DoctorPermissions.defaultPermissions);
      perms['hak_akses'] = item['hak_akses'] as bool;
      perms['download_dataset_rekapitulasi'] = true;
      perms['daftar_resep_mpasi'] = true;
      perms['daftar_artikel_kesehatan'] = true;
      perms['download_dataset_pengguna'] = true;
      perms['permainan'] = true;
      perms['edit_resume_medis'] = false;
      perms['ruang_obrolan'] = false;
      perms['konfirmasi_konsultasi'] = false;

      await _staffAuthService.createStaffAccount(
        name: item['name'] as String,
        email: item['email'] as String,
        password: 'PmikPassword123!',
        role: StaffRole.admin,
        createdByEmail: createdBy,
        permissions: perms,
        experience: item['experience'] as String,
        strNumber: item['str'] as String,
        birthDate: item['birthDate'] as String,
        education: item['education'] as String,
      );
    }
  }

  void _navigateToTambah() async {
    final currentEmail = _staffAuthService.currentStaff?.email ??
        StaffAuthService.defaultSuperadminEmail;

    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) =>
            TambahPmikAksesPage(createdByEmail: currentEmail),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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

    if (result == true || result != null) {
      await _loadPmikAccounts();
    }
  }

  void _navigateToEdit(StaffAccount pmik) async {
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) =>
            EditPmikAksesPage(staffAccount: pmik),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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

    if (result == true || result != null) {
      await _loadPmikAccounts();
    }
  }

  void _showDeleteDialog(StaffAccount pmik) {
    HapusPmikAksesPage.show(
      context,
      pmik: pmik,
      onDeleted: () {
        _loadPmikAccounts();
      },
    );
  }

  void _handleBottomNavTap(int index) {
    if (index == _selectedNavIndex) return;

    Widget targetPage;
    switch (index) {
      case 0:
        targetPage = const BerandaSuperadminPage();
        break;
      case 1:
        targetPage = const KonsultasiSuperadminPage();
        break;
      case 2:
        targetPage = const DaftarRiwayatKonsultasiAdminPage();
        break;
      case 3:
      default:
        targetPage = const ProfilSuperadminPage();
        break;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetPage,
        transitionsBuilder: (context, a, secondaryAnimation, c) =>
            FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
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
            // SEARCH BAR (Cari PMIK)
            _buildSearchBar(),

            // DAFTAR KARTU PMIK
            Expanded(
              child: _isLoading && _pmikList.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF3985E7),
                      ),
                    )
                  : Builder(
                      builder: (context) {
                        final filtered = _pmikList.where((pmik) {
                          if (_searchQuery.isEmpty) return true;
                          final q = _searchQuery.toLowerCase();
                          final matchName = pmik.name.toLowerCase().contains(q);
                          final matchEmail = pmik.email.toLowerCase().contains(q);
                          final matchEdu =
                              pmik.education?.toLowerCase().contains(q) ?? false;
                          return matchName || matchEmail || matchEdu;
                        }).toList();

                        if (filtered.isEmpty) {
                          return _buildEmptyState();
                        }

                        return RefreshIndicator(
                          color: const Color(0xFF3985E7),
                          onRefresh: _loadPmikAccounts,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 10.0,
                            ),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 14.0),
                            itemBuilder: (context, index) {
                              final pmik = filtered[index];
                              return _buildPmikCard(pmik);
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
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              const ProfilSuperadminPage(),
                          transitionsBuilder: (context, a, secondaryAnimation, c) =>
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

                // Judul "Daftar PMIK"
                Expanded(
                  child: Text(
                    'Daftar PMIK',
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

                // Tombol (+) Tambah PMIK di kanan atas
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
  // SEARCH BAR (Cari PMIK)
  // ---------------------------------------------------------------------------
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
            fontSize: 14.5,
            color: const Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            hintText: 'Cari PMIK',
            hintStyle: GoogleFonts.lato(
              fontSize: 14.5,
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
                      _searchCtrl.clear();
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
  // KARTU PMIK (Sesuai Desain Referensi)
  // ---------------------------------------------------------------------------
  Widget _buildPmikCard(StaffAccount pmik) {
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
          // Bagian Atas: Avatar + Nama + Label PMIK
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
                    child: _buildPmikAvatar(pmik),
                  ),
                ),
                const SizedBox(width: 14.0),

                // Nama & Label PMIK
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pmik.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'PMIK',
                        style: GoogleFonts.lato(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Garis Pemisah Tipis
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
                // Tombol Hapus (Merah Muda)
                GestureDetector(
                  onTap: () => _showDeleteDialog(pmik),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 34.0,
                    height: 34.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2), // Merah muda lembut
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: const Color(0xFFFECACA),
                        width: 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18.0,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),

                // Tombol Edit (Biru Muda)
                GestureDetector(
                  onTap: () => _navigateToEdit(pmik),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 34.0,
                    height: 34.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE), // Biru muda lembut
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: const Color(0xFFBAE6FD),
                        width: 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 18.0,
                      color: Color(0xFF0284C7),
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

  Widget _buildPmikAvatar(StaffAccount pmik) {
    final avatar = pmik.avatarPath;
    if (avatar != null && avatar.isNotEmpty) {
      if (File(avatar).existsSync()) {
        return Image.file(
          File(avatar),
          fit: BoxFit.cover,
          width: 58.0,
          height: 58.0,
        );
      }
      if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
        return Image.network(
          avatar,
          fit: BoxFit.cover,
          width: 58.0,
          height: 58.0,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackAvatarIcon(),
        );
      }
      if (avatar.startsWith('assets/')) {
        return Image.asset(
          avatar,
          fit: BoxFit.cover,
          width: 58.0,
          height: 58.0,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackAvatarIcon(),
        );
      }
    }
    return _buildFallbackAvatarIcon();
  }

  Widget _buildFallbackAvatarIcon() {
    return Container(
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person,
        size: 36.0,
        color: Color(0xFF94A3B8),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY STATE
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76.0,
                height: 76.0,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_search_rounded,
                  size: 40.0,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                _searchQuery.isNotEmpty
                    ? 'PMIK Tidak Ditemukan'
                    : 'Belum Ada Data PMIK',
                style: GoogleFonts.lato(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Tidak ada akun PMIK yang cocok dengan "$_searchQuery".'
                    : 'Tekan tombol (+) di atas untuk menambahkan akun PMIK baru.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 13.5,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM NAVIGATION BAR (Permanen Scaffold 4 Menu)
  // ---------------------------------------------------------------------------
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 68.0,
      decoration: const BoxDecoration(
        color: Color(0xFFF2EDED),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8.0,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.home_rounded,
            label: 'Beranda',
            isActive: _selectedNavIndex == 0,
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Konsultasi',
            isActive: _selectedNavIndex == 1,
          ),
          _buildNavItem(
            index: 2,
            icon: Icons.history_rounded,
            label: 'Riwayat Konsultasi',
            isActive: _selectedNavIndex == 2,
          ),
          _buildNavItem(
            index: 3,
            icon: Icons.person_rounded,
            label: 'Profil',
            isActive: _selectedNavIndex == 3,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => _handleBottomNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 76.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24.0,
                color: isActive ? const Color(0xFF72A9F4) : const Color(0xFF4A4A4A),
              ),
            ),
            const SizedBox(height: 2.0),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? const Color(0xFF72A9F4) : const Color(0xFF4A4A4A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
