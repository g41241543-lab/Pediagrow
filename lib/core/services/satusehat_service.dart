import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Model data pasien sederhana hasil respons SATUSEHAT (FHIR Patient Resource)
class SatuSehatPatient {
  final String ihsNumber; // resource.id
  final String name; // resource.name[0].text
  final String? gender;
  final String? birthDate;
  final String? nik;
  final Map<String, dynamic> rawResource;

  const SatuSehatPatient({
    required this.ihsNumber,
    required this.name,
    this.gender,
    this.birthDate,
    this.nik,
    required this.rawResource,
  });

  factory SatuSehatPatient.fromFhirResource(Map<String, dynamic> res) {
    // 1. Ekstraksi nama lengkap
    String extractedName = '-';
    if (res['name'] is List && (res['name'] as List).isNotEmpty) {
      final nameObj = res['name'][0];
      if (nameObj is Map) {
        if (nameObj['text'] != null && nameObj['text'].toString().isNotEmpty) {
          extractedName = nameObj['text'].toString();
        } else if (nameObj['given'] is List) {
          final givenList = (nameObj['given'] as List).map((e) => e.toString()).toList();
          final family = nameObj['family']?.toString() ?? '';
          extractedName = [...givenList, if (family.isNotEmpty) family].join(' ');
        }
      }
    }

    // 2. Ekstraksi NIK dari array identifier
    String? extractedNik;
    if (res['identifier'] is List) {
      for (final id in res['identifier']) {
        if (id is Map && id['system'] == 'https://fhir.kemkes.go.id/id/nik') {
          extractedNik = id['value']?.toString();
          break;
        }
      }
    }

    return SatuSehatPatient(
      ihsNumber: res['id']?.toString() ?? '',
      name: extractedName,
      gender: res['gender']?.toString(),
      birthDate: res['birthDate']?.toString(),
      nik: extractedNik,
      rawResource: res,
    );
  }
}

/// Service komunikasi antara aplikasi mobile PediaGrow (Flutter)
/// dan backend SATUSEHAT proxy (satusehat-mobile-backend).
class SatuSehatService {
  /// APP_API_KEY dari .env backend
  static const String appApiKey = 'Pediagrow MIK 5C';

  /// IP Wi-Fi laptop untuk pengujian di HP Android fisik
  static const String defaultLaptopIp = '192.168.110.194';

  /// Ubah ke `true` jika Anda menguji di HP Android fisik via Wi-Fi.
  /// Biarkan `false` jika Anda menguji di Emulator Android Studio.
  static bool usePhysicalDevice = true;

  /// Mendapatkan Base URL backend sesuai platform running
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    try {
      if (Platform.isAndroid) {
        return usePhysicalDevice
            ? 'http://$defaultLaptopIp:3000'
            : 'http://10.0.2.2:3000';
      } else if (Platform.isIOS) {
        return 'http://localhost:3000';
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        return 'http://127.0.0.1:3000';
      }
    } catch (_) {}
    return 'http://10.0.2.2:3000';
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (appApiKey.isNotEmpty) 'x-api-key': appApiKey,
      };

  /// 1. Mencari data pasien SATUSEHAT berdasarkan NIK (16 digit)
  static Future<SatuSehatPatient?> cariPasien(String nik, {String? customBaseUrl}) async {
    final cleanNik = nik.trim();
    if (cleanNik.length != 16 || !RegExp(r'^\d{16}$').hasMatch(cleanNik)) {
      throw Exception('NIK harus berupa 16 digit angka.');
    }

    final host = customBaseUrl ?? baseUrl;
    final url = Uri.parse('$host/patients?nik=$cleanNik');

    final response = await http.get(url, headers: _headers).timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception('Koneksi timeout. Pastikan backend SATUSEHAT (npm start) sudah berjalan.'),
        );

    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);
      if (data is Map && data['entry'] is List && (data['entry'] as List).isNotEmpty) {
        final firstEntry = data['entry'][0];
        if (firstEntry is Map && firstEntry['resource'] is Map) {
          return SatuSehatPatient.fromFhirResource(Map<String, dynamic>.from(firstEntry['resource'] as Map));
        }
      }
      return null;
    } else {
      throw Exception(_parseErrorMessage(response));
    }
  }

  /// 2. Mendaftarkan Pasien Anak Baru menggunakan NIK mandiri (POST /patients)
  static Future<String> daftarPasienBaru({
    required String nik,
    required String name,
    required String gender,
    required String birthDate,
    String? address,
    String? city,
  }) async {
    final url = Uri.parse('$baseUrl/patients');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'nik': nik.trim(),
        'name': name.trim(),
        'gender': gender,
        'birthDate': birthDate,
        'address': address ?? 'Jl. Medan Merdeka Barat No. 1',
        'city': city ?? 'Jakarta Pusat',
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['ihsNumber']?.toString() ?? '';
    } else {
      throw Exception(_parseErrorMessage(response));
    }
  }

  /// 3. Mengirim Data Pengukuran Antropometri Anak (BB, TB, Lingkar Kepala)
  static Future<Map<String, dynamic>> kirimAntropometri({
    required String patientIhs,
    double? weightKg,
    double? heightCm,
    double? headCircumferenceCm,
    DateTime? recordDate,
  }) async {
    final url = Uri.parse('$baseUrl/children/growth');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'patientIhs': patientIhs,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'headCircumferenceCm': headCircumferenceCm,
        'recordDate': recordDate?.toIso8601String(),
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_parseErrorMessage(response));
    }
  }

  /// 4. Sinkronisasi Lengkap Data Profil Anak (Otomatis Cari/Daftar + Kirim BB, TB, LK)
  static Future<Map<String, dynamic>> syncProfilAnak({
    required String nik,
    required String name,
    required String gender,
    required String birthDate,
    double? weightKg,
    double? heightCm,
    double? headCircumferenceCm,
    String? address,
    String? city,
  }) async {
    final url = Uri.parse('$baseUrl/children/sync-profile');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'nik': nik.trim(),
        'name': name.trim(),
        'gender': gender,
        'birthDate': birthDate,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'headCircumferenceCm': headCircumferenceCm,
        'address': address ?? 'Jl. Kalimantan No. 37',
        'city': city ?? 'Jember',
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(_parseErrorMessage(response));
    }
  }

  static String _parseErrorMessage(http.Response response) {
    try {
      final dynamic body = jsonDecode(response.body);
      if (body is Map && body['error'] != null) {
        return body['error'].toString();
      }
    } catch (_) {}
    return 'Gagal (${response.statusCode}): ${response.reasonPhrase}';
  }
}
