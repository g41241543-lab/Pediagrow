/// Konfigurasi Google Authentication untuk PediaGrow.
///
/// Berisi informasi sertifikat SHA-1, Package Name, dan Web Client ID
/// yang dibutuhkan agar Google Play Services dapat mengenali aplikasi.
class GoogleAuthConfig {
  /// Nama package Android resmi aplikasi
  static const String androidPackageName = 'com.example.pediagrow';

  /// SHA-1 Debug Certificate Fingerprint dari mesin/keystore pengembangan
  static const String debugSha1 =
      '7E:29:68:9E:26:81:DE:AC:A0:44:EA:E3:8E:20:E0:6B:7C:F2:39:8D';

  /// SHA-256 Debug Certificate Fingerprint
  static const String debugSha256 =
      '06:27:7E:E7:5C:E4:54:DC:95:03:B5:EC:CB:A9:54:64:21:6A:A5:A8:2B:F1:96:46:CC:D6:9F:57:A4:81:4C:CF';

  /// Web Client ID (OAuth 2.0 Web Application) dari Google Cloud Console.
  /// Isi ini jika Anda sudah membuat Web Client ID di Google Cloud Console.
  static const String webClientId =
      '174123262665-shn3fiqdqlt88oaoingeoetsi4l4af7k.apps.googleusercontent.com';
}
