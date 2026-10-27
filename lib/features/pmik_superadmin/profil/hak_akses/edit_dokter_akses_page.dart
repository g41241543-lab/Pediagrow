import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/doctor_service.dart';
import '../../../../core/services/jadwal_dokter_service.dart';
import '../../../../core/services/local_push_service.dart';
import '../../../../core/services/staff_auth_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../models/doctor_model.dart';
import '../../../../models/doctor_permissions.dart';
import '../../../../models/staff_account_model.dart';
import '../../../dokter/jadwal/atur_jadwal_dokter_page.dart';
import 'widgets/pendidikan_triplet_input.dart';

/// Halaman Edit Dokter oleh Superadmin PediaGrow.
///
/// Mengacu pada desain referensi:
/// - Header 56dp dengan tombol Back di 12dp dan Judul "Edit Dokter" / "Profil"
/// - Kartu Profil dengan foto avatar + "Unggah Foto" (Kamera & Galeri)
/// - Input Nama Dokter, Spesialis, E-mail, Pengalaman (angka + tahun), No. STR (hanya angka)
/// - Section Tempat Praktik dengan tombol (+) dinamis
/// - Section Hak Akses dengan 16 switch toggle pengaturan hak kontrol dokter
/// - Tombol "Simpan" biru solid
class EditDokterAksesPage extends StatefulWidget {
  final DoctorModel doctor;
  final StaffAccount? staffAccount;

  const EditDokterAksesPage({
    super.key,
    required this.doctor,
    this.staffAccount,
  });

  @override
  State<EditDokterAksesPage> createState() => _EditDokterAksesPageState();
}

