import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/booking_service.dart';
import '../../../core/services/google_calendar_service.dart';
import '../../../core/services/local_push_service.dart';
import '../../../models/booking_consultation_model.dart';
import '../../../models/child_model.dart';
import '../../../models/doctor_model.dart';
import 'daftar_dokter_page.dart';
import 'status_booking_page.dart';

/// Halaman Pembayaran Konsultasi Dokter (POV Pengguna).
///
/// Pengguna melihat rincian biaya, memilih metode pembayaran (Virtual Account atau QRIS),
/// melihat nomor tagihan / QR, serta petunjuk pembayaran (m-Banking, ATM, Internet Banking).
/// Setelah pembayaran dikonfirmasi/diverifikasi, jadwal konsultasi resmi tersimpan dan
/// muncul alert dialog sukses dengan opsi opsional menyambungkan ke Google Kalender.
class PembayaranKonsultasiPage extends StatefulWidget {
  final DoctorModel doctor;
  final ChildModel child;
  final DateTime selectedDate;
  final String selectedTimeSlot;
  final DateTime startDateTime;
  final DateTime endDateTime;

  const PembayaranKonsultasiPage({
    super.key,
    required this.doctor,
    required this.child,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.startDateTime,
    required this.endDateTime,
  });

  @override
  State<PembayaranKonsultasiPage> createState() =>
      _PembayaranKonsultasiPageState();
}

enum MetodePembayaran { va, qris }

class _PembayaranKonsultasiPageState extends State<PembayaranKonsultasiPage> {
  static const Color _colorPrimaryBlue = Color(0xFF3985E7);
  static const Color _colorTextBlack = Color(0xFF1A2228);
  static const Color _colorLabelGrey = Color(0xFF667781);
  static const Color _colorBorder = Color(0xFFE9EDEF);

  MetodePembayaran _selectedMethod = MetodePembayaran.va;
  String _selectedBank = 'BCA';

  // Bank Virtual Account options
  final List<Map<String, String>> _bankList = [
    {
      'code': 'BCA',
      'name': 'BCA Virtual Account',
      'vaNumber': '8808 0812 3456 7891',
      'color': '#003087',
    },
    {
      'code': 'Mandiri',
      'name': 'Mandiri Virtual Account',
      'vaNumber': '8902 2026 8812 3456',
      'color': '#003087',
    },
    {
      'code': 'BRI',
      'name': 'BRI Virtual Account (BRIVA)',
      'vaNumber': '1280 0812 3456 7892',
      'color': '#00529B',
    },
    {
      'code': 'BNI',
      'name': 'BNI Virtual Account',
      'vaNumber': '9880 0812 3456 7893',
      'color': '#F37021',
    },
    {
      'code': 'BTN',
      'name': 'BTN Virtual Account',
      'vaNumber': '0027 0812 3456 7894',
      'color': '#1D4ED8',
    },
    {
      'code': 'Maybank',
      'name': 'Maybank Virtual Account',
      'vaNumber': '9888 0812 3456 7895',
      'color': '#F5A623',
    },
    {
      'code': 'Lainnya',
      'name': 'Bank Lainnya',
      'vaNumber': '8008 0812 3456 7896',
      'color': '#64748B',
    },
  ];

  // Timer countdown 15 menit
  Timer? _countdownTimer;
  int _remainingSeconds = 15 * 60; // 15 menit

