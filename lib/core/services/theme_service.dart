import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pilihan tema aplikasi PediaGrow.
enum AppThemeMode {
  /// Mengikuti pengaturan tampilan perangkat.
  system,

  /// Selalu tampilan terang.
  light,

  /// Selalu tampilan gelap.
  dark,
}

/// Service singleton untuk mengelola tema aplikasi PediaGrow.
///
/// Fitur:
/// - Tiga pilihan tema: System (default), Light, Dark.
/// - Pilihan disimpan ke SharedPreferences agar bertahan setelah restart.
/// - [themeModeNotifier] reaktif — rebuild [MaterialApp] secara otomatis.
class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _prefKey = 'app_theme_mode';

  /// Notifier reaktif untuk mode tema yang dipilih pengguna.
  final ValueNotifier<AppThemeMode> themeModeNotifier =
      ValueNotifier<AppThemeMode>(AppThemeMode.system);

  /// Mode tema yang sedang aktif.
  AppThemeMode get currentMode => themeModeNotifier.value;

  /// ThemeMode Flutter yang sesuai dengan pilihan pengguna.
  ThemeMode get flutterThemeMode {
    switch (currentMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  /// Memuat preferensi tema dari penyimpanan lokal.
  /// Harus dipanggil sekali di `main()` sebelum `runApp`.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null) {
        themeModeNotifier.value = _fromString(saved);
      }
    } catch (e) {
      debugPrint('[ThemeService] init error: $e');
    }
  }

  /// Mengubah tema dan menyimpannya ke penyimpanan lokal.
  Future<void> setTheme(AppThemeMode mode) async {
    themeModeNotifier.value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, _toString(mode));
    } catch (e) {
      debugPrint('[ThemeService] setTheme error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // TEMA TERANG
  // ---------------------------------------------------------------------------

  /// ThemeData untuk mode terang (identik dengan tampilan saat ini).
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3985E7),
          primary: const Color(0xFF3985E7),
          brightness: Brightness.light,
        ),
      );

  // ---------------------------------------------------------------------------
  // TEMA GELAP
  // ---------------------------------------------------------------------------

  /// ThemeData untuk mode gelap — biru tua kehitaman yang lembut.
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3985E7),
          primary: const Color(0xFF3985E7),
          brightness: Brightness.dark,
          surface: const Color(0xFF1E293B),
          onSurface: const Color(0xFFF1F5F9),
        ),
        cardColor: const Color(0xFF1E293B),
        dividerColor: const Color(0xFF334155),
        iconTheme: const IconThemeData(color: Color(0xFFF1F5F9)),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFF1F5F9)),
          bodyMedium: TextStyle(color: Color(0xFFCBD5E1)),
          titleLarge: TextStyle(color: Color(0xFFF1F5F9)),
        ),
      );

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  String _toString(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.system:
        return 'system';
    }
  }

  AppThemeMode _fromString(String value) {
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      default:
        return AppThemeMode.system;
    }
  }
}
