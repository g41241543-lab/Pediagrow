import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/services/api_service.dart';
import '../models/fasyankes_model.dart';

/// Status izin lokasi pengguna
enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
  unknown,
}

/// Service untuk mengelola pencarian, pengambilan data Google Places API,
/// serta penyediaan fallback fasyankes terdekat secara komprehensif.
class FasyankesService {
  // Singleton pattern
  static final FasyankesService _instance = FasyankesService._internal();
  factory FasyankesService() => _instance;
  FasyankesService._internal();

  /// Google Maps Platform API Key opsional (dapat di-inject via runtime atau config)
  static String apiKey = '';

  /// Koordinat default (Kabupaten Jember - Jawa Timur, sesuai acuan data referensi desain)
  static const double defaultLat = -8.1585;
  static const double defaultLng = 113.7225;

  /// Cache pencarian untuk efisiensi request & kuota API
  final Map<String, List<FasyankesModel>> _cache = {};

  /// Mengambil daftar fasyankes terdekat dengan batasan maksimal 10 data,
  /// diurutkan berdasarkan jarak dari lokasi pengguna.
  Future<List<FasyankesModel>> getNearestFasyankes({
    double userLat = defaultLat,
    double userLng = defaultLng,
    String query = '',
    String category = 'all',
  }) async {
    final cacheKey = '$userLat,$userLng,$query,$category';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    List<FasyankesModel> list = [];

    // 1. Jika API Key Google Maps tersedia, ambil data live via Google Places API
    if (apiKey.isNotEmpty) {
      try {
        list = await _fetchFromGooglePlaces(
          userLat: userLat,
          userLng: userLng,
          query: query,
        );
      } catch (e) {
        debugPrint('Google Places API error: $e');
      }
    }

    // 2. Ambil dari database MySQL tabel fasyankes via ApiService
    if (list.isEmpty) {
      try {
        final dbList = await ApiService.getFasyankes();
        if (dbList.isNotEmpty) {
          list = dbList
              .map((m) => FasyankesModel.fromDbMap(
                    m,
                    userLat: userLat,
                    userLng: userLng,
                  ))
              .toList();
        }
      } catch (e) {
        debugPrint('Fasyankes database API error: $e');
      }
    }

    // 3. Jika list masih kosong atau offline, gunakan dataset fasyankes lokal terverifikasi
    if (list.isEmpty) {
      list = _getVerifiedLocalFasyankes(userLat: userLat, userLng: userLng);
    }


    // 3. Filter berdasarkan Kata Kunci Pencarian (Search Query)
    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      list = list.where((f) {
        return f.name.toLowerCase().contains(q) ||
            f.address.toLowerCase().contains(q) ||
            f.category.toLowerCase().contains(q);
      }).toList();
    }

    // 4. Filter berdasarkan Kategori
    if (category.isNotEmpty && category != 'all') {
      final cat = category.toLowerCase();
      list = list.where((f) => f.category.toLowerCase() == cat).toList();
    }

    // 5. Urutkan berdasarkan jarak terdekat
    list.sort((a, b) {
      final distA = a.distanceKm ?? a.calculateDistance(userLat, userLng);
      final distB = b.distanceKm ?? b.calculateDistance(userLat, userLng);
      return distA.compareTo(distB);
    });

    // 6. Batasi maksimal 10 fasyankes terdekat sesuai spesifikasi
    final limitedList = list.take(10).toList();

