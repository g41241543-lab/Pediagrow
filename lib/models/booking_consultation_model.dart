import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String? userId;
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
  final String? sessionId;
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

  BookingConsultationModel({
    required this.id,
    this.userId,
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
    this.sessionId,
    required this.createdAt,
  })  : scheduledDate = scheduledDate ?? bookingDate ?? createdAt,
        scheduledTimeSlot = scheduledTimeSlot ?? timeSlot ?? '09:00 - 09:30 WIB',
        scheduledStartDateTime = _resolveStartDateTime(
          scheduledStartDateTime,
          scheduledDate ?? bookingDate ?? createdAt,
          scheduledTimeSlot ?? timeSlot ?? '09:00 - 09:30 WIB',
        ),
        scheduledEndDateTime = _resolveEndDateTime(
          scheduledEndDateTime,
          scheduledDate ?? bookingDate ?? createdAt,
          scheduledTimeSlot ?? timeSlot ?? '09:00 - 09:30 WIB',
        );

  static DateTime _resolveStartDateTime(
    DateTime? explicit,
    DateTime baseDate,
    String slotStr,
  ) {
    if (explicit != null) return explicit;
    // Coba ekstrak jam & menit dari string slot, contoh: "09:00 - 09:30 WIB"
    final matches = RegExp(r'(\d{1,2})[:.](\d{2})').allMatches(slotStr).toList();
    if (matches.isNotEmpty) {
      final hour = int.tryParse(matches[0].group(1) ?? '') ?? 9;
      final minute = int.tryParse(matches[0].group(2) ?? '') ?? 0;
      return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
    }
    return baseDate;
  }

  static DateTime _resolveEndDateTime(
    DateTime? explicit,
    DateTime baseDate,
    String slotStr,
  ) {
    if (explicit != null) return explicit;
    final matches = RegExp(r'(\d{1,2})[:.](\d{2})').allMatches(slotStr).toList();
    if (matches.length >= 2) {
      final hour = int.tryParse(matches[1].group(1) ?? '') ?? 9;
      final minute = int.tryParse(matches[1].group(2) ?? '') ?? 30;
      return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
    } else if (matches.isNotEmpty) {
      final start = _resolveStartDateTime(null, baseDate, slotStr);
      return start.add(const Duration(minutes: 30));
    }
    return baseDate.add(const Duration(minutes: 30));
  }

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
    final rawDate = map['scheduledDate'] ?? map['bookingDate'];
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

    final rawStart = map['scheduledStartDateTime'];
    final DateTime? scheduledStartDateTime = rawStart is Timestamp
        ? rawStart.toDate()
        : rawStart is String
            ? DateTime.tryParse(rawStart)
            : null;

    final rawEnd = map['scheduledEndDateTime'];
    final DateTime? scheduledEndDateTime = rawEnd is Timestamp
        ? rawEnd.toDate()
        : rawEnd is String
            ? DateTime.tryParse(rawEnd)
            : null;

    final rawWeight = map['weightKg'];
    final double? weightKg =
        rawWeight != null ? (rawWeight as num).toDouble() : null;

    final rawHeight = map['heightCm'];
    final double? heightCm =
        rawHeight != null ? (rawHeight as num).toDouble() : null;

    final doctorMap = map['doctor'];
    final DoctorModel doctor = doctorMap is Map
        ? DoctorModel.fromMap({
            ...Map<String, dynamic>.from(doctorMap),
            if (doctorMap['id'] != null) 'id': doctorMap['id'].toString(),
          })
        : DoctorModel.defaultDoctor;

    final childMap = map['child'];
    final ChildModel child = childMap is Map
        ? ChildModel.fromMap(Map<String, dynamic>.from(childMap))
        : ChildModel(
            id: (map['childId'] as String?) ?? '',
            name: map['childName'] as String? ?? 'Ananda',
          );

    return BookingConsultationModel(
      id: id ?? (map['id'] as String? ?? ''),
      userId: map['userId'] as String? ?? (child.ownerId.isNotEmpty ? child.ownerId : null),
      doctor: doctor,
      child: child,
      scheduledDate: scheduledDate,
      scheduledTimeSlot:
          (map['scheduledTimeSlot'] ?? map['timeSlot']) as String? ?? '',
      scheduledStartDateTime: scheduledStartDateTime,
      scheduledEndDateTime: scheduledEndDateTime,
      status: map['status'] as String? ?? 'Terjadwal',
      googleCalendarUrl: map['googleCalendarUrl'] as String?,
      weightKg: weightKg,
      heightCm: heightCm,
      complaint: map['complaint'] as String?,
      sessionId: map['sessionId'] as String?,
      createdAt: createdAt,
    );
  }

  /// Konversi ke Map untuk disimpan di Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId ?? child.ownerId,
      'doctorId': doctor.id,
      'childId': child.id,
      'doctor': {
        'id': doctor.id,
        'name': doctor.name,
        'specialization': doctor.specialization,
        'avatar_url': doctor.avatarUrl,
        'asset_image_path': doctor.assetImagePath,
        'experience_years': doctor.experienceYears,
        'str_number': doctor.strNumber,
        'hospital': doctor.hospital,
        'places_of_practice': doctor.placesOfPractice,
        'consultation_fee': doctor.consultationFee,
        'is_online': doctor.isOnline,
        'staff_account_id': doctor.staffAccountId,
        'email': doctor.email,
      },
      'child': child.toMap(),
      'childName': child.name,
      'doctorName': doctor.name,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'scheduledTimeSlot': scheduledTimeSlot,
      'scheduledStartDateTime': Timestamp.fromDate(scheduledStartDateTime),
      'scheduledEndDateTime': Timestamp.fromDate(scheduledEndDateTime),
      'status': status,
      'googleCalendarUrl': googleCalendarUrl,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'complaint': complaint,
      'sessionId': sessionId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Cek apakah waktu saat ini masih sebelum jadwal mulai konsultasi
  bool get isBeforeStart => DateTime.now().isBefore(scheduledStartDateTime);

  /// Cek apakah waktu saat ini berada dalam rentang jadwal konsultasi (mulai sampai selesai)
  bool get isInTimeWindow {
    final now = DateTime.now();
    return (now.isAfter(scheduledStartDateTime) || now.isAtSameMomentAs(scheduledStartDateTime)) &&
        now.isBefore(scheduledEndDateTime);
  }

  /// Cek apakah waktu jadwal konsultasi sudah berakhir (waktu booking habis)
  bool get isExpired {
    return DateTime.now().isAfter(scheduledEndDateTime) || status.toLowerCase() == 'selesai';
  }

  /// Cek apakah formulir konsultasi untuk booking ini sudah pernah diisi
  bool get hasFilledForm {
    return (complaint != null && complaint!.trim().isNotEmpty) ||
        (sessionId != null && sessionId!.isNotEmpty) ||
        status.toLowerCase() == 'sedang berlangsung';
  }

  /// Format tanggal standar Indonesia: "Senin, 13 Okt 2026"
  /// Cek apakah waktu saat ini sudah memasuki atau melewati jadwal konsultasi
  bool get isTimeReady => isInTimeWindow;

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
    String? userId,
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
    String? sessionId,
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
      userId: userId ?? this.userId,
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
      sessionId: sessionId ?? this.sessionId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

