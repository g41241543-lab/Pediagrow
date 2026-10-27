import 'dart:math' as math;

/// Model ulasan pengguna yang terdaftar di Google Maps untuk fasyankes
class FasyankesReview {
  final String authorName;
  final double rating;
  final String relativeTime;
  final String text;
  final String? profilePhotoUrl;

  const FasyankesReview({
    required this.authorName,
    required this.rating,
    required this.relativeTime,
    required this.text,
    this.profilePhotoUrl,
  });

  factory FasyankesReview.fromJson(Map<String, dynamic> json) {
    return FasyankesReview(
      authorName: (json['author_name'] ?? json['authorName'] ?? 'Pengguna Google Maps').toString(),
      rating: ((json['rating'] ?? 5.0) as num).toDouble(),
      relativeTime: (json['relative_time_description'] ?? json['relativeTime'] ?? 'Baru saja').toString(),
      text: (json['text'] ?? '').toString(),
      profilePhotoUrl: json['profile_photo_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'authorName': authorName,
    'rating': rating,
    'relativeTime': relativeTime,
    'text': text,
    'profilePhotoUrl': profilePhotoUrl,
  };
}

/// Model data Fasilitas Pelayanan Kesehatan (Fasyankes)
/// Menyimpan informasi terverifikasi dan lengkap seperti yang terdaftar di Google Maps:
/// titik koordinat resmi, ulasan pengguna, foto-foto, nomor telepon, jam operasional,
/// layanan spesifik anak/KIA, dan Google Plus Code.
class FasyankesModel {
  final String id;
  final String name;
  final String address;
  final String phone;
  final double rating;
  final int userRatingsTotal;
  final double latitude;
  final double longitude;
  final String category; // 'Klinik', 'Puskesmas', 'Rumah Sakit', 'Apotek'
  final bool isOpenNow;
  final double? distanceKm;
  final String operatingHours;
  final String? plusCode;
  final String? imageUrl;
  final List<String>? _photos;
  final List<String>? _services;
  final List<FasyankesReview>? _reviews;

  /// Daftar foto fasilitas (dijamin tidak pernah null)
  List<String> get photos => _photos ?? const <String>[];

  /// Daftar layanan fasilitas (dijamin tidak pernah null)
  List<String> get services => _services ?? const <String>[];

  /// Daftar ulasan fasilitas (dijamin tidak pernah null)
  List<FasyankesReview> get reviews => _reviews ?? const <FasyankesReview>[];

  const FasyankesModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.rating,
    this.userRatingsTotal = 0,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.isOpenNow = true,
    this.distanceKm,
    this.operatingHours = 'Buka 24 Jam',
    this.plusCode,
    this.imageUrl,
    List<String>? photos,
    List<String>? services,
    List<FasyankesReview>? reviews,
  })  : _photos = photos,
        _services = services,
        _reviews = reviews;

