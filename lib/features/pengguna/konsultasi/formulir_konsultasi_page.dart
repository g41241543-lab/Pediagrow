import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/child_model.dart';
import '../../../models/consultation_model.dart';
import '../../../models/doctor_model.dart';
import 'chat_konsultasi_page.dart';
import '../../../shared/widgets/pedia_banner.dart';

/// Halaman "Formulir Konsultasi" PediaGrow.
///
/// Halaman ini digunakan pengguna untuk melengkapi informasi berat badan,
/// tinggi badan, dan keluhan anak sebelum memulai sesi konsultasi chat dokter.
class FormulirKonsultasiPage extends StatefulWidget {
  final DoctorModel? doctor;
  final ConsultationModel? consultation;
  final ChildModel? child;
  final String? namaAnak;
  final String? jenisKelamin;
  final String? usiaAnak;

  const FormulirKonsultasiPage({
    super.key,
    this.doctor,
    this.consultation,
    this.child,
    this.namaAnak,
    this.jenisKelamin,
    this.usiaAnak,
  });

  @override
  State<FormulirKonsultasiPage> createState() => _FormulirKonsultasiPageState();
}

class _FormulirKonsultasiPageState extends State<FormulirKonsultasiPage> {
  // Palet Warna Resmi PediaGrow & Spesifikasi Desain Figma
  static const Color colorPrimaryBlue = Color(0xFF2A85FF);
  static const Color colorSoftBlue = Color(0xFFEBF5FF);
  static const Color colorIconBoxBlue = Color(0xFFE2F0FE);
  static const Color colorCardBg = Color(0xFFF8FAFC);
  static const Color colorTextPrimary = Color(0xFF1A202C);
  static const Color colorTextSecondary = Color(0xFF4A5568);
  static const Color colorTextMuted = Color(0xFF718096);
  static const Color colorBorder = Color(0xFFE2E8F0);
  static const Color colorGreenSuccess = Color(0xFF48BB78);
  static const Color colorPeachAvatar = Color(0xFFFFEDEB);
  static const Color colorAmberTip = Color(0xFFFFB300);

  // Controllers untuk input form
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _complaintController;

  // FocusNodes untuk navigasi keyboard yang halus
  final FocusNode _weightFocusNode = FocusNode();
  final FocusNode _heightFocusNode = FocusNode();
  final FocusNode _complaintFocusNode = FocusNode();

  // State validasi & realtime counter
  String? _weightError;
  String? _heightError;
  String? _complaintError;
  int _complaintCharCount = 0;
  static const int _maxComplaintChars = 500;

  // Data anak teresolusi (dinamis dengan fallback aman)
  late String _effectiveGender;
  late String _effectiveAge;
  late String _effectiveName;

