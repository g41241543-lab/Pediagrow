import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/booking_service.dart';
import '../../../models/booking_consultation_model.dart';
import '../beranda/beranda_page.dart';
import 'formulir_konsultasi_page.dart';

/// Halaman "Status Booking Konsultasi" PediaGrow.
///
/// Menampilkan tiket booking, integrasi Google Kalender, dan status waktu konsultasi.
/// Ketika sudah masuk waktunya, pengguna diarahkan untuk mengisi formulir konsultasi
/// (BB, TB, dan keluhan), lalu lanjut ke chat dokter.
class StatusBookingPage extends StatefulWidget {
  final BookingConsultationModel booking;

  const StatusBookingPage({
    super.key,
    required this.booking,
  });

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
  bool _forceReady = false;
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;

    // Timer cek waktu secara berkala setiap 10 detik
    _tickerTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && !_forceReady) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }

  bool get _isSessionReady {
    return _forceReady || _currentBooking.isTimeReady;
  }

  void _onIsiFormulirPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FormulirKonsultasiPage(
          doctor: _currentBooking.doctor,
          child: _currentBooking.child,
        ),
      ),
    );
  }

  Future<void> _openGoogleCalendar() async {
    if (_currentBooking.googleCalendarUrl != null) {
      final success = await BookingService().launchGoogleCalendar(
        _currentBooking.googleCalendarUrl!,
      );
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tidak dapat membuka Google Kalender di perangkat ini',
              style: GoogleFonts.lato(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReady = _isSessionReady;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomBar(isReady),
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
                    _buildTimeStatusBanner(isReady),
                    const SizedBox(height: 18),

                    // Kartu Tiket Booking Janji Temu
                    _buildTicketCard(),
                    const SizedBox(height: 20),

                    // Kartu Google Kalender
                    _buildGoogleCalendarInfoCard(),
                    const SizedBox(height: 20),

                    // Informasi Alur Konsultasi
                    _buildFlowGuideCard(isReady),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
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
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const BerandaPage()),
                (route) => false,
              );
            },
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.home_outlined,
                color: _kTextDark,
                size: 26.0,
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
                color: _kTextDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Banner Status Waktu ───────────────────────────────────────────────────
  Widget _buildTimeStatusBanner(bool isReady) {
    if (isReady) {
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
                    'Waktu Konsultasi Telah Tiba!',
                    style: GoogleFonts.lato(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF166534),
                    ),
                  ),
                  const SizedBox(height: 3.0),
                  Text(
                    'Silakan isi formulir konsultasi (BB, TB, dan keluhan anak) terlebih dahulu agar dokter dapat mempelajari kondisi pasien sebelum chat dimulai.',
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
            'Sesi konsultasi akan dibuka secara otomatis saat waktu janji temu tiba. Anda akan diarahkan untuk mengisi formulir kondisi anak.',
            style: GoogleFonts.lato(
              fontSize: 12.5,
              height: 1.35,
              color: const Color(0xFF1E40AF),
            ),
          ),
          const SizedBox(height: 10.0),
          // Tombol Simulasi untuk Kemudahan Testing Pengguna
          InkWell(
            onTap: () {
              setState(() => _forceReady = true);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: _kPrimaryBlue),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flash_on_rounded, size: 15, color: _kPrimaryBlue),
                  const SizedBox(width: 4),
                  Text(
                    'Masuk Waktu Konsultasi Sekarang (Mulai)',
                    style: GoogleFonts.lato(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: _kPrimaryBlue,
                    ),
                  ),
                ],
              ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.5),
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
                        child: doc.avatarUrl != null && doc.avatarUrl!.isNotEmpty
                            ? (doc.avatarUrl!.startsWith('http')
                                ? Image.network(
                                    doc.avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        const Icon(Icons.person, color: _kTextMuted),
                                  )
                                : Image.file(
                                    File(doc.avatarUrl!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        const Icon(Icons.person, color: _kTextMuted),
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
                            style: GoogleFonts.lato(fontSize: 11.5, color: _kTextMuted),
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
                            style: GoogleFonts.lato(fontSize: 11.5, color: _kTextMuted),
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
                  'Pengingat jadwal telah disiapkan untuk agenda konsultasi ini.',
                  style: GoogleFonts.lato(
                    fontSize: 11.5,
                    color: _kTextMuted,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: _openGoogleCalendar,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimaryBlue,
              side: const BorderSide(color: _kPrimaryBlue),
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: Text(
              'Buka',
              style: GoogleFonts.lato(
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Informasi Alur Konsultasi ─────────────────────────────────────────────
  Widget _buildFlowGuideCard(bool isReady) {
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
            subtitle: 'Jadwal janji temu berhasil dipesan.',
            isDone: true,
          ),
          _buildFlowStep(
            number: '2',
            title: 'Masuk Waktu Konsultasi & Isi Formulir',
            subtitle: 'Lengkapi berat badan, tinggi badan, dan keluhan anak.',
            isDone: isReady,
            isActive: isReady,
          ),
          _buildFlowStep(
            number: '3',
            title: 'Mulai Chat dengan Dokter',
            subtitle: 'Konsultasi interaktif langsung bersama dokter spesialis.',
            isDone: false,
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
    );
  }

  // ── Bottom Action Bar ─────────────────────────────────────────────────────
  Widget _buildBottomBar(bool isReady) {
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
            onPressed: isReady ? _onIsiFormulirPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isReady ? _kOrangePrimary : const Color(0xFFCBD5E1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isReady ? Icons.edit_document : Icons.lock_clock,
                  size: 18.0,
                ),
                const SizedBox(width: 8.0),
                Text(
                  isReady
                      ? 'Isi Formulir Konsultasi Sekarang'
                      : 'Menunggu Waktu Konsultasi Tiba',
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
