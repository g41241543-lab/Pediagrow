import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/youtube_config.dart';
import '../../models/youtube_video_model.dart';

/// Service untuk mengambil daftar video edukasi dari YouTube Data API v3.
///
/// Mendukung:
/// 1. Pengambilan real-time dari playlist / channel edukasi anak (misal: Cocomelon).
/// 2. Resolusi detail durasi video (`contentDetails.duration`).
/// 3. In-memory caching agar tidak boros kuota API pada setiap pergantian state/rebuild.
/// 4. Fallback otomatis ke daftar video edukatif terkurasi jika API key belum disetel,
///    kuota habis, atau perangkat sedang offline.
class YoutubeService {
  static final YoutubeService _instance = YoutubeService._internal();
  factory YoutubeService() => _instance;
  YoutubeService._internal();

  List<YoutubeVideoModel>? _cachedVideos;

  /// Mengambil daftar video edukasi anak
  Future<List<YoutubeVideoModel>> getEducationalVideos({
    int maxResults = 8,
    bool forceRefresh = false,
  }) async {
    // Kembalikan dari cache jika tersedia dan tidak diminta refresh
    if (!forceRefresh && _cachedVideos != null && _cachedVideos!.isNotEmpty) {
      return _cachedVideos!;
    }

    // Jika API Key belum disetel, langsung gunakan data terkurasi tanpa throw error
    if (!YoutubeConfig.hasApiKey) {
      _cachedVideos = YoutubeVideoModel.curatedFallbackVideos;
      return _cachedVideos!;
    }

    try {
      final apiKey = YoutubeConfig.apiKey;

      // 1. Ambil video anak & balita/bayi edukatif (kartun, stimulasi sensorik, lagu anak)
      final searchUri = Uri.parse(
        'https://www.googleapis.com/youtube/v3/search'
        '?part=snippet'
        '&q=lagu+edukasi+anak+balita+bayi+kartun'
        '&type=video'
        '&videoEmbeddable=true'
        '&maxResults=$maxResults'
        '&key=$apiKey',
      );

      final searchResponse = await http.get(searchUri).timeout(
        const Duration(seconds: 8),
      );

      if (searchResponse.statusCode != 200) {
        // Fallback ke video terkurasi jika kuota API habis / error
        debugPrint('YouTube API query fallback: ${searchResponse.body}');
        _cachedVideos = YoutubeVideoModel.curatedFallbackVideos;
        return _cachedVideos!;
      }

      final searchData = jsonDecode(searchResponse.body) as Map<String, dynamic>;
      final items = searchData['items'] as List<dynamic>? ?? [];

      if (items.isEmpty) {
        _cachedVideos = YoutubeVideoModel.curatedFallbackVideos;
        return _cachedVideos!;
      }

      // Ambil daftar Video ID untuk query detail durasi
      final videoIds = <String>[];
      for (final item in items) {
        final snippet = item['snippet'] as Map<String, dynamic>?;
        final resId = snippet?['resourceId'] as Map<String, dynamic>?;
        final vid = resId?['videoId'] as String?;
        if (vid != null && vid.isNotEmpty) {
          videoIds.add(vid);
        }
      }

      if (videoIds.isEmpty) {
        _cachedVideos = YoutubeVideoModel.curatedFallbackVideos;
        return _cachedVideos!;
      }

      // 2. Query detail video (durasi) menggunakan endpoint videos
      final videosUri = Uri.parse(
        'https://www.googleapis.com/youtube/v3/videos'
        '?part=snippet,contentDetails'
        '&id=${videoIds.join(',')}'
        '&key=$apiKey',
      );

      final videosResponse = await http.get(videosUri).timeout(
        const Duration(seconds: 8),
      );

      if (videosResponse.statusCode == 200) {
        final videosData = jsonDecode(videosResponse.body) as Map<String, dynamic>;
        final detailItems = videosData['items'] as List<dynamic>? ?? [];

        final resultList = <YoutubeVideoModel>[];
        for (final item in detailItems) {
          final contentDetails = item['contentDetails'] as Map<String, dynamic>?;
          final isoDuration = contentDetails?['duration'] as String?;
          final formattedDuration = YoutubeVideoModel.parseIsoDuration(isoDuration);

          resultList.add(
            YoutubeVideoModel.fromYoutubeApi(
              item: item as Map<String, dynamic>,
              duration: formattedDuration,
            ),
          );
        }

        if (resultList.isNotEmpty) {
          _cachedVideos = resultList;
          return resultList;
        }
      }

      // Jika query detail gagal, tetap buat model dasar dari playlist items
      final fallbackFromItems = items.map((item) {
        return YoutubeVideoModel.fromYoutubeApi(
          item: item as Map<String, dynamic>,
          duration: '03:00',
        );
      }).toList();

      _cachedVideos = fallbackFromItems;
      return fallbackFromItems;
    } catch (e) {
      debugPrint('Error fetching YouTube videos: $e');
      _cachedVideos = YoutubeVideoModel.curatedFallbackVideos;
      return _cachedVideos!;
    }
  }

  /// Menghapus cache agar bisa me-load ulang
  void clearCache() {
    _cachedVideos = null;
  }
}
