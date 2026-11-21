import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/child_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/user_service.dart';
import '../../models/user_model.dart';
import '../../shared/widgets/pedia_banner.dart';
import '../pengguna/beranda/beranda_page.dart';

/// Halaman onboarding wajib melengkapi profil ibu setelah pendaftaran akun baru.
///
/// Halaman ini TIDAK dapat dilewati — pengguna wajib mengisi data profil
/// sebelum masuk ke Beranda. Alur: Register → LengkapiProfilIbuPage → BerandaPage.
///
/// Gaya visual 100% identik dengan [ProfilIbuPage]:
/// - Warna background AppBar sama dengan isi halaman (seamless, tanpa border pemisah).
/// - Icon input field persis sama dengan profil_ibu_page.dart.
/// - Tombol pill rounded "Simpan dan Masuk ke Beranda".
class LengkapiProfilIbuPage extends StatefulWidget {
  const LengkapiProfilIbuPage({super.key});

  @override
  State<LengkapiProfilIbuPage> createState() => _LengkapiProfilIbuPageState();
}

class _LengkapiProfilIbuPageState extends State<LengkapiProfilIbuPage> {
  static const Color _colorPrimary = Color(0xFF3985E7);

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _birthDateController;
  late TextEditingController _provinceController;
  late TextEditingController _cityController;
  late TextEditingController _districtController;
  late TextEditingController _subDistrictController;
  late TextEditingController _noKkController;
  late TextEditingController _nikController;

  String _selectedGender = 'Perempuan';
  bool _isSaving = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  // ─── Helpers Tema ──────────────────────────────────────────────────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _scaffoldBg => _isDark ? const Color(0xFF0B1014) : Colors.white;

  Color get _fieldBg => _isDark ? const Color(0xFF1A2228) : Colors.white;

  Color get _borderColor =>
      _isDark ? const Color(0xFF2C363D) : const Color(0xFFD1D7DB);

  Color get _iconColor =>
      _isDark ? const Color(0xFF8696A0) : const Color(0xFF667781);

  Color get _hintColor =>
      _isDark ? const Color(0xFF667781) : const Color(0xFF8696A0);

