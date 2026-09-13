import 'doctor_model.dart';

/// Status permintaan konsultasi
enum ConsultationStatus {
  waiting,
  accepted,
  expired,
}

/// Model data untuk permintaan konsultasi dokter di PediaGrow.
class ConsultationModel {
  final String id;
  final DoctorModel doctor;
  final DateTime createdAt;
  final ConsultationStatus status;
  final String? consultationDate;
  final String? consultationTime;
  final String? notes;

  const ConsultationModel({
    required this.id,
    required this.doctor,
    required this.createdAt,
    this.status = ConsultationStatus.waiting,
    this.consultationDate,
    this.consultationTime,
    this.notes,
  });

  /// Salin objek dengan perubahan status atau field lainnya
  ConsultationModel copyWith({
    String? id,
    DoctorModel? doctor,
    DateTime? createdAt,
    ConsultationStatus? status,
    String? consultationDate,
    String? consultationTime,
    String? notes,
  }) {
    return ConsultationModel(
      id: id ?? this.id,
      doctor: doctor ?? this.doctor,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      consultationDate: consultationDate ?? this.consultationDate,
      consultationTime: consultationTime ?? this.consultationTime,
      notes: notes ?? this.notes,
    );
  }

  /// Format tanggal dan waktu standar Indonesia: "Rabu, 26 Agu 2026 15 : 26"
  String get formattedCreatedAt {
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

    final dayName = days[createdAt.weekday - 1];
    final dayNum = createdAt.day;
    final monthName = months[createdAt.month - 1];
    final year = createdAt.year;
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');

    return '$dayName, $dayNum $monthName $year $hour : $minute';
  }

  /// Data dummy konsultasi default untuk fallback/testing
  static ConsultationModel defaultConsultation({DoctorModel? doctor}) {
    return ConsultationModel(
      id: 'cons-001',
      doctor: doctor ?? DoctorModel.defaultDoctor,
      createdAt: DateTime.now(),
      status: ConsultationStatus.waiting,
    );
  }
}
