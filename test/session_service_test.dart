import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/core/services/session_service.dart';
import 'package:pediagrow/features/auth/auth_choice_page.dart';
import 'package:pediagrow/features/auth/login_page.dart';
import 'package:pediagrow/features/dokter/beranda/beranda_dokter_page.dart';
import 'package:pediagrow/features/pengguna/beranda/beranda_page.dart';
import 'package:pediagrow/features/pmik_admin/beranda_pmik_page.dart';
import 'package:pediagrow/features/pmik_superadmin/beranda/beranda_superadmin_page.dart';
import 'package:pediagrow/models/staff_account_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionService - Logika Batas Waktu Sesi', () {
    final sessionService = SessionService();

    test('Pengguna: Login kurang dari 30 hari yang lalu dianggap belum kadaluarsa', () {
      final now = DateTime.now();

      // 10 hari yang lalu
      final tenDaysAgo = now.subtract(const Duration(days: 10)).millisecondsSinceEpoch;
      expect(sessionService.isPenggunaSessionExpired(tenDaysAgo), isFalse);

      // 29 hari yang lalu
      final twentyNineDaysAgo = now.subtract(const Duration(days: 29)).millisecondsSinceEpoch;
      expect(sessionService.isPenggunaSessionExpired(twentyNineDaysAgo), isFalse);
    });

    test('Pengguna: Login tepat atau lebih dari 30 hari yang lalu dianggap kadaluarsa', () {
      final now = DateTime.now();

      // Tepat 30 hari yang lalu
      final thirtyDaysAgo = now.subtract(const Duration(days: 30)).millisecondsSinceEpoch;
      expect(sessionService.isPenggunaSessionExpired(thirtyDaysAgo), isTrue);

      // 31 hari yang lalu
      final thirtyOneDaysAgo = now.subtract(const Duration(days: 31)).millisecondsSinceEpoch;
      expect(sessionService.isPenggunaSessionExpired(thirtyOneDaysAgo), isTrue);
    });

    test('Staf: Ditinggalkan kurang dari 10 menit dianggap masih aktif/valid', () {
      final now = DateTime.now();

      // 5 menit yang lalu
      final fiveMinAgo = now.subtract(const Duration(minutes: 5)).millisecondsSinceEpoch;
      expect(sessionService.isStaffInactivityExpired(fiveMinAgo), isFalse);

      // 9 menit 30 detik yang lalu
      final nineMinAgo = now
          .subtract(const Duration(minutes: 9, seconds: 30))
          .millisecondsSinceEpoch;
      expect(sessionService.isStaffInactivityExpired(nineMinAgo), isFalse);
    });

    test('Staf: Ditinggalkan lebih dari 10 menit dianggap kadaluarsa', () {
      final now = DateTime.now();

      // Tepat 10 menit yang lalu
      final tenMinAgo = now.subtract(const Duration(minutes: 10)).millisecondsSinceEpoch;
      expect(sessionService.isStaffInactivityExpired(tenMinAgo), isTrue);

      // 15 menit yang lalu
      final fifteenMinAgo = now.subtract(const Duration(minutes: 15)).millisecondsSinceEpoch;
      expect(sessionService.isStaffInactivityExpired(fifteenMinAgo), isTrue);
    });
  });

  group('SessionService - Alur Penyimpanan dan Navigasi Awal', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Belum ada sesi: membuka AuthChoicePage', () async {
      SharedPreferences.setMockInitialValues({});
      final sessionService = SessionService();

      final destination = await sessionService.getInitialDestination();
      expect(destination.page, isA<AuthChoicePage>());
      expect(destination.expiredMessage, isNull);
    });

    test('Pengguna: Sesi valid (< 30 hari) langsung masuk BerandaPage tanpa login', () async {
      final now = DateTime.now();
      final loginTime = now.subtract(const Duration(days: 5)).millisecondsSinceEpoch;

      SharedPreferences.setMockInitialValues({
        'pediagrow_session_role': 'pengguna',
        'pediagrow_session_user_id': 'user_dummy_123',
        'pediagrow_session_login_time': loginTime,
      });

      final sessionService = SessionService();
      final destination = await sessionService.getInitialDestination();

      expect(destination.page, isA<BerandaPage>());
      expect(destination.expiredMessage, isNull);
    });

    test('Pengguna: Sesi lewat 30 hari diarahkan ke LoginPage dengan pesan kadaluarsa', () async {
      final now = DateTime.now();
      final expiredLoginTime = now.subtract(const Duration(days: 31)).millisecondsSinceEpoch;

      SharedPreferences.setMockInitialValues({
        'pediagrow_session_role': 'pengguna',
        'pediagrow_session_user_id': 'user_dummy_123',
        'pediagrow_session_login_time': expiredLoginTime,
      });

      final sessionService = SessionService();
      final destination = await sessionService.getInitialDestination();

      expect(destination.page, isA<LoginPage>());
      expect(destination.expiredMessage, contains('30 hari'));

      // Sesi SharedPreferences harus sudah dibersihkan
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pediagrow_session_role'), isNull);
    });

    test('Staf Dokter: Ditinggalkan < 10 menit langsung masuk BerandaDokterPage', () async {
      final now = DateTime.now();
      final lastLeft = now.subtract(const Duration(minutes: 3)).millisecondsSinceEpoch;

      const doctorAccount = StaffAccount(
        id: 'doc_1',
        name: 'dr. Budi',
        email: 'dokter@pediagrow.com',
        passwordHash: 'hash',
        role: StaffRole.dokter,
        createdBy: 'system',
      );

      final sessionService = SessionService();
      await sessionService.saveStaffSession(doctorAccount);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('pediagrow_session_staff_last_left', lastLeft);

      final destination = await sessionService.getInitialDestination();
      expect(destination.page, isA<BerandaDokterPage>());
      expect(destination.expiredMessage, isNull);
    });

    test('Staf PMIK: Ditinggalkan < 10 menit langsung masuk BerandaPmikPage', () async {
      final now = DateTime.now();
      final lastLeft = now.subtract(const Duration(minutes: 4)).millisecondsSinceEpoch;

      const pmikAccount = StaffAccount(
        id: 'pmik_1',
        name: 'Admin PMIK',
        email: 'admin@pediagrow.com',
        passwordHash: 'hash',
        role: StaffRole.admin,
        createdBy: 'system',
      );

      final sessionService = SessionService();
      await sessionService.saveStaffSession(pmikAccount);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('pediagrow_session_staff_last_left', lastLeft);

      final destination = await sessionService.getInitialDestination();
      expect(destination.page, isA<BerandaPmikPage>());
      expect(destination.expiredMessage, isNull);
    });

    test('Staf Superadmin: Ditinggalkan < 10 menit langsung masuk BerandaSuperadminPage', () async {
      final now = DateTime.now();
      final lastLeft = now.subtract(const Duration(minutes: 4)).millisecondsSinceEpoch;

      const superadminAccount = StaffAccount(
        id: 'super_1',
        name: 'Superadmin',
        email: 'superadmin@pediagrow.com',
        passwordHash: 'hash',
        role: StaffRole.superadmin,
        createdBy: 'system',
      );

      final sessionService = SessionService();
      await sessionService.saveStaffSession(superadminAccount);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('pediagrow_session_staff_last_left', lastLeft);

      final destination = await sessionService.getInitialDestination();
      expect(destination.page, isA<BerandaSuperadminPage>());
      expect(destination.expiredMessage, isNull);
    });

    test('Staf: Ditinggalkan >= 10 menit diarahkan ke LoginPage dengan pesan kadaluarsa', () async {
      final now = DateTime.now();
      final expiredLeftTime = now.subtract(const Duration(minutes: 12)).millisecondsSinceEpoch;

      const doctorAccount = StaffAccount(
        id: 'doc_1',
        name: 'dr. Budi',
        email: 'dokter@pediagrow.com',
        passwordHash: 'hash',
        role: StaffRole.dokter,
        createdBy: 'system',
      );

      final sessionService = SessionService();
      await sessionService.saveStaffSession(doctorAccount);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('pediagrow_session_staff_last_left', expiredLeftTime);

      final destination = await sessionService.getInitialDestination();
      expect(destination.page, isA<LoginPage>());
      expect(destination.expiredMessage, contains('10 menit'));

      // Sesi SharedPreferences harus sudah dibersihkan
      expect(prefs.getString('pediagrow_session_role'), isNull);
    });
  });
}
