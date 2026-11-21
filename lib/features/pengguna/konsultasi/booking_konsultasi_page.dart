import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/booking_service.dart';
import '../../../core/services/child_service.dart';
import '../../../core/services/jadwal_dokter_service.dart';
import '../../../shared/widgets/pedia_banner.dart';
import '../../../models/child_model.dart';
import '../../../models/doctor_model.dart';
import '../../../shared/widgets/child_avatar.dart';
import '../../../shared/widgets/doctor_live_avatar.dart';
import '../profil_anak/tambah_anak_page.dart';
import 'pembayaran_konsultasi_page.dart';

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
    final rawSlots = BookingService().getAvailableSlotsForDoctor(
      doctor: widget.doctor,
      date: _selectedDate,
    );

    // Deduplikasi slot dan urutkan terawal hingga terakhir
    final Map<String, DoctorTimeSlot> uniqueSlots = {};
    for (final slot in rawSlots) {
      if (!uniqueSlots.containsKey(slot.time)) {
        uniqueSlots[slot.time] = slot;
      } else if (!slot.isAvailable && uniqueSlots[slot.time]!.isAvailable) {
        uniqueSlots[slot.time] = slot;
      }
    }

    _availableSlots = uniqueSlots.values.toList()
      ..sort((a, b) {
        final aMinutes = (a.startHour * 60) + a.startMinute;
        final bMinutes = (b.startHour * 60) + b.startMinute;
        return aMinutes.compareTo(bMinutes);
      });

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

  void _onConfirmBooking() {
    if (_selectedChild == null) {
      _showSnackbar('Silakan pilih profil anak terlebih dahulu');
      return;
    }

    if (_selectedSlot == null) {
      _showSnackbar('Silakan pilih jam / slot waktu konsultasi yang tersedia');
      return;
    }

    final chosenChild = _selectedChild!;
    final chosenSlot = _selectedSlot!;
    final chosenDate = _selectedDate;

    final startDt = DateTime(
      chosenDate.year,
      chosenDate.month,
      chosenDate.day,
      chosenSlot.startHour,
      chosenSlot.startMinute,
    );
    final endDt = startDt.add(const Duration(minutes: 30));

    // Alur baru: Navigasi ke Halaman Pembayaran Konsultasi terlebih dahulu
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PembayaranKonsultasiPage(
          doctor: widget.doctor,
          child: chosenChild,
          selectedDate: chosenDate,
          selectedTimeSlot: chosenSlot.time,
          startDateTime: startDt,
          endDateTime: endDt,
        ),
      ),
    );
  }



  void _showSnackbar(String msg) {
    PediaBanner.showError(context, message: msg);
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
                physics: const ClampingScrollPhysics(),
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

  // â”€â”€ Header (56dp) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
              'Booking Konsultasi',
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

  // â”€â”€ Kartu Ringkasan Dokter â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
          DoctorLiveAvatar(
            doctorId: widget.doctor.id,
            doctorName: widget.doctor.name,
            fallbackPhoto:
                widget.doctor.avatarUrl ?? widget.doctor.assetImagePath,
            size: 54.0,
            borderRadius: BorderRadius.circular(12.0),
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

  // â”€â”€ Step 1: Pilih Anak â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildChildSelectionSection(bool isDark) {
    final children = ChildService().children;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1. Pilih Anak',
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
            physics: const ClampingScrollPhysics(),
            child: Row(
              children: children.map((c) {
                final isSelected = _selectedChild?.id == c.id;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedChild = c;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12.0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 10.0,
                    ),
                    width: 185.0,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                                ? const Color(0xFF1E3A8A)
                                      .withValues(alpha: 0.35)
                                : const Color(0xFFEFF6FF))
                          : (isDark ? const Color(0xFF1A2228) : Colors.white),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: isSelected
                            ? _kPrimaryBlue
                            : (isDark
                                  ? const Color(0xFF2C363D)
                                  : _kBorderLight),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        ChildAvatar(
                          child: c,
                          size: 38.0,
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.lato(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? const Color(0xFFE9EDEF)
                                      : _kTextDark,
                                ),
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                c.ageDescription.isNotEmpty
                                    ? c.ageDescription
                                    : (c.gender),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.lato(
                                  fontSize: 11.0,
                                  color: isDark
                                      ? const Color(0xFF8696A0)
                                      : _kTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 6.0),
                          const Icon(
                            Icons.check_circle,
                            color: _kPrimaryBlue,
                            size: 18.0,
                          ),
                        ],
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

  // â”€â”€ Step 2: Pilih Tanggal â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
          physics: const ClampingScrollPhysics(),
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
                        : (isDark
                              ? const Color(0xFF451A03)
                              : const Color(0xFFFEF3C7)),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    'Cuti',
                    style: GoogleFonts.lato(
                      fontSize: 9.0,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFD97706)),
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
                        : (isDark
                              ? const Color(0xFF2C363D)
                              : const Color(0xFFE9EDEF)),
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
                final slotsKosong = JadwalDokterService().hitungSlotKosong(
                  dokterId: widget.doctor.id,
                  tanggal: d,
                );
                final isPenuh = slotsKosong.isEmpty;

                statusBadge = Container(
                  margin: const EdgeInsets.only(top: 4.0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5.0,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.22)
                        : isPenuh
                        ? (isDark
                              ? const Color(0xFF2C363D)
                              : const Color(0xFFF1F5F9))
                        : (isDark
                              ? const Color(0xFF064E3B)
                              : const Color(0xFFD1FAE5)),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    isPenuh ? 'Penuh' : 'Praktik',
                    style: GoogleFonts.lato(
                      fontSize: 9.0,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : isPenuh
                          ? (isDark
                                ? const Color(0xFF8696A0)
                                : const Color(0xFF64748B))
                          : (isDark
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFF059669)),
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
                        : (isDark
                              ? const Color(0xFF1A2228)
                              : const Color(0xFFF8FAFC)),
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
                              : (isDark
                                    ? const Color(0xFF8696A0)
                                    : _kTextMuted),
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
                              : (isDark
                                    ? const Color(0xFF8696A0)
                                    : _kTextMuted),
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

  // â”€â”€ Step 3: Pilih Jam / Slot Waktu Praktik â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildTimeSlotSection(bool isDark) {
    final periods = ['Semua', 'Pagi', 'Siang', 'Sore', 'Malam'];

    final baseSlots = _selectedPeriodFilter == 'Semua'
        ? _availableSlots
        : _availableSlots
              .where((s) => s.period == _selectedPeriodFilter)
              .toList();

    // Deduplikasi slot dan urutkan terawal hingga terakhir
    final Map<String, DoctorTimeSlot> uniqueFiltered = {};
    for (final s in baseSlots) {
      if (!uniqueFiltered.containsKey(s.time)) {
        uniqueFiltered[s.time] = s;
      } else if (!s.isAvailable && uniqueFiltered[s.time]!.isAvailable) {
        uniqueFiltered[s.time] = s;
      }
    }
    final filteredSlots = uniqueFiltered.values.toList()
      ..sort((a, b) {
        final aMinutes = (a.startHour * 60) + a.startMinute;
        final bMinutes = (b.startHour * 60) + b.startMinute;
        return aMinutes.compareTo(bMinutes);
      });

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
          physics: const ClampingScrollPhysics(),
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
                  backgroundColor: isDark
                      ? const Color(0xFF1A2228)
                      : const Color(0xFFE9EDEF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  side: isDark
                      ? BorderSide(
                          color: isFilterSelected
                              ? _kPrimaryBlue
                              : const Color(0xFF2C363D),
                        )
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
                    color: isDark
                        ? const Color(0xFF92400E)
                        : const Color(0xFFFCD34D),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_busy_rounded,
                      color: isDark
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFFD97706),
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
                              color: isDark
                                  ? const Color(0xFFFDE68A)
                                  : const Color(0xFF92400E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.doctor.name} sedang cuti: ${cuti.alasan} (${cuti.rentangTanggalStr}). Silakan pilih tanggal lain yang tersedia.',
                            style: GoogleFonts.lato(
                              fontSize: 11.5,
                              color: isDark
                                  ? const Color(0xFFFCD34D)
                                  : const Color(0xFFB45309),
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
                  color: isDark
                      ? const Color(0xFF1A2228)
                      : const Color(0xFFF8FAFC),
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
                              color: isDark
                                  ? const Color(0xFFE9EDEF)
                                  : _kTextDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Dokter tidak memiliki jadwal praktik reguler pada hari $dayName. Silakan lihat jadwal praktik dokter pada profil atau pilih tanggal lain.',
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
                color: isDark
                    ? const Color(0xFF1A2228)
                    : const Color(0xFFF8FAFC),
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
                            color: isDark
                                ? const Color(0xFFE9EDEF)
                                : _kTextDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Semua slot jadwal konsultasi dokter pada tanggal ini telah terisi atau jam praktik telah selesai. Silakan pilih tanggal berikutnya.',
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
            );
          }(),
        ] else
          LayoutBuilder(
            builder: (context, constraints) {
              // Menyesuaikan ukuran layar HP Android 12, 13, 15, 16 hingga tablet
              // Pada smartphone, selalu 2 kolom yang memenuhi penuh lebar layar tanpa space kosong di kanan
              final bool isTablet = constraints.maxWidth >= 600;
              final int crossAxisCount = isTablet ? 3 : 2;
              const double spacing = 8.0;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredSlots.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  mainAxisExtent: 40.0, // Ukuran compact dan proporsional
                ),
                itemBuilder: (context, index) {
                  final slot = filteredSlots[index];
                  final isSelected = _selectedSlot?.time == slot.time;
                  final isAvail = slot.isAvailable;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isAvail ? () => _onSlotSelected(slot) : null,
                      borderRadius: BorderRadius.circular(10.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _kPrimaryBlue
                              : (isAvail
                                    ? (isDark
                                          ? const Color(0xFF1A2228)
                                          : Colors.white)
                                    : (isDark
                                          ? const Color(0xFF12181C)
                                          : const Color(0xFFF1F5F9))),
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                            color: isSelected
                                ? _kPrimaryBlue
                                : (isAvail
                                      ? (isDark
                                            ? const Color(0xFF2C363D)
                                            : const Color(0xFFD1D7DB))
                                      : (isDark
                                            ? const Color(0xFF232D34)
                                            : const Color(0xFFE2E8F0))),
                            width: isSelected ? 1.6 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14.0,
                              color: isSelected
                                  ? Colors.white
                                  : (isAvail
                                        ? _kPrimaryBlue
                                        : (isDark
                                              ? const Color(0xFF667781)
                                              : const Color(0xFF94A3B8))),
                            ),
                            const SizedBox(width: 5.0),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  slot.time,
                                  maxLines: 1,
                                  style: GoogleFonts.lato(
                                    fontSize: 12.0,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : (isAvail
                                              ? (isDark
                                                    ? const Color(0xFFE9EDEF)
                                                    : _kTextDark)
                                              : (isDark
                                                    ? const Color(0xFF667781)
                                                    : const Color(0xFF94A3B8))),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  // â”€â”€ Bottom Confirm Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                'Lanjut ke Pembayaran',
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
