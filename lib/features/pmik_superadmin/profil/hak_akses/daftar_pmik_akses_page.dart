import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/staff_auth_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../models/doctor_permissions.dart';
import '../../../../models/staff_account_model.dart';
import '../../../../shared/widgets/pedia_bottom_nav_bar.dart';
import '../profil_superadmin_page.dart';
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
/// 4. Scaffold.bottomNavigationBar permanen 4 menu (tanpa lingkaran aktif)
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
      perms['edit_resep_mpasi'] = true;
      perms['daftar_artikel_kesehatan'] = true;
      perms['edit_artikel_kesehatan'] = true;
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
            // SEARCH BAR (Cari PMIK)
            _buildSearchBar(isDark),

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
                          return _buildEmptyState(isDark);
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
                              return _buildPmikCard(pmik, isDark);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
<<<<<<< HEAD
      bottomNavigationBar: _buildBottomNavigationBar(isDark),
=======
      bottomNavigationBar: const PediaBottomNavBar(selectedIndex: -1),
>>>>>>> 69f9bbd5b3b1a63c0172d779502ab9f5acb8edc8
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
                    child: Icon(
                      Icons.arrow_back,
                      size: 24.0,
                      color: textPrimary,
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
                      color: textPrimary,
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
  Widget _buildSearchBar(bool isDark) {
    final searchBg = isDark ? const Color(0xFF1A2228) : const Color(0xFFE9EDEF);
    final searchBorder = isDark ? const Color(0xFF2C363D) : Colors.transparent;
    final textColor = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
            fontSize: 14.5,
            color: textColor,
          ),
          decoration: InputDecoration(
            hintText: 'Cari PMIK',
            hintStyle: GoogleFonts.lato(
              fontSize: 14.5,
              color: const Color(0xFF8696A0),
            ),
            prefixIcon: const Icon(
              Icons.search,
              size: 22.0,
              color: Color(0xFF8696A0),
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
                      color: Color(0xFF8696A0),
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
  Widget _buildPmikCard(StaffAccount pmik, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1A2228) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF);
    final nameColor = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000);
    final roleColor = isDark ? const Color(0xFF8696A0) : const Color(0xFF667781);
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
                      color: borderColor,
                      width: 1.2,
                    ),
                    color: isDark ? const Color(0xFF242E35) : const Color(0xFFF8FAFC),
                  ),
                  child: ClipOval(
                    child: _buildPmikAvatar(pmik, isDark),
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
                          color: nameColor,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'PMIK',
                        style: GoogleFonts.lato(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w500,
                          color: roleColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Garis Pemisah Tipis
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
                      color: isDark
                          ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                          : const Color(0xFFFEE2E2), // Merah muda lembut
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                            : const Color(0xFFFECACA),
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
                      color: isDark
                          ? const Color(0xFF0284C7).withValues(alpha: 0.15)
                          : const Color(0xFFE0F2FE), // Biru muda lembut
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF0284C7).withValues(alpha: 0.3)
                            : const Color(0xFFBAE6FD),
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

  Widget _buildPmikAvatar(StaffAccount pmik, bool isDark) {
    return StorageService.buildImageWidget(
      pmik.avatarPath,
      fit: BoxFit.cover,
      width: 58.0,
      height: 58.0,
      errorWidget: _buildFallbackAvatarIcon(isDark),
    );
  }

  Widget _buildFallbackAvatarIcon(bool isDark) {
    return Container(
<<<<<<< HEAD
      color: isDark ? const Color(0xFF242E35) : const Color(0xFFE9EDEF),
      alignment: Alignment.center,
      child: Icon(
        Icons.person,
        size: 36.0,
        color: isDark ? const Color(0xFF8696A0) : const Color(0xFF8696A0),
=======
      color: const Color(0xFFECF6FF),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_rounded,
        size: 36.0,
        color: Color(0xFF3985E7),
>>>>>>> 69f9bbd5b3b1a63c0172d779502ab9f5acb8edc8
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY STATE
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState(bool isDark) {
    final titleColor = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228);
    final subtitleColor = isDark ? const Color(0xFF8696A0) : const Color(0xFF667781);
    final circleBg = isDark ? const Color(0xFF1A2228) : const Color(0xFFE9EDEF);

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
<<<<<<< HEAD
                decoration: BoxDecoration(
                  color: circleBg,
=======
                decoration: const BoxDecoration(
                  color: Color(0xFFECF6FF),
>>>>>>> 69f9bbd5b3b1a63c0172d779502ab9f5acb8edc8
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_search_rounded,
                  size: 40.0,
                  color: Color(0xFF3985E7),
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
                  color: titleColor,
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
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
<<<<<<< HEAD

  // ---------------------------------------------------------------------------
  // BOTTOM NAVIGATION BAR (Permanen Scaffold 4 Menu)
  // ---------------------------------------------------------------------------
  Widget _buildBottomNavigationBar(bool isDark) {
    final barBg = isDark ? const Color(0xFF1A2228) : const Color(0xFFF2EDED);

    return Container(
      height: 68.0,
      decoration: BoxDecoration(
        color: barBg,
        boxShadow: const [
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
            isDark: isDark,
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Konsultasi',
            isActive: _selectedNavIndex == 1,
            isDark: isDark,
          ),
          _buildNavItem(
            index: 2,
            icon: Icons.history_rounded,
            label: 'Riwayat Konsultasi',
            isActive: _selectedNavIndex == 2,
            isDark: isDark,
          ),
          _buildNavItem(
            index: 3,
            icon: Icons.person_rounded,
            label: 'Profil',
            isActive: _selectedNavIndex == 3,
            isDark: isDark,
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
    required bool isDark,
  }) {
    final activeCircleBg = isDark ? const Color(0xFF2C363D) : Colors.white;
    final inactiveColor = isDark ? const Color(0xFF8696A0) : const Color(0xFF4A4A4A);

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
                color: isActive ? activeCircleBg : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24.0,
                color: isActive ? const Color(0xFF72A9F4) : inactiveColor,
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
                color: isActive ? const Color(0xFF72A9F4) : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
=======
>>>>>>> 69f9bbd5b3b1a63c0172d779502ab9f5acb8edc8
}

