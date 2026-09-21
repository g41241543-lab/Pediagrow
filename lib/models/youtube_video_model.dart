/// Model representasi Video Edukasi YouTube untuk anak pada aplikasi PediaGrow.
class YoutubeVideoModel {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String duration;
  final String channelTitle;
  final String publishedAt;

  const YoutubeVideoModel({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.duration,
    this.channelTitle = 'Cocomelon',
    this.publishedAt = '',
  });

  /// URL web YouTube langsung
  String get youtubeUrl => 'https://www.youtube.com/watch?v=$id';

  /// URL Deep link aplikasi YouTube (Android/iOS intent)
  String get appDeepLinkUrl => 'vnd.youtube:$id';

  /// Konversi durasi ISO 8601 (contoh: PT3M32S atau PT1H2M15S) ke format mm:ss atau hh:mm:ss
  static String parseIsoDuration(String? iso) {
    if (iso == null || iso.isEmpty) return '03:00';
    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(iso);
    if (match == null) return '03:00';

    final hours = int.tryParse(match.group(1) ?? '') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '') ?? 0;
    final seconds = int.tryParse(match.group(3) ?? '') ?? 0;

    final sStr = seconds.toString().padLeft(2, '0');
    final mStr = minutes.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$mStr:$sStr';
    }
    return '$mStr:$sStr';
  }

  /// Membuat model dari respon item YouTube Data API v3
  factory YoutubeVideoModel.fromYoutubeApi({
    required Map<String, dynamic> item,
    String duration = '03:00',
  }) {
    final snippet = item['snippet'] as Map<String, dynamic>? ?? {};

    // ID dapat berada di item['id'] (videos) atau snippet['resourceId']['videoId'] (playlistItems) atau item['id']['videoId'] (search)
    String videoId = '';
    if (item['id'] is String) {
      videoId = item['id'] as String;
    } else if (item['id'] is Map && item['id']['videoId'] != null) {
      videoId = item['id']['videoId'] as String;
    } else if (snippet['resourceId'] is Map && snippet['resourceId']['videoId'] != null) {
      videoId = snippet['resourceId']['videoId'] as String;
    }

    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>? ?? {};
    final highThumb = thumbnails['high'] as Map<String, dynamic>?;
    final medThumb = thumbnails['medium'] as Map<String, dynamic>?;
    final defThumb = thumbnails['default'] as Map<String, dynamic>?;

    final thumbUrl = highThumb?['url'] as String? ??
        medThumb?['url'] as String? ??
        defThumb?['url'] as String? ??
        'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

    return YoutubeVideoModel(
      id: videoId,
      title: snippet['title'] as String? ?? 'Video Edukasi Anak',
      thumbnailUrl: thumbUrl,
      duration: duration,
      channelTitle: snippet['channelTitle'] as String? ?? 'Cocomelon',
      publishedAt: snippet['publishedAt'] as String? ?? '',
    );
  }

  /// Daftar video edukasi terkurasi sebagai fallback jika offline atau API key belum dikonfigurasi
  static const List<YoutubeVideoModel> curatedFallbackVideos = [
    YoutubeVideoModel(
      id: 'e_04ZrNroTo',
      title: 'Wheels on the Bus | CoComelon Nursery Rhymes & Kids Songs',
      thumbnailUrl: 'https://i.ytimg.com/vi/e_04ZrNroTo/hqdefault.jpg',
      duration: '03:32',
      channelTitle: 'CoComelon',
      publishedAt: '2026',
    ),
    YoutubeVideoModel(
      id: 'WRVsOCh907o',
      title: 'Bath Song | CoComelon Nursery Rhymes & Kids Songs',
      thumbnailUrl: 'https://i.ytimg.com/vi/WRVsOCh907o/hqdefault.jpg',
      duration: '02:44',
      channelTitle: 'CoComelon',
      publishedAt: '2026',
    ),
    YoutubeVideoModel(
      id: '0-t_1U4qNoc',
      title: 'Yes Yes Vegetables Song | CoComelon Nursery Rhymes & Kids Songs',
      thumbnailUrl: 'https://i.ytimg.com/vi/0-t_1U4qNoc/hqdefault.jpg',
      duration: '03:47',
      channelTitle: 'CoComelon',
      publishedAt: '2026',
    ),
    YoutubeVideoModel(
      id: '71h8MZ88194',
      title: 'Baa Baa Black Sheep | CoComelon Nursery Rhymes',
      thumbnailUrl: 'https://i.ytimg.com/vi/71h8MZ88194/hqdefault.jpg',
      duration: '02:30',
      channelTitle: 'CoComelon',
      publishedAt: '2026',
    ),
    YoutubeVideoModel(
      id: 'yCjJyiqpAuU',
      title: 'Twinkle Twinkle Little Star | CoComelon Nursery Rhymes',
      thumbnailUrl: 'https://i.ytimg.com/vi/yCjJyiqpAuU/hqdefault.jpg',
      duration: '04:12',
      channelTitle: 'CoComelon',
      publishedAt: '2026',
    ),
    YoutubeVideoModel(
      id: 'XqZsoesa55w',
      title: 'Baby Shark Dance | Sing and Dance! | Animal Songs',
      thumbnailUrl: 'https://i.ytimg.com/vi/XqZsoesa55w/hqdefault.jpg',
      duration: '02:16',
      channelTitle: 'Pinkfong Baby Shark',
      publishedAt: '2026',
    ),
  ];
}
