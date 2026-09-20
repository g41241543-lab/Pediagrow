import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/child_service.dart';
import '../../../models/child_model.dart';
import '../../../models/consultation_model.dart';
import '../../../models/doctor_model.dart';
import 'daftar_dokter_page.dart';
import 'formulir_konsultasi_page.dart';

/// Halaman "Menunggu Persetujuan Dokter" PediaGrow.
///
/// Halaman ini muncul setelah pengguna memilih dokter dan mengajukan permintaan
/// konsultasi. Menampilkan ilustrasi animasi, informasi dokter dinamis,
/// timeline 3 tahap, dan countdown timer 5 menit interaktif.
class MenungguPersetujuanPage extends StatefulWidget {
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
  State<MenungguPersetujuanPage> createState() => MenungguPersetujuanPageState();
}

class MenungguPersetujuanPageState extends State<MenungguPersetujuanPage>
    with TickerProviderStateMixin {
  // Palet Warna Resmi PediaGrow & Spesifikasi
  static const Color colorPrimaryBlue = Color(0xFF3985E7);
  static const Color colorGreyDark = Color(0xFF7F7F7F);
  static const Color colorGreyLight = Color(0xFFC5C5C5);
  static const Color colorGreyBg = Color(0xFFEBECEF);
  static const Color colorTextDark = Color(0xFF1E293B);
  static const Color colorExpiredRed = Color(0xFFE53935);

  // Status & Data Konsultasi
  late ConsultationStatus _status;
  late DoctorModel _effectiveDoctor;
  late ConsultationModel _effectiveConsultation;

  // Countdown Timer (5 menit = 300 detik)
  static const int _initialCountdownSeconds = 300;
  int _remainingSeconds = _initialCountdownSeconds;
  Timer? _countdownTimer;
  Timer? _approvalSimulationTimer;
  Timer? _autoNavTimer;

  // Timer & State untuk Fase 1 (10 Detik di Tengah)
  static const int _tenSecInitial = 10;
  int _tenSecCountdown = _tenSecInitial;
  Timer? _tenSecTimer;
  Timer? _tenSecTickTimer;

  // Animation Controllers:
  // 1. Slow, calm breathing/pulsing animation loop (3000ms)
  late AnimationController _breathingController;
  late Animation<double> _breathingScaleAnimation;
  late Animation<double> _breathingAuraAnimation;

  // 2. Upward push transition controller (1200ms, Curves.easeInOutCubic)
  late AnimationController _pushUpController;
  late Animation<double> _pushUpAnimation;
  late Animation<Offset> _cardSlideAnimation;
  late Animation<double> _cardFadeAnimation;
  late Animation<double> _centerHintFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Inisialisasi status awal
    _status = widget.consultation?.status ?? ConsultationStatus.waiting;

    // Resolve data dokter & konsultasi awal
    _resolveData();

    // 1. Inisialisasi animasi breathing yang santai & slow (2800ms)
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _breathingScaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOutSine,
      ),
    );

    _breathingAuraAnimation = Tween<double>(begin: 0.18, end: 0.42).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOutSine,
      ),
    );

    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      _breathingController.forward();
    } else {
      _breathingController.repeat(reverse: true);
    }

    // 2. Inisialisasi controller pendorong ke atas (1200ms, Curves.easeInOutCubic)
    _pushUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pushUpAnimation = CurvedAnimation(
      parent: _pushUpController,
      curve: Curves.easeInOutCubic,
    );

    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.15),
      end: Offset.zero,
    ).animate(_pushUpAnimation);

    _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pushUpController,
        curve: const Interval(0.20, 1.0, curve: Curves.easeOut),
      ),
    );

    _centerHintFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _pushUpController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    // Mulai countdown jika dalam kondisi waiting
    if (_status == ConsultationStatus.waiting) {
      _startCountdownTimer();

      // Countdown 10 detik di tengah layar
      _tenSecTickTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_tenSecCountdown > 1) {
          setState(() {
            _tenSecCountdown--;
          });
        } else {
          timer.cancel();
        }
      });

      // Pemicu pendorongan ke atas tepat setelah 10 detik
      _tenSecTimer = Timer(const Duration(seconds: 10), () {
        if (!mounted || _status != ConsultationStatus.waiting) return;
        _triggerPushUp();
      });

      // Simulasi persetujuan dokter otomatis (dijadwalkan di detik 18 agar ada jeda setelah card naik)
      _approvalSimulationTimer = Timer(const Duration(seconds: 18), () {
        if (!mounted || _status != ConsultationStatus.waiting) return;
        simulateDoctorAccept();
      });
    } else {
      // Jika langsung accepted / expired dari awal, langsung posisikan card di atas
      _pushUpController.value = 1.0;
    }
  }

  void _triggerPushUp() {
    if (!mounted) return;
    _pushUpController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mendukung pengiriman data via ModalRoute / RouteSettings jika ada
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ConsultationModel) {
      setState(() {
        _effectiveConsultation = args;
        _effectiveDoctor = args.doctor;
        _status = args.status;
      });
    } else if (args is DoctorModel) {
      setState(() {
        _effectiveDoctor = args;
        _effectiveConsultation = ConsultationModel(
          id: 'cons-${DateTime.now().millisecondsSinceEpoch}',
          doctor: args,
          createdAt: widget.consultationCreatedAt ?? DateTime.now(),
        );
      });
    }
  }

  /// Menyiapkan data konsultasi dan dokter dinamis dengan fallback aman
  void _resolveData() {
    if (widget.consultation != null) {
      _effectiveConsultation = widget.consultation!;
      _effectiveDoctor = widget.consultation!.doctor;
    } else if (widget.doctor != null) {
      _effectiveDoctor = widget.doctor!;
      _effectiveConsultation = ConsultationModel(
        id: 'cons-${DateTime.now().millisecondsSinceEpoch}',
        doctor: widget.doctor!,
        createdAt: widget.consultationCreatedAt ?? DateTime.now(),
      );
    } else {
      _effectiveDoctor = DoctorModel.defaultDoctor;
      _effectiveConsultation = ConsultationModel.defaultConsultation(
        doctor: _effectiveDoctor,
      );
    }
  }

  /// Memulai countdown timer 5 menit (berkurang setiap detik)
  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        // Waktu habis -> otomatis masuk kondisi expired
        timer.cancel();
        setState(() {
          _status = ConsultationStatus.expired;
        });
      }
    });
  }

  @override
  void dispose() {
    // Membersihkan timer dan animation controller untuk mencegah memory leak
    _countdownTimer?.cancel();
    _approvalSimulationTimer?.cancel();
    _autoNavTimer?.cancel();
    _tenSecTimer?.cancel();
    _tenSecTickTimer?.cancel();
    _breathingController.dispose();
    _pushUpController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // FUNGSI TESTING & DEVELOPMENT (Sesuai spesifikasi prompt)
  // ===========================================================================

  /// Mensimulasikan dokter menyetujui konsultasi secara instan.
  /// Menghentikan countdown timer dan mengubah state menjadi `accepted`.
  /// Secara otomatis beralih ke formulir konsultasi.
  void simulateDoctorAccept() {
    if (!mounted) return;
    _countdownTimer?.cancel();
    _approvalSimulationTimer?.cancel();
    _tenSecTimer?.cancel();
    _tenSecTickTimer?.cancel();

    // Selesaikan animasi dorong ke atas secara instan jika belum selesai
    if (_pushUpController.value < 1.0) {
      _pushUpController.value = 1.0;
    }

    setState(() {
      _status = ConsultationStatus.accepted;
    });

    // Otomatis beralih ke halaman isi formulir setelah dokter menyetujui
    _autoNavTimer?.cancel();
    _autoNavTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted || _status != ConsultationStatus.accepted) return;
      _navigateToFormulir();
    });
  }

  /// [DEV/TESTING METHOD]
  /// Mensimulasikan dokter menolak konsultasi atau waktu konfirmasi habis.
  /// Menghentikan countdown timer dan mengubah state menjadi `expired`.
  void simulateDoctorReject() {
    if (!mounted) return;
    _countdownTimer?.cancel();
    _approvalSimulationTimer?.cancel();
    _autoNavTimer?.cancel();
    _tenSecTimer?.cancel();
    _tenSecTickTimer?.cancel();

    if (_pushUpController.value < 1.0) {
      _pushUpController.value = 1.0;
    }

    setState(() {
      _status = ConsultationStatus.expired;
      _remainingSeconds = 0;
    });
  }

  // ===========================================================================
  // NAVIGASI & AKSI TOMBOL
  // ===========================================================================

  /// Berpindah ke formulir konsultasi saat disetujui
  void _navigateToFormulir() {
    _autoNavTimer?.cancel();
    _approvalSimulationTimer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FormulirKonsultasiPage(
          doctor: _effectiveDoctor,
          consultation: _effectiveConsultation,
          child: widget.child ?? ChildService().activeChild,
        ),
      ),
    );
  }

  /// Tombol "Kembali ke Daftar Dokter" ditekan saat status expired/rejected
  void _navigateToDaftarDokter() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const DaftarDokterPage(),
      ),
      (route) => route.isFirst,
    );
  }

  /// Tombol back ditekan
  void _onBackPressed() {
    Navigator.of(context).maybePop();
  }

  /// Format countdown timer menjadi teks "MM : SS"
  String get _formattedCountdown {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes : $seconds';
  }

  // ===========================================================================
  // BUILD METHOD UTAMA
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final topPadding = mediaQuery.padding.top;
    final isCompactScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // -----------------------------------------------------------------
            // 1. HEADER TETAP (Tinggi 56dp, Tombol Back 12dp dari kiri,
            //    Judul 12dp setelah tombol back)
            // -----------------------------------------------------------------
            _buildFixedHeader(),

            // -----------------------------------------------------------------
            // 2. KONTEN UTAMA: Ilustrasi Dokter & Card Informasi (Koreografi 2-Fase)
            // -----------------------------------------------------------------
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalHeight = constraints.maxHeight;

                  return AnimatedBuilder(
                    animation: Listenable.merge([
                      _breathingController,
                      _pushUpController,
                    ]),
                    builder: (context, child) {
                      final t = _pushUpAnimation.value;

                      // Tinggi proporsional ilustrasi dokter
                      final double illustrationHeight = isCompactScreen
                          ? (totalHeight * 0.28).clamp(100.0, 150.0)
                          : (totalHeight * 0.34).clamp(130.0, 200.0);

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // 1. ILUSTRASI DOKTER DENGAN GERAKAN DARI TENGAH KE ATAS
                          // Pada t = 0 (10 detik awal): tampil tenang di tengah layar
                          // Pada t = 1 (setelah 10 detik): terdorong mulus ke atas menyesuaikan card
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.lerp(
                                const Alignment(0.0, -0.15),
                                const Alignment(0.0, -0.92),
                                t,
                              )!,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Transform.scale(
                                    scale: _breathingScaleAnimation.value,
                                    child: _buildDoctorIllustration(
                                      illustrationHeight,
                                      _breathingAuraAnimation.value,
                                    ),
                                  ),
                                  if (t < 0.95) ...[
                                    const SizedBox(height: 14),
                                    Opacity(
                                      opacity: (1.0 - (t * 1.5)).clamp(0.0, 1.0),
                                      child: _buildCenterHint(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // 2. CARD INFORMASI KONSULTASI (SWIPE UP BERSAMAAN SAAT ILUSTRASI NAIK)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: SlideTransition(
                              position: _cardSlideAnimation,
                              child: FadeTransition(
                                opacity: _cardFadeAnimation,
                                child: _buildConsultationCard(isCompactScreen),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                color: colorPrimaryBlue.withOpacity(auraOpacity * 0.65),
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
                  color: colorPrimaryBlue.withOpacity(0.35),
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

  Widget _buildCenterHint() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Menghubungkan ke dokter...',
          style: GoogleFonts.lato(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: colorTextDark,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF5FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFC7E2FE)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colorPrimaryBlue),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Mohon tunggu sebentar (00:${_tenSecCountdown.toString().padLeft(2, '0')})',
                style: GoogleFonts.lato(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: colorPrimaryBlue,
                ),
              ),
            ],
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
              color: const Color(0xFF0288D1).withOpacity(0.9),
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
        text = 'Waktu persetujuan telah habis';
        textColor = colorExpiredRed;
        break;
    }

    return Text(
      text,
      style: GoogleFonts.lato(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: textColor,
        letterSpacing: -0.2,
      ),
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
    final isStage1Active = true; // Selalu aktif karena permintaan telah dibuat
    final isStage2Active = _status == ConsultationStatus.accepted;
    final isStage3Active = _status == ConsultationStatus.accepted;
    final isStage3Expired = _status == ConsultationStatus.expired;

    return Column(
      children: [
        // Tahap 1: Permintaan konsultasi dibuat (Aktif Biru)
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

        // Tahap 2: Menunggu persetujuan dokter (Abu saat waiting, Biru saat accepted)
        _buildTimelineStep(
          indicatorColor: isStage2Active ? colorPrimaryBlue : colorGreyDark,
          isFirst: false,
          isLast: false,
          showLineDown: true,
          lineColor: isStage3Active ? colorPrimaryBlue : colorGreyLight,
          title: 'Menunggu persetujuan dokter',
          subtitle: null,
          isTitleBold: false,
        ),

        // Tahap 3: Lanjut isi formulir (Abu saat waiting, Biru saat accepted, Merah saat expired)
        _buildTimelineStep(
          indicatorColor: isStage3Expired
              ? colorExpiredRed
              : (isStage3Active ? colorPrimaryBlue : colorGreyDark),
          isFirst: false,
          isLast: true,
          showLineDown: false,
          lineColor: colorGreyLight,
          title: isStage3Expired
              ? 'Waktu persetujuan habis'
              : 'Lanjut isi formulir',
          subtitle: null,
          isTitleBold: false,
          titleColor: isStage3Expired ? colorExpiredRed : null,
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
  }) {
    const double circleDiameter = 14.0;
    const double lineThickness = 1.6;
    const double columnWidth = 24.0;

    return IntrinsicHeight(
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
  }

  // ===========================================================================
  // BOTTOM ACTION: Countdown / Tombol Isi Formulir / Tombol Kembali
  // ===========================================================================

  Widget _buildBottomAction() {
    switch (_status) {
      case ConsultationStatus.waiting:
        // Kotak Abu Muda Countdown 05:00 .. 00:00
        return Container(
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
        );

      case ConsultationStatus.accepted:
        // Tombol Biru "Isi Formulir"
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
              'Isi Formulir',
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
}
