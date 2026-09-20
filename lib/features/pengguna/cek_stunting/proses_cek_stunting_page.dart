import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/local_db_service.dart';
import '../../../models/child_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../konsultasi/daftar_dokter_page.dart';
import '../profil/menu_profil_page.dart';
import '../riwayat_konsultasi/daftar_riwayat_page.dart';
import 'form_cek_stunting_page.dart';
import 'hasil_cek_stunting_page.dart';
import 'services/stunting_ml_service.dart';
import 'widgets/pego_analysis_overlay.dart';
import '../../Grafik_Pertumbuhan/services/growth_service.dart';

/// Halaman Proses Cek Stunting PediaGrow
///
/// Mengimplementasikan alur sinematik interaktif:
/// 1. UI compact, clean, soft, friendly, mobile-first, bebas overflow
/// 2. Header custom fixed 56dp (Back button 12dp dari kiri, judul 12dp setelahnya)
/// 3. Scaffold.bottomNavigationBar permanen 4 menu
/// 4. Animasi micro-interaction Pego: White fade 50% -> Black hole #484747 ->
///    Pego emergence (Spring physics 1632ms) -> Text analyzing looping dots ->
///    Reverse return -> Result sheet
/// 5. Integrasi model klasifikasi Random Forest & GridSearchCV terkalibrasi.
class ProsesCekStuntingPage extends StatefulWidget {
  final ChildModel? child;
  final String title;

  const ProsesCekStuntingPage({
    super.key,
    this.child,
    this.title = 'Cek Stunting',
  });

  @override
  State<ProsesCekStuntingPage> createState() => _ProsesCekStuntingPageState();
}

