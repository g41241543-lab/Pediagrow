import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/booking_service.dart';
import '../../../models/booking_consultation_model.dart';
import '../beranda/beranda_page.dart';
import 'chat_konsultasi_page.dart';
import 'daftar_dokter_page.dart';
import 'formulir_konsultasi_page.dart';

/// Halaman "Status Booking Konsultasi" PediaGrow.
///
/// Menampilkan tiket booking, integrasi Google Kalender, dan status waktu konsultasi secara realtime.
/// - Belum tiba jadwal: Menunggu waktu tiba (tombol non-aktif, info pengingat menyatu).
/// - Saat jadwal tiba: Tombol aktif menjadi "Isi Formulir Konsultasi" (pertama kali).
/// - Setelah isi formulir: Langsung beralih ke Room Chat, dan selama rentang booking pengguna
///   dapat membuka room konsultasi kapan saja dengan riwayat chat tersimpan.
/// - Waktu booking habis: Room konsultasi ditutup dan tidak dapat dibuka lagi.
class StatusBookingPage extends StatefulWidget {
  final BookingConsultationModel booking;

  const StatusBookingPage({super.key, required this.booking});

  @override
  State<StatusBookingPage> createState() => _StatusBookingPageState();
}

class _StatusBookingPageState extends State<StatusBookingPage> {
  static const Color _kPrimaryBlue = Color(0xFF2B7AE8);
  static const Color _kGreenSuccess = Color(0xFF16A34A);
  static const Color _kOrangePrimary = Color(0xFFF59E0B);
  static const Color _kTextDark = Color(0xFF1E293B);
  static const Color _kTextMuted = Color(0xFF64748B);
  static const Color _kBorderLight = Color(0xFFE2E8F0);

  late BookingConsultationModel _currentBooking;
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;

    BookingService().bookingsNotifier.addListener(_syncBookingFromService);
    BookingService().activeBookingNotifier.addListener(_syncBookingFromService);