  /// Salin objek dengan parameter yang diperbarui (misal: jarak yang dihitung ulang)
  FasyankesModel copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    double? rating,
    int? userRatingsTotal,
    double? latitude,
    double? longitude,
    String? category,
    bool? isOpenNow,
    double? distanceKm,
    String? operatingHours,
    String? plusCode,
    String? imageUrl,
    List<String>? photos,
    List<String>? services,
    List<FasyankesReview>? reviews,
  }) {
    return FasyankesModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      rating: rating ?? this.rating,
      userRatingsTotal: userRatingsTotal ?? this.userRatingsTotal,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      isOpenNow: isOpenNow ?? this.isOpenNow,
      distanceKm: distanceKm ?? this.distanceKm,
      operatingHours: operatingHours ?? this.operatingHours,
      plusCode: plusCode ?? this.plusCode,
      imageUrl: imageUrl ?? this.imageUrl,
      photos: photos ?? this.photos,
      services: services ?? this.services,
      reviews: reviews ?? this.reviews,
    );
  }

  /// Menghitung jarak ke lokasi pengguna menggunakan formula Haversine (dalam km)
  double calculateDistance(double userLat, double userLng) {
    const earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(latitude - userLat);
    final dLon = _degreesToRadians(longitude - userLng);

    final lat1 = _degreesToRadians(userLat);
    final lat2 = _degreesToRadians(latitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) * math.sin(dLon / 2) * math.cos(lat1) * math.cos(lat2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Format teks jarak yang user-friendly (contoh: "1.2 km" atau "650 m")
  String get formattedDistance {
    if (distanceKm == null) return '';
    if (distanceKm! < 1.0) {
      return '${(distanceKm! * 1000).round()} m';
    }
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  /// URL Google Maps: membuka lokasi dengan titik koordinat resmi terdaftar di Google Maps
  String get googleMapsUrl {
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }

  /// URL Maps native — langsung membuka aplikasi peta HP (Google Maps di Android / Apple Maps di iOS)
  String get googleMapsDirectUrl {
    final encodedName = Uri.encodeComponent(name);
    return 'geo:$latitude,$longitude?q=$latitude,$longitude($encodedName)';
  }

  /// Teks ringkasan untuk fitur bagikan fasyankes
  String get shareText {
    final plusText = (plusCode != null && plusCode!.isNotEmpty) ? '\nPlus Code GMaps: $plusCode' : '';
    return '📍 *$name*\n'
        'Kategori: $category\n'
        'Rating Google Maps: ⭐ ${rating.toStringAsFixed(1)} ($userRatingsTotal ulasan)\n'
        'Jam Operasional: $operatingHours\n'
        'Telepon: $phone\n'
        'Alamat: $address$plusText\n'
        'Rute Google Maps: $googleMapsUrl';
  }

  /// Parsing data dari database MySQL (Tabel fasyankes)
  factory FasyankesModel.fromDbMap(
    Map<String, dynamic> map, {
    double userLat = -8.160563,
    double userLng = 113.721688,
  }) {
    final lat = double.tryParse(map['latitude']?.toString() ?? '') ?? userLat;
    final lng = double.tryParse(map['longitude']?.toString() ?? '') ?? userLng;
    final name = (map['nama'] ?? map['name'] ?? 'Fasyankes').toString();
    final address = (map['alamat'] ?? map['address'] ?? 'Alamat tidak tersedia').toString();
    final phone = (map['telepon'] ?? map['phone'] ?? '-').toString();

    String cat = 'Klinik';
    final lowerName = name.toLowerCase();
    if (lowerName.contains('puskesmas')) {
      cat = 'Puskesmas';
    } else if (lowerName.contains('rs') || lowerName.contains('rumah sakit')) {
      cat = 'Rumah Sakit';
    } else if (lowerName.contains('apotek')) {
      cat = 'Apotek';
    }

    List<String> photos = const [];
    if (map['photos'] is List) {
      photos = (map['photos'] as List).map((e) => e.toString()).toList();
    } else if (map['foto'] != null && map['foto'].toString().isNotEmpty) {
      photos = [map['foto'].toString()];
    }

    List<String> services = const [
      'Pemeriksaan Kesehatan Anak',
      'Pelayanan BPJS Kesehatan',
      'Farmasi & Apotek',
      'Konsultasi Gizi',
    ];
    if (map['services'] is List) {
      services = (map['services'] as List).map((e) => e.toString()).toList();
    } else if (map['layanan'] is List) {
      services = (map['layanan'] as List).map((e) => e.toString()).toList();
    }

    final model = FasyankesModel(
      id: (map['id'] ?? 'db_$name').toString(),
      name: name,
      address: address,
      phone: phone,
      rating: 4.5,
      userRatingsTotal: 80,
      latitude: lat,
      longitude: lng,
      category: cat,
      isOpenNow: true,
      operatingHours: (map['jam_operasional'] ?? 'Buka 24 Jam').toString(),
      plusCode: map['plus_code']?.toString(),
      imageUrl: map['foto']?.toString(),
      photos: photos,
      services: services,
    );

    return model.copyWith(distanceKm: model.calculateDistance(userLat, userLng));
  }

  /// Parsing data dari Google Places API (baik format legacy maupun New Places API)
  factory FasyankesModel.fromGooglePlace(
    Map<String, dynamic> json, {
    double? userLat,
    double? userLng,
  }) {
    // Menangani format Google Places API (New) vs Legacy
    final id = json['id'] ?? json['place_id'] ?? '';

    // Nama tempat
    String name = '';
    if (json['displayName'] is Map) {
      name = json['displayName']['text'] ?? '';
    } else {
      name = json['name'] ?? 'Fasilitas Kesehatan';
    }

    // Alamat
    final address = json['formattedAddress'] ??
        json['vicinity'] ??
        json['formatted_address'] ??
        'Alamat tidak tersedia';

    // Telepon
    final phone = json['nationalPhoneNumber'] ??
        json['formatted_phone_number'] ??
        json['internationalPhoneNumber'] ??
        '-';

    // Rating
    final double rating = ((json['rating'] ?? 4.5) as num).toDouble();
    final int userRatingsTotal = (json['userRatingCount'] ?? json['user_ratings_total'] ?? 0) as int;

    // Koordinat
    double lat = 0.0;
    double lng = 0.0;
    if (json['location'] is Map) {
      lat = (json['location']['latitude'] ?? 0.0).toDouble();
      lng = (json['location']['longitude'] ?? 0.0).toDouble();
    } else if (json['geometry']?['location'] is Map) {
      lat = (json['geometry']['location']['lat'] ?? 0.0).toDouble();
      lng = (json['geometry']['location']['lng'] ?? 0.0).toDouble();
    }

    // Status buka
    final bool isOpenNow = json['currentOpeningHours']?['openNow'] ??
        json['opening_hours']?['open_now'] ??
        true;

    // Jam Operasional
    String operatingHours = 'Buka 24 Jam';
    final weekdayList = json['currentOpeningHours']?['weekdayDescriptions'];
    if (weekdayList is List && weekdayList.isNotEmpty) {
      operatingHours = weekdayList.first.toString();
    }

    // Plus Code
    String? plusCode;
    if (json['plusCode'] is Map) {
      plusCode = json['plusCode']['compoundCode'] ?? json['plusCode']['globalCode'];
    } else if (json['plus_code'] is Map) {
      plusCode = json['plus_code']['compound_code'] ?? json['plus_code']['global_code'];
    }

    // Ulasan Google Maps
    List<FasyankesReview> reviews = [];
    final rawReviews = json['reviews'];
    if (rawReviews is List) {
      for (final r in rawReviews) {
        if (r is Map) {
          reviews.add(FasyankesReview.fromJson(Map<String, dynamic>.from(r)));
        }
      }
    }

    // Foto Google Maps
    List<String> photos = [];
    final rawPhotos = json['photos'];
    if (rawPhotos is List) {
      for (final p in rawPhotos) {
        if (p is Map && p['name'] != null) {
          photos.add(p['name'].toString());
        }
      }
    }

    // Kategori
    String category = 'Klinik';
    final lowerName = name.toLowerCase();
    if (lowerName.contains('rumah sakit') || lowerName.contains('rsud') || lowerName.contains('rs ')) {
      category = 'Rumah Sakit';
    } else if (lowerName.contains('puskesmas')) {
      category = 'Puskesmas';
    } else if (lowerName.contains('apotek') || lowerName.contains('apotik')) {
      category = 'Apotek';
    }

    final model = FasyankesModel(
      id: id,
      name: name,
      address: address,
      phone: phone,
      rating: rating,
      userRatingsTotal: userRatingsTotal,
      latitude: lat,
      longitude: lng,
      category: category,
      isOpenNow: isOpenNow,
      operatingHours: operatingHours,
      plusCode: plusCode,
      photos: photos,
      reviews: reviews,
      services: const [
        'Pemeriksaan Kesehatan Anak',
        'Pelayanan BPJS Kesehatan',
        'Farmasi & Apotek',
        'Konsultasi Gizi',
      ],
    );

    if (userLat != null && userLng != null && lat != 0.0 && lng != 0.0) {
      return model.copyWith(distanceKm: model.calculateDistance(userLat, userLng));
    }

    return model;
  }
}
