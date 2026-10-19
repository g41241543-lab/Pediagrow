<<<<<<< HEAD
﻿import 'dart:async';
=======
import 'dart:async';
>>>>>>> 289e71df0313336a1855296b39040c36eaa51608

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/storage_service.dart';
import '../../../core/services/user_service.dart';
import '../../../models/user_model.dart';
import 'menu_profil_page.dart';
import '../../../shared/widgets/pedia_banner.dart';

/// Halaman Detail / Edit Profil Pengguna (Profil Ibu / Profil Anda) PediaGrow.
///
/// Menyajikan form profil lengkap 9 elemen sesuai desain Figma:
/// 1. Avatar foto profil dengan camera badge bulat biru & link "Ubah Foto Profil"
/// 2. Nama Pengguna* (auto-fill dari data registrasi pengguna, wajib)
/// 3. Email* (auto-fill dari data akun pengguna, validasi format email, wajib)
/// 4. Jenis Kelamin* (radio button horizontal "Laki-laki" dan "Perempuan", wajib)
/// 5. Tanggal Lahir Anda* (date picker bawaan Flutter, format DD/MM/YYYY, wajib)
/// 6. Provinsi* (text field, wajib)
/// 7. Kota/ Kabupaten* (text field, wajib)
/// 8. Kecamatan (text field, opsional)
/// 9. Kelurahan/ Desa (text field, opsional)
///
/// Komponen mempertahankan gaya visual rounded border, interaktif error border,
/// tombol pill rounded "Simpan Perubahan", serta tata letak compact untuk smartphone Android.
class ProfilIbuPage extends StatefulWidget {
  const ProfilIbuPage({super.key});

  @override
  State<ProfilIbuPage> createState() => _ProfilIbuPageState();
}

