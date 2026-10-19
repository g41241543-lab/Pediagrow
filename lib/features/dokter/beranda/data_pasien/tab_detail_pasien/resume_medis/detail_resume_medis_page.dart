import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../core/services/resume_medis_service.dart';
import '../../../../../../models/child_model.dart';
import '../../../../../../models/resume_medis_model.dart';
import '../../../../../../models/user_model.dart';
import '../../../../../../shared/widgets/pedia_banner.dart';

/// Halaman Detail Resume Medis versi Dokter.
///
/// Menggunakan desain modern card & input container (selaras dengan screenshot & BuatResumeMedisDokterPage).
/// - Header bersih (hanya tombol kembali dan judul "Detail Resume Medis").
/// - Data pemeriksaan & anamnesis pasien (read-only).
/// - Tombol "Edit Resume Medis" diletakkan di bawah setelah formulir.
/// - Saat mode edit aktif, muncul tombol "Batal" dan "Simpan Perubahan" di bagian bawah.
class DetailResumeMedisPage extends StatefulWidget {
  final ResumeMedisModel resume;
  final ChildModel? child;
  final UserModel? parentUser;
  final String? initialSuccessMessage;

  const DetailResumeMedisPage({
    super.key,
    required this.resume,
    this.child,
    this.parentUser,
    this.initialSuccessMessage,
  });

  @override
  State<DetailResumeMedisPage> createState() => _DetailResumeMedisPageState();
}

class _DetailResumeMedisPageState extends State<DetailResumeMedisPage> {
  static const Color _colorPrimaryBlue = Color(0xFF2A85FF);
  static const Color _colorTextBlack = Color(0xFF1A2228);
  static const Color _colorLabelGrey = Color(0xFF667781);
  static const Color _colorBorder = Color(0xFFE9EDEF);
  static const Color _colorSoftBlue = Color(0xFFEBF5FF);
  static const Color _colorReadOnlyBg = Color(0xFFF8FAFC);
  static const Color _colorReadOnlyBorder = Color(0xFFE9EDEF);

  bool _isEditing = false;
  bool _isSaving = false;

  late TextEditingController _assessmentCtrl;
  late TextEditingController _summaryCtrl;
  late TextEditingController _recommendationsCtrl;
  late TextEditingController _prescriptionCtrl;

  late ResumeMedisModel _resume;

