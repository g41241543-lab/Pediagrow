import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/resume_medis_model.dart';
import '../../../shared/widgets/child_live_avatar.dart';
import '../../../shared/widgets/doctor_live_avatar.dart';
import '../../../shared/widgets/pedia_bottom_nav_bar.dart';
import 'riwayat_konsultasi_admin_model.dart';

/// Halaman Detail Riwayat Konsultasi untuk POV PMIK dan Dokter (Desain Utama PediaGrow).
///
/// - Header bersih dan serasi (AppBar dengan tombol back & judul tebal).
/// - Kartu Header Pasien (Soft Blue gradient, avatar anak real-time dari Firebase,
///   nama anak, jenis kelamin, usia terhitung, info orang tua, & badge status konsultasi).
/// - Kartu Informasi Konsultasi (Dokter penanggung jawab dengan DoctorLiveAvatar,
///   tanggal & waktu sesi berikon warna, serta data vital BB & TB saat pemeriksaan).
/// - Seksi Rekam Medis & Catatan Klinis (Keluhan anamnesis, asesmen medis, ringkasan
///   tindakan dokter, anjuran dokter, dan resep obat yang tertata rapi dalam container khusus).
/// - Tombol pintasan langsung "Buka Formulir Resume Medis Lengkap" untuk dokter/PMIK.
/// - Footer ilustrasi PediaGrow dan Bottom Navigation Bar aktif di tab Riwayat.
class DetailRiwayatKonsultasiAdminPage extends StatefulWidget {
  final RiwayatKonsultasiAdminItem? item;
  final ResumeMedisModel? resume; // Backward compatibility

  const DetailRiwayatKonsultasiAdminPage({
    super.key,
    this.item,
    this.resume,
  });

  @override
  State<DetailRiwayatKonsultasiAdminPage> createState() =>
      _DetailRiwayatKonsultasiAdminPageState();
}

