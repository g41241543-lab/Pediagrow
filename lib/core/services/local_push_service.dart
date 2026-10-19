import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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

  /// Menginisialisasi plugin dan meminta izin notifikasi (Android 13+) serta alarm eksak.
  ///
  /// Harus dipanggil sekali di `main()` sebelum `runApp`.
  Future<void> init() async {
    if (_initialized) return;

    // Inisialisasi basis data zona waktu untuk notifikasi terjadwal
    tz.initializeTimeZones();

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

    // Minta izin POST_NOTIFICATIONS di Android 13+ & Exact Alarm
    if (Platform.isAndroid) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      try {
        await androidPlugin?.requestExactAlarmsPermission();
      } catch (e) {
        debugPrint('[LocalPushService] requestExactAlarmsPermission info: $e');
      }
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
    if (targetRole != null && _activeRole != null && _activeRole != targetRole) {
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

  // ============================================================
  // MENJADWALKAN NOTIFIKASI
  // ============================================================

  /// Menjadwalkan notifikasi sistem di waktu tertentu di masa depan.
  /// Notifikasi akan muncul di status bar / notification tray HP pada saat
  /// [scheduledDate] tiba, meskipun aplikasi sedang ditutup / di latar belakang.
  ///
  /// [id]            — ID unik integer notifikasi.
  /// [title]         — Judul notifikasi.
  /// [body]          — Isi pesan notifikasi.
  /// [scheduledDate] — Waktu kemunculan notifikasi di masa depan.
  /// [targetRole]    — Role yang berhak menerima notifikasi ini.
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    PushRole? targetRole,
  }) async {
    if (!_initialized) {
      debugPrint('[LocalPushService] schedule() dipanggil sebelum init() — abaikan.');
      return;
    }

    // Filter role aktif
    if (targetRole != null && _activeRole != null && _activeRole != targetRole) {
      debugPrint(
        '[LocalPushService] Notifikasi terjadwal difilter: activeRole=$_activeRole, '
        'targetRole=$targetRole — tidak dijadwalkan.',
      );
      return;
    }

    final now = DateTime.now();
    // Jika waktu sudah tiba atau lewat, langsung munculkan
    if (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
      await show(title: title, body: body, targetRole: targetRole, id: id);
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'pediagrow_consultation_channel',
      'Pengingat Konsultasi PediaGrow',
      channelDescription: 'Pengingat saat waktu konsultasi dokter telah tiba',
      importance: Importance.max,
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
      final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint(
        '[LocalPushService] Notifikasi berhasil dijadwalkan pada $scheduledDate (id=$id): "$title"',
      );
    } catch (e) {
      debugPrint('[LocalPushService] schedule() error: $e');
      // Fallback: Jika waktu sudah lewat atau gagal, panggil show() jika dalam hitungan menit
      if (scheduledDate.difference(now).inSeconds < 10) {
        await show(title: title, body: body, targetRole: targetRole, id: id);
      }
    }
  }

  /// Membatalkan notifikasi terjadwal berdasarkan ID
  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id);
      debugPrint('[LocalPushService] Notifikasi id=$id dibatalkan');
    } catch (e) {
      debugPrint('[LocalPushService] cancel() error: $e');
    }
  }
}
