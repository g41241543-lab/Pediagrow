<<<<<<< HEAD
﻿import 'package:flutter/material.dart';
=======

import 'package:flutter/material.dart';
>>>>>>> 289e71df0313336a1855296b39040c36eaa51608
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/chat_message_service.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/services/child_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/konsultasi_service.dart';
import '../../../core/services/user_service.dart';
import '../../../models/booking_consultation_model.dart';
import '../../../models/child_model.dart';
import '../../../models/consultation_model.dart';
import '../../../models/doctor_model.dart';
import 'chat_konsultasi_page.dart';
import '../../../shared/widgets/child_avatar.dart';
import '../../../shared/widgets/pedia_banner.dart';

/// Halaman "Formulir Konsultasi" PediaGrow.
///
/// Halaman ini digunakan pengguna untuk melengkapi informasi berat badan,
/// tinggi badan, dan keluhan anak sebelum memulai sesi konsultasi chat dokter.
class FormulirKonsultasiPage extends StatefulWidget {
  final DoctorModel? doctor;
  final ConsultationModel? consultation;
  final ChildModel? child;
  final BookingConsultationModel? booking;
  final String? namaAnak;
  final String? jenisKelamin;
  final String? usiaAnak;

  const FormulirKonsultasiPage({
    super.key,
    this.doctor,
    this.consultation,
    this.child,
    this.booking,
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
  static const Color colorBorder = Color(0xFFE9EDEF);
  static const Color colorGreenSuccess = Color(0xFF48BB78);
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

  // Profil anak yang sedang aktif (dari ChildService atau parameter)
  ChildModel? _activeChild;

  // Data anak teresolusi (dinamis dengan fallback aman)
  late String _effectiveGender;
  late String _effectiveAge;
  late String _effectiveName;

  @override
  void initState() {
    super.initState();

    _resolveChildData();
    ChildService().activeChildNotifier.addListener(_onActiveChildChanged);

    final selectedChild = _activeChild ?? widget.child;
    final initWeight =
        selectedChild?.weightKg != null && selectedChild!.weightKg! > 0
        ? (selectedChild.weightKg! % 1 == 0
              ? selectedChild.weightKg!.toInt().toString()
              : selectedChild.weightKg!.toString())
        : (selectedChild?.birthWeightKg != null &&
                  selectedChild!.birthWeightKg! > 0
              ? (selectedChild.birthWeightKg! % 1 == 0
                    ? selectedChild.birthWeightKg!.toInt().toString()
                    : selectedChild.birthWeightKg!.toString())
              : '');
    final initHeight =
        selectedChild?.heightCm != null && selectedChild!.heightCm! > 0
        ? (selectedChild.heightCm! % 1 == 0
              ? selectedChild.heightCm!.toInt().toString()
              : selectedChild.heightCm!.toString())
        : (selectedChild?.birthHeightCm != null &&
                  selectedChild!.birthHeightCm! > 0
              ? (selectedChild.birthHeightCm! % 1 == 0
                    ? selectedChild.birthHeightCm!.toInt().toString()
                    : selectedChild.birthHeightCm!.toString())
              : '');

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

  void _onActiveChildChanged() {
    final active = ChildService().activeChild;
    if (active != null && mounted) {
      _applyChildModel(active);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mendukung penerimaan argumen navigasi via RouteSettings jika ada
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ChildModel) {
      _applyChildModel(args);
    } else if (args is Map<String, dynamic>) {
      setState(() {
        if (args['namaAnak'] != null) _effectiveName = args['namaAnak'];
        if (args['jenisKelamin'] != null) {
          _effectiveGender = args['jenisKelamin'];
        }
        if (args['usiaAnak'] != null) _effectiveAge = args['usiaAnak'];
      });
    }
  }

  void _applyChildModel(ChildModel model) {
    setState(() {
      _activeChild = model;
      _effectiveName = model.name;
      _effectiveGender = model.gender;
      _effectiveAge = _formatChildAge(model);
      if (model.weightKg != null &&
          model.weightKg! > 0 &&
          _weightController.text.isEmpty) {
        _weightController.text = model.weightKg! % 1 == 0
            ? model.weightKg!.toInt().toString()
            : model.weightKg!.toString();
      }
      if (model.heightCm != null &&
          model.heightCm! > 0 &&
          _heightController.text.isEmpty) {
        _heightController.text = model.heightCm! % 1 == 0
            ? model.heightCm!.toInt().toString()
            : model.heightCm!.toString();
      }
    });
  }

  /// Menyiapkan data anak secara default menyesuaikan profil anak di ChildService
  void _resolveChildData() {
    _activeChild = widget.child ?? ChildService().activeChild;

    if (_activeChild != null) {
      _effectiveName = _activeChild!.name;
      _effectiveGender = _activeChild!.gender;
      _effectiveAge = _formatChildAge(_activeChild!);
    } else if (widget.namaAnak != null && widget.namaAnak!.trim().isNotEmpty) {
      _effectiveName = widget.namaAnak!;
      _effectiveGender = widget.jenisKelamin ?? 'Perempuan';
      _effectiveAge = widget.usiaAnak ?? '1 tahun 3 bulan';
    } else {
      _effectiveName = 'Kaia Anastasya';
      _effectiveGender = widget.jenisKelamin ?? 'Perempuan';
      _effectiveAge = widget.usiaAnak ?? '1 tahun 3 bulan';
    }
  }

  String _formatChildAge(ChildModel child) {
    if (child.ageDescription.trim().isNotEmpty) {
      return child.ageDescription.trim();
    }
    if (child.birthDate != null) {
      return _calculateChildAge(child.birthDate!);
    }
    return '1 tahun 3 bulan';
  }

  String _calculateChildAge(DateTime birthDate) {
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    int days = now.day - birthDate.day;

    if (days < 0) {
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
      return '$months bulan';
    } else {
      return '$days hari';
    }
  }

  @override
  void dispose() {
    ChildService().activeChildNotifier.removeListener(_onActiveChildChanged);
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

  Future<void> _handleSubmit() async {
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

    final childData =
        _activeChild?.copyWith(weightKg: weight, heightCm: height) ??
        widget.child?.copyWith(weightKg: weight, heightCm: height) ??
        ChildModel(
          id: 'child-${DateTime.now().millisecondsSinceEpoch}',
          name: _effectiveName,
          gender: _effectiveGender,
          ageDescription: _effectiveAge,
          weightKg: weight,
          heightCm: height,
        );

    final effectiveDoctor =
        widget.doctor ??
        widget.consultation?.doctor ??
        DoctorModel.defaultDoctor;

    final currentUser = UserService().currentUser;
    final parentName = currentUser.name.isNotEmpty && currentUser.name != 'Tamu'
        ? currentUser.name
        : 'Orang Tua $_effectiveName';
    final userId = currentUser.id.isNotEmpty
        ? currentUser.id
        : 'user-${DateTime.now().millisecondsSinceEpoch}';

    final targetBooking =
        widget.booking ?? BookingService().activeBookingNotifier.value;
    final desiredSessionId = targetBooking?.sessionId ?? (targetBooking != null ? 'session_${targetBooking.id}' : null);

    String? sessionId;
    try {
      sessionId = await KonsultasiService.instance.buatSesi(
        customSessionId: desiredSessionId,
        childId: childData.id,
        childName: childData.name,
        userId: userId,
        parentName: parentName,
        doctorId: effectiveDoctor.id.isNotEmpty
            ? effectiveDoctor.id
            : effectiveDoctor.name,
        doctorName: effectiveDoctor.name,
        keluhanAwal: complaint,
        weightKg: weight,
        heightCm: height,
        childPhotoUrl: childData.photoUrl,
        childGender: childData.gender,
        childAge: childData.ageDescription,
      );

      // Kirim dokumen formulir keluhan awal ke pesan chat
      await ChatMessageService.instance.kirimFormulir(
        sessionId: sessionId,
        senderId: userId,
        keluhanText: complaint,
      );
    } catch (e) {
      debugPrint('Gagal buat sesi di Firestore: $e');
    }

    if (!mounted) return;

    // Perbarui data booking aktif jika ada (BB, TB, keluhan tersinkron ke BookingService)
    if (targetBooking != null) {
      BookingService().updateBookingForm(
        bookingId: targetBooking.id,
        weightKg: weight,
        heightCm: height,
        complaint: complaint,
        sessionId: sessionId ?? desiredSessionId,
      );
    }

    final effectiveSessionId = sessionId ?? desiredSessionId ?? 'session_${DateTime.now().millisecondsSinceEpoch}';

    // Navigasi ke halaman Chat Konsultasi Dokter (pushReplacement agar pengguna tidak bisa kembali ke halaman formulir)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChatKonsultasiPage(
          doctor: effectiveDoctor,
          consultation: widget.consultation,
          child: childData,
          weightKg: weight,
          heightCm: height,
          complaint: complaint,
          sessionId: effectiveSessionId,
          userId: userId,
          booking: targetBooking,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      // Menutup keyboard ketika pengguna mengetuk di luar input
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1014) : Colors.white,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ---------------------------------------------------------------
              // 1. HEADER TETAP (Tinggi 56dp)
              // ---------------------------------------------------------------
              _buildFixedHeader(isDark),

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
                      _buildInfoBannerCard(isDark),
                      const SizedBox(height: 18),

                      // Informasi "Data Anak"
                      _buildChildInfoSection(isDark),
                      const SizedBox(height: 18),

                      // Card "Berat Badan Saat Ini"
                      _buildWeightCard(isDark),
                      const SizedBox(height: 16),

                      // Card "Tinggi Badan Saat Ini"
                      _buildHeightCard(isDark),
                      const SizedBox(height: 16),

                      // Card "Keluhan"
                      _buildComplaintCard(isDark),
                      const SizedBox(height: 16),

                      // Card "Tips"
                      _buildTipsCard(isDark),
                      const SizedBox(height: 16),

                      // Card "Informasi Penting"
                      _buildImportantInfoCard(isDark),
                      const SizedBox(height: 24),

                      // Button "Lanjutkan Chat Dokter"
                      _buildSubmitButton(),
                      const SizedBox(height: 14),

                      // Footer Keamanan "Data Anda aman dan terlindungi"
                      _buildSecurityFooter(isDark),
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

  Widget _buildFixedHeader(bool isDark) {
    return Container(
      height: 56,
      width: double.infinity,
      color: isDark ? const Color(0xFF0B1014) : Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _onBackPressed,
              child: SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: isDark ? Colors.white : colorTextPrimary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Formulir Konsultasi',
              style: GoogleFonts.lato(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE9EDEF) : colorTextPrimary,
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

  Widget _buildInfoBannerCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : colorSoftBlue,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.5)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ikon Dokumen Biru
          Container(
            padding: const EdgeInsets.all(2),
            child: Icon(
              Icons.description_outlined,
              color: isDark ? const Color(0xFF60A5FA) : colorPrimaryBlue,
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
                    color: isDark ? const Color(0xFF93C5FD) : colorTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mohon lengkapi data berikut agar dokter dapat memahami kondisi anak Anda dengan lebih baik.',
                  style: GoogleFonts.lato(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFFD1D7DB) : colorTextSecondary,
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

  Widget _buildChildInfoSection(bool isDark) {
    final hasCustomName =
        _activeChild != null ||
        (widget.namaAnak != null && widget.namaAnak!.trim().isNotEmpty);
    final allChildren = ChildService().children;
    final canSwitchChild = allChildren.length > 1;

    return InkWell(
      onTap: canSwitchChild ? () => _showChildPickerBottomSheet(isDark) : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar Anak Lingkaran Proporsional
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
                      color: isDark ? const Color(0xFFE9EDEF) : colorTextPrimary,
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
                      color: isDark ? const Color(0xFF8696A0) : colorTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (canSwitchChild)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2228) : colorSoftBlue,
                  borderRadius: BorderRadius.circular(8),
                  border: isDark ? Border.all(color: const Color(0xFF2C363D)) : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ganti',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF60A5FA) : colorPrimaryBlue,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: isDark ? const Color(0xFF60A5FA) : colorPrimaryBlue,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showChildPickerBottomSheet(bool isDark) {
    final allChildren = ChildService().children;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2228) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Anak untuk Konsultasi',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE9EDEF) : colorTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...allChildren.map((child) {
                final isSelected = child.id == _activeChild?.id;
                final isGirl = child.gender.toLowerCase().contains('perempuan');
                return InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _applyChildModel(child);
                    ChildService().setActiveChild(child);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                              : colorSoftBlue)
                          : (isDark ? const Color(0xFF0B1014) : colorCardBg),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? colorPrimaryBlue
                            : (isDark ? const Color(0xFF2C363D) : colorBorder),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isGirl
                              ? const Color(0xFFFFD1DC)
                              : const Color(0xFFCCE4FF),
                          child: Icon(
                            Icons.child_care_rounded,
                            color: isGirl
                                ? const Color(0xFFF687B3)
                                : const Color(0xFF63B3ED),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                child.name,
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? const Color(0xFFE9EDEF)
                                      : colorTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${child.gender}, ${child.ageDescription}',
                                style: GoogleFonts.lato(
                                  fontSize: 12,
                                  color: isDark
                                      ? const Color(0xFF8696A0)
                                      : colorTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: colorPrimaryBlue,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChildAvatar() {
    const double size = 48;
    final isGirl = _effectiveGender.toLowerCase().contains('perempuan');

    // Background: jika cewe berwarna pink, jika cowo berwarna biru
    final bgColor = isGirl ? const Color(0xFFFFD1DC) : const Color(0xFFCCE4FF);
    final borderColor = isGirl
        ? const Color(0xFFF687B3)
        : const Color(0xFF63B3ED);

    final photoUrl = _activeChild?.photoUrl ?? widget.child?.photoUrl;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: StorageService.buildImageWidget(
        photoUrl,
        fit: BoxFit.cover,
        placeholder: _buildDefaultBabyIcon(),
        errorWidget: _buildDefaultBabyIcon(),
      ),
    );
  }

  Widget _buildDefaultBabyIcon() {
    return ChildAvatar(gender: _effectiveGender, size: 44);
  }

  // ===========================================================================
  // 4. CARD "BERAT BADAN SAAT INI"
  // ===========================================================================

  Widget _buildWeightCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : colorCardBg,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: const Color(0xFF2C363D)) : null,
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
              color: isDark ? const Color(0xFFE9EDEF) : colorTextPrimary,
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
                  color: isDark ? const Color(0xFF0B1014) : colorIconBoxBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.scale_rounded,
                    color: isDark ? const Color(0xFF60A5FA) : colorPrimaryBlue,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Input Field
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  focusNode: _weightFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: GoogleFonts.lato(
                    fontSize: 14.5,
                    color: isDark ? const Color(0xFFE9EDEF) : colorTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Masukkan berat badan',
                    hintStyle: GoogleFonts.lato(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF667781) : const Color(0xFFA0AEC0),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0B1014) : Colors.white,
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
                            : (isDark ? const Color(0xFF2C363D) : colorBorder),
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
                      borderSide: const BorderSide(color: Color(0xFFE53935)),
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
                  color: isDark ? const Color(0xFF8696A0) : colorTextMuted,
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
              color: isDark ? const Color(0xFF667781) : colorTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. CARD "TINGGI BADAN SAAT INI"
  // ===========================================================================

  Widget _buildHeightCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : colorCardBg,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: const Color(0xFF2C363D)) : null,
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
              color: isDark ? const Color(0xFFE9EDEF) : colorTextPrimary,
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
                  color: isDark ? const Color(0xFF0B1014) : colorIconBoxBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.straighten_rounded,
                    color: isDark ? const Color(0xFF60A5FA) : colorPrimaryBlue,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Input Field
              Expanded(
                child: TextFormField(
                  controller: _heightController,
                  focusNode: _heightFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: GoogleFonts.lato(
                    fontSize: 14.5,
                    color: isDark ? const Color(0xFFE9EDEF) : colorTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Masukkan tinggi badan',
                    hintStyle: GoogleFonts.lato(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF667781) : const Color(0xFFA0AEC0),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0B1014) : Colors.white,
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
                            : (isDark ? const Color(0xFF2C363D) : colorBorder),
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
                      borderSide: const BorderSide(color: Color(0xFFE53935)),
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
                  color: isDark ? const Color(0xFF8696A0) : colorTextMuted,
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
              color: isDark ? const Color(0xFF667781) : colorTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. CARD "KELUHAN"
  // ===========================================================================

  Widget _buildComplaintCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : colorCardBg,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: const Color(0xFF2C363D)) : null,
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
                  color: isDark ? const Color(0xFF0B1014) : colorIconBoxBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: isDark ? const Color(0xFF60A5FA) : colorPrimaryBlue,
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
                        color: isDark ? const Color(0xFFE9EDEF) : colorTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ceritakan keluhan atau kondisi yang dirasakan anak saat ini.',
                      style: GoogleFonts.lato(
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFF8696A0) : colorTextSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Textarea dengan Realtime Counter di Kanan Bawah
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B1014) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _complaintError != null
                    ? const Color(0xFFE53935)
                    : (isDark ? const Color(0xFF2C363D) : colorBorder),
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
                    color: isDark ? const Color(0xFFE9EDEF) : colorTextPrimary,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    counterText: '', // Hilangkan default counter agar rapi
                    hintText: 'Tuliskan keluhan secara detail...',
                    hintStyle: GoogleFonts.lato(
                      fontSize: 13.5,
                      color: isDark ? const Color(0xFF667781) : const Color(0xFFA0AEC0),
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
                    color: isDark ? const Color(0xFF667781) : colorTextMuted,
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

  Widget _buildTipsCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E3A8A).withValues(alpha: 0.25)
            : colorSoftBlue,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: const Color(0xFF1E40AF).withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ikon Lampu Kuning / Amber
          const Icon(Icons.lightbulb_rounded, color: colorAmberTip, size: 24),
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
                    color: isDark ? const Color(0xFF93C5FD) : colorPrimaryBlue,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Berikan informasi selengkap mungkin agar dokter dapat memberikan saran yang tepat.',
                  style: GoogleFonts.lato(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFFD1D7DB) : colorTextSecondary,
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

  Widget _buildImportantInfoCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : colorBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Ikon Gembok / Shield Biru
          Row(
            children: [
              Icon(
                Icons.shield_rounded,
                color: isDark ? const Color(0xFF60A5FA) : colorPrimaryBlue,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Informasi Penting',
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE9EDEF) : colorTextPrimary,
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
                    color: isDark ? const Color(0xFFD1D7DB) : colorTextSecondary,
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
                    color: isDark ? const Color(0xFFD1D7DB) : colorTextSecondary,
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
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.near_me_rounded, size: 20, color: Colors.white),
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
      ),
    );
  }

  // ===========================================================================
  // 10. FOOTER KEAMANAN
  // ===========================================================================

  Widget _buildSecurityFooter(bool isDark) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: isDark ? const Color(0xFF667781) : colorTextMuted,
          ),
          const SizedBox(width: 6),
          Text(
            'Data Anda aman dan terlindungi',
            style: GoogleFonts.lato(
              fontSize: 12.5,
              color: isDark ? const Color(0xFF667781) : colorTextMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

