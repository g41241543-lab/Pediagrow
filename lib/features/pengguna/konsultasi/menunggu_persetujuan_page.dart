import 'package:flutter/material.dart';

import '../../../models/child_model.dart';
import '../../../models/consultation_model.dart';
import '../../../models/doctor_model.dart';
import 'booking_dokter_page.dart';

export 'booking_dokter_page.dart';

/// Halaman Menunggu Persetujuan Dokter telah digantikan oleh [BookingDokterPage]
/// sesuai sistem booking jadwal dokter oleh pengguna.
class MenungguPersetujuanPage extends StatelessWidget {
  final DoctorModel? doctor;
  final ConsultationModel? consultation;
  final DateTime? consultationCreatedAt;
  final ChildModel? child;

  const MenungguPersetujuanPage({
    super.key,
    this.doctor,
    this.consultation,
    this.consultationCreatedAt,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BookingDokterPage(
      doctor: doctor ?? consultation?.doctor,
      child: child,
    );
  }
<<<<<<< HEAD

  // ===========================================================================
  // KOMPONEN HEADER TETAP (56dp)
  // ===========================================================================

  Widget _buildFixedHeader() {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tombol back berjarak tepat 12dp dari tepi kiri layar
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
                    Icons.arrow_back,
                    color: colorTextDark,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          // Jarak 12dp setelah posisi tombol back menuju nama halaman
          const SizedBox(width: 12),
          // Nama Halaman "Menunggu Persetujuan Dokter"
          Expanded(
            child: Text(
              'Menunggu Persetujuan Dokter',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorTextDark,
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
  // ILUSTRASI DOKTER HD & HINT FASE TENGAH
  // ===========================================================================

  Widget _buildDoctorIllustration(double targetHeight, double auraOpacity) {
    // Lebar ilustrasi sedikit lebih besar dari tinggi agar proporsional dengan
    // gambar dokter yang memiliki elemen medis melebar ke samping.
    final double illustrationWidth = targetHeight * 1.15;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ─── Aura glow + gambar ilustrasi dokter ───────────────────────────
        Container(
          width: illustrationWidth,
          height: targetHeight,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorPrimaryBlue.withValues(alpha: auraOpacity * 0.65),
                blurRadius: 36,
                spreadRadius: 6,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/doctor_waiting_illustration.png',
            width: illustrationWidth,
            height: targetHeight,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) {
              return _buildVectorIllustrationFallback(targetHeight);
            },
          ),
        ),

        // ─── Badge jam (ikon waktu) di pojok kanan atas ilustrasi ──────────
        Positioned(
          top: 2,
          right: 2,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colorPrimaryBlue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: colorPrimaryBlue.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.access_time_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Fallback vector illustration jika file gambar belum siap
  Widget _buildVectorIllustrationFallback(double height) {
    return Container(
      height: height,
      width: height * 1.1,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Lingkaran aura biru
          Container(
            width: height * 0.85,
            height: height * 0.85,
            decoration: BoxDecoration(
              color: const Color(0xFF0288D1).withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
          ),
          // Ikon dokter & stetoskop
          Icon(
            Icons.medical_services_rounded,
            size: height * 0.45,
            color: Colors.white,
          ),
          // Aksen jam kuning di kanan atas
          Positioned(
            right: height * 0.08,
            top: height * 0.08,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFFFD54F),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.access_time_filled_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CARD INFORMASI KONSULTASI (Floating Bottom Sheet Style)
  // ===========================================================================

  Widget _buildConsultationCard(bool isCompact) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000), // Shadow sangat halus
            blurRadius: 20,
            offset: Offset(0, -6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          // Padding horizontal 16dp sesuai spesifikasi standar terbaru
          padding: EdgeInsets.fromLTRB(16, 12, 16, isCompact ? 14 : 20),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Handle Bar Horizontal Abu Muda #C5C5C5
              Center(
                child: GestureDetector(
                  // Fitur testing dev tersembunyi: double tap handle bar untuk toggle status
                  onDoubleTap: () {
                    if (kDebugMode) {
                      if (_status == ConsultationStatus.waiting) {
                        simulateDoctorAccept();
                      } else if (_status == ConsultationStatus.accepted) {
                        simulateDoctorReject();
                      } else {
                        setState(() {
                          _status = ConsultationStatus.waiting;
                          _remainingSeconds = _initialCountdownSeconds;
                          _startCountdownTimer();
                        });
                      }
                    }
                  },
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorGreyLight,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Status Utama Dinamis
              _buildMainStatusText(),
              const SizedBox(height: 16),

              // Informasi Dokter (Avatar + Nama + Spesialisasi)
              _buildDoctorInfoSection(),
              const SizedBox(height: 18),

              // Timeline Vertikal 3 Tahapan
              _buildConsultationTimeline(),
              const SizedBox(height: 22),

              // Action Area (Countdown box saat waiting, Tombol "Isi Formulir" saat accepted,
              // atau Tombol "Kembali ke Daftar Dokter" saat expired)
              _buildBottomAction(),
            ],
          ),
        ),
      ),
    ),
  );
}

  // ===========================================================================
  // STATUS UTAMA (Dinamis)
  // ===========================================================================

  Widget _buildMainStatusText() {
    String text;
    Color textColor = colorTextDark;

    switch (_status) {
      case ConsultationStatus.waiting:
        text = 'Menunggu persetujuan dokter...';
        break;
      case ConsultationStatus.accepted:
        text = 'Konsultasi disetujui dokter!';
        textColor = colorPrimaryBlue;
        break;
      case ConsultationStatus.expired:
        text = 'Konsultasi tidak diterima';
        textColor = colorExpiredRed;
        break;
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.lato(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (_status == ConsultationStatus.waiting)
          _buildPulsingDots(color: colorPrimaryBlue)
        else if (_status == ConsultationStatus.accepted)
          _buildPulsingDots(color: const Color(0xFF10B981)),
      ],
    );
  }

  /// Indikator animasi titik bergantian (silih berganti)
  Widget _buildPulsingDots({required Color color}) {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.25;
            final progress = (_dotsController.value - delay) % 1.0;
            final opacity =
                (progress < 0.5 ? progress * 2 : (1.0 - progress) * 2)
                    .clamp(0.25, 1.0);
            final scale = 0.75 + (opacity * 0.25);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: 7 * scale,
              height: 7 * scale,
              decoration: BoxDecoration(
                color: color.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }

  // ===========================================================================
  // SECTION INFORMASI DOKTER
  // ===========================================================================

  Widget _buildDoctorInfoSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar Dokter dengan aksen badge PediaGrow
        _buildDoctorAvatar(),
        const SizedBox(width: 14),

        // Nama & Spesialisasi Dokter
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _effectiveDoctor.name,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorTextDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (_effectiveDoctor.specialization.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  _effectiveDoctor.specialization,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: colorGreyDark,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorAvatar() {
    const double avatarSize = 48;

    if (_effectiveDoctor.assetImagePath != null) {
      return Image.asset(
        _effectiveDoctor.assetImagePath!,
        width: avatarSize,
        height: avatarSize,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackAvatar(avatarSize),
      );
    }

    return _buildFallbackAvatar(avatarSize);
  }

  Widget _buildFallbackAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF1F5F9),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: ClipOval(
        child: _effectiveDoctor.avatarUrl != null
            ? Image.network(
                _effectiveDoctor.avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildDefaultDoctorIcon(),
              )
            : _buildDefaultDoctorIcon(),
      ),
    );
  }

  Widget _buildDefaultDoctorIcon() {
    return const Center(
      child: Icon(
        Icons.person,
        size: 28,
        color: colorGreyDark,
      ),
    );
  }

  // ===========================================================================
  // TIMELINE VERTIKAL KONSULTASI (3 Tahap)
  // ===========================================================================

  Widget _buildConsultationTimeline() {
    // Expired: tahap 1 & 2 sudah dilalui → keduanya biru; tahap 3 merah (tidak diterima).
    // Accepted: semua tahap biru.
    // Waiting:  hanya tahap 1 biru, sisanya abu.
    final isStage2Active = _status == ConsultationStatus.accepted ||
        _status == ConsultationStatus.expired;
    final isStage3Active = _status == ConsultationStatus.accepted;
    final isStage3Expired = _status == ConsultationStatus.expired;

    return Column(
      children: [
        // Tahap 1: Permintaan konsultasi dibuat (selalu biru)
        _buildTimelineStep(
          indicatorColor: colorPrimaryBlue,
          isFirst: true,
          isLast: false,
          showLineDown: true,
          lineColor: isStage2Active ? colorPrimaryBlue : colorGreyLight,
          title: 'Permintaan konsultasi dibuat',
          subtitle: _effectiveConsultation.formattedCreatedAt,
          isTitleBold: false,
        ),

        // Tahap 2: Menunggu persetujuan dokter
        // Biru saat accepted ATAU expired (tahap ini sudah dilewati), abu saat waiting
        _buildTimelineStep(
          indicatorColor: isStage2Active ? colorPrimaryBlue : colorGreyDark,
          isFirst: false,
          isLast: false,
          showLineDown: true,
          lineColor: isStage3Active ? colorPrimaryBlue : colorGreyLight,
          title: 'Menunggu persetujuan dokter',
          subtitle: null,
          isTitleBold: false,
          onTap: _status == ConsultationStatus.waiting ? simulateDoctorAccept : null,
        ),

        // Tahap 3: Biru saat accepted, merah saat expired, abu saat waiting
        _buildTimelineStep(
          indicatorColor: isStage3Expired
              ? colorExpiredRed
              : (isStage3Active ? colorPrimaryBlue : colorGreyDark),
          isFirst: false,
          isLast: true,
          showLineDown: false,
          lineColor: colorGreyLight,
          title: isStage3Expired
              ? 'Konsultasi tidak diterima'
              : 'Lanjut isi formulir',
          subtitle: isStage3Expired
              ? 'Waktu konfirmasi 5 menit telah habis'
              : (isStage3Active
                  ? 'Dokter menyetujui, silakan isi formulir'
                  : null),
          isTitleBold: isStage3Active,
          titleColor: isStage3Expired ? colorExpiredRed : null,
          onTap: _status == ConsultationStatus.waiting ? simulateDoctorAccept : null,
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required Color indicatorColor,
    required bool isFirst,
    required bool isLast,
    required bool showLineDown,
    required Color lineColor,
    required String title,
    String? subtitle,
    bool isTitleBold = false,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    const double circleDiameter = 14.0;
    const double lineThickness = 1.6;
    const double columnWidth = 24.0;

    final rowContent = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kolom Indikator Titik & Garis Vertikal
          SizedBox(
            width: columnWidth,
            child: Column(
              children: [
                const SizedBox(height: 2),
                // Titik Lingkaran Timeline
                Container(
                  width: circleDiameter,
                  height: circleDiameter,
                  decoration: BoxDecoration(
                    color: indicatorColor,
                    shape: BoxShape.circle,
                  ),
                ),
                // Garis Vertikal Penghubung
                if (showLineDown)
                  Expanded(
                    child: Container(
                      width: lineThickness,
                      color: lineColor,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                    ),
                  )
                else
                  const SizedBox(height: 4),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Teks Judul & Subtitle
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: 14.5,
                      fontWeight:
                          isTitleBold ? FontWeight.bold : FontWeight.w500,
                      color: titleColor ?? colorTextDark,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: colorGreyDark,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: rowContent,
      );
    }
    return rowContent;
  }

  // ===========================================================================
  // BOTTOM ACTION: Countdown / Tombol Isi Formulir / Tombol Kembali
  // ===========================================================================

  Widget _buildBottomAction() {
    switch (_status) {
      case ConsultationStatus.waiting:
        // Kotak Abu Muda Countdown 05:00 .. 00:00 (dapat di-tap langsung untuk demo konfirmasi dokter)
        return InkWell(
          onTap: simulateDoctorAccept,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: colorGreyBg,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              _formattedCountdown,
              style: GoogleFonts.lato(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.8,
                color: colorTextDark,
              ),
            ),
          ),
        );

      case ConsultationStatus.accepted:
        // Tombol Biru "Lanjutkan Isi Formulir"
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _navigateToFormulir,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorPrimaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Text(
              'Lanjutkan Isi Formulir',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
          ),
        );

      case ConsultationStatus.expired:
        // Tombol "Kembali ke Daftar Dokter"
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _navigateToDaftarDokter,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorPrimaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Text(
              'Kembali ke Daftar Dokter',
              style: GoogleFonts.lato(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
    }
  }
=======
>>>>>>> b1d1817c7b7ec594c2e8c0b2f211cc738c6d7e85
}
