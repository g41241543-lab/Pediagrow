/// Model data untuk profil dokter pada fitur konsultasi PediaGrow.
class DoctorModel {
  final String id;
  final String name;
  final String specialization;
  final String? avatarUrl;
  final String? assetImagePath;
  final int experienceYears;
  final String? strNumber;
  final String? hospital;
  final bool isOnline;

  const DoctorModel({
    required this.id,
    required this.name,
    this.specialization = 'Spesialis Anak',
    this.avatarUrl,
    this.assetImagePath,
    this.experienceYears = 5,
    this.strNumber,
    this.hospital,
    this.isOnline = true,
  });

  /// Factory untuk membuat DoctorModel dari Map / JSON backend.
  factory DoctorModel.fromMap(Map<String, dynamic> map) {
    return DoctorModel(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      specialization: map['specialization'] ?? 'Spesialis Anak',
      avatarUrl: map['avatar_url'],
      assetImagePath: map['asset_image_path'],
      experienceYears: (map['experience_years'] as num?)?.toInt() ?? 0,
      strNumber: map['str_number'],
      hospital: map['hospital'],
      isOnline: map['is_online'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'specialization': specialization,
      'avatar_url': avatarUrl,
      'asset_image_path': assetImagePath,
      'experience_years': experienceYears,
      'str_number': strNumber,
      'hospital': hospital,
      'is_online': isOnline,
    };
  }

  /// Daftar dokter default sesuai acuan desain Konsul PediaGrow.
  static List<DoctorModel> get dummyList => const [
        DoctorModel(
          id: 'doc-1',
          name: 'dr. Ahmad Nuri, Sp. A',
          specialization: 'Spesialis Anak',
          assetImagePath: 'assets/images/doctor_ahmad_nuri.png',
          experienceYears: 35,
          strNumber: '3511201402016252',
          hospital: 'RSD dr. Soebandi Jember',
          isOnline: true,
        ),
        DoctorModel(
          id: 'doc-2',
          name: 'dr. B. Gebyar Tri Baskoro, Sp.A',
          specialization: 'Spesialis Anak',
          experienceYears: 20,
          isOnline: true,
        ),
        DoctorModel(
          id: 'doc-3',
          name: 'dr. M. Ali Shodikin, Sp.A, M. Kes',
          specialization: 'Spesialis Anak',
          experienceYears: 12,
          isOnline: true,
        ),
        DoctorModel(
          id: 'doc-4',
          name: 'dr. Ririn Esterina, Sp.A',
          specialization: 'Spesialis Anak',
          assetImagePath: 'assets/images/doctor_ririn.png',
          experienceYears: 9,
          isOnline: true,
        ),
        DoctorModel(
          id: 'doc-5',
          name: 'dr. Devina Marchita Inge S, Sp.A',
          specialization: 'Spesialis Anak',
          experienceYears: 6,
          isOnline: true,
        ),
      ];

  /// Dokter default untuk fallback jika data tidak disertakan
  static DoctorModel get defaultDoctor => dummyList[3]; // dr. Ririn Esterina, Sp.A
}
