import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../models/soal_model.dart';
import 'api_service.dart';

/// Service untuk mengelola bank soal kuis Parenting.
///
/// Menggunakan pola Stale-While-Revalidate & In-Memory Cache:
/// 1. [loadInitialSoal] → mengembalikan data dari memory cache atau asset lokal
///    secara instan (< 25 ms) tanpa memblokir UI dengan network timeout.
/// 2. [getAllSoal] → mengambil data terbaru dari server API (MySQL) dengan timeout
///    singkat (2,5 detik). Jika gagal, otomatis fallback ke cache / asset lokal.
/// 3. [updateSoal] → mengirim pembaruan ke server dan langsung menyinkronkan
///    cache lokal agar data selalu mutakhir.
class SoalService {
  /// Timeout jaringan diperpendek agar tidak menggantung jika server mati/offline
  static const Duration _timeout = Duration(milliseconds: 2500);

  /// In-memory cache bank soal agar pembukaan halaman berikutnya instan (0 ms)
  static List<SoalModel>? _cache;

  /// Mengambil data soal dari cache jika tersedia
  static List<SoalModel>? get cachedSoal =>
      _cache != null ? List.unmodifiable(_cache!) : null;

  // ──────────────────────────────────────────────────────────────────
  // LOAD INITIAL (INSTAN: DARI CACHE ATAU ASSET LOKAL)
  // ──────────────────────────────────────────────────────────────────

  /// Mengambil data awal secepat mungkin (0 - 30 ms):
  /// - Dari memory cache jika ada
  /// - Dari asset JSON lokal jika cache masih kosong
  static Future<List<SoalModel>> loadInitialSoal() async {
    if (_cache != null && _cache!.isNotEmpty) {
      return List<SoalModel>.from(_cache!);
    }
    final assetData = await _loadFromAsset();
    if (assetData.isNotEmpty) {
      _cache = List<SoalModel>.from(assetData);
    }
    return assetData;
  }

  // ──────────────────────────────────────────────────────────────────
  // GET ALL (JARINGAN DENGAN TIMEOUT CEPAT + CACHE FALLBACK)
  // ──────────────────────────────────────────────────────────────────

  /// Mengambil seluruh bank soal dari database via API.
  ///
  /// Jika API berhasil, memperbarui cache lokal dan mengembalikan data terbaru.
  /// Jika API gagal/timeout, fallback ke cache yang sudah ada atau asset lokal.
  static Future<List<SoalModel>> getAllSoal({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null && _cache!.isNotEmpty) {
      return List<SoalModel>.from(_cache!);
    }

    try {
      final root = await ApiService.getEffectiveBaseUrl();
      final response = await http
          .get(Uri.parse('$root/permainan/get_soal.php'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          final serverList = decoded
              .map((e) => SoalModel.fromJson(e as Map<String, dynamic>))
              .toList();
          _cache = List<SoalModel>.from(serverList);
          return serverList;
        }
      }
    } catch (e) {
      debugPrint(
        'SoalService.getAllSoal API error/timeout: $e — menggunakan cache/fallback',
      );
    }

    // Jika sudah ada cache di memori, pakai itu
    if (_cache != null && _cache!.isNotEmpty) {
      return List<SoalModel>.from(_cache!);
    }

    // Fallback terakhir: baca dari asset JSON
    final assetList = await _loadFromAsset();
    if (assetList.isNotEmpty) {
      _cache = List<SoalModel>.from(assetList);
    }
    return assetList;
  }

  /// Sinkronisasi data di latar belakang (background sync) tanpa memblokir UI
  static Future<List<SoalModel>?> syncInBackground() async {
    try {
      final root = await ApiService.getEffectiveBaseUrl();
      final response = await http
          .get(Uri.parse('$root/permainan/get_soal.php'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          final serverList = decoded
              .map((e) => SoalModel.fromJson(e as Map<String, dynamic>))
              .toList();
          _cache = List<SoalModel>.from(serverList);
          return serverList;
        }
      }
    } catch (_) {}
    return null;
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
  // UPDATE & CACHE MANAGEMENT
  // ──────────────────────────────────────────────────────────────────

  /// Memperbarui cache lokal untuk satu soal tertentu secara langsung
  static void updateCache(SoalModel updated) {
    if (_cache == null) {
      _cache = [updated];
      return;
    }
    final index = _cache!.indexWhere((s) => s.id == updated.id);
    if (index != -1) {
      _cache![index] = updated;
    } else {
      _cache!.add(updated);
    }
  }

  /// Mengosongkan cache
  static void clearCache() {
    _cache = null;
  }

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
        final isSuccess = decoded['status'] == 'berhasil';
        if (isSuccess) {
          // Sinkronkan cache lokal langsung
          if (_cache != null) {
            final idx = _cache!.indexWhere((s) => s.id == id);
            if (idx != -1) {
              final old = _cache![idx];
              _cache![idx] = SoalModel(
                id: id,
                kategori: old.kategori,
                pertanyaan: pertanyaan,
                jawabanBenar: jawabanBenar,
                penjelasan: penjelasan,
              );
            }
          }
        }
        return isSuccess;
      }
    } catch (e) {
      debugPrint('SoalService.updateSoal error: $e');
    }
    return false;
  }
}
