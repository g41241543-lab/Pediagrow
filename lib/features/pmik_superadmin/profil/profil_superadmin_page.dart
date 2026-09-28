import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/staff_auth_service.dart';
import '../../auth/auth_choice_page.dart';
import '../beranda/beranda_superadmin_page.dart';
import '../konsultasi/konsultasi_superadmin_page.dart';
import '../riwayat_konsultasi/daftar_riwayat_konsultasi_admin_page.dart';
import 'hak_akses/hak_akses_page.dart';
import '../../../models/staff_account_model.dart';
import '../beranda/staff_home_placeholder_page.dart';

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
      if (_superadmin?.avatarPath != null && _superadmin!.avatarPath!.isNotEmpty) {
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

  // ---------------------------------------------------------------------------
  // PEMILIH FOTO PROFIL (KAMERA / GALERI)
  // ---------------------------------------------------------------------------
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
                    color: const Color(0xFF0F172A),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
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
        setState(() {
          _superadminAvatarPath = pickedFile.path;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('superadmin_avatar_path', pickedFile.path);

        final staffId = StaffAuthService().currentStaff?.id;
        if (staffId != null && staffId.isNotEmpty) {
          await StaffAuthService().updateAvatar(staffId, pickedFile.path);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Foto profil Superadmin berhasil diperbarui',
                style: GoogleFonts.lato(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memilih foto: $e',
              style: GoogleFonts.lato(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Widget _buildModalField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 13.0,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6.0),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.lato(fontSize: 14.5, color: const Color(0xFF0F172A)),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Color(0xFF3985E7)),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  void _showEditSuperadminDialog() {
    final formKey = GlobalKey<FormState>();
    final superadmin = _superadmin;

    final nameCtrl = TextEditingController(
      text: superadmin?.name.isNotEmpty == true
          ? superadmin!.name
          : 'Anita Setyowati, S.Tr. RMIK',
    );
    final emailCtrl = TextEditingController(
      text: superadmin?.email.isNotEmpty == true
          ? superadmin!.email
          : 'superadmin@pediagrow.com',
    );
    final passwordCtrl = TextEditingController();
    bool obscurePassword = true;

    final rawExp = superadmin?.experience ?? '7 tahun';
    final expDigits = RegExp(r'\d+').stringMatch(rawExp) ?? rawExp;
    final expCtrl = TextEditingController(text: expDigits);

    final strCtrl = TextEditingController(
      text: superadmin?.strNumber ?? '3511201402012222',
    );
    final birthDateCtrl = TextEditingController(
      text: superadmin?.birthDate ?? '16/07/2006',
    );
    final eduCtrl = TextEditingController(
      text: superadmin?.education ?? 'DIV - Manajemen Informasi Kesehatan',
    );

    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 16.0,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24.0,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40.0,
                          height: 4.0,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(2.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Edit Profil & Akun Superadmin',
                            style: GoogleFonts.lato(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: Color(0xFF64748B)),
                            onPressed: () => Navigator.of(bottomSheetCtx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),

                      _buildModalField(
                        label: 'Nama Lengkap',
                        controller: nameCtrl,
                        icon: Icons.person_outline_rounded,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Nama tidak boleh kosong'
                            : null,
                      ),
                      const SizedBox(height: 12.0),

                      _buildModalField(
                        label: 'Email (Digunakan untuk Login)',
                        controller: emailCtrl,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          if (!v.contains('@') || !v.contains('.')) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12.0),

                      Text(
                        'Kata Sandi / Password Baru (Opsional)',
                        style: GoogleFonts.lato(
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      TextFormField(
                        controller: passwordCtrl,
                        obscureText: obscurePassword,
                        style: GoogleFonts.lato(fontSize: 14.5),
                        decoration: InputDecoration(
                          hintText:
                              'Kosongkan jika tidak ingin mengubah password',
                          hintStyle: GoogleFonts.lato(
                            fontSize: 13.0,
                            color: const Color(0xFF94A3B8),
                          ),
                          prefixIcon: const Icon(Icons.lock_outline_rounded,
                              size: 20, color: Color(0xFF64748B)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 20,
                              color: const Color(0xFF94A3B8),
                            ),
                            onPressed: () {
                              setModalState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14.0, vertical: 12.0),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide:
                                const BorderSide(color: Color(0xFF3985E7)),
                          ),
                        ),
                        validator: (v) {
                          if (v != null && v.isNotEmpty && v.length < 6) {
                            return 'Password minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12.0),

                      Row(
                        children: [
                          Expanded(
                            child: _buildModalField(
                              label: 'Pengalaman (Tahun)',
                              controller: expCtrl,
                              icon: Icons.work_outline_rounded,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: _buildModalField(
                              label: 'No. STR',
                              controller: strCtrl,
                              icon: Icons.badge_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),

                      Text(
                        'Tanggal Lahir',
                        style: GoogleFonts.lato(
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      TextFormField(
                        controller: birthDateCtrl,
                        readOnly: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2000, 1, 1),
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            final formatted =
                                '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                            setModalState(() {
                              birthDateCtrl.text = formatted;
                            });
                          }
                        },
                        style: GoogleFonts.lato(fontSize: 14.5),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.cake_outlined,
                              size: 20, color: Color(0xFF64748B)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14.0, vertical: 12.0),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide:
                                const BorderSide(color: Color(0xFF3985E7)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12.0),

                      _buildModalField(
                        label: 'Pendidikan',
                        controller: eduCtrl,
                        icon: Icons.school_outlined,
                      ),
                      const SizedBox(height: 24.0),

                      SizedBox(
                        width: double.infinity,
                        height: 48.0,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setModalState(() => isSubmitting = true);
                                  try {
                                    final currentAcc = _superadmin ??
                                        await StaffAuthService()
                                            .getSuperadminAccount();
                                    if (currentAcc == null ||
                                        currentAcc.id.isEmpty) {
                                      throw Exception(
                                          'Akun Superadmin belum terdata di sistem.');
                                    }

                                    await StaffAuthService().updateStaffAccount(
                                      currentAcc.id,
                                      name: nameCtrl.text.trim(),
                                      email:
                                          emailCtrl.text.trim().toLowerCase(),
                                      password:
                                          passwordCtrl.text.trim().isNotEmpty
                                              ? passwordCtrl.text.trim()
                                              : null,
                                      experience: expCtrl.text.trim().isNotEmpty
                                          ? '${expCtrl.text.trim()} tahun'
                                          : null,
                                      strNumber: strCtrl.text.trim().isNotEmpty
                                          ? strCtrl.text.trim()
                                          : null,
                                      birthDate:
                                          birthDateCtrl.text.trim().isNotEmpty
                                              ? birthDateCtrl.text.trim()
                                              : null,
                                      education: eduCtrl.text.trim().isNotEmpty
                                          ? eduCtrl.text.trim()
                                          : null,
                                    );

                                    await _loadSuperadminData();

                                    if (!mounted) return;
                                    Navigator.of(bottomSheetCtx).pop();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Profil & kredensial Superadmin berhasil diperbarui.',
                                          style: GoogleFonts.lato(
                                              fontWeight: FontWeight.w600),
                                        ),
                                        backgroundColor:
                                            const Color(0xFF16A34A),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                    );
                                  } catch (e) {
                                    setModalState(() => isSubmitting = false);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Gagal menyimpan: $e'),
                                        backgroundColor:
                                            const Color(0xFFDC2626),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3985E7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            elevation: 0,
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  'Simpan Perubahan',
                                  style: GoogleFonts.lato(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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

    final staff = StaffAuthService().currentStaff;
    if (index == 1 && staff != null && !staff.hasPermission('konsultasi')) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Akses fitur "Konsultasi" dinonaktifkan oleh Superadmin.',
            style: GoogleFonts.lato(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (index == 2 && staff != null && !staff.hasPermission('riwayat_konsultasi')) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Akses fitur "Riwayat Konsultasi" dinonaktifkan oleh Superadmin.',
            style: GoogleFonts.lato(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
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
      pageBuilder: (_, __, ___) => targetPage,
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
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
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

              // 4. TOMBOL EDIT PROFIL & KREDENSIAL AKUN (Warna Biru PediaGrow #3985E7)
              SizedBox(
                height: 50.0,
                child: ElevatedButton.icon(
                  onPressed: _showEditSuperadminDialog,
                  icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 22),
                  label: Text(
                    'EDIT PROFIL & AKUN',
                    style: GoogleFonts.lato(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3985E7),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12.0),

              // 5. TOMBOL HAK AKSES (Warna Toska #38C1A2) jika Superadmin / memiliki izin hak_akses
              if (_superadmin?.isSuperAdmin == true ||
                  StaffAuthService().currentStaff?.isSuperAdmin == true ||
                  StaffAuthService().currentStaff?.hasPermission('hak_akses') == true) ...[
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
              ] else if (_superadmin != null) ...[
                SizedBox(
                  height: 50.0,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StaffHomePlaceholderPage(
                            account: _superadmin!,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.security_rounded,
                      color: Color(0xFF38C1A2),
                      size: 20,
                    ),
                    label: Text(
                      'DETAIL HAK AKSES SAYA',
                      style: GoogleFonts.lato(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: const Color(0xFF38C1A2),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF38C1A2), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
              ],

              // 6. TOMBOL LOGOUT (Warna Merah #DC2626)
              SizedBox(
                height: 50.0,
                child: OutlinedButton(
                  onPressed: _showLogoutConfirmationDialog,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
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
                      color: const Color(0xFFDC2626),
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
  /// Judul "Profil" terletak tepat 16dp dari pojok layar kiri (tanpa tombol back).
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
            child: Align(
              alignment: Alignment.centerLeft,
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
                _superadmin?.name.isNotEmpty == true
                    ? _superadmin!.name
                    : 'Anita Setyowati, S.Tr. RMIK',
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
                _superadmin?.pmikRoleDisplay ?? 'PMIK (SUPER ADMIN)',
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
                _superadmin?.email.isNotEmpty == true
                    ? _superadmin!.email
                    : 'superadmin@pediagrow.com',
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
                        Container(
                          width: 36.0,
                          height: 36.0,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.work_rounded,
                            size: 20.0,
                            color: Color(0xFF2563EB),
                          ),
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
                                _superadmin?.experience ?? '7 tahun',
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
                        Container(
                          width: 36.0,
                          height: 36.0,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.badge_rounded,
                            size: 20.0,
                            color: Color(0xFF10B981),
                          ),
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
                                _superadmin?.strNumber ?? '3511201402012222',
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

        // Tombol Edit di pojok kanan atas kartu
        Positioned(
          top: avatarRadius + 6.0,
          right: 6.0,
          child: IconButton(
            onPressed: _showEditSuperadminDialog,
            icon: const Icon(
              Icons.edit_outlined,
              color: Color(0xFF64748B),
              size: 20.0,
            ),
            tooltip: 'Edit Profil & Akun',
          ),
        ),

        // Avatar Bulat melayang di posisi atas dengan badge kamera
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
                    child: _buildSuperadminAvatarImage(),
                  ),
                ),

                // Badge Kamera di pojok kanan bawah (Gaya standar Profil Ibu)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 30.0,
                    height: 30.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3985E7),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.2),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF3985E7).withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 15.0,
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
    if (_superadminAvatarPath != null && _superadminAvatarPath!.isNotEmpty) {
      if (File(_superadminAvatarPath!).existsSync()) {
        return Image.file(
          File(_superadminAvatarPath!),
          fit: BoxFit.cover,
        );
      }
      if (_superadminAvatarPath!.startsWith('http')) {
        return Image.network(
          _superadminAvatarPath!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackAvatar(),
        );
      }
    }
    return Image.asset(
      'assets/images/anita_superadmin.jpg',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      color: const Color(0xFFE2E8F0),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_rounded,
        size: 52.0,
        color: Color(0xFF72A9F4),
      ),
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
                Container(
                  width: 40.0,
                  height: 40.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.cake_rounded,
                    size: 22.0,
                    color: Color(0xFFF43F5E),
                  ),
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
                        _superadmin?.birthDate ?? '16/07/2006',
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
                Container(
                  width: 40.0,
                  height: 40.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.school_rounded,
                    size: 22.0,
                    color: Color(0xFF8B5CF6),
                  ),
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
                        _superadmin?.education ??
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
