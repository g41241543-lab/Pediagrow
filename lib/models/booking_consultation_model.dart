import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// Konversi dari DocumentSnapshot Firestore
  factory BookingConsultationModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return BookingConsultationModel.fromMap(doc.data() ?? {}, id: doc.id);
  }

  /// Konversi dari Map
  factory BookingConsultationModel.fromMap(
    Map<String, dynamic> map, {
    String? id,
  }) {
    final rawDate = map['scheduledDate'];
    final DateTime scheduledDate = rawDate is Timestamp
        ? rawDate.toDate()
        : rawDate is String
            ? DateTime.tryParse(rawDate) ?? DateTime.now()
            : DateTime.now();

    final rawCreated = map['createdAt'];
    final DateTime createdAt = rawCreated is Timestamp
        ? rawCreated.toDate()
        : rawCreated is String
            ? DateTime.tryParse(rawCreated) ?? DateTime.now()
            : DateTime.now();

    return BookingConsultationModel(
      id: id ?? (map['id'] as String? ?? ''),
      doctor: map['doctor'] is Map<String, dynamic>
          ? DoctorModel.fromMap(map['doctor'] as Map<String, dynamic>)
          : DoctorModel.defaultDoctor,
      child: map['child'] is Map<String, dynamic>
          ? ChildModel.fromMap(map['child'] as Map<String, dynamic>)
          : ChildModel(
              id: '',
              name: map['childName'] as String? ?? 'Ananda',
            ),
      scheduledDate: scheduledDate,
      scheduledTimeSlot: map['scheduledTimeSlot'] as String? ?? '',
      status: map['status'] as String? ?? 'Terjadwal',
      createdAt: createdAt,
    );
  }

  /// Konversi ke Map untuk disimpan di Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctor': doctor.toMap(),
      'child': child.toMap(),
      'childName': child.name,
      'doctorName': doctor.name,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'scheduledTimeSlot': scheduledTimeSlot,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

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

