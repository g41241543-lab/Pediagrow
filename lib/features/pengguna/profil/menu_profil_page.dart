import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/user_service.dart';
import '../../../models/user_model.dart';
import '../../../shared/widgets/illustration_forest_footer.dart';
import '../../auth/terms_page.dart';
import '../beranda/beranda_page.dart';
import '../beranda/notifikasi_page.dart';
import '../konsultasi/daftar_dokter_page.dart';
import '../riwayat_konsultasi/daftar_riwayat_page.dart';
import 'keluar_logout_dialog.dart';
import 'profil_ibu_page.dart';
import 'tentang_aplikasi_page.dart';
import 'ubah_password_page.dart';

/// Halaman Menu Profil Ibu PediaGrow.
///
/// Halaman utama tab navigasi bawah (bottom tab ke-4):
/// 1. Header Tetap (56dp) di bawah SafeArea:
///    - Judul "Profil Ibu" (Lato Bold 20, #000000), 16dp dari pinggir kiri layar.
///    - Tanpa tombol back (karena merupakan halaman utama tab navigasi).
///    - Ikon notifikasi lonceng di kanan atas (onTap -> NotifikasiPage) sama dengan beranda_page.dart (31x31).
/// 2. Konten Scrollable:
///    - Padding horizontal 16dp konsisten.
///    - Kartu Profil Ibu: avatar bulat (placeholder abu-abu terang / foto lokal kamera/galeri)
///      + nama user dinamis dari [UserService] (Lato Bold 18 #000000 sejajar tengah).
///    - Divider tipis abu-abu di bawah kartu profil.
///    - 5 Daftar Menu vertikal:
///      1. Profil (person outline) -> profil_ibu_page.dart
///      2. Ubah Kata Sandi (key outline) -> ubah_password_page.dart
///      3. Tentang Aplikasi (info outline) -> tentang_aplikasi_page.dart
///      4. Keluar (logout outline) -> Alert dialog konfirmasi keluar
///      5. Syarat dan Ketentuan (document outline) -> terms_page.dart
///    - Tipografi: Lato Reguler 18 #000000, icon hitam 22-24dp, chevron right (>), dan animasi onTap.
///    - Ilustrasi penutup footer pemandangan hutan/rumput/tenda reusable menempel di bawah konten sebelum navbar.
/// 3. Navigation Bar Tetap (68dp, #F2EDED) di posisi Scaffold:
///    - Menu Profil Ibu terpilih dengan bulatan putih dan ikon biru (#72A9F4).
class MenuProfilPage extends StatefulWidget {
  const MenuProfilPage({super.key});

  @override
  State<MenuProfilPage> createState() => _MenuProfilPageState();
}

class _MenuProfilPageState extends State<MenuProfilPage> {
  // Indeks tab navigasi aktif (3 = Profil Ibu)
  final int _selectedNavIndex = 3;

  final ImagePicker _picker = ImagePicker();

