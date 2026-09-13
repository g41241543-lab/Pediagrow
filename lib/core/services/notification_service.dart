import 'package:flutter/foundation.dart';
import '../../models/notification_model.dart';

/// Service singleton untuk mengelola sistem notifikasi PediaGrow.
///
/// Fitur sistem notifikasi otomatis:
/// 1. Notifikasi bulanan Pengingat Cek Stunting:
///    - Dibuat otomatis oleh sistem pada rentang tanggal 1 - 10 setiap bulan.
///    - Dikirim 1 hari sekali secara berturut-turut sampai tanggal 10.
///    - Jika pengguna telah melakukan cek stunting di bulan ini dalam rentang tanggal 1-10,
///      notifikasi otomatis dihentikan.
/// 2. Notifikasi Konsultasi Berakhir:
///    - Dibuat otomatis saat pengguna mengakhiri sesi chat konsultasi dengan dokter.
/// 3. Default awal: daftar notifikasi kosong (menampilkan empty state lonceng).
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// State daftar notifikasi secara reaktif
  final ValueNotifier<List<NotificationItem>> notificationsNotifier =
      ValueNotifier<List<NotificationItem>>([]);

  /// Mengambil seluruh notifikasi saat ini
  List<NotificationItem> get notifications => notificationsNotifier.value;

  /// Status apakah stunting sudah dicek pada bulan ini (dalam rentang tanggal 1-10)
  bool _hasCheckedStuntingThisMonth = false;
  bool get hasCheckedStuntingThisMonth => _hasCheckedStuntingThisMonth;

  /// Menandai bahwa pengguna telah melakukan cek stunting bulan ini
  void markStuntingCheckedThisMonth() {
    _hasCheckedStuntingThisMonth = true;
  }

  /// Reset status cek stunting (misal saat berganti bulan)
  void resetStuntingCheckedStatus() {
    _hasCheckedStuntingThisMonth = false;
  }

  /// Menambahkan notifikasi baru ke dalam daftar
  void addNotification(NotificationItem item) {
    // Hindari duplikasi ID
    final currentList = List<NotificationItem>.from(notificationsNotifier.value);
    currentList.removeWhere((element) => element.id == item.id);
    currentList.insert(0, item);
    notificationsNotifier.value = currentList;
  }

  /// Sistem otomatis memeriksa dan menambahkan pengingat cek stunting bulanan (tanggal 1-10)
  void checkMonthlyStuntingReminder({DateTime? currentDate}) {
    final now = currentDate ?? DateTime.now();
    final day = now.day;

    // Rentang tanggal 1-10
    if (day >= 1 && day <= 10) {
      // Jika pengguna sudah cek stunting, notifikasi otomatis dihentikan
      if (_hasCheckedStuntingThisMonth) {
        return;
      }

      // ID unik harian untuk bulan dan tahun ini (misal stunting_reminder_2026_07_05)
      final id = 'stunting_reminder_${now.year}_${now.month}_$day';
      final alreadyExists = notificationsNotifier.value.any((item) => item.id == id);

      if (!alreadyExists) {
        final newItem = NotificationItem(
          id: id,
          title: 'Pengingat Bulanan',
          message:
              'Status stunting anak anda belum dicek pada bulan ini. Update sekarang supaya tumbuh kembangnya tetap terpantau optimal.',
          date: now,
          type: NotificationType.stunting,
        );
        addNotification(newItem);
      }
    }
  }

  /// Menambahkan notifikasi saat konsultasi chat dengan dokter telah berakhir
  void addConsultationEndedNotification({DateTime? date}) {
    final now = date ?? DateTime.now();
    final id = 'consultation_ended_${now.millisecondsSinceEpoch}';

    final newItem = NotificationItem(
      id: id,
      title: 'Konsultasi Selesai',
      message:
          'Konsultasi telah berakhir dan anda bisa melihat riwayat konsultasi.',
      date: now,
      type: NotificationType.consultation,
    );
    addNotification(newItem);
  }

  /// Menghapus seluruh notifikasi (untuk testing atau reset ke empty state)
  void clearNotifications() {
    notificationsNotifier.value = [];
  }
}
