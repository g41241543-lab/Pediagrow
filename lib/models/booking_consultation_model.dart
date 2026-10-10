import 'child_model.dart';
import 'doctor_model.dart';

/// Model data untuk jadwal booking konsultasi dokter oleh pengguna.
class BookingConsultationModel {
  final String id;
  final DoctorModel doctor;
  final ChildModel child;
  final DateTime scheduledDate;
  final String scheduledTimeSlot; // Contoh: '09:00 - 09:30 WIB'
  final String status; // 'Terjadwal' | 'Selesai' | 'Dibatalkan'
  final DateTime createdAt;

  const BookingConsultationModel({
    required this.id,
    required this.doctor,
    required this.child,
    required this.scheduledDate,
    required this.scheduledTimeSlot,
    this.status = 'Terjadwal',
    required this.createdAt,
  });

  /// Format tanggal standar Indonesia: "Senin, 13 Okt 2026"
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

    final dayName = days[scheduledDate.weekday - 1];
    final dayNum = scheduledDate.day;
    final monthName = months[scheduledDate.month - 1];
    final year = scheduledDate.year;

    return '$dayName, $dayNum $monthName $year';
  }
}