class _EditDokterAksesPageState extends State<EditDokterAksesPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _namaCtrl;
  late final TextEditingController _spesialisasiCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _pengalamanCtrl;
  late final TextEditingController _strCtrl;

  final List<TextEditingController> _tempatPraktikCtrls = [];
  final List<EducationEntry> _pendidikanEntries = [];

  late Map<String, bool> _permissions;
  String? _avatarPath;
  bool _isLoading = false;

  // Opsional ubah password akun staff
  final _passwordBaruCtrl = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    final d = widget.doctor;

    _namaCtrl = TextEditingController(text: d.name);
    _spesialisasiCtrl = TextEditingController(text: d.specialization);
    _emailCtrl = TextEditingController(
      text: d.email ?? widget.staffAccount?.email ?? '',
    );
    _pengalamanCtrl = TextEditingController(
      text: d.experienceYears > 0 ? d.experienceYears.toString() : '',
    );
    _strCtrl = TextEditingController(text: d.strNumber ?? '');

    _avatarPath = d.avatarUrl ?? d.assetImagePath;

    // Inisialisasi daftar pendidikan triplet (Strata, Prodi, Univ)
    final edus = d.daftarPendidikan;
    if (edus.isNotEmpty) {
      for (final e in edus) {
        _pendidikanEntries.add(EducationEntry.fromString(e));
      }
    } else if (widget.staffAccount?.education != null &&
        widget.staffAccount!.education!.trim().isNotEmpty) {
      _pendidikanEntries.add(
        EducationEntry.fromString(widget.staffAccount!.education!.trim()),
      );
    } else {
      _pendidikanEntries.add(EducationEntry());
    }

    // Inisialisasi daftar tempat praktik
    final places = d.daftarTempatPraktik;
    if (places.isNotEmpty) {
      for (final p in places) {
        _tempatPraktikCtrls.add(TextEditingController(text: p));
      }
    } else {
      _tempatPraktikCtrls.add(TextEditingController(text: ''));
    }

    // Inisialisasi 16 permissions
    _permissions = Map<String, bool>.from(
      DoctorPermissions.sanitize(
        widget.staffAccount?.permissions.isNotEmpty == true
            ? widget.staffAccount?.permissions
            : d.permissions,
      ),
    );
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _spesialisasiCtrl.dispose();
    _emailCtrl.dispose();
    _pengalamanCtrl.dispose();
    _strCtrl.dispose();
    for (final c in _tempatPraktikCtrls) {
      c.dispose();
    }
    for (final e in _pendidikanEntries) {
      e.dispose();
    }
    _passwordBaruCtrl.dispose();
    super.dispose();
  }

  void _addPendidikan() {
    setState(() {
      _pendidikanEntries.add(EducationEntry());
    });
  }

  void _removePendidikan(int index) {
    if (_pendidikanEntries.length > 1) {
      setState(() {
        final removed = _pendidikanEntries.removeAt(index);
        removed.dispose();
      });
    } else {
      _pendidikanEntries.first.strataCtrl.clear();
      _pendidikanEntries.first.prodiCtrl.clear();
      _pendidikanEntries.first.univCtrl.clear();
      setState(() {});
    }
  }

  void _addTempatPraktik() {
    setState(() {
      _tempatPraktikCtrls.add(TextEditingController());
    });
  }

  void _removeTempatPraktik(int index) {
    if (_tempatPraktikCtrls.length > 1) {
      setState(() {
        final removed = _tempatPraktikCtrls.removeAt(index);
        removed.dispose();
      });
    } else {
      _tempatPraktikCtrls.first.clear();
      setState(() {});
    }
  }

  // ---------------------------------------------------------------------------
  // IMAGE PICKER (KAMERA & GALERI)
  // ---------------------------------------------------------------------------
  void _showImagePickerOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1A2228) : Colors.white;
    final barColor = isDark ? const Color(0xFF2C363D) : const Color(0xFFD1D7DB);
    final textPrimary = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014);
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
                    color: barColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Unggah Foto Dokter',
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
                      fontSize: 15,
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
                      fontSize: 15,
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
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          _avatarPath = picked.path;
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
  // SIMPAN PERUBAHAN
  // ---------------------------------------------------------------------------
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final places = _tempatPraktikCtrls
          .map((c) => c.text.trim())
          .where((p) => p.isNotEmpty)
          .toList();

      final edus = _pendidikanEntries
          .map((e) => e.toEducationString())
          .where((e) => e.isNotEmpty)
          .toList();

      final sanitizedPermissions = DoctorPermissions.sanitize(_permissions);

      final updatedDoctor = widget.doctor.copyWith(
        name: _namaCtrl.text.trim(),
        specialization: _spesialisasiCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        experienceYears: int.tryParse(_pengalamanCtrl.text.trim()) ?? 0,
        strNumber: _strCtrl.text.trim(),
        placesOfPractice: places,
        hospital: places.isNotEmpty ? places.first : null,
        educations: edus,
        education: edus.isNotEmpty ? edus.first : null,
        avatarUrl: _avatarPath,
        permissions: sanitizedPermissions,
      );

      // Simpan perubahan ke Firestore
      await DoctorService().updateDoctor(updatedDoctor);

      // Jika ada akun login staff terkait (dokter), perbarui kredensial & data staff
      String targetStaffId = widget.doctor.staffAccountId;
      if (targetStaffId.isEmpty && widget.staffAccount != null) {
        targetStaffId = widget.staffAccount!.id;
      }
      if (targetStaffId.isEmpty && _emailCtrl.text.trim().isNotEmpty) {
        final acc = await StaffAuthService().getStaffAccountByEmail(_emailCtrl.text.trim());
        if (acc != null) targetStaffId = acc.id;
      }
      if (targetStaffId.isNotEmpty) {
        await StaffAuthService().updateStaffAccount(
          targetStaffId,
          name: _namaCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordBaruCtrl.text.trim().isNotEmpty
              ? _passwordBaruCtrl.text.trim()
              : null,
          permissions: sanitizedPermissions,
          avatarPath: _avatarPath,
          experience: _pengalamanCtrl.text.trim().isNotEmpty
              ? '${_pengalamanCtrl.text.trim()} tahun'
              : null,
          strNumber: _strCtrl.text.trim().isNotEmpty ? _strCtrl.text.trim() : null,
          education: edus.isNotEmpty ? edus.join(' • ') : null,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        LocalPushService().show(
          title: 'Peringatan',
          body: 'Gagal menyimpan: $e',
          targetRole: PushRole.superadmin,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0B1014) : const Color(0xFFFBFBFB);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: _buildHeader(context, isDark),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. KARTU PROFIL DOKTER
                _buildDoctorProfileCard(isDark),
                const SizedBox(height: 20.0),

                // 2. SECTION PENDIDIKAN
                _buildPendidikanSection(isDark),
                const SizedBox(height: 20.0),

                // 3. SECTION TEMPAT PRAKTIK
                _buildTempatPraktikSection(isDark),
                const SizedBox(height: 20.0),

                // 3. SECTION JADWAL KONSULTASI STANDAR
                _buildJadwalStandarSection(isDark),
                const SizedBox(height: 20.0),

                // 4. SECTION HAK AKSES
                _buildHakAksesSection(isDark),
                const SizedBox(height: 24.0),

                // 4. TOMBOL SIMPAN
                SizedBox(
                  height: 48.0,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3985E7),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
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
                ),
                const SizedBox(height: 30.0),
              ],
            ),
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
              crossAxisAlignment: CrossAxisAlignment.center,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // KARTU PROFIL DOKTER
  // ---------------------------------------------------------------------------
  Widget _buildDoctorProfileCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1A2228) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF);
    final textPrimary = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000);
    final textSecondary = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF2C363D);
    final textMuted = const Color(0xFF8696A0);

    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 18.0, 16.0, 16.0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0x0A000000),
            blurRadius: 10.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar dengan badge/border
          GestureDetector(
            onTap: _showImagePickerOptions,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 82.0,
                  height: 82.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF2C363D) : const Color(0xFFD1D7DB),
                      width: 1.5,
                    ),
                    color: isDark ? const Color(0xFF242E35) : const Color(0xFFF8FAFC),
                  ),
                  child: ClipOval(
                    child: _buildAvatarImage(isDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8.0),

          // Teks Tombol "Unggah Foto"
          GestureDetector(
            onTap: _showImagePickerOptions,
            child: Text(
              'Unggah Foto',
              style: GoogleFonts.lato(
                fontSize: 13.0,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3985E7),
              ),
            ),
          ),
          const SizedBox(height: 14.0),

          // Nama Dokter
          TextFormField(
            controller: _namaCtrl,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
              border: InputBorder.none,
              hintText: 'Nama Dokter',
              hintStyle: GoogleFonts.lato(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: textMuted,
              ),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
          ),
          const SizedBox(height: 4.0),
          const _DottedLine(),
          const SizedBox(height: 10.0),

          // Spesialis
          TextFormField(
            controller: _spesialisasiCtrl,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
              border: InputBorder.none,
              hintText: 'Spesialis',
              hintStyle: GoogleFonts.lato(
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
          ),
          const SizedBox(height: 4.0),
          const _DottedLine(),
          const SizedBox(height: 10.0),

          // E-mail
          TextFormField(
            controller: _emailCtrl,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.lato(
              fontSize: 13.0,
              color: textSecondary,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
              border: InputBorder.none,
              hintText: 'E-mail',
              hintStyle: GoogleFonts.lato(
                fontSize: 13.0,
                color: textMuted,
              ),
            ),
          ),
          const SizedBox(height: 4.0),
          const _DottedLine(),
          const SizedBox(height: 10.0),

          // Kata Sandi / Password Baru (Opsional)
          TextFormField(
            controller: _passwordBaruCtrl,
            obscureText: !_isPasswordVisible,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 13.0,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
              border: InputBorder.none,
              hintText: 'Kata Sandi Baru (Opsional)',
              hintStyle: GoogleFonts.lato(
                fontSize: 13.0,
                color: textMuted,
              ),
              suffixIcon: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18.0,
                  color: textMuted,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
            validator: (v) {
              if (v != null && v.isNotEmpty && v.length < 6) {
                return 'Password minimal 6 karakter';
              }
              return null;
            },
          ),
          const SizedBox(height: 4.0),
          const _DottedLine(),
          const SizedBox(height: 14.0),

          // Baris 2 Kolom: Pengalaman & No. STR
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kolom Kiri: Pengalaman (Hanya Angka + Fixed "tahun")
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
<<<<<<< HEAD
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Icon(
                        Icons.work_outline_rounded,
                        size: 20.0,
                        color: textMuted,
=======
                    Container(
                      width: 28.0,
                      height: 28.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: const Icon(
                        Icons.work_outline_rounded,
                        size: 16.0,
                        color: Color(0xFF3985E7),
>>>>>>> 69f9bbd5b3b1a63c0172d779502ab9f5acb8edc8
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
                            ),
                          ),
                          Row(
                            children: [
                              IntrinsicWidth(
                                child: TextFormField(
                                  controller: _pengalamanCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  style: GoogleFonts.lato(
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w600,
                                    color: textSecondary,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 2.0),
                                    border: InputBorder.none,
                                    hintText: '0',
                                    hintStyle: GoogleFonts.lato(
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w600,
                                      color: textMuted,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                'tahun',
                                style: GoogleFonts.lato(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2.0),
                          const _DottedLine(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Garis Pemisah Vertikal
              Container(
                width: 1.0,
                height: 44.0,
                color: cardBorder,
                margin: const EdgeInsets.symmetric(horizontal: 10.0),
              ),

              // Kolom Kanan: No. STR (Hanya Angka)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
<<<<<<< HEAD
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Icon(
                        Icons.badge_outlined,
                        size: 20.0,
                        color: textMuted,
=======
                    Container(
                      width: 28.0,
                      height: 28.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: const Icon(
                        Icons.badge_outlined,
                        size: 16.0,
                        color: Color(0xFF3985E7),
>>>>>>> 69f9bbd5b3b1a63c0172d779502ab9f5acb8edc8
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
                            ),
                          ),
                          TextFormField(
                            controller: _strCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: GoogleFonts.lato(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 2.0),
                              border: InputBorder.none,
                              hintText: 'No. STR',
                              hintStyle: GoogleFonts.lato(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w600,
                                color: textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          const _DottedLine(),
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

  Widget _buildAvatarImage(bool isDark) {
    return StorageService.buildImageWidget(
      _avatarPath,
      fit: BoxFit.cover,
      width: 82.0,
      height: 82.0,
      errorWidget: _buildAvatarFallback(isDark),
    );
  }

  Widget _buildAvatarFallback(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF242E35) : const Color(0xFFEFF6FF),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_rounded,
        size: 46.0,
        color: Color(0xFF3985E7),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION PENDIDIKAN
  // ---------------------------------------------------------------------------
  Widget _buildPendidikanSection(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1A2228) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF);
    final textTitle = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000);
    final textValue = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF2C363D);
    final textMuted = const Color(0xFF8696A0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pendidikan',
              style: GoogleFonts.lato(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: textTitle,
              ),
            ),
            IconButton(
              onPressed: _addPendidikan,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: Color(0xFF3985E7),
                size: 26.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0x0A000000),
                blurRadius: 10.0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
<<<<<<< HEAD
            children: List.generate(_pendidikanCtrls.length, (idx) {
              final ctrl = _pendidikanCtrls[idx];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 22.0,
                      color: textMuted,
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: ctrl,
                            style: GoogleFonts.lato(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500,
                              color: textValue,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              border: InputBorder.none,
                              hintText: 'Riwayat Pendidikan (Gelar / Univ)',
                              hintStyle: GoogleFonts.lato(
                                fontSize: 14.0,
                                color: textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          const _DottedLine(),
                        ],
                      ),
                    ),
                    if (_pendidikanCtrls.length > 1)
                      GestureDetector(
                        onTap: () => _removePendidikan(idx),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(
                            Icons.remove_circle_outline_rounded,
                            size: 20.0,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                  ],
                ),
=======
            children: List.generate(_pendidikanEntries.length, (idx) {
              final entry = _pendidikanEntries[idx];
              return Column(
                children: [
                  PendidikanTripletCard(
                    entry: entry,
                    isDokter: true,
                    showRemove: _pendidikanEntries.length > 1,
                    onRemove: () => _removePendidikan(idx),
                  ),
                  if (idx < _pendidikanEntries.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Divider(color: Color(0xFFE9EDEF), height: 1.0),
                    ),
                ],
>>>>>>> 69f9bbd5b3b1a63c0172d779502ab9f5acb8edc8
              );
            }),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION TEMPAT PRAKTIK
  // ---------------------------------------------------------------------------
  Widget _buildTempatPraktikSection(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1A2228) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF);
    final textTitle = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000);
    final textValue = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF2C363D);
    final textMuted = const Color(0xFF8696A0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tempat Praktik',
              style: GoogleFonts.lato(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: textTitle,
              ),
            ),
            IconButton(
              onPressed: _addTempatPraktik,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: Color(0xFF3985E7),
                size: 26.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0x0A000000),
                blurRadius: 10.0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: List.generate(_tempatPraktikCtrls.length, (idx) {
              final ctrl = _tempatPraktikCtrls[idx];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
<<<<<<< HEAD
                    Icon(
                      Icons.apartment_rounded,
                      size: 22.0,
                      color: textMuted,
=======
                    Container(
                      width: 32.0,
                      height: 32.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Icon(
                        Icons.apartment_rounded,
                        size: 20.0,
                        color: Color(0xFF3985E7),
                      ),
>>>>>>> 69f9bbd5b3b1a63c0172d779502ab9f5acb8edc8
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: ctrl,
                            style: GoogleFonts.lato(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500,
                              color: textValue,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              border: InputBorder.none,
                              hintText: 'Nama Tempat Praktik',
                              hintStyle: GoogleFonts.lato(
                                fontSize: 14.0,
                                color: textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          const _DottedLine(),
                        ],
                      ),
                    ),
                    if (_tempatPraktikCtrls.length > 1)
                      GestureDetector(
                        onTap: () => _removeTempatPraktik(idx),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(
                            Icons.remove_circle_outline_rounded,
                            size: 20.0,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION JADWAL KONSULTASI DOKTER (SUPERADMIN)
  // ---------------------------------------------------------------------------
  Widget _buildJadwalStandarSection(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1A2228) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF);
    final textTitle = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000);
    final textItemTitle = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228);
    final textMuted = const Color(0xFF8696A0);

    final List<JadwalPraktikModel> jadwalList =
        JadwalDokterService().getJadwalDokter(widget.doctor.id);
    final activeDays = jadwalList.where((j) => j.aktif).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
<<<<<<< HEAD
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Jadwal Konsultasi Standar',
              style: GoogleFonts.lato(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: textTitle,
              ),
            ),
            GestureDetector(
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AturJadwalDokterPage(
                      dokterId: widget.doctor.id,
                      doctorName: _namaCtrl.text,
                      isSuperadmin: true,
                    ),
                  ),
                );
                if (mounted) setState(() {});
              },
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_calendar_rounded,
                    color: Color(0xFF0284C7),
                    size: 18.0,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    'Kelola',
                    style: GoogleFonts.lato(
                      fontSize: 13.0,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0284C7),
                    ),
                  ),
                ],
              ),
            ),
          ],
