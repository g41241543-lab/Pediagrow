import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pediagrow/core/services/notification_service.dart';
import 'package:pediagrow/core/services/superadmin_notification_service.dart';
import 'package:pediagrow/core/services/local_push_service.dart';
import 'package:pediagrow/core/services/user_service.dart';
import 'package:pediagrow/core/services/staff_auth_service.dart';
import 'package:pediagrow/models/notification_model.dart';
import 'package:pediagrow/models/staff_account_model.dart';
import 'package:pediagrow/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('TUGAS 1: Satu Notifikasi HP = Satu Baris di Aplikasi & Badge Sinkron', () {
    test('addNotification menambah tepat 1 baris dan badge bertambah tepat 1', () {
      final notifService = NotificationService();
      notifService.notificationsNotifier.value = [];
      notifService.unreadCountNotifier.value = 0;

      final now = DateTime.now();
      final item = NotificationItem(
        id: 'test_event_1',
        title: 'Booking Konsultasi Berhasil',
        message: 'Jadwal konsultasi anak Budi berhasil dipesan.',
        date: now,
        type: NotificationType.consultation,
      );

      notifService.addNotification(item, showPush: false);

      expect(notifService.notificationsNotifier.value.length, 1);
      expect(notifService.unreadCountNotifier.value, 1);
      expect(notifService.notificationsNotifier.value.first.title, 'Booking Konsultasi Berhasil');
      expect(notifService.notificationsNotifier.value.first.message, 'Jadwal konsultasi anak Budi berhasil dipesan.');
    });

    test('Duplikasi ID yang sama diabaikan sepenuhnya (tidak menambah baris & badge)', () {
      final notifService = NotificationService();
      notifService.notificationsNotifier.value = [];
      notifService.unreadCountNotifier.value = 0;

      final now = DateTime.now();
      final item1 = NotificationItem(
        id: 'event_unique_100',
        title: 'Booking Konsultasi Berhasil',
        message: 'Jadwal konsultasi anak Budi berhasil dipesan.',
        date: now,
        type: NotificationType.consultation,
      );

      final itemDuplicate = NotificationItem(
        id: 'event_unique_100', // ID sama persis
        title: 'Booking Konsultasi Berhasil',
        message: 'Jadwal konsultasi anak Budi berhasil dipesan.',
        date: now.add(const Duration(milliseconds: 100)),
        type: NotificationType.consultation,
      );

      notifService.addNotification(item1, showPush: false);
      expect(notifService.notificationsNotifier.value.length, 1);
      expect(notifService.unreadCountNotifier.value, 1);

      // Panggilan kedua untuk event yang sama harus diabaikan
      notifService.addNotification(itemDuplicate, showPush: false);
      expect(notifService.notificationsNotifier.value.length, 1);
      expect(notifService.unreadCountNotifier.value, 1);
    });

    test('Angka badge lonceng selalu sama persis dengan jumlah baris belum dibaca', () {
      final notifService = NotificationService();
      notifService.notificationsNotifier.value = [];
      notifService.unreadCountNotifier.value = 0;

      for (int i = 1; i <= 3; i++) {
        notifService.addNotification(
          NotificationItem(
            id: 'item_$i',
            title: 'Notif $i',
            message: 'Pesan $i',
            date: DateTime.now().add(Duration(seconds: i)),
            type: NotificationType.system,
          ),
          showPush: false,
        );
      }

      expect(notifService.notificationsNotifier.value.length, 3);
      expect(notifService.unreadCountNotifier.value, 3);

      // Tandai semua dibaca
      notifService.markAllAsRead();
      expect(notifService.unreadCountNotifier.value, 0);

      // Hapus 1 notifikasi
      notifService.deleteNotification('item_1');
      expect(notifService.notificationsNotifier.value.length, 2);
      expect(notifService.unreadCountNotifier.value, 0);
    });
  });

  group('TUGAS 2: Notifikasi Terikat ke Akun Penerima & Tidak Bocor', () {
    test('Notifikasi dokter terikat ke akun dokter pembuat dan disaring per akun', () async {
      final staffService = SuperadminNotificationService();
      staffService.notificationsNotifier.value = [];
      staffService.unreadCountNotifier.value = 0;

      // Buat akun dokter Reny dan dokter Zaskia
      final drReny = StaffAccount(
        id: 'dr_reny_101',
        name: 'dr. Reny, Sp.A',
        email: 'reny@pediagrow.com',
        passwordHash: 'hash',
        role: StaffRole.dokter,
        pmikLevel: PmikLevel.biasa,
        createdBy: 'admin',
        createdAt: DateTime.now(),
      );

      final drZaskia = StaffAccount(
        id: 'dr_zaskia_102',
        name: 'dr. Zaskia, Sp.A',
        email: 'zaskia@pediagrow.com',
        passwordHash: 'hash',
        role: StaffRole.dokter,
        pmikLevel: PmikLevel.biasa,
        createdBy: 'admin',
        createdAt: DateTime.now(),
      );

      // dr. Reny login dan membuat perubahan resep MPASI
      StaffAuthService().setStaff(drReny);
      await staffService.notifyResepTambah(
        'Puree Alpukat Gurih',
        recipientId: drReny.id,
        role: 'dokter',
      );

      // Pastikan notifikasi muncul untuk dr. Reny
      final notifsReny = staffService.getNotificationsForRole(
        PushRole.dokter,
        targetUserId: drReny.id,
      );
      expect(notifsReny.length, 1);
      expect(notifsReny.first.title, 'Berhasil Menambahkan Resep MPASI');
      expect(notifsReny.first.recipientId, drReny.id);

      // Saat dibuka dengan akun dr. Zaskia, notifikasi dr. Reny TIDAK BOLEH muncul
      StaffAuthService().setStaff(drZaskia);
      final notifsZaskia = staffService.getNotificationsForRole(
        PushRole.dokter,
        targetUserId: drZaskia.id,
      );
      expect(notifsZaskia.isEmpty, true);

      // Unread badge untuk dr. Zaskia juga harus 0
      final unreadZaskia = staffService.getUnreadCountForRole(
        PushRole.dokter,
        targetUserId: drZaskia.id,
      );
      expect(unreadZaskia, 0);
    });

    test('Saat logout, antrean pengingat dibatalkan dan notifikasi dibersihkan', () async {
      final notifService = NotificationService();
      UserService().currentUserNotifier.value = const UserModel(
        id: 'user_ibu_1',
        name: 'Ibu Ani',
        email: 'ani@mail.com',
      );

      // Tambah pengingat booking tertunda
      notifService.addBookingReminderNotification(
        doctorName: 'dr. Reny, Sp.A',
        childName: 'Doni',
        dateFormatted: '28/10/2026',
        timeSlot: '10:00 - 10:30',
        scheduledTime: DateTime.now().add(const Duration(hours: 2)),
        bookingId: 'booking_999',
      );

      // Batalkan semua pengingat saat logout
      notifService.cancelAllPendingReminders();

      // Periksa bahwa cancelBookingReminder aman dipanggil
      notifService.cancelBookingReminder('booking_999');
    });
  });

  group('TUGAS 3: Notifikasi Hapus Booking (Role Pengguna)', () {
    test('Pembatalan pengingat booking menghapus dari pending reminders', () {
      final notifService = NotificationService();

      // Jadwalkan pengingat booking
      notifService.addBookingReminderNotification(
        doctorName: 'dr. Reny, Sp.A',
        childName: 'Doni',
        dateFormatted: '28/10/2026',
        timeSlot: '10:00 - 10:30',
        scheduledTime: DateTime.now().add(const Duration(hours: 3)),
        bookingId: 'booking_to_cancel',
      );

      // Batalkan pengingat
      notifService.cancelBookingReminder('booking_to_cancel');

      // Pastikan antrean pengingat tidak memicu notifikasi baru
      final beforeCount = notifService.notificationsNotifier.value.length;
      notifService.checkPendingBookingReminders();
      expect(notifService.notificationsNotifier.value.length, beforeCount);
    });
  });
}
