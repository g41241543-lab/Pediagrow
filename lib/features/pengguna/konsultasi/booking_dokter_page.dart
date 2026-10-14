import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/booking_service.dart';
import '../../../core/services/child_service.dart';
import '../../../core/services/doctor_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../models/booking_consultation_model.dart';
import '../../../models/child_model.dart';
import '../../../models/doctor_model.dart';
import 'daftar_dokter_page.dart';
import 'pilih_anak_page.dart';

/// Halaman formulir booking dokter anak oleh pengguna.
///
/// Pengguna memilih tanggal dan sesi jam booking konsultasi dokter.
/// Setelah konfirmasi, jadwal booking disimpan dan diarahkan ke tab Jadwal Konsultasi.
class BookingDokterPage extends StatefulWidget {
  final DoctorModel? doctor;
  final ChildModel? child;

  const BookingDokterPage({
    super.key,
    this.doctor,
    this.child,
  });

  @override
  State<BookingDokterPage> createState() => _BookingDokterPageState();
}

class _BookingDokterPageState extends State<BookingDokterPage> {
  // Palet Warna Resmi PediaGrow
  static const Color _colorPrimaryBlue = Color(0xFF3985E7);
  static const Color _colorTextBlack = Color(0xFF1E293B);
  static const Color _colorLabelGrey = Color(0xFF64748B);
  static const Color _colorBorder = Color(0xFFE2E8F0);

  late DoctorModel _doctor;
  late ChildModel _child;

  late DateTime _selectedDate;
  late String _selectedTimeSlot;

  final List<String> _timeSlots = [
    '08:30 - 09:00 WIB',
    '09:30 - 10:00 WIB',
    '10:30 - 11:00 WIB',
    '13:30 - 14:00 WIB',
    '14:30 - 15:00 WIB',
    '15:30 - 16:00 WIB',
  ];

  late List<DateTime> _availableDates;

