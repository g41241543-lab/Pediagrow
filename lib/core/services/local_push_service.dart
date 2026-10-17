import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Daftar role yang dikenali oleh [LocalPushService] untuk pemfilteran notifikasi.
enum PushRole {
  pengguna,
  dokter,
  pmik,
  superadmin,
}

/// Service singleton yang mengelola notifikasi sistem (system tray / status bar)
/// menggunakan flutter_local_notifications — **tanpa Firebase Cloud Messaging**.
///
/// ### Cara kerja filter role
/// Setiap kali role aktif di-set via [setActiveRole], service akan mencatat
/// role tersebut secara in-memory. Saat [show] dipanggil, pemanggil dapat
/// menentukan [targetRole] — jika berbeda dengan role aktif, notifikasi
/// **tidak akan ditampilkan di HP**.
///
/// ### Integrasi
/// - [NotificationService.addNotification] → memanggil `show` dengan
///   `targetRole: LocalPushService().activeRole` (mengikuti role login aktif:
///   pengguna, dokter, maupun pmik).
/// - [SuperadminNotificationService.addNotification] → memanggil `show`
///   dengan `targetRole: PushRole.superadmin`
class LocalPushService {
  static final LocalPushService _instance = LocalPushService._internal();
  factory LocalPushService() => _instance;
  LocalPushService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  PushRole? _activeRole;

  // ============================================================
  // INISIALISASI
  // ============================================================

  /// Menginisialisasi plugin dan meminta izin notifikasi (Android 13+).
  ///
  /// Harus dipanggil sekali di `main()` sebelum `runApp`.
  Future<void> init() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    // Minta izin POST_NOTIFICATIONS di Android 13+
    if (Platform.isAndroid) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }

    _initialized = true;
    debugPrint('[LocalPushService] Inisialisasi selesai.');
  }

  // ============================================================
  // FILTER ROLE
  // ============================================================

  /// Menetapkan role akun yang sedang aktif login.
  ///
  /// Panggil ini segera setelah sesi login/restore berhasil, dan hapus
  /// (set ke null) ketika sesi berakhir / logout.
  void setActiveRole(PushRole? role) {
    _activeRole = role;
    debugPrint('[LocalPushService] Role aktif diset: $role');
  }

  /// Role akun yang sedang aktif (bisa null jika belum login)
  PushRole? get activeRole => _activeRole;

  // ============================================================
  // MENAMPILKAN NOTIFIKASI
  // ============================================================

  /// Menampilkan notifikasi di system tray perangkat.
  ///
  /// [title]      — Judul notifikasi.
  /// [body]       — Isi pesan notifikasi.
  /// [targetRole] — Role yang berhak menerima notifikasi ini. Jika berbeda
  ///               dengan [_activeRole], notifikasi **tidak** ditampilkan.
  ///               Jika null, notifikasi selalu ditampilkan (tanpa filter).
  /// [id]         — ID notifikasi unik (opsional). Jika tidak diisi, akan
  ///               digenerate secara acak.
  Future<void> show({
    required String title,
    required String body,
    PushRole? targetRole,
    int? id,
  }) async {
    if (!_initialized) {
      debugPrint(
        '[LocalPushService] show() dipanggil sebelum init() — abaikan.',
      );
      return;
    }

    // Filter: jangan tampilkan jika role aktif berbeda dari targetRole
    if (targetRole != null && _activeRole != targetRole) {
      debugPrint(
        '[LocalPushService] Notifikasi difilter: activeRole=$_activeRole, '
        'targetRole=$targetRole — tidak ditampilkan.',
      );
      return;
    }

    final int notifId = id ?? Random().nextInt(0x7FFFFFFF);

    // Channel Android
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'pediagrow_channel', // channel id (unik per aplikasi)
      'PediaGrow', // channel name yang tampil di pengaturan HP
      channelDescription: 'Notifikasi sistem PediaGrow',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _plugin.show(notifId, title, body, details);
      debugPrint(
        '[LocalPushService] Notifikasi ditampilkan: id=$notifId, '
        'title="$title", targetRole=$targetRole',
      );
    } catch (e) {
      debugPrint('[LocalPushService] show() error: $e');
    }
  }
}