  @override
  void initState() {
    super.initState();
    _resume = widget.resume;
    _initControllers();
    if (widget.initialSuccessMessage != null &&
        widget.initialSuccessMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          PediaBanner.showSuccess(
            context,
            message: widget.initialSuccessMessage!,
          );
        }
      });
    }
  }

  void _initControllers() {
    _assessmentCtrl = TextEditingController(text: _resume.doctorAssessment);
    _summaryCtrl = TextEditingController(text: _resume.summary);
    _recommendationsCtrl = TextEditingController(
      text: _resume.recommendations.join('\n'),
    );
    _prescriptionCtrl = TextEditingController(
      text: _resume.prescription == '-' ? '' : _resume.prescription,
    );
  }

  @override
  void dispose() {
    _assessmentCtrl.dispose();
    _summaryCtrl.dispose();
    _recommendationsCtrl.dispose();
    _prescriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_resume.id.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      final recs = _recommendationsCtrl.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final updatedData = {
        'doctor_assessment': _assessmentCtrl.text.trim(),
        'summary': _summaryCtrl.text.trim(),
        'recommendations': recs,
        'prescription': _prescriptionCtrl.text.trim().isEmpty
            ? '-'
            : _prescriptionCtrl.text.trim(),
      };

      await ResumeMedisService().updateResumeMedis(_resume.id, updatedData);

      setState(() {
        _resume = ResumeMedisModel(
          id: _resume.id,
          childId: _resume.childId,
          userId: _resume.userId,
          doctorName: _resume.doctorName,
          doctorSpecialization: _resume.doctorSpecialization,
          doctorPhoto: _resume.doctorPhoto,
          childName: _resume.childName,
          childAgeAtConsultation: _resume.childAgeAtConsultation,
          consultationDate: _resume.consultationDate,
          consultationTime: _resume.consultationTime,
          bbLahir: _resume.bbLahir,
          bbSaatIni: _resume.bbSaatIni,
          tbLahir: _resume.tbLahir,
          tbSaatIni: _resume.tbSaatIni,
          complaint: _resume.complaint,
          complaintShort: _resume.complaintShort,
          doctorAssessment: _assessmentCtrl.text.trim(),
          summary: _summaryCtrl.text.trim(),
          recommendations: recs,
          prescription: _prescriptionCtrl.text.trim().isEmpty
              ? '-'
              : _prescriptionCtrl.text.trim(),
          status: _resume.status,
          sessionId: _resume.sessionId,
          createdAt: _resume.createdAt,
        );
        _isEditing = false;
      });

      if (mounted) {
        PediaBanner.showSuccess(
          context,
          message: 'Berhasil Memperbarui Resume Medis',
        );
      }
    } catch (e) {
      if (mounted) {
        PediaBanner.showError(
          context,
          message: 'Gagal memperbarui resume medis: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDeleteResume() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.54),
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          elevation: 8,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hapus Data',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Mohon pastikan ulang sebelum menghapus resume medis. Apakah anda yakin ingin menghapus?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: const Color(0xFF7F7F7F),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(true),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(
                              color: Color(0xFFC5C5C5),
                              width: 1.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            'Ya',
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3985E7),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            'Tidak',
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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

    if (confirmed == true && mounted) {
      try {
        await ResumeMedisService().deleteResumeMedis(_resume.id);
        if (mounted) {
          final nav = Navigator.of(context);
          nav.pop('deleted');
          PediaBanner.showSuccess(
            nav.context,
            message: 'Berhasil Menghapus Resume Medis',
          );
        }
      } catch (e) {
        if (mounted) {
          PediaBanner.showError(
            context,
            message: 'Gagal menghapus resume medis: $e',
          );
        }
      }
    }
  }

  void _cancelEdit() {
    _assessmentCtrl.text = _resume.doctorAssessment;
    _summaryCtrl.text = _resume.summary;
    _recommendationsCtrl.text = _resume.recommendations.join('\n');
    _prescriptionCtrl.text =
        _resume.prescription == '-' ? '' : _resume.prescription;
    setState(() => _isEditing = false);
  }

  String _formatNum(double? numVal) {
    if (numVal == null) return '-';
    if (numVal == numVal.toInt()) {
      return numVal.toInt().toString();
    }
    return numVal.toString();
  }

  @override
  Widget build(BuildContext context) {
    final childName = _resume.childName.isNotEmpty
        ? _resume.childName
        : widget.child?.name ?? 'Pasien Anak';
    final parentName = widget.parentUser?.name ?? 'Orang Tua $childName';

    final bbVal = _resume.bbSaatIni > 0
        ? _formatNum(_resume.bbSaatIni)
        : (widget.child?.birthWeightKg != null
            ? _formatNum(widget.child!.birthWeightKg!)
            : '-');
    final tbVal = _resume.tbSaatIni > 0
        ? _formatNum(_resume.tbSaatIni)
        : (widget.child?.birthHeightCm != null
            ? _formatNum(widget.child!.birthHeightCm!)
            : '-');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _colorTextBlack),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Detail Resume Medis',
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _colorTextBlack,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE53935)),
            tooltip: 'Hapus Resume Medis',
            onPressed: _confirmDeleteResume,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _colorBorder, height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Card Header Pasien (Soft Blue)
              _buildPatientSummaryCard(childName, parentName),
              const SizedBox(height: 24),

              // Mode Edit Banner Indicator (jika aktif)
              if (_isEditing) ...[
                _buildEditModeBanner(),
                const SizedBox(height: 16),
              ],

              // ── SEKSI 1: Formulir Hasil Pemeriksaan Dokter ───────────
              _buildSectionHeader(
                'Formulir Hasil Pemeriksaan Dokter',
                'Lengkapi ringkasan klinis konsultasi untuk tercatat pada rekam medis pasien.',
                Icons.assignment_outlined,
              ),
              const SizedBox(height: 14),

              // Dokter Pemeriksa (Read-only)
              _buildModernDisplayField(
                label: 'Dokter Pemeriksa',
                value: _resume.doctorName,
                icon: Icons.person_outline_rounded,
                isLocked: true,
              ),
              const SizedBox(height: 12),

              // Tanggal & Waktu Konsultasi (Read-only)
              Row(
                children: [
                  Expanded(
                    child: _buildModernDisplayField(
                      label: 'Tanggal Konsultasi',
                      value: _resume.consultationDate,
                      icon: Icons.calendar_today_rounded,
                      isLocked: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModernDisplayField(
                      label: 'Waktu Sesi',
                      value: _resume.consultationTime,
                      icon: Icons.access_time_rounded,
                      isLocked: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Berat Badan & Tinggi Badan Saat Ini (Read-only)
              Row(
                children: [
                  Expanded(
                    child: _buildModernDisplayField(
                      label: 'Berat Badan Saat Ini (kg)',
                      value: bbVal,
                      icon: Icons.scale_rounded,
                      isLocked: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModernDisplayField(
                      label: 'Tinggi Badan Saat Ini (cm)',
                      value: tbVal,
                      icon: Icons.straighten_rounded,
                      isLocked: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Keluhan Pasien (Anamnesis) - Read-only
              _buildModernDisplayField(
                label: 'Keluhan Pasien (Anamnesis)',
                value: _resume.complaint.isNotEmpty ? _resume.complaint : '-',
                icon: Icons.chat_bubble_outline_rounded,
                maxLines: 4,
                isLocked: true,
              ),
              const SizedBox(height: 24),

              // ── SEKSI 2: Catatan Medis Dokter ────────────────────────
              _buildSectionHeader(
                'Catatan Medis Dokter',
                _isEditing
                    ? 'Ubah catatan klinis, anjuran, dan resep di bawah ini.'
                    : 'Hasil diagnosis, ringkasan kondisi, dan anjuran dokter.',
                Icons.medical_services_outlined,
              ),
              const SizedBox(height: 14),

              // Diagnosis / Asesmen Medis
              _buildModernField(
                label: 'Diagnosis / Asesmen Medis',
                controller: _assessmentCtrl,
                displayValue: _resume.doctorAssessment,
                icon: Icons.biotech_rounded,
                hint: 'Diagnosis klinis hasil pemeriksaan...',
                maxLines: 3,
              ),
              const SizedBox(height: 14),

              // Ringkasan Kondisi & Tindakan
              _buildModernField(
                label: 'Ringkasan Kondisi & Tindakan',
                controller: _summaryCtrl,
                displayValue: _resume.summary,
                icon: Icons.notes_rounded,
                hint: 'Ringkasan kondisi anak dan tindakan...',
                maxLines: 3,
              ),
              const SizedBox(height: 14),

              // Anjuran / Saran Perawatan Medis
              _buildRecommendationsField(),
              const SizedBox(height: 14),

              // Resep Obat / Terapi
              _buildModernField(
                label: 'Resep Obat / Terapi',
                controller: _prescriptionCtrl,
                displayValue: _resume.prescription,
                icon: Icons.medication_outlined,
                hint: 'Nama obat, dosis, dan aturan pakai (opsional)...',
                maxLines: 2,
              ),

              const SizedBox(height: 32),

              // ── SEKSI 3: Tombol Aksi di Bawah Form ────────────────────
              _buildBottomActionButtons(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WIDGET HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPatientSummaryCard(String childName, String parentName) {
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
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medical_information_rounded,
              color: _colorPrimaryBlue,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  childName,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _colorTextBlack,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Orang Tua: $parentName',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: _colorLabelGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditModeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_note_rounded,
              color: Color(0xFFEA580C), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mode Edit Aktif: Silakan ubah catatan dokter di bawah dan tekan Simpan Perubahan.',
              style: GoogleFonts.lato(
                fontSize: 12.5,
                color: const Color(0xFFC2410C),
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _colorSoftBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _colorPrimaryBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: _colorTextBlack,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: _colorLabelGrey,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Field read-only (tampilan kotak abu-abu bersih sesuai screenshot)
  Widget _buildModernDisplayField({
    required String label,
    required String value,
    required IconData icon,
    int maxLines = 1,
    bool isLocked = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _colorTextBlack,
              ),
            ),
            if (isLocked) ...[
              const SizedBox(width: 4),
              const Icon(Icons.lock_outline_rounded,
                  size: 13, color: Color(0xFF8696A0)),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _colorReadOnlyBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _colorReadOnlyBorder),
          ),
          child: Row(
            crossAxisAlignment: maxLines > 1
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(top: maxLines > 1 ? 2.0 : 0),
                child: Icon(icon, size: 19, color: _colorLabelGrey),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value.isNotEmpty ? value : '-',
                  style: GoogleFonts.lato(
                    fontSize: 13.5,
                    color: _colorTextBlack,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  maxLines: maxLines,
                  overflow:
                      maxLines == 1 ? TextOverflow.ellipsis : TextOverflow.visible,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Field yang bisa diedit saat mode edit aktif
  Widget _buildModernField({
    required String label,
    required TextEditingController controller,
    required String displayValue,
    required IconData icon,
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: _colorTextBlack,
          ),
        ),
        const SizedBox(height: 6),
        if (_isEditing)
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.lato(fontSize: 13.5, color: _colorTextBlack),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: GoogleFonts.lato(
                fontSize: 13,
                color: const Color(0xFFB0BEC5),
              ),
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
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _colorReadOnlyBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _colorBorder),
            ),
            child: Row(
              crossAxisAlignment: maxLines > 1
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: maxLines > 1 ? 2.0 : 0),
                  child: Icon(icon, size: 19, color: _colorLabelGrey),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    displayValue.isNotEmpty ? displayValue : '-',
                    style: GoogleFonts.lato(
                      fontSize: 13.5,
                      color: _colorTextBlack,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Field Rekomendasi / Saran Perawatan
  Widget _buildRecommendationsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Anjuran / Saran Perawatan Medis',
          style: GoogleFonts.lato(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: _colorTextBlack,
          ),
        ),
        const SizedBox(height: 6),
        if (_isEditing) ...[
          TextFormField(
            controller: _recommendationsCtrl,
            maxLines: 4,
            style: GoogleFonts.lato(fontSize: 13.5, color: _colorTextBlack),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Tulis anjuran satu per baris:\n1. Berikan ASI sesering mungkin\n2. Kontrol ulang 2 minggu',
              hintStyle: GoogleFonts.lato(
                fontSize: 13,
                color: const Color(0xFFB0BEC5),
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(top: 2.0),
                child: Icon(Icons.check_circle_outline_rounded,
                    size: 20, color: _colorLabelGrey),
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
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              '* Pisahkan setiap butir anjuran dengan baris baru (Enter)',
              style: GoogleFonts.lato(fontSize: 11.5, color: _colorLabelGrey),
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _colorReadOnlyBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _colorBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2.0),
                  child: Icon(Icons.check_circle_outline_rounded,
                      size: 19, color: _colorLabelGrey),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _resume.recommendations.isEmpty
                      ? Text(
                          '-',
                          style: GoogleFonts.lato(
                            fontSize: 13.5,
                            color: _colorTextBlack,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _resume.recommendations
                              .asMap()
                              .entries
                              .map((entry) {
                            final idx = entry.key + 1;
                            final text = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 3.0),
                              child: Text(
                                '$idx. $text',
                                style: GoogleFonts.lato(
                                  fontSize: 13.5,
                                  color: _colorTextBlack,
                                  height: 1.45,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TOMBOL DI BAWAH FORM
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBottomActionButtons() {
    if (!_isEditing) {
      // Normal Mode: Tombol "Edit Resume Medis" di bawah formulir
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () => setState(() => _isEditing = true),
          style: ElevatedButton.styleFrom(
            backgroundColor: _colorPrimaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.edit_outlined, size: 20),
              const SizedBox(width: 8),
              Text(
                'Edit Resume Medis',
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Edit Mode: Tombol "Batal" & "Simpan Perubahan" di bawah formulir
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _cancelEdit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE9EDEF),
                foregroundColor: const Color(0xFF667781),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Batal',
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: _colorPrimaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Simpan Perubahan',
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
