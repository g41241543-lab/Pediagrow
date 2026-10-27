import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/local_push_service.dart';
import '../../core/services/staff_auth_service.dart';
import '../../core/services/storage_service.dart';
import '../../models/staff_account_model.dart';
import '../auth/auth_choice_page.dart';
import 'beranda/beranda_pmik_page.dart';
import 'konsultasi/konsultasi_pmik_admin_page.dart';
import '../pmik_superadmin/riwayat_konsultasi/daftar_riwayat_konsultasi_admin_page.dart';
import '../pengguna/profil/tampilan_page.dart';

/// Halaman Profil PMIK Admin PediaGrow.
///
/// - Hanya foto profil yang dapat diubah oleh PMIK sendiri.
/// - Semua informasi lain hanya dapat diedit oleh Superadmin.
class ProfilPmikPage extends StatefulWidget {
  const ProfilPmikPage({super.key});

  @override
  State<ProfilPmikPage> createState() => _ProfilPmikPageState();
}

class _ProfilPmikPageState extends State<ProfilPmikPage> {
  final int _selectedIndex = 3; // Profil aktif
  final ImagePicker _picker = ImagePicker();

  String? _avatarPath;
  StaffAccount? _pmik;

  @override
  void initState() {
    super.initState();
    _pmik = StaffAuthService().currentStaff;
    _avatarPath = _pmik?.avatarPath;
    _loadSavedData();
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
      _pmik = StaffAuthService().currentStaff;
      if (_pmik?.avatarPath != null && _pmik!.avatarPath!.isNotEmpty) {
        _avatarPath = _pmik!.avatarPath;
      }
    });
  }

  Future<void> _loadSavedData() async {
    final staff = StaffAuthService().currentStaff;
    if (staff != null) {
      setState(() => _pmik = staff);
      if (staff.avatarPath != null && staff.avatarPath!.isNotEmpty) {
        setState(() => _avatarPath = staff.avatarPath);
        return;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('pmik_avatar_${_pmik?.id}');
    if (savedPath != null && mounted) {
      setState(() => _avatarPath = savedPath);
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
                      color: Color(0xFF0891B2),
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
                      color: Color(0xFF0891B2),
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
        setState(() => _avatarPath = picked.path);
        final persistable = await StorageService.uploadIfLocal(picked.path);
        final prefs = await SharedPreferences.getInstance();
        if (_pmik?.id != null) {
          await prefs.setString('pmik_avatar_${_pmik!.id}', persistable);
          await StaffAuthService().updateStaffAccount(
            _pmik!.id,
            avatarPath: persistable,
          );
        }
        if (mounted) {
          LocalPushService().show(
            title: 'PediaGrow',
            body: 'Berhasil memperbarui foto profil',
            targetRole: PushRole.pmik,
          );
        }
      }
    } catch (e) {
      debugPrint('[ProfilPmikPage] _pickImage error: $e');
    }
  }

  // ─── LOGOUT ───────────────────────────────────────────────────────────────
  void _showLogoutConfirmationDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF1A2228) : Colors.white,
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
                  color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Apakah Anda yakin ingin keluar dari akun PMIK?',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark ? const Color(0xFF2C363D) : const Color(0xFFD1D7DB),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF2C363D),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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

  // ─── BOTTOM NAV ───────────────────────────────────────────────────────────
  void _onBottomNavTap(int index) {
    if (index == _selectedIndex) return;

    Widget targetPage;
    switch (index) {
      case 0:
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 280),
            pageBuilder: (_, _, _) => const BerandaPmikPage(),
            transitionsBuilder: (_, anim, _, child) => SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(-0.25, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                  ),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(anim),
                child: child,
              ),
            ),
          ),
          (r) => false,
        );
        return;
      case 1:
        targetPage = const KonsultasiPmikAdminPage();
        break;
      case 2:
        targetPage = const DaftarRiwayatKonsultasiAdminPage();
        break;
      default:
        return;
    }

    final isLeft = index < _selectedIndex;
    final route = PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, _, _) => targetPage,
      transitionsBuilder: (_, anim, _, child) => SlideTransition(
        position: Tween<Offset>(
          begin: Offset(isLeft ? -0.25 : 0.25, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(anim),
          child: child,
        ),
      ),
    );
    Navigator.of(context).pushReplacement(route);
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onBottomNavTap(0);
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1014) : const Color(0xFFFBFBFB),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: _buildCustomHeader(isDark),
        ),
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

                // 1. KARTU PROFIL
                _buildProfileCard(isDark),

                const SizedBox(height: 24.0),

                // 2. INFORMASI UMUM
                Text(
                  'Informasi Umum',
                  style: GoogleFonts.lato(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014),
                  ),
                ),
                const SizedBox(height: 12.0),
                _buildGeneralInfoCard(isDark),

                const SizedBox(height: 20.0),

                // 3. INFO hanya superadmin yang bisa edit
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF7C2D12).withValues(alpha: 0.25)
                        : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF9A3412) : const Color(0xFFFED7AA),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFF97316),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Informasi profil hanya dapat diubah oleh Superadmin. '
                          'Hubungi Superadmin jika perlu pembaruan data.',
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            color: isDark ? const Color(0xFFFDBA74) : const Color(0xFF92400E),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20.0),

                // 3.5 PENGATURAN TAMPILAN
                _buildTampilanMenuCard(isDark),

                const SizedBox(height: 24.0),

                // 4. TOMBOL LOGOUT
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
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────
  Widget _buildCustomHeader(bool isDark) {
    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF0B1014) : Colors.white,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56.0,
          child: Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _onBottomNavTap(0),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.arrow_back,
                      size: 24.0,
                      color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Text(
                  'Profil',
                  style: GoogleFonts.lato(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
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

  // ─── PROFILE CARD ─────────────────────────────────────────────────────────
  Widget _buildProfileCard(bool isDark) {
    const double avatarRadius = 46.0;
    final name = _pmik?.name.isNotEmpty == true ? _pmik!.name : 'Nama PMIK';
    final email = _pmik?.email ?? '';
    final roleLabel = _pmik?.pmikRoleDisplay ?? 'PMIK Admin';

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: const EdgeInsets.only(top: avatarRadius),
          padding: EdgeInsets.only(
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
              Text(
                name,
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014),
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                roleLabel,
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4.0),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 13.0,
                    color: const Color(0xFF8696A0),
                  ),
                ),
              ],
              const SizedBox(height: 18.0),
              Row(
                children: [
                  Expanded(
                    child: _buildStatChip(
                      isDark: isDark,
                      icon: Icons.work_rounded,
                      iconColor: const Color(0xFF2563EB),
                      bgColor: const Color(0xFFEFF6FF),
                      label: 'Pengalaman',
                      value: _pmik?.experience != null
                          ? '${_pmik!.experience} thn'
                          : '-',
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
                      value: _pmik?.strNumber ?? '-',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Avatar melayang dengan badge kamera
        Positioned(
          top: 0,
          child: GestureDetector(
            onTap: _showImagePickerOptions,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: isDark ? const Color(0xFF2C363D) : const Color(0xFFE0F2FE),
                  backgroundImage: StorageService.buildImageProvider(
                    _avatarPath,
                  ),
                  child: StorageService.buildImageProvider(_avatarPath) == null
                      ? Icon(
                          Icons.person_rounded,
                          size: avatarRadius * 1.1,
                          color: const Color(0xFF0891B2),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0891B2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF1A2228) : Colors.white,
                        width: 2,
                      ),
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
                  color: const Color(0xFF8696A0),
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lato(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── GENERAL INFO CARD ────────────────────────────────────────────────────
  Widget _buildGeneralInfoCard(bool isDark) {
    final items = [
      _InfoItem(
        icon: Icons.calendar_today_rounded,
        iconColor: const Color(0xFF3985E7),
        bgColor: const Color(0xFFEFF6FF),
        label: 'Tanggal Lahir',
        value: _pmik?.birthDate ?? '-',
      ),
      _InfoItem(
        icon: Icons.school_rounded,
        iconColor: const Color(0xFF3985E7),
        bgColor: const Color(0xFFEFF6FF),
        label: 'Pendidikan',
        value: _pmik?.education ?? '-',
      ),
    ];

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
            blurRadius: 12.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 14.0,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C363D) : item.bgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(item.icon, size: 20, color: item.iconColor),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: const Color(0xFF8696A0),
                          ),
                        ),
                        Text(
                          item.value,
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1)
                Divider(
                  height: 1,
                  indent: 66,
                  color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF),
                ),
            ],
          );
        }),
      ),
    );
  }

  // ─── BOTTOM NAV ───────────────────────────────────────────────────────────
  Widget _buildBottomNavigationBar() {
    final navItems = [
      const _NavItem(icon: Icons.home_rounded, label: 'Beranda'),
      const _NavItem(icon: Icons.question_answer_rounded, label: 'Konsultasi'),
      const _NavItem(
        icon: Icons.manage_search_rounded,
        label: 'Riwayat Konsultasi',
      ),
      const _NavItem(icon: Icons.person_rounded, label: 'Profil'),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? const Color(0xFF1A2228) : const Color(0xFFF2EDED);
    final activeCircleBg = isDark ? const Color(0xFF2C363D) : Colors.white;
    final activeLabelColor = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1E293B);
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

// ─── DATA CLASS ───────────────────────────────────────────────────────────────
class _InfoItem {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  final String value;
  const _InfoItem({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.value,
  });
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
