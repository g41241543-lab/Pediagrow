import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pediagrow/core/services/notification_service.dart';
import 'package:pediagrow/features/pengguna/beranda/notifikasi_page.dart';
import 'package:pediagrow/models/notification_model.dart';

void main() {
  setUp(() {
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
}
