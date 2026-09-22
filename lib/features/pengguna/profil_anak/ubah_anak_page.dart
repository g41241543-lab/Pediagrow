import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/child_service.dart';
import '../../../models/child_model.dart';
import '../../Grafik_Pertumbuhan/pertumbuhan_grafik_page.dart';
import '../beranda/beranda_page.dart';
import '../cek_stunting/pilih_anak_page.dart';
import '../konsultasi/daftar_dokter_page.dart';
import 'hapus_anak_dialog.dart';

/// Halaman Ubah Data Profil Anak PediaGrow.
///
/// Menggunakan layout dan urutan field yang SAMA PERSIS dengan halaman
/// Tambah Profil Anak (setelah section Data Kelahiran / Foto Si Kecil dihapus):
/// 1. Foto Profil ("Unggah Foto Anda") [EDITABLE]
/// 2. Usia Anak Badge (jika tanggal lahir tersedia)
/// 3. Nama Lengkap [EDITABLE]
/// 4. Tanggal Lahir [LOCKED]
/// 5. Jenis Kelamin [LOCKED]
/// 6. Apakah Anak Anda Lahir Prematur? [LOCKED]
/// 7. Usia Kehamilan Saat Lahir (jika prematur == true) [LOCKED]
/// 8. Berat Badan Saat Lahir [LOCKED]
/// 9. Tinggi Badan Saat Lahir [LOCKED]
/// 10. Lingkar Kepala Saat Lahir [LOCKED]
/// 11. Alergi (beserta Sebutkan Alergi jika Ada) [EDITABLE]
/// 12. Tombol Simpan
///
/// HANYA 3 field yang dapat diubah: Foto Profil, Nama Lengkap, dan Alergi.
/// Interaksi dengan field locked akan memunculkan bottom sheet notifikasi
/// setinggi 1/4 layar: "Informasi ini tidak dapat diubah", tertutup otomatis
/// dalam 3 detik atau segera bila layar disentuh.
class UbahAnakPage extends StatefulWidget {
  final ChildModel child;

  const UbahAnakPage({super.key, required this.child});

  @override
  State<UbahAnakPage> createState() => _UbahAnakPageState();
}

class _UbahAnakPageState extends State<UbahAnakPage> {
  // Controller input untuk field yang editable
  late final TextEditingController _namaController;
  late final TextEditingController _alergiController;

  // Focus nodes
  final FocusNode _namaFocus = FocusNode();
  final FocusNode _alergiFocus = FocusNode();

  // Scroll controller & GlobalKey untuk auto-scroll
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _namaKey = GlobalKey();
  final GlobalKey _alergiKey = GlobalKey();
  final GlobalKey _alergiDetailKey = GlobalKey();

  // Form states (Editable)
  String? _fotoProfilPath;
  bool? _hasAllergies;

  // Form states (Locked / Disimpan sebelumnya)
  late final DateTime? _selectedBirthDate;
  late final String _birthDateFormatted;
  late final String? _calculatedAgeString;
  late final String _selectedGender;
  late final bool _isPremature;
  late final int? _gestationalAgeWeeks;
  late final String _birthWeightFormatted;
  late final String _birthHeightFormatted;
  late final String _headCircumferenceFormatted;

  // Error states untuk field editable
  String? _namaError;
  String? _alergiError;
  String? _alergiDetailError;

  bool _isSaving = false;
  bool _isLockedSheetShowing = false;

