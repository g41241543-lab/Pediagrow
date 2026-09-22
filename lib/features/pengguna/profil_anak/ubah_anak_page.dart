import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/child_service.dart';
import '../../../models/child_model.dart';
import '../beranda/beranda_page.dart';
import '../konsultasi/daftar_dokter_page.dart';
import '../profil/menu_profil_page.dart';
import '../riwayat_konsultasi/daftar_riwayat_page.dart';
import 'hapus_anak_dialog.dart';

/// Halaman Ubah Data Profil Anak PediaGrow.
///
/// Spesifikasi UI & Alur:
/// - Header memiliki jarak 56dp dari tepi atas layar
/// - Tombol back 12dp dari tepi kiri, judul 'Ubah Data Profil' 12dp setelah tombol back
/// - Tombol 'Hapus' (teks merah #E74C3C) di pojok kanan header sejajar judul
/// - Margin konten form 16dp dari tepi kiri & kanan
/// - Field terisi otomatis dari data tersimpan (ChildModel)
/// - Input field: tinggi 48dp, border #C5C5C5, corner radius 8, placeholder #C5C5C5
/// - Tombol Simpan: tinggi 48dp, corner radius 17, background #3985E7, teks putih
class UbahAnakPage extends StatefulWidget {
  final ChildModel child;

  const UbahAnakPage({super.key, required this.child});

  @override
  State<UbahAnakPage> createState() => _UbahAnakPageState();
}

class _UbahAnakPageState extends State<UbahAnakPage> {
  // Controller input
  late final TextEditingController _namaController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _beratBadanController;
  late final TextEditingController _tinggiBadanController;
  late final TextEditingController _alergiController;

  // Focus node
  final FocusNode _namaFocus = FocusNode();
  final FocusNode _beratBadanFocus = FocusNode();
  final FocusNode _tinggiBadanFocus = FocusNode();
  final FocusNode _alergiFocus = FocusNode();

  // Scroll controller & GlobalKeys untuk auto-scroll error
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _namaKey = GlobalKey();
  final GlobalKey _tanggalLahirKey = GlobalKey();
  final GlobalKey _genderKey = GlobalKey();
  final GlobalKey _beratBadanKey = GlobalKey();
  final GlobalKey _tinggiBadanKey = GlobalKey();
  final GlobalKey _alergiKey = GlobalKey();
  final GlobalKey _alergiDetailKey = GlobalKey();

  // Form states
  DateTime? _selectedBirthDate;
  String? _calculatedAgeString;
  String? _selectedGender;
  String? _fotoProfilPath;
  String? _fotoKelahiranPath;
  bool? _hasAllergies;

  // Error & warning states
  String? _namaError;
  String? _tanggalLahirError;
  String? _genderError;
  String? _beratBadanError;
  String? _beratBadanWarning;
  String? _tinggiBadanError;
  String? _tinggiBadanWarning;
  String? _alergiError;
  String? _alergiDetailError;

  bool _isSaving = false;
  final int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();

    _namaController = TextEditingController(text: widget.child.name);
    _selectedBirthDate = widget.child.birthDate;
    if (_selectedBirthDate != null) {
      final d = _selectedBirthDate!;
      _birthDateController = TextEditingController(
        text:
            '${d.day.toString().padLeft(2, "0")}/${d.month.toString().padLeft(2, "0")}/${d.year}',
      );
      _calculatedAgeString = widget.child.ageDescription.isNotEmpty
          ? widget.child.ageDescription
          : _calculateAgeString(_selectedBirthDate!);
    } else {
      _birthDateController = TextEditingController();
      _calculatedAgeString = widget.child.ageDescription.isNotEmpty
          ? widget.child.ageDescription
          : null;
    }

    _selectedGender = widget.child.gender.isNotEmpty
        ? widget.child.gender
        : 'Laki-laki';
    _beratBadanController = TextEditingController(
      text: widget.child.weightKg != null
          ? widget.child.weightKg.toString()
          : '',
    );
    _tinggiBadanController = TextEditingController(
      text: widget.child.heightCm != null
          ? widget.child.heightCm.toString()
          : '',
    );

