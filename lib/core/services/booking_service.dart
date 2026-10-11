import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/booking_consultation_model.dart';

/// Service singleton untuk mengelola daftar jadwal booking konsultasi dokter
/// yang dibuat oleh pengguna, tersimpan dan tersinkronisasi di Firestore.
class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'consultation_bookings';

  BookingService._internal() {
    _initFirestoreListener();
  }

  /// Daftar semua riwayat / jadwal booking pengguna
  final ValueNotifier<List<BookingConsultationModel>> bookingsNotifier =
      ValueNotifier<List<BookingConsultationModel>>([]);

  /// Booking yang sedang aktif saat ini
  final ValueNotifier<BookingConsultationModel?> activeBookingNotifier =
      ValueNotifier<BookingConsultationModel?>(null);

  List<BookingConsultationModel> get bookings => bookingsNotifier.value;

<<<<<<< ours
  void _initFirestoreListener() {
    try {
      _db
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
        (snapshot) {
          final items = snapshot.docs
              .map((doc) => BookingConsultationModel.fromDoc(doc))
              .toList();
          // Merge dengan memory jika ada data lokal
          final existingIds = items.map((i) => i.id).toSet();
          final localOnly =
              bookingsNotifier.value.where((b) => !existingIds.contains(b.id));
          bookingsNotifier.value = [...items, ...localOnly];
        },
        onError: (err) {
          debugPrint('BookingService Firestore error: $err');
        },
      );
    } catch (e) {
      debugPrint('BookingService init error: $e');
    }
  }

  /// Menambahkan booking konsultasi baru ke lokal notifier dan Firestore
  Future<void> addBooking(BookingConsultationModel booking) async {
    // 1. Update lokal langsung agar instan di UI
    if (!bookingsNotifier.value.any((b) => b.id == booking.id)) {
      bookingsNotifier.value = [booking, ...bookingsNotifier.value];
    }
=======
  void addBooking(BookingConsultationModel booking) {
    bookingsNotifier.value = [booking, ...bookingsNotifier.value];
    if (activeBookingNotifier.value == null) {
      activeBookingNotifier.value = booking;
    }
  }

  /// Menghasilkan slot waktu yang tersedia untuk dokter pada tanggal tertentu
  /// Mengelompokkan slot waktu menjadi Pagi, Siang, dan Sore/Malam
  List<DoctorTimeSlot> getAvailableSlotsForDoctor({
    required DoctorModel doctor,
    required DateTime date,
  }) {
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    // Slot standar jam praktik konsultasi dokter anak
    final rawSlots = [
      const DoctorTimeSlot(time: '08:30 - 09:00', startHour: 8, startMinute: 30, period: 'Pagi'),
      const DoctorTimeSlot(time: '09:00 - 09:30', startHour: 9, startMinute: 0, period: 'Pagi'),
      const DoctorTimeSlot(time: '10:00 - 10:30', startHour: 10, startMinute: 0, period: 'Pagi'),
      const DoctorTimeSlot(time: '11:00 - 11:30', startHour: 11, startMinute: 0, period: 'Pagi'),
      const DoctorTimeSlot(time: '13:00 - 13:30', startHour: 13, startMinute: 0, period: 'Siang'),
      const DoctorTimeSlot(time: '14:00 - 14:30', startHour: 14, startMinute: 0, period: 'Siang'),
      const DoctorTimeSlot(time: '15:30 - 16:00', startHour: 15, startMinute: 30, period: 'Sore'),
      const DoctorTimeSlot(time: '16:30 - 17:00', startHour: 16, startMinute: 30, period: 'Sore'),
      const DoctorTimeSlot(time: '19:00 - 19:30', startHour: 19, startMinute: 0, period: 'Malam'),
      const DoctorTimeSlot(time: '20:00 - 20:30', startHour: 20, startMinute: 0, period: 'Malam'),
    ];

    // Cek ketersediaan berdasarkan jam saat ini jika hari ini
    return rawSlots.map((slot) {
      bool available = true;
      if (isToday) {
        final slotTime = DateTime(date.year, date.month, date.day, slot.startHour, slot.startMinute);
        if (slotTime.isBefore(now)) {
          available = false; // Jam sudah lewat
        }
      }

      // Cek apakah sudah pernah di-booking
      final isAlreadyBooked = bookingsNotifier.value.any((b) =>
          b.doctor.id == doctor.id &&
          b.bookingDate.year == date.year &&
          b.bookingDate.month == date.month &&
          b.bookingDate.day == date.day &&
          b.timeSlot == slot.time &&
          b.status != 'Dibatalkan');

      if (isAlreadyBooked) {
        available = false;
      }

      return slot.copyWith(isAvailable: available);
    }).toList();
  }

  /// Membuat booking baru
  BookingConsultationModel createBooking({
    required DoctorModel doctor,
    required ChildModel child,
    required DateTime date,
    required DoctorTimeSlot slot,
  }) {
    final startDt = DateTime(
      date.year,
      date.month,
      date.day,
      slot.startHour,
      slot.startMinute,
    );
    final endDt = startDt.add(const Duration(minutes: 30));

    final id = 'booking-${DateTime.now().millisecondsSinceEpoch}';
    final calUrl = generateGoogleCalendarUrl(
      doctor: doctor,
      child: child,
      startTime: startDt,
      endTime: endDt,
    );

    final newBooking = BookingConsultationModel(
      id: id,
      doctor: doctor,
      child: child,
      bookingDate: date,
      timeSlot: slot.time,
      scheduledStartDateTime: startDt,
      scheduledEndDateTime: endDt,
      status: 'Terjadwal',
      googleCalendarUrl: calUrl,
      createdAt: DateTime.now(),
    );

    final updated = List<BookingConsultationModel>.from(bookingsNotifier.value)
      ..insert(0, newBooking);
    bookingsNotifier.value = updated;
    activeBookingNotifier.value = newBooking;

    return newBooking;
  }

  /// Memperbarui booking dengan data formulir konsultasi (BB, TB, Keluhan)
  void updateBookingForm({
    required String bookingId,
    required double weightKg,
    required double heightCm,
    required String complaint,
  }) {
    final list = List<BookingConsultationModel>.from(bookingsNotifier.value);
    final idx = list.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      final updated = list[idx].copyWith(
        weightKg: weightKg,
        heightCm: heightCm,
        complaint: complaint,
        status: 'Sedang Berlangsung',
      );
      list[idx] = updated;
      bookingsNotifier.value = list;

      if (activeBookingNotifier.value?.id == bookingId) {
        activeBookingNotifier.value = updated;
      }
    }
  }

  /// Format URL Google Calendar (Render Template Action)
  /// Menyertakan nama dokter, nama anak, waktu janji temu, dan pengingat
  String generateGoogleCalendarUrl({
    required DoctorModel doctor,
    required ChildModel child,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    // Format UTC: YYYYMMDDTHHmmssZ
    final startUtc = startTime.toUtc();
    final endUtc = endTime.toUtc();

    String formatUtc(DateTime dt) {
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      final s = dt.second.toString().padLeft(2, '0');
      return '$y$m${d}T$h$min${s}Z';
    }

    final datesParam = '${formatUtc(startUtc)}/${formatUtc(endUtc)}';
    final title = 'Konsultasi Dokter: ${doctor.name} - PediaGrow';
    final details = 'Jadwal konsultasi kesehatan anak: ${child.name} '
        'bersama ${doctor.name} (${doctor.specialization}) '
        'melalui sesi chat aplikasi PediaGrow.';
    const location = 'Aplikasi PediaGrow (Online Chat)';

    return 'https://calendar.google.com/calendar/render?'
        'action=TEMPLATE&'
        'text=${Uri.encodeComponent(title)}&'
        'dates=$datesParam&'
        'details=${Uri.encodeComponent(details)}&'
        'location=${Uri.encodeComponent(location)}';
  }

  /// Membuka Google Kalender secara langsung
  Future<bool> launchGoogleCalendar(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[BookingService] Error launchGoogleCalendar: $e');
    }
    return false;
  }

  void _initDefaultBookings() {
    final child1 = ChildModel(
      id: 'child_mock_1',
      name: 'Devaro Ramadhan',
      gender: 'Laki-laki',
      ageDescription: '1 tahun 2 bulan 13 hari',
      birthDate: DateTime.now().subtract(const Duration(days: 440)),
      photoUrl: null,
    );

    final child2 = ChildModel(
      id: 'child_mock_2',
      name: 'Naya Seiza Putri',
      gender: 'Perempuan',
      ageDescription: '0 tahun 8 bulan 20 hari',
      birthDate: DateTime.now().subtract(const Duration(days: 260)),
      photoUrl: null,
    );

    const doc1 = DoctorModel(
      id: 'doc_1',
      name: 'dr. Ahmad Nuri, Sp. A',
      specialization: 'Spesialis Anak',
      experienceYears: 12,
      isOnline: true,
      strNumber: 'STR-33.1.1.100.2.20.123456',
      placesOfPractice: ['RS Hermina Pasteur', 'Klinik Tumbuh Kembang'],
    );
>>>>>>> theirs

    // 2. Simpan ke Firestore
    try {
      await _db.collection(_collection).doc(booking.id).set(booking.toMap());
    } catch (e) {
      debugPrint('Gagal menyimpan booking ke Firestore: $e');
    }
  }

  /// Menghapus booking berdasarkan ID
  Future<void> removeBooking(String bookingId) async {
    bookingsNotifier.value =
        bookingsNotifier.value.where((b) => b.id != bookingId).toList();

    try {
      await _db.collection(_collection).doc(bookingId).delete();
    } catch (e) {
      debugPrint('Gagal menghapus booking dari Firestore: $e');
    }
  }
}

<<<<<<< ours
=======
class DoctorTimeSlot {
  final String time;
  final int startHour;
  final int startMinute;
  final String period; // Pagi, Siang, Sore, Malam
  final bool isAvailable;

  const DoctorTimeSlot({
    required this.time,
    required this.startHour,
    required this.startMinute,
    required this.period,
    this.isAvailable = true,
  });

  DoctorTimeSlot copyWith({
    String? time,
    int? startHour,
    int? startMinute,
    String? period,
    bool? isAvailable,
  }) {
    return DoctorTimeSlot(
      time: time ?? this.time,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      period: period ?? this.period,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
>>>>>>> theirs
