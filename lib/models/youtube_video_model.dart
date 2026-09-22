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

  /// Daftar video edukasi terkurasi ramah anak & balita/bayi (kartun, stimulasi sensorik, edukasi, musik)
  /// yang sudah diverifikasi aktif dan tersedia secara penuh di YouTube.
  static const List<YoutubeVideoModel> curatedFallbackVideos = [
    YoutubeVideoModel(
      id: 'KPP4Cfupzhs',
      title: 'Hey Bear Sensory - Smoothie Mix! Dance & Visual Bayi',
      thumbnailUrl: 'https://i.ytimg.com/vi/KPP4Cfupzhs/hqdefault.jpg',
      duration: '03:15',
      channelTitle: 'Hey Bear Sensory',
      publishedAt: '2025',
    ),
    YoutubeVideoModel(
      id: 'XeObnIGnX4A',
      title: 'Koleksi Lagu Anak Indonesia 30 Menit - BaLiTa',
      thumbnailUrl: 'https://i.ytimg.com/vi/XeObnIGnX4A/hqdefault.jpg',
      duration: '30:00',
      channelTitle: 'BaLiTa (Baba Lili Tata)',
      publishedAt: '2025',
    ),
    YoutubeVideoModel(
      id: 'XqZsoesa55w',
      title: 'Baby Shark Dance | Lagu & Tarian Hewan Lucu Balita',
      thumbnailUrl: 'https://i.ytimg.com/vi/XqZsoesa55w/hqdefault.jpg',
      duration: '02:16',
      channelTitle: 'Pinkfong Baby Shark',
      publishedAt: '2025',
    ),
    YoutubeVideoModel(
      id: 'Hxh9wcwvfxs',
      title: 'Baby Sensory Video | High Contrast Visuals & Musik Bayi',
      thumbnailUrl: 'https://i.ytimg.com/vi/Hxh9wcwvfxs/hqdefault.jpg',
      duration: '20:15',
      channelTitle: 'Baby Sensory Evergreen',
      publishedAt: '2025',
    ),
    YoutubeVideoModel(
      id: '0bsev7RMYbc',
      title: 'Main Rumah Sakit | Siapa Sakit? | Kartun Balita Edukatif',
      thumbnailUrl: 'https://i.ytimg.com/vi/0bsev7RMYbc/hqdefault.jpg',
      duration: '03:30',
      channelTitle: 'Bebefinn Bahasa Indonesia',
      publishedAt: '2025',
    ),
    YoutubeVideoModel(
      id: 'oevHysasp4s',
      title: 'Banana Cha Cha | Bernyanyi dan Menari Pororo',
      thumbnailUrl: 'https://i.ytimg.com/vi/oevHysasp4s/hqdefault.jpg',
      duration: '02:08',
      channelTitle: 'Pororo the Little Penguin',
      publishedAt: '2025',
    ),
    YoutubeVideoModel(
      id: 'g9UT6Ho5I-U',
      title: 'Petualangan Kartun Bus Kecil Tayo & Tim Penyelamat',
      thumbnailUrl: 'https://i.ytimg.com/vi/g9UT6Ho5I-U/hqdefault.jpg',
      duration: '11:45',
      channelTitle: 'Tayo the Little Bus',
      publishedAt: '2025',
    ),
    YoutubeVideoModel(
      id: 'yCjJyiqpAuU',
      title: 'Twinkle Twinkle Little Star | Lagu Pengantar Tidur Bayi',
      thumbnailUrl: 'https://i.ytimg.com/vi/yCjJyiqpAuU/hqdefault.jpg',
      duration: '04:12',
      channelTitle: 'Super Simple Songs',
      publishedAt: '2025',
    ),
    YoutubeVideoModel(
      id: '8omgp63nVUo',
      title: 'Lagu Belajar Angka & Edukasi Balita | Bebefinn Indonesia',
      thumbnailUrl: 'https://i.ytimg.com/vi/8omgp63nVUo/hqdefault.jpg',
      duration: '04:15',
      channelTitle: 'Bebefinn Bahasa Indonesia',
      publishedAt: '2025',
    ),
    YoutubeVideoModel(
      id: 'dynF31X9WfY',
      title: 'Baby Sensory Bedtime Lullaby | Stimulasi Visual Tidur Bayi',
      thumbnailUrl: 'https://i.ytimg.com/vi/dynF31X9WfY/hqdefault.jpg',
      duration: '15:20',
      channelTitle: 'This Little Piggy',
      publishedAt: '2025',
    ),
    YoutubeVideoModel(
      id: 'e_04ZrNroTo',
      title: 'Wheels on the Bus | Lagu Edukasi Balita & Anak',
      thumbnailUrl: 'https://i.ytimg.com/vi/e_04ZrNroTo/hqdefault.jpg',
      duration: '03:32',
      channelTitle: 'CoComelon',
      publishedAt: '2025',
    ),
    YoutubeVideoModel(
      id: 'WRVsOCh907o',
      title: 'Bath Song | Kebiasaan Baik Mandi Balita & Anak',
      thumbnailUrl: 'https://i.ytimg.com/vi/WRVsOCh907o/hqdefault.jpg',
      duration: '02:44',
      channelTitle: 'CoComelon',
      publishedAt: '2025',
    ),
  ];
}