    _hasAllergies = widget.child.hasAllergies;
    _alergiController = TextEditingController(
      text: widget.child.allergies ?? '',
    );

    _fotoProfilPath = widget.child.photoUrl;
    _fotoKelahiranPath = widget.child.birthPhotoUrl;

    _beratBadanController.addListener(_checkBeratBadanRange);
    _tinggiBadanController.addListener(_checkTinggiBadanRange);

    _checkBeratBadanRange();
    _checkTinggiBadanRange();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _birthDateController.dispose();
    _beratBadanController.dispose();
    _tinggiBadanController.dispose();
    _alergiController.dispose();

    _namaFocus.dispose();
    _beratBadanFocus.dispose();
    _tinggiBadanFocus.dispose();
    _alergiFocus.dispose();

    _scrollController.dispose();
    super.dispose();
  }

  void _checkBeratBadanRange() {
    final text = _beratBadanController.text.trim();
    if (text.isEmpty) {
      if (_beratBadanWarning != null) setState(() => _beratBadanWarning = null);
      return;
    }
    final val = double.tryParse(text);
    if (val != null && (val < 2.5 || val > 4.5)) {
      if (_beratBadanWarning == null) {
        setState(
          () => _beratBadanWarning =
              'Rentang wajar bayi baru lahir: 2.5 - 4.5 kg',
        );
      }
    } else {
      if (_beratBadanWarning != null) setState(() => _beratBadanWarning = null);
    }
  }

  void _checkTinggiBadanRange() {
    final text = _tinggiBadanController.text.trim();
    if (text.isEmpty) {
      if (_tinggiBadanWarning != null)
        setState(() => _tinggiBadanWarning = null);
      return;
    }
    final val = double.tryParse(text);
    if (val != null && (val < 45.0 || val > 55.0)) {
      if (_tinggiBadanWarning == null) {
        setState(
          () =>
              _tinggiBadanWarning = 'Rentang wajar bayi baru lahir: 45 - 55 cm',
        );
      }
    } else {
      if (_tinggiBadanWarning != null)
        setState(() => _tinggiBadanWarning = null);
    }
  }

  /// Memeriksa apakah terdapat minimal 1 field yang diubah dari data awal
  bool get _isFormChanged {
    if (_namaController.text.trim() != widget.child.name) return true;
    if (_selectedBirthDate != widget.child.birthDate) return true;
    if (_selectedGender != widget.child.gender) return true;

    final origWeight = widget.child.weightKg != null
        ? widget.child.weightKg.toString()
        : '';
    if (_beratBadanController.text.trim() != origWeight) return true;

    final origHeight = widget.child.heightCm != null
        ? widget.child.heightCm.toString()
        : '';
    if (_tinggiBadanController.text.trim() != origHeight) return true;

    if (_hasAllergies != widget.child.hasAllergies) return true;
    final origAllergies = widget.child.allergies ?? '';
    if (_alergiController.text.trim() != origAllergies) return true;

    if (_fotoProfilPath != widget.child.photoUrl) return true;
    if (_fotoKelahiranPath != widget.child.birthPhotoUrl) return true;

    return false;
  }

  /// Penanganan navigasi kembali
  void _handleBackNavigation() {
    if (!_isFormChanged) {
      Navigator.of(context).pop();
      return;
    }
    _showExitConfirmationDialog();
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFD97706),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Data yang belum disimpan akan hilang, yakin ingin keluar?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogCtx).pop();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Ya, Kembali ke Beranda',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Lanjutkan Mengisi Profil',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Dialog konfirmasi hapus data profil anak
  void _showDeleteConfirmationDialog() {
    HapusAnakDialog.show(
      context,
      onConfirmDelete: () {
        ChildService().deleteChild(widget.child.id);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => BerandaPage(
              showAddSuccessSnackbar: true,
              addSuccessMessage: 'Profil anak berhasil dihapus',
            ),
          ),
          (route) => false,
        );
      },
    );
  }

  // Pemilih foto (Kamera / Galeri)
  Future<void> _pickImage(
    ImageSource source, {
    required bool isBirthPhoto,
  }) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          if (isBirthPhoto) {
            _fotoKelahiranPath = picked.path;
          } else {
            _fotoProfilPath = picked.path;
          }
        });
      }
    } catch (_) {
      _showSnackBar('Gagal memilih foto, coba lagi', isError: true);
    }
  }

  void _showImagePickerModal({required bool isBirthPhoto}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBirthPhoto ? 'Pilih Foto Si Kecil' : 'Pilih Foto Profil',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFF3985E7),
                  ),
                  title: Text(
                    'Kamera',
                    style: GoogleFonts.lato(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera, isBirthPhoto: isBirthPhoto);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFF3985E7),
                  ),
                  title: Text(
                    'Galeri',
                    style: GoogleFonts.lato(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery, isBirthPhoto: isBirthPhoto);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openFullScreenPhoto(String path, String heroTag) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        pageBuilder: (context, anim, secAnim) {
          final isLocalFile = File(path).existsSync();
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 3.5,
                      child: Hero(
                        tag: heroTag,
                        child: isLocalFile
                            ? Image.file(File(path), fit: BoxFit.contain)
                            : Image.asset(
                                'assets/images/default_baby_avatar.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.child_care,
                                      size: 100,
                                      color: Colors.white,
                                    ),
                              ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final firstAllowedDate = DateTime(now.year - 5, now.month, now.day);
    DateTime initial = _selectedBirthDate ?? now;
    if (initial.isBefore(firstAllowedDate)) initial = firstAllowedDate;
    if (initial.isAfter(now)) initial = now;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstAllowedDate,
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3985E7),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text =
            '${picked.day.toString().padLeft(2, "0")}/${picked.month.toString().padLeft(2, "0")}/${picked.year}';
        _calculatedAgeString = _calculateAgeString(picked);
        _tanggalLahirError = null;
      });
    }
  }

  String _calculateAgeString(DateTime birthDate) {
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    int days = now.day - birthDate.day;

    if (days < 0) {
      months -= 1;
      final prevMonthDays = DateTime(now.year, now.month, 0).day;
      days += prevMonthDays;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }

    final parts = <String>[];
    if (years > 0) parts.add('$years tahun');
    if (months > 0) parts.add('$months bulan');
    if (days > 0 || parts.isEmpty) parts.add('$days hari');

    return parts.join(' ');
  }

  // Simpan data & validasi
  Future<void> _handleSave() async {
    setState(() {
      _namaError = null;
      _tanggalLahirError = null;
      _genderError = null;
      _beratBadanError = null;
      _tinggiBadanError = null;
      _alergiError = null;
      _alergiDetailError = null;
    });

    bool hasError = false;
    GlobalKey? firstErrorKey;

    final nama = _namaController.text.trim();
    if (nama.isEmpty) {
      _namaError = 'Nama lengkap wajib diisi';
      hasError = true;
      firstErrorKey ??= _namaKey;
    }

    if (_selectedBirthDate == null) {
      _tanggalLahirError = 'Tanggal lahir wajib dipilih';
      hasError = true;
      firstErrorKey ??= _tanggalLahirKey;
    }

    if (_selectedGender == null || _selectedGender!.isEmpty) {
      _genderError = 'Jenis kelamin wajib dipilih';
      hasError = true;
      firstErrorKey ??= _genderKey;
    }

    final bbText = _beratBadanController.text.trim();
    if (bbText.isEmpty) {
      _beratBadanError = 'Berat badan saat lahir wajib diisi';
      hasError = true;
      firstErrorKey ??= _beratBadanKey;
    } else if (double.tryParse(bbText) == null) {
      _beratBadanError = 'Format berat badan tidak valid';
      hasError = true;
      firstErrorKey ??= _beratBadanKey;
    }

    final tbText = _tinggiBadanController.text.trim();
    if (tbText.isEmpty) {
      _tinggiBadanError = 'Tinggi badan saat lahir wajib diisi';
      hasError = true;
      firstErrorKey ??= _tinggiBadanKey;
    } else if (double.tryParse(tbText) == null) {
      _tinggiBadanError = 'Format tinggi badan tidak valid';
      hasError = true;
      firstErrorKey ??= _tinggiBadanKey;
    }

    if (_hasAllergies == null) {
      _alergiError = 'Pilih apakah anak memiliki alergi atau tidak';
      hasError = true;
      firstErrorKey ??= _alergiKey;
    } else if (_hasAllergies == true && _alergiController.text.trim().isEmpty) {
      _alergiDetailError = 'Sebutkan alergi yang dimiliki anak';
      hasError = true;
      firstErrorKey ??= _alergiDetailKey;
    }

    if (hasError) {
      setState(() {});
      if (firstErrorKey?.currentContext != null) {
        Scrollable.ensureVisible(
          firstErrorKey!.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final weight = double.tryParse(_beratBadanController.text.trim());
      final height = double.tryParse(_tinggiBadanController.text.trim());

      final updatedChild = ChildModel(
        id: widget.child.id,
        name: _namaController.text.trim(),
        gender: _selectedGender!,
        ageDescription: _calculatedAgeString ?? widget.child.ageDescription,
        birthDate: _selectedBirthDate,
        weightKg: weight,
        heightCm: height,
        headCircumferenceCm: widget.child.headCircumferenceCm,
        photoUrl: _fotoProfilPath,
        birthPhotoUrl: _fotoKelahiranPath,
        isPremature: widget.child.isPremature,
        gestationalAgeWeeks: widget.child.gestationalAgeWeeks,
        hasAllergies: _hasAllergies,
        allergies: _hasAllergies == true ? _alergiController.text.trim() : null,
      );

      // Perbarui record pada ChildService reaktif
      ChildService().updateChild(updatedChild);

      if (!mounted) return;
      setState(() => _isSaving = false);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const BerandaPage(
            showAddSuccessSnackbar: true,
            addSuccessMessage: 'Data profil anak berhasil diperbarui',
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnackBar('Gagal memperbarui data, coba lagi', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.lato(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isError
            ? const Color(0xFFDC2626)
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: !_isFormChanged,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _showExitConfirmationDialog();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // 1. Header Bar (Jarak 56dp dari tepi atas layar)
            _buildHeader(topPadding),

            // 2. Konten Form Scrollable (Margin 16dp kiri-kanan)
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // 1. Foto Profil ('Unggah Foto Anda')
                    _buildFotoProfilSection(),
                    const SizedBox(height: 12),

                    // Usia Anak Badge jika tanggal lahir terpilih
                    if (_calculatedAgeString != null) ...[
                      _buildUsiaBadge(),
                      const SizedBox(height: 18),
                    ] else ...[
                      const SizedBox(height: 12),
                    ],

                    // 2. Nama Lengkap*
                    Container(key: _namaKey),
                    _buildNamaLengkapField(),
                    const SizedBox(height: 14),

                    // 3. Tanggal Lahir*
                    Container(key: _tanggalLahirKey),
                    _buildTanggalLahirField(),
                    const SizedBox(height: 14),

                    // 4. Jenis Kelamin* (Laki-laki = Biru, Perempuan = Pink)
                    Container(key: _genderKey),
                    _buildJenisKelaminSection(),
                    const SizedBox(height: 18),

                    // Divider tipis sebelum Data Kelahiran
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 18),

                    // Section: Data Kelahiran (hanya berisi field Foto Si Kecil)
                    Text(
                      'Data Kelahiran',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFotoSiKecilSection(),
                    const SizedBox(height: 14),

                    // 5. Berat Badan Saat Lahir (kg)*
                    Container(key: _beratBadanKey),
                    _buildBeratBadanField(),
                    const SizedBox(height: 14),

                    // 6. Tinggi Badan Saat Lahir (cm)*
                    Container(key: _tinggiBadanKey),
                    _buildTinggiBadanField(),
                    const SizedBox(height: 18),

                    // Divider tipis sebelum Alergi
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 18),

                    // 8. Alergi*
                    Container(key: _alergiKey),
                    _buildAlergiSection(),

                    // Kondisional: Sebutkan Alergi
                    if (_hasAllergies == true) ...[
                      const SizedBox(height: 14),
                      Container(key: _alergiDetailKey),
                      _buildAlergiDetailField(),
                    ],
                    const SizedBox(height: 24),

                    // 9. Tombol Simpan
                    _buildSimpanButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. HEADER BAR TETAP
  // - Memiliki jarak 56dp dari tepi atas layar
  // - Tombol back 12dp dari tepi kiri layar
  // - Judul 'Ubah Data Profil' 12dp setelah tombol back
  // - Tombol 'Hapus' teks merah di pojok kanan header, sejajar judul
  // ---------------------------------------------------------------------------
  Widget _buildHeader(double topPadding) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(top: math.max(topPadding, 56.0), bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.only(left: 12.0, right: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Tombol Kembali (12dp dari tepi kiri)
            GestureDetector(
              onTap: _handleBackNavigation,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(
                  Icons.arrow_back,
                  color: Color(0xFF0F172A),
                  size: 24,
                ),
              ),
            ),
            // Jarak 12dp setelah tombol kembali
            const SizedBox(width: 12),
            // Judul Header
            Text(
              'Ubah Data Profil',
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            // Tombol 'Hapus' teks merah plain
            GestureDetector(
              onTap: _showDeleteConfirmationDialog,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4.0,
                  vertical: 8.0,
                ),
                child: Text(
                  'Hapus',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE74C3C),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FOTO PROFIL ANAK (UNGGAH FOTO ANDA)
  // ---------------------------------------------------------------------------
  Widget _buildFotoProfilSection() {
    final hasPhoto = _fotoProfilPath != null && _fotoProfilPath!.isNotEmpty;
    final isLocal = hasPhoto && File(_fotoProfilPath!).existsSync();

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              if (hasPhoto) {
                _openFullScreenPhoto(_fotoProfilPath!, 'avatar_foto_profil');
              } else {
                _showImagePickerModal(isBirthPhoto: false);
              }
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF8FAFC),
                  ),
                  child: CustomPaint(
                    painter: _DashedCirclePainter(
                      color: const Color(0xFF93C5FD),
                      strokeWidth: 1.5,
                      dashLength: 5,
                      dashSpace: 3,
                    ),
                    child: ClipOval(
                      child: hasPhoto
                          ? (isLocal
                                ? Image.file(
                                    File(_fotoProfilPath!),
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                  )
                                : Image.asset(
                                    'assets/images/default_baby_avatar.png',
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Center(
                                              child: Icon(
                                                Icons.child_care,
                                                size: 44,
                                                color: Color(0xFF3985E7),
                                              ),
                                            ),
                                  ))
                          : const Center(
                              child: Icon(
                                Icons.person_add_alt_1_rounded,
                                size: 36,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _showImagePickerModal(isBirthPhoto: false),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3985E7),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        hasPhoto ? Icons.edit : Icons.camera_alt,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasPhoto ? 'Ubah Foto Profil' : 'Unggah Foto Anda',
            style: GoogleFonts.lato(
              fontSize: 13,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // USIA ANAK BADGE
  // ---------------------------------------------------------------------------
  Widget _buildUsiaBadge() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cake_outlined, size: 16, color: Color(0xFF3985E7)),
            const SizedBox(width: 6),
            Text(
              'Usia: $_calculatedAgeString',
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1D4ED8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FIELD: NAMA LENGKAP*
  // ---------------------------------------------------------------------------
  Widget _buildNamaLengkapField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Nama Lengkap', isRequired: true),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: TextField(
            controller: _namaController,
            focusNode: _namaFocus,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s'.\-]")),
            ],
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _pickBirthDate(),
            style: GoogleFonts.lato(
              fontSize: 14,
              color: const Color(0xFF0F172A),
            ),
            decoration: _inputDecoration(
              hint: 'Contoh: Arga Pratama',
              hasError: _namaError != null,
            ),
          ),
        ),
        if (_namaError != null) _buildErrorText(_namaError!),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FIELD: TANGGAL LAHIR*
  // ---------------------------------------------------------------------------
  Widget _buildTanggalLahirField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Tanggal Lahir', isRequired: true),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickBirthDate,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 48,
            child: IgnorePointer(
              child: TextField(
                controller: _birthDateController,
                readOnly: true,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: const Color(0xFF0F172A),
                ),
                decoration: _inputDecoration(
                  hint: 'DD/MM/YYYY',
                  suffixIcon: Icons.calendar_month_outlined,
                  hasError: _tanggalLahirError != null,
                ),
              ),
            ),
          ),
        ),
        if (_tanggalLahirError != null) _buildErrorText(_tanggalLahirError!),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FIELD: JENIS KELAMIN* (Laki-laki = Biru #3985E7, Perempuan = Pink)
  // ---------------------------------------------------------------------------
  Widget _buildJenisKelaminSection() {
    final isLaki = _selectedGender == 'Laki-laki';
    final isPerempuan = _selectedGender == 'Perempuan';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Jenis Kelamin', isRequired: true),
        const SizedBox(height: 8),
        Row(
          children: [
            // Opsi Laki-laki
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = 'Laki-laki';
                    _genderError = null;
                  });
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isLaki ? const Color(0xFFEFF6FF) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isLaki
                          ? const Color(0xFF3985E7)
                          : const Color(0xFFC5C5C5),
                      width: isLaki ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isLaki
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isLaki
                            ? const Color(0xFF3985E7)
                            : const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Laki-laki',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: isLaki
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isLaki
                              ? const Color(0xFF3985E7)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Opsi Perempuan
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = 'Perempuan';
                    _genderError = null;
                  });
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isPerempuan ? const Color(0xFFFDF2F8) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPerempuan
                          ? const Color(0xFFEC4899)
                          : const Color(0xFFC5C5C5),
                      width: isPerempuan ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPerempuan
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isPerempuan
                            ? const Color(0xFFEC4899)
                            : const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Perempuan',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: isPerempuan
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isPerempuan
                              ? const Color(0xFFEC4899)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_genderError != null) _buildErrorText(_genderError!),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FIELD: BERAT BADAN SAAT LAHIR (KG)*
  // ---------------------------------------------------------------------------
  Widget _buildBeratBadanField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Berat Badan Saat Lahir (kg)', isRequired: true),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: TextField(
            controller: _beratBadanController,
            focusNode: _beratBadanFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _tinggiBadanFocus.requestFocus(),
            style: GoogleFonts.lato(
              fontSize: 14,
              color: const Color(0xFF0F172A),
            ),
            decoration: _inputDecoration(
              hint: 'Contoh: 3.2',
              suffixText: 'kg',
              hasError: _beratBadanError != null,
            ),
          ),
        ),
        if (_beratBadanError != null) _buildErrorText(_beratBadanError!),
        if (_beratBadanWarning != null && _beratBadanError == null)
          _buildWarningText(_beratBadanWarning!),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FIELD: TINGGI BADAN SAAT LAHIR (CM)*
  // ---------------------------------------------------------------------------
  Widget _buildTinggiBadanField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Tinggi Badan Saat Lahir (cm)', isRequired: true),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: TextField(
            controller: _tinggiBadanController,
            focusNode: _tinggiBadanFocus,
            keyboardType: const TextInputFormattersDecimal(),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            style: GoogleFonts.lato(
              fontSize: 14,
              color: const Color(0xFF0F172A),
            ),
            decoration: _inputDecoration(
              hint: 'Contoh: 49.5',
              suffixText: 'cm',
              hasError: _tinggiBadanError != null,
            ),
          ),
        ),
        if (_tinggiBadanError != null) _buildErrorText(_tinggiBadanError!),
        if (_tinggiBadanWarning != null && _tinggiBadanError == null)
          _buildWarningText(_tinggiBadanWarning!),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FOTO SI KECIL (DATA KELAHIRAN)
  // ---------------------------------------------------------------------------
  Widget _buildFotoSiKecilSection() {
    final hasBirthPhoto =
        _fotoKelahiranPath != null && _fotoKelahiranPath!.isNotEmpty;
    final isLocal = hasBirthPhoto && File(_fotoKelahiranPath!).existsSync();

    return GestureDetector(
      onTap: () {
        if (hasBirthPhoto) {
          _openFullScreenPhoto(_fotoKelahiranPath!, 'birth_photo_preview');
        } else {
          _showImagePickerModal(isBirthPhoto: true);
        }
      },
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomPaint(
          painter: _DashedRRectPainter(
            color: const Color(0xFFCBD5E1),
            radius: 8,
            strokeWidth: 1.5,
            dashLength: 6,
            dashSpace: 4,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: hasBirthPhoto
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      isLocal
                          ? Image.file(
                              File(_fotoKelahiranPath!),
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              'assets/images/default_baby_avatar.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Icon(
                                      Icons.photo,
                                      size: 48,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                            ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () =>
                              _showImagePickerModal(isBirthPhoto: true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Ganti',
                                  style: GoogleFonts.lato(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 36,
                          color: Color(0xFF3985E7),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Foto Si Kecil',
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3985E7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Unggah momen kenangan kelahiran si kecil',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FIELD: ALERGI*
  // ---------------------------------------------------------------------------
  Widget _buildAlergiSection() {
    final hasAllergy = _hasAllergies == true;
    final noAllergy = _hasAllergies == false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Alergi', isRequired: true),
        const SizedBox(height: 8),
        Row(
          children: [
            // Opsi Ada
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _hasAllergies = true;
                    _alergiError = null;
                  });
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: hasAllergy ? const Color(0xFFEFF6FF) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasAllergy
                          ? const Color(0xFF3985E7)
                          : const Color(0xFFC5C5C5),
                      width: hasAllergy ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        hasAllergy
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: hasAllergy
                            ? const Color(0xFF3985E7)
                            : const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ada',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: hasAllergy
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: hasAllergy
                              ? const Color(0xFF3985E7)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Opsi Tidak
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _hasAllergies = false;
                    _alergiError = null;
                    _alergiController.clear();
                    _alergiDetailError = null;
                  });
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: noAllergy ? const Color(0xFFEFF6FF) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: noAllergy
                          ? const Color(0xFF3985E7)
                          : const Color(0xFFC5C5C5),
                      width: noAllergy ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        noAllergy
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: noAllergy
                            ? const Color(0xFF3985E7)
                            : const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tidak',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: noAllergy
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: noAllergy
                              ? const Color(0xFF3985E7)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_alergiError != null) _buildErrorText(_alergiError!),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FIELD KONDISIONAL: SEBUTKAN ALERGI*
  // ---------------------------------------------------------------------------
  Widget _buildAlergiDetailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Sebutkan Alergi', isRequired: true),
        const SizedBox(height: 6),
        SizedBox(
          height: 48,
          child: TextField(
            controller: _alergiController,
            focusNode: _alergiFocus,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            style: GoogleFonts.lato(
              fontSize: 14,
              color: const Color(0xFF0F172A),
            ),
            decoration: _inputDecoration(
              hint: 'Contoh: Susu sapi, seafood, telur',
              hasError: _alergiDetailError != null,
            ),
          ),
        ),
        if (_alergiDetailError != null) _buildErrorText(_alergiDetailError!),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TOMBOL SIMPAN
  // ---------------------------------------------------------------------------
  Widget _buildSimpanButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3985E7),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          disabledBackgroundColor: const Color(0xFF93C5FD),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'Simpan',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FIXED BOTTOM NAVIGATION BAR
  // ---------------------------------------------------------------------------
  Widget _buildBottomNavigationBar() {
    const navItems = [
      _NavData(icon: Icons.home_rounded, label: 'Beranda'),
      _NavData(icon: Icons.chat_outlined, label: 'Konsultasi'),
      _NavData(icon: Icons.history_rounded, label: 'Riwayat'),
      _NavData(icon: Icons.person_outline_rounded, label: 'Profil'),
    ];

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navItems.length, (index) {
          final item = navItems[index];
          final isSelected = index == _selectedNavIndex;
          return _buildNavItem(
            icon: item.icon,
            label: item.label,
            isSelected: isSelected,
            onTap: () {
              if (index == _selectedNavIndex) return;
              if (index == 0) {
                _handleBackNavigation();
              } else if (index == 1) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DaftarDokterPage()),
                );
              } else if (index == 2) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DaftarRiwayatPage()),
                );
              } else if (index == 3) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MenuProfilPage()),
                );
              }
            },
          );
        }),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? const Color(0xFF3985E7)
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF3985E7)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------
  Widget _buildLabel(String label, {bool isRequired = false}) {
    return Text.rich(
      TextSpan(
        text: label,
        style: GoogleFonts.lato(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
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

  InputDecoration _inputDecoration({
    required String hint,
    IconData? suffixIcon,
    String? suffixText,
    bool hasError = false,
  }) {
    final borderColor = hasError
        ? const Color(0xFFEF4444)
        : const Color(0xFFC5C5C5);

    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.lato(fontSize: 14, color: const Color(0xFFC5C5C5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      suffixIcon: suffixIcon != null
          ? Icon(suffixIcon, size: 20, color: const Color(0xFF94A3B8))
          : null,
      suffixText: suffixText,
      suffixStyle: GoogleFonts.lato(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF64748B),
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: hasError ? const Color(0xFFEF4444) : const Color(0xFF3985E7),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildErrorText(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 2.0),
      child: Text(
        error,
        style: GoogleFonts.lato(
          fontSize: 12,
          color: const Color(0xFFEF4444),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildWarningText(String warning) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 2.0),
      child: Text(
        warning,
        style: GoogleFonts.lato(
          fontSize: 12,
          color: const Color(0xFFD97706),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _NavData {
  final IconData icon;
  final String label;
  const _NavData({required this.icon, required this.label});
}

class TextInputFormattersDecimal extends TextInputType {
  const TextInputFormattersDecimal() : super.numberWithOptions(decimal: true);
}

// ---------------------------------------------------------------------------
// CUSTOM PAINTER: DASHED CIRCLE BORDER
// ---------------------------------------------------------------------------
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashSpace;

  _DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final radius = size.width / 2;
    final circumference = 2 * math.pi * radius;
    final totalDash = dashLength + dashSpace;
    final count = (circumference / totalDash).floor();
    if (count <= 0) return;
    final adjustedDashLength =
        (circumference / count) * (dashLength / totalDash);
    final adjustedDashSpace = (circumference / count) * (dashSpace / totalDash);

    double currentAngle = 0;
    for (int i = 0; i < count; i++) {
      final sweepAngle = adjustedDashLength / radius;
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(radius, radius),
          radius: radius - strokeWidth / 2,
        ),
        currentAngle,
        sweepAngle,
        false,
        paint,
      );
      currentAngle += sweepAngle + (adjustedDashSpace / radius);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

// ---------------------------------------------------------------------------
// CUSTOM PAINTER: DASHED ROUNDED RECTANGLE BORDER
// ---------------------------------------------------------------------------
class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double dashSpace;

  _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final nextDistance = distance + dashLength;
        final extractPath = metric.extractPath(
          distance,
          nextDistance > metric.length ? metric.length : nextDistance,
        );
        canvas.drawPath(extractPath, paint);
        distance += dashLength + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
