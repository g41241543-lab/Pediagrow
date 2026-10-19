import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/booking_service.dart';
import '../../../core/services/google_calendar_service.dart';
import '../../../models/booking_consultation_model.dart';
// TODO: sesuaikan path import BerandaPage dengan lokasi file beranda pengguna di proyekmu.
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
  static const Color _kTextDark = Color(0xFF1A2228);
  static const Color _kTextMuted = Color(0xFF667781);
  static const Color _kBorderLight = Color(0xFFE9EDEF);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleNavigateBack();
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1014) : Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header (56dp)
              _buildHeader(isDark),

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
                      _buildTimeStatusBanner(isDark),
                      const SizedBox(height: 18),

                      // Kartu Tiket Booking Janji Temu
                      _buildTicketCard(isDark),
                      const SizedBox(height: 20),

                      // Kartu Google Kalender
                      _buildGoogleCalendarInfoCard(isDark),
                      const SizedBox(height: 20),

                      // Informasi Alur Konsultasi
                      _buildFlowGuideCard(isDark),
                      const SizedBox(height: 24),

                      // Tombol Aksi
                      _buildBottomBar(isDark),
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
  Widget _buildHeader(bool isDark) {
    return Container(
      height: 56.0,
      width: double.infinity,
      color: isDark ? const Color(0xFF0B1014) : Colors.white,
      padding: const EdgeInsets.only(left: 12.0, right: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _handleNavigateBack,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 32.0,
              height: 32.0,
              child: Icon(
                Icons.arrow_back,
                color: isDark ? Colors.white : _kTextDark,
                size: 24.0,
              ),
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
                color: isDark ? const Color(0xFFE9EDEF) : _kTextDark,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const BerandaPage()),
                (route) => false,
              );
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                Icons.home_outlined,
                color: isDark ? Colors.white : _kTextDark,
                size: 24.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Banner Status Waktu ───────────────────────────────────────────────────
  Widget _buildTimeStatusBanner(bool isDark) {
    if (_currentBooking.isExpired) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2228) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: isDark ? const Color(0xFF2C363D) : const Color(0xFFD1D7DB),
            width: 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: const BoxDecoration(
                color: Color(0xFF667781),
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
                      color: isDark
                          ? const Color(0xFFE9EDEF)
                          : const Color(0xFF2C363D),
                    ),
                  ),
                  const SizedBox(height: 3.0),
                  Text(
                    'Batas waktu sesi booking ini telah selesai. Ruangan chat telah ditutup dan tidak dapat dibuka lagi.',
                    style: GoogleFonts.lato(
                      fontSize: 12.5,
                      height: 1.35,
                      color: isDark
                          ? const Color(0xFF8696A0)
                          : const Color(0xFF667781),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_currentBooking.isInTimeWindow ||
        _currentBooking.status == 'Sedang Berlangsung') {
      final hasForm = _currentBooking.hasFilledForm;
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF064E3B).withValues(alpha: 0.3)
              : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC),
            width: 1.2,
          ),
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
                      color: isDark
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFF166534),
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
                      color: isDark
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFF15803D),
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
        color: isDark
            ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: isDark ? const Color(0xFF2563EB) : const Color(0xFFBFDBFE),
          width: 1.2,
        ),
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
                    color: isDark ? const Color(0xFF60A5FA) : _kPrimaryBlue,
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
              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
            ),
          ),
          const SizedBox(height: 12.0),
          // Keterangan menyatu terintegrasi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B1014) : Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFFBFDBFE),
              ),
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
                      color: isDark
                          ? const Color(0xFF93C5FD)
                          : const Color(0xFF1E40AF),
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
  Widget _buildTicketCard(bool isDark) {
    final doc = _currentBooking.doctor;
    final child = _currentBooking.child;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : _kBorderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B1014) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15.0),
              ),
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
                        color: isDark ? const Color(0xFFE9EDEF) : _kTextDark,
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
                    color: isDark
                        ? const Color(0xFF064E3B).withValues(alpha: 0.4)
                        : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    'Terkonfirmasi',
                    style: GoogleFonts.lato(
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF4ADE80) : _kGreenSuccess,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF2C363D) : _kBorderLight,
          ),

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
                        color: isDark
                            ? const Color(0xFF0B1014)
                            : const Color(0xFFE9EDEF),
                        child:
                            doc.avatarUrl != null && doc.avatarUrl!.isNotEmpty
                            ? (doc.avatarUrl!.startsWith('http')
                                  ? Image.network(
                                      doc.avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.person,
                                                color: _kTextMuted,
                                              ),
                                    )
                                  : Image.file(
                                      File(doc.avatarUrl!),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
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
                              color: isDark
                                  ? const Color(0xFFE9EDEF)
                                  : _kTextDark,
                            ),
                          ),
                          Text(
                            doc.specialization,
                            style: GoogleFonts.lato(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF60A5FA)
                                  : _kPrimaryBlue,
                            ),
                          ),
                          Text(
                            doc.daftarTempatPraktik.isNotEmpty
                                ? doc.daftarTempatPraktik.first
                                : 'Praktik Online',
                            style: GoogleFonts.lato(
                              fontSize: 11.5,
                              color: isDark
                                  ? const Color(0xFF8696A0)
                                  : _kTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF2C363D) : _kBorderLight,
                ),
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
                              color: isDark
                                  ? const Color(0xFF8696A0)
                                  : _kTextMuted,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            _currentBooking.formattedDate,
                            style: GoogleFonts.lato(
                              fontSize: 13.0,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFE9EDEF)
                                  : _kTextDark,
                            ),
                          ),
                          Text(
                            _currentBooking.timeSlot,
                            style: GoogleFonts.lato(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFF60A5FA)
                                  : _kPrimaryBlue,
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
                              color: isDark
                                  ? const Color(0xFF8696A0)
                                  : _kTextMuted,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            child.name,
                            style: GoogleFonts.lato(
                              fontSize: 13.0,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFE9EDEF)
                                  : _kTextDark,
                            ),
                          ),
                          Text(
                            child.ageDescription.isNotEmpty
                                ? child.ageDescription
                                : child.gender,
                            style: GoogleFonts.lato(
                              fontSize: 12.0,
                              color: isDark
                                  ? const Color(0xFF8696A0)
                                  : _kTextMuted,
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
  Widget _buildGoogleCalendarInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : _kBorderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0B1014) : Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2C363D)
                        : const Color(0xFFD1D7DB),
                  ),
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
                        color: isDark ? const Color(0xFFE9EDEF) : _kTextDark,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      'Jadwal ${_currentBooking.formattedDate} (${_currentBooking.timeSlot}) telah tersambung sebagai kegiatan kalender.',
                      style: GoogleFonts.lato(
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFF8696A0) : _kTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 5.0,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF064E3B).withValues(alpha: 0.4)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF059669)
                        : const Color(0xFF86EFAC),
                  ),
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
                        color: isDark
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1E88E5), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                backgroundColor: isDark
                    ? const Color(0xFF1A2228)
                    : Colors.white,
              ),
              icon: const Icon(
                Icons.event_note_rounded,
                color: Color(0xFF1E88E5),
                size: 18.0,
              ),
              label: Text(
                'Buka di Google Kalender',
                style: GoogleFonts.lato(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E88E5),
                ),
              ),
              onPressed: () {
                final url =
                    _currentBooking.googleCalendarUrl ??
                    GoogleCalendarService().generateCalendarUrl(
                      _currentBooking,
                    );
                BookingService().launchGoogleCalendar(url);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Informasi Alur Konsultasi ─────────────────────────────────────────────
  Widget _buildFlowGuideCard(bool isDark) {
    final isInWindow =
        _currentBooking.isInTimeWindow ||
        _currentBooking.status == 'Sedang Berlangsung';
    final hasFilled = _currentBooking.hasFilledForm;
    final isDone = _currentBooking.status.toLowerCase() == 'selesai';

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : _kBorderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alur Konsultasi Dokter',
            style: GoogleFonts.lato(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFE9EDEF) : _kTextDark,
            ),
          ),
          const SizedBox(height: 12.0),
          _buildFlowStep(
            number: '1',
            title: 'Pilih Dokter & Booking Jadwal',
            subtitle: 'Jadwal janji temu berhasil dipesan & terhubung ke Google Kalender.',
            isDone: true,
            isDark: isDark,
          ),
          _buildFlowStep(
            number: '2',
            title: 'Masuk Waktu Konsultasi & Isi Formulir',
            subtitle: 'Lengkapi berat badan, tinggi badan, dan keluhan anak saat jadwal tiba.',
            isDone: hasFilled,
            isActive: isInWindow && !hasFilled,
            isDark: isDark,
          ),
          _buildFlowStep(
            number: '3',
            title: 'Mulai Chat dengan Dokter',
            subtitle: 'Konsultasi interaktif langsung bersama dokter spesialis selama rentang booking.',
            isDone: isDone,
            isActive: isInWindow && hasFilled,
            isDark: isDark,
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
    bool isDark = false,
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
                  : (isActive
                        ? _kPrimaryBlue
                        : (isDark
                              ? const Color(0xFF2C363D)
                              : const Color(0xFFE9EDEF))),
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
                      color: isActive
                          ? Colors.white
                          : (isDark ? const Color(0xFF8696A0) : _kTextMuted),
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
                    color: isDark ? const Color(0xFFE9EDEF) : _kTextDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.lato(
                    fontSize: 11.5,
                    color: isDark ? const Color(0xFF8696A0) : _kTextMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Action Bar ─────────────────────────────────────────────────────
  Widget _buildBottomBar(bool isDark) {
    final isExpired = _currentBooking.isExpired;
    final isOngoing =
        _currentBooking.status == 'Sedang Berlangsung' ||
        _currentBooking.isInTimeWindow;
    final isBefore = _currentBooking.isBeforeStart && !isOngoing;
    final hasFilled = _currentBooking.hasFilledForm;

    String buttonText;
    IconData buttonIcon;
    Color buttonBg;
    VoidCallback? onTap;

    if (isExpired) {
      buttonText = 'Waktu Konsultasi Telah Berakhir';
      buttonIcon = Icons.timer_off_outlined;
      buttonBg = isDark ? const Color(0xFF2C363D) : const Color(0xFFD1D7DB);
      onTap = null;
    } else if (isBefore) {
      buttonText = 'Menunggu Waktu Konsultasi Tiba';
      buttonIcon = Icons.lock_clock;
      buttonBg = isDark ? const Color(0xFF2C363D) : const Color(0xFFD1D7DB);
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

    return SizedBox(
      width: double.infinity,
      height: 48.0,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonBg,
          foregroundColor: Colors.white,
          disabledBackgroundColor: buttonBg,
          disabledForegroundColor: isDark
              ? const Color(0xFF8696A0)
              : const Color(0xFF667781),
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
    );
  }
}
