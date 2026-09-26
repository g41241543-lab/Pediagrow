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
import '../../../shared/widgets/pedia_banner.dart';

/// Halaman Tambah Profil Anak PediaGrow.
///
/// Fitur:
/// - Custom Fixed Header 56dp dengan tombol kembali 12dp dari sisi kiri
/// - Dialog konfirmasi kembali jika ada data terisi
/// - Foto Profil Anak dengan dashed circle border & preview/zoom
/// - Validasi Nama Lengkap (hanya huruf, kapitalisasi otomatis tiap kata)
/// - Date Picker visual dengan rentang 0-5 tahun & kalkulasi usia otomatis
/// - Radio Jenis Kelamin (Laki-laki = Biru, Perempuan = Pink)
/// - Foto Si Kecil (Data Kelahiran) dengan dashed rounded box
/// - Radio Status Prematur (Ya/Tidak) dengan field usia kehamilan dinamis
/// - Input numerik desimal: Berat Badan, Tinggi Badan, Lingkar Kepala lahir
/// - Peringatan rentang wajar (warning amber) non-blocking
/// - Radio Alergi (Ada/Tidak) dengan field daftar alergi dinamis
/// - Perilaku keyboard otomatis (Next melompati field tersembunyi, Done di field terakhir)
/// - Validasi serentak dan auto-scroll ke error pertama saat tombol Simpan ditekan
/// - Bottom Navigation Bar 4 menu fixed di Scaffold
class TambahAnakPage extends StatefulWidget {
  const TambahAnakPage({super.key});

  @override
  State<TambahAnakPage> createState() => _TambahAnakPageState();
}

