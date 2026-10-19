import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../models/notification_model.dart';
import 'local_push_service.dart';

/// Item pengingat jadwal booking yang masih menunggu waktu tiba
class _PendingBookingReminder {
  final String id;
  final String doctorName;
  final String childName;
  final String dateFormatted;
  final String timeSlot;
  final DateTime scheduledTime;

  _PendingBookingReminder({
    required this.id,
    required this.doctorName,
    required this.childName,
    required this.dateFormatted,
    required this.timeSlot,
    required this.scheduledTime,
  });
}

/// Service singleton untuk mengelola sistem notifikasi PediaGrow.
///
/// Fitur sistem notifikasi otomatis:
/// 1. Notifikasi bulanan Pengingat Cek Stunting:
///    - Dibuat otomatis oleh sistem pada rentang tanggal 1 - 10 setiap bulan (1 kali per hari).
///    - Jika pengguna telah melakukan cek stunting di rentang tanggal 1-10, notifikasi otomatis
///      hilang/dihapus dari daftar dan tidak muncul lagi hari ini maupun besok.
///    - Jika hingga tanggal 10 pengguna belum melakukan cek stunting, notifikasi tetap berhenti di tanggal 10.
/// 2. Notifikasi Konsultasi Berakhir:
///    - Dibuat otomatis setiap kali pengguna melakukan/mengakhiri sesi konsultasi dengan dokter.
///    - Setiap konsultasi selalu menghasilkan 1 notifikasi baru di daftar dan menambah badge lonceng.
/// 3. Notifikasi Pengingat Jadwal Booking Konsultasi:
///    - HANYA muncul di HP dan daftar notifikasi ketika waktu jadwal konsultasi yang dipilih telah tiba.
/// 4. Badge angka unread tersedia via [unreadCountNotifier] untuk ditampilkan di ikon lonceng.
/// 5. Default awal: daftar notifikasi kosong (menampilkan empty state lonceng).
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal() {
    _startReminderCheckTimer();
  }

  /// State daftar notifikasi secara reaktif
  final ValueNotifier<List<NotificationItem>> notificationsNotifier =
      ValueNotifier<List<NotificationItem>>([]);

  /// Jumlah notifikasi yang belum dibaca (untuk badge di ikon lonceng)
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  /// Timer pengecekan waktu tiba pengingat jadwal konsultasi
  Timer? _reminderCheckTimer;
  final List<_PendingBookingReminder> _pendingBookingReminders = [];
  final Set<String> _triggeredReminderIds = {};

  void _startReminderCheckTimer() {
    _reminderCheckTimer?.cancel();
    _reminderCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      checkPendingBookingReminders();
    });
  }

  /// Mengambil seluruh notifikasi saat ini
  List<NotificationItem> get notifications => notificationsNotifier.value;

  /// Jumlah notifikasi yang belum dibaca
  int get unreadCount => unreadCountNotifier.value;

  // ---------------------------------------------------------------------------
  // STATUS CEK STUNTING PER BULAN
  // Kunci: "YYYY_MM" — misal "2026_09"
  // ---------------------------------------------------------------------------

  /// Set bulan-tahun yang sudah dilakukan cek stunting (misal {"2026_09"})
  final Set<String> _stuntingCheckedMonths = {};

  /// Menandai bahwa pengguna telah melakukan cek stunting pada bulan saat ini.
  /// Otomatis menghapus notifikasi pengingat stunting dari daftar sehingga
  /// tidak lagi muncul untuk hari ini maupun besok dalam rentang tanggal 1–10.
  void markStuntingCheckedThisMonth({DateTime? currentDate}) {
    final now = currentDate ?? DateTime.now();
    final key = '${now.year}_${now.month.toString().padLeft(2, '0')}';
    _stuntingCheckedMonths.add(key);

    // Otomatis hilangkan notifikasi pengingat stunting dari daftar notifikasi
    final currentList = List<NotificationItem>.from(notificationsNotifier.value);
    int removedUnread = 0;
    currentList.removeWhere((item) {
      if (item.type == NotificationType.stunting) {
        if (!item.isRead) removedUnread++;
        return true;
      }
      return false;
    });
    notificationsNotifier.value = currentList;
    if (removedUnread > 0) {
      unreadCountNotifier.value =
          (unreadCountNotifier.value - removedUnread).clamp(0, 999);
    }
  }

  /// Mengecek apakah pengguna sudah cek stunting pada bulan tertentu
  bool hasCheckedStuntingForMonth(DateTime date) {
    final key = '${date.year}_${date.month.toString().padLeft(2, '0')}';
    return _stuntingCheckedMonths.contains(key);
  }

  /// [Deprecated — gunakan markStuntingCheckedThisMonth()] untuk kompatibilitas lama
  bool get hasCheckedStuntingThisMonth =>
      hasCheckedStuntingForMonth(DateTime.now());

  /// [Deprecated] Hanya untuk kompatibilitas lama
  void resetStuntingCheckedStatus() {
    // Tidak diperlukan lagi — tracking dilakukan per bulan secara otomatis
  }

  // ---------------------------------------------------------------------------
  // MANAJEMEN NOTIFIKASI
  // ---------------------------------------------------------------------------

  /// Menambahkan notifikasi baru ke dalam daftar (duplikasi ID dicegah).
  /// Notifikasi baru muncul di posisi paling atas.
  /// Sekaligus menampilkan notifikasi sistem (status bar HP) via [LocalPushService].
  void addNotification(NotificationItem item) {
    final currentList = List<NotificationItem>.from(notificationsNotifier.value);
    // Hindari duplikasi ID
    currentList.removeWhere((element) => element.id == item.id);
    currentList.insert(0, item);
    notificationsNotifier.value = currentList;
    // Tambah unread count jika notifikasi baru belum dibaca
    if (!item.isRead) {
      unreadCountNotifier.value = unreadCountNotifier.value + 1;
    }

    // Tampilkan notifikasi sistem (push lokal) — mengikuti role aktif yang sedang login
    LocalPushService().show(
      title: item.title,
      body: item.message,
      targetRole: LocalPushService().activeRole,
    );
  }

  /// Tandai semua notifikasi sebagai sudah dibaca (dipanggil saat buka halaman notifikasi)
  void markAllAsRead() {
    final currentList = notificationsNotifier.value;
    if (currentList.isEmpty) return;
    // Update isRead = true untuk semua item
    final updatedList = currentList
        .map((item) => item.isRead ? item : item.copyWith(isRead: true))
        .toList();
    notificationsNotifier.value = updatedList;
    unreadCountNotifier.value = 0;
  }

  // ---------------------------------------------------------------------------
  // PENGINGAT CEK STUNTING BULANAN
  // ---------------------------------------------------------------------------

  /// Sistem otomatis memeriksa dan menambahkan pengingat cek stunting bulanan.
  void checkMonthlyStuntingReminder({DateTime? currentDate}) {
    final now = currentDate ?? DateTime.now();
    final day = now.day;

    // Hanya proses jika tanggal masih di rentang 1–10
    if (day < 1 || day > 10) return;

    // Jika pengguna sudah cek stunting bulan ini, hentikan notifikasi
    if (hasCheckedStuntingForMonth(now)) return;

    // ID unik harian: stunting_reminder_YYYY_MM_DD
    final id =
        'stunting_reminder_${now.year}_${now.month.toString().padLeft(2, '0')}_${day.toString().padLeft(2, '0')}';
    final alreadyExists =
        notificationsNotifier.value.any((item) => item.id == id);

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

  // ---------------------------------------------------------------------------
  // NOTIFIKASI KONSULTASI
  // ---------------------------------------------------------------------------

  /// Menambahkan notifikasi saat konsultasi chat dengan dokter telah berakhir.
  void addConsultationEndedNotification({DateTime? date}) {
    final now = date ?? DateTime.now();
    final id = 'consultation_ended_${now.microsecondsSinceEpoch}';
    final newItem = NotificationItem(
      id: id,
      title: 'Konsultasi Selesai',
      message:
          'Konsultasi telah berakhir. Ketuk untuk melihat riwayat konsultasi Anda.',
      date: now,
      type: NotificationType.consultation,
    );
    addNotification(newItem);
  }

  /// Menambahkan notifikasi bahwa booking konsultasi dengan dokter berhasil dilakukan.
  /// Notifikasi ini langsung muncul di status bar HP dan tercatat di daftar notifikasi.
  void addBookingSuccessNotification({
    required String doctorName,
    required String childName,
    required String dateFormatted,
    required String timeSlot,
    DateTime? scheduledTime,
    DateTime? bookingDate,
  }) {
    final now = DateTime.now();
    final id =
        'booking_success_${doctorName.trim()}_${childName.trim()}_${dateFormatted.replaceAll('/', '_')}_${timeSlot.replaceAll(':', '_').replaceAll(' ', '')}_${now.millisecondsSinceEpoch}';

    final newItem = NotificationItem(
      id: id,
      title: 'Booking Konsultasi Berhasil',
      message:
          'Booking konsultasi anak $childName bersama $doctorName pada $dateFormatted ($timeSlot) berhasil dilakukan dan telah tersambung dengan Google Kalender.',
      date: now,
      type: NotificationType.consultation,
    );
    addNotification(newItem);
  }

  /// Menambahkan / menjadwalkan notifikasi saat waktu konsultasi telah tiba.
  ///
  /// JIKA waktu jadwal konsultasi masih di masa depan (belum tiba), notifikasi
  /// dijadwalkan di sistem HP (status bar) via [LocalPushService.schedule] serta
  /// disimpan dalam antrean [_pendingBookingReminders], dan baru muncul di HP &
  /// daftar notifikasi aplikasi ketika waktu konsultasi tersebut telah tiba.
  void addBookingReminderNotification({
    required String doctorName,
    required String childName,
    required String dateFormatted,
    required String timeSlot,
    DateTime? scheduledTime,
    String? bookingId,
  }) {
    final now = DateTime.now();
    final id = bookingId != null && bookingId.isNotEmpty
        ? 'booking_reminder_$bookingId'
        : 'booking_reminder_${doctorName.trim()}_${childName.trim()}_${dateFormatted.replaceAll('/', '_')}_${timeSlot.replaceAll(':', '_').replaceAll(' ', '')}';

    const title = 'Waktu Konsultasi Telah Tiba';
    final message =
        'Waktu konsultasi telah tiba! Jadwal konsultasi anak $childName bersama $doctorName ($timeSlot) sudah dimulai. Silakan masuk ke ruang konsultasi.';

    // Jika waktu konsultasi dijadwalkan di masa depan (belum tiba)
    if (scheduledTime != null && scheduledTime.isAfter(now)) {
      final alreadyRegistered =
          _pendingBookingReminders.any((r) => r.id == id) ||
              _triggeredReminderIds.contains(id);
      if (!alreadyRegistered) {
        _pendingBookingReminders.add(
          _PendingBookingReminder(
            id: id,
            doctorName: doctorName,
            childName: childName,
            dateFormatted: dateFormatted,
            timeSlot: timeSlot,
            scheduledTime: scheduledTime,
          ),
        );

        // Jadwalkan notifikasi sistem di HP agar muncul saat waktu tiba (bahkan jika aplikasi ditutup)
        final notifIntId = id.hashCode.abs() % 0x7FFFFFFF;
        LocalPushService().schedule(
          id: notifIntId,
          title: title,
          body: message,
          scheduledDate: scheduledTime,
          targetRole: PushRole.pengguna,
        );
      }
      return;
    }

    // Jika waktu konsultasi memang sudah tiba saat ini
    if (!_triggeredReminderIds.contains(id)) {
      _triggeredReminderIds.add(id);
      final newItem = NotificationItem(
        id: id,
        title: title,
        message: message,
        date: scheduledTime ?? now,
        type: NotificationType.consultation,
      );
      addNotification(newItem);
    }
  }

  /// Sinkronisasi daftar booking aktif dari Firestore untuk memastikan
  /// semua jadwal memiliki alarm/pengingat tepat waktu meskipun aplikasi
  /// baru dibuka kembali setelah ditutup.
  void syncActiveBookings(List<dynamic> bookings) {
    for (final b in bookings) {
      try {
        if (b.status == 'Dibatalkan' || b.isExpired) continue;
        addBookingReminderNotification(
          doctorName: b.doctor.name,
          childName: b.child.name,
          dateFormatted: b.formattedDate,
          timeSlot: b.scheduledTimeSlot,
          scheduledTime: b.scheduledStartDateTime,
          bookingId: b.id,
        );
      } catch (e) {
        debugPrint('[NotificationService] syncActiveBookings item error: $e');
      }
    }
  }

  /// Memeriksa antrean pengingat jadwal booking konsultasi secara berkala.
  /// Notifikasi baru akan dikirimkan ke HP & sistem saat waktu jadwalnya sudah tiba.
  void checkPendingBookingReminders() {
    final now = DateTime.now();
    final toTrigger = <_PendingBookingReminder>[];

    _pendingBookingReminders.removeWhere((reminder) {
      if (_triggeredReminderIds.contains(reminder.id)) {
        return true;
      }
      if (now.isAfter(reminder.scheduledTime) ||
          now.isAtSameMomentAs(reminder.scheduledTime)) {
        // Cek jika belum kadaluarsa lebih dari 12 jam
        if (now.difference(reminder.scheduledTime).inHours < 12) {
          toTrigger.add(reminder);
        }
        return true;
      }
      return false;
    });

    for (final reminder in toTrigger) {
      _triggeredReminderIds.add(reminder.id);
      final newItem = NotificationItem(
        id: reminder.id,
        title: 'Waktu Konsultasi Telah Tiba',
        message:
            'Waktu konsultasi telah tiba! Jadwal konsultasi anak ${reminder.childName} bersama ${reminder.doctorName} (${reminder.timeSlot}) sudah dimulai. Silakan masuk ke ruang konsultasi.',
        date: reminder.scheduledTime,
        type: NotificationType.consultation,
      );
      addNotification(newItem);
    }
  }

  /// Menghapus seluruh notifikasi (untuk testing atau reset ke empty state)
  void clearNotifications() {
    notificationsNotifier.value = [];
    unreadCountNotifier.value = 0;
  }
}
