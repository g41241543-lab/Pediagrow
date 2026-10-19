import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/booking_service.dart';
import '../../../core/services/child_service.dart';
import '../../../core/services/doctor_service.dart';
import '../../../core/services/google_calendar_service.dart';
import '../../../core/services/jadwal_dokter_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../models/booking_consultation_model.dart';
import '../../../models/child_model.dart';
import '../../../models/doctor_model.dart';
import 'daftar_dokter_page.dart';
import 'pilih_anak_page.dart';
import '../../../shared/widgets/child_avatar.dart';

/// Halaman formulir booking dokter anak oleh pengguna.
///
/// Pengguna memilih tanggal dan sesi jam booking konsultasi dokter.
/// Setelah konfirmasi, jadwal booking disimpan dan diarahkan ke tab Jadwal Konsultasi.
class BookingDokterPage extends StatefulWidget {
  final DoctorModel? doctor;
  final ChildModel? child;

  const BookingDokterPage({super.key, this.doctor, this.child});

  @override
  State<BookingDokterPage> createState() => _BookingDokterPageState();
}

class _BookingDokterPageState extends State<BookingDokterPage> {
  // Palet Warna Resmi PediaGrow
  static const Color _colorPrimaryBlue = Color(0xFF3985E7);
  static const Color _colorTextBlack = Color(0xFF1A2228);
  static const Color _colorLabelGrey = Color(0xFF667781);
  static const Color _colorBorder = Color(0xFFE9EDEF);

  late DoctorModel _doctor;
  late ChildModel _child;

  late DateTime _selectedDate;
  String? _selectedTimeSlot;
  List<SlotWaktuDokter> _availableSlots = [];

  late List<DateTime> _availableDates;