class _ProfilIbuPageState extends State<ProfilIbuPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _birthDateController;
  late TextEditingController _provinceController;
  late TextEditingController _cityController;
  late TextEditingController _districtController;
  late TextEditingController _subDistrictController;

  String _selectedGender = 'Perempuan';
  bool _isSaving = false;

  bool _isSuccessBannerVisible = false;
  Timer? _bannerTimer;
  String _successBannerMessage = 'Berhasil Memperbarui Foto Profil';
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    final user = UserService().currentUser;

    _nameController = TextEditingController(text: user.name);
    _emailController = TextEditingController(text: user.email);
    _birthDateController = TextEditingController(text: user.birthDate ?? '');
    _provinceController = TextEditingController(text: user.province ?? '');
    _cityController = TextEditingController(text: user.city ?? '');
    _districtController = TextEditingController(text: user.district ?? '');
    _subDistrictController = TextEditingController(
      text: user.subDistrict ?? '',
    );

    if (user.gender != null && user.gender!.isNotEmpty) {
      _selectedGender = user.gender!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _subDistrictController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _triggerSuccessBanner(String message) {
    _bannerTimer?.cancel();
    setState(() {
      _successBannerMessage = message;
    });

    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      setState(() {
        _isSuccessBannerVisible = true;
      });

      // Banner otomatis menghilang setelah durasi 1 menit
      _bannerTimer = Timer(const Duration(minutes: 1), () {
        _hideSuccessBanner();
      });
    });
  }

  void _hideSuccessBanner() {
    _bannerTimer?.cancel();
    if (mounted && _isSuccessBannerVisible) {
      setState(() {
        _isSuccessBannerVisible = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // PEMILIH FOTO PROFIL (KAMERA / GALERI)
  // ---------------------------------------------------------------------------
  void _showImagePickerOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A2228) : Colors.white,
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
                    color: isDark ? const Color(0xFF2C363D) : const Color(0xFFD1D7DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ubah Foto Profil',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFECF6FF),
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
                      color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFECF6FF),
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
                      color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014),
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
        await UserService().updateAvatar(pickedFile.path);

        if (mounted) {
          _triggerSuccessBanner('Berhasil Memperbarui Foto Profil');
        }
      }
    } catch (e) {
      if (mounted) {
        PediaBanner.showError(
          context,
          message: 'Gagal memilih gambar: $e',
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // PEMILIH TANGGAL LAHIR (DATE PICKER)
  // ---------------------------------------------------------------------------
  Future<void> _pickBirthDate() async {
    DateTime initialDate = DateTime(1995, 5, 15);

    if (_birthDateController.text.isNotEmpty) {
      try {
        final parts = _birthDateController.text.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          initialDate = DateTime(year, month, day);
        }
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3985E7),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0B1014),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF3985E7),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final day = picked.day.toString().padLeft(2, '0');
      final month = picked.month.toString().padLeft(2, '0');
      final year = picked.year.toString();
      setState(() {
        _birthDateController.text = '$day/$month/$year';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // SIMPAN PERUBAHAN
  // ---------------------------------------------------------------------------
  void _saveProfile() {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      UserService().updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        gender: _selectedGender,
        birthDate: _birthDateController.text.trim(),
        province: _provinceController.text.trim(),
        city: _cityController.text.trim(),
        district: _districtController.text.trim().isNotEmpty
            ? _districtController.text.trim()
            : null,
        subDistrict: _subDistrictController.text.trim().isNotEmpty
            ? _subDistrictController.text.trim()
            : null,
      );

      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() => _isSaving = false);

        // Kembali ke MenuProfilPage dengan membawa flag sukses (true)
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const MenuProfilPage(showSuccessBanner: true),
            ),
          );
        }
      });
    } else {
      // Aktifkan autovalidasi hanya setelah tombol Simpan Perubahan diklik
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1014) : Colors.white,
      body: SafeArea(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                // Header bar tetap (56dp)
                _buildAppBar(isDark),

                // Konten form scrollable dan adaptif terhadap keyboard Android
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 14.0,
                    ),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _autovalidateMode,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Avatar foto profil & Ubah Foto Profil
                          _buildAvatarSection(isDark),
                          const SizedBox(height: 18),

                          // 2. Nama Pengguna*
                          _buildTextField(
                            isDark: isDark,
                            controller: _nameController,
                            label: 'Nama Pengguna',
                            hint: 'Masukkan nama pengguna',
                            prefixIcon: Icons.person_outline_rounded,
                            isRequired: true,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Nama pengguna tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // 3. Email*
                          _buildTextField(
                            isDark: isDark,
                            controller: _emailController,
                            label: 'Email',
                            hint: 'contoh@gmail.com',
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            isRequired: true,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Email tidak boleh kosong';
                              }
                              final emailRegex = RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                              );
                              if (!emailRegex.hasMatch(val.trim())) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // 4. Jenis Kelamin*
                          _buildGenderRadioSection(isDark),
                          const SizedBox(height: 14),

                          // 5. Tanggal Lahir Anda*
                          _buildDateField(
                            isDark: isDark,
                            controller: _birthDateController,
                            label: 'Tanggal Lahir Anda',
                            hint: 'DD/MM/YYYY',
                            isRequired: true,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Tanggal lahir tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // 6. Provinsi*
                          _buildTextField(
                            isDark: isDark,
                            controller: _provinceController,
                            label: 'Provinsi',
                            hint: 'Masukkan provinsi',
                            prefixIcon: Icons.map_outlined,
                            isRequired: true,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Provinsi tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // 7. Kota/ Kabupaten*
                          _buildTextField(
                            isDark: isDark,
                            controller: _cityController,
                            label: 'Kota/ Kabupaten',
                            hint: 'Masukkan kota/ kabupaten',
                            prefixIcon: Icons.location_city_outlined,
                            isRequired: true,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Kota/ Kabupaten tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // 8. Kecamatan
                          _buildTextField(
                            isDark: isDark,
                            controller: _districtController,
                            label: 'Kecamatan',
                            hint: 'Masukkan kecamatan',
                            prefixIcon: Icons.place_outlined,
                            isRequired: false,
                          ),
                          const SizedBox(height: 14),

                          // 9. Kelurahan/ Desa
                          _buildTextField(
                            isDark: isDark,
                            controller: _subDistrictController,
                            label: 'Kelurahan/ Desa',
                            hint: 'Masukkan kelurahan/ desa',
                            prefixIcon: Icons.holiday_village_outlined,
                            isRequired: false,
                          ),
                          const SizedBox(height: 28),

                          // Tombol Simpan Perubahan
                          _buildSaveButton(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Success banner overlay
            _buildSuccessBanner(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUCCESS BANNER OVERLAY
  // ---------------------------------------------------------------------------
  Widget _buildSuccessBanner() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      top: _isSuccessBannerVisible ? 62.0 : -70.0,
      left: 16.0,
      right: 16.0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _isSuccessBannerVisible ? 1.0 : 0.0,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: const Color(0xFF3985E7),
            borderRadius: BorderRadius.circular(17),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3985E7).withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _successBannerMessage,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ),
              InkWell(
                onTap: _hideSuccessBanner,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.close, size: 20, color: Color(0xFF000000)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // APPBAR DENGAN TOMBOL KEMBALI
  // ---------------------------------------------------------------------------
  Widget _buildAppBar(bool isDark) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1014) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.arrow_back,
                color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Profil Anda',
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AVATAR SECTION DENGAN CAMERA BADGE
  // ---------------------------------------------------------------------------
  Widget _buildAvatarSection(bool isDark) {
    return Center(
      child: Column(
        children: [
          ValueListenableBuilder<UserModel>(
            valueListenable: UserService().currentUserNotifier,
            builder: (context, user, _) {
              final imageProvider = StorageService.buildImageProvider(user.avatarPath);
              final hasCustom = imageProvider != null;

              return GestureDetector(
                onTap: _showImagePickerOptions,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF1A2228) : const Color(0xFFE9EDEF),
                        border: Border.all(
                           color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF),
                           width: 2,
                        ),
                        image: hasCustom
                            ? DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: hasCustom
                          ? null
                          : Icon(
                              Icons.person_rounded,
                              size: 54,
                              color: isDark ? const Color(0xFF667781) : const Color(0xFF8696A0),
                            ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3985E7),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF0B1014) : Colors.white,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3985E7).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: _showImagePickerOptions,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Ubah Foto Profil',
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3985E7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RADIO BUTTON HORIZONTAL JENIS KELAMIN
  // ---------------------------------------------------------------------------
  Widget _buildGenderRadioSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Jenis Kelamin', isRequired: true, isDark: isDark),
        const SizedBox(height: 6),
        Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [
<<<<<<< HEAD
            _buildGenderOption('Laki-laki', const Color(0xFF3985E7), isDark),
            const SizedBox(width: 24),
            _buildGenderOption('Perempuan', const Color(0xFFEC4899), isDark),
=======
            _buildGenderOption('Laki-laki', const Color(0xFF3985E7)),
            _buildGenderOption('Perempuan', const Color(0xFFEC4899)),
>>>>>>> 289e71df0313336a1855296b39040c36eaa51608
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String value, Color activeColor, bool isDark) {
    final isSelected = _selectedGender == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedGender = value;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? activeColor : (isDark ? const Color(0xFF2C363D) : const Color(0xFFD1D7DB)),
                  width: isSelected ? 6.5 : 1.5,
                ),
                color: isDark ? const Color(0xFF1A2228) : Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              value,
              style: GoogleFonts.lato(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? (isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014))
                    : (isDark ? const Color(0xFF8696A0) : const Color(0xFF2C363D)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INPUT TANGGAL LAHIR (WITH DATE PICKER)
  // ---------------------------------------------------------------------------
  Widget _buildDateField({
    required bool isDark,
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isRequired,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isRequired: isRequired, isDark: isDark),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickBirthDate,
          child: AbsorbPointer(
            child: TextFormField(
              controller: controller,
              readOnly: true,
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014),
              ),
              decoration: _inputDecoration(
                isDark: isDark,
                hint: hint,
                prefixIcon: Icons.calendar_month_outlined,
                suffixIcon: Icons.arrow_drop_down,
              ),
              validator: validator,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // INPUT TEXT FORM FIELD UMUM
  // ---------------------------------------------------------------------------
  Widget _buildTextField({
    required bool isDark,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isRequired: isRequired, isDark: isDark),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014),
          ),
          decoration: _inputDecoration(isDark: isDark, hint: hint, prefixIcon: prefixIcon),
          validator: validator,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // LABEL DENGAN ASTERISK MERAH
  // ---------------------------------------------------------------------------
  Widget _buildLabel(String label, {bool isRequired = false, bool isDark = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: GoogleFonts.lato(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFD1D7DB) : const Color(0xFF2C363D),
        ),
        children: isRequired
            ? [
                TextSpan(
                  text: ' *',
                  style: GoogleFonts.lato(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]
            : [],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DEKORASI INPUT FORM BORDERED ROUNDED
  // ---------------------------------------------------------------------------
  InputDecoration _inputDecoration({
    required bool isDark,
    required String hint,
    required IconData prefixIcon,
    IconData? suffixIcon,
  }) {
    final fieldBg = isDark ? const Color(0xFF1A2228) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C363D) : const Color(0xFFD1D7DB);
    final iconColor = isDark ? const Color(0xFF8696A0) : const Color(0xFF667781);
    final hintColor = isDark ? const Color(0xFF667781) : const Color(0xFF8696A0);
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.lato(fontSize: 14, color: hintColor),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      prefixIcon: Icon(prefixIcon, size: 20, color: iconColor),
      suffixIcon: suffixIcon != null
          ? Icon(suffixIcon, size: 20, color: iconColor)
          : null,
      filled: true,
      fillColor: fieldBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3985E7), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      errorStyle: GoogleFonts.lato(
        fontSize: 12,
        color: const Color(0xFFEF4444),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUTTON SIMPAN PERUBAHAN
  // ---------------------------------------------------------------------------
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3985E7),
          disabledBackgroundColor: const Color(0xFF93C5FD),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                'Simpan Perubahan',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
