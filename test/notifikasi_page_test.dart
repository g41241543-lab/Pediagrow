import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/core/services/child_service.dart';
import 'package:pediagrow/core/services/notification_service.dart';
import 'package:pediagrow/features/Grafik_Pertumbuhan/pertumbuhan_grafik_page.dart';
import 'package:pediagrow/features/pengguna/beranda/notifikasi_page.dart';
import 'package:pediagrow/features/pengguna/profil/profil_ibu_page.dart';
import 'package:pediagrow/features/pengguna/profil/ubah_password_page.dart';
import 'package:pediagrow/features/pengguna/profil_anak/ubah_anak_page.dart';
import 'package:pediagrow/models/child_model.dart';
import 'package:pediagrow/models/notification_model.dart';
import 'package:pediagrow/shared/widgets/pedia_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NotificationService().clearNotifications();
    NotificationService().resetStuntingCheckedStatus();
  });

  testWidgets('NotifikasiPage renders empty state (Gambar 1) by default', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: NotifikasiPage(),
      ),
    );
    await tester.pump();

    // 1. Verify header elements
    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    // 2. Verify empty state text
    expect(find.text('Belum ada notifikasi'), findsOneWidget);
  });

  testWidgets('NotifikasiPage renders notification list (Gambar 2) when items exist', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Add 2 mock stunting notifications like Gambar 2
    NotificationService().addNotification(
      NotificationItem(
        id: 'stunting_1',
        title: 'Pengingat Bulanan',
        message:
            'Status stunting anak anda belum dicek pada bulan ini. Update sekarang supaya tumbuh kembangnya tetap terpantau optimal.',
        date: DateTime(2026, 7, 13),
        type: NotificationType.stunting,
      ),
    );
    NotificationService().addNotification(
      NotificationItem(
        id: 'stunting_2',
        title: 'Pengingat Bulanan',
        message:
            'Status stunting anak anda belum dicek pada bulan ini. Update sekarang supaya tumbuh kembangnya tetap terpantau optimal.',
        date: DateTime(2026, 5, 9),
        type: NotificationType.stunting,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: NotifikasiPage(),
      ),
    );
    await tester.pump();

    // Empty state should not be visible
    expect(find.text('Belum ada notifikasi'), findsNothing);

    // Notifications should be visible
    expect(find.text('Pengingat Bulanan'), findsNWidgets(2));
    expect(find.text('13 Juli 2026'), findsOneWidget);
    expect(find.text('09 Mei 2026'), findsOneWidget);
    expect(find.byIcon(Icons.mail_outline_rounded), findsNWidgets(2));
  });

  test('NotificationService handles monthly stunting reminder and stops when checked', () {
    final service = NotificationService();
    service.clearNotifications();
    service.resetStuntingCheckedStatus();

    // 1. Tanggal 5 (dalam rentang 1-10) -> harus buat notifikasi
    service.checkMonthlyStuntingReminder(currentDate: DateTime(2026, 8, 5));
    expect(service.notifications.length, equals(1));
    expect(service.notifications.first.title, equals('Pengingat Bulanan'));

    // 2. Pengguna melakukan cek stunting
    service.markStuntingCheckedThisMonth();

    // 3. Tanggal 6 (masih dalam rentang 1-10) -> tidak boleh buat notifikasi lagi
    service.checkMonthlyStuntingReminder(currentDate: DateTime(2026, 8, 6));
    expect(service.notifications.length, equals(1)); // tetap 1
  });

  test('NotificationService adds consultation ended notification', () {
    final service = NotificationService();
    service.clearNotifications();

    service.addConsultationEndedNotification(date: DateTime(2026, 9, 13));
    expect(service.notifications.length, equals(1));
    expect(service.notifications.first.title, equals('Konsultasi Selesai'));
    expect(
      service.notifications.first.message,
      contains('Konsultasi telah berakhir'),
    );
  });

  test('NotificationService adds booking success notification immediately', () {
    final service = NotificationService();
    service.clearNotifications();

    service.addBookingSuccessNotification(
      doctorName: 'dr. Reny Puspita, Sp.A',
      childName: 'Anita',
      dateFormatted: '20 Oktober 2026',
      timeSlot: '09:00 - 09:30',
    );

    expect(service.notifications.length, equals(1));
    expect(service.notifications.first.title, equals('Booking Konsultasi Berhasil'));
    expect(
      service.notifications.first.message,
      contains('Booking konsultasi anak Anita bersama dr. Reny Puspita, Sp.A'),
    );
    expect(
      service.notifications.first.message,
      contains('Google Kalender'),
    );
  });

  test('NotificationService triggers consultation arrived notification when time arrives', () {
    final service = NotificationService();
    service.clearNotifications();

    // Jadwal konsultasi yang waktunya telah tiba
    final pastTime = DateTime.now().subtract(const Duration(minutes: 1));
    service.addBookingReminderNotification(
      doctorName: 'dr. Reny Puspita, Sp.A',
      childName: 'Anita',
      dateFormatted: '20 Oktober 2026',
      timeSlot: '09:00 - 09:30',
      scheduledTime: pastTime,
    );

    expect(service.notifications.length, equals(1));
    expect(service.notifications.first.title, equals('Waktu Konsultasi Telah Tiba'));
    expect(
      service.notifications.first.message.toLowerCase(),
      contains('waktu konsultasi telah tiba'),
    );
  });

  test('NotificationService prevents duplicate notification content within 2 seconds', () {
    final service = NotificationService();
    service.clearNotifications();

    final item1 = NotificationItem(
      id: 'item_1',
      title: 'Berhasil Mengubah Data Anak',
      message: 'Data profil anak berhasil diperbarui',
      date: DateTime.now(),
      type: NotificationType.child,
    );
    final item2 = NotificationItem(
      id: 'item_2',
      title: 'Berhasil Mengubah Data Anak',
      message: 'Data profil anak berhasil diperbarui',
      date: DateTime.now(),
      type: NotificationType.child,
    );

    service.addNotification(item1);
    service.addNotification(item2); // Should be ignored by deduplication

    expect(service.notifications.length, equals(1));
  });

  test('resolveActionTitle resolves descriptive action titles based on user actions', () {
    // Ubah data
    expect(
      resolveActionTitle('Data profil anak berhasil diperbarui'),
      equals('Berhasil Mengubah Data Anak'),
    );
    expect(
      resolveActionTitle('Berhasil Memperbarui Profil'),
      equals('Berhasil Mengubah Profil'),
    );
    expect(
      resolveActionTitle('Kata sandi berhasil diperbarui'),
      equals('Berhasil Mengubah Kata Sandi'),
    );

    // Tambah data
    expect(
      resolveActionTitle('Profil anak berhasil ditambahkan'),
      equals('Berhasil Menambahkan Data Anak'),
    );
    expect(
      resolveActionTitle('Artikel berhasil ditambahkan'),
      equals('Berhasil Menambahkan Artikel'),
    );
    expect(
      resolveActionTitle('Resep MPASI berhasil ditambahkan'),
      equals('Berhasil Menambahkan Resep MPASI'),
    );

    // Hapus data
    expect(
      resolveActionTitle('Data anak berhasil dihapus'),
      equals('Berhasil Menghapus Data Anak'),
    );
    expect(
      resolveActionTitle('Artikel telah dihapus dari sistem'),
      equals('Berhasil Menghapus Artikel'),
    );
  });

  test('NotificationService detectType detects correct NotificationType', () {
    final service = NotificationService();

    expect(
      service.detectType('Berhasil Mengubah Data Anak', 'Data profil anak berhasil diperbarui'),
      equals(NotificationType.child),
    );
    expect(
      service.detectType('Berhasil Mengubah Profil', 'Profil ibu berhasil diperbarui'),
      equals(NotificationType.profile),
    );
    expect(
      service.detectType('Pemeriksaan Stunting', 'Status stunting anak'),
      equals(NotificationType.stunting),
    );
    expect(
      service.detectType('Booking Konsultasi Berhasil', 'Booking konsultasi dokter'),
      equals(NotificationType.consultation),
    );
    expect(
      service.detectType('Berhasil Menambahkan Artikel', 'Artikel kesehatan anak'),
      equals(NotificationType.article),
    );
    expect(
      service.detectType('Berhasil Menambahkan Resep MPASI', 'Resep puree pisang'),
      equals(NotificationType.recipe),
    );
  });

  testWidgets('Tapping child notification navigates to UbahAnakPage when child exists', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockChild = ChildModel(
      id: 'child_1',
      ownerId: 'user_1',
      name: 'Baby Anita',
      gender: 'Perempuan',
      birthDate: DateTime(2025, 1, 1),
      birthWeightKg: 3.2,
      birthHeightCm: 49.0,
      headCircumferenceCm: 33.0,
      isPremature: false,
    );
    ChildService().childrenNotifier.value = [mockChild];
    ChildService().activeChildNotifier.value = mockChild;

    NotificationService().addNotification(
      NotificationItem(
        id: 'child_edit_1',
        title: 'Berhasil Mengubah Data Anak',
        message: 'Data profil anak berhasil diperbarui',
        date: DateTime.now(),
        type: NotificationType.child,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: NotifikasiPage(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Berhasil Mengubah Data Anak'));
    await tester.pumpAndSettle();

    expect(find.byType(UbahAnakPage), findsOneWidget);
  });

  testWidgets('Tapping profile notification navigates to ProfilIbuPage', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    NotificationService().addNotification(
      NotificationItem(
        id: 'profil_edit_1',
        title: 'Berhasil Mengubah Profil',
        message: 'Berhasil Memperbarui Profil',
        date: DateTime.now(),
        type: NotificationType.profile,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: NotifikasiPage(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Berhasil Mengubah Profil'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfilIbuPage), findsOneWidget);
  });

  testWidgets('Tapping password notification navigates to UbahPasswordPage', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    NotificationService().addNotification(
      NotificationItem(
        id: 'password_edit_1',
        title: 'Berhasil Mengubah Kata Sandi',
        message: 'Kata sandi berhasil diperbarui',
        date: DateTime.now(),
        type: NotificationType.profile,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: NotifikasiPage(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Berhasil Mengubah Kata Sandi'));
    await tester.pumpAndSettle();

    expect(find.byType(UbahPasswordPage), findsOneWidget);
  });

  testWidgets('Tapping growth limit notification navigates to PertumbuhanGrafikPage', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockChild = ChildModel(
      id: 'child_1',
      ownerId: 'user_1',
      name: 'Baby Anita',
      gender: 'Perempuan',
      birthDate: DateTime(2025, 1, 1),
      birthWeightKg: 3.2,
      birthHeightCm: 49.0,
      headCircumferenceCm: 33.0,
      isPremature: false,
    );
    ChildService().childrenNotifier.value = [mockChild];
    ChildService().activeChildNotifier.value = mockChild;

    final title = resolveActionTitle(
      'Batas input data pertumbuhan 2x per bulan sudah tercapai untuk anak ini. Coba lagi bulan depan.',
      isError: true,
    );
    expect(title, equals('Batas Input Data Pertumbuhan'));

    NotificationService().addNotification(
      NotificationItem(
        id: 'growth_limit_1',
        title: title,
        message: 'Batas input data pertumbuhan 2x per bulan sudah tercapai untuk anak ini. Coba lagi bulan depan.',
        date: DateTime.now(),
        type: NotificationType.stunting,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: NotifikasiPage(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Batas Input Data Pertumbuhan'));
    await tester.pumpAndSettle();

    expect(find.byType(PertumbuhanGrafikPage), findsOneWidget);
  });
}
