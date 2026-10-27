import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/local_push_service.dart';
import '../../../core/services/staff_auth_service.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/auth_choice_page.dart';
import '../beranda/beranda_superadmin_page.dart';
import '../konsultasi/konsultasi_superadmin_page.dart';
import '../riwayat_konsultasi/daftar_riwayat_konsultasi_admin_page.dart';
import '../../../models/staff_account_model.dart';
import '../../pengguna/profil/tampilan_page.dart';

/// Halaman Profil Superadmin untuk aplikasi PediaGrow.
///
/// Fitur Utama:
/// 1. Custom Header 56dp tetap di atas layar (tidak ikut ter-scroll).
///    - Tombol kembali (arrow_back) berjarak tepat 12dp dari sisi kiri.
///    - Judul "Profil" berjarak 12dp setelah tombol kembali.
/// 2. Konten Scrollable menggunakan [SingleChildScrollView] dengan padding responsif
///    sehingga aman dari overflow di semua resolusi Android.
/// 3. Kartu Profil dengan foto avatar yang melayang di atas kartu,
///    menampilkan data Anita Setyowati, S.Tr. RMIK, Pengalaman, dan No. STR.
///    Dapat diubah fotonya dari galeri maupun kamera dengan badge kamera standar PediaGrow.
/// 4. Kartu Informasi Umum (Tanggal Lahir dan Pendidikan).
/// 5. Informasi Hak Akses (status hak akses penuh Superadmin) dan tombol "LOGOUT".
/// 6. Bottom Navigation Bar permanen 4 menu pada [Scaffold.bottomNavigationBar]
///    dengan menu "Profil" aktif sesuai desain PediaGrow.
class ProfilSuperadminPage extends StatefulWidget {
  final VoidCallback? onBackPressed;

  /// Ketika [inShell] true, halaman berjalan di dalam [SuperadminShell]:
  /// - bottomNavigationBar tidak dirender (navbar milik shell).
  /// - _onBottomNavTap tidak melakukan push/replace (shell yang mengelola tab).
  final bool inShell;

  const ProfilSuperadminPage({super.key, this.onBackPressed, this.inShell = false});

  @override
  State<ProfilSuperadminPage> createState() => _ProfilSuperadminPageState();
}

class _ProfilSuperadminPageState extends State<ProfilSuperadminPage> {
  final int _selectedIndex = 3; // Menu Profil aktif
  final ImagePicker _picker = ImagePicker();
  String? _superadminAvatarPath;
  StaffAccount? _superadmin;

  @override
  void initState() {
    super.initState();
    _superadmin = StaffAuthService().currentStaff;
    _superadminAvatarPath = _superadmin?.avatarPath;
    _loadSavedAvatar();
    _loadSuperadminData();
    StaffAuthService().currentStaffNotifier.addListener(_onStaffUpdated);
  }

  @override
  void dispose() {
    StaffAuthService().currentStaffNotifier.removeListener(_onStaffUpdated);
    super.dispose();
  }

  void _onStaffUpdated() {
    if (!mounted) return;
    setState(() {
      _superadmin = StaffAuthService().currentStaff;
      if (_superadmin?.avatarPath != null &&
          _superadmin!.avatarPath!.isNotEmpty) {
        _superadminAvatarPath = _superadmin!.avatarPath;
      }
    });
  }

  Future<void> _loadSuperadminData() async {
    final current = StaffAuthService().currentStaff;
    if (current != null) {
      if (mounted) {
        setState(() {
          _superadmin = current;
          if (current.avatarPath != null && current.avatarPath!.isNotEmpty) {
            _superadminAvatarPath = current.avatarPath;
          }
        });
      }
      return;
    }
    final acc = await StaffAuthService().getSuperadminAccount();
    if (acc != null && mounted) {
      setState(() {
        _superadmin = acc;
        if (acc.avatarPath != null && acc.avatarPath!.isNotEmpty) {
          _superadminAvatarPath = acc.avatarPath;
        }
      });
    }
  }

