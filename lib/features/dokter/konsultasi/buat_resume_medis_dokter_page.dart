import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/doctor_service.dart';
import '../../../core/services/konsultasi_service.dart';
import '../../../core/services/resume_medis_service.dart';
import '../../../core/services/staff_auth_service.dart';
import '../../../models/booking_consultation_model.dart';
import '../../../models/child_model.dart';
import '../../../models/resume_medis_model.dart';
import '../../../models/staff_account_model.dart';
import '../../../models/user_model.dart';
import '../../../shared/widgets/pedia_banner.dart';
import 'detail_resume_medis_dokter_page.dart';

class BuatResumeMedisDokterPage extends StatefulWidget {
  final ChildModel? child;
  final UserModel? parentUser;
  final String? parentName;
  final String? doctorName;
  final String? complaint;
  final double? weightKg;
  final double? heightCm;
  final String? sessionId;
  final BookingConsultationModel? booking;

  const BuatResumeMedisDokterPage({
    super.key,
    this.child,
    this.parentUser,
    this.parentName,
    this.doctorName,
    this.complaint,
    this.weightKg,
    this.heightCm,
    this.sessionId,
    this.booking,
  });

  @override
  State<BuatResumeMedisDokterPage> createState() =>
      _BuatResumeMedisDokterPageState();
}

class _BuatResumeMedisDokterPageState extends State<BuatResumeMedisDokterPage> {
  static const Color _colorPrimaryBlue = Color(0xFF2A85FF);
  static const Color _colorTextBlack = Color(0xFF1A2228);
  static const Color _colorLabelGrey = Color(0xFF667781);
  static const Color _colorBorder = Color(0xFFE9EDEF);
  static const Color _colorSoftBlue = Color(0xFFEBF5FF);
  static const Color _colorReadOnlyBg = Color(0xFFF0F7FF);
  static const Color _colorReadOnlyBorder = Color(0xFFD6E8FA);

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _assessmentController;
  late TextEditingController _summaryController;
  late TextEditingController _recommendationsController;
  late TextEditingController _prescriptionController;

