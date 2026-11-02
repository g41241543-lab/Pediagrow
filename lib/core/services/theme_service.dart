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

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3985E7),
          primary: const Color(0xFF3985E7),
          brightness: Brightness.light,
          surface: Colors.white,
          onSurface: const Color(0xFF0B1014),
        ),
        dividerColor: const Color(0xFFE9EDEF),
      );

  // ---------------------------------------------------------------------------
  // TEMA GELAP
  // ---------------------------------------------------------------------------

  /// ThemeData untuk mode gelap — hitam pekat ala WhatsApp.
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1014),
        cardColor: const Color(0xFF1A2228),
        canvasColor: const Color(0xFF0B1014),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF1A2228),
          modalBackgroundColor: Color(0xFF1A2228),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF1A2228),
          surfaceTintColor: Colors.transparent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B1014),
          foregroundColor: Color(0xFFE9EDEF),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF1A2228),
          surfaceTintColor: Colors.transparent,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3985E7),
          primary: const Color(0xFF3985E7),
          brightness: Brightness.dark,
          surface: const Color(0xFF1A2228),
          onSurface: const Color(0xFFE9EDEF),
        ),
        dividerColor: const Color(0xFF2C363D),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF2C363D),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFE9EDEF)),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFE9EDEF)),
          bodyMedium: TextStyle(color: Color(0xFFD1D7DB)),
          bodySmall: TextStyle(color: Color(0xFF8696A0)),
          titleLarge: TextStyle(color: Color(0xFFE9EDEF)),
          titleMedium: TextStyle(color: Color(0xFFE9EDEF)),
          titleSmall: TextStyle(color: Color(0xFFE9EDEF)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF11171B),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF11171B),
          indicatorColor: Color(0xFF2C363D),
        ),
      );

  // ---------------------------------------------------------------------------
  // PALET WARNA TEMA PEDIA GROW
  // ---------------------------------------------------------------------------
  static const Color darkBg = Color(0xFF0B1014);
  static const Color darkCard = Color(0xFF1A2228);
  static const Color darkBorder = Color(0xFF2C363D);
  static const Color darkNavBar = Color(0xFF11171B);
  static const Color darkTextPrimary = Color(0xFFE9EDEF);
  static const Color darkTextSecondary = Color(0xFF8696A0);
  static const Color darkTextMuted = Color(0xFF667781);
  static const Color darkInputBg = Color(0xFF1A2228);
  static const Color primaryBlue = Color(0xFF3985E7);

  // Helper getters reaktif berbasis konteks
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color getScaffoldBg(BuildContext context) =>
      isDark(context) ? darkBg : Colors.white;

  static Color getCardBg(BuildContext context) =>
      isDark(context) ? darkCard : Colors.white;

  static Color getBorder(BuildContext context) =>
      isDark(context) ? darkBorder : const Color(0xFFE9EDEF);

  static Color getTextPrimary(BuildContext context) =>
      isDark(context) ? darkTextPrimary : const Color(0xFF0B1014);

  static Color getTextSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : const Color(0xFF8696A0);

  static Color getInputBg(BuildContext context) =>
      isDark(context) ? darkInputBg : Colors.white;

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
