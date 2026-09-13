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