=======
        Text(
          'Jadwal Konsultasi Dokter',
          style: GoogleFonts.lato(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF000000),
          ),
>>>>>>> 69f9bbd5b3b1a63c0172d779502ab9f5acb8edc8
        ),
        const SizedBox(height: 8.0),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0x0A000000),
                blurRadius: 10.0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0284C7).withValues(alpha: 0.2)
                          : const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: Color(0xFF0284C7),
                      size: 20.0,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jadwal Rutin Mingguan',
                          style: GoogleFonts.lato(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: textItemTitle,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          activeDays.isEmpty
                              ? 'Belum ada hari praktik aktif yang diatur.'
                              : '${activeDays.length} hari aktif per minggu (${activeDays.map((e) => e.namaHari).join(', ')})',
                          style: GoogleFonts.lato(
                            fontSize: 12.0,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14.0),
              InkWell(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AturJadwalDokterPage(
                        dokterId: widget.doctor.id,
                        doctorName: _namaCtrl.text,
                        isSuperadmin: true,
                      ),
                    ),
                  );
                  if (mounted) setState(() {});
                },
                borderRadius: BorderRadius.circular(10.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0284C7).withValues(alpha: 0.15)
                        : const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF0284C7).withValues(alpha: 0.3)
                          : const Color(0xFFBAE6FD),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.settings_suggest_rounded,
                        color: Color(0xFF0284C7),
                        size: 18.0,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        'Buka Pengaturan Jadwal & Cuti',
                        style: GoogleFonts.lato(
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION HAK AKSES (16 TOGGLE)
  // ---------------------------------------------------------------------------
  Widget _buildHakAksesSection(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1A2228) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF);
    final textTitle = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000);
    final textItem = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF2C363D);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hak Akses',
          style: GoogleFonts.lato(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: textTitle,
          ),
        ),
        const SizedBox(height: 8.0),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0x0A000000),
                blurRadius: 10.0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: List.generate(
              DoctorPermissions.allPermissions.length,
              (index) {
                final item = DoctorPermissions.allPermissions[index];
                final isChecked = _permissions[item.key] ?? item.defaultValue;
                final isLast =
                    index == DoctorPermissions.allPermissions.length - 1;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.label,
                              style: GoogleFonts.lato(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w600,
                                color: textItem,
                              ),
                            ),
                          ),