  @override
  void initState() {
    super.initState();

    // 1. Inisialisasi field editable
    _namaController = TextEditingController(text: widget.child.name);
    _fotoProfilPath = widget.child.photoUrl;
    _hasAllergies = widget.child.hasAllergies;
    _alergiController = TextEditingController(
      text: widget.child.allergies ?? '',
    );

    // 2. Inisialisasi field locked dari data tersimpan
    _selectedBirthDate = widget.child.birthDate;
    if (_selectedBirthDate != null) {
      final d = _selectedBirthDate;
      _birthDateFormatted =
          '${d.day.toString().padLeft(2, "0")}/${d.month.toString().padLeft(2, "0")}/${d.year}';
      _calculatedAgeString = widget.child.ageDescription.isNotEmpty
          ? widget.child.ageDescription
          : _calculateAgeString(d);
    } else {
      _birthDateFormatted = '-';
      _calculatedAgeString = widget.child.ageDescription.isNotEmpty
          ? widget.child.ageDescription
          : null;
    }

    _selectedGender = widget.child.gender.isNotEmpty
        ? widget.child.gender
        : 'Laki-laki';

    _isPremature = widget.child.isPremature ?? false;
    _gestationalAgeWeeks = widget.child.gestationalAgeWeeks;

    final bw = widget.child.birthWeightKg ?? widget.child.weightKg;
    _birthWeightFormatted = bw != null ? '$bw' : '-';

    final bh = widget.child.birthHeightCm ?? widget.child.heightCm;
    _birthHeightFormatted = bh != null ? '$bh' : '-';

    final hc = widget.child.headCircumferenceCm;
    _headCircumferenceFormatted = hc != null ? '$hc' : '-';
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alergiController.dispose();
    _namaFocus.dispose();
    _alergiFocus.dispose();
    _scrollController.dispose();
    super.dispose();
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

  /// Memeriksa apakah ada perubahan pada field yang editable
  bool get _isFormChanged {
    if (_namaController.text.trim() != widget.child.name) return true;
    if (_fotoProfilPath != widget.child.photoUrl) return true;
    if (_hasAllergies != widget.child.hasAllergies) return true;
    if (_hasAllergies == true &&
        _alergiController.text.trim() != (widget.child.allergies ?? '')) {
      return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // NOTIFIKASI BOTTOM SHEET FIELD TERKUNCI (1/4 LAYAR, 3 DETIK AUTO-DISMISS)
  // ---------------------------------------------------------------------------
  void _showLockedNotification() {
    if (_isLockedSheetShowing) return;
    _isLockedSheetShowing = true;

    Timer? autoDismissTimer;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      isDismissible: true,
      enableDrag: true,
      builder: (sheetContext) {
        // Otomatis tertutup dalam 3 detik jika tidak disentuh
        autoDismissTimer = Timer(const Duration(seconds: 3), () {
          if (Navigator.of(sheetContext).canPop()) {
            Navigator.of(sheetContext).pop();
          }
        });

        // Sentuhan pada area notifikasi langsung menutupnya seketika
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            autoDismissTimer?.cancel();
            if (Navigator.of(sheetContext).canPop()) {
              Navigator.of(sheetContext).pop();
            }
          },
          child: Container(
            height: MediaQuery.of(context).size.height * 0.25,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        'Informasi ini tidak dapat diubah',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      autoDismissTimer?.cancel();
      _isLockedSheetShowing = false;
    });
  }

  // ---------------------------------------------------------------------------
  // NAVIGASI KEMBALI & DIALOG KONFIRMASI
  // ---------------------------------------------------------------------------
  void _handleBackNavigation() {
    if (_isFormChanged) {
      _showExitConfirmationDialog();
    } else {
      Navigator.of(context).pop();
    }
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
            padding: const EdgeInsets.all(20.0),
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
                      'Lanjutkan Mengubah Profil',
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

  void _showDeleteConfirmationDialog() {
    HapusAnakDialog.show(
      context,
      onConfirmDelete: () {
        ChildService().deleteChild(widget.child.id);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const BerandaPage(
              showAddSuccessSnackbar: true,
              addSuccessMessage: 'Profil anak berhasil dihapus',
            ),
          ),
          (route) => false,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // FOTO PROFIL HANDLERS (EDITABLE)
  // ---------------------------------------------------------------------------
  Future<void> _pickImage(ImageSource source) async {
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
          _fotoProfilPath = picked.path;
        });
      }
    } catch (_) {
      _showSnackBar('Gagal memilih foto, coba lagi', isError: true);
    }
  }

  void _showImagePickerModal() {
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
                  'Pilih Foto Profil Anak',
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
                    _pickImage(ImageSource.camera);
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
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_fotoProfilPath != null && _fotoProfilPath!.isNotEmpty)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFEF4444),
                    ),
                    title: Text(
                      'Hapus Foto Profil',
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _fotoProfilPath = null);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openFullScreenPhoto(String path) {
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
                        tag: 'foto_profil_preview',
                        child: isLocalFile
                            ? Image.file(File(path), fit: BoxFit.contain)
                            : Image.asset(
                                'assets/images/default_baby_avatar.png',
                                fit: BoxFit.contain,
                              ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
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

  // ---------------------------------------------------------------------------
  // SIMPAN DATA (HANYA VALIDASI 3 FIELD EDITABLE)
  // ---------------------------------------------------------------------------
  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _namaError = null;
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

    if (_hasAllergies == null) {
      _alergiError = 'Status alergi wajib dipilih';
      hasError = true;
      firstErrorKey ??= _alergiKey;
    } else if (_hasAllergies == true &&
        _alergiController.text.trim().isEmpty) {
      _alergiDetailError = 'Alergi wajib disebutkan minimal satu';
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
      final updatedChild = widget.child.copyWith(
        name: nama,
        photoUrl: _fotoProfilPath,
        hasAllergies: _hasAllergies,
        allergies: _hasAllergies == true ? _alergiController.text.trim() : null,
      );

      await ChildService().updateChild(updatedChild);

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

  // ---------------------------------------------------------------------------
  // BUILD METHOD UTAMA
  // ---------------------------------------------------------------------------
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
            // 1. Header Bar (56dp jarak dari atas, back button 12dp, Hapus di kanan)
            _buildHeader(topPadding),

            // 2. Konten Form Scrollable
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),

                    // 1. Foto Profil Anak ("Unggah Foto Anda") [EDITABLE]
                    _buildFotoProfilSection(),
                    const SizedBox(height: 20),

                    // Usia Anak Badge (Jika tanggal lahir ada)
                    if (_calculatedAgeString != null) ...[
                      _buildAgeBadge(),
                      const SizedBox(height: 14),
                    ],

                    // 2. Nama Lengkap* [EDITABLE]
                    Container(key: _namaKey),
                    _buildNamaLengkapField(),
                    const SizedBox(height: 14),

                    // 3. Tanggal Lahir* [LOCKED]
                    _buildLockedTanggalLahirField(),
                    const SizedBox(height: 14),

                    // 4. Jenis Kelamin* [LOCKED]
                    _buildLockedJenisKelaminSection(),
                    const SizedBox(height: 18),

                    // 5. Apakah Anak Anda Lahir Prematur?* [LOCKED]
                    _buildLockedPrematurSection(),

                    // Kondisional: Usia Kehamilan Saat Lahir [LOCKED]
                    if (_isPremature) ...[
                      const SizedBox(height: 14),
                      _buildLockedUsiaKehamilanField(),
                    ],
                    const SizedBox(height: 14),

                    // 6. Berat Badan Saat Lahir (kg)* [LOCKED]
                    _buildLockedBeratBadanField(),
                    const SizedBox(height: 14),

                    // 7. Tinggi Badan Saat Lahir (cm)* [LOCKED]
                    _buildLockedTinggiBadanField(),
                    const SizedBox(height: 14),

                    // 8. Lingkar Kepala Saat Lahir (cm)* [LOCKED]
                    _buildLockedLingkarKepalaField(),
                    const SizedBox(height: 14),

                    // 9. Alergi* [EDITABLE]
                    Container(key: _alergiKey),
                    _buildAlergiSection(),

                    // Kondisional: Sebutkan Alergi [EDITABLE]
                    if (_hasAllergies == true) ...[
                      const SizedBox(height: 14),
                      Container(key: _alergiDetailKey),
                      _buildAlergiDetailField(),
                    ],
                    const SizedBox(height: 24),

                    // 10. Tombol Simpan
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
            const SizedBox(width: 12),
            Text(
              'Ubah Data Profil',
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            // Tombol 'Hapus' teks merah di kanan
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
  // FOTO PROFIL ANAK (UNGGAH FOTO ANDA) [EDITABLE]
  // ---------------------------------------------------------------------------
  Widget _buildFotoProfilSection() {
    final hasPhoto = _fotoProfilPath != null && _fotoProfilPath!.isNotEmpty;
    final isLocal = hasPhoto && File(_fotoProfilPath!).existsSync();

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: hasPhoto
                ? () => _openFullScreenPhoto(_fotoProfilPath!)
                : _showImagePickerModal,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!hasPhoto)
                  CustomPaint(
                    painter: _DashedCirclePainter(
                      color: const Color(0xFF3985E7),
                      strokeWidth: 2.0,
                      dashLength: 8,
                      dashSpace: 5,
                    ),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF0F6FE),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: Color(0xFF3985E7),
                          size: 34,
                        ),
                      ),
                    ),
                  )
                else
                  Hero(
                    tag: 'foto_profil_preview',
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF3985E7),
                          width: 2.0,
                        ),
                        image: DecorationImage(
                          image: isLocal
                              ? FileImage(File(_fotoProfilPath!))
                              : const AssetImage(
                                  'assets/images/default_baby_avatar.png',
                                ) as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                if (hasPhoto)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showImagePickerModal,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3985E7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _showImagePickerModal,
            child: Text(
              hasPhoto ? 'Ubah Foto Profil' : 'Unggah Foto Anda',
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
  // USIA ANAK BADGE (OTOMATIS TAMPIL JIKA TANGGAL LAHIR TERSEDIA)
  // ---------------------------------------------------------------------------
  Widget _buildAgeBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cake_outlined,
            color: Color(0xFF3985E7),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usia Saat Ini',
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _calculatedAgeString ?? '-',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E40AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FIELD: NAMA LENGKAP* [EDITABLE]
  // ---------------------------------------------------------------------------
  Widget _buildNamaLengkapField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Nama Lengkap', isRequired: true),
        const SizedBox(height: 6),
        TextFormField(
          controller: _namaController,
          focusNode: _namaFocus,
          textCapitalization: TextCapitalization.words,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s.,'-]")),
          ],
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0F172A),
          ),
          decoration: _inputDecoration(
            hint: 'Nama Lengkap Anak',
            hasError: _namaError != null,
          ),
          onChanged: (val) {
            if (_namaError != null && val.trim().isNotEmpty) {
              setState(() => _namaError = null);
            }
          },
        ),
        if (_namaError != null) _buildErrorText(_namaError!),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER: WRAPPER FIELD LOCKED
  // Menangani sentuhan pengguna dan memunculkan bottom sheet 1/4 layar
  // ---------------------------------------------------------------------------
  Widget _buildLockedContainer({required Widget child}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _showLockedNotification,
      child: IgnorePointer(
        child: child,
      ),
    );
  }

  Widget _buildLockedBox({
    required String value,
    String? suffix,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF334155),
              ),
            ),
          ),
          if (suffix != null)
            Text(
              suffix,
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          if (icon != null)
            Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FIELD: TANGGAL LAHIR* [LOCKED]
  // ---------------------------------------------------------------------------
  Widget _buildLockedTanggalLahirField() {
    return _buildLockedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Tanggal Lahir', isRequired: true),
          const SizedBox(height: 6),
          _buildLockedBox(
            value: _birthDateFormatted,
            icon: Icons.calendar_today_rounded,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FIELD: JENIS KELAMIN* [LOCKED]
  // ---------------------------------------------------------------------------
  Widget _buildLockedJenisKelaminSection() {
    final isLaki = _selectedGender == 'Laki-laki';
    final isPerempuan = _selectedGender == 'Perempuan';

    return _buildLockedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Jenis Kelamin', isRequired: true),
          const SizedBox(height: 8),
          Row(
            children: [
              // Laki-laki
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isLaki
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isLaki
                          ? const Color(0xFF3985E7)
                          : const Color(0xFFE2E8F0),
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
                          fontWeight:
                              isLaki ? FontWeight.bold : FontWeight.w500,
                          color: isLaki
                              ? const Color(0xFF3985E7)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Perempuan
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isPerempuan
                        ? const Color(0xFFFDF2F8)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPerempuan
                          ? const Color(0xFFEC4899)
                          : const Color(0xFFE2E8F0),
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
                          fontWeight:
                              isPerempuan ? FontWeight.bold : FontWeight.w500,
                          color: isPerempuan
                              ? const Color(0xFFEC4899)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FIELD: APAKAH ANAK LAHIR PREMATUR?* [LOCKED]
  // ---------------------------------------------------------------------------
  Widget _buildLockedPrematurSection() {
    final isPrematur = _isPremature == true;
    final isNotPrematur = _isPremature == false;

    return _buildLockedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Apakah Anak Anda Lahir Prematur?', isRequired: true),
          const SizedBox(height: 8),
          Row(
            children: [
              // Ya
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isPrematur
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPrematur
                          ? const Color(0xFF3985E7)
                          : const Color(0xFFE2E8F0),
                      width: isPrematur ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPrematur
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isPrematur
                            ? const Color(0xFF3985E7)
                            : const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ya',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight:
                              isPrematur ? FontWeight.bold : FontWeight.w500,
                          color: isPrematur
                              ? const Color(0xFF3985E7)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Tidak
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isNotPrematur
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isNotPrematur
                          ? const Color(0xFF3985E7)
                          : const Color(0xFFE2E8F0),
                      width: isNotPrematur ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isNotPrematur
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isNotPrematur
                            ? const Color(0xFF3985E7)
                            : const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tidak',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight:
                              isNotPrematur ? FontWeight.bold : FontWeight.w500,
                          color: isNotPrematur
                              ? const Color(0xFF3985E7)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FIELD: USIA KEHAMILAN SAAT LAHIR [LOCKED]
  // ---------------------------------------------------------------------------
  Widget _buildLockedUsiaKehamilanField() {
    return _buildLockedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Usia Kehamilan Saat Lahir (minggu)', isRequired: true),
          const SizedBox(height: 6),
          _buildLockedBox(
            value: _gestationalAgeWeeks != null ? '$_gestationalAgeWeeks' : '-',
            suffix: 'minggu',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FIELD: BERAT BADAN SAAT LAHIR [LOCKED]
  // ---------------------------------------------------------------------------
  Widget _buildLockedBeratBadanField() {
    return _buildLockedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Berat Badan Saat Lahir (kg)', isRequired: true),
          const SizedBox(height: 6),
          _buildLockedBox(
            value: _birthWeightFormatted,
            suffix: 'kg',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FIELD: TINGGI BADAN SAAT LAHIR [LOCKED]
  // ---------------------------------------------------------------------------
  Widget _buildLockedTinggiBadanField() {
    return _buildLockedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Tinggi Badan Saat Lahir (cm)', isRequired: true),
          const SizedBox(height: 6),
          _buildLockedBox(
            value: _birthHeightFormatted,
            suffix: 'cm',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FIELD: LINGKAR KEPALA SAAT LAHIR [LOCKED]
  // ---------------------------------------------------------------------------
  Widget _buildLockedLingkarKepalaField() {
    return _buildLockedContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Lingkar Kepala Saat Lahir (cm)', isRequired: true),
          const SizedBox(height: 6),
          _buildLockedBox(
            value: _headCircumferenceFormatted,
            suffix: 'cm',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FIELD: ALERGI* [EDITABLE]
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
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _alergiFocus.requestFocus();
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
                    _alergiDetailError = null;
                    _alergiController.clear();
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
                          fontWeight:
                              noAllergy ? FontWeight.bold : FontWeight.w500,
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
  // FIELD KONDISIONAL: SEBUTKAN ALERGI* [EDITABLE]
  // ---------------------------------------------------------------------------
  Widget _buildAlergiDetailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Sebutkan Alergi', isRequired: true),
        const SizedBox(height: 6),
        TextFormField(
          controller: _alergiController,
          focusNode: _alergiFocus,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0F172A),
          ),
          decoration: _inputDecoration(
            hint: 'Contoh: Susu sapi, seafood, kacang-kacangan',
            hasError: _alergiDetailError != null,
          ),
          onChanged: (val) {
            if (_alergiDetailError != null && val.trim().isNotEmpty) {
              setState(() => _alergiDetailError = null);
            }
          },
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
  // BOTTOM NAVIGATION BAR TETAP DI HALAMAN
  // ---------------------------------------------------------------------------
  Widget _buildBottomNavigationBar() {
    const navItems = [
      _NavData(icon: Icons.home_rounded, label: 'Beranda'),
      _NavData(icon: Icons.favorite_border_rounded, label: 'Cek Stunting'),
      _NavData(icon: Icons.insert_chart_outlined_rounded, label: 'Grafik'),
      _NavData(icon: Icons.chat_outlined, label: 'Konsultasi'),
    ];

    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navItems.length, (index) {
          final item = navItems[index];
          final isSelected = index == 0;

          return GestureDetector(
            onTap: () {
              if (index == 0) {
                _handleBackNavigation();
              } else if (index == 1) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PilihAnakPage()),
                );
              } else if (index == 2) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PertumbuhanGrafikPage(child: widget.child),
                  ),
                );
              } else if (index == 3) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DaftarDokterPage()),
                );
              }
            },
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    size: 24,
                    color: isSelected
                        ? const Color(0xFF3985E7)
                        : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF3985E7)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
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
    final borderColor =
        hasError ? const Color(0xFFEF4444) : const Color(0xFFC5C5C5);

    return InputDecoration(
      hintText: hint,
      hintStyle:
          GoogleFonts.lato(fontSize: 14, color: const Color(0xFFC5C5C5)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
          color: hasError
              ? const Color(0xFFEF4444)
              : const Color(0xFF3985E7),
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
}

class _NavData {
  final IconData icon;
  final String label;
  const _NavData({required this.icon, required this.label});
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
    final adjustedDashSpace =
        (circumference / count) * (dashSpace / totalDash);

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