  Future<void> _loadSavedAvatar() async {
    final staff = StaffAuthService().currentStaff;
    if (staff?.avatarPath != null && staff!.avatarPath!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _superadminAvatarPath = staff.avatarPath;
        });
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('superadmin_avatar_path');
    if (savedPath != null && mounted) {
      setState(() {
        _superadminAvatarPath = savedPath;
      });
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D7DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ubah Foto Profil',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0B1014),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Color(0xFF38C1A2),
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Ambil Foto dari Kamera',
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0B1014),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                const Divider(height: 1, color: Color(0xFFE9EDEF)),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: Color(0xFF38C1A2),
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Pilih Foto dari Galeri',
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0B1014),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _superadminAvatarPath = picked.path;
        });
        final persistable = await StorageService.uploadIfLocal(picked.path);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('superadmin_avatar_path', persistable);

        if (_superadmin?.id != null && _superadmin!.id.isNotEmpty) {
          await StaffAuthService().updateStaffAccount(
            _superadmin!.id,
            avatarPath: persistable,
          );
        }

        if (mounted) {
          LocalPushService().show(
            title: 'PediaGrow',
            body: 'Berhasil memperbarui foto profil',
            targetRole: PushRole.superadmin,
          );
        }
      }
    } catch (e) {
      debugPrint('[ProfilSuperadminPage] _pickImage error: $e');
    }
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A2228)
            : Colors.white,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                'Keluar dari Akun',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFE9EDEF)
                      : const Color(0xFF0B1014),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Apakah Anda yakin ingin keluar dari akun Superadmin?',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF8696A0)
                      : const Color(0xFF667781),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  // Tombol Batal
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2C363D)
                                : const Color(0xFFD1D7DB),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFFE9EDEF)
                                : const Color(0xFF2C363D),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tombol Keluar
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogCtx).pop();
                          StaffAuthService().logout();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const AuthChoicePage(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          'Keluar',
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onBottomNavTap(int index) {
    // Ketika berjalan di dalam shell, navigasi tab dikelola oleh SuperadminShell.
    if (widget.inShell) return;
    if (index == _selectedIndex) return;

    final staff = StaffAuthService().currentStaff;
    if (index == 1 && staff != null && !staff.hasPermission('konsultasi')) {
      LocalPushService().show(
        title: 'Akses Terbatas',
        body: 'Akses fitur "Konsultasi" dinonaktifkan oleh Superadmin.',
        targetRole: PushRole.superadmin,
      );
      return;
    }
    if (index == 2 &&
        staff != null &&
        !staff.isSuperAdmin &&
        !staff.hasPermission('riwayat_konsultasi')) {
      LocalPushService().show(
        title: 'Akses Terbatas',
        body: 'Akses fitur "Riwayat Konsultasi" dinonaktifkan oleh Superadmin.',
        targetRole: PushRole.superadmin,
      );
      return;
    }

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
      default:
        return;
    }

    final isLeft = index < _selectedIndex;
    final beginOffset = Offset(isLeft ? -0.25 : 0.25, 0.0);

    final route = PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, _, _) => targetPage,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(curvedAnimation),
            child: child,
          ),
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
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1014) : const Color(0xFFFBFBFB),
      // Custom Header permanen 56dp di bagian paling atas layar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: _buildCustomHeader(isDark),
      ),
      // Konten utama scrollable anti-overflow
      body: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16.0),

              // 1. KARTU PROFIL DENGAN AVATAR MELAYANG
              _buildProfileCard(isDark),

              const SizedBox(height: 24.0),

              // 2. JUDUL INFORMASI UMUM
              Text(
                'Informasi Umum',
                style: GoogleFonts.lato(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014),
                ),
              ),

              const SizedBox(height: 12.0),

              // 3. KARTU INFORMASI UMUM
              _buildGeneralInfoCard(isDark),

              const SizedBox(height: 20.0),

              // 4. INFORMASI HAK AKSES SUPERADMIN
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF064E3B).withValues(alpha: 0.3)
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF059669).withValues(alpha: 0.5)
                        : const Color(0xFFA7F3D0),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: Color(0xFF059669),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Akun ini memiliki hak akses penuh sebagai Superadmin. '
                        'Pengelolaan hak akses staf dan dokter dapat dilakukan melalui menu Kelola Hak Akses di Beranda.',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFF6EE7B7)
                              : const Color(0xFF065F46),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20.0),

              // 4.5 PENGATURAN TAMPILAN
              _buildTampilanMenuCard(isDark),

              const SizedBox(height: 24.0),

              // 5. TOMBOL LOGOUT (Warna Biru PediaGrow #3985E7)
              SizedBox(
                height: 50.0,
                child: ElevatedButton(
                  onPressed: _showLogoutConfirmationDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3985E7),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: Text(
                    'LOGOUT',
                    style: GoogleFonts.lato(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
      // Scaffold.bottomNavigationBar permanen 4 menu
      bottomNavigationBar: widget.inShell ? null : _buildBottomNavigationBar(),
    );
  }

  /// Header kustom dengan tinggi tepat 56dp di bawah SafeArea atas.
  /// Judul "Profil" terletak tepat 16dp dari pojok layar kiri (tanpa tombol back).
  Widget _buildCustomHeader(bool isDark) {
    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF0B1014) : Colors.white,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Profil',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lato(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── MENU TAMPILAN ─────────────────────────────────────────────────────────
  Widget _buildTampilanMenuCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const TampilanPage(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0B1014) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.palette_outlined,
                    color: Color(0xFF3985E7),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tampilan',
                        style: GoogleFonts.lato(
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pilih tema terang, gelap, atau sistem',
                        style: GoogleFonts.lato(
                          fontSize: 12.0,
                          color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: isDark ? const Color(0xFF8696A0) : const Color(0xFF8696A0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Kartu profil dengan avatar bulat melayang di bagian atas kartu
  Widget _buildProfileCard(bool isDark) {
    const double avatarRadius = 46.0; // Diameter 92dp

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Kontainer kartu putih
        Container(
          margin: const EdgeInsets.only(top: avatarRadius),
          padding: const EdgeInsets.only(
            top: avatarRadius + 10.0,
            left: 16.0,
            right: 16.0,
            bottom: 20.0,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2228) : Colors.white,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 16.0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nama Superadmin
              Text(
                _superadmin?.name.isNotEmpty == true
                    ? _superadmin!.name
                    : 'Anita Setyowati, S.Tr. RMIK',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014),
                ),
              ),

              const SizedBox(height: 4.0),

              // Role / Profesi
              Text(
                'PMIK',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                ),
              ),

              const SizedBox(height: 4.0),

              // Email
              Text(
                _superadmin?.email.isNotEmpty == true
                    ? _superadmin!.email
                    : 'g41241509@student.polije.ac.id',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 13.0,
                  color: const Color(0xFF8696A0),
                ),
              ),

              const SizedBox(height: 18.0),

              // Baris Info: Pengalaman & No. STR (Ikon berwarna)
              Row(
                children: [
                  Expanded(
                    child: _buildStatChip(
                      isDark: isDark,
                      icon: Icons.work_rounded,
                      iconColor: const Color(0xFF2563EB),
                      bgColor: const Color(0xFFEFF6FF),
                      label: 'Pengalaman',
                      value: _superadmin?.experience ?? '7 tahun',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatChip(
                      isDark: isDark,
                      icon: Icons.badge_outlined,
                      iconColor: const Color(0xFF0891B2),
                      bgColor: const Color(0xFFECFEFF),
                      label: 'No. STR',
                      value: _superadmin?.strNumber ?? '3511201402012222',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Avatar Bulat melayang di posisi atas
        Positioned(
          top: 0,
          child: GestureDetector(
            onTap: _showImagePickerOptions,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: avatarRadius * 2,
                  height: avatarRadius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF1A2228) : Colors.white,
                      width: 3.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 10.0,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(child: _buildSuperadminAvatarImage()),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF38C1A2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuperadminAvatarImage() {
    return StorageService.buildImageWidget(
      _superadminAvatarPath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorWidget: Image.asset(
        'assets/images/anita_superadmin.jpg',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      color: const Color(0xFFE9EDEF),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_rounded,
        size: 52.0,
        color: Color(0xFF72A9F4),
      ),
    );
  }

  Widget _buildStatChip({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C363D) : bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                style: GoogleFonts.lato(
                  fontSize: 11,
                  color: isDark ? const Color(0xFF8696A0) : const Color(0xFF94A3B8),
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lato(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Kartu Informasi Umum (Tanggal Lahir dan Pendidikan)
  Widget _buildGeneralInfoCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Item 1: Tanggal Lahir
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 26.0,
                  color: Color(0xFF8696A0),
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tanggal Lahir',
                        style: GoogleFonts.lato(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014),
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        _superadmin?.birthDate ?? '16/07/2006',
                        style: GoogleFonts.lato(
                          fontSize: 14.0,
                          color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Garis pemisah tipis
          Divider(
            height: 1.0,
            thickness: 1.0,
            color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF),
          ),

          // Item 2: Pendidikan
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.home_work_outlined,
                  size: 26.0,
                  color: Color(0xFF8696A0),
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pendidikan',
                        style: GoogleFonts.lato(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014),
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        _superadmin?.education ??
                            'DIV - Manajemen Informasi Kesehatan',
                        style: GoogleFonts.lato(
                          fontSize: 14.0,
                          color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Scaffold.bottomNavigationBar permanen 4 menu konsisten dengan PediaGrow
  Widget _buildBottomNavigationBar() {
    final navItems = [
      _BottomNavItemData(icon: Icons.home_rounded, label: 'Beranda'),
      _BottomNavItemData(
        icon: Icons.question_answer_rounded,
        label: 'Konsultasi',
      ),
      _BottomNavItemData(
        icon: Icons.manage_search_rounded,
        label: 'Riwayat Konsultasi',
      ),
      _BottomNavItemData(icon: Icons.person_rounded, label: 'Profil'),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? const Color(0xFF1A2228) : const Color(0xFFF2EDED);
    final activeCircleBg = isDark ? const Color(0xFF2C363D) : Colors.white;
    final activeLabelColor = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228);
    final inactiveColor = isDark ? const Color(0xFF667781) : const Color(0xFF9E9E9E);

    return Container(
      width: double.infinity,
      height: 68.0,
      decoration: BoxDecoration(
        color: navBg,
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
            final isSelected = i == _selectedIndex;
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
                        // State aktif: bulatan putih dengan icon biru #72A9F4
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
                                color: activeLabelColor,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // State tidak aktif: icon & teks abu-abu #9E9E9E
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

  const _BottomNavItemData({required this.icon, required this.label});
}