<<<<<<< HEAD
                          Switch(
                            value: isChecked,
                            activeThumbColor: const Color(0xFF3985E7),
                            activeTrackColor:
                                const Color(0xFF3985E7).withValues(alpha: 0.5),
                            inactiveThumbColor: const Color(0xFFFFFFFF),
                            inactiveTrackColor: const Color(0xFF8696A0),
                            onChanged: (val) {
                              setState(() {
                                _permissions[item.key] = val;
                              });
                            },
                          ),
=======
                          if (item.key == 'daftar_resep_mpasi' ||
                              item.key == 'daftar_artikel_kesehatan')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10.0,
                                vertical: 4.0,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2563EB).withValues(alpha: 0.15)
                                    : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF2563EB).withValues(alpha: 0.3)
                                      : const Color(0xFFBFDBFE),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.visibility_outlined,
                                    size: 14.0,
                                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                                  ),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    'Hanya Lihat',
                                    style: GoogleFonts.lato(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Switch(
                              value: isChecked,
                              activeThumbColor: const Color(0xFF3985E7),
                              activeTrackColor:
                                  const Color(0xFF3985E7).withValues(alpha: 0.5),
                              inactiveThumbColor: const Color(0xFFFFFFFF),
                              inactiveTrackColor: isDark ? const Color(0xFF334155) : const Color(0xFF8696A0),
                              onChanged: (val) {
                                setState(() {
                                  _permissions[item.key] = val;
                                });
                              },
                            ),
>>>>>>> 53862d66c0ac0cb11c407b684ab7fd713d754749
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1.0,
                        thickness: 0.8,
                        color: cardBorder,
                        indent: 16.0,
                        endIndent: 16.0,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Garis putus-putus horizontal sesuai desain
class _DottedLine extends StatelessWidget {
  final Color? color;
  const _DottedLine({this.color});

  static const Color _defaultColor = Color(0xFFD1D7DB);
  static const double _height = 1.0;
  static const double _dotWidth = 3.0;
  static const double _spaceWidth = 3.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dotColor = color ?? (isDark ? const Color(0xFF2C363D) : _defaultColor);

    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        final count = (boxWidth / (_dotWidth + _spaceWidth)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(count > 0 ? count : 1, (_) {
            return SizedBox(
              width: _dotWidth,
              height: _height,
              child: DecoratedBox(
                decoration: BoxDecoration(color: dotColor),
              ),
            );
          }),
        );
      },
    );
  }
}
