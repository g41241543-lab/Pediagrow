import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/doctor_service.dart';
import '../../../../core/services/staff_auth_service.dart';
import '../../../../models/doctor_model.dart';
import '../../../../models/doctor_permissions.dart';
import '../../../../models/staff_account_model.dart';

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

  late Map<String, bool> _permissions;
  String? _avatarPath;
  bool _isLoading = false;

  // Opsional ubah password akun staff
  bool _showPasswordChange = false;
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
    _passwordBaruCtrl.dispose();
    super.dispose();
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
                  'Unggah Foto Dokter',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
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

      final updatedDoctor = widget.doctor.copyWith(
        name: _namaCtrl.text.trim(),
        specialization: _spesialisasiCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        experienceYears: int.tryParse(_pengalamanCtrl.text.trim()) ?? 0,
        strNumber: _strCtrl.text.trim(),
        placesOfPractice: places,
        hospital: places.isNotEmpty ? places.first : null,
        avatarUrl: _avatarPath,
        permissions: _permissions,
      );

      // Simpan perubahan ke Firestore
      await DoctorService().updateDoctor(updatedDoctor);

      // Jika ada akun login staff terkait (dokter), perbarui kredensial & data staff
      if (widget.doctor.staffAccountId.isNotEmpty) {
        await StaffAuthService().updateStaffAccount(
          widget.doctor.staffAccountId,
          name: _namaCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: (_showPasswordChange && _passwordBaruCtrl.text.isNotEmpty)
              ? _passwordBaruCtrl.text.trim()
              : null,
          permissions: _permissions,
          avatarPath: _avatarPath,
          experience: _pengalamanCtrl.text.trim().isNotEmpty
              ? '${_pengalamanCtrl.text.trim()} tahun'
              : null,
          strNumber: _strCtrl.text.trim().isNotEmpty ? _strCtrl.text.trim() : null,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Data dokter berhasil disimpan.',
            style: GoogleFonts.lato(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menyimpan: $e',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: _buildHeader(context),
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
                _buildDoctorProfileCard(),
                const SizedBox(height: 20.0),

                // 2. SECTION TEMPAT PRAKTIK
                _buildTempatPraktikSection(),
                const SizedBox(height: 20.0),

                // 3. SECTION HAK AKSES
                _buildHakAksesSection(),
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
  Widget _buildHeader(BuildContext context) {
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
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
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
                const SizedBox(width: 12.0),
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

  // ---------------------------------------------------------------------------
  // KARTU PROFIL DOKTER
  // ---------------------------------------------------------------------------
  Widget _buildDoctorProfileCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 18.0, 16.0, 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                      color: const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                    color: const Color(0xFFF8FAFC),
                  ),
                  child: ClipOval(
                    child: _buildAvatarImage(),
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
              color: const Color(0xFF000000),
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 4.0),
              border: InputBorder.none,
              hintText: 'Nama Dokter',
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
              color: const Color(0xFF475569),
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 4.0),
              border: InputBorder.none,
              hintText: 'Spesialis',
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
              color: const Color(0xFF475569),
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 4.0),
              border: InputBorder.none,
              hintText: 'E-mail',
            ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2.0),
                      child: Icon(
                        Icons.work_outline_rounded,
                        size: 20.0,
                        color: Color(0xFF94A3B8),
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
                              color: const Color(0xFF94A3B8),
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
                                    color: const Color(0xFF334155),
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 2.0),
                                    border: InputBorder.none,
                                    hintText: '0',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                'tahun',
                                style: GoogleFonts.lato(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF334155),
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
                color: const Color(0xFFE2E8F0),
                margin: const EdgeInsets.symmetric(horizontal: 10.0),
              ),

              // Kolom Kanan: No. STR (Hanya Angka)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2.0),
                      child: Icon(
                        Icons.badge_outlined,
                        size: 20.0,
                        color: Color(0xFF94A3B8),
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
                              color: const Color(0xFF94A3B8),
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
                              color: const Color(0xFF334155),
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 2.0),
                              border: InputBorder.none,
                              hintText: 'No. STR',
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

  Widget _buildAvatarImage() {
    if (_avatarPath != null && _avatarPath!.isNotEmpty) {
      if (File(_avatarPath!).existsSync()) {
        return Image.file(
          File(_avatarPath!),
          fit: BoxFit.cover,
          width: 82.0,
          height: 82.0,
        );
      }
      if (_avatarPath!.startsWith('http')) {
        return Image.network(
          _avatarPath!,
          fit: BoxFit.cover,
          width: 82.0,
          height: 82.0,
          errorBuilder: (_, __, ___) => _buildAvatarFallback(),
        );
      }
      if (_avatarPath!.startsWith('assets/')) {
        return Image.asset(
          _avatarPath!,
          fit: BoxFit.cover,
          width: 82.0,
          height: 82.0,
          errorBuilder: (_, __, ___) => _buildAvatarFallback(),
        );
      }
    }
    return _buildAvatarFallback();
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: const Color(0xFFEFF6FF),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_rounded,
        size: 46.0,
        color: Color(0xFF3985E7),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION TEMPAT PRAKTIK
  // ---------------------------------------------------------------------------
  Widget _buildTempatPraktikSection() {
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
                color: const Color(0xFF000000),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10.0,
                offset: Offset(0, 3),
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
                    const Icon(
                      Icons.apartment_rounded,
                      size: 22.0,
                      color: Color(0xFF94A3B8),
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
                              color: const Color(0xFF334155),
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              border: InputBorder.none,
                              hintText: 'Nama Tempat Praktik',
                              hintStyle: GoogleFonts.lato(
                                fontSize: 14.0,
                                color: const Color(0xFF94A3B8),
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
  // SECTION HAK AKSES (16 TOGGLE)
  // ---------------------------------------------------------------------------
  Widget _buildHakAksesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hak Akses',
          style: GoogleFonts.lato(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF000000),
          ),
        ),
        const SizedBox(height: 8.0),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10.0,
                offset: Offset(0, 3),
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
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ),
                          Switch(
                            value: isChecked,
                            activeColor: const Color(0xFF3985E7),
                            activeTrackColor:
                                const Color(0xFF3985E7).withOpacity(0.5),
                            inactiveThumbColor: const Color(0xFFFFFFFF),
                            inactiveTrackColor: const Color(0xFF94A3B8),
                            onChanged: (val) {
                              setState(() {
                                _permissions[item.key] = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      const Divider(
                        height: 1.0,
                        thickness: 0.8,
                        color: Color(0xFFF1F5F9),
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
  final Color color;
  final double height;
  final double dotWidth;
  final double spaceWidth;

  const _DottedLine({
    this.color = const Color(0xFFCBD5E1),
    this.height = 1.0,
    this.dotWidth = 3.0,
    this.spaceWidth = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        final count = (boxWidth / (dotWidth + spaceWidth)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(count > 0 ? count : 1, (_) {
            return SizedBox(
              width: dotWidth,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}