  @override
  void initState() {
    super.initState();

    final availableDoctors = DoctorService().doctorsNotifier.value;
    // Resolusi dokter (fallback ke dokter pertama dari DoctorService jika null)
    _doctor =
        widget.doctor ??
        (availableDoctors.isNotEmpty
            ? availableDoctors.first
            : DoctorModel.defaultDoctor);

    // Resolusi anak (fallback ke active child atau anak pertama dari ChildService)
    _child =
        widget.child ??
        (ChildService().activeChild ??
            ChildModel(
              id: 'child_default',
              name: 'Anak PediaGrow',
              gender: 'Laki-laki',
              birthDate: DateTime.now().subtract(const Duration(days: 365)),
            ));

    // Siapkan daftar tanggal 7 hari ke depan (mulai besok)
    final now = DateTime.now();
    _availableDates = List.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day + 1 + i),
    );
    _selectedDate = _availableDates.first;
    _refreshSlots();

    DoctorService().doctorsNotifier.addListener(_onDataUpdated);
    JadwalDokterService().jadwalListNotifier.addListener(_onDataUpdated);
    JadwalDokterService().cutiListNotifier.addListener(_onDataUpdated);
    BookingService().bookingsNotifier.addListener(_onDataUpdated);
  }

  @override
  void dispose() {
    DoctorService().doctorsNotifier.removeListener(_onDataUpdated);
    JadwalDokterService().jadwalListNotifier.removeListener(_onDataUpdated);
    JadwalDokterService().cutiListNotifier.removeListener(_onDataUpdated);
    BookingService().bookingsNotifier.removeListener(_onDataUpdated);
    super.dispose();
  }

  void _onDataUpdated() {
    if (mounted) {
      setState(() {
        _refreshSlots();
      });
    }
  }

  void _refreshSlots() {
    final slots = JadwalDokterService().hitungSlotKosong(
      dokterId: _doctor.id,
      tanggal: _selectedDate,
    );
    _availableSlots = slots;

    // Sinkronkan slot terpilih
    if (_selectedTimeSlot != null) {
      final exists = slots.any((s) => s.timeLabel == _selectedTimeSlot && s.isAvailable);
      if (!exists) {
        final firstAvail = slots.where((s) => s.isAvailable).firstOrNull;
        _selectedTimeSlot = firstAvail?.timeLabel;
      }
    } else {
      final firstAvail = slots.where((s) => s.isAvailable).firstOrNull;
      _selectedTimeSlot = firstAvail?.timeLabel;
    }
  }

  void _changeChild() {
    PilihAnakPage.show(
      context,
      onChildSelected: (newChild) {
        setState(() {
          _child = newChild;
        });
      },
    );
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _colorPrimaryBlue,
              onPrimary: Colors.white,
              onSurface: _colorTextBlack,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        if (!_availableDates.any((d) => _isSameDay(d, picked))) {
          _availableDates.insert(0, picked);
        }
        _refreshSlots();
      });
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSubmitting = false;

  Future<void> _confirmBooking() async {
    if (_isSubmitting) return;

    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan pilih tanggal dan sesi waktu yang tersedia terlebih dahulu',
          ),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final selectedSlotObj = _availableSlots
        .where((s) => s.timeLabel == _selectedTimeSlot)
        .firstOrNull;
    final startDt = selectedSlotObj?.startDateTime ??
        DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          9,
          0,
        );
    final endDt = selectedSlotObj?.endDateTime ??
        startDt.add(const Duration(minutes: 30));

    final calUrl = BookingService().generateGoogleCalendarUrl(
      doctor: _doctor,
      child: _child,
      startTime: startDt,
      endTime: endDt,
    );

    final newBooking = BookingConsultationModel(
      id: 'booking-${DateTime.now().millisecondsSinceEpoch}',
      userId: _child.ownerId.isNotEmpty ? _child.ownerId : null,
      doctor: _doctor,
      child: _child,
      scheduledDate: _selectedDate,
      scheduledTimeSlot: _selectedTimeSlot!,
      scheduledStartDateTime: startDt,
      scheduledEndDateTime: endDt,
      googleCalendarUrl: calUrl,
      status: 'Terjadwal',
      createdAt: DateTime.now(),
    );

    // Simpan ke BookingService (tersimpan ke Cloud Firestore koleksi consultation_booking)
    try {
      await BookingService().addBooking(newBooking);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan booking: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    // Otomatis jadwalkan notifikasi pengingat kalender
    NotificationService().addBookingReminderNotification(
      doctorName: _doctor.name,
      childName: _child.name,
      dateFormatted: newBooking.formattedDate,
      timeSlot: _selectedTimeSlot!,
      scheduledTime: startDt,
    );

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });

    // Tampilkan dialog sukses
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildSuccessDialog(ctx, newBooking),
    );
  }

  Widget _buildSuccessDialog(
    BuildContext ctx,
    BookingConsultationModel booking,
  ) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1A2228) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 38,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Booking Berhasil Dijadwalkan!',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Jadwal konsultasi untuk ${_child.name} bersama ${_doctor.name} telah berhasil dicatat pada:\n\n${booking.formattedDate}\n${booking.scheduledTimeSlot}',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 13,
                color: isDark ? const Color(0xFF8696A0) : _colorLabelGrey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            // Card info Google Kalender
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: _colorPrimaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tersambung ke Google Kalender dengan alarm pengingat kegiatan.',
                      style: GoogleFonts.lato(
                        fontSize: 11.5,
                        color: const Color(0xFF1E40AF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tombol Buka di Google Kalender
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _colorPrimaryBlue, width: 1.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  // Arahkan ke DaftarDokterPage dengan Tab Jadwal Konsultasi (index 1)
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) =>
                          const DaftarDokterPage(initialTabIndex: 1),
                    ),
                    (route) => route.isFirst,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _colorPrimaryBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: Text(
                  'Lihat Jadwal Saya',
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
    final isFemale = _child.gender.toLowerCase() == 'perempuan';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1014) : Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: _buildHeader(isDark),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ringkasan Pasien Anak
              _buildChildSummaryCard(isFemale, isDark),
              const SizedBox(height: 14),

              // Ringkasan Dokter
              _buildDoctorSummaryCard(isDark),
              const SizedBox(height: 18),

              // Bagian Pilihan Tanggal
              _buildDateSection(isDark),
              const SizedBox(height: 18),

              // Bagian Pilihan Jam
              _buildTimeSlotSection(isDark),
              const SizedBox(height: 18),

              // Info Banner Form Keluhan
              _buildInfoBanner(isDark),
              const SizedBox(height: 24),

              // Tombol Konfirmasi
              _buildConfirmButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF0B1014) : Colors.white,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 4),
                Text(
                  'Formulir Booking Dokter',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChildSummaryCard(bool isFemale, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : const Color(0xFFBFDBFE),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _colorPrimaryBlue.withValues(alpha: isDark ? 0.04 : 0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.child_care_rounded,
                    size: 16,
                    color: isDark ? const Color(0xFF60A5FA) : _colorPrimaryBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Pasien Terpilih',
                    style: GoogleFonts.lato(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF60A5FA) : _colorPrimaryBlue,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _changeChild,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Ganti Anak',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF60A5FA) : _colorPrimaryBlue,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.swap_horiz_rounded,
                        size: 14,
                        color: isDark ? const Color(0xFF60A5FA) : _colorPrimaryBlue,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildChildAvatar(
                photoUrl: _child.photoUrl,
                isFemale: isFemale,
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _child.name,
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          isFemale ? Icons.female : Icons.male,
                          size: 14,
                          color: isFemale
                              ? const Color(0xFFEC4899)
                              : const Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _child.ageDescription,
                          style: GoogleFonts.lato(
                            fontSize: 12.5,
                            color: isDark ? const Color(0xFF8696A0) : _colorLabelGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorSummaryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : const Color(0xFFBFDBFE),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _colorPrimaryBlue.withValues(alpha: isDark ? 0.04 : 0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B1014) : const Color(0xFFECF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_rounded,
              color: isDark ? const Color(0xFF60A5FA) : _colorPrimaryBlue,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _doctor.name,
                  style: GoogleFonts.lato(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _doctor.specialization,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF60A5FA) : _colorPrimaryBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_doctor.experienceYears} tahun pengalaman praktik',
                  style: GoogleFonts.lato(
                    fontSize: 11.5,
                    color: isDark ? const Color(0xFF8696A0) : _colorLabelGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection(bool isDark) {
    const daysName = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    const monthsName = [
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pilih Tanggal Booking',
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
              ),
            ),
            InkWell(
              onTap: _pickCustomDate,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 15,
                      color: isDark ? const Color(0xFF60A5FA) : _colorPrimaryBlue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Kalender',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF60A5FA) : _colorPrimaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _availableDates.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final date = _availableDates[i];
              final isSelected = _isSameDay(date, _selectedDate);
              final dayOfWeek = daysName[date.weekday % 7];
              final month = monthsName[date.month - 1];

              final cuti = JadwalDokterService().getCutiPadaTanggal(
                _doctor.id,
                date,
              );
              final isPraktik = JadwalDokterService().isDokterPraktikPadaHari(
                _doctor.id,
                date.weekday,
              );

              Widget statusBadge;
              if (cuti != null) {
                statusBadge = Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.22)
                        : (isDark ? const Color(0xFF451A03).withValues(alpha: 0.4) : const Color(0xFFFEF3C7)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Cuti',
                    style: GoogleFonts.lato(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)),
                    ),
                  ),
                );
              } else if (!isPraktik) {
                statusBadge = Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.22)
                        : (isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Libur',
                    style: GoogleFonts.lato(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white70
                          : (isDark ? const Color(0xFF8696A0) : _colorLabelGrey),
                    ),
                  ),
                );
              } else {
                statusBadge = Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.22)
                        : (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFD1FAE5)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Praktik',
                    style: GoogleFonts.lato(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? const Color(0xFF34D399) : const Color(0xFF059669)),
                    ),
                  ),
                );
              }

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                    _refreshSlots();
                  });
                },
                child: Container(
                  width: 60,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _colorPrimaryBlue
                        : (isDark ? const Color(0xFF1A2228) : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? _colorPrimaryBlue
                          : (isDark ? const Color(0xFF2C363D) : _colorBorder),
                      width: 1,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: _colorPrimaryBlue.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayOfWeek,
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white70
                              : (isDark ? const Color(0xFF8696A0) : _colorLabelGrey),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${date.day}',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? const Color(0xFFE9EDEF) : _colorTextBlack),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        month,
                        style: GoogleFonts.lato(
                          fontSize: 9.5,
                          color: isSelected
                              ? Colors.white70
                              : (isDark ? const Color(0xFF8696A0) : _colorLabelGrey),
                        ),
                      ),
                      statusBadge,
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotSection(bool isDark) {
    final cuti = JadwalDokterService().getCutiPadaTanggal(
      _doctor.id,
      _selectedDate,
    );
    final isPraktik = JadwalDokterService().isDokterPraktikPadaHari(
      _doctor.id,
      _selectedDate.weekday,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pilih Sesi Waktu',
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
              ),
            ),
            Text(
              'Sinkron Real-Time',
              style: GoogleFonts.lato(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_availableSlots.isEmpty) ...[
          if (cuti != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF451A03).withValues(alpha: 0.4)
                    : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF78350F) : const Color(0xFFFCD34D),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_busy_rounded, color: Color(0xFFD97706), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${_doctor.name} sedang cuti (${cuti.alasan}). Silakan pilih tanggal lain yang tersedia.',
                      style: GoogleFonts.lato(
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (!isPraktik)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2228) : const Color(0xFFE9EDEF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF2C363D) : _colorBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.hotel_rounded,
                    color: isDark ? const Color(0xFF8696A0) : _colorLabelGrey,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Dokter tidak memiliki jadwal praktik reguler pada hari ini. Silakan pilih tanggal praktik lainnya.',
                      style: GoogleFonts.lato(
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFF8696A0) : _colorLabelGrey,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2228) : const Color(0xFFE9EDEF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF2C363D) : _colorBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: isDark ? const Color(0xFF8696A0) : _colorLabelGrey,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Semua slot konsultasi pada tanggal ini telah penuh atau jam praktik telah selesai. Silakan pilih tanggal berikutnya.',
                      style: GoogleFonts.lato(
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFF8696A0) : _colorLabelGrey,
                      ),
                    ),
                  ),
                ],
              ),
            )
        ] else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableSlots.map((slot) {
              final isSelected = _selectedTimeSlot == slot.timeLabel;
              final isAvail = slot.isAvailable;
              return GestureDetector(
                onTap: isAvail
                    ? () {
                        setState(() {
                          _selectedTimeSlot = slot.timeLabel;
                        });
                      }
                    : null,
                child: Opacity(
                  opacity: isAvail ? 1.0 : 0.45,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
                              : const Color(0xFFEFF6FF))
                          : (isDark ? const Color(0xFF1A2228) : Colors.white),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? _colorPrimaryBlue
                            : (isDark ? const Color(0xFF2C363D) : _colorBorder),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: isSelected
                              ? (isDark ? const Color(0xFF60A5FA) : _colorPrimaryBlue)
                              : (isDark ? const Color(0xFF8696A0) : _colorLabelGrey),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          slot.timeLabel,
                          style: GoogleFonts.lato(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? const Color(0xFF60A5FA) : _colorPrimaryBlue)
                                : (isDark ? const Color(0xFFE9EDEF) : _colorTextBlack),
                            decoration: isAvail ? null : TextDecoration.lineThrough,
                          ),
                        ),
                        if (!isAvail) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(Penuh)',
                            style: GoogleFonts.lato(
                              fontSize: 10,
                              color: const Color(0xFFEF4444),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildInfoBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E3A8A).withValues(alpha: 0.25)
            : _colorPrimaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1E40AF).withValues(alpha: 0.4)
              : _colorPrimaryBlue.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: isDark ? const Color(0xFF60A5FA) : _colorPrimaryBlue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Form keluhan lengkap dan riwayat pengukuran anak akan diisi oleh orang tua ketika waktu sesi konsultasi telah tiba.',
              style: GoogleFonts.lato(
                fontSize: 12,
                color: isDark ? const Color(0xFF93C5FD) : _colorPrimaryBlue,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    final canBook = _selectedTimeSlot != null;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: canBook
            ? _confirmBooking
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Silakan pilih tanggal dan sesi waktu yang tersedia terlebih dahulu',
                    ),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: canBook
              ? _colorPrimaryBlue
              : const Color(0xFF8696A0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Konfirmasi Booking',
          style: GoogleFonts.lato(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildChildAvatar({
    required String? photoUrl,
    required bool isFemale,
    required double size,
  }) {
    // Avatar bawaan memakai widget bersama ChildAvatar.
    final fallback = ChildAvatar(isGirl: isFemale, size: size);

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isFemale ? const Color(0xFFFFEEF0) : const Color(0xFFEBF5FF),
        ),
        clipBehavior: Clip.antiAlias,
        child: StorageService.buildImageWidget(
          photoUrl,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorWidget: fallback,
        ),
      );
    }

    return fallback;
  }
}
