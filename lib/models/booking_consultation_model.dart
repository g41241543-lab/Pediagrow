import 'child_model.dart';
import 'doctor_model.dart';

enum BookingStatus {
  scheduled, // Terjadwal, menunggu waktu
  ready,     // Waktu tiba, diarahkan mengisi formulir
  inProgress,// Sedang berlangsung chat
  completed, // Selesai
  cancelled, // Dibatalkan
}

/// Model data untuk pemesanan jadwal (Booking) konsultasi dokter anak.
class BookingConsultationModel {
  final String id;
  final DoctorModel doctor;
  final ChildModel child;
  final DateTime bookingDate; // Tanggal janji temu
  final String timeSlot; // misal: "09:00 - 09:30"
  final DateTime scheduledStartDateTime;
  final DateTime scheduledEndDateTime;
  final BookingStatus status;
  final String? googleCalendarUrl;
  final double? weightKg;
  final double? heightCm;
  final String? complaint;
  final DateTime createdAt;

  const BookingConsultationModel({
    required this.id,
    required this.doctor,
    required this.child,
    required this.bookingDate,
    required this.timeSlot,
    required this.scheduledStartDateTime,
    required this.scheduledEndDateTime,
    this.status = BookingStatus.scheduled,
    this.googleCalendarUrl,
    this.weightKg,
    this.heightCm,
    this.complaint,
    required this.createdAt,
  });

  /// Cek apakah waktu saat ini sudah memasuki atau melewati jadwal konsultasi
  bool get isTimeReady {
    final now = DateTime.now();
    // Boleh dimulai 10 menit sebelum jadwal atau saat jam tiba
    final threshold = scheduledStartDateTime.subtract(const Duration(minutes: 10));
    return now.isAfter(threshold);
  }

  /// Format tanggal Indonesia: "Senin, 12 Oktober 2026"
  String get formattedDate {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final dayName = days[bookingDate.weekday - 1];
    final dayNum = bookingDate.day;
    final monthName = months[bookingDate.month - 1];
    final year = bookingDate.year;

    return '$dayName, $dayNum $monthName $year';
  }

  BookingConsultationModel copyWith({
    String? id,
    DoctorModel? doctor,
    ChildModel? child,
    DateTime? bookingDate,
    String? timeSlot,
    DateTime? scheduledStartDateTime,
    DateTime? scheduledEndDateTime,
    BookingStatus? status,
    String? googleCalendarUrl,
    double? weightKg,
    double? heightCm,
    String? complaint,
    DateTime? createdAt,
  }) {
    return BookingConsultationModel(
      id: id ?? this.id,
      doctor: doctor ?? this.doctor,
      child: child ?? this.child,
      bookingDate: bookingDate ?? this.bookingDate,
      timeSlot: timeSlot ?? this.timeSlot,
      scheduledStartDateTime:
          scheduledStartDateTime ?? this.scheduledStartDateTime,
      scheduledEndDateTime: scheduledEndDateTime ?? this.scheduledEndDateTime,
      status: status ?? this.status,
      googleCalendarUrl: googleCalendarUrl ?? this.googleCalendarUrl,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      complaint: complaint ?? this.complaint,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
