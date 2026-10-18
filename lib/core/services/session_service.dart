import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/auth_choice_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/dokter/beranda/beranda_dokter_page.dart';
import '../../features/pengguna/beranda/beranda_page.dart';
import '../../features/pmik_admin/beranda/beranda_pmik_page.dart';
import '../../features/pmik_superadmin/beranda/beranda_superadmin_page.dart';
import '../../models/staff_account_model.dart';
import 'child_service.dart';
import 'local_push_service.dart';
import 'staff_auth_service.dart';
import 'user_service.dart';

/// Model untuk menentukan halaman tujuan awal berdasarkan status session.
class SessionDestination {
  final Widget page;
  final String? expiredMessage;

  const SessionDestination({
    required this.page,
    this.expiredMessage,
  });
}

/// Service singleton untuk mengelola aturan session login PediaGrow:
///
/// 1. **Role Pengguna**:
///    - Session berlaku 30 hari sejak waktu login.
///    - Selama belum lewat 30 hari, user langsung masuk beranda tanpa login,
///      berapa kali pun aplikasi ditutup atau dibuka.
///    - Setelah lewat 30 hari sejak login, session dihapus dan user diarahkan
///      ke halaman login.
///    - Batas 30 hari dihitung dari waktu login, bukan dari terakhir aplikasi dibuka.
///    - Siklus ini berulang terus-menerus setiap login kembali.
///
/// 2. **Role Dokter, PMIK, dan Superadmin**:
///    - Session berbasis ketidakaktifan (inactivity timeout).
///    - Jika aplikasi ditinggalkan (masuk background atau ditutup) kurang dari 10 menit
///      lalu kembali, user tetap login.
///    - Jika lebih dari 10 menit, session dihapus dan user diarahkan ke halaman login.
///    - Selama user aktif memakai aplikasi di layar (foreground), TIDAK BOLEH ada logout otomatis.
class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  /// Navigator key global untuk routing otomatis ketika session kadaluarsa
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// ScaffoldMessenger key global untuk menampilkan SnackBar notifikasi
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // Kunci penyimpanan SharedPreferences
  static const String _keySessionRole = 'pediagrow_session_role';
  static const String _keySessionUserId = 'pediagrow_session_user_id';
  static const String _keySessionLoginTime = 'pediagrow_session_login_time';
  static const String _keyStaffId = 'pediagrow_session_staff_id';
  static const String _keyStaffData = 'pediagrow_session_staff_data';
  static const String _keyStaffLastLeftTime = 'pediagrow_session_staff_last_left';

  // Batas waktu sesi sesuai aturan
  static const Duration durationPengguna = Duration(days: 30);
  static const Duration durationStaffInactivity = Duration(minutes: 10);

  // Cache in-memory
  int? _inMemoryStaffLastLeftTime;
  Timer? _periodicCheckTimer;
  bool _isRedirecting = false;

  /// Inisialisasi service pada start aplikasi
  Future<void> init() async {
    _startPeriodicCheck();
  }

  /// Menjalankan timer berkala ringan untuk mengecek batas waktu 30 hari pengguna
  /// (HANYA mengecek pengguna, staf TIDAK pernah di-logout otomatis saat aktif di layar)
  void _startPeriodicCheck() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      final role = await getActiveRole();
      if (role == 'pengguna') {
        final prefs = await SharedPreferences.getInstance();
        final loginTimeMs = prefs.getInt(_keySessionLoginTime);
        if (loginTimeMs != null && isPenggunaSessionExpired(loginTimeMs)) {
          debugPrint('[SessionService] Sesi 30 hari pengguna telah habis.');
          await clearSession();
          UserService().logout();
          _redirectToLogin(
            message:
                'Sesi login Anda telah berakhir (30 hari). Silakan masuk kembali.',
          );
        }
      }
    });
  }

  // ============================================================
  // MENYIMPAN SESI
  // ============================================================

  /// Menyimpan sesi login role Pengguna (30 hari dari SEKARANG)
  Future<void> savePenggunaSession({required String userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;

      await prefs.setString(_keySessionRole, 'pengguna');
      await prefs.setString(_keySessionUserId, userId);
      await prefs.setInt(_keySessionLoginTime, now);

      // Bersihkan data sesi staf jika ada
      await prefs.remove(_keyStaffId);
      await prefs.remove(_keyStaffData);
      await prefs.remove(_keyStaffLastLeftTime);
      _inMemoryStaffLastLeftTime = null;

      // Set role aktif untuk filter push notifikasi
      LocalPushService().setActiveRole(PushRole.pengguna);

      debugPrint(
        '[SessionService] Sesi Pengguna disimpan (berlaku 30 hari hingga '
        '${DateTime.fromMillisecondsSinceEpoch(now).add(durationPengguna)})',
      );
    } catch (e) {
      debugPrint('[SessionService] savePenggunaSession error: $e');
    }
  }

  /// Menyimpan sesi login role Staf (Dokter, PMIK, Superadmin)
  Future<void> saveStaffSession(StaffAccount staff) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String roleStr;
      if (staff.isSuperAdmin || staff.role == StaffRole.superadmin) {
        roleStr = 'superadmin';
      } else if (staff.role == StaffRole.admin) {
        roleStr = 'pmik';
      } else {
        roleStr = 'dokter';
      }

      await prefs.setString(_keySessionRole, roleStr);
      await prefs.setString(_keyStaffId, staff.id);
      await prefs.setString(_keyStaffData, jsonEncode(staff.toMap()));
      // Reset waktu ditinggalkan karena baru login dan aktif di layar
      await prefs.remove(_keyStaffLastLeftTime);
      _inMemoryStaffLastLeftTime = null;

      // Bersihkan data sesi pengguna jika ada
      await prefs.remove(_keySessionUserId);
      await prefs.remove(_keySessionLoginTime);

      // Set role aktif untuk filter push notifikasi
      final pushRole = roleStr == 'superadmin'
          ? PushRole.superadmin
          : roleStr == 'pmik'
              ? PushRole.pmik
              : PushRole.dokter;
      LocalPushService().setActiveRole(pushRole);

      debugPrint('[SessionService] Sesi Staf ($roleStr) disimpan: ${staff.name}');
    } catch (e) {
      debugPrint('[SessionService] saveStaffSession error: $e');
    }
  }

  /// Menghapus seluruh sesi dari SharedPreferences
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySessionRole);
      await prefs.remove(_keySessionUserId);
      await prefs.remove(_keySessionLoginTime);
      await prefs.remove(_keyStaffId);
      await prefs.remove(_keyStaffData);
      await prefs.remove(_keyStaffLastLeftTime);
      _inMemoryStaffLastLeftTime = null;

      // Hapus role aktif push notifikasi
      LocalPushService().setActiveRole(null);

      debugPrint('[SessionService] Seluruh data sesi dibersihkan.');
    } catch (e) {
      debugPrint('[SessionService] clearSession error: $e');
    }
  }

  // ============================================================
  // PENGECEKAN SESI & KADALUARSA
  // ============================================================

  /// Mengambil nama role aktif saat ini ('pengguna', 'dokter', 'pmik', 'superadmin', atau null)
  Future<String?> getActiveRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keySessionRole);
    } catch (_) {
      return null;
    }
  }

  /// Apakah sesi pengguna saat ini masih valid (< 30 hari dari waktu login)
  Future<bool> hasValidPenggunaSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString(_keySessionRole);
      if (role != 'pengguna') return false;

      final userId = prefs.getString(_keySessionUserId);
      final loginTimeMs = prefs.getInt(_keySessionLoginTime);
      if (userId == null || userId.isEmpty || loginTimeMs == null) {
        return false;
      }

      return !isPenggunaSessionExpired(loginTimeMs);
    } catch (_) {
      return false;
    }
  }

  /// Mengecek apakah waktu login pengguna sudah lewat 30 hari
  bool isPenggunaSessionExpired(int loginTimeMs) {
    final loginDate = DateTime.fromMillisecondsSinceEpoch(loginTimeMs);
    final diff = DateTime.now().difference(loginDate);
    return diff >= durationPengguna;
  }

  /// Mengecek apakah staf meninggalkan aplikasi >= 10 menit
  bool isStaffInactivityExpired(int lastLeftTimeMs) {
    final leftDate = DateTime.fromMillisecondsSinceEpoch(lastLeftTimeMs);
    final diff = DateTime.now().difference(leftDate);
    return diff >= durationStaffInactivity;
  }

  // ============================================================
  // APP LIFECYCLE (KETIDAKAKTIFAN STAF & RESUME PENGGUNA)
  // ============================================================

  /// Dipanggil dari [WidgetsBindingObserver.didChangeAppLifecycleState]
  Future<void> handleAppLifecycleState(AppLifecycleState state) async {
    final role = await getActiveRole();
    if (role == null) return;

    final isStaff = (role == 'dokter' || role == 'pmik' || role == 'superadmin');

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      // Aplikasi ditinggalkan (masuk background atau diminimize)
      if (isStaff) {
        await _recordStaffLeftTime();
      }
    } else if (state == AppLifecycleState.resumed) {
      // Aplikasi kembali ke layar (foreground)
      await _handleAppResumed(role, isStaff);
    }
  }

  Future<void> _recordStaffLeftTime() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      _inMemoryStaffLastLeftTime = now;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyStaffLastLeftTime, now);
      debugPrint(
        '[SessionService] Staf meninggalkan aplikasi pada '
        '${DateTime.fromMillisecondsSinceEpoch(now)}',
      );
    } catch (e) {
      debugPrint('[SessionService] recordStaffLeftTime error: $e');
    }
  }

  Future<void> _handleAppResumed(String role, bool isStaff) async {
    if (_isRedirecting) return;

    if (isStaff) {
      final prefs = await SharedPreferences.getInstance();
      final lastLeftMs =
          _inMemoryStaffLastLeftTime ?? prefs.getInt(_keyStaffLastLeftTime);

      if (lastLeftMs != null) {
        if (isStaffInactivityExpired(lastLeftMs)) {
          debugPrint(
            '[SessionService] Staf meninggalkan aplikasi >= 10 menit. Sesi berakhir.',
          );
          await clearSession();
          StaffAuthService().logout();
          _redirectToLogin(
            message:
                'Sesi Anda telah berakhir karena tidak aktif lebih dari 10 menit. Silakan masuk kembali.',
          );
          return;
        } else {
          // Kurang dari 10 menit -> tetap login, reset waktu left
          debugPrint(
            '[SessionService] Staf kembali kurang dari 10 menit. Sesi tetap aktif.',
          );
          _inMemoryStaffLastLeftTime = null;
          await prefs.remove(_keyStaffLastLeftTime);
        }
      }
    } else if (role == 'pengguna') {
      final prefs = await SharedPreferences.getInstance();
      final loginTimeMs = prefs.getInt(_keySessionLoginTime);
      if (loginTimeMs != null && isPenggunaSessionExpired(loginTimeMs)) {
        debugPrint(
          '[SessionService] Pengguna membuka aplikasi lewat 30 hari. Sesi berakhir.',
        );
        await clearSession();
        UserService().logout();
        _redirectToLogin(
          message:
              'Sesi login Anda telah berakhir (30 hari). Silakan masuk kembali.',
        );
      }
    }
  }

  void _redirectToLogin({required String message}) {
    if (_isRedirecting) return;
    _isRedirecting = true;

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginPage(sessionExpiredMessage: message),
      ),
      (route) => false,
    );

    showExpiredNotice(message);

    // Reset lock setelah delay singkat
    Future.delayed(const Duration(seconds: 1), () {
      _isRedirecting = false;
    });
  }

  /// Menampilkan SnackBar merah informatif saat session kadaluarsa
  static void showExpiredNotice(String message) {
    try {
      scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      debugPrint('[SessionService] showExpiredNotice error: $e');
    }
  }

  // ============================================================
  // DESTINASI AWAL (SPLASH SCREEN / COLD START)
  // ============================================================

  /// Menentukan halaman tujuan saat splash screen selesai atau di-skip
  Future<SessionDestination> getInitialDestination() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString(_keySessionRole);

      if (role == null || role.isEmpty) {
        return const SessionDestination(page: AuthChoicePage());
      }

      // --------------------------------------------------------
      // 1. Role Pengguna: batas 30 hari dari waktu login
      // --------------------------------------------------------
      if (role == 'pengguna') {
        final userId = prefs.getString(_keySessionUserId);
        final loginTimeMs = prefs.getInt(_keySessionLoginTime);

        if (userId == null || userId.isEmpty || loginTimeMs == null) {
          await clearSession();
          return const SessionDestination(page: AuthChoicePage());
        }

        if (isPenggunaSessionExpired(loginTimeMs)) {
          debugPrint(
            '[SessionService] Sesi pengguna telah melewati 30 hari sejak login.',
          );
          await clearSession();
          UserService().logout();
          return const SessionDestination(
            page: LoginPage(
              sessionExpiredMessage:
                  'Sesi login Anda telah berakhir (30 hari). Silakan masuk kembali.',
            ),
            expiredMessage:
                'Sesi login Anda telah berakhir (30 hari). Silakan masuk kembali.',
          );
        }

        // Sesi valid (< 30 hari): Muat user & anak
        await UserService().init();
        await ChildService().loadChildrenForCurrentUser();

        // Pulihkan role aktif push notifikasi
        LocalPushService().setActiveRole(PushRole.pengguna);

        debugPrint(
          '[SessionService] Pengguna valid (< 30 hari). Langsung ke beranda.',
        );
        return const SessionDestination(
          page: BerandaPage(showLengkapiProfilBanner: false),
        );
      }

      // --------------------------------------------------------
      // 2. Role Staf: Dokter, PMIK, Superadmin (inactivity 10 menit)
      // --------------------------------------------------------
      if (role == 'dokter' || role == 'pmik' || role == 'superadmin') {
        final staffId = prefs.getString(_keyStaffId);
        final staffDataStr = prefs.getString(_keyStaffData);
        final lastLeftTimeMs = prefs.getInt(_keyStaffLastLeftTime);

        if (staffId == null || staffId.isEmpty) {
          await clearSession();
          return const SessionDestination(page: AuthChoicePage());
        }

        if (lastLeftTimeMs != null && isStaffInactivityExpired(lastLeftTimeMs)) {
          debugPrint(
            '[SessionService] Staf ditinggalkan >= 10 menit. Sesi berakhir.',
          );
          await clearSession();
          StaffAuthService().logout();
          return const SessionDestination(
            page: LoginPage(
              sessionExpiredMessage:
                  'Sesi Anda telah berakhir karena tidak aktif lebih dari 10 menit. Silakan masuk kembali.',
            ),
            expiredMessage:
                'Sesi Anda telah berakhir karena tidak aktif lebih dari 10 menit. Silakan masuk kembali.',
          );
        }

        // Sesi staf valid (kembali < 10 menit atau baru dibuka)
        StaffAccount? restoredStaff;
        if (staffDataStr != null && staffDataStr.isNotEmpty) {
          try {
            final map = jsonDecode(staffDataStr) as Map<String, dynamic>;
            restoredStaff = StaffAccount.fromMap(staffId, map);
          } catch (e) {
            debugPrint('[SessionService] parse staff cache error: $e');
          }
        }

        // Fallback mengambil dari Firestore jika cache lokal kosong
        restoredStaff ??= await StaffAuthService().getStaffById(staffId);

        if (restoredStaff == null || !restoredStaff.isActive) {
          debugPrint(
            '[SessionService] Akun staf tidak ditemukan atau tidak aktif.',
          );
          await clearSession();
          StaffAuthService().logout();
          return const SessionDestination(
            page: LoginPage(
              sessionExpiredMessage:
                  'Akun staf tidak ditemukan atau tidak aktif.',
            ),
            expiredMessage: 'Akun staf tidak ditemukan atau tidak aktif.',
          );
        }

        // Pulihkan ke state runtime StaffAuthService
        StaffAuthService().setStaff(restoredStaff);

        // Reset waktu ditinggalkan karena staf sekarang aktif di layar
        await prefs.remove(_keyStaffLastLeftTime);
        _inMemoryStaffLastLeftTime = null;

        // Pulihkan role aktif push notifikasi
        final pushRole = role == 'superadmin'
            ? PushRole.superadmin
            : role == 'pmik'
                ? PushRole.pmik
                : PushRole.dokter;
        LocalPushService().setActiveRole(pushRole);

        debugPrint(
          '[SessionService] Sesi staf valid ($role). Langsung ke beranda.',
        );

        Widget destination;
        if (role == 'superadmin' || restoredStaff.isSuperAdmin) {
          destination = const BerandaSuperadminPage();
        } else if (role == 'pmik' || restoredStaff.role == StaffRole.admin) {
          destination = const BerandaPmikPage();
        } else {
          destination = const BerandaDokterPage();
        }

        return SessionDestination(page: destination);
      }

      return const SessionDestination(page: AuthChoicePage());
    } catch (e) {
      debugPrint('[SessionService] getInitialDestination error: $e');
      return const SessionDestination(page: AuthChoicePage());
    }
  }
}
