import 'package:flutter/foundation.dart';
import '../../models/notification_model.dart';

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
/// 3. Badge angka unread tersedia via [unreadCountNotifier] untuk ditampilkan di ikon lonceng.
/// 4. Default awal: daftar notifikasi kosong (menampilkan empty state lonceng).
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// State daftar notifikasi secara reaktif
  final ValueNotifier<List<NotificationItem>> notificationsNotifier =
      ValueNotifier<List<NotificationItem>>([]);

  /// Jumlah notifikasi yang belum dibaca (untuk badge di ikon lonceng)
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

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
  ///
  /// Aturan:
  /// - Hanya mengirim notifikasi pada rentang tanggal 1–10 setiap bulan.
  /// - Jika pengguna sudah cek stunting bulan ini → tidak kirim notifikasi.
  /// - Jika sudah lewat tanggal 10 → tidak kirim notifikasi.
  /// - Setiap hari (dalam rentang 1–10) hanya membuat 1 notifikasi unik.
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
  ///
  /// Setiap kali pengguna melakukan atau mengakhiri sesi konsultasi dengan dokter,
  /// selalu dibuatkan notifikasi baru di dalam daftar notifikasi dan menambah
  /// badge notifikasi yang belum dibaca pada ikon lonceng.
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

  /// Menghapus seluruh notifikasi (untuk testing atau reset ke empty state)
  void clearNotifications() {
    notificationsNotifier.value = [];
    unreadCountNotifier.value = 0;
  }
}
