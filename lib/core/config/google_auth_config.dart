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
      'B0:9F:F7:9A:F1:83:EC:A3:81:18:D0:9A:F2:36:C8:59:DB:A7:96:D0:51:AB:68:73:73:DF:C5:FE:47:8C:DE:3D';

  /// Web Client ID (OAuth 2.0 Web Application) dari Google Cloud Console.
  /// Isi ini jika Anda sudah membuat Web Client ID di Google Cloud Console.
  static const String webClientId =
      '1025789904190-539nj9eokon8sfbnkvd4nh5iugngv0ss.apps.googleusercontent.com';
}