class _ProsesCekStuntingPageState extends State<ProsesCekStuntingPage>
    with TickerProviderStateMixin {
  // Konstanta Warna & Desain PediaGrow
  static const Color colorPrimaryBlue = Color(0xFF3B82F6);
  static const Color colorPastelButton = Color(0xFFCCE2FC);
  static const Color colorButtonText = Colors.white;
  static const Color colorDangerRed = Color(0xFFB13535);
  static const Color colorMintBg = Color(0xFFE6FAF4);
  static const Color colorMintBorder = Color(0xFF38D5B1);
  static const Color colorMintText = Color(0xFF0F766E);
  static const Color colorTextTitle = Color(0xFF484747);
  static const Color colorTextDark = Color(0xFF222222);
  static const Color colorBorderGrey = Color(0xFFD1D5DB);
  static const Color colorReadOnlyBg = Color(0xFFF9FAFB);
  static const Color colorNavBarBg = Color(0xFFF2EDED);

  // Controllers Form
  final TextEditingController _namaController = TextEditingController(text: 'Kaia Anastasya');
  final TextEditingController _beratLahirController = TextEditingController(text: '2.9');
  final TextEditingController _tinggiLahirController = TextEditingController(text: '50');
  final TextEditingController _beratSekarangController = TextEditingController(text: '9.1');
  final TextEditingController _tinggiSekarangController = TextEditingController(text: '77');

  final FocusNode _beratSekarangFocus = FocusNode();
  final FocusNode _tinggiSekarangFocus = FocusNode();

  // State Nilai
  String _jenisKelamin = 'Perempuan';
  DateTime _birthDate = DateTime(2025, 5, 22);
  DateTime _checkDate = DateTime(2026, 8, 26);
  bool? _isAsiEksklusif = true; // Sesuai Gambar Referensi 1 ("Ya" terpilih)

  // Error Messages
  String? _beratError;
  String? _tinggiError;
  String? _asiError;

  // Umur Otomatis
  String _calculatedAgeText = '1 tahun 3 bulan 4 Hari';

  // State Animasi & Analisis
  bool _isAnalyzing = false;
  final GlobalKey<PegoAnalysisOverlayState> _overlayKey = GlobalKey<PegoAnalysisOverlayState>();

  // Bottom Sheet Hasil State
  bool _showResultSheet = false;
  StuntingPredictionResult? _predictionResult;
  late AnimationController _sheetAnimationController;
  late Animation<double> _sheetSlideAnimation;

  @override
  void initState() {
    super.initState();
    _setupInitialData();
    _calculateAge();

    _sheetAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _sheetSlideAnimation = CurvedAnimation(
      parent: _sheetAnimationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // Listener validasi real-time
    _beratSekarangController.addListener(() {
      if (_beratError != null && _beratSekarangController.text.trim().isNotEmpty) {
        setState(() => _beratError = null);
      }
    });

    _tinggiSekarangController.addListener(() {
      if (_tinggiError != null && _tinggiSekarangController.text.trim().isNotEmpty) {
        setState(() => _tinggiError = null);
      }
    });
  }

  @override
  void dispose() {
    _namaController.dispose();
    _beratLahirController.dispose();
    _tinggiLahirController.dispose();
    _beratSekarangController.dispose();
    _tinggiSekarangController.dispose();
    _beratSekarangFocus.dispose();
    _tinggiSekarangFocus.dispose();
    _sheetAnimationController.dispose();
    super.dispose();
  }

  void _setupInitialData() {
    if (widget.child != null) {
      _namaController.text = widget.child!.name;
      _jenisKelamin = widget.child!.gender;
      if (widget.child!.birthDate != null) {
        _birthDate = widget.child!.birthDate!;
      }
      if (widget.child!.weightKg != null) {
        _beratLahirController.text = widget.child!.weightKg.toString();
      }
      if (widget.child!.heightCm != null) {
        _tinggiLahirController.text =
            widget.child!.heightCm.toString().replaceAll('.0', '');
      }
    }
  }

  void _calculateAge() {
    int years = _checkDate.year - _birthDate.year;
    int months = _checkDate.month - _birthDate.month;
    int days = _checkDate.day - _birthDate.day;

    if (days < 0) {
      final prevMonth = DateTime(_checkDate.year, _checkDate.month, 0);
      days += prevMonth.day;
      months -= 1;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }
    setState(() {
      _calculatedAgeText = '$years tahun $months bulan $days Hari';
    });
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    return '$day/$month/$year';
  }

  // ===========================================================================
  // VALIDASI & ALUR ANIMASI SINEMATIK
  // ===========================================================================

  void _onCekSekarangPressed() {
    if (_isAnalyzing) return;
    FocusScope.of(context).unfocus();

    bool isValid = true;
    String? bErr;
    String? tErr;
    String? aErr;

    final rawBerat = _beratSekarangController.text.trim().replaceAll(',', '.');
    final rawTinggi = _tinggiSekarangController.text.trim().replaceAll(',', '.');

    // 1. Validasi Berat Badan Sekarang
    if (rawBerat.isEmpty) {
      bErr = 'Berat badan sekarang wajib diisi';
      isValid = false;
    } else {
      final val = double.tryParse(rawBerat);
      if (val == null || val <= 0 || val > 60) {
        bErr = 'Format berat tidak valid (contoh: 9.1)';
        isValid = false;
      }
    }

    // 2. Validasi Tinggi Badan Sekarang
    if (rawTinggi.isEmpty) {
      tErr = 'Tinggi badan sekarang wajib diisi';
      isValid = false;
    } else {
      final val = double.tryParse(rawTinggi);
      if (val == null || val < 25 || val > 160) {
        tErr = 'Format tinggi tidak valid (contoh: 77)';
        isValid = false;
      }
    }

    // 3. Validasi ASI Eksklusif
    if (_isAsiEksklusif == null) {
      aErr = 'Silakan tentukan status ASI';
      isValid = false;
    }

    setState(() {
      _beratError = bErr;
      _tinggiError = tErr;
      _asiError = aErr;
    });

    if (!isValid) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mohon lengkapi seluruh isian wajib sebelum mengecek!',
            style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          backgroundColor: colorDangerRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Mulai Alur Animasi Pego & Black Hole Overlay
    _startPegoAnalysisFlow(
      currentWeight: double.parse(rawBerat),
      currentHeight: double.parse(rawTinggi),
    );
  }

  Future<void> _startPegoAnalysisFlow({
    required double currentWeight,
    required double currentHeight,
  }) async {
    setState(() => _isAnalyzing = true);

    final inputData = StuntingInputData(
      namaAnak: _namaController.text.trim(),
      gender: _jenisKelamin,
      birthDate: _birthDate,
      checkDate: _checkDate,
      birthWeightKg: double.tryParse(_beratLahirController.text.trim()) ?? 2.9,
      birthHeightCm: double.tryParse(_tinggiLahirController.text.trim()) ?? 50.0,
      currentWeightKg: currentWeight,
      currentHeightCm: currentHeight,
      isExclusiveBreastfeeding: _isAsiEksklusif ?? true,
    );

    StuntingPredictionResult? resultHolder;

    // Menjalankan sekuens animasi Pego sinematik
    await _overlayKey.currentState?.runSequence(
      performAnalysisTask: () async {
        try {
          // Menjalankan inferensi model Random Forest & GridSearchCV (REST API / Local Engine)
          resultHolder = await StuntingMlService.predict(inputData);

          // Simpan ke database MySQL tabel data_pertumbuhan
          final childIdInt = int.tryParse(widget.child?.id ?? '1') ?? 1;
          final statusLabel = resultHolder?.status ?? 'Normal';
          final formattedDate = _formatDate(_checkDate);

          try {
            final prefs = await SharedPreferences.getInstance();
            final idAkun = prefs.getInt('id_akun');
            await ApiService.addGrowthRecord({
              'id_anak': childIdInt,
              'tanggal': formattedDate,
              'berat_kg': currentWeight,
              'tinggi_cm': currentHeight,
              'lingkar_kepala_cm': 0.0,
              'status_stunting': statusLabel,
              'hasil_prediksi_ai': statusLabel,
              'dicatat_oleh': idAkun,
            });
          } catch (e) {
            debugPrint('Gagal simpan growth record ke MySQL: $e');
          }

          // Simpan ke database lokal SQLite jika tersedia
          try {
            await LocalDbService().insertGrowthRecord({
              'child_id': childIdInt,
              'tanggal': formattedDate,
              'berat_kg': currentWeight,
              'tinggi_cm': currentHeight,
              'lingkar_kepala_cm': 0.0,
              'synced': 1,
            }).catchError((_) => 0);
          } catch (_) {}


          // Catat ke GrowthService agar titik baru langsung muncul di Grafik Pertumbuhan
          try {
            if (widget.child != null) {
              GrowthService().addMeasurementFromStunting(
                child: widget.child!,
                weightKg: currentWeight,
                heightCm: currentHeight,
                measurementDate: _checkDate,
              );
            }
          } catch (_) {}
        } catch (e) {
          debugPrint('Error saat prediksi: $e');
        }
      },
    );

    if (!mounted) return;

    setState(() {
      _isAnalyzing = false;
      _predictionResult = resultHolder;
      _showResultSheet = true;
    });

    _sheetAnimationController.forward();
  }

  void _hideResultSheet() {
    _sheetAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() => _showResultSheet = false);
      }
    });
  }

  // ===========================================================================
  // DATE PICKERS
  // ===========================================================================

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(2018),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: colorPrimaryBlue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
      _calculateAge();
    }
  }

  Future<void> _pickCheckDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: colorPrimaryBlue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _checkDate = picked);
      _calculateAge();
    }
  }

  // ===========================================================================
  // BUILD METHOD UTAMA
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        bottomNavigationBar: _buildPermanentBottomNavigationBar(),
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // ---------------------------------------------------------------
              // 1. KONTEN UTAMA: Header Tetap 56dp + Form Scrollable
              // ---------------------------------------------------------------
              Column(
                children: [
                  // A. Custom Header Fixed 56dp (Back 12dp dari kiri, Judul 12dp setelahnya)
                  _buildCustomHeader(),

                  // B. Area Scrollable Form (Bebas Overflow)
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),

                          // Heading "Lengkapi Informasi Tentang Si Kecil!"
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Lengkapi Informasi Tentang Si Kecil!',
                              style: GoogleFonts.lato(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: colorTextTitle,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Card Formulir Lengkap
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildFormCard(),
                          ),

                          const SizedBox(height: 20),

                          // Tombol Pill "CEK SEKARANG!"
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildCekSekarangButton(),
                          ),

                          const SizedBox(height: 24),

                          // Ilustrasi Footer Menempel ke Nav Bar
                          _buildFooterLandscape(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ---------------------------------------------------------------
              // 2. OVERLAY ANIMASI PEGO & BLACK HOLE (CINEMATIC STATE FLOW)
              // ---------------------------------------------------------------
              AbsorbPointer(
                absorbing: _isAnalyzing,
                child: PegoAnalysisOverlay(
                  key: _overlayKey,
                  isVisible: _isAnalyzing,
                ),
              ),

              // ---------------------------------------------------------------
              // 3. IN-SCAFFOLD BOTTOM SHEET HASIL PREDIKSI
              // ---------------------------------------------------------------
              if (_showResultSheet)
                FadeTransition(
                  opacity: _sheetAnimationController,
                  child: GestureDetector(
                    onTap: _hideResultSheet,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                ),

              if (_showResultSheet && _predictionResult != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(_sheetSlideAnimation),
                    child: _buildResultBottomSheetContent(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. CUSTOM APP BAR / HEADER FIXED 56DP
  // ===========================================================================

  Widget _buildCustomHeader() {
    return Container(
      height: 56.0,
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tombol Kembali tepat 12dp dari sisi kiri
          InkWell(
            onTap: () {
              if (!_isAnalyzing) Navigator.maybePop(context);
            },
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF9E9E9E),
                size: 26,
              ),
            ),
          ),

          // Jarak 12dp setelah area tombol kembali
          const SizedBox(width: 12.0),

          // Judul Halaman "Cek Stunting"
          Text(
            widget.title,
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFBDBDBD),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. CARD FORMULIR CEK STUNTING (COMPACT & MODERN)
  // ===========================================================================

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            spreadRadius: 1,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Nama Lengkap
          _buildFieldTitle('Nama Lengkap'),
          const SizedBox(height: 5),
          _buildInputField(controller: _namaController, isReadOnly: true),
          const SizedBox(height: 9),

          // 2. Jenis Kelamin
          _buildFieldTitle('Jenis Kelamin'),
          const SizedBox(height: 5),
          _buildInputField(text: _jenisKelamin, isReadOnly: true),
          const SizedBox(height: 9),

          // 3. Tanggal Lahir
          _buildFieldTitle('Tanggal Lahir'),
          const SizedBox(height: 5),
          _buildDateField(dateText: _formatDate(_birthDate), onTap: _pickBirthDate),
          const SizedBox(height: 9),

          // 4. Tanggal Cek Stunting
          _buildFieldTitle('Tanggal Cek Stunting'),
          const SizedBox(height: 5),
          _buildDateField(dateText: _formatDate(_checkDate), onTap: _pickCheckDate),
          const SizedBox(height: 9),

          // 5. Berat Badan Saat Lahir
          _buildFieldTitle('Berat Badan Saat Lahir'),
          const SizedBox(height: 5),
          _buildInputField(controller: _beratLahirController, isReadOnly: true),
          const SizedBox(height: 9),

          // 6. Tinggi Badan Saat Lahir
          _buildFieldTitle('Tinggi Badan Saat Lahir'),
          const SizedBox(height: 5),
          _buildInputField(controller: _tinggiLahirController, isReadOnly: true),
          const SizedBox(height: 9),

          // 7. Berat Badan Sekarang
          _buildFieldTitle('Berat Badan Sekarang'),
          const SizedBox(height: 5),
          _buildEditableField(
            controller: _beratSekarangController,
            focusNode: _beratSekarangFocus,
            hint: 'Contoh: 9.1',
            errorText: _beratError,
          ),
          const SizedBox(height: 9),

          // 8. Tinggi Badan Sekarang
          _buildFieldTitle('Tinggi Badan Sekarang'),
          const SizedBox(height: 5),
          _buildEditableField(
            controller: _tinggiSekarangController,
            focusNode: _tinggiSekarangFocus,
            hint: 'Contoh: 77',
            errorText: _tinggiError,
          ),
          const SizedBox(height: 10),

          // 9. Pertanyaan ASI Eksklusif
          Text(
            'Apakah hingga saat ini si kecil mendapatkan ASI secara penuh?',
            style: GoogleFonts.lato(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: colorTextTitle,
            ),
          ),
          const SizedBox(height: 8),

          // Pill Option: "Tidak" dan "Ya"
          Row(
            children: [
              // Opsi "Tidak"
              Expanded(
                child: _buildAsiPill(
                  label: 'Tidak',
                  isSelected: _isAsiEksklusif == false,
                  onTap: () {
                    if (!_isAnalyzing) {
                      setState(() {
                        _isAsiEksklusif = false;
                        _asiError = null;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Opsi "Ya" (Sesuai Referensi Gambar 1 & 2)
              Expanded(
                child: _buildAsiPill(
                  label: 'Ya',
                  isSelected: _isAsiEksklusif == true,
                  onTap: () {
                    if (!_isAnalyzing) {
                      setState(() {
                        _isAsiEksklusif = true;
                        _asiError = null;
                      });
                    }
                  },
                ),
              ),
            ],
          ),

          if (_asiError != null) ...[
            const SizedBox(height: 4),
            Text(
              _asiError!,
              style: GoogleFonts.lato(fontSize: 11, color: colorDangerRed),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.lato(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF9E9E9E),
      ),
    );
  }

  Widget _buildInputField({
    TextEditingController? controller,
    String? text,
    bool isReadOnly = true,
  }) {
    return Container(
      height: 38,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isReadOnly ? colorReadOnlyBg : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorBorderGrey, width: 0.9),
      ),
      alignment: Alignment.centerLeft,
      child: controller != null
          ? TextField(
              controller: controller,
              readOnly: isReadOnly,
              style: GoogleFonts.lato(fontSize: 13, color: const Color(0xFF757575)),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            )
          : Text(
              text ?? '',
              style: GoogleFonts.lato(fontSize: 13, color: const Color(0xFF757575)),
            ),
    );
  }

  Widget _buildDateField({required String dateText, required VoidCallback onTap}) {
    return InkWell(
      onTap: _isAnalyzing ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 38,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: colorReadOnlyBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorBorderGrey, width: 0.9),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dateText,
              style: GoogleFonts.lato(fontSize: 13, color: const Color(0xFF757575)),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: Color(0xFF9E9E9E),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    String? errorText,
  }) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 38,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasError ? colorDangerRed : colorBorderGrey,
              width: hasError ? 1.2 : 0.9,
            ),
          ),
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: !_isAnalyzing,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.lato(fontSize: 13, color: colorTextDark),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: focusNode.hasFocus ? '' : hint,
              hintStyle: GoogleFonts.lato(fontSize: 13, color: Colors.grey.shade400),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 3),
          Text(
            errorText,
            style: GoogleFonts.lato(fontSize: 11, color: colorDangerRed),
          ),
        ],
      ],
    );
  }

  Widget _buildAsiPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? colorMintBg : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? colorMintBorder : colorBorderGrey,
            width: isSelected ? 1.3 : 0.9,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? colorMintText : const Color(0xFF757575),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. TOMBOL UTAMA "CEK SEKARANG!" (PASTEL BLUE PILL)
  // ===========================================================================

  Widget _buildCekSekarangButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: _isAnalyzing ? null : _onCekSekarangPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorPastelButton,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          'CEK SEKARANG!',
          style: GoogleFonts.lato(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: colorButtonText,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. FOOTER ILUSTRASI LANDSCAPE
  // ===========================================================================

  Widget _buildFooterLandscape() {
    return Container(
      width: double.infinity,
      height: 34,
      alignment: Alignment.bottomCenter,
      child: Opacity(
        opacity: 0.85,
        child: Image.asset(
          'assets/images/beranda_landscape_footer.jpg',
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  // ===========================================================================
  // 5. SCAFFOLD.BOTTOMNAVIGATIONBAR PERMANEN 4 MENU
  // ===========================================================================

  Widget _buildPermanentBottomNavigationBar() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: const BoxDecoration(
        color: colorNavBarBg,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.home_outlined,
            label: 'Beranda',
            isActive: false,
            onTap: () {
              if (!_isAnalyzing) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
          _buildNavItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Konsultasi',
            isActive: false,
            onTap: () {
              if (!_isAnalyzing) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DaftarDokterPage()),
                );
              }
            },
          ),
          _buildNavItem(
            icon: Icons.assignment_outlined,
            label: 'Riwayat Konsultasi',
            isActive: false,
            onTap: () {
              if (!_isAnalyzing) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DaftarRiwayatPage()),
                );
              }
            },
          ),
          _buildNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profil Ibu',
            isActive: false,
            onTap: () {
              if (!_isAnalyzing) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MenuProfilPage()),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 23,
              color: isActive ? colorPrimaryBlue : const Color(0xFF9E9E9E),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? colorPrimaryBlue : const Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 6. BOTTOM SHEET HASIL ANALISIS STUNTING
  // ===========================================================================

  Widget _buildResultBottomSheetContent() {
    final res = _predictionResult!;
    final isNormal = res.status == StuntingStatusCategory.normal;
    final statusColor = isNormal ? const Color(0xFF2E7D32) : colorDangerRed;
    final statusBgColor = isNormal ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header Status Badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: statusColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(
                  isNormal ? Icons.check_circle_rounded : Icons.warning_rounded,
                  color: statusColor,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        res.statusLabel,
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Akurasi: ${(res.confidenceProbability * 100).toStringAsFixed(1)}% | Z-Score (TB/U): ${res.zScoreHeightForAge.toStringAsFixed(2)} SD',
                        style: GoogleFonts.lato(
                          fontSize: 11.5,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Ringkasan Info Anak (Responsif)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: colorReadOnlyBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(child: _buildSummaryInfo('Umur Anak', _calculatedAgeText)),
                Expanded(child: _buildSummaryInfo('BB Sekarang', '${_beratSekarangController.text.trim()} kg')),
                Expanded(child: _buildSummaryInfo('TB Sekarang', '${_tinggiSekarangController.text.trim()} cm')),
                Expanded(child: _buildSummaryInfo('ASI', _isAsiEksklusif == true ? 'Penuh' : 'Tidak')),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Tombol Aksi: Tutup & Lihat Hasil Lengkap
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _hideResultSheet,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: colorBorderGrey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Tutup',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorTextDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _hideResultSheet();
                    // Konversi ke format StuntingAnalysisResult untuk halaman detail
                    final analysisRes = StuntingAnalysisResult(
                      status: _mapStatusToLegacy(res.status),
                      statusLabel: res.statusLabel,
                      zScoreHeightForAge: res.zScoreHeightForAge,
                      zScoreWeightForAge: res.zScoreWeightForAge,
                      confidenceProbability: res.confidenceProbability,
                      description: res.description,
                      recommendations: res.recommendations,
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HasilCekStuntingPage(
                          result: analysisRes,
                          namaAnak: _namaController.text.trim(),
                          jenisKelamin: _jenisKelamin,
                          usiaDeskripsi: _calculatedAgeText,
                          beratBadanSekarang: double.parse(
                              _beratSekarangController.text.trim().replaceAll(',', '.')),
                          tinggiBadanSekarang: double.parse(
                              _tinggiSekarangController.text.trim().replaceAll(',', '.')),
                          isAsiEksklusif: _isAsiEksklusif ?? true,
                          tanggalPemeriksaan: _formatDate(_checkDate),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorPrimaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Lihat Hasil Lengkap',
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
    );
  }

  Widget _buildSummaryInfo(String title, String val) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.lato(fontSize: 10.5, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.lato(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: colorTextDark,
          ),
        ),
      ],
    );
  }

  StuntingStatus _mapStatusToLegacy(StuntingStatusCategory cat) {
    switch (cat) {
      case StuntingStatusCategory.severelyStunted:
        return StuntingStatus.severelyStunted;
      case StuntingStatusCategory.berisikoStunting:
        return StuntingStatus.berisikoStunting;
      case StuntingStatusCategory.tinggi:
        return StuntingStatus.tinggi;
      case StuntingStatusCategory.normal:
        return StuntingStatus.normal;
    }
  }
}