    // Timer cek waktu real-time setiap detik agar peralihan status jadwal presisi
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    BookingService().bookingsNotifier.removeListener(_syncBookingFromService);
    BookingService().activeBookingNotifier.removeListener(
      _syncBookingFromService,
    );
    super.dispose();
  }

  void _syncBookingFromService() {
    if (!mounted) return;
    final allBookings = BookingService().bookingsNotifier.value;
    final found = allBookings.where((b) => b.id == _currentBooking.id);
    if (found.isNotEmpty) {
      setState(() {
        _currentBooking = found.first;
      });
    } else if (BookingService().activeBookingNotifier.value?.id ==
        _currentBooking.id) {
      setState(() {
        _currentBooking = BookingService().activeBookingNotifier.value!;
      });
    }
  }

  void _onIsiFormulirPressed() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => FormulirKonsultasiPage(
              doctor: _currentBooking.doctor,
              child: _currentBooking.child,
              booking: _currentBooking,
            ),
          ),
        )
        .then((_) {
          _syncBookingFromService();
        });
  }

  void _onMasukRoomKonsultasiPressed() {
    if (_currentBooking.isExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Waktu sesi konsultasi telah berakhir.',
            style: GoogleFonts.lato(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFE53E3E),
        ),
      );
      return;
    }

    final effectiveSessionId =
        _currentBooking.sessionId ?? 'session_${_currentBooking.id}';

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => ChatKonsultasiPage(
              doctor: _currentBooking.doctor,
              child: _currentBooking.child,
              weightKg: _currentBooking.weightKg,
              heightCm: _currentBooking.heightCm,
              complaint: _currentBooking.complaint,
              sessionId: effectiveSessionId,
              booking: _currentBooking,
            ),
          ),
        )
        .then((_) {
          _syncBookingFromService();
        });
  }

  void _handleNavigateBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const DaftarDokterPage(initialTabIndex: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleNavigateBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: _buildBottomBar(),
        body: SafeArea(
          child: Column(
            children: [
              // Header (56dp)
              _buildHeader(),

              // Konten Tiket Booking
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // Banner Status Waktu (Ready vs Waiting)
                      _buildTimeStatusBanner(),
                      const SizedBox(height: 18),

                      // Kartu Tiket Booking Janji Temu
                      _buildTicketCard(),
                      const SizedBox(height: 20),

                      // Kartu Google Kalender
                      _buildGoogleCalendarInfoCard(),
                      const SizedBox(height: 20),

                      // Informasi Alur Konsultasi
                      _buildFlowGuideCard(),
                      const SizedBox(height: 32),
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

  // ── Header (56dp) ──────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      height: 56.0,
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _handleNavigateBack,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.arrow_back, color: _kTextDark, size: 24.0),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              'Status Booking',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 19.0,
                fontWeight: FontWeight.bold,
                color: _kTextDark,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const BerandaPage()),
                  (route) => false,
                );
              }
            },
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.arrow_back, color: _kTextDark, size: 24.0),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              'Status Booking Konsultasi',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 19.0,
                fontWeight: FontWeight.bold,
                color: _kTextDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Banner Status Waktu ───────────────────────────────────────────────────
  Widget _buildTimeStatusBanner() {
    if (_currentBooking.isExpired) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: const BoxDecoration(
                color: Color(0xFF64748B),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.timer_off_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Waktu Konsultasi Telah Berakhir',
                    style: GoogleFonts.lato(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 3.0),
                  Text(
                    'Batas waktu sesi booking ini telah selesai. Ruangan chat telah ditutup dan tidak dapat dibuka lagi.',
                    style: GoogleFonts.lato(
                      fontSize: 12.5,
                      height: 1.35,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_currentBooking.isInTimeWindow) {
      final hasForm = _currentBooking.hasFilledForm;
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: const BoxDecoration(
                color: _kGreenSuccess,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasForm
                        ? 'Sesi Konsultasi Sedang Aktif'
                        : 'Waktu Konsultasi Telah Tiba!',
                    style: GoogleFonts.lato(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF166534),
                    ),
                  ),
                  const SizedBox(height: 3.0),
                  Text(
                    hasForm
                        ? 'Sesi chat sedang berlangsung. Anda dapat langsung membuka room konsultasi untuk melanjutkan obrolan bersama dokter.'
                        : 'Silakan isi formulir konsultasi (BB, TB, dan keluhan anak) terlebih dahulu agar dokter dapat mempelajari kondisi pasien sebelum chat dimulai.',
                    style: GoogleFonts.lato(
                      fontSize: 12.5,
                      height: 1.35,
                      color: const Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.access_time_filled_rounded,
                color: _kPrimaryBlue,
                size: 24.0,
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Text(
                  'Konsultasi Terjadwal',
                  style: GoogleFonts.lato(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: _kPrimaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            'Sesi konsultasi dokter bersifat realtime. Sistem akan otomatis mengaktifkan ruang konsultasi begitu jadwal janji temu tiba.',
            style: GoogleFonts.lato(
              fontSize: 12.5,
              height: 1.35,
              color: const Color(0xFF1E40AF),
            ),
          ),
          const SizedBox(height: 12.0),
          // Keterangan menyatu terintegrasi (bukan button yang beralih halaman)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  size: 16.0,
                  color: _kPrimaryBlue,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    'Pengingat Google Kalender aktif: Tombol ruang konsultasi akan otomatis aktif saat jadwal tiba.',
                    style: GoogleFonts.lato(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E40AF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Kartu Tiket Booking ───────────────────────────────────────────────────
  Widget _buildTicketCard() {
    final doc = _currentBooking.doctor;
    final child = _currentBooking.child;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: _kBorderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Tiket
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.confirmation_number_outlined,
                      size: 18.0,
                      color: _kPrimaryBlue,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      'Tiket Janji Temu',
                      style: GoogleFonts.lato(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: _kTextDark,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    'Terkonfirmasi',
                    style: GoogleFonts.lato(
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                      color: _kGreenSuccess,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kBorderLight),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Dokter
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Container(
                        width: 50.0,
                        height: 50.0,
                        color: const Color(0xFFE2E8F0),
                        child:
                            doc.avatarUrl != null && doc.avatarUrl!.isNotEmpty
                            ? (doc.avatarUrl!.startsWith('http')
                                  ? Image.network(
                                      doc.avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.person,
                                        color: _kTextMuted,
                                      ),
                                    )
                                  : Image.file(
                                      File(doc.avatarUrl!),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.person,
                                        color: _kTextMuted,
                                      ),
                                    ))
                            : const Icon(Icons.person, color: _kTextMuted),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.name,
                            style: GoogleFonts.lato(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: _kTextDark,
                            ),
                          ),
                          Text(
                            doc.specialization,
                            style: GoogleFonts.lato(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                              color: _kPrimaryBlue,
                            ),
                          ),
                          Text(
                            doc.daftarTempatPraktik.isNotEmpty
                                ? doc.daftarTempatPraktik.first
                                : 'Praktik Online',
                            style: GoogleFonts.lato(
                              fontSize: 11.5,
                              color: _kTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                const Divider(height: 1, color: _kBorderLight),
                const SizedBox(height: 14.0),

                // Baris Jadwal & Pasien
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jadwal Konsultasi',
                            style: GoogleFonts.lato(
                              fontSize: 11.5,
                              color: _kTextMuted,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            _currentBooking.formattedDate,
                            style: GoogleFonts.lato(
                              fontSize: 13.0,
                              fontWeight: FontWeight.bold,
                              color: _kTextDark,
                            ),
                          ),
                          Text(
                            _currentBooking.timeSlot,
                            style: GoogleFonts.lato(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: _kPrimaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pasien Anak',
                            style: GoogleFonts.lato(
                              fontSize: 11.5,
                              color: _kTextMuted,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            child.name,
                            style: GoogleFonts.lato(
                              fontSize: 13.0,
                              fontWeight: FontWeight.bold,
                              color: _kTextDark,
                            ),
                          ),
                          Text(
                            child.ageDescription.isNotEmpty
                                ? child.ageDescription
                                : child.gender,
                            style: GoogleFonts.lato(
                              fontSize: 12.0,
                              color: _kTextMuted,
                            ),
                          ),
                        ],
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

  // ── Kartu Google Kalender ─────────────────────────────────────────────────
  Widget _buildGoogleCalendarInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: _kBorderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF1E88E5),
              size: 24.0,
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terhubung ke Google Kalender',
                  style: GoogleFonts.lato(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: _kTextDark,
                  ),
                ),
                Text(
                  'Pengingat otomatis aktif dan notifikasi kalender akan muncul saat jadwal tiba.',
                  style: GoogleFonts.lato(fontSize: 11.5, color: _kTextMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 5.0,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 14.0,
                  color: Color(0xFF16A34A),
                ),
                const SizedBox(width: 4.0),
                Text(
                  'Aktif',
                  style: GoogleFonts.lato(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF166534),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Informasi Alur Konsultasi ─────────────────────────────────────────────
  Widget _buildFlowGuideCard() {
    final isInWindow = _currentBooking.isInTimeWindow;
    final hasFilled = _currentBooking.hasFilledForm;
    final isDone = _currentBooking.status.toLowerCase() == 'selesai';

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: _kBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alur Konsultasi Dokter',
            style: GoogleFonts.lato(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: _kTextDark,
            ),
          ),
          const SizedBox(height: 12.0),
          _buildFlowStep(
            number: '1',
            title: 'Pilih Dokter & Booking Jadwal',
            subtitle: 'Jadwal janji temu berhasil dipesan & terhubung ke Google Kalender.',
            isDone: true,
          ),
          _buildFlowStep(
            number: '2',
            title: 'Masuk Waktu Konsultasi & Isi Formulir',
            subtitle: 'Lengkapi berat badan, tinggi badan, dan keluhan anak saat jadwal tiba.',
            isDone: hasFilled,
            isActive: isInWindow && !hasFilled,
          ),
          _buildFlowStep(
            number: '3',
            title: 'Mulai Chat dengan Dokter',
            subtitle: 'Konsultasi interaktif langsung bersama dokter spesialis selama rentang booking.',
            isDone: isDone,
            isActive: isInWindow && hasFilled,
          ),
        ],
      ),
    );
  }

  Widget _buildFlowStep({
    required String number,
    required String title,
    required String subtitle,
    bool isDone = false,
    bool isActive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22.0,
            height: 22.0,
            decoration: BoxDecoration(
              color: isDone
                  ? _kGreenSuccess
                  : (isActive ? _kPrimaryBlue : const Color(0xFFE2E8F0)),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isDone
                ? const Icon(Icons.check, size: 14.0, color: Colors.white)
                : Text(
                    number,
                    style: GoogleFonts.lato(
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : _kTextMuted,
                    ),
                  ),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lato(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: _kTextDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.lato(fontSize: 11.5, color: _kTextMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Action Bar ─────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final isExpired = _currentBooking.isExpired;
    final isBefore = _currentBooking.isBeforeStart;
    final hasFilled = _currentBooking.hasFilledForm;

    String buttonText;
    IconData buttonIcon;
    Color buttonBg;
    VoidCallback? onTap;

    if (isExpired) {
      buttonText = 'Waktu Konsultasi Telah Berakhir';
      buttonIcon = Icons.timer_off_outlined;
      buttonBg = const Color(0xFFCBD5E1);
      onTap = null;
    } else if (isBefore) {
      buttonText = 'Menunggu Waktu Konsultasi Tiba';
      buttonIcon = Icons.lock_clock;
      buttonBg = const Color(0xFFCBD5E1);
      onTap = null;
    } else if (hasFilled) {
      buttonText = 'Masuk ke Room Konsultasi';
      buttonIcon = Icons.chat_bubble_outline_rounded;
      buttonBg = _kPrimaryBlue;
      onTap = _onMasukRoomKonsultasiPressed;
    } else {
      buttonText = 'Isi Formulir Konsultasi Sekarang';
      buttonIcon = Icons.edit_document;
      buttonBg = _kOrangePrimary;
      onTap = _onIsiFormulirPressed;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 8.0,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48.0,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonBg,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(buttonIcon, size: 18.0),
                const SizedBox(width: 8.0),
                Text(
                  buttonText,
                  style: GoogleFonts.lato(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