  @override
  void initState() {
    super.initState();

    final availableDoctors = DoctorService().doctorsNotifier.value;
    // Resolusi dokter (fallback ke dokter pertama dari DoctorService jika null)
    _doctor = widget.doctor ??
        (availableDoctors.isNotEmpty
            ? availableDoctors.first
            : const DoctorModel(
                id: 'doc_default',
                name: 'dr. Ahmad Nuri, Sp. A',
                specialization: 'Spesialis Anak',
                experienceYears: 10,
                isOnline: true,
                placesOfPractice: ['Klinik Tumbuh Kembang PediaGrow'],
              ));

    // Resolusi anak (fallback ke active child atau anak pertama dari ChildService)
    _child = widget.child ??
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
    _selectedTimeSlot = _timeSlots[1]; // default jam 09:30
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
      });
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _confirmBooking() {
    final newBooking = BookingConsultationModel(
      id: 'book_${DateTime.now().millisecondsSinceEpoch}',
      doctor: _doctor,
      child: _child,
      scheduledDate: _selectedDate,
      scheduledTimeSlot: _selectedTimeSlot,
      status: 'Terjadwal',
      createdAt: DateTime.now(),
    );

    // Simpan ke BookingService
    BookingService().addBooking(newBooking);

    // Tampilkan dialog sukses
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildSuccessDialog(ctx, newBooking),
    );
  }

  Widget _buildSuccessDialog(BuildContext ctx, BookingConsultationModel booking) {
    return Dialog(
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
                color: _colorTextBlack,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Jadwal konsultasi untuk ${_child.name} bersama ${_doctor.name} telah berhasil dicatat pada:\n\n${booking.formattedDate}\n${booking.scheduledTimeSlot}',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 13,
                color: _colorLabelGrey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  // Arahkan ke DaftarDokterPage dengan Tab Jadwal Konsultasi (index 1)
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const DaftarDokterPage(initialTabIndex: 1),
                    ),
                    (route) => false,
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
    final isFemale = _child.gender.toLowerCase() == 'perempuan';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: _buildHeader(),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ringkasan Pasien Anak
              _buildChildSummaryCard(isFemale),
              const SizedBox(height: 14),

              // Ringkasan Dokter
              _buildDoctorSummaryCard(),
              const SizedBox(height: 18),

              // Bagian Pilihan Tanggal
              _buildDateSection(),
              const SizedBox(height: 18),

              // Bagian Pilihan Jam
              _buildTimeSlotSection(),
              const SizedBox(height: 18),



              // Info Banner Form Keluhan
              _buildInfoBanner(),
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

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: _colorTextBlack,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 4),
                Text(
                  'Formulir Booking Dokter',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _colorTextBlack,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChildSummaryCard(bool isFemale) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _colorBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
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
                  const Icon(
                    Icons.child_care_rounded,
                    size: 16,
                    color: _colorPrimaryBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Pasien Terpilih',
                    style: GoogleFonts.lato(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: _colorPrimaryBlue,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _changeChild,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'Ganti Anak',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _colorPrimaryBlue,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.swap_horiz_rounded,
                        size: 14,
                        color: _colorPrimaryBlue,
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
                        color: _colorTextBlack,
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
                            color: _colorLabelGrey,
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

  Widget _buildDoctorSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _colorBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFECF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: _colorPrimaryBlue,
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
                    color: _colorTextBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _doctor.specialization,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _colorPrimaryBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_doctor.experienceYears} tahun pengalaman praktik',
                  style: GoogleFonts.lato(
                    fontSize: 11.5,
                    color: _colorLabelGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
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
                color: _colorTextBlack,
              ),
            ),
            InkWell(
              onTap: _pickCustomDate,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 15,
                      color: _colorPrimaryBlue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Kalender',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _colorPrimaryBlue,
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
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _availableDates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final date = _availableDates[i];
              final isSelected = _isSameDay(date, _selectedDate);
              final dayOfWeek = daysName[date.weekday % 7];
              final month = monthsName[date.month - 1];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: Container(
                  width: 60,
                  decoration: BoxDecoration(
                    color: isSelected ? _colorPrimaryBlue : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? _colorPrimaryBlue : _colorBorder,
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
                          color: isSelected ? Colors.white70 : _colorLabelGrey,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${date.day}',
                        style: GoogleFonts.lato(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : _colorTextBlack,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        month,
                        style: GoogleFonts.lato(
                          fontSize: 10,
                          color: isSelected ? Colors.white70 : _colorLabelGrey,
                        ),
                      ),
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

  Widget _buildTimeSlotSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Sesi Waktu',
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _colorTextBlack,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _timeSlots.map((slot) {
            final isSelected = _selectedTimeSlot == slot;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTimeSlot = slot;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? _colorPrimaryBlue : _colorBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: isSelected ? _colorPrimaryBlue : _colorLabelGrey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      slot,
                      style: GoogleFonts.lato(
                        fontSize: 12.5,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? _colorPrimaryBlue : _colorTextBlack,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }



  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _colorPrimaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _colorPrimaryBlue.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: _colorPrimaryBlue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Form keluhan lengkap dan riwayat pengukuran anak akan diisi oleh orang tua ketika waktu sesi konsultasi telah tiba.',
              style: GoogleFonts.lato(
                fontSize: 12,
                color: _colorPrimaryBlue,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _confirmBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: _colorPrimaryBlue,
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
    final bgColor =
        isFemale ? const Color(0xFFFFE4E6) : const Color(0xFFDBEAFE);

    final fallback = Container(
      color: bgColor,
      child: CustomPaint(painter: _BabyFacePainter(isGirl: isFemale)),
    );

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
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

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: CustomPaint(painter: _BabyFacePainter(isGirl: isFemale)),
    );
  }
}

class _BabyFacePainter extends CustomPainter {
  final bool isGirl;
  const _BabyFacePainter({this.isGirl = true});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final strokePaint = Paint()
      ..color = const Color(0xFF222222)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = const Color(0xFF222222)
      ..style = PaintingStyle.fill;

    final blushPaint = Paint()
      ..color = const Color(0xFFFF8FA3).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final cx = w * 0.5;
    final cy = h * 0.52;
    final r = w * 0.36;

    final headRect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    canvas.drawArc(headRect, 0, math.pi * 2, false, strokePaint);

    final hairPath = Path();
    hairPath.moveTo(cx - r * 0.85, cy - r * 0.3);
    hairPath.quadraticBezierTo(cx - r * 0.35, cy - r * 0.9, cx, cy - r * 0.4);
    hairPath.quadraticBezierTo(
      cx + r * 0.35,
      cy - r * 0.9,
      cx + r * 0.85,
      cy - r * 0.3,
    );
    canvas.drawPath(hairPath, strokePaint);

    canvas.drawCircle(
      Offset(cx - r * 0.38, cy - r * 0.05),
      w * 0.045,
      fillPaint,
    );
    canvas.drawCircle(
      Offset(cx + r * 0.38, cy - r * 0.05),
      w * 0.045,
      fillPaint,
    );

    canvas.drawCircle(
      Offset(cx - r * 0.55, cy + r * 0.15),
      w * 0.065,
      blushPaint,
    );
    canvas.drawCircle(
      Offset(cx + r * 0.55, cy + r * 0.15),
      w * 0.065,
      blushPaint,
    );

    final smilePath = Path();
    smilePath.moveTo(cx - r * 0.35, cy + r * 0.18);
    smilePath.quadraticBezierTo(
      cx,
      cy + r * 0.62,
      cx + r * 0.35,
      cy + r * 0.18,
    );
    canvas.drawPath(smilePath, strokePaint);

    if (isGirl) {
      final bowPaint = Paint()
        ..color = const Color(0xFFFF6B9D)
        ..style = PaintingStyle.fill;
      final bowPath = Path();
      bowPath.moveTo(cx - r * 0.1, cy - r * 0.85);
      bowPath.quadraticBezierTo(
          cx - r * 0.4, cy - r * 1.15, cx - r * 0.25, cy - r * 0.75);
      bowPath.quadraticBezierTo(
          cx - r * 0.1, cy - r * 1.05, cx, cy - r * 0.85);
      bowPath.quadraticBezierTo(
          cx + r * 0.1, cy - r * 1.05, cx + r * 0.25, cy - r * 0.75);
      bowPath.quadraticBezierTo(
          cx + r * 0.4, cy - r * 1.15, cx + r * 0.1, cy - r * 0.85);
      canvas.drawPath(bowPath, bowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