class _TambahAnakPageState extends State<TambahAnakPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  // GlobalKeys untuk auto-scroll ke field yang error
  final GlobalKey _namaKey = GlobalKey();
  final GlobalKey _tanggalLahirKey = GlobalKey();
  final GlobalKey _genderKey = GlobalKey();
  final GlobalKey _prematurKey = GlobalKey();
  final GlobalKey _usiaKehamilanKey = GlobalKey();
  final GlobalKey _beratBadanKey = GlobalKey();
  final GlobalKey _tinggiBadanKey = GlobalKey();
  final GlobalKey _lingkarKepalaKey = GlobalKey();
  final GlobalKey _alergiKey = GlobalKey();
  final GlobalKey _alergiDetailKey = GlobalKey();

  // Controllers
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _usiaKehamilanController =
      TextEditingController();
  final TextEditingController _beratBadanController = TextEditingController();
  final TextEditingController _tinggiBadanController = TextEditingController();
  final TextEditingController _lingkarKepalaController =
      TextEditingController();
  final TextEditingController _alergiController = TextEditingController();

  // FocusNodes
  final FocusNode _namaFocusNode = FocusNode();
  final FocusNode _usiaKehamilanFocusNode = FocusNode();
  final FocusNode _beratBadanFocusNode = FocusNode();
  final FocusNode _tinggiBadanFocusNode = FocusNode();
  final FocusNode _lingkarKepalaFocusNode = FocusNode();
  final FocusNode _alergiFocusNode = FocusNode();

  // State nilai pilihan
  DateTime? _selectedBirthDate;
  String? _calculatedAgeString;
  String? _selectedGender; // 'Laki-laki' | 'Perempuan'
  bool? _isPremature; // true = Ya, false = Tidak
  bool? _hasAllergies; // true = Ada, false = Tidak

  // State foto
  String? _fotoProfilPath;
  String? _fotoKelahiranPath;

  // State error message manual untuk radio / date
  String? _namaError;
  String? _birthDateError;
  String? _genderError;
  String? _prematurError;
  String? _usiaKehamilanError;
  String? _beratBadanError;
  String? _tinggiBadanError;
  String? _lingkarKepalaError;
  String? _alergiError;
  String? _alergiDetailError;

  // Warning non-blocking
  String? _beratBadanWarning;
  String? _tinggiBadanWarning;
  String? _lingkarKepalaWarning;
  String? _usiaKehamilanWarning;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _beratBadanController.addListener(_checkBeratBadanRange);
    _tinggiBadanController.addListener(_checkTinggiBadanRange);
    _lingkarKepalaController.addListener(_checkLingkarKepalaRange);
    _usiaKehamilanController.addListener(_checkUsiaKehamilanRange);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _birthDateController.dispose();
    _usiaKehamilanController.dispose();
    _beratBadanController.dispose();
    _tinggiBadanController.dispose();
    _lingkarKepalaController.dispose();
    _alergiController.dispose();

    _namaFocusNode.dispose();
    _usiaKehamilanFocusNode.dispose();
    _beratBadanFocusNode.dispose();
    _tinggiBadanFocusNode.dispose();
    _lingkarKepalaFocusNode.dispose();
    _alergiFocusNode.dispose();

    _scrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // PENGECEKAN RENTANG WAJAR (WARNING NON-BLOCKING)
  // ---------------------------------------------------------------------------
  void _checkBeratBadanRange() {
    final text = _beratBadanController.text.trim();
    if (text.isEmpty) {
      if (_beratBadanWarning != null) setState(() => _beratBadanWarning = null);
      return;
    }
    final val = double.tryParse(text);
    if (val != null && (val < 0.5 || val > 7.0)) {
      if (_beratBadanWarning == null) {
        setState(
          () => _beratBadanWarning =
              'Nilai ini di luar rentang umum, mohon periksa kembali',
        );
      }
    } else {
      if (_beratBadanWarning != null) {
        setState(() => _beratBadanWarning = null);
      }
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
    if (val != null && (val < 20.0 || val > 60.0)) {
      if (_tinggiBadanWarning == null) {
        setState(
          () => _tinggiBadanWarning =
              'Nilai ini di luar rentang umum, mohon periksa kembali',
        );
      }
    } else {
      if (_tinggiBadanWarning != null) {
        setState(() => _tinggiBadanWarning = null);
      }
    }
  }

  void _checkLingkarKepalaRange() {
    final text = _lingkarKepalaController.text.trim();
    if (text.isEmpty) {
      if (_lingkarKepalaWarning != null) {
        setState(() => _lingkarKepalaWarning = null);
      }
      return;
    }
    final val = double.tryParse(text);
    if (val != null && (val < 20.0 || val > 40.0)) {
      if (_lingkarKepalaWarning == null) {
        setState(
          () => _lingkarKepalaWarning =
              'Nilai ini di luar rentang umum, mohon periksa kembali',
        );
      }
    } else {
      if (_lingkarKepalaWarning != null) {
        setState(() => _lingkarKepalaWarning = null);
      }
    }
  }

  void _checkUsiaKehamilanRange() {
    final text = _usiaKehamilanController.text.trim();
    if (text.isEmpty) {
      if (_usiaKehamilanWarning != null) {
        setState(() => _usiaKehamilanWarning = null);
      }
      return;
    }
    final val = int.tryParse(text);
    if (val != null && (val < 20 || val > 42)) {
      if (_usiaKehamilanWarning == null) {
        setState(
          () => _usiaKehamilanWarning = 'Nilai ini di luar rentang umum (20-42 minggu), mohon periksa kembali',
        );
      }
    } else {
      if (_usiaKehamilanWarning != null) {
        setState(() => _usiaKehamilanWarning = null);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // CEK APAKAH FORM KOSONG
  // ---------------------------------------------------------------------------
  bool get _isFormEmpty {
    return _namaController.text.trim().isEmpty &&
        _selectedBirthDate == null &&
        _selectedGender == null &&
        _fotoProfilPath == null &&
        _fotoKelahiranPath == null &&
        _isPremature == null &&
        _usiaKehamilanController.text.trim().isEmpty &&
        _beratBadanController.text.trim().isEmpty &&
        _tinggiBadanController.text.trim().isEmpty &&
        _lingkarKepalaController.text.trim().isEmpty &&
        _hasAllergies == null &&
        _alergiController.text.trim().isEmpty;
  }

  // ---------------------------------------------------------------------------
  // NAVIGASI KEMBALI & DIALOG KONFIRMASI
  // ---------------------------------------------------------------------------
  void _handleBackAction() {
    if (_isFormEmpty) {
      _navigateBack();
    } else {
      _showDiscardConfirmationDialog();
    }
  }

  void _navigateBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const BerandaPage()));
    }
  }

  void _showDiscardConfirmationDialog() {
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFEF4444),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Data Belum Tersimpan',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Apakah Anda yakin ingin kembali? Data yang sudah diisi akan hilang.',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Lanjutkan Mengisi Profil',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogCtx).pop();
                          _navigateBack();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Ya, Kembali ke Beranda',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // PEMILIH FOTO (GALERI & KAMERA)
  // ---------------------------------------------------------------------------
  void _showImagePickerModal({required bool isBirthPhoto}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
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
                  isBirthPhoto
                      ? 'Unggah Foto Si Kecil'
                      : 'Unggah Foto Profil Anak',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 20),
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
                    'Galeri',
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    _pickAndValidateImage(
                      ImageSource.gallery,
                      isBirthPhoto: isBirthPhoto,
                    );
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
                      Icons.camera_alt_outlined,
                      color: Color(0xFF3985E7),
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Kamera',
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    _pickAndValidateImage(
                      ImageSource.camera,
                      isBirthPhoto: isBirthPhoto,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndValidateImage(
    ImageSource source, {
    required bool isBirthPhoto,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final bytes = await file.length();

      // Validasi ukuran > 5MB
      if (bytes > 5 * 1024 * 1024) {
        _showBanner('Ukuran foto terlalu besar, maksimal 5MB', isError: true);
        return;
      }

      // Validasi format file (jpg, jpeg, png)
      final ext = pickedFile.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png'].contains(ext)) {
        _showBanner(
          'Format foto tidak didukung, gunakan JPG atau PNG',
          isError: true,
        );
        return;
      }

      // Tampilkan Preview Konfirmasi
      if (mounted) {
        _showImagePreviewDialog(
          file: file,
          source: source,
          isBirthPhoto: isBirthPhoto,
        );
      }
    } on PlatformException catch (e) {
      if (e.code.contains('access_denied') || e.code.contains('permission')) {
        _showBanner('Izin akses diperlukan untuk memilih foto', isError: true);
      } else {
        _showBanner('Gagal mengakses foto: ${e.message}', isError: true);
      }
    } catch (e) {
      _showBanner('Gagal memilih foto: $e', isError: true);
    }
  }

  void _showImagePreviewDialog({
    required File file,
    required ImageSource source,
    required bool isBirthPhoto,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pratinjau Foto',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Image.file(file, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _pickAndValidateImage(
                            source,
                            isBirthPhoto: isBirthPhoto,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          source == ImageSource.camera
                              ? 'Ambil Ulang'
                              : 'Pilih Ulang',
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          setState(() {
                            if (isBirthPhoto) {
                              _fotoKelahiranPath = file.path;
                            } else {
                              _fotoProfilPath = file.path;
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3985E7),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Gunakan Foto',
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // FULLSCREEN ZOOM TAMPILAN FOTO
  // ---------------------------------------------------------------------------
  void _openFullScreenPhoto(String path, String heroTag) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        pageBuilder: (context, anim, secAnim) {
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
                        child: Image.file(File(path), fit: BoxFit.contain),
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

  // ---------------------------------------------------------------------------
  // PEMILIH TANGGAL LAHIR & KALKULASI USIA OTOMATIS
  // ---------------------------------------------------------------------------
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

      final ageStr = _calculateAge(picked, now);

      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = '$day/$month/$year';
        _calculatedAgeString = ageStr;
        _birthDateError = null;
      });
    }
  }

  String _calculateAge(DateTime birthDate, DateTime now) {
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    int days = now.day - birthDate.day;

    if (days < 0) {
      final prevMonth = DateTime(now.year, now.month, 0);
      days += prevMonth.day;
      months -= 1;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }

    if (years > 0 && months > 0) {
      return '$years tahun $months bulan';
    } else if (years > 0) {
      return '$years tahun';
    } else if (months > 0) {
      return '$months bulan $days hari';
    } else {
      return '$days hari';
    }
  }

  // ---------------------------------------------------------------------------
  // NAVIGASI KEYBOARD OTOMATIS
  // ---------------------------------------------------------------------------
  void _onNamaSubmitted() {
    if (_isPremature == true) {
      _usiaKehamilanFocusNode.requestFocus();
    } else {
      _beratBadanFocusNode.requestFocus();
    }
  }

  void _onUsiaKehamilanSubmitted() {
    _beratBadanFocusNode.requestFocus();
  }

  void _onBeratBadanSubmitted() {
    _tinggiBadanFocusNode.requestFocus();
  }

  void _onTinggiBadanSubmitted() {
    _lingkarKepalaFocusNode.requestFocus();
  }

  void _onLingkarKepalaSubmitted() {
    if (_hasAllergies == true) {
      _alergiFocusNode.requestFocus();
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  void _onAlergiSubmitted() {
    FocusScope.of(context).unfocus();
  }

  // ---------------------------------------------------------------------------
  // SIMPAN DATA & VALIDASI LENGKAP
  // ---------------------------------------------------------------------------
  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();

    String? namaErr;
    String? dateErr;
    String? genderErr;
    String? prematurErr;
    String? usiaKehamilanErr;
    String? beratErr;
    String? tinggiErr;
    String? lingkarErr;
    String? alergiErr;
    String? alergiDetailErr;

    GlobalKey? firstErrorKey;

    // 1. Nama Lengkap
    if (_namaController.text.trim().isEmpty) {
      namaErr = 'Nama lengkap wajib diisi';
      firstErrorKey ??= _namaKey;
    }

    // 2. Tanggal Lahir
    if (_selectedBirthDate == null ||
        _birthDateController.text.trim().isEmpty) {
      dateErr = 'Tanggal lahir wajib diisi';
      firstErrorKey ??= _tanggalLahirKey;
    }

    // 3. Jenis Kelamin
    if (_selectedGender == null) {
      genderErr = 'Jenis kelamin anak wajib dipilih';
      firstErrorKey ??= _genderKey;
    }

    // 4. Status Prematur
    if (_isPremature == null) {
      prematurErr = 'Status kelahiran prematur wajib dipilih';
      firstErrorKey ??= _prematurKey;
    } else if (_isPremature == true &&
        _usiaKehamilanController.text.trim().isEmpty) {
      usiaKehamilanErr = 'Usia kehamilan wajib diisi';
      firstErrorKey ??= _usiaKehamilanKey;
    }

    // 5. Berat Badan
    if (_beratBadanController.text.trim().isEmpty) {
      beratErr = 'Berat badan saat lahir wajib diisi';
      firstErrorKey ??= _beratBadanKey;
    }

    // 6. Tinggi Badan
    if (_tinggiBadanController.text.trim().isEmpty) {
      tinggiErr = 'Tinggi badan saat lahir wajib diisi';
      firstErrorKey ??= _tinggiBadanKey;
    }

    // 7. Lingkar Kepala
    if (_lingkarKepalaController.text.trim().isEmpty) {
      lingkarErr = 'Lingkar kepala saat lahir wajib diisi';
      firstErrorKey ??= _lingkarKepalaKey;
    }

    // 8. Alergi
    if (_hasAllergies == null) {
      alergiErr = 'Status alergi wajib dipilih';
      firstErrorKey ??= _alergiKey;
    } else if (_hasAllergies == true && _alergiController.text.trim().isEmpty) {
      alergiDetailErr = 'Alergi wajib disebutkan minimal satu';
      firstErrorKey ??= _alergiDetailKey;
    }

    setState(() {
      _namaError = namaErr;
      _birthDateError = dateErr;
      _genderError = genderErr;
      _prematurError = prematurErr;
      _usiaKehamilanError = usiaKehamilanErr;
      _beratBadanError = beratErr;
      _tinggiBadanError = tinggiErr;
      _lingkarKepalaError = lingkarErr;
      _alergiError = alergiErr;
      _alergiDetailError = alergiDetailErr;
    });

    if (firstErrorKey != null) {
      // Auto-scroll ke error pertama
      final contextToScroll = firstErrorKey.currentContext;
      if (contextToScroll != null) {
        Scrollable.ensureVisible(
          contextToScroll,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      }
      return;
    }

    // Seluruh field valid
    setState(() => _isSaving = true);

    try {
      await Future.delayed(const Duration(milliseconds: 400));

      final weight = double.tryParse(_beratBadanController.text.trim());
      final height = double.tryParse(_tinggiBadanController.text.trim());
      final headCirc = double.tryParse(_lingkarKepalaController.text.trim());
      final gestWeeks = _isPremature == true
          ? int.tryParse(_usiaKehamilanController.text.trim())
          : null;

      final newChild = ChildModel(
        id: 'child_${DateTime.now().millisecondsSinceEpoch}',
        name: _namaController.text.trim(),
        gender: _selectedGender!,
        ageDescription: _calculatedAgeString ?? '0 bulan',
        birthDate: _selectedBirthDate,
        weightKg: weight,
        heightCm: height,
        headCircumferenceCm: headCirc,
        photoUrl: _fotoProfilPath,
        birthPhotoUrl: _fotoKelahiranPath,
        isPremature: _isPremature,
        gestationalAgeWeeks: gestWeeks,
        hasAllergies: _hasAllergies,
        allergies: _hasAllergies == true ? _alergiController.text.trim() : null,
      );

      // Simpan ke ChildService reaktif
      ChildService().addChild(newChild);

      if (!mounted) return;

      setState(() => _isSaving = false);

      // Arahkan ke Beranda dengan flag notifikasi sukses
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const BerandaPage(showAddSuccessSnackbar: true),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showBanner('Gagal menyimpan data, coba lagi', isError: true);
    }
  }

  void _showBanner(String message, {bool isError = false}) {
    PediaBanner.show(context, message: message, isError: isError);
  }

  // ---------------------------------------------------------------------------
  // BUILD UTAMA
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackAction();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // 1. Header Tetap (56dp)
              _buildHeaderBar(),

              // 2. Konten Scrollable
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 14),

                        // Foto Profil Anak ("Unggah Foto Anda")
                        _buildFotoProfilSection(),
                        const SizedBox(height: 20),

                        // Usia Anak Badge (Jika tanggal lahir sudah dipilih)
                        if (_calculatedAgeString != null) ...[
                          _buildAgeBadge(),
                          const SizedBox(height: 14),
                        ],

                        // Nama Lengkap*
                        Container(key: _namaKey),
                        _buildNamaLengkapField(),
                        const SizedBox(height: 14),

                        // Tanggal Lahir*
                        Container(key: _tanggalLahirKey),
                        _buildTanggalLahirField(),
                        const SizedBox(height: 14),

                        // Jenis Kelamin*
                        Container(key: _genderKey),
                        _buildJenisKelaminSection(),
                        const SizedBox(height: 18),

                        // Divider tipis pemisah data kelahiran
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 18),

                        // Section: Data Kelahiran
                        Text(
                          'Data Kelahiran',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Foto Si Kecil
                        _buildFotoSiKecilSection(),
                        const SizedBox(height: 14),

                        // Apakah Anak Anda Lahir Prematur?*
                        Container(key: _prematurKey),
                        _buildPrematurSection(),

                        // Kondisional: Usia Kehamilan Saat Lahir
                        if (_isPremature == true) ...[
                          const SizedBox(height: 14),
                          Container(key: _usiaKehamilanKey),
                          _buildUsiaKehamilanField(),
                        ],
                        const SizedBox(height: 14),

                        // Berat Badan Saat Lahir (kg)*
                        Container(key: _beratBadanKey),
                        _buildBeratBadanField(),
                        const SizedBox(height: 14),

                        // Tinggi Badan Saat Lahir (cm)*
                        Container(key: _tinggiBadanKey),
                        _buildTinggiBadanField(),
                        const SizedBox(height: 14),

                        // Lingkar Kepala Saat Lahir (cm)*
                        Container(key: _lingkarKepalaKey),
                        _buildLingkarKepalaField(),
                        const SizedBox(height: 14),

                        // Alergi*
                        Container(key: _alergiKey),
                        _buildAlergiSection(),

                        // Kondisional: Sebutkan Alergi
                        if (_hasAllergies == true) ...[
                          const SizedBox(height: 14),
                          Container(key: _alergiDetailKey),
                          _buildAlergiDetailField(),
                        ],
                        const SizedBox(height: 24),

                        // Tombol Simpan
                        _buildSimpanButton(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // 3. Navigation Bar Tetap di Scaffold (68dp)
        bottomNavigationBar: _buildFixedBottomNavBar(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. HEADER BAR TETAP (56dp)
  // ---------------------------------------------------------------------------
  Widget _buildHeaderBar() {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tombol kembali 12dp dari batas kiri layar
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: InkWell(
              onTap: _handleBackAction,
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(
                  Icons.arrow_back,
                  color: Color(0xFF0F172A),
                  size: 24,
                ),
              ),
            ),
          ),
          // Jarak 12dp setelah tombol kembali
          const SizedBox(width: 12),
          // Judul Header
          Text(
            'Tambah Profil Anak',
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FOTO PROFIL ANAK (UNGGAH FOTO ANDA)
  // ---------------------------------------------------------------------------
  Widget _buildFotoProfilSection() {
    final hasPhoto = _fotoProfilPath != null;

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
                CustomPaint(
                  painter: _DashedCirclePainter(
                    color: const Color(0xFFCBD5E1),
                    strokeWidth: 1.5,
                    dashLength: 5,
                    dashSpace: 3,
                  ),
                  child: Container(
                    width: 96,
                    height: 96,
                    padding: const EdgeInsets.all(4),
                    child: ClipOval(
                      child: hasPhoto
                          ? Hero(
                              tag: 'avatar_foto_profil',
                              child: Image.file(
                                File(_fotoProfilPath!),
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              color: const Color(0xFFF1F5F9),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.person_rounded,
                                size: 52,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                    ),
                  ),
                ),
                if (hasPhoto)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () => _showImagePickerModal(isBirthPhoto: false),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3985E7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showImagePickerModal(isBirthPhoto: false),
            child: Text(
              hasPhoto ? 'Ganti Foto' : 'Unggah Foto Anda',
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
  // USIA ANAK BADGE (OTOMATIS DARI TANGGAL LAHIR)
  // ---------------------------------------------------------------------------
  Widget _buildAgeBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cake_outlined, size: 18, color: Color(0xFF3985E7)),
          const SizedBox(width: 8),
          Text(
            'Usia saat ini: ',
            style: GoogleFonts.lato(
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: const Color(0xFF1E40AF),
            ),
          ),
          Text(
            _calculatedAgeString!,
            style: GoogleFonts.lato(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1D4ED8),
            ),
          ),
        ],
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
        TextFormField(
          controller: _namaController,
          focusNode: _namaFocusNode,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s\-]")),
          ],
          onFieldSubmitted: (_) => _onNamaSubmitted(),
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0F172A),
          ),
          decoration: _inputDecoration(
            hint: 'Nama Lengkap',
            errorText: _namaError,
          ),
          onChanged: (val) {
            if (_namaError != null && val.trim().isNotEmpty) {
              setState(() => _namaError = null);
            }
          },
        ),
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
        GestureDetector(
          onTap: _pickBirthDate,
          child: AbsorbPointer(
            child: TextFormField(
              controller: _birthDateController,
              readOnly: true,
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0F172A),
              ),
              decoration: _inputDecoration(
                hint: 'DD/MM/YYYY',
                suffixIcon: Icons.calendar_month_outlined,
                errorText: _birthDateError,
              ),
            ),
          ),
        ),
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
        if (_genderError != null) ...[
          const SizedBox(height: 6),
          Text(
            _genderError!,
            style: GoogleFonts.lato(
              fontSize: 12,
              color: const Color(0xFFEF4444),
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FOTO SI KECIL (DATA KELAHIRAN)
  // ---------------------------------------------------------------------------
  Widget _buildFotoSiKecilSection() {
    final hasPhoto = _fotoKelahiranPath != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto Si Kecil',
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        if (!hasPhoto)
          GestureDetector(
            onTap: () => _showImagePickerModal(isBirthPhoto: true),
            child: CustomPaint(
              painter: _DashedRRectPainter(
                color: const Color(0xFF3985E7),
                radius: 10,
                strokeWidth: 1.5,
                dashLength: 6,
                dashSpace: 4,
              ),
              child: Container(
                width: double.infinity,
                height: 48,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, color: Color(0xFF3985E7), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '+ Unggah Foto',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3985E7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _openFullScreenPhoto(
                    _fotoKelahiranPath!,
                    'foto_si_kecil_preview',
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Hero(
                      tag: 'foto_si_kecil_preview',
                      child: Image.file(
                        File(_fotoKelahiranPath!),
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Foto Kelahiran Terpilih',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Ketuk untuk melihat ukuran penuh',
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showImagePickerModal(isBirthPhoto: true),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    'Ubah',
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3985E7),
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
  // FIELD: APAKAH LAHIR PREMATUR?*
  // ---------------------------------------------------------------------------
  Widget _buildPrematurSection() {
    final isPrematur = _isPremature == true;
    final isNotPrematur = _isPremature == false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Apakah Anak Anda Lahir Prematur?', isRequired: true),
        const SizedBox(height: 8),
        Row(
          children: [
            // Opsi Ya
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isPremature = true;
                    _prematurError = null;
                  });
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isPrematur ? const Color(0xFFEFF6FF) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPrematur
                          ? const Color(0xFF3985E7)
                          : const Color(0xFFC5C5C5),
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
                          fontWeight: isPrematur
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isPrematur
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
                    _isPremature = false;
                    _prematurError = null;
                    _usiaKehamilanController.clear();
                    _usiaKehamilanError = null;
                    _usiaKehamilanWarning = null;
                  });
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isNotPrematur
                        ? const Color(0xFFEFF6FF)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isNotPrematur
                          ? const Color(0xFF3985E7)
                          : const Color(0xFFC5C5C5),
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
                          fontWeight: isNotPrematur
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isNotPrematur
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
        if (_prematurError != null) ...[
          const SizedBox(height: 6),
          Text(
            _prematurError!,
            style: GoogleFonts.lato(
              fontSize: 12,
              color: const Color(0xFFEF4444),
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FIELD KONDISIONAL: USIA KEHAMILAN (MINGGU)*
  // ---------------------------------------------------------------------------
  Widget _buildUsiaKehamilanField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Usia Kehamilan Saat Lahir (minggu)', isRequired: true),
        const SizedBox(height: 6),
        TextFormField(
          controller: _usiaKehamilanController,
          focusNode: _usiaKehamilanFocusNode,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onFieldSubmitted: (_) => _onUsiaKehamilanSubmitted(),
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0F172A),
          ),
          decoration: _inputDecoration(
            hint: 'Contoh: 34',
            errorText: _usiaKehamilanError,
            warningText: _usiaKehamilanWarning,
          ),
          onChanged: (val) {
            if (_usiaKehamilanError != null && val.trim().isNotEmpty) {
              setState(() => _usiaKehamilanError = null);
            }
          },
        ),
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
        TextFormField(
          controller: _beratBadanController,
          focusNode: _beratBadanFocusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          onFieldSubmitted: (_) => _onBeratBadanSubmitted(),
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0F172A),
          ),
          decoration: _inputDecoration(
            hint: 'Berat Badan Saat Lahir (kg)',
            errorText: _beratBadanError,
            warningText: _beratBadanWarning,
          ),
          onChanged: (val) {
            if (_beratBadanError != null && val.trim().isNotEmpty) {
              setState(() => _beratBadanError = null);
            }
          },
        ),
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
        TextFormField(
          controller: _tinggiBadanController,
          focusNode: _tinggiBadanFocusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          onFieldSubmitted: (_) => _onTinggiBadanSubmitted(),
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0F172A),
          ),
          decoration: _inputDecoration(
            hint: 'Tinggi Badan Saat Lahir (cm)',
            errorText: _tinggiBadanError,
            warningText: _tinggiBadanWarning,
          ),
          onChanged: (val) {
            if (_tinggiBadanError != null && val.trim().isNotEmpty) {
              setState(() => _tinggiBadanError = null);
            }
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FIELD: LINGKAR KEPALA SAAT LAHIR (CM)*
  // ---------------------------------------------------------------------------
  Widget _buildLingkarKepalaField() {
    // Tombol keyboard: jika Alergi == Ada, tombolnya Next; jika tidak, tombolnya Done
    final action = (_hasAllergies == true)
        ? TextInputAction.next
        : TextInputAction.done;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Lingkar Kepala Saat Lahir (cm)', isRequired: true),
        const SizedBox(height: 6),
        TextFormField(
          controller: _lingkarKepalaController,
          focusNode: _lingkarKepalaFocusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: action,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          onFieldSubmitted: (_) => _onLingkarKepalaSubmitted(),
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0F172A),
          ),
          decoration: _inputDecoration(
            hint: 'Lingkar Kepala Saat Lahir (cm)',
            errorText: _lingkarKepalaError,
            warningText: _lingkarKepalaWarning,
          ),
          onChanged: (val) {
            if (_lingkarKepalaError != null && val.trim().isNotEmpty) {
              setState(() => _lingkarKepalaError = null);
            }
          },
        ),
      ],
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
        if (_alergiError != null) ...[
          const SizedBox(height: 6),
          Text(
            _alergiError!,
            style: GoogleFonts.lato(
              fontSize: 12,
              color: const Color(0xFFEF4444),
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FIELD KONDISIONAL: SEBUTKAN ALERGI* (FIELD TERAKHIR -> DONE)
  // ---------------------------------------------------------------------------
  Widget _buildAlergiDetailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Sebutkan Alergi (pisahkan dengan koma)', isRequired: true),
        const SizedBox(height: 6),
        TextFormField(
          controller: _alergiController,
          focusNode: _alergiFocusNode,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _onAlergiSubmitted(),
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0F172A),
          ),
          decoration: _inputDecoration(
            hint: 'Contoh: Susu sapi, Telur, Kacang',
            errorText: _alergiDetailError,
          ),
          onChanged: (val) {
            if (_alergiDetailError != null && val.trim().isNotEmpty) {
              setState(() => _alergiDetailError = null);
            }
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TOMBOL SIMPAN (ROUNDED PILL BIRU)
  // ---------------------------------------------------------------------------
  Widget _buildSimpanButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _handleSave,
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
  // 3. FIXED BOTTOM NAVIGATION BAR (68dp)
  // ---------------------------------------------------------------------------
  Widget _buildFixedBottomNavBar() {
    final navItems = [
      _NavData(icon: Icons.home_rounded, label: 'Beranda'),
      _NavData(icon: Icons.question_answer_rounded, label: 'Konsultasi'),
      _NavData(icon: Icons.manage_search_rounded, label: 'Riwayat Konsultasi'),
      _NavData(icon: Icons.person_outline_rounded, label: 'Profil Ibu'),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(navItems.length, (i) {
          final item = navItems[i];
          return GestureDetector(
            onTap: () {
              switch (i) {
                case 0:
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const BerandaPage()),
                    (route) => false,
                  );
                  break;
                case 1:
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DaftarDokterPage()),
                  );
                  break;
                case 2:
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DaftarRiwayatPage(),
                    ),
                  );
                  break;
                case 3:
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MenuProfilPage()),
                  );
                  break;
              }
            },
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 76,
              height: 68,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, size: 24, color: const Color(0xFF9E9E9E)),
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
          color: const Color(0xFF334155),
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
    String? errorText,
    String? warningText,
  }) {
    final hasError = errorText != null;
    final hasWarning = warningText != null && !hasError;

    Color borderColor = const Color(0xFFCBD5E1);
    if (hasError) {
      borderColor = const Color(0xFFEF4444);
    } else if (hasWarning) {
      borderColor = const Color(0xFFF59E0B);
    }

    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.lato(fontSize: 14, color: const Color(0xFF94A3B8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      suffixIcon: suffixIcon != null
          ? Icon(suffixIcon, size: 20, color: const Color(0xFF64748B))
          : null,
      filled: true,
      fillColor: Colors.white,
      errorText: errorText,
      helperText: hasWarning ? warningText : null,
      helperMaxLines: 2,
      helperStyle: GoogleFonts.lato(
        fontSize: 12,
        color: const Color(0xFFD97706),
        fontWeight: FontWeight.w500,
      ),
      errorMaxLines: 2,
      errorStyle: GoogleFonts.lato(
        fontSize: 12,
        color: const Color(0xFFEF4444),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: hasError
              ? const Color(0xFFEF4444)
              : (hasWarning
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF3985E7)),
          width: 1.5,
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
    );
  }
}

// ---------------------------------------------------------------------------
// DATA CLASS BOTTOM NAV
// ---------------------------------------------------------------------------
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
