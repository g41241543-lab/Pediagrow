import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/resume_medis_model.dart';
import '../../../models/riwayat_konsultasi_model.dart';
import '../../../shared/widgets/child_live_avatar.dart';
import '../../../shared/widgets/doctor_live_avatar.dart';
import '../../../shared/widgets/pedia_bottom_nav_bar.dart';
import 'widgets/riwayat_header.dart';

/// Halaman Detail Riwayat Konsultasi untuk POV Pengguna (Orang Tua) PediaGrow.
///
/// Desain kaya dan informatif – konsisten dengan desain Admin/Dokter:
/// - Kartu header anak: avatar Firebase, nama, usia, gender, badge status.
/// - Kartu info konsultasi: dokter dengan DoctorLiveAvatar, 2-kolom
///   Tanggal + Waktu Sesi, 2-kolom BB + TB (diambil real-time dari resume_medis).
/// - Seksi Keluhan (anamnesis lengkap dari orang tua).
/// - Seksi Ringkasan Konsultasi (catatan akhir dokter).
/// - Footer ilustrasi PediaGrow.
class DetailKonsultasiPage extends StatefulWidget {
  final RiwayatKonsultasiModel riwayat;

  const DetailKonsultasiPage({super.key, required this.riwayat});

  @override
  State<DetailKonsultasiPage> createState() => _DetailKonsultasiPageState();
}