  @override
  void initState() {
    super.initState();

    _resolveChildData();

    final initWeight = widget.child?.weightKg != null && widget.child!.weightKg! > 0
        ? (widget.child!.weightKg! % 1 == 0
            ? widget.child!.weightKg!.toInt().toString()
            : widget.child!.weightKg!.toString())
        : '';
    final initHeight = widget.child?.heightCm != null && widget.child!.heightCm! > 0
        ? (widget.child!.heightCm! % 1 == 0
            ? widget.child!.heightCm!.toInt().toString()
            : widget.child!.heightCm!.toString())
        : '';

    _weightController = TextEditingController(text: initWeight);
    _heightController = TextEditingController(text: initHeight);
    _complaintController = TextEditingController();

    _complaintController.addListener(() {
      final text = _complaintController.text;
      if (text.length != _complaintCharCount) {
        setState(() {
          _complaintCharCount = text.length;
          if (_complaintError != null && text.trim().isNotEmpty) {
            _complaintError = null;
          }
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mendukung penerimaan argumen navigasi via RouteSettings jika ada
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ChildModel) {
      setState(() {
        _effectiveName = args.name;
        _effectiveGender = args.gender;
        _effectiveAge = args.birthDate != null
            ? _calculateChildAge(args.birthDate!)
            : args.ageDescription;
        if (args.weightKg != null && args.weightKg! > 0 && _weightController.text.isEmpty) {
          _weightController.text = args.weightKg! % 1 == 0
              ? args.weightKg!.toInt().toString()
              : args.weightKg!.toString();
        }
        if (args.heightCm != null && args.heightCm! > 0 && _heightController.text.isEmpty) {
          _heightController.text = args.heightCm! % 1 == 0
              ? args.heightCm!.toInt().toString()
              : args.heightCm!.toString();
        }
      });
    } else if (args is Map<String, dynamic>) {
      setState(() {
        if (args['namaAnak'] != null) _effectiveName = args['namaAnak'];
        if (args['jenisKelamin'] != null) _effectiveGender = args['jenisKelamin'];
        if (args['usiaAnak'] != null) _effectiveAge = args['usiaAnak'];
      });
    }
  }

  /// Menyiapkan data anak secara dinamis dari parameter atau fallback aman
  void _resolveChildData() {
    if (widget.child != null) {
      _effectiveName = widget.child!.name;
      _effectiveGender = widget.child!.gender;
      _effectiveAge = widget.child!.birthDate != null
          ? _calculateChildAge(widget.child!.birthDate!)
          : widget.child!.ageDescription;
    } else {
      _effectiveName = widget.namaAnak ?? 'Kaia Anastasya';
      _effectiveGender = widget.jenisKelamin ?? 'Perempuan';
      _effectiveAge = widget.usiaAnak ?? '1 tahun 3 bulan 3 hari';
    }
  }

  String _calculateChildAge(DateTime birthDate) {
    final now = DateTime.now();
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

    if (years > 0) {
      return '$years tahun $months bulan $days hari';
    } else if (months > 0) {
      return '$months bulan $days hari';
    } else {
      return '$days hari';
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _complaintController.dispose();
    _weightFocusNode.dispose();
    _heightFocusNode.dispose();
    _complaintFocusNode.dispose();
    super.dispose();
  }

  // ===========================================================================
  // VALIDASI FORM & NAVIGASI
  // ===========================================================================

  bool _validateForm() {
    bool isValid = true;

    final weightText = _weightController.text.trim();
    if (weightText.isEmpty) {
      _weightError = 'Berat badan belum diisi.';
      isValid = false;
    } else {
      final parsedWeight = double.tryParse(weightText.replaceAll(',', '.'));
      if (parsedWeight == null || parsedWeight <= 0) {
        _weightError = 'Format berat badan tidak valid (contoh: 10.5).';
        isValid = false;
      } else {
        _weightError = null;
      }
    }

    final heightText = _heightController.text.trim();
    if (heightText.isEmpty) {
      _heightError = 'Tinggi badan belum diisi.';
      isValid = false;
    } else {
      final parsedHeight = double.tryParse(heightText.replaceAll(',', '.'));
      if (parsedHeight == null || parsedHeight <= 0) {
        _heightError = 'Format tinggi badan tidak valid (contoh: 85.0).';
        isValid = false;
      } else {
        _heightError = null;
      }
    }

    final complaintText = _complaintController.text.trim();
    if (complaintText.isEmpty) {
      _complaintError = 'Keluhan belum diisi.';
      isValid = false;
    } else {
      _complaintError = null;
    }

    setState(() {});
    return isValid;
  }

  void _handleSubmit() {
    // Tutup keyboard
    FocusScope.of(context).unfocus();

    if (!_validateForm()) {
      // Tampilkan notifikasi singkat jika ada field yang belum diisi
      PediaBanner.showError(
        context,
        message: 'Mohon lengkapi seluruh data formulir terlebih dahulu.',
      );
      return;
    }

    // Persiapkan data yang telah diisi untuk dikirim ke chat dokter
    final double weight = double.parse(
      _weightController.text.trim().replaceAll(',', '.'),
    );
    final double height = double.parse(
      _heightController.text.trim().replaceAll(',', '.'),
    );
    final String complaint = _complaintController.text.trim();

    final childData = widget.child ??
        ChildModel(
          id: 'child-${DateTime.now().millisecondsSinceEpoch}',
          name: _effectiveName,
          gender: _effectiveGender,
          ageDescription: _effectiveAge,
          weightKg: weight,
          heightCm: height,
        );

    final effectiveDoctor =
        widget.doctor ?? widget.consultation?.doctor ?? DoctorModel.defaultDoctor;

    // Navigasi ke halaman Chat Konsultasi Dokter yang sudah tersedia
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatKonsultasiPage(
          doctor: effectiveDoctor,
          consultation: widget.consultation,
          child: childData,
          weightKg: weight,
          heightCm: height,
          complaint: complaint,
        ),
      ),
    );
  }

  void _onBackPressed() {
    Navigator.of(context).maybePop();
  }

  // ===========================================================================
  // BUILD METHOD UTAMA
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Menutup keyboard ketika pengguna mengetuk di luar input
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ---------------------------------------------------------------
              // 1. HEADER TETAP (Tinggi 56dp, Tombol Back 12dp dari kiri,
              //    Judul 12dp setelah tombol back)
              // ---------------------------------------------------------------
              _buildFixedHeader(),

              // ---------------------------------------------------------------
              // 2. KONTEN SCROLLABLE (Padding horizontal 16dp)
              // ---------------------------------------------------------------
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card "Lengkapi Form Konsultasi"
                      _buildInfoBannerCard(),
                      const SizedBox(height: 18),

                      // Informasi "Data Anak"
                      _buildChildInfoSection(),
                      const SizedBox(height: 18),

                      // Card "Berat Badan Saat Ini"
                      _buildWeightCard(),
                      const SizedBox(height: 16),

                      // Card "Tinggi Badan Saat Ini"
                      _buildHeightCard(),
                      const SizedBox(height: 16),

                      // Card "Keluhan"
                      _buildComplaintCard(),
                      const SizedBox(height: 16),

                      // Card "Tips"
                      _buildTipsCard(),
                      const SizedBox(height: 16),

                      // Card "Informasi Penting"
                      _buildImportantInfoCard(),
                      const SizedBox(height: 24),

                      // Button "Lanjutkan Chat Dokter"
                      _buildSubmitButton(),
                      const SizedBox(height: 14),

                      // Footer Keamanan "Data Anda aman dan terlindungi"
                      _buildSecurityFooter(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. HEADER TETAP (56dp)
  // ===========================================================================

  Widget _buildFixedHeader() {
    return Container(
      height: 56,
      width: double.infinity,
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tombol back berjarak tepat 12dp dari pinggir kiri layar
          const SizedBox(width: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _onBackPressed,
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: colorTextPrimary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          // Jarak 12dp setelah posisi tombol back menuju judul halaman
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Formulir Konsultasi',
              style: GoogleFonts.lato(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: colorTextPrimary,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. CARD "LENGKAPI FORM KONSULTASI"
  // ===========================================================================

  Widget _buildInfoBannerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorSoftBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ikon Dokumen Biru
          Container(
            padding: const EdgeInsets.all(2),
            child: const Icon(
              Icons.description_outlined,
              color: colorPrimaryBlue,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          // Judul & Deskripsi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lengkapi Form Konsultasi',
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colorTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mohon lengkapi data berikut agar dokter dapat memahami kondisi anak Anda dengan lebih baik.',
                  style: GoogleFonts.lato(
                    fontSize: 12.5,
                    color: colorTextSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. INFORMASI "DATA ANAK"
  // ===========================================================================

  Widget _buildChildInfoSection() {
    final hasCustomName =
        _effectiveName.isNotEmpty && _effectiveName.toLowerCase() != 'anak';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar Anak Lingkaran Proporsional (Anti-peyang)
        _buildChildAvatar(),
        const SizedBox(width: 14),

        // Teks "Data Anak" dan Subtitle Dinamis
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hasCustomName ? 'Data Anak ($_effectiveName)' : 'Data Anak',
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colorTextPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '$_effectiveGender, $_effectiveAge',
                style: GoogleFonts.lato(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: colorTextSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChildAvatar() {
    const double size = 48;
    final isGirl = _effectiveGender.toLowerCase().contains('perempuan');

    // Background: jika cewe berwarna pink, jika cowo berwarna biru
    final bgColor = isGirl ? const Color(0xFFFFD1DC) : const Color(0xFFCCE4FF);
    final borderColor =
        isGirl ? const Color(0xFFF687B3) : const Color(0xFF63B3ED);

    final photoUrl = widget.child?.photoUrl;
    final hasPhoto = photoUrl != null &&
        photoUrl.isNotEmpty &&
        (photoUrl.startsWith('assets/') || File(photoUrl).existsSync());

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? (photoUrl.startsWith('assets/')
              ? Image.asset(
                  photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildDefaultBabyIcon(),
                )
              : Image.file(
                  File(photoUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildDefaultBabyIcon(),
                ))
          : _buildDefaultBabyIcon(),
    );
  }

  Widget _buildDefaultBabyIcon() {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Image.asset(
        'assets/images/default_baby_avatar.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Center(
          child: CustomPaint(
            size: const Size(34, 34),
            painter: _CuteBabyFacePainter(
              isGirl: _effectiveGender.toLowerCase().contains('perempuan'),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. CARD "BERAT BADAN SAAT INI"
  // ===========================================================================

  Widget _buildWeightCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorCardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul Card
          Text(
            'Berat Badan Saat Ini',
            style: GoogleFonts.lato(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: colorTextPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Baris: Ikon Timbangan + TextFormField + Satuan "kg"
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Kotak Ikon Soft Blue (Scale / Weight)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorIconBoxBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.scale_rounded,
                    color: colorPrimaryBlue,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Input Field Putih
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  focusNode: _weightFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.lato(
                    fontSize: 14.5,
                    color: colorTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Masukkan berat badan',
                    hintStyle: GoogleFonts.lato(
                      fontSize: 14,
                      color: const Color(0xFFA0AEC0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    isDense: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _weightError != null
                            ? const Color(0xFFE53935)
                            : colorBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: colorPrimaryBlue,
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE53935),
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    if (_weightError != null && val.trim().isNotEmpty) {
                      setState(() {
                        _weightError = null;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),

              // Satuan "kg"
              Text(
                'kg',
                style: GoogleFonts.lato(
                  fontSize: 14.5,
                  color: colorTextMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Pesan Error jika tidak valid
          if (_weightError != null) ...[
            const SizedBox(height: 4),
            Text(
              _weightError!,
              style: GoogleFonts.lato(
                fontSize: 12,
                color: const Color(0xFFE53935),
              ),
            ),
          ],

          const SizedBox(height: 6),
          // Subtext "Contoh: 10.5"
          Text(
            'Contoh: 10.5',
            style: GoogleFonts.lato(
              fontSize: 12,
              color: colorTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. CARD "TINGGI BADAN SAAT INI"
  // ===========================================================================

  Widget _buildHeightCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorCardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul Card
          Text(
            'Tinggi Badan Saat Ini',
            style: GoogleFonts.lato(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: colorTextPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Baris: Ikon Pengukur + TextFormField + Satuan "cm"
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Kotak Ikon Soft Blue (Ruler / Straighten)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorIconBoxBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.straighten_rounded,
                    color: colorPrimaryBlue,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Input Field Putih
              Expanded(
                child: TextFormField(
                  controller: _heightController,
                  focusNode: _heightFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.lato(
                    fontSize: 14.5,
                    color: colorTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Masukkan tinggi badan',
                    hintStyle: GoogleFonts.lato(
                      fontSize: 14,
                      color: const Color(0xFFA0AEC0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    isDense: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _heightError != null
                            ? const Color(0xFFE53935)
                            : colorBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: colorPrimaryBlue,
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE53935),
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    if (_heightError != null && val.trim().isNotEmpty) {
                      setState(() {
                        _heightError = null;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),

              // Satuan "cm"
              Text(
                'cm',
                style: GoogleFonts.lato(
                  fontSize: 14.5,
                  color: colorTextMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Pesan Error jika tidak valid
          if (_heightError != null) ...[
            const SizedBox(height: 4),
            Text(
              _heightError!,
              style: GoogleFonts.lato(
                fontSize: 12,
                color: const Color(0xFFE53935),
              ),
            ),
          ],

          const SizedBox(height: 6),
          // Subtext "Contoh: 85.0"
          Text(
            'Contoh: 85.0',
            style: GoogleFonts.lato(
              fontSize: 12,
              color: colorTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. CARD "KELUHAN"
  // ===========================================================================

  Widget _buildComplaintCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorCardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Ikon Chat Bubble + Judul & Deskripsi
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorIconBoxBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: colorPrimaryBlue,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keluhan',
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ceritakan keluhan atau kondisi yang dirasakan anak saat ini.',
                      style: GoogleFonts.lato(
                        fontSize: 12.5,
                        color: colorTextSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Textarea Putih dengan Realtime Counter di Kanan Bawah
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _complaintError != null
                    ? const Color(0xFFE53935)
                    : colorBorder,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: _complaintController,
                  focusNode: _complaintFocusNode,
                  maxLength: _maxComplaintChars,
                  maxLines: 5,
                  minLines: 4,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: colorTextPrimary,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    counterText: '', // Hilangkan default counter agar rapi
                    hintText: 'Tuliskan keluhan secara detail...',
                    hintStyle: GoogleFonts.lato(
                      fontSize: 13.5,
                      color: const Color(0xFFA0AEC0),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 4),
                // Counter Realtime "0/500"
                Text(
                  '$_complaintCharCount/$_maxComplaintChars',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorTextMuted,
                  ),
                ),
              ],
            ),
          ),

          // Pesan Error jika keluhan belum diisi
          if (_complaintError != null) ...[
            const SizedBox(height: 4),
            Text(
              _complaintError!,
              style: GoogleFonts.lato(
                fontSize: 12,
                color: const Color(0xFFE53935),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // 7. CARD "TIPS"
  // ===========================================================================

  Widget _buildTipsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorSoftBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ikon Lampu Kuning / Amber
          const Icon(
            Icons.lightbulb_rounded,
            color: colorAmberTip,
            size: 24,
          ),
          const SizedBox(width: 12),
          // Judul Tips & Isi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips',
                  style: GoogleFonts.lato(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: colorPrimaryBlue,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Berikan informasi selengkap mungkin agar dokter dapat memberikan saran yang tepat.',
                  style: GoogleFonts.lato(
                    fontSize: 12.5,
                    color: colorTextSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 8. CARD "INFORMASI PENTING"
  // ===========================================================================

  Widget _buildImportantInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Ikon Gembok / Shield Biru
          Row(
            children: [
              const Icon(
                Icons.shield_rounded,
                color: colorPrimaryBlue,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Informasi Penting',
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colorTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Poin 1: Data rahasia
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: colorGreenSuccess,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Data yang anda berikan bersifat rahasia.',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: colorTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Poin 2: Data benar
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: colorGreenSuccess,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pastikan data yang diisi sudah benar.',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: colorTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 9. BUTTON "LANJUTKAN CHAT DOKTER"
  // ===========================================================================

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorPrimaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.near_me_rounded,
              size: 20,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              'Lanjutkan Chat Dokter',
              style: GoogleFonts.lato(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 10. FOOTER KEAMANAN
  // ===========================================================================

  Widget _buildSecurityFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          size: 16,
          color: colorTextMuted,
        ),
        const SizedBox(width: 6),
        Text(
          'Data Anda aman dan terlindungi',
          style: GoogleFonts.lato(
            fontSize: 12.5,
            color: colorTextMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Custom Painter untuk avatar muka anak imut yang bulat, simetris, dan proporsional (anti-peyang)
class _CuteBabyFacePainter extends CustomPainter {
  final bool isGirl;

  _CuteBabyFacePainter({required this.isGirl});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final blushPaint = Paint()
      ..color = isGirl
          ? const Color(0xFFFB7185).withOpacity(0.5)
          : const Color(0xFF60A5FA).withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final fillEyePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Lingkaran kepala simetris di tengah
    final headCenter = Offset(w * 0.5, h * 0.52);
    final headRadius = w * 0.38;

    // Telinga Kiri & Kanan simetris
    canvas.drawCircle(Offset(w * 0.12, h * 0.52), 3.8, strokePaint);
    canvas.drawCircle(Offset(w * 0.88, h * 0.52), 3.8, strokePaint);

    // Garis Kepala Bulat Sempurna
    canvas.drawCircle(headCenter, headRadius, strokePaint);

    // Rambut Bayi
    final hairPath = Path()
      ..moveTo(w * 0.38, h * 0.20)
      ..cubicTo(w * 0.42, h * 0.08, w * 0.58, h * 0.08, w * 0.62, h * 0.20);
    canvas.drawPath(hairPath, strokePaint);

    // Mata Kiri & Kanan (Lengkungan senyum ramah)
    final leftEye = Path()
      ..moveTo(w * 0.33, h * 0.47)
      ..quadraticBezierTo(w * 0.38, h * 0.42, w * 0.43, h * 0.47);
    canvas.drawPath(leftEye, strokePaint..strokeWidth = 2.0);

    final rightEye = Path()
      ..moveTo(w * 0.57, h * 0.47)
      ..quadraticBezierTo(w * 0.62, h * 0.42, w * 0.67, h * 0.47);
    canvas.drawPath(rightEye, strokePaint);

    strokePaint.strokeWidth = 1.8;

    // Pipi Merah Merona
    canvas.drawCircle(Offset(w * 0.29, h * 0.56), 3.2, blushPaint);
    canvas.drawCircle(Offset(w * 0.71, h * 0.56), 3.2, blushPaint);

    // Hidung mungil
    canvas.drawCircle(Offset(w * 0.5, h * 0.54), 1.2, fillEyePaint);

    // Senyuman Ceria Melengkung Manis
    final smilePath = Path()
      ..moveTo(w * 0.41, h * 0.64)
      ..quadraticBezierTo(w * 0.50, h * 0.74, w * 0.59, h * 0.64);
    canvas.drawPath(smilePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
