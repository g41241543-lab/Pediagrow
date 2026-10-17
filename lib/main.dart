import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/splash/splash_page.dart';

import 'core/services/local_push_service.dart';
import 'core/services/session_service.dart';
import 'core/services/staff_auth_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase sebelum app dijalankan
  await Firebase.initializeApp();
  await StaffAuthService().ensureSuperadminSeeded();
  await SessionService().init();
  await UserService().init();

  // Inisialisasi notifikasi lokal HP (tanpa Firebase Cloud Messaging)
  await LocalPushService().init();

  // Inisialisasi preferensi tema aplikasi (Default Sistem / Terang / Gelap)
  await ThemeService().init();

  // Mengatur status bar transparan dan ikon gelap agar menyatu dengan background putih
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
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
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: ThemeService().themeModeNotifier,
      builder: (context, mode, child) {
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
