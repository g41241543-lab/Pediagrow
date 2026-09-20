import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service utama untuk komunikasi REST API antara aplikasi PediaGrow
/// dan backend PHP yang tersambung ke database MySQL 'pediagrow'.
class ApiService {
  /// Default IP WiFi laptop / PC untuk testing di HP Android fisik
  static const String defaultDeviceIp = '192.168.110.107';

  /// Mendapatkan Base URL yang sesuai dengan platform yang sedang menjalankan aplikasi.
  /// - Windows Desktop: http://127.0.0.1/pediagrow_api
  /// - Android Emulator: http://10.0.2.2/pediagrow_api
  /// - Android Device Fisik: http://192.168.110.107/pediagrow_api
  /// - Web: http://localhost/pediagrow_api
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost/pediagrow_api';
    }
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        return 'http://127.0.0.1/pediagrow_api';
      } else if (Platform.isAndroid) {
        return 'http://$defaultDeviceIp/pediagrow_api';
      }
    } catch (_) {}
    return 'http://$defaultDeviceIp/pediagrow_api';
  }

  /// Base URL dinamis yang dapat membaca override dari SharedPreferences jika user mengatur IP custom
  static Future<String> getEffectiveBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customUrl = prefs.getString('custom_api_base_url');
      if (customUrl != null && customUrl.trim().isNotEmpty) {
        return customUrl.trim().replaceAll(RegExp(r'/+$'), '');
      }
    } catch (_) {}
    return baseUrl;
  }

  static const Duration _timeoutDuration = Duration(seconds: 8);

  // ---------------------------------------------------------------------------
  // AUTHENTICATION
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> register(
    String nama,
    String email,
    String kataSandi,
    String peran,
  ) async {
    final root = await getEffectiveBaseUrl();
    try {
      final response = await http
          .post(
            Uri.parse('$root/auth/register.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nama': nama,
              'email': email,
              'kata_sandi': kataSandi,
              'peran': peran,
            }),
          )
          .timeout(_timeoutDuration);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('ApiService.register error: $e');
      return {'status': 'gagal', 'pesan': 'Koneksi ke server gagal: $e'};
    }
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String kataSandi,
  ) async {
    final root = await getEffectiveBaseUrl();
    try {
      final response = await http
          .post(
            Uri.parse('$root/auth/login.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'kata_sandi': kataSandi}),
          )
          .timeout(_timeoutDuration);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('ApiService.login error: $e');
      return {'status': 'gagal', 'pesan': 'Koneksi ke server gagal: $e'};
    }
  }

  // ---------------------------------------------------------------------------
  // PROFIL ANAK (Tabel: anak)
  // ---------------------------------------------------------------------------

  /// Mengambil daftar anak milik orang tua berdasarkan [idOrangTua]
  static Future<List<Map<String, dynamic>>> getChildren(int idOrangTua) async {
    final root = await getEffectiveBaseUrl();
    try {
      final response = await http
          .get(Uri.parse('$root/pengguna/get_children.php?id_orang_tua=$idOrangTua'))
          .timeout(_timeoutDuration);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      debugPrint('ApiService.getChildren error: $e');
    }
    return [];
  }

  /// Menambahkan data profil anak ke database MySQL
  static Future<Map<String, dynamic>> addChild(Map<String, dynamic> data) async {
    final root = await getEffectiveBaseUrl();
    try {
      final response = await http
          .post(
            Uri.parse('$root/pengguna/add_child.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(_timeoutDuration);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('ApiService.addChild error: $e');
      return {'status': 'gagal', 'pesan': 'Koneksi ke server gagal: $e'};
    }
  }

  // ---------------------------------------------------------------------------
  // DATA PERTUMBUHAN (Tabel: data_pertumbuhan)
  // ---------------------------------------------------------------------------

  /// Mencatat riwayat pengukuran stunting/pertumbuhan anak ke database MySQL
  static Future<Map<String, dynamic>> addGrowthRecord(
      Map<String, dynamic> record) async {
    final root = await getEffectiveBaseUrl();
    try {
      final response = await http
          .post(
            Uri.parse('$root/pengguna/add_growth_record.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(record),
          )
          .timeout(_timeoutDuration);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('ApiService.addGrowthRecord error: $e');
      return {'status': 'gagal', 'pesan': 'Koneksi ke server gagal: $e'};
    }
  }

  /// Mengambil riwayat pertumbuhan anak berdasarkan [idAnak]
  static Future<List<Map<String, dynamic>>> getGrowthRecords(int idAnak) async {
    final root = await getEffectiveBaseUrl();
    try {
      final response = await http
          .get(Uri.parse('$root/pengguna/get_growth_records.php?id_anak=$idAnak'))
          .timeout(_timeoutDuration);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      debugPrint('ApiService.getGrowthRecords error: $e');
    }
    return [];
  }

  // ---------------------------------------------------------------------------
  // ARTIKEL (Tabel: artikel)
  // ---------------------------------------------------------------------------

  /// Mengambil daftar artikel kesehatan dari database MySQL
  static Future<List<Map<String, dynamic>>> getArticles({String? query}) async {
    final root = await getEffectiveBaseUrl();
    try {
      final uri = (query != null && query.trim().isNotEmpty)
          ? Uri.parse('$root/pengguna/get_articles.php?q=${Uri.encodeComponent(query.trim())}')
          : Uri.parse('$root/pengguna/get_articles.php');
      final response = await http.get(uri).timeout(_timeoutDuration);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      debugPrint('ApiService.getArticles error: $e');
    }
    return [];
  }

  // ---------------------------------------------------------------------------
  // RESEP MPASI (Tabel: resep_mpasi)
  // ---------------------------------------------------------------------------

  /// Mengambil daftar resep MPASI dari database MySQL
  static Future<List<Map<String, dynamic>>> getRecipes({String? query}) async {
    final root = await getEffectiveBaseUrl();
    try {
      final uri = (query != null && query.trim().isNotEmpty)
          ? Uri.parse('$root/pengguna/get_recipes.php?q=${Uri.encodeComponent(query.trim())}')
          : Uri.parse('$root/pengguna/get_recipes.php');
      final response = await http.get(uri).timeout(_timeoutDuration);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      debugPrint('ApiService.getRecipes error: $e');
    }
    return [];
  }

  // ---------------------------------------------------------------------------
  // FASYANKES (Tabel: fasyankes)
  // ---------------------------------------------------------------------------

  /// Mengambil daftar fasilitas pelayanan kesehatan dari database MySQL
  static Future<List<Map<String, dynamic>>> getFasyankes() async {
    final root = await getEffectiveBaseUrl();
    try {
      final response = await http
          .get(Uri.parse('$root/pengguna/get_fasyankes.php'))
          .timeout(_timeoutDuration);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      debugPrint('ApiService.getFasyankes error: $e');
    }
    return [];
  }

  // ---------------------------------------------------------------------------
  // KONSULTASI (Tabel: konsultasi)
  // ---------------------------------------------------------------------------

  /// Mengambil riwayat konsultasi milik orang tua
  static Future<List<Map<String, dynamic>>> getConsultations(int idOrangTua) async {
    final root = await getEffectiveBaseUrl();
    try {
      final response = await http
          .get(Uri.parse('$root/pengguna/get_consultations.php?id_orang_tua=$idOrangTua'))
          .timeout(_timeoutDuration);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      debugPrint('ApiService.getConsultations error: $e');
    }
    return [];
  }

  // ---------------------------------------------------------------------------
  // NOTIFIKASI (Tabel: notifikasi)
  // ---------------------------------------------------------------------------

  /// Mengambil daftar notifikasi akun pengguna
  static Future<List<Map<String, dynamic>>> getNotifications(int idAkun) async {
    final root = await getEffectiveBaseUrl();
    try {
      final response = await http
          .get(Uri.parse('$root/pengguna/get_notifications.php?id_akun=$idAkun'))
          .timeout(_timeoutDuration);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      debugPrint('ApiService.getNotifications error: $e');
    }
    return [];
  }

  // ---------------------------------------------------------------------------
  // PROFIL PENGGUNA (Tabel: akun)
  // ---------------------------------------------------------------------------

  /// Memperbarui nama atau foto profil pengguna di database MySQL
  static Future<Map<String, dynamic>> updateProfile(
    int idAkun, {
    String? nama,
    String? fotoUrl,
  }) async {
    final root = await getEffectiveBaseUrl();
    try {
      final body = <String, dynamic>{'id_akun': idAkun};
      if (nama != null) body['nama'] = nama;
      if (fotoUrl != null) body['foto_url'] = fotoUrl;

      final response = await http
          .post(
            Uri.parse('$root/pengguna/update_profile.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeoutDuration);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('ApiService.updateProfile error: $e');
      return {'status': 'gagal', 'pesan': 'Koneksi ke server gagal: $e'};
    }
  }
}

