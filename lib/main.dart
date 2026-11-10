import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/splash/splash_page.dart';

import 'core/services/local_push_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/session_service.dart';
import 'core/services/staff_auth_service.dart';
import 'core/services/superadmin_notification_service.dart';
import 'core/services/theme_service.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Fase 1: Inisialisasi WAJIB sebelum UI muncul ──────────────────────────
  // Firebase harus selesai terlebih dahulu (prasyarat semua service lainnya).
  await Firebase.initializeApp();

  // ThemeService dan SessionService hanya membaca SharedPreferences (lokal, cepat).
  // Jalankan paralel setelah Firebase siap — tidak ada dependensi antar keduanya.
  await Future.wait([
    ThemeService().init(),
    SessionService().init(),
  ]);

  // Mengatur status bar transparan dan ikon gelap agar menyatu dengan background putih
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());

  // ── Fase 2: Background init setelah UI sudah tampil ───────────────────────
  // ensureSuperadminSeeded hanya perlu berjalan sekali setelah setup awal.
  // Jalankan di background agar tidak memblokir startup.
  StaffAuthService().ensureSuperadminSeeded();

  // Service notifikasi (hanya baca local storage) — tidak perlu blocking.
  Future.wait([
    LocalPushService().init(),
    NotificationService().init(),
    SuperadminNotificationService().init(),
  ]);
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    SessionService().handleAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ThemeService().themeModeNotifier,
        StaffAuthService().currentStaffNotifier,
      ]),
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: SessionService.navigatorKey,
          scaffoldMessengerKey: SessionService.scaffoldMessengerKey,
          title: 'PediaGrow',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeService().flutterThemeMode,
          theme: ThemeService.lightTheme,
          darkTheme: ThemeService.darkTheme,
          home: const SplashPage(),
        );
      },
    );
  }
}
