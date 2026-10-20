import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/booking_service.dart';
import '../../../core/services/google_calendar_service.dart';
import '../../../core/services/local_push_service.dart';
import '../../../models/booking_consultation_model.dart';
import '../../../shared/widgets/doctor_live_avatar.dart';
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
/// - Tersedia tombol "Batalkan Konsultasi" untuk membatalkan janji temu.
class StatusBookingPage extends StatefulWidget {
  final BookingConsultationModel booking;

  const StatusBookingPage({super.key, required this.booking});

  @override
  State<StatusBookingPage> createState() => _StatusBookingPageState();
}

class _StatusBookingPageState extends State<StatusBookingPage> {
  static const Color _kPrimaryBlue = Color(0xFF2B7AE8);
  static const Color _kGreenSuccess = Color(0xFF16A34A);
  static const Color _kOrangePrimary = Color(0xFFEA580C);
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
      LocalPushService().show(
        title: 'Sesi Konsultasi Berakhir',
        body: 'Waktu sesi konsultasi telah berakhir.',
        targetRole: PushRole.pengguna,
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

  void _showBatalkanDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        actionsPadding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 20.0),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFEF4444),
                size: 22.0,
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                'Batalkan Konsultasi?',
                style: GoogleFonts.lato(
                  fontSize: 17.0,
                  fontWeight: FontWeight.bold,
                  color: _kTextDark,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin membatalkan jadwal konsultasi anak bersama ${_currentBooking.doctor.name} pada ${_currentBooking.formattedDate} (${_currentBooking.timeSlot})?\n\nJadwal yang telah dibatalkan akan dihapus dan tidak dapat dikembalikan.',
          style: GoogleFonts.lato(
            fontSize: 13.5,
            height: 1.45,
            color: const Color(0xFF475569),
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  child: Text(
                    'Kembali',
                    style: GoogleFonts.lato(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(dialogCtx).pop();
                    await BookingService().cancelBooking(_currentBooking.id);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Jadwal konsultasi berhasil dibatalkan.'),
                        backgroundColor: Color(0xFFEF4444),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    _handleNavigateBack();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Ya, Batalkan',
                    style: GoogleFonts.lato(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
              // Header bersih (tanpa ikon home)
              _buildHeader(isDark),

              // Konten Tiket Booking dengan space lega & nyaman dilihat
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner Status Waktu (Ready vs Waiting)
                      _buildTimeStatusBanner(isDark),
                      const SizedBox(height: 20.0),

                      // Kartu Tiket Booking Janji Temu
                      _buildTicketCard(isDark),
                      const SizedBox(height: 20.0),

                      // Kartu Google Kalender
                      _buildGoogleCalendarInfoCard(isDark),
                      const SizedBox(height: 20.0),

                      // Informasi Alur Konsultasi
                      _buildFlowGuideCard(isDark),
                      const SizedBox(height: 28.0),

                      // Tombol Aksi Utama & Tombol Batalkan Konsultasi
                      _buildBottomBar(isDark),
                      const SizedBox(height: 24.0),
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

  // ── Header (56dp) — Bersih, tanpa ikon home ───────────────────────────────
  Widget _buildHeader(bool isDark) {
    return Container(
      height: 56.0,
      width: double.infinity,
      color: isDark ? const Color(0xFF0B1014) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20.0),
            child: InkWell(
              onTap: _handleNavigateBack,
              borderRadius: BorderRadius.circular(20.0),
              hoverColor: isDark ? Colors.white12 : const Color(0x12000000),
              child: SizedBox(
                width: 38.0,
                height: 38.0,
                child: Icon(
                  Icons.arrow_back,
                  color: isDark ? Colors.white : _kTextDark,
                  size: 24.0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              'Status Booking Konsultasi',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE9EDEF) : _kTextDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Banner Status Waktu — Alami, Tenang, Nyaman Dilihat ────────────────────
  Widget _buildTimeStatusBanner(bool isDark) {
    if (_currentBooking.isExpired) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : _kBorderLight,
            width: 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.timer_off_outlined,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                size: 22,
              ),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Waktu Konsultasi Telah Selesai',
                    style: GoogleFonts.lato(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFE2E8F0) : _kTextDark,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Batas sesi booking ini telah selesai. Ruangan chat telah ditutup dan rekap konsultasi akan tersedia pada riwayat konsultasi.',
                    style: GoogleFonts.lato(
                      fontSize: 13.0,
                      height: 1.4,
                      color: isDark ? const Color(0xFF94A3B8) : _kTextMuted,
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
          color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.25) : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isDark ? const Color(0xFF059669) : const Color(0xFFBBF7D0),
            width: 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: _kGreenSuccess,
                size: 22,
              ),
            ),
            const SizedBox(width: 14.0),
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
                      color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    hasForm
                        ? 'Sesi chat sedang berlangsung. Anda dapat langsung membuka room konsultasi untuk melanjutkan obrolan bersama dokter.'
                        : 'Silakan isi formulir konsultasi (BB, TB, dan keluhan anak) terlebih dahulu agar dokter dapat mempelajari kondisi pasien sebelum chat dimulai.',
                    style: GoogleFonts.lato(
                      fontSize: 13.0,
                      height: 1.4,
                      color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Default: Jadwal Menunggu Waktu
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : _kBorderLight,
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.4) : const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: _kPrimaryBlue,
                  size: 22.0,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Konsultasi Terjadwal',
                      style: GoogleFonts.lato(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF93C5FD) : _kPrimaryBlue,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      'Jadwal janji temu telah berhasil dikonfirmasi.',
                      style: GoogleFonts.lato(
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFF8696A0) : _kTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 10.0,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  size: 16.0,
                  color: _kPrimaryBlue,
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Text(
                    'Tombol ruang konsultasi akan otomatis aktif begitu jadwal tiba.',
                    style: GoogleFonts.lato(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
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

  // ── Kartu Tiket Booking — Bersih, Elegan, Humanis ─────────────────────────
  Widget _buildTicketCard(bool isDark) {
    final doc = _currentBooking.doctor;
    final child = _currentBooking.child;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : _kBorderLight,
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10.0,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Tiket
          Padding(
            padding: const EdgeInsets.fromLTRB(18.0, 16.0, 18.0, 14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.confirmation_number_outlined,
                      size: 20.0,
                      color: _kPrimaryBlue,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      'Detail Booking',
                      style: GoogleFonts.lato(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFE9EDEF) : _kTextDark,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                        : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    'Terkonfirmasi',
                    style: GoogleFonts.lato(
                      fontSize: 11.5,
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
            thickness: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          ),

          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Dokter
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    DoctorLiveAvatar(
                      doctorId: doc.id,
                      doctorName: doc.name,
                      fallbackPhoto: doc.avatarUrl,
                      size: 52.0,
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.name,
                            style: GoogleFonts.lato(
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFE9EDEF) : _kTextDark,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            doc.specialization,
                            style: GoogleFonts.lato(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: _kPrimaryBlue,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            doc.daftarTempatPraktik.isNotEmpty
                                ? doc.daftarTempatPraktik.first
                                : 'Praktik Online',
                            style: GoogleFonts.lato(
                              fontSize: 12.0,
                              color: isDark ? const Color(0xFF8696A0) : _kTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18.0),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                ),
                const SizedBox(height: 16.0),

                // Baris Jadwal & Pasien dengan space lega
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'JADWAL KONSULTASI',
                            style: GoogleFonts.lato(
                              fontSize: 11.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: isDark ? const Color(0xFF8696A0) : _kTextMuted,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            _currentBooking.formattedDate,
                            style: GoogleFonts.lato(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFE9EDEF) : _kTextDark,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            _currentBooking.timeSlot,
                            style: GoogleFonts.lato(
                              fontSize: 13.0,
                              fontWeight: FontWeight.bold,
                              color: _kPrimaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PASIEN ANAK',
                            style: GoogleFonts.lato(
                              fontSize: 11.0,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: isDark ? const Color(0xFF8696A0) : _kTextMuted,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            child.name,
                            style: GoogleFonts.lato(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFE9EDEF) : _kTextDark,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            child.ageDescription.isNotEmpty
                                ? child.ageDescription
                                : child.gender,
                            style: GoogleFonts.lato(
                              fontSize: 12.5,
                              color: isDark ? const Color(0xFF8696A0) : _kTextMuted,
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

  // ── Kartu Google Kalender — Ringan, Modern, Fungsional ───────────────────
  Widget _buildGoogleCalendarInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : _kBorderLight,
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFF1E88E5),
                  size: 24.0,
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tersambung ke Google Kalender',
                      style: GoogleFonts.lato(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFE9EDEF) : _kTextDark,
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      'Jadwal konsultasi telah tersinkron otomatis.',
                      style: GoogleFonts.lato(
                        fontSize: 12.0,
                        color: isDark ? const Color(0xFF8696A0) : _kTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check,
                      size: 13.0,
                      color: Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 3.0),
                    Text(
                      'Aktif',
                      style: GoogleFonts.lato(
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 11.0),
                backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                foregroundColor: const Color(0xFF1E88E5),
              ).copyWith(
                overlayColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return isDark
                        ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                        : const Color(0xFFEFF6FF);
                  }
                  return null;
                }),
              ),
              icon: const Icon(
                Icons.event_note_rounded,
                color: Color(0xFF1E88E5),
                size: 18.0,
              ),
              label: Text(
                'Buka di Google Kalender',
                style: GoogleFonts.lato(
                  fontSize: 13.0,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E88E5),
                ),
              ),
              onPressed: () {
                final url = _currentBooking.googleCalendarUrl ??
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

  // ── Informasi Alur Konsultasi — Rapi & Menjelaskan ─────────────────────────
  Widget _buildFlowGuideCard(bool isDark) {
    final isInWindow =
        _currentBooking.isInTimeWindow ||
        _currentBooking.status == 'Sedang Berlangsung';
    final hasFilled = _currentBooking.hasFilledForm;
    final isDone = _currentBooking.status.toLowerCase() == 'selesai';

    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : _kBorderLight,
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alur Konsultasi Dokter',
            style: GoogleFonts.lato(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFE9EDEF) : _kTextDark,
            ),
          ),
          const SizedBox(height: 16.0),
          _buildFlowStep(
            number: '1',
            title: 'Pilih Dokter & Booking Jadwal',
            isDone: true,
            isDark: isDark,
          ),
          _buildFlowStep(
            number: '2',
            title: 'Masuk Waktu Konsultasi & Isi Formulir',
            isDone: hasFilled,
            isActive: isInWindow && !hasFilled,
            isDark: isDark,
          ),
          _buildFlowStep(
            number: '3',
            title: 'Mulai Chat dengan Dokter',
            isDone: isDone,
            isActive: isInWindow && hasFilled,
            isDark: isDark,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFlowStep({
    required String number,
    required String title,
    bool isDone = false,
    bool isActive = false,
    bool isDark = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26.0,
              height: 26.0,
              decoration: BoxDecoration(
                color: isDone
                    ? _kGreenSuccess
                    : (isActive
                          ? _kPrimaryBlue
                          : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0))),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: isDone
                  ? const Icon(Icons.check, size: 15.0, color: Colors.white)
                  : Text(
                      number,
                      style: GoogleFonts.lato(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? Colors.white
                            : (isDark ? const Color(0xFF94A3B8) : _kTextMuted),
                      ),
                    ),
            ),
            if (!isLast)
              Container(
                width: 2.0,
                height: 16.0,
                color: isDone
                    ? const Color(0xFFBBF7D0)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
          ],
        ),
        const SizedBox(width: 14.0),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16.0),
            child: Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE9EDEF) : _kTextDark,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Bottom Action Bar: Tombol Utama & Tombol Batalkan Konsultasi ──────────
  Widget _buildBottomBar(bool isDark) {
    final isExpired = _currentBooking.isExpired;
    final isOngoing =
        _currentBooking.status == 'Sedang Berlangsung' ||
        _currentBooking.isInTimeWindow;
    final isBefore = _currentBooking.isBeforeStart && !isOngoing;
    final hasFilled = _currentBooking.hasFilledForm;
    final isCancelled = _currentBooking.status.toLowerCase() == 'dibatalkan';

    String buttonText;
    IconData buttonIcon;
    Color buttonBg;
    VoidCallback? onTap;

    if (isCancelled) {
      buttonText = 'Konsultasi Telah Dibatalkan';
      buttonIcon = Icons.cancel_outlined;
      buttonBg = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
      onTap = null;
    } else if (isExpired) {
      buttonText = 'Waktu Konsultasi Telah Selesai';
      buttonIcon = Icons.timer_off_outlined;
      buttonBg = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
      onTap = null;
    } else if (isBefore) {
      buttonText = 'Menunggu Waktu Konsultasi Tiba';
      buttonIcon = Icons.lock_clock;
      buttonBg = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
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

    final bool canCancel = !isExpired && !isCancelled && _currentBooking.status.toLowerCase() != 'selesai';

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48.0,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonBg,
              foregroundColor: Colors.white,
              disabledBackgroundColor: buttonBg,
              disabledForegroundColor: isDark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 0,
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered)) {
                  return Colors.white.withValues(alpha: 0.15);
                }
                return null;
              }),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(buttonIcon, size: 18.0),
                const SizedBox(width: 8.0),
                Text(
                  buttonText,
                  style: GoogleFonts.lato(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tombol Batalkan Konsultasi (Card Button Berkarakter dengan Hover)
        if (canCancel) ...[
          const SizedBox(height: 12.0),
          Container(
            width: double.infinity,
            height: 48.0,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5),
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 6.0,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12.0),
              child: InkWell(
                onTap: _showBatalkanDialog,
                hoverColor: isDark
                    ? const Color(0xFF7F1D1D).withValues(alpha: 0.25)
                    : const Color(0xFFFEF2F2),
                splashColor: const Color(0xFFEF4444).withValues(alpha: 0.12),
                highlightColor: const Color(0xFFEF4444).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cancel_outlined,
                      color: Color(0xFFEF4444),
                      size: 18.0,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      'Batalkan Konsultasi',
                      style: GoogleFonts.lato(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
