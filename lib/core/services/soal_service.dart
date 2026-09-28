import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../models/soal_model.dart';
import 'api_service.dart';

/// Service untuk mengelola bank soal kuis Parenting.
///
/// Alur data:
/// 1. [getAllSoal] → membaca soal dari endpoint API (database MySQL).
///    Jika gagal (jaringan/server), *fallback* ke file JSON lokal.
/// 2. [updateSoal] → mengirim perubahan soal ke endpoint API.
///
/// File JSON (`assets/data/soal_kuis.json`) hanya dipakai sebagai
/// data seed awal dan sebagai fallback offline.
class SoalService {
  static const Duration _timeout = Duration(seconds: 8);

  // ──────────────────────────────────────────────────────────────────
  // GET ALL
  // ──────────────────────────────────────────────────────────────────

  /// Mengambil seluruh bank soal dari database via API.
  ///
  /// Jika API tidak tersedia (exception), fallback ke JSON lokal.
  static Future<List<SoalModel>> getAllSoal() async {
    try {
      final root = await ApiService.getEffectiveBaseUrl();
      final response = await http
          .get(Uri.parse('$root/permainan/get_soal.php'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded
              .map((e) => SoalModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('SoalService.getAllSoal API error: $e — fallback ke JSON lokal');
    }

    // Fallback: baca dari asset JSON
    return _loadFromAsset();
  }

  /// Membaca bank soal dari file JSON lokal sebagai fallback / seed.
  static Future<List<SoalModel>> _loadFromAsset() async {
    try {
      final raw = await rootBundle.loadString('assets/data/soal_kuis.json');
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SoalModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('SoalService._loadFromAsset error: $e');
      return [];
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // UPDATE
  // ──────────────────────────────────────────────────────────────────

  /// Memperbarui data soal di database.
  ///
  /// Hanya mengubah [pertanyaan], [jawabanBenar], dan [penjelasan]
  /// pada record yang memiliki [id] yang sama (bukan membuat soal baru).
  ///
  /// Mengembalikan `true` jika berhasil, `false` jika gagal.
  static Future<bool> updateSoal({
    required int id,
    required String pertanyaan,
    required bool jawabanBenar,
    required String penjelasan,
  }) async {
    try {
      final root = await ApiService.getEffectiveBaseUrl();
      final response = await http
          .post(
            Uri.parse('$root/permainan/update_soal.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id': id,
              'pertanyaan': pertanyaan,
              'jawaban_benar': jawabanBenar,
              'penjelasan': penjelasan,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return decoded['status'] == 'berhasil';
      }
    } catch (e) {
      debugPrint('SoalService.updateSoal error: $e');
    }
    return false;
  }
}
