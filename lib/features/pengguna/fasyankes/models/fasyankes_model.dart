import 'dart:math' as math;

/// Model data Fasilitas Pelayanan Kesehatan (Fasyankes)
class FasyankesModel {
  final String id;
  final String name;
  final String address;
  final String phone;
  final double rating;
  final int userRatingsTotal;
  final double latitude;
  final double longitude;
  final String category; // 'Klinik', 'Puskesmas', 'Rumah Sakit', 'Apotek', dll.
  final bool isOpenNow;
  final double? distanceKm;

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
  });

  /// Salin objek dengan parameter yang diperbarui (misal: jarak yang dihitung)
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

  /// URL Google Maps: membuka lokasi dengan nama + koordinat sehingga akurat.
  /// Format `geo:lat,lng?q=lat,lng(NamaLokasi)` diprioritaskan untuk Android;
  /// fallback ke web Maps URL yang selalu berfungsi.
  String get googleMapsUrl {
    final encodedName = Uri.encodeComponent(name);
    // Format intent Android & iOS: membuka Maps dengan pin bernama pada koordinat tepat
    return 'https://www.google.com/maps/search/?api=1'
        '&query=$encodedName'
        '&query_place_id='
        '&center=$latitude,$longitude'
        // Sertakan koordinat dalam query agar pin jatuh di lokasi yang tepat
        '&query=$latitude,$longitude';
  }

  /// URL Maps yang lebih sederhana — langsung ke koordinat + label nama
  String get googleMapsDirectUrl {
    final encodedName = Uri.encodeComponent(name);
    return 'geo:$latitude,$longitude?q=$latitude,$longitude($encodedName)';
  }

  /// Parsing data dari database MySQL (Tabel fasyankes)
  factory FasyankesModel.fromDbMap(
    Map<String, dynamic> map, {
    double userLat = -8.1585,
    double userLng = 113.7225,
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
    );

    return model.copyWith(distanceKm: model.calculateDistance(userLat, userLng));
  }


  /// Parsing data dari Google Places API (baik format legacy maupun New Places API)
  factory FasyankesModel.fromGooglePlace(Map<String, dynamic> json, {double? userLat, double? userLng}) {

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
    final double rating = ((json['rating'] ?? 4.0) as num).toDouble();
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
    );

    if (userLat != null && userLng != null && lat != 0.0 && lng != 0.0) {
      return model.copyWith(distanceKm: model.calculateDistance(userLat, userLng));
    }

    return model;
  }
}
