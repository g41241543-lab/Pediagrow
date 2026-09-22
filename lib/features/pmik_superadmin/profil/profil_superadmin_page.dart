import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/staff_auth_service.dart';
import '../../auth/auth_choice_page.dart';
import 'hak_akses/hak_akses_page.dart';

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
/// 4. Kartu Informasi Umum (Tanggal Lahir dan Pendidikan).
/// 5. Tombol aksi "HAK AKSES" (menuju halaman pengelolaan hak akses Dokter & PMIK)
///    dan tombol "LOGOUT" (dengan dialog konfirmasi keluar).
/// 6. Bottom Navigation Bar permanen 4 menu pada [Scaffold.bottomNavigationBar]
///    dengan menu "Profil" aktif sesuai desain PediaGrow.
class ProfilSuperadminPage extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const ProfilSuperadminPage({
    super.key,
    this.onBackPressed,
  });

  @override
  State<ProfilSuperadminPage> createState() => _ProfilSuperadminPageState();
}

class _ProfilSuperadminPageState extends State<ProfilSuperadminPage> {
  int _selectedIndex = 3; // Menu Profil aktif

  void _handleBack() {
    if (widget.onBackPressed != null) {
      widget.onBackPressed!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _navigateToHakAkses() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const HakAksesPage(),
      ),
    );
  }

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
                'Apakah Anda yakin ingin keluar dari akun Superadmin?',
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
                  // Tombol Batal
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
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
                            color: const Color(0xFF475569),
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
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    switch (index) {
      case 0:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Menavigasi ke Beranda Superadmin',
              style: GoogleFonts.lato(),
            ),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case 1:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Halaman Konsultasi Superadmin',
              style: GoogleFonts.lato(),
            ),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case 2:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Halaman Riwayat Konsultasi Superadmin',
              style: GoogleFonts.lato(),
            ),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case 3:
        // Sudah di profil
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      // Custom Header permanen 56dp di bagian paling atas layar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: _buildCustomHeader(),
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
              _buildProfileCard(),

              const SizedBox(height: 24.0),

              // 2. JUDUL INFORMASI UMUM
              Text(
                'Informasi Umum',
                style: GoogleFonts.lato(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),

              const SizedBox(height: 12.0),

              // 3. KARTU INFORMASI UMUM
              _buildGeneralInfoCard(),

              const SizedBox(height: 24.0),

              // 4. TOMBOL HAK AKSES (Warna Toska #38C1A2)
              SizedBox(
                height: 50.0,
                child: ElevatedButton(
                  onPressed: _navigateToHakAkses,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38C1A2),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: Text(
                    'HAK AKSES',
                    style: GoogleFonts.lato(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12.0),

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
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Header kustom dengan tinggi tepat 56dp di bawah SafeArea atas.
  /// Tombol kembali berada 12dp dari sisi kiri, diikuti judul "Profil" 12dp setelahnya.
  Widget _buildCustomHeader() {
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
                // Tombol kembali (12dp dari sisi kiri layar)
                GestureDetector(
                  onTap: _handleBack,
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

                // Jarak 12dp setelah area tombol kembali
                const SizedBox(width: 12.0),

                // Judul "Profil"
                Expanded(
                  child: Text(
                    'Profil',
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

  /// Kartu profil dengan avatar bulat melayang di bagian atas kartu
  Widget _buildProfileCard() {
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.0,
            ),
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
              // Nama Superadmin
              Text(
                'Anita Setyowati, S.Tr. RMIK',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
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
                  color: const Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 4.0),

              // Email
              Text(
                'g41241509@student.polije.ac.id',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 13.0,
                  color: const Color(0xFF94A3B8),
                ),
              ),

              const SizedBox(height: 18.0),

              // Baris Info: Pengalaman & No. STR
              Row(
                children: [
                  // Kolom Kiri: Pengalaman
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.work_outline_rounded,
                          size: 24.0,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pengalaman',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.lato(
                                  fontSize: 13.0,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              Text(
                                '7 tahun',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.lato(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Kolom Kanan: No. STR
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.badge_outlined,
                          size: 24.0,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No. STR',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.lato(
                                  fontSize: 13.0,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              Text(
                                '3511201402012222',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.lato(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF334155),
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
            ],
          ),
        ),

        // Avatar Bulat melayang di posisi atas
        Positioned(
          top: 0,
          child: Container(
            width: avatarRadius * 2,
            height: avatarRadius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
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
            child: ClipOval(
              child: Image.asset(
                'assets/images/anita_superadmin.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFE2E8F0),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.person_rounded,
                      size: 52.0,
                      color: Color(0xFF72A9F4),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Kartu Informasi Umum (Tanggal Lahir dan Pendidikan)
  Widget _buildGeneralInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10.0,
            offset: Offset(0, 3),
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
                  Icons.event_note_outlined,
                  size: 28.0,
                  color: Color(0xFF94A3B8),
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
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        '16/07/2006',
                        style: GoogleFonts.lato(
                          fontSize: 14.0,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Garis pemisah tipis
          const Divider(
            height: 1.0,
            thickness: 1.0,
            color: Color(0xFFF1F5F9),
          ),

          // Item 2: Pendidikan
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.home_work_outlined,
                  size: 28.0,
                  color: Color(0xFF94A3B8),
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
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        'DIV - Manajemen Informasi Kesehatan',
                        style: GoogleFonts.lato(
                          fontSize: 14.0,
                          color: const Color(0xFF64748B),
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
      _BottomNavItemData(icon: Icons.question_answer_rounded, label: 'Konsultasi'),
      _BottomNavItemData(icon: Icons.manage_search_rounded, label: 'Riwayat Konsultasi'),
      _BottomNavItemData(icon: Icons.person_rounded, label: 'Profil'),
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
                        // State tidak aktif: icon & teks abu-abu #9E9E9E
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
