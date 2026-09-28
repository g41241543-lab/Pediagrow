/// Model data untuk profil dokter pada fitur konsultasi PediaGrow.
///
/// Data dokter ditentukan oleh Superadmin dan disimpan di Firestore.
/// DoctorModel hanya bertugas merepresentasikan data dokter yang
/// berasal dari Firestore.
class DoctorModel {
  /// ID dokumen dokter di Firestore.
  final String id;

  /// Nama lengkap dokter.
  final String name;

  /// Spesialisasi dokter.
  final String specialization;

  /// URL foto dokter dari storage/cloud.
  final String? avatarUrl;

  /// Path gambar dokter jika menggunakan asset aplikasi.
  final String? assetImagePath;

  /// Jumlah tahun pengalaman dokter.
  final int experienceYears;

  /// Nomor STR dokter.
  final String? strNumber;

  /// Rumah sakit utama tempat dokter praktik.
  final String? hospital;

  /// Daftar tempat praktik dokter.
  final List<String> placesOfPractice;

  /// Biaya konsultasi dokter.
  final int consultationFee;

  /// Status online dokter.
  final bool isOnline;

  /// ID akun staff dokter.
  final String staffAccountId;

  const DoctorModel({
    required this.id,
    required this.name,
    this.specialization = 'Spesialis Anak',
    this.avatarUrl,
    this.assetImagePath,
    this.experienceYears = 0,
    this.strNumber,
    this.hospital,
    this.placesOfPractice = const [],
    this.consultationFee = 0,
    this.isOnline = true,
    this.staffAccountId = '',
  });

  /// Mengambil daftar tempat praktik dokter.
  ///
  /// Prioritas:
  /// 1. placesOfPractice jika tersedia.
  /// 2. hospital jika placesOfPractice kosong.
  /// 3. List kosong jika keduanya tidak tersedia.
  ///
  /// Tidak menggunakan data dokter default/dummy.
  List<String> get daftarTempatPraktik {
    if (placesOfPractice.isNotEmpty) {
      return placesOfPractice;
    }

    if (hospital != null && hospital!.trim().isNotEmpty) {
      return [hospital!];
    }

    return const [];
  }

  /// Membuat DoctorModel dari data Map/Firestore.
  factory DoctorModel.fromMap(Map<String, dynamic> map) {
    List<String> places = [];

    // Format utama dari Firestore.
    if (map['places_of_practice'] is List) {
      places = (map['places_of_practice'] as List)
          .map((item) => item.toString())
          .toList();
    }

    // Fallback jika data lama menggunakan nama field
    // 'tempat_praktik'.
    else if (map['tempat_praktik'] is List) {
      places = (map['tempat_praktik'] as List)
          .map((item) => item.toString())
          .toList();
    }

    return DoctorModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      specialization:
          map['specialization']?.toString() ?? '',
      avatarUrl:
          map['avatar_url']?.toString(),
      assetImagePath:
          map['asset_image_path']?.toString(),
      experienceYears:
          (map['experience_years'] as num?)?.toInt() ?? 0,
      strNumber:
          map['str_number']?.toString(),
      hospital:
          map['hospital']?.toString(),
      placesOfPractice:
          places,
      consultationFee:
          (map['consultation_fee'] as num?)?.toInt() ?? 0,
      isOnline:
          map['is_online'] as bool? ?? false,
      staffAccountId:
          map['staff_account_id']?.toString() ?? '',
    );
  }

  /// Mengubah DoctorModel menjadi Map untuk Firestore.
  ///
  /// ID dokumen tidak dimasukkan ke Map karena ketika dokter
  /// dibuat melalui DoctorService, Firestore menggunakan
  /// document ID-nya sendiri.
  Map<String, dynamic> toMap() {
    return {
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
      'staff_account_id': staffAccountId,
    };
  }

  /// Dokter default untuk fallback jika data dokter tidak disertakan
  static const DoctorModel defaultDoctor = DoctorModel(
    id: 'doc-default',
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
  );
}
