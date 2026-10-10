import 'child_model.dart';
import 'doctor_model.dart';

enum BookingStatus {
  scheduled, // Terjadwal, menunggu waktu
  ready, // Waktu tiba, diarahkan mengisi formulir
  inProgress, // Sedang berlangsung chat
  completed, // Selesai
  cancelled, // Dibatalkan
}

/// Model data untuk pemesanan jadwal (Booking) konsultasi dokter anak.
class BookingConsultationModel {
  final String id;
  final DoctorModel doctor;
  final ChildModel child;
  final DateTime scheduledDate;
  final String scheduledTimeSlot;
  final DateTime scheduledStartDateTime;
  final DateTime scheduledEndDateTime;
  final String status; // 'Terjadwal' | 'Selesai' | 'Dibatalkan' | 'Siap Konsultasi'
  final String? googleCalendarUrl;
  final double? weightKg;
  final double? heightCm;
  final String? complaint;
  final DateTime createdAt;

  // Getter alias untuk fleksibilitas kode
  DateTime get bookingDate => scheduledDate;
  String get timeSlot => scheduledTimeSlot;

  BookingStatus get bookingStatus {
    switch (status.toLowerCase()) {
      case 'siap konsultasi':
      case 'ready':
        return BookingStatus.ready;
      case 'sedang berlangsung':
      case 'inprogress':
        return BookingStatus.inProgress;
      case 'selesai':
      case 'completed':
        return BookingStatus.completed;
      case 'dibatalkan':
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.scheduled;
    }
  }

  const BookingConsultationModel({
    required this.id,
    required this.doctor,
    required this.child,
    DateTime? scheduledDate,
    DateTime? bookingDate,
    String? scheduledTimeSlot,
    String? timeSlot,
    DateTime? scheduledStartDateTime,
    DateTime? scheduledEndDateTime,
    this.status = 'Terjadwal',
    this.googleCalendarUrl,
    this.weightKg,
    this.heightCm,
    this.complaint,
    required this.createdAt,
  })  : scheduledDate = scheduledDate ?? bookingDate ?? createdAt,
        scheduledTimeSlot = scheduledTimeSlot ?? timeSlot ?? '09:00 - 09:30 WIB',
        scheduledStartDateTime = scheduledStartDateTime ?? (scheduledDate ?? bookingDate ?? createdAt),
        scheduledEndDateTime = scheduledEndDateTime ?? (scheduledDate ?? bookingDate ?? createdAt);

  /// Cek apakah waktu saat ini sudah memasuki atau melewati jadwal konsultasi
  bool get isTimeReady {
    final now = DateTime.now();
    final threshold = scheduledStartDateTime.subtract(const Duration(minutes: 10));
    return now.isAfter(threshold);
  }

  /// Format tanggal standar Indonesia: "Senin, 12 Oktober 2026"
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

    final dayName = days[scheduledDate.weekday - 1];
    final dayNum = scheduledDate.day;
    final monthName = months[scheduledDate.month - 1];
    final year = scheduledDate.year;

    return '$dayName, $dayNum $monthName $year';
  }

  BookingConsultationModel copyWith({
    String? id,
    DoctorModel? doctor,
    ChildModel? child,
    DateTime? scheduledDate,
    DateTime? bookingDate,
    String? scheduledTimeSlot,
    String? timeSlot,
    DateTime? scheduledStartDateTime,
    DateTime? scheduledEndDateTime,
    String? status,
    BookingStatus? bookingStatus,
    String? googleCalendarUrl,
    double? weightKg,
    double? heightCm,
    String? complaint,
    DateTime? createdAt,
  }) {
    String resolvedStatus = status ?? this.status;
    if (bookingStatus != null) {
      switch (bookingStatus) {
        case BookingStatus.ready:
          resolvedStatus = 'Siap Konsultasi';
          break;
        case BookingStatus.inProgress:
          resolvedStatus = 'Sedang Berlangsung';
          break;
        case BookingStatus.completed:
          resolvedStatus = 'Selesai';
          break;
        case BookingStatus.cancelled:
          resolvedStatus = 'Dibatalkan';
          break;
        case BookingStatus.scheduled:
          resolvedStatus = 'Terjadwal';
          break;
      }
    }

    return BookingConsultationModel(
      id: id ?? this.id,
      doctor: doctor ?? this.doctor,
      child: child ?? this.child,
      scheduledDate: scheduledDate ?? bookingDate ?? this.scheduledDate,
      scheduledTimeSlot: scheduledTimeSlot ?? timeSlot ?? this.scheduledTimeSlot,
      scheduledStartDateTime: scheduledStartDateTime ?? this.scheduledStartDateTime,
      scheduledEndDateTime: scheduledEndDateTime ?? this.scheduledEndDateTime,
      status: resolvedStatus,
      googleCalendarUrl: googleCalendarUrl ?? this.googleCalendarUrl,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      complaint: complaint ?? this.complaint,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