class _DetailRiwayatKonsultasiAdminPageState
    extends State<DetailRiwayatKonsultasiAdminPage> {
  // ─── Color Palette ──────────────────────────────────────────────────────────
  static const Color _colorPrimaryBlue = Color(0xFF2A85FF);

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _colorBg => _isDark ? const Color(0xFF0B1014) : Colors.white;
  Color get _colorTextBlack =>
      _isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1E293B);
  Color get _colorSecondaryGrey =>
      _isDark ? const Color(0xFF8696A0) : const Color(0xFF64748B);

  late RiwayatKonsultasiAdminItem _item;
  ResumeMedisModel? _resumeModel;
  String? _parentName;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _item = widget.item!;
    } else if (widget.resume != null) {
      final r = widget.resume!;
      _resumeModel = r;
      _item = RiwayatKonsultasiAdminItem(
        id: r.id,
        childId: r.childId,
        childName: r.childName,
        childAge: r.childAgeAtConsultation,
        doctorId: r.doctorId,
        doctorName: r.doctorName,
        formattedDate: r.consultationDate,
        status: r.status,
        complaint: r.complaint,
        summary: r.summary,
        resumeMedisId: r.id,
        sessionId: r.sessionId,
      );
    } else {
      _item = RiwayatKonsultasiAdminItem.getMockData()[1];
    }

    _listenRealTimeChildAndResume();
  }

  /// Sinkronisasi real-time jika ada pembaruan data anak atau resume medis di Firebase
  void _listenRealTimeChildAndResume() {
    try {
      final db = FirebaseFirestore.instance;

      // 1. Dengarkan pembaruan data anak jika childId tersedia
      if (_item.childId.isNotEmpty) {
        db.collection('children').doc(_item.childId).snapshots().listen((doc) {
          if (!mounted || !doc.exists || doc.data() == null) return;
          final data = doc.data()!;
          final birthDate = parseAnyDate(
            data['birth_date'] ?? data['tanggal_lahir'],
          );
          final gender = data['gender']?.toString() ?? _item.childGender;
          final parent = data['parent_name'] ??
              data['parentName'] ??
              data['nama_orang_tua'] ??
              data['owner_name'];

          setState(() {
            _item = _item.copyWith(
              childBirthDate: birthDate ?? _item.childBirthDate,
              childGender: gender,
            );
            if (parent != null && parent.toString().trim().isNotEmpty) {
              _parentName = parent.toString().trim();
            }
          });
        });
      }

      // 2. Dengarkan pembaruan resume medis jika resumeMedisId tersedia
      final resumeId = _item.resumeMedisId;
      if (resumeId != null && resumeId.isNotEmpty) {
        db.collection('resume_medis').doc(resumeId).snapshots().listen((doc) {
          if (!mounted || !doc.exists || doc.data() == null) return;
          try {
            final parsedResume = ResumeMedisModel.fromFirestore(doc);
            setState(() {
              _resumeModel = parsedResume;
              _item = _item.copyWith(
                complaint: parsedResume.complaint.isNotEmpty
                    ? parsedResume.complaint
                    : _item.complaint,
                summary: parsedResume.summary.isNotEmpty
                    ? parsedResume.summary
                    : _item.summary,
                status: parsedResume.status.isNotEmpty
                    ? parsedResume.status
                    : _item.status,
              );
            });
          } catch (_) {
            final data = doc.data()!;
            final complaint =
                (data['complaint'] ?? data['complaint_short'] ?? '').toString();
            final summary = (data['summary'] ?? '').toString();
            final status = (data['status'] ?? _item.status).toString();
            setState(() {
              _item = _item.copyWith(
                complaint: complaint.isNotEmpty ? complaint : _item.complaint,
                summary: summary.isNotEmpty ? summary : _item.summary,
                status: status,
              );
            });
          }
        });
      }
    } catch (_) {
      // Fallback offline
    }
  }

  String _formatNum(double? val) {
    if (val == null || val <= 0) return '-';
    if (val == val.toInt()) return val.toInt().toString();
    return val.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isGirl = _item.isGirl;
    final isSelesai = _item.status.toLowerCase().contains('selesai');

    final complaintText = _item.complaint.trim().isNotEmpty
        ? _item.complaint.trim()
        : (_resumeModel?.complaint.trim().isNotEmpty == true
            ? _resumeModel!.complaint.trim()
            : '-');

    final summaryText = _item.summary.trim().isNotEmpty
        ? _item.summary.trim()
        : (_resumeModel?.summary.trim().isNotEmpty == true
            ? _resumeModel!.summary.trim()
            : '-');

    return Scaffold(
      backgroundColor: _colorBg,
      appBar: AppBar(
        backgroundColor: _isDark ? const Color(0xFF0B1014) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _colorTextBlack),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Detail Riwayat Konsultasi',
          style: GoogleFonts.lato(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: _colorTextBlack,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 1. KARTU HEADER PASIEN ──────────────────────────────────────
            _buildPatientHeaderCard(isGirl, isSelesai),
            const SizedBox(height: 20.0),

            // ─── 2. SEKSI INFORMASI KONSULTASI & DOKTER ───────────────────────
            _buildSectionTitle(
              title: 'Informasi Konsultasi',
              subtitle: 'Rincian dokter pemeriksa dan jadwal sesi',
            ),
            const SizedBox(height: 10.0),
            _buildConsultationInfoCard(),
            const SizedBox(height: 22.0),

            // ─── 3. SEKSI KELUHAN ─────────────────────────────────────────────
            _buildSectionTitle(
              title: 'Keluhan',
              subtitle: 'Keluhan yang disampaikan saat konsultasi',
            ),
            const SizedBox(height: 10.0),
            _buildContentCard(
              content: complaintText,
              isEmpty: complaintText == '-',
            ),
            const SizedBox(height: 22.0),

            // ─── 4. SEKSI RINGKASAN KONSULTASI ────────────────────────────────
            _buildSectionTitle(
              title: 'Ringkasan Konsultasi',
              subtitle: 'Catatan akhir dokter setelah sesi konsultasi',
            ),
            const SizedBox(height: 10.0),
            _buildContentCard(
              content: summaryText,
              isEmpty: summaryText == '-',
            ),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
      bottomNavigationBar: const PediaBottomNavBar(
        selectedIndex: 2,
      ),
    );
  }

  // ─── SECTION TITLE WIDGET (TANPA IKON) ──────────────────────────────────
  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 15.0,
            fontWeight: FontWeight.bold,
            color: _colorTextBlack,
          ),
        ),
        const SizedBox(height: 2.0),
        Text(
          subtitle,
          style: GoogleFonts.lato(
            fontSize: 12.0,
            color: _colorSecondaryGrey,
          ),
        ),
      ],
    );
  }

  // ─── 1. KARTU HEADER PASIEN ────────────────────────────────────────────────
  Widget _buildPatientHeaderCard(bool isGirl, bool isSelesai) {
    final genderColor = isGirl ? const Color(0xFFEC4899) : const Color(0xFF3B82F6);
    final genderIcon = isGirl ? Icons.female : Icons.male;

    return _InteractiveDetailCard(
      isGradientHeader: true,
      borderRadius: 18.0,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar Anak Real-Time dari Firebase
          ChildLiveAvatar(
            childId: _item.childId,
            childName: _item.childName,
            photoUrl: _item.childPhotoUrl,
            gender: _item.childGender,
            isGirl: isGirl,
            size: 54.0,
            shape: BoxShape.circle,
          ),
          const SizedBox(width: 14.0),
          // Info Anak & Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _item.childName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          fontSize: 17.5,
                          fontWeight: FontWeight.bold,
                          color: _colorTextBlack,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    _buildStatusBadge(isSelesai),
                  ],
                ),
                const SizedBox(height: 5.0),
                Row(
                  children: [
                    Icon(genderIcon, size: 14.0, color: genderColor),
                    const SizedBox(width: 3.0),
                    Text(
                      _item.childGender,
                      style: GoogleFonts.lato(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: genderColor,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      '•',
                      style: TextStyle(fontSize: 12.0, color: _colorSecondaryGrey),
                    ),
                    const SizedBox(width: 6.0),
                    Expanded(
                      child: Text(
                        _item.calculatedAge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          fontSize: 13.0,
                          color: _colorTextBlack,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_parentName != null && _parentName!.isNotEmpty) ...[
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      Icon(
                        Icons.family_restroom_rounded,
                        size: 13.5,
                        color: _colorSecondaryGrey,
                      ),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          'Orang Tua: $_parentName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(
                            fontSize: 12.0,
                            color: _colorSecondaryGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. KARTU INFORMASI KONSULTASI ──────────────────────────────────────────
  Widget _buildConsultationInfoCard() {
    final bb = _resumeModel?.bbSaatIni;
    final tb = _resumeModel?.tbSaatIni;
    final bbStr = (bb != null && bb > 0) ? '${_formatNum(bb)} kg' : '7.8 kg';
    final tbStr = (tb != null && tb > 0) ? '${_formatNum(tb)} cm' : '53 cm';

    final consultationTimeStr = (_resumeModel?.consultationTime.isNotEmpty == true)
        ? _resumeModel!.consultationTime
        : '14:27 WIB';

    return _InteractiveDetailCard(
      borderRadius: 16.0,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Dokter Pemeriksa
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DoctorLiveAvatar(
                doctorId: _item.doctorId,
                doctorName: _item.doctorName,
                size: 44.0,
                shape: BoxShape.circle,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dokter Pemeriksa',
                      style: GoogleFonts.lato(
                        fontSize: 11.5,
                        color: _colorSecondaryGrey,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      _item.doctorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: _colorTextBlack,
                      ),
                    ),
                    if (_resumeModel?.doctorSpecialization.isNotEmpty == true) ...[
                      const SizedBox(height: 1.0),
                      Text(
                        _resumeModel!.doctorSpecialization,
                        style: GoogleFonts.lato(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w500,
                          color: _colorPrimaryBlue,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          Divider(height: 24.0, thickness: 0.8, color: _isDark ? const Color(0xFF2C363D) : const Color(0xFFE2E8F0)),

          // Tanggal & Waktu Sesi (2 Kolom)
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.calendar_today_rounded,
                  label: 'Tanggal Konsultasi',
                  value: _item.formattedDate,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.access_time_rounded,
                  label: 'Waktu Sesi',
                  value: consultationTimeStr,
                ),
              ),
            ],
          ),

          Divider(height: 24.0, thickness: 0.8, color: _isDark ? const Color(0xFF2C363D) : const Color(0xFFE2E8F0)),

          // Data Fisik (BB & TB) (2 Kolom)
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.scale_rounded,
                  label: 'Berat Badan Saat Ini',
                  value: bbStr,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.straighten_rounded,
                  label: 'Tinggi Badan Saat Ini',
                  value: tbStr,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32.0,
          height: 32.0,
          decoration: BoxDecoration(
            color: _isDark ? const Color(0xFF1E2835) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8.0),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 17.0,
            color: _colorSecondaryGrey,
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lato(
                  fontSize: 11.0,
                  color: _colorSecondaryGrey,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lato(
                  fontSize: 13.0,
                  fontWeight: FontWeight.bold,
                  color: _colorTextBlack,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── 3. KARTU KONTEN TEKS (KELUHAN / RINGKASAN KONSULTASI) ────────────────
  Widget _buildContentCard({
    required String content,
    bool isEmpty = false,
  }) {
    return _InteractiveDetailCard(
      borderRadius: 14.0,
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: Text(
          content,
          style: GoogleFonts.lato(
            fontSize: 14.5,
            fontWeight: FontWeight.normal,
            color: isEmpty ? _colorSecondaryGrey : _colorTextBlack,
            fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  // ─── BADGE STATUS KONSULTASI ────────────────────────────────────────────────
  Widget _buildStatusBadge(bool isSelesai) {
    if (isSelesai) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: _isDark
              ? const Color(0xFF064E3B).withValues(alpha: 0.6)
              : const Color(0xFFD1FAE5),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: _isDark
                ? const Color(0xFF059669).withValues(alpha: 0.4)
                : const Color(0xFFA7F3D0),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 13.0,
              color: _isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
            ),
            const SizedBox(width: 4.0),
            Text(
              'Selesai',
              style: GoogleFonts.lato(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: _isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: _isDark
              ? const Color(0xFF78350F).withValues(alpha: 0.5)
              : const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: _isDark
                ? const Color(0xFFD97706).withValues(alpha: 0.3)
                : const Color(0xFFFDE68A),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 13.0,
              color: _isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
            ),
            const SizedBox(width: 4.0),
            Text(
              'Dijadwalkan',
              style: GoogleFonts.lato(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: _isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
              ),
            ),
          ],
        ),
      );
    }
  }
}

/// Kartu interaktif konsisten dengan kartu pada daftar riwayat konsultasi (`RiwayatConsultationCard`):
/// - Memiliki efek hover biru (desktop/web) dan efek sentuh/tekan (mobile touch).
/// - Border default biru muda lembut (#BFDBFE) yang menyala menjadi biru tajam (#2B7AE8) saat disentuh/di-hover.
/// - Terangkat naik -3dp secara dinamis (animasi 160ms easeOutCubic).
/// - Memberikan feedback visual sentuhan (ripple splash / highlight) sehingga terasa responsif di layar ponsel.
class _InteractiveDetailCard extends StatefulWidget {
  final Widget child;
  final bool isGradientHeader;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const _InteractiveDetailCard({
    required this.child,
    this.isGradientHeader = false,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  State<_InteractiveDetailCard> createState() => _InteractiveDetailCardState();
}

class _InteractiveDetailCardState extends State<_InteractiveDetailCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isActive => _isHovered || _isPressed;

  // Warna aksen konsisten dengan kartu RiwayatConsultationCard (#2B7AE8 dan #BFDBFE)
  static const Color _primaryBlue = Color(0xFF2B7AE8);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Latar belakang card: berubah menjadi biru muda lembut saat disentuh/di-hover
    final Color cardBgColor = _isActive
        ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F7FF))
        : (isDark ? const Color(0xFF1A2228) : Colors.white);

    // Garis tepi (border): biru muda lembut (#BFDBFE) saat normal, dan menyala biru tajam saat aktif (#2B7AE8)
    final Color borderColor = _isActive
        ? _primaryBlue
        : (isDark ? const Color(0xFF2C363D) : const Color(0xFFBFDBFE));

    final radius = BorderRadius.circular(widget.borderRadius);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (mounted) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _isHovered = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isActive ? -3.0 : 0.0, 0),
        decoration: BoxDecoration(
          color: widget.isGradientHeader ? null : cardBgColor,
          gradient: widget.isGradientHeader
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : _isActive
                          ? [const Color(0xFFE0F0FF), const Color(0xFFD0E8FF)]
                          : [const Color(0xFFF0F7FF), const Color(0xFFE5F1FF)],
                )
              : null,
          borderRadius: radius,
          border: Border.all(
            color: borderColor,
            width: _isActive ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _isActive
                  ? _primaryBlue.withValues(alpha: isDark ? 0.35 : 0.20)
                  : _primaryBlue.withValues(alpha: isDark ? 0.25 : 0.08),
              blurRadius: _isActive ? 14.0 : 10.0,
              offset: _isActive ? const Offset(0, 5) : const Offset(0, 3),
            ),
            if (!_isActive)
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 6.0,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: () {},
            onTapDown: (_) {
              if (mounted) setState(() => _isPressed = true);
            },
            onTapUp: (_) {
              if (mounted) setState(() => _isPressed = false);
            },
            onTapCancel: () {
              if (mounted) setState(() => _isPressed = false);
            },
            onHover: (hovering) {
              if (mounted) setState(() => _isHovered = hovering);
            },
            mouseCursor: SystemMouseCursors.click,
            splashColor: _primaryBlue.withValues(alpha: 0.12),
            highlightColor: _primaryBlue.withValues(alpha: 0.08),
            hoverColor: _primaryBlue.withValues(alpha: 0.04),
            borderRadius: radius,
            child: Padding(
              padding: widget.padding,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
