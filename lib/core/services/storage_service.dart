import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Service untuk memproses penyimpanan & penampilan foto secara lintas-perangkat
/// menggunakan Base64 Data URI di Cloud Firestore (tanpa Firebase Storage / Blaze).
class StorageService {
  // Nama kategori (dipertahankan untuk kompatibilitas pemanggilan)
  static const String artikel = 'artikel';
  static const String resepMpasi = 'resep_mpasi';
  static const String profilIbu = 'profil_ibu';
  static const String profilAnak = 'profil_anak';
  static const String profilDokter = 'profil_dokter';
  static const String profilPmik = 'profil_pmik';
  static const String profilSuperadmin = 'profil_superadmin';
  static const String chat = 'chat_konsultasi';

  /// Batas ukuran file mentah (700 KB). Setelah Base64 (+33%) sekitar 930 KB,
  /// masih di bawah batas dokumen Firestore (1 MB).
  static const int maxRawBytes = 700 * 1024;

  /// Cache hasil decode Base64 supaya tidak decode ulang setiap rebuild.
  static final Map<String, Uint8List> _decodeCache = {};
  static const int _maxCacheEntries = 50;

  /// Mengecek apakah string adalah Base64 Data URI gambar.
  static bool isBase64(String? value) {
    if (value == null) return false;
    return value.startsWith('data:image/');
  }

  /// Mengonversi foto lokal ke Base64 Data URI agar bisa disimpan di Firestore.
  ///
  /// Parameter [folder] dan [fileName] tidak dipakai, hanya dipertahankan
  /// agar pemanggilan lama tetap kompatibel.
  static Future<String> uploadIfLocal(
    String pathOrUrl, {
    String? folder,
    String? fileName,
  }) async {
    return toPersistableString(pathOrUrl);
  }

  /// Mengonversi path file lokal ke Base64 Data URI.
  /// - Data URI / http / https / assets dikembalikan apa adanya.
  /// - File lokal dibaca lalu di-encode.
  /// - Jika file terlalu besar, mengembalikan string kosong.
  static Future<String> toPersistableString(String? pathOrUrl) async {
    if (pathOrUrl == null || pathOrUrl.isEmpty) return '';
    if (pathOrUrl.startsWith('data:image/') ||
        pathOrUrl.startsWith('http://') ||
        pathOrUrl.startsWith('https://') ||
        pathOrUrl.startsWith('assets/')) {
      return pathOrUrl;
    }

    try {
      final file = File(pathOrUrl);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();

        if (bytes.length > maxRawBytes) {
          debugPrint(
            '[StorageService] Foto terlalu besar: ${bytes.length} byte '
            '(maks $maxRawBytes). Foto tidak disimpan.',
          );
          return '';
        }

        final base64String = base64Encode(bytes);
        final lower = pathOrUrl.toLowerCase();
        String mime = 'image/jpeg';
        if (lower.endsWith('.png')) {
          mime = 'image/png';
        } else if (lower.endsWith('.webp')) {
          mime = 'image/webp';
        }
        return 'data:$mime;base64,$base64String';
      }
    } catch (e) {
      debugPrint('[StorageService] Gagal encode gambar lokal ke Base64: $e');
    }

    return pathOrUrl;
  }

  /// Mendekode string Base64 menjadi byte Uint8List (dengan cache).
  static Uint8List? decodeBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;

    final cached = _decodeCache[base64String];
    if (cached != null) return cached;

    try {
      Uint8List? result;
      if (base64String.startsWith('data:image/')) {
        final commaIndex = base64String.indexOf(',');
        if (commaIndex != -1) {
          result = base64Decode(base64String.substring(commaIndex + 1));
        }
      } else if (base64String.length > 200 &&
          !base64String.contains('/') &&
          !base64String.contains('\\')) {
        result = base64Decode(base64String);
      }

      if (result != null) {
        if (_decodeCache.length >= _maxCacheEntries) {
          _decodeCache.remove(_decodeCache.keys.first);
        }
        _decodeCache[base64String] = result;
        return result;
      }
    } catch (e) {
      debugPrint('[StorageService] Gagal decode base64: $e');
    }
    return null;
  }

  /// Mengembalikan [ImageProvider] yang sesuai, atau null jika tidak bisa dimuat.
  static ImageProvider? buildImageProvider(String? urlOrPath) {
    if (urlOrPath == null || urlOrPath.isEmpty) return null;

    if (urlOrPath.startsWith('data:image/')) {
      final bytes = decodeBase64(urlOrPath);
      if (bytes != null) return MemoryImage(bytes);
      return null;
    }

    if (urlOrPath.startsWith('http://') || urlOrPath.startsWith('https://')) {
      return NetworkImage(urlOrPath);
    }

    if (urlOrPath.startsWith('assets/')) {
      return AssetImage(urlOrPath);
    }

    try {
      final file = File(urlOrPath);
      if (file.existsSync()) {
        return FileImage(file);
      }
    } catch (_) {}

    return null;
  }

  /// Widget universal untuk menampilkan gambar dengan fallback placeholder.
  static Widget buildImageWidget(
    String? urlOrPath, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    final fallback =
        placeholder ??
        Container(
          width: width,
          height: height,
          color: const Color(0xFFF1F5F9),
          child: const Icon(Icons.image_outlined, color: Color(0xFF94A3B8)),
        );

    if (urlOrPath == null || urlOrPath.isEmpty) return fallback;

    if (urlOrPath.startsWith('data:image/')) {
      final bytes = decodeBase64(urlOrPath);
      if (bytes != null) {
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => errorWidget ?? fallback,
        );
      }
      return fallback;
    }

    if (urlOrPath.startsWith('http://') || urlOrPath.startsWith('https://')) {
      return Image.network(
        urlOrPath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => errorWidget ?? fallback,
      );
    }

    if (urlOrPath.startsWith('assets/')) {
      return Image.asset(
        urlOrPath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => errorWidget ?? fallback,
      );
    }

    try {
      final file = File(urlOrPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => errorWidget ?? fallback,
        );
      }
    } catch (_) {}

    return fallback;
  }
}
