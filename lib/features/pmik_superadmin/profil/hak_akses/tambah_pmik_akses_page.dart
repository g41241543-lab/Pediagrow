import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/local_push_service.dart';
import '../../../../core/services/staff_auth_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../models/doctor_permissions.dart';
import '../../../../models/staff_account_model.dart';
import 'widgets/pendidikan_triplet_input.dart';

/// Halaman Tambah Profil PMIK untuk Superadmin PediaGrow.
///
/// Mengacu persis pada desain referensi:
/// - Header 56dp dengan tombol Back dan Judul "Profil" / "Tambah Profil PMIK"
/// - Card Profil:
///   * Unggah Foto (kamera & galeri gaya profil ibu)
///   * Input Nama PMIK
///   * Badge PMIK (otomatis menjadi "PMIK (SUPER ADMIN)" jika Hak Akses aktif)
///   * Input E-mail
///   * Pengalaman (hanya angka + teks 'tahun' tetap) & No. STR (hanya angka)
/// - Informasi Umum: Tanggal Lahir (DatePicker) & Pendidikan
/// - Hak Akses: 16 Switches kontrol akses fitur
/// - Tombol Simpan (Biru #3985E7)
class TambahPmikAksesPage extends StatefulWidget {
  final String createdByEmail;

  const TambahPmikAksesPage({
    super.key,
    required this.createdByEmail,
  });

  @override
  State<TambahPmikAksesPage> createState() => _TambahPmikAksesPageState();
}

class _TambahPmikAksesPageState extends State<TambahPmikAksesPage> {
  final _formKey = GlobalKey<FormState>();
  final StaffAuthService _staffAuthService = StaffAuthService();
  final ImagePicker _picker = ImagePicker();

  // Form Controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _experienceCtrl = TextEditingController();
  final TextEditingController _strCtrl = TextEditingController();
  final EducationEntry _educationEntry = EducationEntry();
  final TextEditingController _birthDateCtrl = TextEditingController();

  String? _selectedImagePath;
  bool _isSaving = false;

  // Daftar informasi umum dinamis tambahan (jika ditambah via tombol +)
  final List<MapEntry<String, String>> _extraInfoList = [];

  // 16 Hak Akses state (default mengikuti gambar referensi PMIK)
  late Map<String, bool> _permissions;

  @override
  void initState() {
    super.initState();
    _initDefaultPermissions();
  }