  bool _isProcessing = false;
  bool _isPaid = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _currentVaNumber {
    final bank = _bankList.firstWhere(
      (b) => b['code'] == _selectedBank,
      orElse: () => _bankList.first,
    );
    return bank['vaNumber']!;
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text.replaceAll(' ', '')));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label berhasil disalin ke clipboard',
          style: GoogleFonts.lato(fontSize: 13),
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handlePayment() async {
    if (_isProcessing || _isPaid) return;

    setState(() {
      _isProcessing = true;
    });

    // Simulasi verifikasi mBanking / QRIS
    await Future.delayed(const Duration(milliseconds: 1400));

    // Generate link Google Kalender
    final calUrl = BookingService().generateGoogleCalendarUrl(
      doctor: widget.doctor,
      child: widget.child,
      startTime: widget.startDateTime,
      endTime: widget.endDateTime,
    );

    // Buat data booking resmi
    final newBooking = BookingConsultationModel(
      id: 'booking-${DateTime.now().millisecondsSinceEpoch}',
      userId: widget.child.ownerId.isNotEmpty ? widget.child.ownerId : null,
      doctor: widget.doctor,
      child: widget.child,
      scheduledDate: widget.selectedDate,
      scheduledTimeSlot: widget.selectedTimeSlot,
      scheduledStartDateTime: widget.startDateTime,
      scheduledEndDateTime: widget.endDateTime,
      googleCalendarUrl: calUrl,
      status: 'Terjadwal',
      createdAt: DateTime.now(),
    );

    // 1. Tampilkan notifikasi pembayaran berhasil (notifikasi pertama yang muncul)
    LocalPushService().show(
      title: 'Pembayaran Berhasil',
      body:
          'Pembayaran terverifikasi. Jadwal konsultasi anak ${widget.child.name} bersama ${widget.doctor.name} telah berhasil dijadwalkan.',
      targetRole: PushRole.pengguna,
    );

    // Jeda singkat agar notifikasi pembayaran terproses terlebih dahulu
    await Future.delayed(const Duration(milliseconds: 300));

    // 2. Simpan booking ke BookingService (kemudian diikuti dengan notifikasi booking berhasil)
    try {
      await BookingService().addBooking(newBooking);
    } catch (e) {
      debugPrint('[Pembayaran] Catatan simpan booking: $e');
    }

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _isPaid = true;
    });

    // Tampilkan Alert Dialog Sukses persis seperti pada lampiran pengguna
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildSuccessDialog(ctx, newBooking),
    );
  }

  // ─── DIALOG PEMBAYARAN & BOOKING BERHASIL (SESUAI LAMPIRAN) ────────────────
  Widget _buildSuccessDialog(
    BuildContext ctx,
    BookingConsultationModel booking,
  ) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1A2228) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Lingkaran Centang Hijau
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.28),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.check_rounded,
                  size: 44,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Judul: "Pembayaran Selesai"
            Text(
              'Pembayaran Selesai',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Jadwal konsultasi Anda bersama ${widget.doctor.name} telah berhasil terkonfirmasi.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 13,
                color: isDark ? const Color(0xFF8696A0) : _colorLabelGrey,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),

            // Info Box Tersambung ke Google Kalender
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E3A8A).withValues(alpha: 0.18)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2563EB).withValues(alpha: 0.4)
                      : const Color(0xFFBFDBFE),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A2228) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFBFDBFE),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: _colorPrimaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tersambung ke Google Kalender',
                          style: GoogleFonts.lato(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFF93C5FD)
                                : const Color(0xFF1E40AF),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Kegiatan pada ${booking.formattedDate} (${booking.scheduledTimeSlot}) otomatis didaftarkan ke Google Kalender Anda dengan alarm pengingat.',
                          style: GoogleFonts.lato(
                            fontSize: 11.5,
                            color: isDark
                                ? const Color(0xFFD1D7DB)
                                : const Color(0xFF3B5998),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Tombol 1: Buka di Google Kalender (Opsional)
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _colorPrimaryBlue, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.event_note_rounded,
                  color: _colorPrimaryBlue,
                  size: 20,
                ),
                label: Text(
                  'Buka di Google Kalender',
                  style: GoogleFonts.lato(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: _colorPrimaryBlue,
                  ),
                ),
                onPressed: () {
                  final url = booking.googleCalendarUrl ??
                      GoogleCalendarService().generateCalendarUrl(booking);
                  BookingService().launchGoogleCalendar(url);
                },
              ),
            ),
            const SizedBox(height: 10),

            // Tombol 2: Lihat Status Booking / Detail Booking
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _colorPrimaryBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop(); // Tutup dialog
                  // Navigasi ke StatusBookingPage / Jadwal Konsultasi
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => StatusBookingPage(
                        booking: booking,
                      ),
                    ),
                  );
                },
                child: Text(
                  'Lihat Status Booking',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_isProcessing,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmCancelPayment(context);
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1014) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1A2228) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : _colorTextBlack,
            ),
            onPressed: () => _confirmCancelPayment(context),
          ),
          title: Text(
            'Pembayaran Konsultasi',
            style: GoogleFonts.lato(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : _colorTextBlack,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: isDark ? const Color(0xFF2C363D) : _colorBorder,
              height: 1,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Banner Countdown Waktu Pembayaran
              _buildTimerBanner(isDark),
              const SizedBox(height: 14),

              // 2. Card Ringkasan Konsultasi
              _buildConsultationSummaryCard(isDark),
              const SizedBox(height: 14),

              // 3. Card Rincian Biaya
              _buildPaymentDetailCard(isDark),
              const SizedBox(height: 18),

              // 4. Pilih Metode Pembayaran (Tab VA / QRIS)
              Text(
                'Pilih Metode Pembayaran',
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
                ),
              ),
              const SizedBox(height: 10),
              _buildPaymentMethodTabs(isDark),
              const SizedBox(height: 14),

              // 5. Isi Metode (Tampilan VA atau QRIS)
              if (_selectedMethod == MetodePembayaran.va)
                _buildVirtualAccountSection(isDark)
              else
                _buildQrisSection(isDark),

              const SizedBox(height: 20),

              // 6. Petunjuk / Cara Pembayaran
              _buildPaymentInstructionsAccordion(isDark),
              const SizedBox(height: 32),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(isDark),
      ),
    );
  }

  void _confirmCancelPayment(BuildContext context) {
    if (_isPaid) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const DaftarDokterPage(initialTabIndex: 1),
        ),
        (route) => false,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Batalkan Pembayaran?',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Jadwal konsultasi belum tersimpan. Jika keluar sekarang, pemesanan sesi ini tidak akan dicatat.',
          style: GoogleFonts.lato(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Lanjutkan Pembayaran',
              style: GoogleFonts.lato(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              'Batalkan',
              style: GoogleFonts.lato(
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 1. BANNER TIMER COUNTDOWN ─────────────────────────────────────────────
  Widget _buildTimerBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E3A8A).withValues(alpha: 0.18)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2563EB).withValues(alpha: 0.4)
              : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            size: 20,
            color: isDark ? const Color(0xFF93C5FD) : _colorPrimaryBlue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Selesaikan pembayaran dalam waktu',
              style: GoogleFonts.lato(
                fontSize: 12.5,
                color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2563EB) : _colorPrimaryBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatTimer(_remainingSeconds),
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. CARD RINGKASAN KONSULTASI ──────────────────────────────────────────
  Widget _buildConsultationSummaryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : _colorBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: (widget.doctor.avatarUrl != null && widget.doctor.avatarUrl!.isNotEmpty)
                    ? Image.network(
                        widget.doctor.avatarUrl!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildDoctorAvatarFallback(isDark),
                      )
                    : _buildDoctorAvatarFallback(isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.doctor.name,
                      style: GoogleFonts.lato(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.doctor.specialization,
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: _colorPrimaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF2C363D) : _colorBorder,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pasien Anak',
                style: GoogleFonts.lato(fontSize: 12, color: _colorLabelGrey),
              ),
              Text(
                widget.child.name,
                style: GoogleFonts.lato(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jadwal Konsultasi',
                style: GoogleFonts.lato(fontSize: 12, color: _colorLabelGrey),
              ),
              Text(
                '${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year} • ${widget.selectedTimeSlot}',
                style: GoogleFonts.lato(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorAvatarFallback(bool isDark) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1014) : const Color(0xFFEFF6FF),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
      ),
      child: const Icon(
        Icons.medical_services_rounded,
        color: _colorPrimaryBlue,
        size: 22,
      ),
    );
  }

  // ─── 3. CARD RINCIAN BIAYA ─────────────────────────────────────────────────
  Widget _buildPaymentDetailCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : _colorBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rincian Biaya',
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jasa Konsultasi Dokter (30 Menit)',
                style: GoogleFonts.lato(fontSize: 12.5, color: _colorLabelGrey),
              ),
              Text(
                widget.doctor.consultationFeeFormatted,
                style: GoogleFonts.lato(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Biaya Layanan Aplikasi',
                style: GoogleFonts.lato(fontSize: 12.5, color: _colorLabelGrey),
              ),
              Text(
                'Gratis',
                style: GoogleFonts.lato(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF2C363D) : _colorBorder,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pembayaran',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
                ),
              ),
              Row(
                children: [
                  Text(
                    widget.doctor.consultationFeeFormatted,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF93C5FD) : _colorPrimaryBlue,
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _copyToClipboard(
                      widget.doctor.effectiveFee.toString(),
                      'Nominal pembayaran',
                    ),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 15,
                        color: _colorPrimaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 4. TAB METODE PEMBAYARAN ──────────────────────────────────────────────
  Widget _buildPaymentMethodTabs(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMethodTabButton(
              title: 'Virtual Account (VA)',
              icon: Icons.account_balance_rounded,
              isSelected: _selectedMethod == MetodePembayaran.va,
              onTap: () => setState(() => _selectedMethod = MetodePembayaran.va),
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _buildMethodTabButton(
              title: 'QRIS (Instant)',
              icon: Icons.qr_code_2_rounded,
              isSelected: _selectedMethod == MetodePembayaran.qris,
              onTap: () =>
                  setState(() => _selectedMethod = MetodePembayaran.qris),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF242E35) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? _colorPrimaryBlue : _colorLabelGrey,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : _colorTextBlack)
                    : _colorLabelGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 5A. BAGIAN VIRTUAL ACCOUNT ───────────────────────────────────────────
  Color _bankColor(String code) {
    switch (code) {
      case 'BCA':
        return const Color(0xFF003087);
      case 'Mandiri':
        return const Color(0xFF003087);
      case 'BRI':
        return const Color(0xFF00529B);
      case 'BNI':
        return const Color(0xFFF37021);
      case 'BTN':
        return const Color(0xFF1D4ED8);
      case 'Maybank':
        return const Color(0xFFF5A623);
      default:
        return const Color(0xFF64748B);
    }
  }


  Widget _buildVirtualAccountSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : _colorBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Bank Virtual Account',
            style: GoogleFonts.lato(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
            ),
          ),
          const SizedBox(height: 10),
          // Pilihan Bank
          Column(
            children: _bankList.map((bank) {
              final isSelected = _selectedBank == bank['code'];
              return InkWell(
                onTap: () => setState(() => _selectedBank = bank['code']!),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                            ? _bankColor(bank['code']!).withValues(alpha: 0.22)
                            : _bankColor(bank['code']!).withValues(alpha: 0.08))
                        : (isDark ? const Color(0xFF0B1014) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? _bankColor(bank['code']!)
                          : (isDark ? const Color(0xFF2C363D) : _colorBorder),
                      width: isSelected ? 1.4 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _bankColor(bank['code']!)
                                : (isDark ? const Color(0xFF242E35) : Colors.white),
                            borderRadius: BorderRadius.circular(6),
                            border: isSelected
                                ? null
                                : Border.all(
                                    color: bank['code'] == 'Lainnya'
                                        ? const Color(0xFFCBD5E1)
                                        : _bankColor(bank['code']!).withValues(alpha: 0.4),
                                    width: 0.8,
                                  ),
                          ),
                          child: bank['code'] == 'Lainnya'
                              ? Icon(
                                  Icons.account_balance_rounded,
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                )
                              : Text(
                                  bank['code']!,
                                  style: GoogleFonts.lato(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: isSelected
                                        ? Colors.white
                                        : _bankColor(bank['code']!),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          bank['name']!,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isDark
                                ? const Color(0xFFE9EDEF)
                                : _colorTextBlack,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: _bankColor(bank['code']!),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Box Tampilan Nomor VA & Tombol Salin
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B1014) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF2C363D) : const Color(0xFFCBD5E1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nomor Virtual Account ($_selectedBank)',
                  style: GoogleFonts.lato(
                    fontSize: 11.5,
                    color: _colorLabelGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _currentVaNumber,
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: isDark ? Colors.white : _colorTextBlack,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _copyToClipboard(
                        _currentVaNumber,
                        'Nomor Virtual Account',
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: Text(
                        'Salin',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _colorPrimaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
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

  // ─── 5B. BAGIAN QRIS ──────────────────────────────────────────────────────
  Widget _buildQrisSection(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : _colorBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'QRIS',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Pembayaran Cepat & Otomatis',
                style: GoogleFonts.lato(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Simulasi Gambar QR Code QRIS
          Container(
            width: 200,
            height: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/images/bayi_pediagrow_logo.png',
                  width: 140,
                  height: 140,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.qr_code_2_rounded,
                    size: 150,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 32,
                    color: _colorPrimaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Tombol Unduh QR
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'QR Code berhasil diunduh',
                    style: GoogleFonts.lato(fontSize: 13),
                  ),
                  backgroundColor: const Color(0xFF1E293B),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.download_rounded, size: 16),
            label: Text(
              'Unduh QR Code',
              style: GoogleFonts.lato(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _colorPrimaryBlue,
              side: const BorderSide(color: _colorPrimaryBlue, width: 1.2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 10),

          Text(
            'Scan QR menggunakan aplikasi e-Wallet atau m-Banking Anda',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 12,
              color: _colorLabelGrey,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 6. PETUNJUK PEMBAYARAN ACCORDION ─────────────────────────────────────
  Widget _buildPaymentInstructionsAccordion(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : _colorBorder,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          leading: const Icon(
            Icons.info_outline_rounded,
            color: _colorPrimaryBlue,
            size: 20,
          ),
          title: Text(
            'Petunjuk / Cara Pembayaran',
            style: GoogleFonts.lato(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
            ),
          ),
          children: [
            DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    indicatorColor: _colorPrimaryBlue,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: _colorPrimaryBlue,
                    unselectedLabelColor: _colorLabelGrey,
                    labelStyle: GoogleFonts.lato(
                        fontSize: 12, fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: 'm-Banking'),
                      Tab(text: 'ATM'),
                      Tab(text: 'Internet Banking'),
                    ],
                  ),
                  SizedBox(
                    height: 160,
                    child: TabBarView(
                      children: [
                        _buildInstructionSteps([
                          'Buka aplikasi m-Banking ($_selectedBank) di ponsel Anda.',
                          'Pilih menu Transfer > Virtual Account.',
                          'Masukkan nomor Virtual Account: $_currentVaNumber.',
                          'Periksa detail tagihan: ${widget.doctor.consultationFeeFormatted}.',
                          'Masukkan PIN m-Banking Anda untuk menyelesaikan pembayaran.',
                        ], isDark),
                        _buildInstructionSteps([
                          'Masukkan kartu ATM dan PIN $_selectedBank Anda.',
                          'Pilih menu Transaksi Lainnya > Pembayaran > Virtual Account.',
                          'Ketik nomor Virtual Account: $_currentVaNumber.',
                          'Pastikan nama dokter & total tagihan telah sesuai.',
                          'Pilih Ya/Benar untuk menyelesaikan transaksi.',
                        ], isDark),
                        _buildInstructionSteps([
                          'Login ke portal Internet Banking bank Anda.',
                          'Pilih menu Pembayaran Tagihan > Pembayaran Virtual Account.',
                          'Masukkan nomor VA: $_currentVaNumber.',
                          'Verifikasi kode OTP/Token autentikasi Anda.',
                          'Simpan bukti transfer sebagai konfirmasi pembayaran.',
                        ], isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionSteps(List<String> steps, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.lato(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: _colorPrimaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  steps[index],
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: isDark ? const Color(0xFFD1D7DB) : _colorTextBlack,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── BOTTOM ACTION BAR ─────────────────────────────────────────────────────
  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2C363D) : _colorBorder,
            width: 1,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _handlePayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: _colorPrimaryBlue,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Bayar Sekarang',
                        style: GoogleFonts.lato(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
