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
  final List<String> placesOfPractice;
  final int consultationFee;
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
    this.placesOfPractice = const [],
    this.consultationFee = 35000,
    this.isOnline = true,
  });

  /// Daftar tempat praktik dokter (fallback ke field hospital jika list kosong)
  List<String> get daftarTempatPraktik {
    if (placesOfPractice.isNotEmpty) {
      return placesOfPractice;
    }
    if (hospital != null && hospital!.trim().isNotEmpty) {
      return [hospital!];
    }
    return const ['Klinik Ramah Anak PediaGrow'];
  }

  /// Factory untuk membuat DoctorModel dari Map / JSON backend.
  factory DoctorModel.fromMap(Map<String, dynamic> map) {
    List<String> places = [];
    if (map['places_of_practice'] is List) {
      places = (map['places_of_practice'] as List)
          .map((e) => e.toString())
          .toList();
    } else if (map['tempat_praktik'] is List) {
      places = (map['tempat_praktik'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return DoctorModel(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      specialization: map['specialization'] ?? 'Spesialis Anak',
      avatarUrl: map['avatar_url'],
      assetImagePath: map['asset_image_path'],
      experienceYears: (map['experience_years'] as num?)?.toInt() ?? 0,
      strNumber: map['str_number'],
      hospital: map['hospital'],
      placesOfPractice: places,
      consultationFee: (map['consultation_fee'] as num?)?.toInt() ?? 35000,
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
      'places_of_practice': placesOfPractice,
      'consultation_fee': consultationFee,
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
          placesOfPractice: [
            'RSD dr. Soebandi Jember',
            'IHC RS Perkebunan Jember Klinik',
            'Praktek Mandiri',
          ],
          consultationFee: 50000,
          isOnline: true,
        ),
        DoctorModel(
          id: 'doc-2',
          name: 'dr. B. Gebyar Tri Baskoro, Sp.A',
          specialization: 'Spesialis Anak',
          experienceYears: 20,
          strNumber: '3511201402018891',
          hospital: 'RS Bina Sehat Jember',
          placesOfPractice: [
            'RS Bina Sehat Jember',
            'Klinik Rawat Inap Utama PediaGrow',
          ],
          consultationFee: 45000,
          isOnline: true,
        ),
        DoctorModel(
          id: 'doc-3',
          name: 'dr. M. Ali Shodikin, Sp.A, M. Kes',
          specialization: 'Spesialis Anak',
          experienceYears: 12,
          strNumber: '3511201402017734',
          hospital: 'RS Citra Husada Jember',
          placesOfPractice: [
            'RS Citra Husada Jember',
            'Fakultas Kedokteran Universitas Jember',
          ],
          consultationFee: 40000,
          isOnline: true,
        ),
        DoctorModel(
          id: 'doc-4',
          name: 'dr. Ririn Esterina, Sp.A',
          specialization: 'Spesialis Anak',
          assetImagePath: 'assets/images/doctor_ririn.png',
          experienceYears: 9,
          strNumber: '3511201402019943',
          hospital: 'Klinik Tumbuh Kembang PediaGrow',
          placesOfPractice: [
            'Klinik Tumbuh Kembang PediaGrow',
            'RS Siloam Jember',
          ],
          consultationFee: 35000,
          isOnline: true,
        ),
        DoctorModel(
          id: 'doc-5',
          name: 'dr. Devina Marchita Inge S, Sp.A',
          specialization: 'Spesialis Anak',
          experienceYears: 6,
          strNumber: '3511201402021102',
          hospital: 'RS Jember Klinik',
          placesOfPractice: [
            'RS Jember Klinik',
            'Puskesmas Sumbersari',
          ],
          consultationFee: 35000,
          isOnline: true,
        ),
      ];

  /// Dokter default untuk fallback jika data tidak disertakan
  static DoctorModel get defaultDoctor => dummyList[3]; // dr. Ririn Esterina, Sp.A
}