  void _initDefaultPermissions() {
    _permissions = {
      'rekapitulasi': true,
      'download_dataset_rekapitulasi': false,
      'data_pasien': true,
      'detail_pasien': true,
      'edit_resume_medis': false,
      'ruang_obrolan': false,
      'daftar_resep_mpasi': true,
      'edit_resep_mpasi': true,
      'daftar_artikel_kesehatan': true,
      'edit_artikel_kesehatan': true,
      'grafik_pengguna': true,
      'download_dataset_pengguna': false,
      'permainan': true,
      'konsultasi': true,
      'konfirmasi_konsultasi': false,
      'riwayat_konsultasi': true,
      'profil': true,
      'hak_akses': false, // Ketika true, otomatis jadi PMIK (SUPER ADMIN)
    };
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _experienceCtrl.dispose();
    _strCtrl.dispose();
    _educationEntry.dispose();
    _birthDateCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // IMAGE PICKER (Gaya Profil Ibu POV Pengguna)
  // ---------------------------------------------------------------------------
  // ---------------------------------------------------------------------------
  // IMAGE PICKER (Gaya Profil Ibu POV Pengguna)
  // ---------------------------------------------------------------------------
  void _showImagePickerOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1A2228) : Colors.white;
    final handleColor = isDark ? const Color(0xFF2C363D) : const Color(0xFFD1D7DB);
    final textPrimary = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000);
    final iconBg = isDark ? const Color(0xFF3985E7).withValues(alpha: 0.15) : const Color(0xFFECF6FF);
    final dividerColor = isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
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
                    color: handleColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ubah Foto Profil PMIK',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBg,
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
                      color: textPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                Divider(height: 1, color: dividerColor),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBg,
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
                      color: textPrimary,
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
          _selectedImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        LocalPushService().show(
          title: 'Peringatan',
          body: 'Gagal memilih foto: $e',
          targetRole: PushRole.superadmin,
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // DATE PICKER TANGGAL LAHIR
  // ---------------------------------------------------------------------------
  Future<void> _selectBirthDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final initialDate = DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF3985E7),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1A2228),
                    onSurface: Color(0xFFE9EDEF),
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF3985E7),
                    onPrimary: Colors.white,
                    onSurface: Color(0xFF1A2228),
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      setState(() {
        _birthDateCtrl.text = formatted;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // DIALOG TAMBAH INFORMASI UMUM DINAMIS
  // ---------------------------------------------------------------------------
  void _showAddExtraInfoDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleCtrl = TextEditingController();
    final valueCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A2228) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Tambah Informasi Umum',
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: GoogleFonts.lato(
                color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228),
              ),
              decoration: InputDecoration(
                labelText: 'Judul Informasi',
                hintText: 'Contoh: Alamat Domisili',
                labelStyle: GoogleFonts.lato(color: const Color(0xFF8696A0)),
                hintStyle: GoogleFonts.lato(color: const Color(0xFF8696A0)),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF3985E7)),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF2C363D) : const Color(0xFFD1D7DB),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueCtrl,
              style: GoogleFonts.lato(
                color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228),
              ),
              decoration: InputDecoration(
                labelText: 'Keterangan',
                hintText: 'Contoh: Semarang, Jawa Tengah',
                labelStyle: GoogleFonts.lato(color: const Color(0xFF8696A0)),
                hintStyle: GoogleFonts.lato(color: const Color(0xFF8696A0)),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF3985E7)),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF2C363D) : const Color(0xFFD1D7DB),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Batal',
              style: GoogleFonts.lato(
                color: isDark ? const Color(0xFF8696A0) : Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty &&
                  valueCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _extraInfoList.add(
                    MapEntry(titleCtrl.text.trim(), valueCtrl.text.trim()),
                  );
                });
                Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3985E7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Tambah',
              style: GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SIMPAN DATA KE FIREBASE
  // ---------------------------------------------------------------------------
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim().toLowerCase();
    final experience = _experienceCtrl.text.trim();
    final strNumber = _strCtrl.text.trim();
    final education = _educationEntry.toEducationString();
    final birthDate = _birthDateCtrl.text.trim();

    setState(() => _isSaving = true);

    try {
      final Map<String, dynamic> additionalInfo = {};
      for (final entry in _extraInfoList) {
        additionalInfo[entry.key] = entry.value;
      }

      // Password default untuk akun PMIK baru
      const defaultPassword = 'PmikPassword123!';

      final newId = await _staffAuthService.createStaffAccount(
        name: name,
        email: email,
        password: defaultPassword,
        role: StaffRole.admin, // PMIK adalah StaffRole.admin
        createdByEmail: widget.createdByEmail,
        permissions: _permissions,
        avatarPath: _selectedImagePath,
        experience: experience.isNotEmpty ? '$experience tahun' : null,
        strNumber: strNumber.isNotEmpty ? strNumber : null,
        birthDate: birthDate.isNotEmpty ? birthDate : null,
        education: education.isNotEmpty ? education : null,
        additionalInfo: additionalInfo.isNotEmpty ? additionalInfo : null,
      );

      if (!mounted) return;

      if (newId == null) {
        throw Exception('Email sudah terdaftar atau gagal menyimpan ke server.');
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        LocalPushService().show(
          title: 'Peringatan',
          body: 'Gagal menyimpan PMIK: $e',
          targetRole: PushRole.superadmin,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0B1014) : const Color(0xFFF8FAFC);

    // Role label: berganti otomatis jika toggle "Hak Akses" dihidupkan
    final bool isHakAksesActive = _permissions['hak_akses'] == true;
    final String roleBadgeText =
        isHakAksesActive ? 'PMIK (SUPER ADMIN)' : 'PMIK';

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: _buildHeader(context, isDark),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            physics: const BouncingScrollPhysics(),
            children: [
              // 1. KARTU PROFIL UTAMA
              _buildProfileCard(roleBadgeText, isDark),

              const SizedBox(height: 24.0),

              // 2. SECTION INFORMASI UMUM
              _buildSectionTitle(
                title: 'Informasi Umum',
                onAddPressed: _showAddExtraInfoDialog,
                isDark: isDark,
              ),
              const SizedBox(height: 10.0),
              _buildGeneralInfoCard(isDark),

              const SizedBox(height: 24.0),

              // 3. SECTION HAK AKSES (16 Switches)
              _buildSectionTitle(title: 'Hak Akses', isDark: isDark),
              const SizedBox(height: 10.0),
              _buildPermissionsCard(isDark),

              const SizedBox(height: 32.0),

              // 4. TOMBOL SIMPAN
              _buildSaveButton(),

              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
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
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
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
                Expanded(
                  child: Text(
                    'Profil',
                    style: GoogleFonts.lato(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
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

  // ---------------------------------------------------------------------------
  // KARTU PROFIL UTAMA
  // ---------------------------------------------------------------------------
  Widget _buildProfileCard(String roleBadgeText, bool isDark) {
    final bool isHakAksesActive = _permissions['hak_akses'] == true;
    final cardBg = isDark ? const Color(0xFF1A2228) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF);
    final textPrimary = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000);
    final textSecondary = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF2C363D);
    final textMuted = const Color(0xFF8696A0);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0x0A000000),
            blurRadius: 10.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Avatar dengan Dotted Border
          Center(
            child: GestureDetector(
              onTap: _showImagePickerOptions,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 90.0,
                    height: 90.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF2C363D) : const Color(0xFFD1D7DB),
                        width: 1.5,
                        style: BorderStyle.solid,
                      ),
                      color: isDark ? const Color(0xFF242E35) : const Color(0xFFE9EDEF),
                    ),
                    child: ClipOval(
                      child: StorageService.buildImageWidget(
                        _selectedImagePath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
errorWidget: Container(
                          color: isDark ? const Color(0xFF242E35) : const Color(0xFFECF6FF),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.person_rounded,
                            size: 54.0,
                            color: isDark ? textMuted : const Color(0xFF3985E7),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8.0),

          // Tombol / Teks Unggah Foto
          GestureDetector(
            onTap: _showImagePickerOptions,
            child: Text(
              'Unggah Foto',
              style: GoogleFonts.lato(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3985E7),
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          // Input Nama PMIK
          TextFormField(
            controller: _nameCtrl,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 17.0,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Nama PMIK',
              hintStyle: GoogleFonts.lato(
                fontSize: 16.0,
                color: textMuted,
                fontWeight: FontWeight.w600,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Nama PMIK tidak boleh kosong';
              }
              return null;
            },
          ),

          _buildDottedDivider(),

          // Badge Role PMIK / PMIK (SUPER ADMIN)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isHakAksesActive
                  ? (isDark
                      ? const Color(0xFF0284C7).withValues(alpha: 0.2)
                      : const Color(0xFFE0F2FE))
                  : (isDark
                      ? const Color(0xFF242E35)
                      : const Color(0xFFE9EDEF)),
              borderRadius: BorderRadius.circular(6.0),
              border: isHakAksesActive
                  ? Border.all(
                      color: isDark
                          ? const Color(0xFF0284C7).withValues(alpha: 0.3)
                          : const Color(0xFFBAE6FD),
                    )
                  : null,
            ),
            child: Text(
              roleBadgeText,
              style: GoogleFonts.lato(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: isHakAksesActive
                    ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1))
                    : (isDark ? const Color(0xFFE9EDEF) : const Color(0xFF2C363D)),
                letterSpacing: 0.5,
              ),
            ),
          ),

          _buildDottedDivider(),

          // Input E-mail
          TextFormField(
            controller: _emailCtrl,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.lato(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
            decoration: InputDecoration(
              hintText: 'E-mail',
              hintStyle: GoogleFonts.lato(
                fontSize: 14.5,
                color: textMuted,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
            ),
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

          _buildDottedDivider(),

          // Baris 2 Kolom: Pengalaman & No. STR
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kolom Pengalaman
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 32.0,
                      height: 32.0,
                      decoration: BoxDecoration(
color: isDark ? const Color(0xFF242E35) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Icon(
                        Icons.work_outline_rounded,
                        size: 18.0,
color: isDark ? textMuted : const Color(0xFF3985E7),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pengalaman',
                            style: GoogleFonts.lato(
                              fontSize: 12.0,
                              color: textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Row(
                            children: [
                              IntrinsicWidth(
                                child: TextFormField(
                                  controller: _experienceCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  style: GoogleFonts.lato(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: textSecondary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Isi',
                                    hintStyle: GoogleFonts.lato(
                                      fontSize: 13.0,
                                      color: textMuted,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                'tahun',
                                style: GoogleFonts.lato(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                height: 40.0,
                width: 1.0,
                color: cardBorder,
                margin: const EdgeInsets.symmetric(horizontal: 10.0),
              ),

              // Kolom No. STR
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 32.0,
                      height: 32.0,
                      decoration: BoxDecoration(
color: isDark ? const Color(0xFF242E35) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Icon(
                        Icons.badge_outlined,
                        size: 18.0,
color: isDark ? textMuted : const Color(0xFF3985E7),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No. STR',
                            style: GoogleFonts.lato(
                              fontSize: 12.0,
                              color: textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          TextFormField(
                            controller: _strCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: GoogleFonts.lato(
                              fontSize: 13.0,
                              fontWeight: FontWeight.bold,
                              color: textSecondary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'No. STR',
                              hintStyle: GoogleFonts.lato(
                                fontSize: 13.0,
                                color: textMuted,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
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
    );
  }

  // ---------------------------------------------------------------------------
  // KARTU INFORMASI UMUM
  // ---------------------------------------------------------------------------
  Widget _buildGeneralInfoCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1A2228) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF);
    final textTitle = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228);
    final textValue = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF2C363D);
    final textMuted = const Color(0xFF8696A0);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0x0A000000),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. Tanggal Lahir (Dengan DatePicker)
          InkWell(
            onTap: _selectBirthDate,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Row(
                children: [
                  Container(
                    width: 36.0,
                    height: 36.0,
                    decoration: BoxDecoration(
color: isDark ? const Color(0xFF242E35) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      Icons.calendar_month_outlined,
                      size: 20.0,
color: isDark ? textMuted : const Color(0xFF3985E7),
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
                            color: textTitle,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          _birthDateCtrl.text.isNotEmpty
                              ? _birthDateCtrl.text
                              : 'Pilih Tanggal Lahir (DD/MM/YYYY)',
                          style: GoogleFonts.lato(
                            fontSize: 13.5,
                            color: _birthDateCtrl.text.isNotEmpty
                                ? textValue
                                : textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20.0,
color: isDark ? textMuted : const Color(0xFF3985E7),
                  ),
                ],
              ),
            ),
          ),

          Divider(height: 1.0, color: cardBorder),

          // 2. Pendidikan (Strata, Prodi, Universitas)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
Text(
                  'Pendidikan',
                  style: GoogleFonts.lato(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: textTitle,
                  ),
                ),
                PendidikanTripletCard(
                  entry: _educationEntry,
                  isDokter: false,
                  showRemove: false,
                ),
              ],
            ),
          ),

          // Daftar Info Tambahan Dinamis (jika ada)
          for (int i = 0; i < _extraInfoList.length; i++) ...[
            Divider(height: 1.0, color: cardBorder),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Container(
                    width: 36.0,
                    height: 36.0,
                    decoration: BoxDecoration(
color: isDark ? const Color(0xFF242E35) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 20.0,
color: isDark ? textMuted : const Color(0xFF3985E7),
                    ),
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _extraInfoList[i].key,
                          style: GoogleFonts.lato(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: textTitle,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          _extraInfoList[i].value,
                          style: GoogleFonts.lato(
                            fontSize: 13.5,
                            color: textValue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18.0, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _extraInfoList.removeAt(i);
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // KARTU HAK AKSES (16 TOGGLES)
  // ---------------------------------------------------------------------------
  Widget _buildPermissionsCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1A2228) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0x0A000000),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < DoctorPermissions.allPermissions.length; i++) ...[
            _buildPermissionRow(DoctorPermissions.allPermissions[i], isDark),
            if (i < DoctorPermissions.allPermissions.length - 1)
              Divider(height: 1.0, color: cardBorder),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionRow(DoctorPermissionItem item, bool isDark) {
    final isChecked = _permissions[item.key] ?? false;
    final textTitle = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              item.label,
              style: GoogleFonts.lato(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: textTitle,
              ),
            ),
          ),
          Switch(
            value: isChecked,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF3985E7),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: isDark ? const Color(0xFF334155) : const Color(0xFF8696A0),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (bool newVal) {
              setState(() {
                _permissions[item.key] = newVal;
              });
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TOMBOL SIMPAN
  // ---------------------------------------------------------------------------
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48.0,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3985E7),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22.0,
                height: 22.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Simpan',
                style: GoogleFonts.lato(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------
  Widget _buildSectionTitle({
    required String title,
    VoidCallback? onAddPressed,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 17.0,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
          ),
        ),
        if (onAddPressed != null)
          GestureDetector(
            onTap: onAddPressed,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.add_circle_outline_rounded,
                size: 26.0,
                color: Color(0xFF3985E7),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDottedDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final dotColor = isDark ? const Color(0xFF2C363D) : const Color(0xFFD1D7DB);
          final boxWidth = constraints.constrainWidth();
          const dashWidth = 4.0;
          const dashSpace = 3.0;
          final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
          return Flex(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: Axis.horizontal,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: 1.0,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: dotColor),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
