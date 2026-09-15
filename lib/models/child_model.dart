/// Model data untuk anak pada aplikasi PediaGrow.
class ChildModel {
  final String id;
  final String name;
  final String gender; // 'Perempuan' atau 'Laki-laki'
  final String ageDescription; // e.g. '1 tahun 3 bulan 3 hari'
  final DateTime? birthDate;
  final double? weightKg;
  final double? heightCm;
  final double? headCircumferenceCm;
  final String? photoUrl;
  final String? birthPhotoUrl;
  final bool? isPremature;
  final int? gestationalAgeWeeks;
  final bool? hasAllergies;
  final String? allergies;

  const ChildModel({
    required this.id,
    required this.name,
    this.gender = 'Perempuan',
    this.ageDescription = '1 tahun 3 bulan 3 hari',
    this.birthDate,
    this.weightKg,
    this.heightCm,
    this.headCircumferenceCm,
    this.photoUrl,
    this.birthPhotoUrl,
    this.isPremature,
    this.gestationalAgeWeeks,
    this.hasAllergies,
    this.allergies,
  });

  /// Factory dari Map/JSON
  factory ChildModel.fromMap(Map<String, dynamic> map) {
    return ChildModel(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      gender: map['gender'] ?? 'Perempuan',
      ageDescription: map['age_description'] ?? '1 tahun 3 bulan 3 hari',
      birthDate: map['birth_date'] != null
          ? DateTime.tryParse(map['birth_date'])
          : null,
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      headCircumferenceCm: (map['head_circumference_cm'] as num?)?.toDouble(),
      photoUrl: map['photo_url'] ?? map['avatar'],
      birthPhotoUrl: map['birth_photo_url'],
      isPremature: map['is_premature'] == null
          ? null
          : (map['is_premature'] == 1 || map['is_premature'] == true),
      gestationalAgeWeeks: (map['gestational_age_weeks'] as num?)?.toInt(),
      hasAllergies: map['has_allergies'] == null
          ? null
          : (map['has_allergies'] == 1 || map['has_allergies'] == true),
      allergies: map['allergies'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'age_description': ageDescription,
      'birth_date': birthDate?.toIso8601String(),
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'head_circumference_cm': headCircumferenceCm,
      'photo_url': photoUrl,
      'birth_photo_url': birthPhotoUrl,
      'is_premature': isPremature == true ? 1 : (isPremature == false ? 0 : null),
      'gestational_age_weeks': gestationalAgeWeeks,
      'has_allergies': hasAllergies == true ? 1 : (hasAllergies == false ? 0 : null),
      'allergies': allergies,
    };
  }

  /// Data dummy anak default untuk fallback
  static const ChildModel defaultChild = ChildModel(
    id: 'child-default',
    name: 'Anak',
    gender: 'Perempuan',
    ageDescription: '1 tahun 3 bulan 3 hari',
    weightKg: 10.5,
    heightCm: 85.0,
  );
}