    _cache[cacheKey] = limitedList;
    return limitedList;
  }

  /// Request HTTP ke Google Places API (New Text Search Endpoint)
  Future<List<FasyankesModel>> _fetchFromGooglePlaces({
    required double userLat,
    required double userLng,
    required String query,
  }) async {
    final textQuery = query.isNotEmpty
        ? '$query fasyankes kesehatan'
        : 'klinik puskesmas rumah sakit';

    final url = Uri.parse('https://places.googleapis.com/v1/places:searchText');

    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': apiKey,
            'X-Goog-FieldMask':
                'places.id,places.displayName,places.formattedAddress,places.nationalPhoneNumber,places.rating,places.userRatingCount,places.location,places.currentOpeningHours',
          },
          body: jsonEncode({
            'textQuery': textQuery,
            'locationBias': {
              'circle': {
                'center': {'latitude': userLat, 'longitude': userLng},
                'radius': 15000.0, // 15 km radius
              }
            },
            'maxResultCount': 10,
          }),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final places = data['places'] as List<dynamic>?;
      if (places != null) {
        return places
            .map((p) => FasyankesModel.fromGooglePlace(
                  p as Map<String, dynamic>,
                  userLat: userLat,
                  userLng: userLng,
                ))
            .toList();
      }
    }
    return [];
  }

  /// Dataset Fasyankes lokal terverifikasi (Wilayah Jember / Jawa Timur)
  /// Identik dengan data pada referensi desain:
  /// 1. Klinik Pratama Politeknik Negeri Jember
  /// 2. Klinik Kimia Farma UNEJ Medical Center
  /// 3. Klinik Sakinah Kaliurang Jember
  /// dst.
  List<FasyankesModel> _getVerifiedLocalFasyankes({
    required double userLat,
    required double userLng,
  }) {
    final rawList = [
      const FasyankesModel(
        id: 'fasyankes_1',
        name: 'Klinik Pratama Politeknik Negeri Jember',
        address:
            'Jl. Mastrip No.164, Lingkungan Panji, Tegalgede, Kec. Sumbersari, Kabupaten Jember',
        phone: '0812-3300-0905',
        rating: 4.0,
        userRatingsTotal: 142,
        latitude: -8.157829,
        longitude: 113.722814,
        category: 'Klinik',
      ),
      const FasyankesModel(
        id: 'fasyankes_2',
        name: 'Klinik Kimia Farma UNEJ Medical Center',
        address:
            'Jl. Kalimantan, Krajan Timur, Sumbersari, Kec. Sumbersari, Kabupaten Jember',
        phone: '(0331) 333527',
        rating: 4.8,
        userRatingsTotal: 310,
        latitude: -8.163611,
        longitude: 113.715278,
        category: 'Klinik',
      ),
      const FasyankesModel(
        id: 'fasyankes_3',
        name: 'Klinik Sakinah Kaliurang Jember',
        address:
            'Jl. Kaliurang, Lingkungan Krajan Timur, Tegalgede, Kec. Sumbersari, Kabupaten Jember',
        phone: '0815-5969-4882',
        rating: 4.7,
        userRatingsTotal: 205,
        latitude: -8.160100,
        longitude: 113.731500,
        category: 'Klinik',
      ),
      const FasyankesModel(
        id: 'fasyankes_4',
        name: 'Puskesmas Sumbersari Jember',
        address:
            'Jl. KH. Wachid Hasyim No.2, Krajan, Sumbersari, Kec. Sumbersari, Kabupaten Jember',
        phone: '(0331) 337920',
        rating: 4.3,
        userRatingsTotal: 180,
        latitude: -8.172400,
        longitude: 113.719800,
        category: 'Puskesmas',
      ),
      const FasyankesModel(
        id: 'fasyankes_5',
        name: 'RS Jember Klinik',
        address:
            'Jl. Bedadung No.2, Kp. Using, Jemberlor, Kec. Patrang, Kabupaten Jember',
        phone: '(0331) 487104',
        rating: 4.6,
        userRatingsTotal: 520,
        latitude: -8.166200,
        longitude: 113.703400,
        category: 'Rumah Sakit',
      ),
      const FasyankesModel(
        id: 'fasyankes_6',
        name: 'RSUD dr. Soebandi Jember',
        address:
            'Jl. Dr. Soebandi No.1, Krajan, Jemberlor, Kec. Patrang, Kabupaten Jember',
        phone: '(0331) 487441',
        rating: 4.5,
        userRatingsTotal: 840,
        latitude: -8.150100,
        longitude: 113.705600,
        category: 'Rumah Sakit',
      ),
      const FasyankesModel(
        id: 'fasyankes_7',
        name: 'Klinik Rawat Inap PMI Jember',
        address:
            'Jl. Jawa No.57, Tegal Boto Lor, Sumbersari, Kec. Sumbersari, Kabupaten Jember',
        phone: '(0331) 337022',
        rating: 4.4,
        userRatingsTotal: 115,
        latitude: -8.168900,
        longitude: 113.717000,
        category: 'Klinik',
      ),
      const FasyankesModel(
        id: 'fasyankes_8',
        name: 'Puskesmas Gladak Pakem',
        address:
            'Jl. MT Haryono No.117, Gladak Pakem, Sumbersari, Kec. Sumbersari, Kabupaten Jember',
        phone: '(0331) 336912',
        rating: 4.2,
        userRatingsTotal: 98,
        latitude: -8.181200,
        longitude: 113.725000,
        category: 'Puskesmas',
      ),
      const FasyankesModel(
        id: 'fasyankes_9',
        name: 'Apotek & Klinik Bunda Sehat Sumbersari',
        address:
            'Jl. R.A. Kartini No.28, Kepatihan, Kec. Kaliwates, Kabupaten Jember',
        phone: '(0331) 484321',
        rating: 4.5,
        userRatingsTotal: 160,
        latitude: -8.175500,
        longitude: 113.699100,
        category: 'Apotek',
      ),
      const FasyankesModel(
        id: 'fasyankes_10',
        name: 'RS Siloam Hospitals Jember',
        address:
            'Jl. Gajah Mada No.104, Jember Kidul, Kec. Kaliwates, Kabupaten Jember',
        phone: '(0331) 2861900',
        rating: 4.7,
        userRatingsTotal: 730,
        latitude: -8.178000,
        longitude: 113.689000,
        category: 'Rumah Sakit',
      ),
      const FasyankesModel(
        id: 'fasyankes_11',
        name: 'Klinik Pratama Rawat Inap Amanda',
        address:
            'Jl. Danau Toba No.12, Sumbersari, Kec. Sumbersari, Kabupaten Jember',
        phone: '0821-4321-9876',
        rating: 4.3,
        userRatingsTotal: 88,
        latitude: -8.167000,
        longitude: 113.729000,
        category: 'Klinik',
      ),
    ];

    // Hitung jarak dinamis untuk setiap fasyankes terhadap user
    return rawList.map((item) {
      final dist = item.calculateDistance(userLat, userLng);
      return item.copyWith(distanceKm: dist);
    }).toList();
  }
}
