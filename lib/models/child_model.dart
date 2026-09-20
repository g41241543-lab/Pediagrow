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
  /// Factory dari Map/JSON (Mendukung skema MySQL dan model lokal)
  factory ChildModel.fromMap(Map<String, dynamic> map) {
    final rawBirth = map['birth_date'] ?? map['tanggal_lahir'];
    final parsedBirth = rawBirth != null ? DateTime.tryParse(rawBirth.toString()) : null;

    String desc = map['age_description'] ?? '';
    if (desc.isEmpty && parsedBirth != null) {
      final now = DateTime.now();
      final diffDays = now.difference(parsedBirth).inDays;
      final years = diffDays ~/ 365;
      final months = (diffDays % 365) ~/ 30;
      final days = (diffDays % 365) % 30;
      if (years > 0) {
        desc = '$years tahun $months bulan $days hari';
      } else if (months > 0) {
        desc = '$months bulan $days hari';
      } else {
        desc = '$days hari';
      }
    }
    if (desc.isEmpty) desc = '1 tahun 3 bulan 3 hari';

    final rawGender = map['gender'] ?? map['jenis_kelamin'];
    String genderStr = 'Perempuan';
    if (rawGender != null) {
      final g = rawGender.toString().trim().toUpperCase();
      if (g == 'L' || g == 'LAKI-LAKI') {
        genderStr = 'Laki-laki';
      } else {
        genderStr = 'Perempuan';
      }
    }

    final rawWeight = map['weight_kg'] ?? map['berat_lahir_kg'];
    final parsedWeight = rawWeight != null ? double.tryParse(rawWeight.toString()) : null;

    final rawHeight = map['height_cm'];
    final parsedHeight = rawHeight != null ? double.tryParse(rawHeight.toString()) : null;

    final rawHead = map['head_circumference_cm'];
    final parsedHead = rawHead != null ? double.tryParse(rawHead.toString()) : null;

    return ChildModel(
      id: map['id']?.toString() ?? '',
      name: (map['name'] ?? map['nama'] ?? '').toString(),
      gender: genderStr,
      ageDescription: desc,
      birthDate: parsedBirth,
      weightKg: parsedWeight,
      heightCm: parsedHeight,
      headCircumferenceCm: parsedHead,
      photoUrl: (map['photo_url'] ?? map['foto_url'] ?? map['avatar'])?.toString(),
      birthPhotoUrl: map['birth_photo_url']?.toString(),
      isPremature: map['is_premature'] == null
          ? null
          : (map['is_premature'] == 1 || map['is_premature'] == true || map['is_premature'] == '1'),
      gestationalAgeWeeks: (map['gestational_age_weeks'] as num?)?.toInt(),
      hasAllergies: map['has_allergies'] == null
          ? null
          : (map['has_allergies'] == 1 || map['has_allergies'] == true || map['has_allergies'] == '1'),
      allergies: map['allergies']?.toString(),
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
