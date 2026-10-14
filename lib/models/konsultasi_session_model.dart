import 'package:cloud_firestore/cloud_firestore.dart';

/// Status sesi konsultasi antara pengguna dan dokter.
enum KonsultasiStatus {
  menunggu,  // Booking dibuat, belum dimulai dokter
  aktif,     // Dokter sudah masuk, sesi sedang berlangsung
  selesai,   // Dokter telah mengakhiri sesi
}

/// Model sesi konsultasi yang tersimpan di Firestore.
///
/// Struktur Firestore:
/// ```
/// konsultasi_sessions/{sessionId}
/// ```
class KonsultasiSessionModel {
  final String id;
  final String childId;
  final String childName;
  final String userId;       // ID pengguna (orang tua)
  final String parentName;
  final String doctorId;     // ID staff dokter (dari StaffAccount)
  final String doctorName;
  final KonsultasiStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? keluhanAwal; // Keluhan yang diisi di formulir
  final double? weightKg;
  final double? heightCm;
  final String? childPhotoUrl;
  final String? childGender;
  final String? childAge;

  const KonsultasiSessionModel({
    required this.id,
    required this.childId,
    required this.childName,
    required this.userId,
    required this.parentName,
    required this.doctorId,
    required this.doctorName,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.keluhanAwal,
    this.weightKg,
    this.heightCm,
    this.childPhotoUrl,
    this.childGender,
    this.childAge,
  });

  bool get isAktif => status == KonsultasiStatus.aktif;
  bool get isSelesai => status == KonsultasiStatus.selesai;
  bool get isMenunggu => status == KonsultasiStatus.menunggu;

  /// Parsing dari dokumen Firestore.
  factory KonsultasiSessionModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return KonsultasiSessionModel(
      id: doc.id,
      childId: data['childId'] as String? ?? '',
      childName: data['childName'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      parentName: data['parentName'] as String? ?? '',
      doctorId: data['doctorId'] as String? ?? '',
      doctorName: data['doctorName'] as String? ?? '',
      status: _parseStatus(data['status'] as String? ?? 'menunggu'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      endedAt: (data['endedAt'] as Timestamp?)?.toDate(),
      keluhanAwal: data['keluhanAwal'] as String?,
      weightKg: (data['weightKg'] as num?)?.toDouble(),
      heightCm: (data['heightCm'] as num?)?.toDouble(),
      childPhotoUrl: data['childPhotoUrl'] as String?,
      childGender: data['childGender'] as String?,
      childAge: data['childAge'] as String?,
    );
  }

  /// Konversi ke Map untuk disimpan ke Firestore.
  Map<String, dynamic> toMap() {
    return {
      'childId': childId,
      'childName': childName,
      'userId': userId,
      'parentName': parentName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'status': status.name,
      'createdAt': FieldValue.serverTimestamp(),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'keluhanAwal': keluhanAwal,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'childPhotoUrl': childPhotoUrl,
      'childGender': childGender,
      'childAge': childAge,
    };
  }

  KonsultasiSessionModel copyWith({
    String? id,
    KonsultasiStatus? status,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return KonsultasiSessionModel(
      id: id ?? this.id,
      childId: childId,
      childName: childName,
      userId: userId,
      parentName: parentName,
      doctorId: doctorId,
      doctorName: doctorName,
      status: status ?? this.status,
      createdAt: createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      keluhanAwal: keluhanAwal,
      weightKg: weightKg,
      heightCm: heightCm,
      childPhotoUrl: childPhotoUrl,
      childGender: childGender,
      childAge: childAge,
    );
  }

  static KonsultasiStatus _parseStatus(String raw) {
    switch (raw) {
      case 'aktif':
        return KonsultasiStatus.aktif;
      case 'selesai':
        return KonsultasiStatus.selesai;
      default:
        return KonsultasiStatus.menunggu;
    }
  }
}