class _DetailKonsultasiPageState extends State<DetailKonsultasiPage> {
  // ─── Color Palette ───────────────────────────────────────────────────────
  static const Color _colorPrimaryBlue = Color(0xFF2A85FF);

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _colorBg =>
      _isDark ? const Color(0xFF0B1014) : Colors.white;
  Color get _colorTextBlack =>
      _isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1E293B);
  Color get _colorSecondaryGrey =>
      _isDark ? const Color(0xFF8696A0) : const Color(0xFF64748B);

  // ─── State ───────────────────────────────────────────────────────────────
  ResumeMedisModel? _resumeModel;
  StreamSubscription? _resumeSub;

  @override
  void initState() {
    super.initState();
    _loadResumeMedis();
  }

  @override
  void dispose() {
    _resumeSub?.cancel();
    super.dispose();
  }

  /// Ambil data resume medis dari Firestore berdasarkan ID riwayat konsultasi
  Future<void> _loadResumeMedis() async {
    final resumeId = widget.riwayat.id;
    if (resumeId.isEmpty) return;

    try {
      final db = FirebaseFirestore.instance;

      _resumeSub = db
          .collection('resume_medis')
          .doc(resumeId)
          .snapshots()
          .listen((doc) async {
        if (!mounted) return;

        if (doc.exists && doc.data() != null) {
          try {
            final parsed = ResumeMedisModel.fromFirestore(doc);
            if (mounted) setState(() => _resumeModel = parsed);
          } catch (_) {
            try {
              final parsed =
                  ResumeMedisModel.fromMap(doc.data()!, docId: doc.id);
              if (mounted) setState(() => _resumeModel = parsed);
            } catch (e) {
              debugPrint('[DetailKonsultasiPage] Error parsing: $e');
            }
          }
        } else {
          // Jika tidak ditemukan by doc id, coba cari by session_id atau child_id
          try {
            final query = await db
                .collection('resume_medis')
                .where('session_id', isEqualTo: resumeId)
                .limit(1)
                .get();
            if (query.docs.isNotEmpty) {
              final parsed =
                  ResumeMedisModel.fromFirestore(query.docs.first);
              if (mounted) setState(() => _resumeModel = parsed);
            } else if (widget.riwayat.childId.isNotEmpty) {
              final childQuery = await db
                  .collection('resume_medis')
                  .where('child_id', isEqualTo: widget.riwayat.childId)
                  .limit(1)
                  .get();
              if (childQuery.docs.isNotEmpty) {
                final parsed =
                    ResumeMedisModel.fromFirestore(childQuery.docs.first);
                if (mounted) setState(() => _resumeModel = parsed);
              }
            }
          } catch (_) {}
        }
      });
    } catch (_) {
      // Offline fallback – data tetap aman
    }
  }

  String _formatNum(double? val) {
    if (val == null || val <= 0) return '-';
    if (val == val.toInt()) return val.toInt().toString();
    return val.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isGirl = widget.riwayat.childGender.toLowerCase() == 'perempuan' ||
        widget.riwayat.childGender.toLowerCase() == 'p' ||
        widget.riwayat.childGender.toLowerCase() == 'female';
    final isSelesai =
        widget.riwayat.status.toLowerCase().trim() == 'selesai';

    final complaintText =
        widget.riwayat.fullComplaint.isNotEmpty
            ? widget.riwayat.fullComplaint
            : widget.riwayat.complaint.isNotEmpty
                ? widget.riwayat.complaint
                : '-';

    final summaryText = widget.riwayat.summary.trim().isNotEmpty
        ? widget.riwayat.summary.trim()
        : '-';

    return Scaffold(
      backgroundColor: _colorBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: RiwayatHeader(
          title: 'Detail Riwayat Konsultasi',
          showBackButton: true,
          showNotification: false,
          onBackPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Kartu Header Anak ───────────────────────────────────
              _buildChildHeaderCard(isGirl, isSelesai),
              const SizedBox(height: 20.0),

              // ── 2. Section Title: Informasi Konsultasi ─────────────────
              _buildSectionTitle(
                title: 'Informasi Konsultasi',
                subtitle: 'Rincian dokter pemeriksa dan jadwal sesi',
              ),
              const SizedBox(height: 10.0),

              // ── 3. Kartu Info Konsultasi (Dokter + Tanggal/Jam + BB/TB) ─
              _buildConsultationInfoCard(),
              const SizedBox(height: 22.0),

              // ── 4. Section Title: Keluhan ──────────────────────────────
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

              // ── 5. Section Title: Ringkasan Konsultasi ─────────────────
              _buildSectionTitle(
                title: 'Ringkasan Konsultasi',
                subtitle: 'Catatan akhir dokter setelah sesi konsultasi',
              ),
              const SizedBox(height: 10.0),
              _buildContentCard(
                content: summaryText,
                isEmpty: summaryText == '-',
              ),
              const SizedBox(height: 28.0),

              const SizedBox(height: 8.0),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PediaBottomNavBar(selectedIndex: 2),
    );
  }

  // ─── Section Title (judul + subjudul, tanpa ikon) ────────────────────────
  Widget _buildSectionTitle({
    required String title,
    String? subtitle,
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
        if (subtitle != null && subtitle.isNotEmpty) ...[
          const SizedBox(height: 2.0),
          Text(
            subtitle,
            style: GoogleFonts.lato(
              fontSize: 12.0,
              color: _colorSecondaryGrey,
            ),
          ),
        ],
      ],
    );
  }

  // ─── Kartu Header Anak ─────────────────────────────────────────────────────
  Widget _buildChildHeaderCard(bool isGirl, bool isSelesai) {
    final genderColor =
        isGirl ? const Color(0xFFEC4899) : const Color(0xFF3B82F6);
    final genderIcon = isGirl ? Icons.female : Icons.male;
    final genderLabel = isGirl ? 'Perempuan' : 'Laki-laki';

    return _InteractiveDetailCard(
      isGradientHeader: true,
      borderRadius: 18.0,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ChildLiveAvatar(
            childId: widget.riwayat.childId,
            childName: widget.riwayat.childName,
            photoUrl: widget.riwayat.childPhotoUrl,
            gender: widget.riwayat.childGender,
            isGirl: isGirl,
            size: 54.0,
            shape: BoxShape.circle,
          ),
          const SizedBox(width: 14.0),
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
                        widget.riwayat.childName,
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
                      genderLabel,
                      style: GoogleFonts.lato(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: genderColor,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      '•',
                      style: TextStyle(
                          fontSize: 12.0, color: _colorSecondaryGrey),
                    ),
                    const SizedBox(width: 6.0),
                    Expanded(
                      child: Text(
                        widget.riwayat.childAge,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isSelesai) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isSelesai
            ? (_isDark
                ? const Color(0xFF064E3B).withValues(alpha: 0.5)
                : const Color(0xFFDCFCE7))
            : (_isDark
                ? const Color(0xFF1E3A5F).withValues(alpha: 0.5)
                : const Color(0xFFEFF6FF)),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Text(
        widget.riwayat.status.isNotEmpty
            ? widget.riwayat.status
            : 'Selesai',
        style: GoogleFonts.lato(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: isSelesai
              ? (_isDark
                  ? const Color(0xFF4ADE80)
                  : const Color(0xFF15803D))
              : (_isDark
                  ? const Color(0xFF60A5FA)
                  : const Color(0xFF2563EB)),
        ),
      ),
    );
  }

  // ─── Kartu Informasi Konsultasi (Dokter + Tanggal/Jam + BB/TB) ───────────
  Widget _buildConsultationInfoCard() {
    final bb = _resumeModel?.bbSaatIni;
    final tb = _resumeModel?.tbSaatIni;
    final bbStr = (bb != null && bb > 0) ? '${_formatNum(bb)} kg' : '-';
    final tbStr = (tb != null && tb > 0) ? '${_formatNum(tb)} cm' : '-';

    final consultationTimeStr =
        (_resumeModel?.consultationTime.isNotEmpty == true)
            ? _resumeModel!.consultationTime
            : '-';

    final doctorSpec = _resumeModel?.doctorSpecialization.isNotEmpty == true
        ? _resumeModel!.doctorSpecialization
        : widget.riwayat.doctorSpecialization.isNotEmpty
            ? widget.riwayat.doctorSpecialization
            : 'Dokter Spesialis Anak';

    return _InteractiveDetailCard(
      borderRadius: 16.0,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Baris Dokter dengan DoctorLiveAvatar
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DoctorLiveAvatar(
                doctorId: widget.riwayat.doctorId,
                doctorName: widget.riwayat.doctorName,
                fallbackPhoto: widget.riwayat.doctorPhoto,
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
                      widget.riwayat.doctorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: _colorTextBlack,
                      ),
                    ),
                    const SizedBox(height: 1.0),
                    Text(
                      doctorSpec,
                      style: GoogleFonts.lato(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                        color: _colorPrimaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Divider(height: 24.0, thickness: 0.8, color: _isDark ? const Color(0xFF2C363D) : const Color(0xFFE2E8F0)),

          // Baris 2 Kolom: Tanggal Konsultasi & Waktu Sesi
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.calendar_today_rounded,
                  label: 'Tanggal Konsultasi',
                  value: widget.riwayat.formattedDate,
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

          // Baris 2 Kolom: BB & TB
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.scale_rounded,
                  label: 'Berat Badan',
                  value: bbStr,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.straighten_rounded,
                  label: 'Tinggi Badan',
                  value: tbStr,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Tile Info 2-kolom (ikon + label kecil + nilai tebal) ─────────────────
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

  // ─── Kartu Konten Teks (Keluhan / Ringkasan) ──────────────────────────────
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