  Color get _textBlack =>
      _isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014);

  Color get _textLabel =>
      _isDark ? const Color(0xFFD1D7DB) : const Color(0xFF2C363D);

  Color get _textGrey =>
      _isDark ? const Color(0xFF8696A0) : const Color(0xFF64748B);

  // ─── Init & Dispose ────────────────────────────────────────────────────────
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
    _noKkController = TextEditingController(text: user.noKk ?? '');
    _nikController = TextEditingController(text: user.nik ?? '');
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
    _noKkController.dispose();
    _nikController.dispose();
    super.dispose();
  }

  // ─── Navigasi ke Beranda ───────────────────────────────────────────────────
  void _navigateToBeranda() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const BerandaPage()),
      (route) => false,
    );
    PediaBanner.showSuccess(
      context,
      message: 'Profil berhasil disimpan! Selamat datang di PediaGrow.',
    );
  }

  // ─── Simpan Profil ─────────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        await UserService().updateProfile(
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
          noKk: _noKkController.text.trim().isNotEmpty
              ? _noKkController.text.trim()
              : null,
          nik: _nikController.text.trim().isNotEmpty
              ? _nikController.text.trim()
              : null,
        );

        if (_noKkController.text.trim().isNotEmpty) {
          ChildService().loadChildrenForCurrentUser();
        }

        if (mounted) {
          setState(() => _isSaving = false);
          _navigateToBeranda();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          PediaBanner.showError(context, message: 'Gagal menyimpan profil: $e');
        }
      }
    } else {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      PediaBanner.showError(
        context,
        message: 'Silakan lengkapi data wajib yang bertanda bintang (*)',
      );
    }
  }

  // ─── Pilih Foto Profil ─────────────────────────────────────────────────────
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isDark ? const Color(0xFF1A2228) : Colors.white,
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
                    color: _isDark
                        ? const Color(0xFF2C363D)
                        : const Color(0xFFD1D7DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ubah Foto Profil',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textBlack,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isDark
                          ? const Color(0xFF1E3A5F)
                          : const Color(0xFFECF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: _colorPrimary,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Ambil Foto dari Kamera',
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textBlack,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                Divider(
                  height: 1,
                  color: _isDark
                      ? const Color(0xFF2C363D)
                      : const Color(0xFFE9EDEF),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isDark
                          ? const Color(0xFF1E3A5F)
                          : const Color(0xFFECF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: _colorPrimary,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Pilih Foto dari Galeri',
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textBlack,
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
          PediaBanner.showSuccess(
            context,
            message: 'Foto profil berhasil diperbarui',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        PediaBanner.showError(context, message: 'Gagal memilih foto: $e');
      }
    }
  }

  // ─── Pilih Tanggal Lahir ───────────────────────────────────────────────────
  Future<void> _pickBirthDate() async {
    DateTime initialDate = DateTime(1995, 5, 15);
    if (_birthDateController.text.isNotEmpty) {
      try {
        final parts = _birthDateController.text.split('/');
        if (parts.length == 3) {
          initialDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
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
              primary: _colorPrimary,
              onPrimary: Colors.white,
              onSurface: Color(0xFF0B1014),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _colorPrimary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthDateController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Tidak bisa di-pop — pengguna harus mengisi profil terlebih dahulu
      canPop: false,
      child: Scaffold(
        backgroundColor: _scaffoldBg,
        body: SafeArea(
          child: Column(
            children: [
              // AppBar custom — warna sama dengan scaffold, tanpa border pemisah
              _buildAppBar(),

              // Form scrollable
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _autovalidateMode,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Avatar
                        _buildAvatarSection(),
                        const SizedBox(height: 18),

                        // 2. Nama Pengguna (Terkunci dari Pendaftaran)
                        _buildTextField(
                          controller: _nameController,
                          label: 'Nama Pengguna',
                          hint: 'Masukkan nama pengguna',
                          prefixIcon: Icons.person_outline_rounded,
                          readOnly: true,
                          isRequired: false,
                        ),
                        const SizedBox(height: 14),

                        // 3. Email (Terkunci dari Pendaftaran)
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'contoh@gmail.com',
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          readOnly: true,
                          isRequired: false,
                        ),
                        const SizedBox(height: 14),

                        // 4. Nomor KK*
                        _buildTextField(
                          controller: _noKkController,
                          label: 'Nomor Kartu Keluarga (KK)',
                          hint: '16 digit Nomor Kartu Keluarga',
                          prefixIcon: Icons.family_restroom_rounded,
                          keyboardType: TextInputType.number,
                          maxLength: 16,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(16),
                          ],
                          isRequired: true,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Nomor KK tidak boleh kosong';
                            }
                            if (val.trim().length != 16) {
                              return 'Nomor KK harus 16 digit angka';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // 5. NIK*
                        _buildTextField(
                          controller: _nikController,
                          label: 'NIK (Nomor Induk Kependudukan)',
                          hint: '16 digit NIK Orang Tua',
                          prefixIcon: Icons.badge_outlined,
                          keyboardType: TextInputType.number,
                          maxLength: 16,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(16),
                          ],
                          isRequired: true,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'NIK tidak boleh kosong';
                            }
                            if (val.trim().length != 16) {
                              return 'NIK harus 16 digit angka';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // 6. Jenis Kelamin*
                        _buildGenderRadioSection(),
                        const SizedBox(height: 14),

                        // 7. Tanggal Lahir*
                        _buildDateField(
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

                        // 8. Provinsi*
                        _buildTextField(
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

                        // 9. Kota / Kabupaten*
                        _buildTextField(
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

                        // 10. Kecamatan
                        _buildTextField(
                          controller: _districtController,
                          label: 'Kecamatan',
                          hint: 'Masukkan kecamatan',
                          prefixIcon: Icons.place_outlined,
                          isRequired: false,
                        ),
                        const SizedBox(height: 14),

                        // 11. Kelurahan / Desa
                        _buildTextField(
                          controller: _subDistrictController,
                          label: 'Kelurahan/ Desa',
                          hint: 'Masukkan kelurahan/ desa',
                          prefixIcon: Icons.holiday_village_outlined,
                          isRequired: false,
                        ),
                        const SizedBox(height: 28),

                        // Tombol Simpan
                        _buildSaveButton(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── AppBar ────────────────────────────────────────────────────────────────
  /// AppBar tanpa border pemisah, background sama persis dengan Scaffold.
  Widget _buildAppBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      // Tidak ada BoxDecoration border — seamless dengan isi halaman
      color: _scaffoldBg,
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text(
            'Profil',
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textBlack,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Avatar Section ────────────────────────────────────────────────────────
  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          ValueListenableBuilder<UserModel>(
            valueListenable: UserService().currentUserNotifier,
            builder: (context, user, _) {
              final imageProvider = StorageService.buildImageProvider(
                user.avatarPath,
              );
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
                        color: _isDark
                            ? const Color(0xFF1A2228)
                            : const Color(0xFFE9EDEF),
                        border: Border.all(
                          color: _isDark
                              ? const Color(0xFF2C363D)
                              : const Color(0xFFE9EDEF),
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
                              color: _isDark
                                  ? const Color(0xFF667781)
                                  : const Color(0xFF8696A0),
                            ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _colorPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isDark
                                ? const Color(0xFF0B1014)
                                : Colors.white,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _colorPrimary.withValues(alpha: 0.3),
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
                color: _colorPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Jenis Kelamin Radio ───────────────────────────────────────────────────
  Widget _buildGenderRadioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Jenis Kelamin', isRequired: true),
        const SizedBox(height: 6),
        Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [
            _buildGenderOption('Laki-laki', _colorPrimary),
            _buildGenderOption('Perempuan', const Color(0xFFEC4899)),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String value, Color activeColor) {
    final isSelected = _selectedGender == value;
    return InkWell(
      onTap: () => setState(() => _selectedGender = value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? activeColor : _borderColor,
                  width: isSelected ? 6.5 : 1.5,
                ),
                color: _isDark ? const Color(0xFF1A2228) : Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              value,
              style: GoogleFonts.lato(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? _textBlack : _textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Date Field ────────────────────────────────────────────────────────────
  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isRequired,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isRequired: isRequired),
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
                color: _textBlack,
              ),
              decoration: _inputDecoration(
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

  // ─── Text Field ────────────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    bool isRequired = false,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isRequired: isRequired),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: readOnly ? _textGrey : _textBlack,
          ),
          decoration: _inputDecoration(
            hint: hint,
            prefixIcon: prefixIcon,
            readOnly: readOnly,
          ).copyWith(counterText: maxLength != null ? '' : null),
          validator: validator,
        ),
      ],
    );
  }

  // ─── Label ─────────────────────────────────────────────────────────────────
  Widget _buildLabel(String label, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: GoogleFonts.lato(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _textLabel,
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

  // ─── Input Decoration ──────────────────────────────────────────────────────
  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    IconData? suffixIcon,
    bool readOnly = false,
  }) {
    final fieldFillColor = readOnly
        ? (_isDark ? const Color(0xFF141C22) : const Color(0xFFF1F5F9))
        : _fieldBg;
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.lato(fontSize: 14, color: _hintColor),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      prefixIcon: Icon(prefixIcon, size: 20, color: _iconColor),
      suffixIcon: readOnly
          ? Icon(Icons.lock_outline_rounded, size: 18, color: _iconColor)
          : (suffixIcon != null
              ? Icon(suffixIcon, size: 20, color: _iconColor)
              : null),
      filled: true,
      fillColor: fieldFillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: readOnly ? _borderColor : _colorPrimary,
          width: readOnly ? 1.0 : 1.5,
        ),
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

  // ─── Tombol Simpan ─────────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: _colorPrimary,
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
                'Simpan dan Masuk ke Beranda',
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