  late String _doctorName;
  late String _consultationDate;
  late String _consultationTime;
  late String _bbSaatIni;
  late String _tbSaatIni;
  late String _complaint;
  late String _childName;
  late String _parentName;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initReadOnlyData();
    _fetchSessionDataIfNeeded();
    _assessmentController = TextEditingController();
    _summaryController = TextEditingController();
    _recommendationsController = TextEditingController();
    _prescriptionController = TextEditingController();
  }

  void _initReadOnlyData() {
    final staff = StaffAuthService().currentStaff;
    _doctorName = widget.doctorName ?? staff?.name ?? 'dr. Spesialis Anak';

    final now = DateTime.now();
    const months = [
      'Januari','Februari','Maret','April','Mei','Juni',
      'Juli','Agustus','September','Oktober','November','Desember',
    ];

    final schedDate = widget.booking?.scheduledDate;
    if (schedDate != null) {
      _consultationDate = '${schedDate.day} ${months[schedDate.month - 1]} ${schedDate.year}';
    } else {
      _consultationDate = '${now.day} ${months[now.month - 1]} ${now.year}';
    }

    final slot = widget.booking?.scheduledTimeSlot;
    if (slot != null && slot.isNotEmpty) {
      _consultationTime = slot;
    } else {
      _consultationTime =
          '${now.hour.toString().padLeft(2,'0')}.${now.minute.toString().padLeft(2,'0')} WIB';
    }

    // Ambil berat badan saat ini (prioritas: formulir konsultasi > booking > child.weightKg)
    // JANGAN fallback ke birthWeightKg karena itu berat lahir!
    final bb = widget.weightKg ?? widget.booking?.weightKg ?? widget.child?.weightKg;
    _bbSaatIni = (bb != null && bb > 0)
        ? (bb % 1 == 0 ? bb.toInt().toString() : bb.toString())
        : '-';

    // Ambil tinggi badan saat ini (prioritas: formulir konsultasi > booking > child.heightCm)
    // JANGAN fallback ke birthHeightCm karena itu panjang lahir!
    final tb = widget.heightCm ?? widget.booking?.heightCm ?? widget.child?.heightCm;
    _tbSaatIni = (tb != null && tb > 0)
        ? (tb % 1 == 0 ? tb.toInt().toString() : tb.toString())
        : '-';

    final comp = widget.complaint ?? widget.booking?.complaint;
    _complaint = comp != null && comp.trim().isNotEmpty
        ? comp.trim()
        : '-';

    _childName = widget.child?.name.isNotEmpty == true
        ? widget.child!.name
        : 'Pasien Anak';

    _parentName = widget.parentUser?.name.isNotEmpty == true
        ? widget.parentUser!.name
        : widget.parentName ?? 'Orang Tua Pasien';
  }

  Future<void> _fetchSessionDataIfNeeded() async {
    final sessId = widget.sessionId;
    if (sessId == null || sessId.isEmpty) return;

    if (_bbSaatIni == '-' || _tbSaatIni == '-' || _complaint == '-') {
      try {
        final session = await KonsultasiService.instance.getSesi(sessId);
        if (session != null && mounted) {
          setState(() {
            if (_bbSaatIni == '-' && session.weightKg != null && session.weightKg! > 0) {
              final bb = session.weightKg!;
              _bbSaatIni = bb % 1 == 0 ? bb.toInt().toString() : bb.toString();
            }
            if (_tbSaatIni == '-' && session.heightCm != null && session.heightCm! > 0) {
              final tb = session.heightCm!;
              _tbSaatIni = tb % 1 == 0 ? tb.toInt().toString() : tb.toString();
            }
            if (_complaint == '-' && session.keluhanAwal != null && session.keluhanAwal!.trim().isNotEmpty) {
              _complaint = session.keluhanAwal!.trim();
            }
          });
        }
      } catch (e) {
        debugPrint('[BuatResumeMedis] Error fetching session: $e');
      }
    }
  }

  @override
  void dispose() {
    _assessmentController.dispose();
    _summaryController.dispose();
    _recommendationsController.dispose();
    _prescriptionController.dispose();
    super.dispose();
  }

  Future<void> _simpanResumeMedis() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final childId = widget.child?.id ?? '';
      final userId = widget.parentUser?.id ?? widget.child?.ownerId ?? '';
      final staff = StaffAuthService().currentStaff;

      final recs = _recommendationsController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final complaintText = _complaint == '-' ? '' : _complaint;
      final complaintShort = complaintText.length > 60
          ? '${complaintText.substring(0, 57)}...'
          : complaintText;

      final matchedDoc = staff != null ? DoctorService().findDoctorForStaff(staff) : null;
      final docId = matchedDoc?.id ?? staff?.id ?? '';
      final docPhoto = (matchedDoc?.avatarUrl != null && matchedDoc!.avatarUrl!.isNotEmpty)
          ? matchedDoc.avatarUrl
          : staff?.avatarPath;

      final resume = ResumeMedisModel(
        id: '',
        childId: childId,
        userId: userId,
        doctorId: docId,
        doctorName: _doctorName,
        doctorSpecialization: staff?.role == StaffRole.dokter
            ? 'Spesialis Anak'
            : 'Dokter Spesialis Anak',
        doctorPhoto: docPhoto,
        childName: _childName,
        childAgeAtConsultation: widget.child?.ageDescription.isNotEmpty == true
            ? widget.child!.ageDescription
            : '0 tahun',
        consultationDate: _consultationDate,
        consultationTime: _consultationTime,
        bbLahir: widget.child?.birthWeightKg ?? 0.0,
        bbSaatIni: double.tryParse(_bbSaatIni) ?? 0.0,
        tbLahir: widget.child?.birthHeightCm ?? 0.0,
        tbSaatIni: double.tryParse(_tbSaatIni) ?? 0.0,
        complaint: complaintText,
        complaintShort: complaintShort.isEmpty ? '-' : complaintShort,
        doctorAssessment: _assessmentController.text.trim(),
        summary: _summaryController.text.trim(),
        recommendations: recs,
        prescription: _prescriptionController.text.trim().isEmpty
            ? '-'
            : _prescriptionController.text.trim(),
        status: 'Selesai',
        sessionId: widget.sessionId,
        createdAt: DateTime.now(),
      );

      final newId = await ResumeMedisService().saveOrUpdateResumeMedis(resume);

      final savedResume = ResumeMedisModel(
        id: newId,
        childId: resume.childId,
        userId: resume.userId,
        doctorId: resume.doctorId,
        doctorName: resume.doctorName,
        doctorSpecialization: resume.doctorSpecialization,
        doctorPhoto: resume.doctorPhoto,
        childName: resume.childName,
        childAgeAtConsultation: resume.childAgeAtConsultation,
        consultationDate: resume.consultationDate,
        consultationTime: resume.consultationTime,
        bbLahir: resume.bbLahir,
        bbSaatIni: resume.bbSaatIni,
        tbLahir: resume.tbLahir,
        tbSaatIni: resume.tbSaatIni,
        complaint: resume.complaint,
        complaintShort: resume.complaintShort,
        doctorAssessment: resume.doctorAssessment,
        summary: resume.summary,
        recommendations: resume.recommendations,
        prescription: resume.prescription,
        status: resume.status,
        sessionId: resume.sessionId,
        createdAt: resume.createdAt,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DetailResumeMedisDokterPage(
            resume: savedResume,
            child: widget.child,
            parentUser: widget.parentUser,
            initialSuccessMessage: 'Berhasil Membuat Resume Medis',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        PediaBanner.showError(
          context,
          message: 'Gagal membuat resume medis: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _colorTextBlack),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Buat Resume Medis',
            style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _colorTextBlack)),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _colorBorder, height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPatientSummaryCard(),
                const SizedBox(height: 24),

                // ── SEKSI A: Formulir Keluhan (Read-Only) ─────────
                _buildSectionHeader(
                  'Formulir Hasil Pemeriksaan',
                  'Data diambil otomatis dari formulir keluhan pasien',
                  Icons.assignment_outlined,
                ),
                const SizedBox(height: 14),
                _buildReadOnlyField(
                    label: 'Dokter Pemeriksa',
                    value: _doctorName,
                    icon: Icons.person_outline_rounded),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: _buildReadOnlyField(
                        label: 'Tanggal Konsultasi',
                        value: _consultationDate,
                        icon: Icons.calendar_today_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildReadOnlyField(
                        label: 'Waktu Sesi',
                        value: _consultationTime,
                        icon: Icons.access_time_rounded),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: _buildReadOnlyField(
                        label: 'BB Saat Ini (kg)',
                        value: _bbSaatIni,
                        icon: Icons.scale_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildReadOnlyField(
                        label: 'TB Saat Ini (cm)',
                        value: _tbSaatIni,
                        icon: Icons.straighten_rounded),
                  ),
                ]),
                const SizedBox(height: 12),
                _buildReadOnlyComplaint(),
                const SizedBox(height: 24),

                // ── SEKSI B: Catatan Medis Dokter (Editable) ──────
                _buildSectionHeader(
                  'Catatan Medis Dokter',
                  'Lengkapi data klinis untuk rekam medis pasien',
                  Icons.medical_services_outlined,
                ),
                const SizedBox(height: 14),
                _buildEditableField(
                  label: 'Diagnosis / Asesmen Medis',
                  controller: _assessmentController,
                  icon: Icons.biotech_rounded,
                  maxLines: 3,
                  hint: 'Tulis diagnosis atau asesmen klinis...',
                ),
                const SizedBox(height: 14),
                _buildEditableField(
                  label: 'Ringkasan Konsultasi',
                  controller: _summaryController,
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                  hint: 'Ringkasan kondisi anak dan tindakan yang diambil...',
                ),
                const SizedBox(height: 14),
                _buildEditableField(
                  label: 'Anjuran / Saran Perawatan Medis',
                  controller: _recommendationsController,
                  icon: Icons.check_circle_outline_rounded,
                  maxLines: 4,
                  hint: 'Tulis anjuran satu per baris.\nContoh:\n1. Beri ASI sesering mungkin\n2. Kontrol ulang 2 minggu',
                ),
                const SizedBox(height: 14),
                _buildEditableField(
                  label: 'Resep Obat / Terapi',
                  controller: _prescriptionController,
                  icon: Icons.medication_outlined,
                  maxLines: 2,
                  hint: 'Nama obat, dosis, aturan pakai (opsional)...',
                  isRequired: false,
                ),
                const SizedBox(height: 28),

                // Tombol Simpan
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _simpanResumeMedis,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _colorPrimaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.save_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text('Simpan Resume Medis',
                                  style: GoogleFonts.lato(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _colorSoftBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E4FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.medical_information_rounded,
                color: _colorPrimaryBlue, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_childName,
                    style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _colorTextBlack)),
                const SizedBox(height: 3),
                Text('Orang Tua: $_parentName',
                    style: GoogleFonts.lato(
                        fontSize: 13, color: _colorLabelGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: _colorSoftBlue,
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _colorPrimaryBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.lato(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: _colorTextBlack)),
              Text(subtitle,
                  style: GoogleFonts.lato(
                      fontSize: 12, color: _colorLabelGrey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.lato(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _colorLabelGrey)),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: _colorReadOnlyBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _colorReadOnlyBorder),
          ),
          child: Row(
            children: [
              Icon(icon, size: 17, color: const Color(0xFF60A5FA)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value.isEmpty ? '-' : value,
                  style: GoogleFonts.lato(
                      fontSize: 13.5,
                      color: _colorTextBlack,
                      fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.lock_outline_rounded,
                  size: 14, color: Color(0xFF93C5FD)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyComplaint() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Keluhan Pasien (Anamnesa)',
            style: GoogleFonts.lato(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _colorLabelGrey)),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _colorReadOnlyBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _colorReadOnlyBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1.5),
                child: Icon(Icons.chat_bubble_outline_rounded,
                    size: 17, color: const Color(0xFF60A5FA)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _complaint.isEmpty ? '-' : _complaint,
                  style: GoogleFonts.lato(
                      fontSize: 13.5, color: _colorTextBlack, height: 1.45),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.lock_outline_rounded,
                  size: 14, color: Color(0xFF93C5FD)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    String? hint,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label,
              style: GoogleFonts.lato(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _colorTextBlack)),
          if (!isRequired)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text('(opsional)',
                  style: GoogleFonts.lato(fontSize: 11, color: _colorLabelGrey)),
            ),
        ]),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.lato(fontSize: 13.5, color: _colorTextBlack),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: GoogleFonts.lato(
                fontSize: 13, color: const Color(0xFFB0BEC5), height: 1.4),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Icon(icon, size: 20, color: _colorLabelGrey),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 44, minHeight: 44),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _colorBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _colorBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: _colorPrimaryBlue, width: 1.5),
            ),
          ),
          validator: isRequired
              ? (val) {
                  if (val == null || val.trim().isEmpty) {
                    return '$label tidak boleh kosong';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }
}
