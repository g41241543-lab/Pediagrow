import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/pengguna/beranda/notifikasi_page.dart';
import '../../features/pmik_superadmin/beranda/notifikasi_superadmin_page.dart';
import 'notification_service.dart';
import 'session_service.dart';
import 'superadmin_notification_service.dart';

import 'user_service.dart';

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
/// ### Fitur Utama:
/// 1. Tampilan notifikasi sistem di HP mendukung expandable text dengan panah kecil
///    (chevron down) menggunakan [BigTextStyleInformation], sehingga seluruh isi
///    notifikasi dapat dibaca lengkap dan tidak terpotong.
/// 2. Setiap kali notifikasi muncul di HP, otomatis tersimpan dan masuk ke menu
///    notifikasi di dalam aplikasi sesuai role yang aktif.
/// 3. Ketika notifikasi di HP diklik oleh pengguna, aplikasi membuka dan langsung
///    mengarahkan ke halaman daftar notifikasi sesuai role.
/// 4. Notifikasi strictly scoped per akun/user ID yang sedang login: notifikasi akun lain
///    tidak boleh masuk ke akun atau perangkat yang sedang aktif untuk akun berbeda.
class LocalPushService {
  static final LocalPushService _instance = LocalPushService._internal();
  factory LocalPushService() => _instance;
  LocalPushService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  PushRole? _activeRole;
  String? _activeUserId;

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

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint(
          '[LocalPushService] Notifikasi diklik di HP: payload=${response.payload}',
        );
        _navigateToNotificationList();
      },
    );

    // Tangani skenario ketika aplikasi dibuka dari kondisi terminate lewat klik notifikasi
    try {
      final NotificationAppLaunchDetails? launchDetails =
          await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        debugPrint('[LocalPushService] Aplikasi dibuka dari klik notifikasi HP.');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 700), () {
            _navigateToNotificationList();
          });
        });
      }
    } catch (e) {
      debugPrint('[LocalPushService] getNotificationAppLaunchDetails error: $e');
    }

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
  // NAVIGASI DARI KLIK NOTIFIKASI
  // ============================================================

  /// Mengarahkan pengguna ke halaman daftar notifikasi sesuai rolenya
  void _navigateToNotificationList() {
    final nav = SessionService.navigatorKey.currentState;
    if (nav == null) {
      // Retry singkat jika NavigatorState belum selesai di-mount
      Future.delayed(const Duration(milliseconds: 500), () {
        final retryNav = SessionService.navigatorKey.currentState;
        if (retryNav != null) {
          _doNavigate(retryNav);
        }
      });
      return;
    }
    _doNavigate(nav);
  }

  void _doNavigate(NavigatorState nav) {
    final role = _activeRole ?? PushRole.pengguna;
    if (role == PushRole.pengguna) {
      nav.push(
        MaterialPageRoute(builder: (_) => const NotifikasiPage()),
      );
    } else {
      nav.push(
        MaterialPageRoute(
          builder: (_) => NotifikasiSuperadminPage(role: role),
        ),
      );
    }
  }

  // ============================================================
  // SINKRONISASI KE MENU NOTIFIKASI IN-APP
  // ============================================================

  void _recordNotificationInApp({
    required String title,
    required String body,
    PushRole? targetRole,
  }) {
    try {
      final effectiveRole = targetRole ?? _activeRole ?? PushRole.pengguna;
      if (effectiveRole == PushRole.pengguna) {
        NotificationService().addNotificationFromPush(
          title: title,
          message: body,
        );
      } else {
        SuperadminNotificationService().addNotificationFromPush(
          title: title,
          message: body,
          role: effectiveRole,
        );
      }
    } catch (e) {
      debugPrint('[LocalPushService] _recordNotificationInApp error: $e');
    }
  }

  // ============================================================
  // FILTER USER & ROLE
  // ============================================================

  /// Menetapkan akun & role yang sedang aktif login.
  void setActiveUser({String? userId, PushRole? role}) {
    _activeUserId = userId;
    if (role != null) {
      _activeRole = role;
    }
    debugPrint('[LocalPushService] User aktif diset: userId=$userId, role=$_activeRole');
  }

  /// Menetapkan role akun yang sedang aktif login.
  void setActiveRole(PushRole? role) {
    _activeRole = role;
    debugPrint('[LocalPushService] Role aktif diset: $role');
  }

  /// ID User yang sedang aktif login
  String? get activeUserId => _activeUserId;

  /// Role akun yang sedang aktif (bisa null jika belum login)
  PushRole? get activeRole => _activeRole;

  // ============================================================
  // MENAMPILKAN NOTIFIKASI
  // ============================================================

  /// Menampilkan notifikasi di system tray perangkat.
  ///
  /// [title]        — Judul notifikasi.
  /// [body]         — Isi pesan notifikasi.
  /// [targetRole]   — Role yang berhak menerima notifikasi ini. Jika berbeda
  ///                 dengan [_activeRole], notifikasi **tidak** ditampilkan di HP.
  /// [targetUserId] — User ID yang berhak menerima notifikasi ini. Jika berbeda
  ///                 dengan akun yang sedang login, notifikasi tidak ditampilkan di HP
  ///                 dan tidak dicatat di menu notifikasi in-app.
  /// [id]           — ID notifikasi unik (opsional). Jika tidak diisi, akan
  ///                 digenerate secara acak.
  /// [recordInApp]  — Jika true, notifikasi juga otomatis dicatat ke daftar
  ///                 menu notifikasi di dalam aplikasi (sesuai role).
  String _resolveActionTitle(String message, String defaultTitle) {
    if (defaultTitle.isNotEmpty &&
        defaultTitle != 'PediaGrow' &&
        defaultTitle != 'Peringatan') {
      return defaultTitle;
    }

    final lower = message.toLowerCase();

    // 0. Aksi: BATAS KUOTA / LIMIT
    if (lower.contains('batas') &&
        (lower.contains('pertumbuhan') || lower.contains('input'))) {
      return 'Batas Input Data Pertumbuhan';
    }
    if (lower.contains('batas') && lower.contains('stunting')) {
      return 'Batas Cek Stunting';
    }

    // 1. Aksi: HAPUS
    if (lower.contains('hapus') || lower.contains('dihapus')) {
      if (lower.contains('anak')) return 'Berhasil Menghapus Data Anak';
      if (lower.contains('artikel')) return 'Berhasil Menghapus Artikel';
      if (lower.contains('resep') || lower.contains('mpasi')) {
        return 'Berhasil Menghapus Resep MPASI';
      }
      if (lower.contains('dokter')) return 'Berhasil Menghapus Data Dokter';
      if (lower.contains('pmik') || lower.contains('staf')) {
        return 'Berhasil Menghapus Akses PMIK';
      }
      if (lower.contains('cuti')) return 'Cuti Dokter Dihapus';
      if (lower.contains('notifikasi')) return 'Berhasil Menghapus Notifikasi';
      return 'Berhasil Menghapus Data';
    }

    // 2. Aksi: UBAH / PERBARUI / EDIT
    if (lower.contains('ubah') ||
        lower.contains('perbarui') ||
        lower.contains('diperbarui') ||
        lower.contains('edit')) {
      if (lower.contains('anak')) return 'Berhasil Mengubah Data Anak';
      if (lower.contains('sandi') || lower.contains('password')) {
        return 'Berhasil Mengubah Kata Sandi';
      }
      if (lower.contains('profil') ||
          lower.contains('ibu') ||
          lower.contains('foto')) {
        return 'Berhasil Mengubah Profil';
      }
      if (lower.contains('artikel')) return 'Berhasil Mengubah Artikel';
      if (lower.contains('resep') || lower.contains('mpasi')) {
        return 'Berhasil Mengubah Resep MPASI';
      }
      if (lower.contains('dokter')) return 'Berhasil Mengubah Data Dokter';
      if (lower.contains('pmik') || lower.contains('staf')) {
        return 'Berhasil Mengubah Akses PMIK';
      }
      if (lower.contains('jadwal')) return 'Berhasil Mengubah Jadwal';
      return 'Berhasil Mengubah Data';
    }

    // 3. Aksi: TAMBAH / BUAT / SIMPAN
    if (lower.contains('tambah') ||
        lower.contains('ditambahkan') ||
        lower.contains('buat') ||
        lower.contains('simpan') ||
        lower.contains('tersimpan')) {
      if (lower.contains('anak')) return 'Berhasil Menambahkan Data Anak';
      if (lower.contains('booking') ||
          lower.contains('konsultasi') ||
          lower.contains('janji')) {
        return 'Berhasil Membuat Janji Konsultasi';
      }
      if (lower.contains('artikel')) return 'Berhasil Menambahkan Artikel';
      if (lower.contains('resep') || lower.contains('mpasi')) {
        return 'Berhasil Menambahkan Resep MPASI';
      }
      if (lower.contains('dokter')) return 'Berhasil Menambahkan Data Dokter';
      if (lower.contains('pmik') || lower.contains('staf')) {
        return 'Berhasil Menambahkan Akses PMIK';
      }
      if (lower.contains('cuti')) return 'Cuti Dokter Berhasil Ditambahkan';
      if (lower.contains('resume')) return 'Resume Medis Disimpan';
      return 'Berhasil Menambahkan Data';
    }

    // 4. Aksi: UNDUH / DOWNLOAD
    if (lower.contains('unduh') || lower.contains('download')) {
      return 'Berhasil Mengunduh Data';
    }

    // 5. Konteks: STUNTING
    if (lower.contains('stunting') || lower.contains('pemeriksaan')) {
      return 'Pemeriksaan Stunting';
    }

    // 6. Konteks: KONSULTASI
    if (lower.contains('konsultasi') || lower.contains('booking')) {
      return 'Konsultasi Dokter';
    }

    if (defaultTitle.isNotEmpty) return defaultTitle;
    return 'PediaGrow';
  }

  /// Menampilkan notifikasi di system tray perangkat.
  ///
  /// [title]        — Judul notifikasi.
  /// [body]         — Isi pesan notifikasi.
  /// [targetRole]   — Role yang berhak menerima notifikasi ini. Jika berbeda
  ///                 dengan [_activeRole], notifikasi **tidak** ditampilkan di HP.
  /// [targetUserId] — User ID yang berhak menerima notifikasi ini. Jika berbeda
  ///                 dengan akun yang sedang login, notifikasi tidak ditampilkan di HP
  ///                 dan tidak dicatat di menu notifikasi in-app.
  /// [id]           — ID notifikasi unik (opsional). Jika tidak diisi, akan
  ///                 digenerate secara acak.
  /// [recordInApp]  — Jika true, notifikasi juga otomatis dicatat ke daftar
  ///                 menu notifikasi di dalam aplikasi (sesuai role).
  Future<void> show({
    required String title,
    required String body,
    PushRole? targetRole,
    String? targetUserId,
    int? id,
    bool recordInApp = true,
  }) async {
    final effectiveTitle = _resolveActionTitle(body, title);

    // Pastikan notifikasi hanya masuk jika sesuai akun pengguna yang aktif
    if (targetUserId != null) {
      final currentUserId = _activeUserId ?? UserService().currentUser.id;
      if (currentUserId.isEmpty || currentUserId != targetUserId) {
        debugPrint(
          '[LocalPushService] Notifikasi ditolak (targetUserId=$targetUserId != activeUserId=$currentUserId).',
        );
        return;
      }
    }

    // Filter role aktif: jangan tampilkan jika role aktif berbeda dari targetRole
    if (targetRole != null && _activeRole != null && _activeRole != targetRole) {
      debugPrint(
        '[LocalPushService] Notifikasi difilter: activeRole=$_activeRole, '
        'targetRole=$targetRole — tidak ditampilkan di HP.',
      );
      return;
    }

    // Selalu pastikan notifikasi tercatat di menu aplikasi jika recordInApp == true
    if (recordInApp) {
      _recordNotificationInApp(
        title: effectiveTitle,
        body: body,
        targetRole: targetRole,
      );
    }

    if (!_initialized) {
      debugPrint(
        '[LocalPushService] show() dipanggil sebelum init() — abaikan push HP.',
      );
      return;
    }

    final int notifId = id ?? Random().nextInt(0x7FFFFFFF);

    // Menggunakan BigTextStyleInformation agar notifikasi di HP memiliki panah kecil
    // (chevron) untuk diexpand dan menampilkan teks lengkap tanpa terpotong
    final BigTextStyleInformation bigTextStyle = BigTextStyleInformation(
      body,
      htmlFormatBigText: false,
      contentTitle: effectiveTitle,
      htmlFormatContentTitle: false,
      summaryText: null,
      htmlFormatSummaryText: false,
    );

    // Channel Android
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'pediagrow_channel', // channel id (unik per aplikasi)
      'PediaGrow', // channel name yang tampil di pengaturan HP
      channelDescription: 'Notifikasi sistem PediaGrow',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: bigTextStyle,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _plugin.show(notifId, effectiveTitle, body, details);
      debugPrint(
        '[LocalPushService] Notifikasi ditampilkan: id=$notifId, '
        'title="$effectiveTitle", targetRole=$targetRole, targetUserId=$targetUserId',
      );
    } catch (e) {
      debugPrint('[LocalPushService] show() error: $e');
    }
  }

  /// Menampilkan notifikasi di system tray dengan judul **persis** seperti yang diberikan,
  /// tanpa diproses oleh [_resolveActionTitle]. Gunakan method ini ketika judul sudah
  /// ditetapkan oleh pemanggil dan harus konsisten antara HP dan daftar notifikasi in-app.
  Future<void> showWithExactTitle({
    required String title,
    required String body,
    PushRole? targetRole,
    String? targetUserId,
    int? id,
    bool recordInApp = false,
  }) async {
    // Pastikan notifikasi hanya masuk jika sesuai akun pengguna yang aktif
    if (targetUserId != null) {
      final currentUserId = _activeUserId ?? UserService().currentUser.id;
      if (currentUserId.isEmpty || currentUserId != targetUserId) {
        debugPrint(
          '[LocalPushService] showWithExactTitle ditolak (targetUserId=$targetUserId != activeUserId=$currentUserId).',
        );
        return;
      }
    }

    // Filter role aktif
    if (targetRole != null && _activeRole != null && _activeRole != targetRole) {
      debugPrint(
        '[LocalPushService] showWithExactTitle difilter: activeRole=$_activeRole, '
        'targetRole=$targetRole — tidak ditampilkan.',
      );
      return;
    }

    if (recordInApp) {
      _recordNotificationInApp(
        title: title,
        body: body,
        targetRole: targetRole,
      );
    }

    if (!_initialized) {
      debugPrint('[LocalPushService] showWithExactTitle dipanggil sebelum init() — abaikan.');
      return;
    }

    final int notifId = id ?? Random().nextInt(0x7FFFFFFF);

    final BigTextStyleInformation bigTextStyle = BigTextStyleInformation(
      body,
      htmlFormatBigText: false,
      contentTitle: title,
      htmlFormatContentTitle: false,
      summaryText: null,
      htmlFormatSummaryText: false,
    );

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'pediagrow_channel',
      'PediaGrow',
      channelDescription: 'Notifikasi sistem PediaGrow',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: bigTextStyle,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _plugin.show(notifId, title, body, details);
      debugPrint(
        '[LocalPushService] showWithExactTitle: id=$notifId, title="$title", targetRole=$targetRole',
      );
    } catch (e) {
      debugPrint('[LocalPushService] showWithExactTitle() error: $e');
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
  /// [targetUserId]  — User ID pemilik notifikasi.
  /// [recordInApp]   — Catat ke menu notifikasi aplikasi.
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    PushRole? targetRole,
    String? targetUserId,
    bool recordInApp = true,
  }) async {
    // Pastikan notifikasi hanya dijadwalkan jika sesuai akun pengguna yang aktif
    if (targetUserId != null) {
      final currentUserId = _activeUserId ?? UserService().currentUser.id;
      if (currentUserId.isEmpty || currentUserId != targetUserId) {
        debugPrint(
          '[LocalPushService] Notifikasi terjadwal ditolak (targetUserId=$targetUserId != activeUserId=$currentUserId).',
        );
        return;
      }
    }

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
      await show(
        title: title,
        body: body,
        targetRole: targetRole,
        targetUserId: targetUserId,
        id: id,
        recordInApp: recordInApp,
      );
      return;
    }

    final BigTextStyleInformation bigTextStyle = BigTextStyleInformation(
      body,
      htmlFormatBigText: false,
      contentTitle: title,
      htmlFormatContentTitle: false,
      summaryText: null,
      htmlFormatSummaryText: false,
    );

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'pediagrow_consultation_channel',
      'Pengingat Konsultasi PediaGrow',
      channelDescription: 'Pengingat saat waktu konsultasi dokter telah tiba',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: bigTextStyle,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
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
      if (recordInApp) {
        _recordNotificationInApp(
          title: title,
          body: body,
          targetRole: targetRole,
        );
      }
    } catch (e) {
      debugPrint('[LocalPushService] schedule() error: $e');
      // Fallback: Jika waktu sudah lewat atau gagal, panggil show() jika dalam hitungan menit
      if (scheduledDate.difference(now).inSeconds < 10) {
        await show(
          title: title,
          body: body,
          targetRole: targetRole,
          targetUserId: targetUserId,
          id: id,
          recordInApp: recordInApp,
        );
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

  /// Membatalkan semua notifikasi sistem yang telah dijadwalkan
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
      debugPrint('[LocalPushService] Seluruh notifikasi lokal dibatalkan');
    } catch (e) {
      debugPrint('[LocalPushService] cancelAll() error: $e');
    }
  }
}
