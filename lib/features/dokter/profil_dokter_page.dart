import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/staff_auth_service.dart';
import '../../models/staff_account_model.dart';
import '../auth/auth_choice_page.dart';
import 'beranda/beranda_dokter_page.dart';

/// Halaman Profil Dokter PediaGrow.
///
/// - Hanya foto profil yang dapat diubah oleh dokter sendiri.
/// - Semua informasi lain hanya dapat diedit oleh Superadmin.
/// - Terdapat toggle Online/Offline di pojok kanan atas header.
class ProfilDokterPage extends StatefulWidget {
  const ProfilDokterPage({super.key});

  @override
  State<ProfilDokterPage> createState() => _ProfilDokterPageState();
}

class _ProfilDokterPageState extends State<ProfilDokterPage> {
  final int _selectedIndex = 3; // Profil aktif

  String? _avatarPath;
  StaffAccount? _dokter;
  bool _isOnline = false; // Status online/offline dokter

  @override
  void initState() {
    super.initState();
    _dokter = StaffAuthService().currentStaff;
    _avatarPath = _dokter?.avatarPath;
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
      _dokter = StaffAuthService().currentStaff;
      if (_dokter?.avatarPath != null && _dokter!.avatarPath!.isNotEmpty) {
        _avatarPath = _dokter!.avatarPath;
      }
    });
  }

  Future<void> _loadSavedData() async {
    final staff = StaffAuthService().currentStaff;
    if (staff != null) {
      setState(() => _dokter = staff);
      if (staff.avatarPath != null && staff.avatarPath!.isNotEmpty) {
        setState(() => _avatarPath = staff.avatarPath);
        return;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('dokter_avatar_${_dokter?.id}');
    final savedOnline = prefs.getBool('dokter_online_${_dokter?.id}') ?? false;
    if (mounted) {
      setState(() {
        if (savedPath != null) _avatarPath = savedPath;
        _isOnline = savedOnline;
      });
    }
  }

  // ─── ONLINE TOGGLE ────────────────────────────────────────────────────────
  Future<void> _toggleOnlineStatus() async {
    final newStatus = !_isOnline;
    setState(() => _isOnline = newStatus);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dokter_online_${_dokter?.id}', newStatus);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? 'Status Anda sekarang Online — pasien dapat menemukan Anda'
                : 'Status Anda sekarang Offline',
            style: GoogleFonts.lato(fontWeight: FontWeight.w600),
          ),
          backgroundColor:
              newStatus ? const Color(0xFF16A34A) : const Color(0xFF64748B),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ─── LOGOUT ───────────────────────────────────────────────────────────────
  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
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
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Apakah Anda yakin ingin keluar dari akun Dokter?',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
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
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Batal',
                            style: GoogleFonts.lato(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF475569))),
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
                                builder: (_) => const AuthChoicePage()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Keluar',
                            style: GoogleFonts.lato(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
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
            pageBuilder: (_, __, ___) => const BerandaDokterPage(),
            transitionsBuilder: (_, anim, __, child) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-0.25, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
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
        targetPage = const _PlaceholderPage(title: 'Konsultasi');
        break;
      case 2:
        targetPage = const _PlaceholderPage(title: 'Riwayat Konsultasi');
        break;
      default:
        return;
    }

    final isLeft = index < _selectedIndex;
    final route = PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => targetPage,
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
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
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: _buildCustomHeader(),
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
              _buildProfileCard(),

              const SizedBox(height: 24.0),

              // 2. INFORMASI UMUM
              Text(
                'Informasi Umum',
                style: GoogleFonts.lato(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12.0),
              _buildGeneralInfoCard(),

              const SizedBox(height: 20.0),

              // 3. INFO hanya superadmin yang bisa edit
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFFF97316), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Informasi profil hanya dapat diubah oleh Superadmin. '
                        'Hubungi Superadmin jika perlu pembaruan data.',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: const Color(0xFF92400E),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

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
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────
  Widget _buildCustomHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  'Profil',
                  style: GoogleFonts.lato(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF000000),
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                // Online/Offline Toggle
                GestureDetector(
                  onTap: _toggleOnlineStatus,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _isOnline
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Stack(
                      children: [
                        AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          alignment: _isOnline
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x30000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  // ─── PROFILE CARD ─────────────────────────────────────────────────────────
  Widget _buildProfileCard() {
    const double avatarRadius = 46.0;
    final name = _dokter?.name.isNotEmpty == true
        ? _dokter!.name
        : 'dr. Nama Dokter, Sp.A';
    final spesialisasi =
        _dokter?.additionalInfo?['spesialisasi']?.toString() ??
            'Spesialis Anak';
    final email = _dokter?.email ?? '';

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Kartu putih
        Container(
          margin: const EdgeInsets.only(top: avatarRadius),
          padding: EdgeInsets.only(
            top: avatarRadius + 10.0,
            left: 16.0,
            right: 16.0,
            bottom: 20.0,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 16.0,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status badge
              if (_isOnline)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Online',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Offline',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

              Text(
                name,
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                spesialisasi,
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4.0),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 13.0,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
              const SizedBox(height: 18.0),
              // Pengalaman & STR
              Row(
                children: [
                  Expanded(
                    child: _buildStatChip(
                      icon: Icons.work_rounded,
                      iconColor: const Color(0xFF2563EB),
                      bgColor: const Color(0xFFEFF6FF),
                      label: 'Pengalaman',
                      value: _dokter?.experience != null
                          ? '${_dokter!.experience} thn'
                          : '-',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatChip(
                      icon: Icons.badge_outlined,
                      iconColor: const Color(0xFF0891B2),
                      bgColor: const Color(0xFFECFEFF),
                      label: 'No. STR',
                      value: _dokter?.strNumber ?? '-',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Avatar melayang
        Positioned(
          top: 0,
          child: CircleAvatar(
            radius: avatarRadius,
            backgroundColor: const Color(0xFFE0EEFF),
            backgroundImage: _avatarPath != null
                ? FileImage(File(_avatarPath!)) as ImageProvider
                : null,
            child: _avatarPath == null
                ? Icon(Icons.person_rounded,
                    size: avatarRadius * 1.1,
                    color: const Color(0xFF3985E7))
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip({
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
            color: bgColor,
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
              Text(label,
                  maxLines: 1,
                  style: GoogleFonts.lato(
                      fontSize: 11, color: const Color(0xFF94A3B8))),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A))),
            ],
          ),
        ),
      ],
    );
  }

  // ─── GENERAL INFO CARD ────────────────────────────────────────────────────
  Widget _buildGeneralInfoCard() {
    final items = [
      _InfoItem(
        icon: Icons.cake_rounded,
        iconColor: const Color(0xFFEC4899),
        bgColor: const Color(0xFFFDF2F8),
        label: 'Tanggal Lahir',
        value: _dokter?.birthDate ?? '-',
      ),
      _InfoItem(
        icon: Icons.school_rounded,
        iconColor: const Color(0xFF7C3AED),
        bgColor: const Color(0xFFF5F3FF),
        label: 'Pendidikan',
        value: _dokter?.education ?? '-',
      ),
      _InfoItem(
        icon: Icons.local_hospital_rounded,
        iconColor: const Color(0xFF0891B2),
        bgColor: const Color(0xFFECFEFF),
        label: 'Spesialisasi',
        value: _dokter?.additionalInfo?['spesialisasi']?.toString() ??
            'Spesialis Anak',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12.0,
            offset: Offset(0, 2),
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
                    horizontal: 16.0, vertical: 14.0),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: item.bgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(item.icon,
                          size: 20, color: item.iconColor),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        Text(
                          item.value,
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1)
                const Divider(
                    height: 1, indent: 66, color: Color(0xFFF1F5F9)),
            ],
          );
        }),
      ),
    );
  }

  // ─── BOTTOM NAV ───────────────────────────────────────────────────────────
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.0)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8.0,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Beranda'),
              _buildNavItem(1, Icons.chat_bubble_outline_rounded, 'Konsultasi'),
              _buildNavItem(
                  2, Icons.receipt_long_rounded, 'Riwayat\nKonsultasi'),
              _buildNavItem(3, Icons.person_rounded, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = index == _selectedIndex;
    return GestureDetector(
      onTap: () => _onBottomNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 24,
                color: isSelected
                    ? const Color(0xFF3985E7)
                    : const Color(0xFF94A3B8)),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.lato(
                fontSize: 10.5,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF3985E7)
                    : const Color(0xFF94A3B8),
                height: 1.2,
              ),
            ),
          ],
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

// ─── PLACEHOLDER ──────────────────────────────────────────────────────────────
class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
