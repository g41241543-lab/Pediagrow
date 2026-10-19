import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/booking_service.dart';
import '../../../core/services/child_service.dart';
import '../../../core/services/jadwal_dokter_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../models/booking_consultation_model.dart';
import '../../../models/child_model.dart';
import '../../../models/doctor_model.dart';
import '../profil_anak/tambah_anak_page.dart';
import 'status_booking_page.dart';


/// Halaman "Booking Konsultasi Dokter" PediaGrow.
///
/// Alur:
/// 1. Ringkasan Dokter
/// 2. Pilih Anak (dari ChildService / Tambah Anak baru)
/// 3. Pilih Tanggal (Date picker horizontal 14 hari)
/// 4. Pilih Jam (Slot waktu praktik pagi, siang, sore/malam realtime)
/// 5. Konfirmasi Booking -> [StatusBookingPage] (otomatis tersambung ke Google Kalender)
class BookingKonsultasiPage extends StatefulWidget {
  final DoctorModel doctor;
  final ChildModel? initialChild;

  const BookingKonsultasiPage({
    super.key,
    required this.doctor,
    this.initialChild,
  });

  @override
  State<BookingKonsultasiPage> createState() => _BookingKonsultasiPageState();
}

class _BookingKonsultasiPageState extends State<BookingKonsultasiPage> {
  static const Color _kPrimaryBlue = Color(0xFF2B7AE8);
  static const Color _kTealAccent = Color(0xFF3CC3A6);
  static const Color _kTextDark = Color(0xFF1A2228);
  static const Color _kTextMuted = Color(0xFF667781);
  static const Color _kBorderLight = Color(0xFFE9EDEF);

  late ChildModel? _selectedChild;
  late DateTime _selectedDate;
  DoctorTimeSlot? _selectedSlot;

  late List<DateTime> _upcomingDates;
  late List<DoctorTimeSlot> _availableSlots;
  String _selectedPeriodFilter = 'Semua';

  @override
  void initState() {
    super.initState();

    // Resolusi anak awal
    _selectedChild = widget.initialChild ?? ChildService().activeChild;
    if (_selectedChild == null && ChildService().children.isNotEmpty) {
      _selectedChild = ChildService().children.first;
    }

    // Tanggal awal hari ini
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);

    // Buat daftar 14 hari ke depan
    _upcomingDates = List.generate(14, (i) {
      return DateTime(now.year, now.month, now.day).add(Duration(days: i));
    });

    _refreshSlots();

