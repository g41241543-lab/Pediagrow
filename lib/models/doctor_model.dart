import 'doctor_permissions.dart';

/// Model data untuk profil dokter pada fitur konsultasi PediaGrow.
///
/// Data dokter ditentukan oleh Superadmin dan disimpan di Firestore.
/// DoctorModel merepresentasikan data dokter yang berasal dari Firestore.
class DoctorModel {
  /// ID dokumen dokter di Firestore.
  final String id;

  /// Nama lengkap dokter.
  final String name;

  /// Spesialisasi dokter.
  final String specialization;

  /// URL foto dokter dari storage/cloud atau path file lokal.
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

  /// Email dokter untuk kontak & akun staff login
  final String? email;

  /// Hak akses dokter yang diatur superadmin
  final Map<String, bool> permissions;

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
    this.email,
    this.permissions = const {},
  });

  /// Mengambil daftar tempat praktik dokter.
  ///
  /// Prioritas:
  /// 1. placesOfPractice jika tersedia.
  /// 2. hospital jika placesOfPractice kosong.
  /// 3. List kosong jika keduanya tidak tersedia.
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
    // Fallback jika data lama menggunakan nama field 'tempat_praktik'.
    else if (map['tempat_praktik'] is List) {
      places = (map['tempat_praktik'] as List)
          .map((item) => item.toString())
          .toList();
    }

    Map<String, bool> parsedPermissions = {};
    if (map['permissions'] is Map) {
      parsedPermissions = (map['permissions'] as Map).map(
        (key, value) => MapEntry(key.toString(), value == true),
      );
    } else if (map['hak_akses'] is Map) {
      parsedPermissions = (map['hak_akses'] as Map).map(
        (key, value) => MapEntry(key.toString(), value == true),
      );
    } else {
      parsedPermissions = DoctorPermissions.defaultPermissions;
    }

    return DoctorModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      specialization: map['specialization']?.toString() ?? 'Spesialis Anak',
      avatarUrl: map['avatar_url']?.toString(),
      assetImagePath: map['asset_image_path']?.toString(),
      experienceYears: (map['experience_years'] as num?)?.toInt() ?? 0,
      strNumber: map['str_number']?.toString(),
      hospital: map['hospital']?.toString(),
      placesOfPractice: places,
      consultationFee: (map['consultation_fee'] as num?)?.toInt() ?? 0,
      isOnline: map['is_online'] as bool? ?? true,
      staffAccountId: map['staff_account_id']?.toString() ?? '',
      email: map['email']?.toString(),
      permissions: parsedPermissions,
    );
  }

  /// Mengubah DoctorModel menjadi Map untuk Firestore.
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
      'email': email,
      'permissions': permissions,
    };
  }

  DoctorModel copyWith({
    String? id,
    String? name,
    String? specialization,
    String? avatarUrl,
    String? assetImagePath,
    int? experienceYears,
    String? strNumber,
    String? hospital,
    List<String>? placesOfPractice,
    int? consultationFee,
    bool? isOnline,
    String? staffAccountId,
    String? email,
    Map<String, bool>? permissions,
  }) {
    return DoctorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      specialization: specialization ?? this.specialization,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      assetImagePath: assetImagePath ?? this.assetImagePath,
      experienceYears: experienceYears ?? this.experienceYears,
      strNumber: strNumber ?? this.strNumber,
      hospital: hospital ?? this.hospital,
      placesOfPractice: placesOfPractice ?? this.placesOfPractice,
      consultationFee: consultationFee ?? this.consultationFee,
      isOnline: isOnline ?? this.isOnline,
      staffAccountId: staffAccountId ?? this.staffAccountId,
      email: email ?? this.email,
      permissions: permissions ?? this.permissions,
    );
  }

  /// Dokter default untuk fallback jika data dokter tidak disertakan
  static const DoctorModel defaultDoctor = DoctorModel(
    id: 'doc-default',
    name: 'dr. Ririn Esterina, Sp.A',
    specialization: 'Spesialis Anak',
    assetImagePath: 'assets/images/doctor_ririn.png',
    experienceYears: 9,
    strNumber: '3321201320131150',
    hospital: 'RS Citra Husada Jember',
    placesOfPractice: [
      'RS Citra Husada Jember',
      'IHC RS Perkebunan Jember Klinik',
      'Praktek Mandiri',
    ],
    consultationFee: 35000,
    isOnline: true,
    email: 'drririnesterina@gmail.com',
  );
}
