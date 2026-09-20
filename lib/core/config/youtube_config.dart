/// Konfigurasi YouTube Data API v3 untuk fitur Video Edukasi Anak di PediaGrow.
///
/// PANDUAN PENGATURAN API KEY:
/// 1. Buka Google Cloud Console: https://console.cloud.google.com/
/// 2. Buat proyek baru atau pilih proyek yang sudah ada.
/// 3. Masuk ke "APIs & Services" > "Library", cari "YouTube Data API v3", lalu klik "Enable".
/// 4. Masuk ke "APIs & Services" > "Credentials", klik "Create Credentials" > "API Key".
/// 5. (Opsional tapi disarankan) Berikan pembatasan (API Restrictions) pada key tersebut khusus untuk "YouTube Data API v3".
/// 6. Jalankan aplikasi menggunakan argumen `--dart-define` saat build/run:
///    ```bash
///    flutter run --dart-define=YOUTUBE_API_KEY=AIzaSy...
///    ```
///    Atau jika menggunakan VS Code / Android Studio, tambahkan ke `launch.json` di bagian `args`:
///    `"--dart-define=YOUTUBE_API_KEY=AIzaSy..."`
///
/// Catatan: Jika API Key tidak disetel atau kuota limit terlampaui / koneksi offline,
/// sistem secara otomatis menggunakan fallback data video edukatif anak yang sudah terkurasi
/// (seperti video lagu & edukasi Cocomelon) sehingga aplikasi selalu siap dipakai.
class YoutubeConfig {
  YoutubeConfig._();

  /// Mengambil API Key dari environment variable `--dart-define=YOUTUBE_API_KEY=...`
  static const String _envApiKey = String.fromEnvironment('YOUTUBE_API_KEY', defaultValue: '');

  /// Runtime override jika pengembang ingin menyetel API key secara langsung
  static String? _customApiKey;

  /// Mendapatkan API Key yang aktif
  static String get apiKey => _customApiKey ?? _envApiKey;

  /// Setel API key saat runtime (jika tidak menggunakan --dart-define)
  static void setApiKey(String key) {
    _customApiKey = key;
  }

  /// Memeriksa apakah API Key telah dikonfigurasi
  static bool get hasApiKey => apiKey.trim().isNotEmpty;

  /// Default channel ID edukasi anak (misal: Cocomelon)
  static const String defaultChannelId = 'UCbCmjCuTUZos62426OGoHaA';

  /// Default uploads playlist ID (otomatis dari channel ID Cocomelon dengan mengganti 'UC' menjadi 'UU')
  static const String defaultPlaylistId = 'UUbCmjCuTUZos62426OGoHaA';

  /// Judul section default
  static const String sectionTitle = 'Video Edukasi Anak';
}