  void _navigateTo(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  void _onNavTap(int index) {
    if (index == _selectedNavIndex) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const BerandaPage()),
          (route) => false,
        );
        break;
      case 1:
        _navigateTo(const DaftarDokterPage());
        break;
      case 2:
        _navigateTo(const DaftarRiwayatPage());
        break;
      case 3:
        // Sudah berada di Menu Profil Ibu
        break;
    }
  }

  /// Menampilkan opsi pemilihan sumber gambar (Kamera atau Galeri)
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
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ubah Foto Profil',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF000000),
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
                      color: Color(0xFF3985E7),
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Ambil Foto dari Kamera',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF000000),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: Color(0xFF3985E7),
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Pilih Foto dari Galeri',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF000000),
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
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        UserService().updateAvatar(pickedFile.path);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Foto profil berhasil diperbarui!',
                style: GoogleFonts.lato(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF3985E7),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memilih gambar: $e',
              style: GoogleFonts.lato(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ---------------------------------------------------------------
            // 1. HEADER TETAP DI POSISI ATAS (56dp)
            // ---------------------------------------------------------------
            _buildFixedHeader(),

            // ---------------------------------------------------------------
            // 2. KONTEN SCROLLABLE (KARTU PROFIL + DAFTAR MENU + ILUSTRASI)
            // ---------------------------------------------------------------
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 12),

                            // Kartu Profil Ibu (Avatar Bulat + Nama Lengkap Dinamis)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: _buildProfileCard(),
                            ),

                            const SizedBox(height: 16),

                            // Garis pembatas tipis di bawah kartu profil
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFF1F5F9),
                            ),

                            const SizedBox(height: 8),

                            // Daftar 5 Menu Vertikal
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: _buildMenuList(),
                            ),

                            // Spacer fleksibel agar ilustrasi menempel di bagian bawah
                            const Spacer(),

                            // Ilustrasi Pemandangan Hutan/Rumput/Tenda Reusable
                            const IllustrationForestFooter(
                              fit: BoxFit.fitWidth,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Navigation Bar tetap di posisi Scaffold
      bottomNavigationBar: _buildFixedNavBar(),
    );
  }

  // -------------------------------------------------------------------------
  // 1. HEADER TETAP DI ATAS (56dp)
  // -------------------------------------------------------------------------
  Widget _buildFixedHeader() {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Nama Halaman: Profil Ibu (Lato Bold 20, #000000, 16dp dari pinggir kiri layar)
            Text(
              'Profil Ibu',
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF000000),
              ),
            ),
            const Spacer(),

            // Lingkaran Notifikasi (31×31, #FFFFFF, 12dp dari kanan) sama persis dengan beranda_page.dart
            GestureDetector(
              onTap: () => _navigateTo(const NotifikasiPage()),
              child: Container(
                width: 31,
                height: 31,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF1E293B),
                  size: 19,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 2. KARTU PROFIL USER (Avatar bulat + Nama dinamis sejajar tengah)
  // -------------------------------------------------------------------------
  Widget _buildProfileCard() {
    return ValueListenableBuilder<UserModel>(
      valueListenable: UserService().currentUserNotifier,
      builder: (context, user, _) {
        final avatarPath = user.avatarPath;
        final hasCustomAvatar =
            avatarPath != null &&
            avatarPath.isNotEmpty &&
            File(avatarPath).existsSync();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar bulat (placeholder icon user / foto lokal)
            GestureDetector(
              onTap: _showImagePickerOptions,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE2E8F0),
                      image: hasCustomAvatar
                          ? DecorationImage(
                              image: FileImage(File(avatarPath)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: hasCustomAvatar
                        ? null
                        : const Icon(
                            Icons.person,
                            size: 40,
                            color: Color(0xFF64748B),
                          ),
                  ),

                  // Badge kecil kamera di pojok kanan bawah avatar
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3985E7),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Nama Lengkap User (Dinamis, teks bold sejajar tengah)
            Expanded(
              child: InkWell(
                onTap: () => _navigateTo(const ProfilIbuPage()),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user.name.isNotEmpty
                            ? user.name
                            : 'Susanti Saputri Dewi',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF000000),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // 3. DAFTAR MENU (5 Item Vertikal)
  // -------------------------------------------------------------------------
  Widget _buildMenuList() {
    return Column(
      children: [
        // 1. Profil (person outline -> profil_ibu_page.dart)
        _buildMenuItem(
          icon: Icons.person_outline_rounded,
          title: 'Profil',
          onTap: () => _navigateTo(const ProfilIbuPage()),
        ),

        // 2. Ubah Kata Sandi (key outline -> ubah_password_page.dart)
        _buildMenuItem(
          icon: Icons.vpn_key_outlined,
          title: 'Ubah Kata Sandi',
          onTap: () => _navigateTo(const UbahPasswordPage()),
        ),

        // 3. Tentang Aplikasi (info outline -> tentang_aplikasi_page.dart)
        _buildMenuItem(
          icon: Icons.info_outline_rounded,
          title: 'Tentang Aplikasi',
          onTap: () => _navigateTo(const TentangAplikasiPage()),
        ),

        // 4. Keluar (logout outline -> konfirmasi dialog)
        _buildMenuItem(
          icon: Icons.logout_rounded,
          title: 'Keluar',
          onTap: () => showKeluarLogoutDialog(context),
        ),

        // 5. Syarat dan Ketentuan (document outline -> terms_page.dart)
        _buildMenuItem(
          icon: Icons.description_outlined,
          title: 'Syarat dan Ketentuan',
          onTap: () => _navigateTo(const TermsPage()),
          showDivider: true,
        ),
      ],
    );
  }

  /// Helper untuk membangun satu baris item menu
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            splashColor: const Color(0x1A72A9F4),
            highlightColor: const Color(0x0D72A9F4),
            child: SizedBox(
              height: 54,
              child: Row(
                children: [
                  // Icon Outline sebelah kiri (warna #000000, ukuran 22-24dp)
                  Icon(
                    icon,
                    size: 22,
                    color: const Color(0xFF000000),
                  ),
                  const SizedBox(width: 14),

                  // Label Teks Nama Menu (font Lato reguler 18, warna #000000)
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                        color: const Color(0xFF000000),
                      ),
                    ),
                  ),

                  // Ikon Selanjutnya (>) sebelah kanan
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: Color(0xFF000000),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFF1F5F9),
          ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // 4. NAVIGATION BAR TETAP (68dp, #F2EDED)
  // Warna #F2EDED, tinggi 68dp (range 65-70dp)
  // State aktif (Profil Ibu): icon dengan background lingkaran putih, warna icon biru #72A9F4
  // State tidak aktif: icon & label abu-abu #9E9E9E
  // -------------------------------------------------------------------------
  Widget _buildFixedNavBar() {
    final navItems = [
      _NavigationData(icon: Icons.home_rounded, label: 'Beranda'),
      _NavigationData(
        icon: Icons.question_answer_rounded,
        label: 'Konsultasi',
      ),
      _NavigationData(
        icon: Icons.manage_search_rounded,
        label: 'Riwayat Konsultasi',
      ),
      _NavigationData(
        icon: Icons.person_outline_rounded,
        label: 'Profil Ibu',
      ),
    ];

    return Container(
      width: double.infinity,
      height: 68,
      decoration: const BoxDecoration(
        color: Color(0xFFF2EDED),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(navItems.length, (i) {
          final isSelected = i == _selectedNavIndex;
          final item = navItems[i];

          return GestureDetector(
            onTap: () => _onNavTap(i),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 80,
              height: 68,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected) ...[
                    // State aktif: lingkaran putih dengan icon biru #72A9F4
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        item.icon,
                        size: 24,
                        color: const Color(0xFF72A9F4),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ] else ...[
                    // State tidak aktif: icon & label abu-abu #9E9E9E
                    Icon(
                      item.icon,
                      size: 24,
                      color: const Color(0xFF9E9E9E),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavigationData {
  final IconData icon;
  final String label;

  const _NavigationData({required this.icon, required this.label});
}
