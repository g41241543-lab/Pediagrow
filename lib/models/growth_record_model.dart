/// Status hasil analisis stunting untuk satu catatan pertumbuhan.
enum GrowthStuntingStatus {
  normal,
  berisikoStunting,
  stunting,
  tinggi;

  String get label {
    switch (this) {
      case GrowthStuntingStatus.normal:
        return 'Normal';
      case GrowthStuntingStatus.berisikoStunting:
        return 'Berisiko Stunting';
      case GrowthStuntingStatus.stunting:
        return 'Stunting';
      case GrowthStuntingStatus.tinggi:
        return 'Tinggi di Atas Rata-rata';
    }
  }

  static GrowthStuntingStatus fromString(String value) {
    return GrowthStuntingStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => GrowthStuntingStatus.normal,
    );
  }
}

/// Satu titik data pertumbuhan anak, dihasilkan setiap kali pengguna
/// melakukan Cek Stunting. Dipakai untuk menampilkan Grafik Pertumbuhan
/// dan riwayat pemeriksaan anak dari waktu ke waktu.
class GrowthRecordModel {
  final String id; // ID dokumen Firestore
  final String childId; // relasi ke ChildModel.id
  final DateTime date; // tanggal pemeriksaan
  final double weightKg;
  final double heightCm;
  final double? headCircumferenceCm;
  final double zScoreHeightForAge;
  final double zScoreWeightForAge;
  final GrowthStuntingStatus status;
  final String? aiDescription;
  final List<String> aiRecommendations;
  final DateTime? createdAt;

  const GrowthRecordModel({
    required this.id,
    required this.childId,
    required this.date,
    required this.weightKg,
    required this.heightCm,
    this.headCircumferenceCm,
    required this.zScoreHeightForAge,
    required this.zScoreWeightForAge,
    required this.status,
    this.aiDescription,
    this.aiRecommendations = const [],
    this.createdAt,
  });

  factory GrowthRecordModel.fromMap(String id, Map<String, dynamic> map) {
    return GrowthRecordModel(
      id: id,
      childId: map['childId'] as String? ?? '',
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0.0,
      heightCm: (map['heightCm'] as num?)?.toDouble() ?? 0.0,
      headCircumferenceCm: (map['headCircumferenceCm'] as num?)?.toDouble(),
      zScoreHeightForAge:
          (map['zScoreHeightForAge'] as num?)?.toDouble() ?? 0.0,
      zScoreWeightForAge:
          (map['zScoreWeightForAge'] as num?)?.toDouble() ?? 0.0,
      status: GrowthStuntingStatus.fromString(
        map['status'] as String? ?? 'normal',
      ),
      aiDescription: map['aiDescription'] as String?,
      aiRecommendations:
          (map['aiRecommendations'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'childId': childId,
      'date': date.toIso8601String(),
      'weightKg': weightKg,
      'heightCm': heightCm,
      'headCircumferenceCm': headCircumferenceCm,
      'zScoreHeightForAge': zScoreHeightForAge,
      'zScoreWeightForAge': zScoreWeightForAge,
      'status': status.name,
      'aiDescription': aiDescription,
      'aiRecommendations': aiRecommendations,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }
}
