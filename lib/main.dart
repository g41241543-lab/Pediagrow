import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/splash/splash_page.dart';

import 'package:firebase_core/firebase_core.dart';

import 'core/services/staff_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase sebelum app dijalankan
  await Firebase.initializeApp();
  await StaffAuthService().ensureSuperadminSeeded();

  // Mengatur status bar transparan dan ikon gelap agar menyatu dengan background putih
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PediaGrow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3985E7),
          primary: const Color(0xFF3985E7),
        ),
      ),
      home: const SplashPage(),
    );
  }
}