    ChildService().childrenNotifier.addListener(_onChildrenUpdated);
    JadwalDokterService().jadwalListNotifier.addListener(
      _onScheduleOrBookingChanged,
    );
    JadwalDokterService().cutiListNotifier.addListener(
      _onScheduleOrBookingChanged,
    );
    BookingService().bookingsNotifier.addListener(_onScheduleOrBookingChanged);
  }

  @override
  void dispose() {
    ChildService().childrenNotifier.removeListener(_onChildrenUpdated);
    JadwalDokterService().jadwalListNotifier.removeListener(
      _onScheduleOrBookingChanged,
    );
    JadwalDokterService().cutiListNotifier.removeListener(
      _onScheduleOrBookingChanged,
    );
    BookingService().bookingsNotifier.removeListener(
      _onScheduleOrBookingChanged,
    );
    super.dispose();
  }

  void _onScheduleOrBookingChanged() {
    if (mounted) {
      setState(() {
        _refreshSlots();
      });
    }
  }

  void _onChildrenUpdated() {
    if (mounted) {
      setState(() {
        if (_selectedChild == null && ChildService().children.isNotEmpty) {
          _selectedChild = ChildService().children.first;
        }
      });
    }
  }

  void _refreshSlots() {
    _availableSlots = BookingService().getAvailableSlotsForDoctor(
      doctor: widget.doctor,
      date: _selectedDate,
    );

    // Jika slot terpilih sebelumnya tidak tersedia di tanggal baru, reset
    if (_selectedSlot != null) {
      final exists = _availableSlots.any(
        (s) => s.time == _selectedSlot!.time && s.isAvailable,
      );
      if (!exists) {
        _selectedSlot = null;
      }
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _refreshSlots();
    });
  }

  void _onSlotSelected(DoctorTimeSlot slot) {
    if (!slot.isAvailable) return;
    setState(() {
      _selectedSlot = slot;
    });
  }

  Future<void> _onConfirmBooking() async {
    if (_selectedChild == null) {
      _showSnackbar('Silakan pilih profil anak terlebih dahulu');
      return;
    }

    if (_selectedSlot == null) {
      _showSnackbar('Silakan pilih jam / slot waktu konsultasi yang tersedia');
      return;
    }

    // Tampilkan loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2B7AE8)),
        ),
      );
    }

    // 1. Simpan booking ke BookingService (URL Google Kalender di-generate otomatis & tersimpan ke Firestore)
    BookingConsultationModel booking;
    try {
      booking = await BookingService().createBooking(
        doctor: widget.doctor,
        child: _selectedChild!,
        date: _selectedDate,
        slot: _selectedSlot!,
      );
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop(); // tutup loading
      if (mounted) {
        _showSnackbar('Gagal membuat booking: $e');
      }
      return;
    }

    if (mounted) Navigator.of(context, rootNavigator: true).pop(); // tutup loading

    // 2. Sistem otomatis menyambungkan pengingat Google Kalender & notifikasi jadwal tiba
    NotificationService().addBookingReminderNotification(
      doctorName: widget.doctor.name,
      childName: _selectedChild!.name,
      dateFormatted:
          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
      timeSlot: _selectedSlot!.time,
      scheduledTime: booking.scheduledStartDateTime,
    );

    if (!mounted) return;

    // 3. Langsung menuju halaman Status Booking tanpa beralih membuka Google Kalender
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) =>
            StatusBookingPage(booking: booking),
        transitionsBuilder: (context, anim, secAnim, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.lato(color: Colors.white)),
        backgroundColor: const Color(0xFF1A2228),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1014) : Colors.white,
      bottomNavigationBar: _buildBottomConfirmBar(isDark),
      body: SafeArea(
        child: Column(
          children: [
            // Header (56dp)
            _buildHeader(isDark),

            // Konten Form Booking Scrollable
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Ringkasan Kartu Dokter
                    _buildDoctorSummaryCard(isDark),
                    const SizedBox(height: 20),

                    // Step 1: Pilih Anak
                    _buildChildSelectionSection(isDark),
                    const SizedBox(height: 24),

                    // Step 2: Pilih Tanggal
                    _buildDateSelectionSection(isDark),
                    const SizedBox(height: 24),

                    // Step 3: Pilih Jam / Slot Waktu Praktik
                    _buildTimeSlotSection(isDark),
                    const SizedBox(height: 28),
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
  Widget _buildHeader(bool isDark) {
    return Container(
      height: 56.0,
      width: double.infinity,
      color: isDark ? const Color(0xFF0B1014) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
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
              'Jadwal Konsultasi Dokter',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 19.0,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE9EDEF) : _kTextDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Kartu Ringkasan Dokter ────────────────────────────────────────────────
  Widget _buildDoctorSummaryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : _kBorderLight,
        ),
      ),
      child: Row(
        children: [
          // Avatar Dokter
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              width: 54.0,
              height: 54.0,
              color: isDark ? const Color(0xFF0B1014) : const Color(0xFFE9EDEF),
              child:
                  widget.doctor.avatarUrl != null &&
                      widget.doctor.avatarUrl!.isNotEmpty
                  ? (widget.doctor.avatarUrl!.startsWith('http')
                        ? Image.network(
                            widget.doctor.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.person, color: _kTextMuted),
                          )
                        : Image.file(
                            File(widget.doctor.avatarUrl!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.person, color: _kTextMuted),
                          ))
                  : (widget.doctor.assetImagePath != null
                        ? Image.asset(
                            widget.doctor.assetImagePath!,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.person, color: _kTextMuted)),
            ),
          ),
          const SizedBox(width: 12.0),

          // Detail Dokter
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctor.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFE9EDEF) : _kTextDark,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  widget.doctor.specialization,
                  style: GoogleFonts.lato(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFF60A5FA) : _kPrimaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  widget.doctor.daftarTempatPraktik.isNotEmpty
                      ? widget.doctor.daftarTempatPraktik.first
                      : 'Praktik Konsultasi Online',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

  // ── Step 1: Pilih Anak ────────────────────────────────────────────────────
  Widget _buildChildSelectionSection(bool isDark) {
    final children = ChildService().children;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1. Pilih Pasien Anak',
              style: GoogleFonts.lato(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE9EDEF) : _kTextDark,
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TambahAnakPage()),
                );
              },
              child: Row(
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    size: 16.0,
                    color: _kPrimaryBlue,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    'Tambah Anak',
                    style: GoogleFonts.lato(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF60A5FA) : _kPrimaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10.0),

        if (children.isEmpty)
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2228) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: isDark ? const Color(0xFF2C363D) : _kBorderLight,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: _kPrimaryBlue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Belum ada profil anak terdaftar. Klik "Tambah Anak" untuk mendaftarkan anak Anda.',
                    style: GoogleFonts.lato(
                      fontSize: 12.5,
                      color: isDark ? const Color(0xFF8696A0) : _kTextMuted,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: children.map((c) {
                final isSelected = _selectedChild?.id == c.id;
                final isBoy = (c.gender.toLowerCase().contains('laki'));

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedChild = c;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12.0),
                    padding: const EdgeInsets.all(12.0),
                    width: 175.0,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                                ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
                                : const Color(0xFFEFF6FF))
                          : (isDark
                                ? const Color(0xFF1A2228)
                                : Colors.white),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: isSelected
                            ? _kPrimaryBlue
                            : (isDark ? const Color(0xFF2C363D) : _kBorderLight),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18.0,
                          backgroundColor: isBoy
                              ? (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFD6E8FE))
                              : (isDark ? const Color(0xFF831843) : const Color(0xFFFFDFD9)),
                          child: Icon(
                            Icons.child_care_rounded,
                            size: 20.0,
                            color: isBoy
                                ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF2B7AE8))
                                : (isDark ? const Color(0xFFF472B6) : const Color(0xFFF87171)),
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.lato(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFFE9EDEF) : _kTextDark,
                                ),
                              ),
                              Text(
                                c.ageDescription.isNotEmpty
                                    ? c.ageDescription
                                    : (c.gender),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.lato(
                                  fontSize: 11.0,
                                  color: isDark ? const Color(0xFF8696A0) : _kTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: _kPrimaryBlue,
                            size: 18.0,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ── Step 2: Pilih Tanggal ─────────────────────────────────────────────────
  Widget _buildDateSelectionSection(bool isDark) {
    const daysAbbr = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const monthsAbbr = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '2. Pilih Tanggal Konsultasi',
          style: GoogleFonts.lato(
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFE9EDEF) : _kTextDark,
          ),
        ),
        const SizedBox(height: 12.0),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _upcomingDates.map((d) {
              final isSelected =
                  _selectedDate.year == d.year &&
                  _selectedDate.month == d.month &&
                  _selectedDate.day == d.day;
              final dayName = daysAbbr[d.weekday - 1];
              final monthName = monthsAbbr[d.month - 1];

              final cuti = JadwalDokterService().getCutiPadaTanggal(
                widget.doctor.id,
                d,
              );
              final isPraktik = JadwalDokterService().isDokterPraktikPadaHari(
                widget.doctor.id,
                d.weekday,
              );

              Widget statusBadge;
              if (cuti != null) {
                statusBadge = Container(
                  margin: const EdgeInsets.only(top: 4.0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5.0,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.22)
                        : (isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7)),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    'Cuti',
                    style: GoogleFonts.lato(
                      fontSize: 9.0,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)),
                    ),
                  ),
                );
              } else if (!isPraktik) {
                statusBadge = Container(
                  margin: const EdgeInsets.only(top: 4.0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5.0,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.22)
                        : (isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF)),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    'Libur',
                    style: GoogleFonts.lato(
                      fontSize: 9.0,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white70
                          : (isDark ? const Color(0xFF8696A0) : _kTextMuted),
                    ),
                  ),
                );
              } else {
                statusBadge = Container(
                  margin: const EdgeInsets.only(top: 4.0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5.0,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.22)
                        : (isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5)),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    'Praktik',
                    style: GoogleFonts.lato(
                      fontSize: 9.0,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? const Color(0xFF4ADE80) : const Color(0xFF059669)),
                    ),
                  ),
                );
              }

              return GestureDetector(
                onTap: () => _onDateSelected(d),
                child: Container(
                  margin: const EdgeInsets.only(right: 10.0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 12.0,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _kPrimaryBlue
                        : (isDark ? const Color(0xFF1A2228) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: isSelected
                          ? _kPrimaryBlue
                          : (isDark ? const Color(0xFF2C363D) : _kBorderLight),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        dayName,
                        style: GoogleFonts.lato(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white70
                              : (isDark ? const Color(0xFF8696A0) : _kTextMuted),
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '${d.day}',
                        style: GoogleFonts.lato(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? const Color(0xFFE9EDEF) : _kTextDark),
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        monthName,
                        style: GoogleFonts.lato(
                          fontSize: 11.0,
                          color: isSelected
                              ? Colors.white70
                              : (isDark ? const Color(0xFF8696A0) : _kTextMuted),
                        ),
                      ),
                      statusBadge,
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Step 3: Pilih Jam / Slot Waktu Praktik ─────────────────────────────────
  Widget _buildTimeSlotSection(bool isDark) {
    final periods = ['Semua', 'Pagi', 'Siang', 'Sore', 'Malam'];

    final filteredSlots = _selectedPeriodFilter == 'Semua'
        ? _availableSlots
        : _availableSlots
              .where((s) => s.period == _selectedPeriodFilter)
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '3. Pilih Waktu Tersedia Dokter',
              style: GoogleFonts.lato(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE9EDEF) : _kTextDark,
              ),
            ),
            Text(
              'Real-Time',
              style: GoogleFonts.lato(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: _kTealAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10.0),

        // Filter Periode (Pagi, Siang, Sore, Malam)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: periods.map((p) {
              final isFilterSelected = _selectedPeriodFilter == p;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(p),
                  selected: isFilterSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedPeriodFilter = p);
                  },
                  labelStyle: GoogleFonts.lato(
                    fontSize: 12.0,
                    fontWeight: isFilterSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isFilterSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFF8696A0) : _kTextMuted),
                  ),
                  selectedColor: _kPrimaryBlue,
                  backgroundColor: isDark ? const Color(0xFF1A2228) : const Color(0xFFE9EDEF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  side: isDark
                      ? BorderSide(color: isFilterSelected ? _kPrimaryBlue : const Color(0xFF2C363D))
                      : BorderSide.none,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12.0),

        // Grid Slot Waktu
        if (filteredSlots.isEmpty) ...[
          () {
            final cuti = JadwalDokterService().getCutiPadaTanggal(
              widget.doctor.id,
              _selectedDate,
            );
            final isPraktik = JadwalDokterService().isDokterPraktikPadaHari(
              widget.doctor.id,
              _selectedDate.weekday,
            );

            if (cuti != null) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF451A03).withValues(alpha: 0.4)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: isDark ? const Color(0xFF92400E) : const Color(0xFFFCD34D),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_busy_rounded,
                      color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dokter Sedang Cuti / Berhalangan',
                            style: GoogleFonts.lato(
                              fontSize: 13.0,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.doctor.name} sedang cuti: ${cuti.alasan} (${cuti.rentangTanggalStr}). Silakan pilih tanggal lain yang tersedia.',
                            style: GoogleFonts.lato(
                              fontSize: 11.5,
                              color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            if (!isPraktik) {
              const dayNames = [
                'Senin',
                'Selasa',
                'Rabu',
                'Kamis',
                'Jumat',
                'Sabtu',
                'Minggu',
              ];
              final dayName = dayNames[_selectedDate.weekday - 1];
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2228) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2C363D) : _kBorderLight,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.hotel_rounded,
                      color: isDark ? const Color(0xFF8696A0) : _kTextMuted,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tidak Ada Jadwal Praktik',
                            style: GoogleFonts.lato(
                              fontSize: 13.0,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFE9EDEF) : _kTextDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Dokter tidak memiliki jadwal praktik reguler pada hari $dayName. Silakan lihat jadwal praktik dokter pada profil atau pilih tanggal lain.',
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

            if (_availableSlots.isNotEmpty &&
                _selectedPeriodFilter != 'Semua') {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                alignment: Alignment.center,
                child: Text(
                  'Tidak ada slot waktu pada kategori "$_selectedPeriodFilter". Coba pilih kategori lain atau "Semua".',
                  style: GoogleFonts.lato(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFF8696A0) : _kTextMuted,
                  ),
                ),
              );
            }

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2228) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: isDark ? const Color(0xFF2C363D) : _kBorderLight,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: isDark ? const Color(0xFF8696A0) : _kTextMuted,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Slot Konsultasi Penuh / Telah Lewat',
                          style: GoogleFonts.lato(
                            fontSize: 13.0,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFE9EDEF) : _kTextDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Semua slot jadwal konsultasi dokter pada tanggal ini telah terisi atau jam praktik telah selesai. Silakan pilih tanggal berikutnya.',
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
          }(),
        ] else
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: filteredSlots.map((slot) {
              final isSelected = _selectedSlot?.time == slot.time;
              final isAvail = slot.isAvailable;

              return GestureDetector(
                onTap: isAvail ? () => _onSlotSelected(slot) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 10.0,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _kPrimaryBlue
                        : (isAvail
                              ? (isDark ? const Color(0xFF1A2228) : Colors.white)
                              : (isDark ? const Color(0xFF0B1014) : const Color(0xFFE9EDEF))),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: isSelected
                          ? _kPrimaryBlue
                          : (isAvail
                                ? (isDark ? const Color(0xFF2C363D) : const Color(0xFFD1D7DB))
                                : (isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF))),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 15.0,
                        color: isSelected
                            ? Colors.white
                            : (isAvail
                                  ? _kPrimaryBlue
                                  : (isDark ? const Color(0xFF667781) : const Color(0xFF8696A0))),
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        slot.time,
                        style: GoogleFonts.lato(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isAvail
                                    ? (isDark ? const Color(0xFFE9EDEF) : _kTextDark)
                                    : (isDark ? const Color(0xFF667781) : const Color(0xFF8696A0))),
                        ),
                      ),
                      if (!isAvail) ...[
                        const SizedBox(width: 4.0),
                        Text(
                          '(Penuh)',
                          style: GoogleFonts.lato(
                            fontSize: 10.0,
                            color: isDark ? const Color(0xFF667781) : const Color(0xFF8696A0),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // ── Bottom Confirm Bar ───────────────────────────────────────────────────
  Widget _buildBottomConfirmBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 8.0,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jadwal Terpilih',
                    style: GoogleFonts.lato(
                      fontSize: 11.0,
                      color: isDark ? const Color(0xFF8696A0) : _kTextMuted,
                    ),
                  ),
                  Text(
                    _selectedSlot != null
                        ? '${_selectedDate.day}/${_selectedDate.month} • ${_selectedSlot!.time}'
                        : 'Belum memilih jam',
                    style: GoogleFonts.lato(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFE9EDEF) : _kTextDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12.0),
            ElevatedButton(
              onPressed: _onConfirmBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22.0,
                  vertical: 13.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 0,
              ),
              child: Text(
                'Booking Jadwal',
                style: GoogleFonts.lato(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
