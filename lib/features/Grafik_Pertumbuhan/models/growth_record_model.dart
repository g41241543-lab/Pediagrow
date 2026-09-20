/// Model data untuk satu entri catatan pertumbuhan anak pada grafik dan riwayat KMS.
class GrowthRecordModel {
  final String id;
  final String childId;
  final DateTime date;
  final int ageMonths;
  final int ageDays;
  final String ageFormatted;
  final double weightKg;
  final double heightCm;
  final double headCircumferenceCm;
  final double zScoreWeightForAge;
  final double zScoreHeightForAge;
  final double zScoreHeadForAge;
  final double zScoreWeightForHeight;
  final String statusGizi; // 'Gizi Normal' atau 'Gizi Buruk'
  final bool isBirthRecord;
  final String? notes;

  const GrowthRecordModel({
    required this.id,
    required this.childId,
    required this.date,
    required this.ageMonths,
    required this.ageDays,
    required this.ageFormatted,
    required this.weightKg,
    required this.heightCm,
    required this.headCircumferenceCm,
    this.zScoreWeightForAge = 0.0,
    this.zScoreHeightForAge = 0.0,
    this.zScoreHeadForAge = 0.0,
    this.zScoreWeightForHeight = 0.0,
    this.statusGizi = 'Gizi Normal',
    this.isBirthRecord = false,
    this.notes,
  });

  /// Factory dari Map/JSON (Mendukung MySQL dan local schema)
  factory GrowthRecordModel.fromMap(Map<String, dynamic> map) {
    final rawDate = map['date'] ?? map['tanggal'];
    final parsedDate = rawDate != null
        ? (DateTime.tryParse(rawDate.toString()) ?? DateTime.now())
        : DateTime.now();

    return GrowthRecordModel(
      id: map['id']?.toString() ?? '',
      childId: (map['child_id'] ?? map['id_anak'])?.toString() ?? '',
      date: parsedDate,
      ageMonths: (map['age_months'] as num?)?.toInt() ?? 0,
      ageDays: (map['age_days'] as num?)?.toInt() ?? 0,
      ageFormatted: map['age_formatted']?.toString() ?? '0 bulan 0 hari',
      weightKg: double.tryParse(map['weight_kg']?.toString() ?? map['berat_kg']?.toString() ?? '0') ?? 0.0,
      heightCm: double.tryParse(map['height_cm']?.toString() ?? map['tinggi_cm']?.toString() ?? '0') ?? 0.0,
      headCircumferenceCm: double.tryParse(map['head_circumference_cm']?.toString() ?? map['lingkar_kepala_cm']?.toString() ?? '0') ?? 0.0,
      zScoreWeightForAge: double.tryParse(map['z_score_weight_for_age']?.toString() ?? map['z_score_bb_u']?.toString() ?? '0') ?? 0.0,
      zScoreHeightForAge: double.tryParse(map['z_score_height_for_age']?.toString() ?? map['z_score_tb_u']?.toString() ?? '0') ?? 0.0,
      zScoreHeadForAge: double.tryParse(map['z_score_head_for_age']?.toString() ?? '0') ?? 0.0,
      zScoreWeightForHeight: double.tryParse(map['z_score_weight_for_height']?.toString() ?? map['z_score_bb_tb']?.toString() ?? '0') ?? 0.0,
      statusGizi: (map['status_gizi'] ?? map['status_stunting'] ?? 'Gizi Normal').toString(),
      isBirthRecord: map['is_birth_record'] == true || map['is_birth_record'] == 1,
      notes: map['notes']?.toString() ?? map['hasil_prediksi_ai']?.toString(),
    );
  }



  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'child_id': childId,
      'date': date.toIso8601String(),
      'age_months': ageMonths,
      'age_days': ageDays,
      'age_formatted': ageFormatted,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'head_circumference_cm': headCircumferenceCm,
      'z_score_weight_for_age': zScoreWeightForAge,
      'z_score_height_for_age': zScoreHeightForAge,
      'z_score_head_for_age': zScoreHeadForAge,
      'z_score_weight_for_height': zScoreWeightForHeight,
      'status_gizi': statusGizi,
      'is_birth_record': isBirthRecord ? 1 : 0,
      'notes': notes,
    };
  }

  GrowthRecordModel copyWith({
    String? id,
    String? childId,
    DateTime? date,
    int? ageMonths,
    int? ageDays,
    String? ageFormatted,
    double? weightKg,
    double? heightCm,
    double? headCircumferenceCm,
    double? zScoreWeightForAge,
    double? zScoreHeightForAge,
    double? zScoreHeadForAge,
    double? zScoreWeightForHeight,
    String? statusGizi,
    bool? isBirthRecord,
    String? notes,
  }) {
    return GrowthRecordModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      date: date ?? this.date,
      ageMonths: ageMonths ?? this.ageMonths,
      ageDays: ageDays ?? this.ageDays,
      ageFormatted: ageFormatted ?? this.ageFormatted,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      headCircumferenceCm: headCircumferenceCm ?? this.headCircumferenceCm,
      zScoreWeightForAge: zScoreWeightForAge ?? this.zScoreWeightForAge,
      zScoreHeightForAge: zScoreHeightForAge ?? this.zScoreHeightForAge,
      zScoreHeadForAge: zScoreHeadForAge ?? this.zScoreHeadForAge,
      zScoreWeightForHeight:
          zScoreWeightForHeight ?? this.zScoreWeightForHeight,
      statusGizi: statusGizi ?? this.statusGizi,
      isBirthRecord: isBirthRecord ?? this.isBirthRecord,
      notes: notes ?? this.notes,
    );
  }
}
