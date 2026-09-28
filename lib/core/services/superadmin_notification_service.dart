import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/superadmin_notification_model.dart';

/// Service singleton untuk mengelola sistem notifikasi Superadmin PediaGrow.
///
/// Fitur notifikasi otomatis by sistem:
/// 1. CRUD Artikel Kesehatan:
///    - Tambah artikel: "Artikel Ditambahkan"
///    - Edit artikel: "Artikel Diperbarui"
///    - Hapus artikel: "Artikel Dihapus"
/// 2. CRUD Resep MPASI:
///    - Tambah resep: "Resep MPASI Ditambahkan"
///    - Edit resep: "Resep MPASI Diperbarui"
///    - Hapus resep: "Resep MPASI Dihapus"
/// 3. CRUD Dokter:
///    - Tambah dokter: "Data Dokter Ditambahkan"
///    - Edit dokter: "Data Dokter Diperbarui"
///    - Hapus/nonaktifkan dokter: "Dokter Dihapus"
/// 4. CRUD PMIK:
///    - Tambah staf PMIK: "Akses PMIK Ditambahkan"
///    - Edit staf PMIK: "Akses PMIK Diperbarui"
///    - Hapus/nonaktifkan staf PMIK: "Akses PMIK Dihapus"
/// 5. Unduh Dataset Cek Stunting:
///    - Berhasil unduh: "Unduh Dataset Berhasil"
/// 6. Pengingat Unduh Dataset Bulanan:
///    - Title: "Info Dataset Cek Stunting"
///    - Pesan: "Segera unduh dataset hasil cek stunting pada bulan [Bulan Lalu] sebagai laporan penggunaan aplikasi atau laporan kasus"
///
/// Catatan Penting:
/// - Notifikasi HANYA dibuat secara otomatis oleh sistem jika Superadmin
///   melakukan aksi-aksi di atas (atau jadwal pengingat unduh dataset aktif).
/// - Jika tidak ada aksi yang dilakukan, daftar notifikasi akan kosong
///   dan menampilkan Tampilan Kosong (Empty State) yang identik dengan
///   halaman notifikasi pengguna.
class SuperadminNotificationService {
  static final SuperadminNotificationService _instance =
      SuperadminNotificationService._internal();
  factory SuperadminNotificationService() => _instance;
  SuperadminNotificationService._internal();

  static const String _storageKey = 'superadmin_notifications_v2';
  static const String _reminderHistoryKey = 'superadmin_dataset_reminder_history_v2';

  /// State daftar notifikasi Superadmin secara reaktif
  final ValueNotifier<List<SuperadminNotificationItem>> notificationsNotifier =
      ValueNotifier<List<SuperadminNotificationItem>>([]);

  /// Jumlah notifikasi yang belum dibaca (untuk badge di ikon lonceng Superadmin)
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  bool _isInitialized = false;

  /// Inisialisasi service: memuat data yang tersimpan dari SharedPreferences.
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await _loadFromPrefs();
  }

  /// Memuat notifikasi dari local storage.
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? jsonList = prefs.getStringList(_storageKey);
      if (jsonList != null && jsonList.isNotEmpty) {
        final List<SuperadminNotificationItem> loaded = [];
        for (final str in jsonList) {
          try {
            final Map<String, dynamic> map =
                json.decode(str) as Map<String, dynamic>;
            loaded.add(SuperadminNotificationItem.fromMap(map));
          } catch (e) {
            debugPrint('[SuperadminNotificationService] Parse error: $e');
          }
        }
        notificationsNotifier.value = loaded;
        unreadCountNotifier.value =
            loaded.where((item) => !item.isRead).length;
      } else {
        notificationsNotifier.value = [];
        unreadCountNotifier.value = 0;
      }
    } catch (e) {
      debugPrint('[SuperadminNotificationService] _loadFromPrefs error: $e');
    }
  }

  /// Menyimpan notifikasi ke local storage.
  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> jsonList = notificationsNotifier.value
          .map((item) => json.encode(item.toMap()))
          .toList();
      await prefs.setStringList(_storageKey, jsonList);
    } catch (e) {
      debugPrint('[SuperadminNotificationService] _saveToPrefs error: $e');
    }
  }

  /// Tandai semua notifikasi sudah dibaca (mereset badge lonceng).
  Future<void> markAllAsRead() async {
    final current = notificationsNotifier.value;
    if (current.isEmpty) return;

    final updated = current.map((item) => item.copyWith(isRead: true)).toList();
    notificationsNotifier.value = updated;
    unreadCountNotifier.value = 0;
    await _saveToPrefs();
  }

  /// Menambahkan notifikasi baru ke daftar (di posisi paling atas).
  Future<void> addNotification(SuperadminNotificationItem item) async {
    final currentList =
        List<SuperadminNotificationItem>.from(notificationsNotifier.value);
    // Hapus jika ada duplikasi ID yang sama
    currentList.removeWhere((element) => element.id == item.id);
    currentList.insert(0, item);
    notificationsNotifier.value = currentList;

    if (!item.isRead) {
      unreadCountNotifier.value = unreadCountNotifier.value + 1;
    }
    await _saveToPrefs();
  }

  /// Hapus seluruh notifikasi (untuk testing / reset)
  Future<void> clearNotifications() async {
    notificationsNotifier.value = [];
    unreadCountNotifier.value = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }

  // ===========================================================================
  // 1. CRUD ARTIKEL KESEHATAN
  // ===========================================================================

  Future<void> notifyArtikelTambah(String judul) async {
    final now = DateTime.now();
    final item = SuperadminNotificationItem(
      id: 'artikel_tambah_${now.millisecondsSinceEpoch}',
      title: 'Artikel Ditambahkan',
      message: 'Artikel "$judul" berhasil ditambahkan ke dalam sistem.',
      date: now,
      type: SuperadminNotificationType.artikel,
      actionType: SuperadminActionType.tambah,
      targetName: judul,
    );
    await addNotification(item);
  }

  Future<void> notifyArtikelUbah(String judul) async {
    final now = DateTime.now();
    final item = SuperadminNotificationItem(
      id: 'artikel_ubah_${now.millisecondsSinceEpoch}',
      title: 'Artikel Diperbarui',
      message: 'Artikel "$judul" berhasil diperbarui.',
      date: now,
      type: SuperadminNotificationType.artikel,
      actionType: SuperadminActionType.edit,
      targetName: judul,
    );
    await addNotification(item);
  }

  Future<void> notifyArtikelHapus(String judul) async {
    final now = DateTime.now();
    final item = SuperadminNotificationItem(
      id: 'artikel_hapus_${now.millisecondsSinceEpoch}',
      title: 'Artikel Dihapus',
      message: 'Artikel "$judul" telah dihapus dari sistem.',
      date: now,
      type: SuperadminNotificationType.artikel,
      actionType: SuperadminActionType.hapus,
      targetName: judul,
    );
    await addNotification(item);
  }

  // ===========================================================================
  // 2. CRUD RESEP MPASI
  // ===========================================================================

  Future<void> notifyResepTambah(String judul) async {
    final now = DateTime.now();
    final item = SuperadminNotificationItem(
      id: 'resep_tambah_${now.millisecondsSinceEpoch}',
      title: 'Resep MPASI Ditambahkan',
      message: 'Resep MPASI "$judul" berhasil ditambahkan ke dalam sistem.',
      date: now,
      type: SuperadminNotificationType.resepMpasi,
      actionType: SuperadminActionType.tambah,
      targetName: judul,
    );
    await addNotification(item);
  }

  Future<void> notifyResepUbah(String judul) async {
    final now = DateTime.now();
    final item = SuperadminNotificationItem(
      id: 'resep_ubah_${now.millisecondsSinceEpoch}',
      title: 'Resep MPASI Diperbarui',
      message: 'Resep MPASI "$judul" berhasil diperbarui.',
      date: now,
      type: SuperadminNotificationType.resepMpasi,
      actionType: SuperadminActionType.edit,
      targetName: judul,
    );
    await addNotification(item);
  }

  Future<void> notifyResepHapus(String judul) async {
    final now = DateTime.now();
    final item = SuperadminNotificationItem(
      id: 'resep_hapus_${now.millisecondsSinceEpoch}',
      title: 'Resep MPASI Dihapus',
      message: 'Resep MPASI "$judul" telah dihapus dari sistem.',
      date: now,
      type: SuperadminNotificationType.resepMpasi,
      actionType: SuperadminActionType.hapus,
      targetName: judul,
    );
    await addNotification(item);
  }

  // ===========================================================================
  // 3. CRUD DOKTER
  // ===========================================================================

  Future<void> notifyDokterTambah(String namaDokter) async {
    final now = DateTime.now();
    final item = SuperadminNotificationItem(
      id: 'dokter_tambah_${now.millisecondsSinceEpoch}',
      title: 'Data Dokter Ditambahkan',
      message:
          'Akun dan data dokter "$namaDokter" berhasil ditambahkan ke dalam sistem.',
      date: now,
      type: SuperadminNotificationType.dokter,
      actionType: SuperadminActionType.tambah,
      targetName: namaDokter,
    );
    await addNotification(item);
  }

  Future<void> notifyDokterUbah(String namaDokter) async {
    final now = DateTime.now();
    final item = SuperadminNotificationItem(
      id: 'dokter_ubah_${now.millisecondsSinceEpoch}',
      title: 'Data Dokter Diperbarui',
      message: 'Data profil dokter "$namaDokter" berhasil diperbarui.',
      date: now,
      type: SuperadminNotificationType.dokter,
      actionType: SuperadminActionType.edit,
      targetName: namaDokter,
    );
    await addNotification(item);
  }

  Future<void> notifyDokterHapus(String namaDokter) async {
    final now = DateTime.now();
    final item = SuperadminNotificationItem(
      id: 'dokter_hapus_${now.millisecondsSinceEpoch}',
      title: 'Dokter Dihapus',
      message: 'Data dan akun dokter "$namaDokter" telah dihapus dari sistem.',
      date: now,
      type: SuperadminNotificationType.dokter,
      actionType: SuperadminActionType.hapus,
      targetName: namaDokter,
    );
    await addNotification(item);
  }

  // ===========================================================================
  // 4. CRUD PMIK / STAF ADMIN
  // ===========================================================================

  Future<void> notifyPmikTambah(String namaStaf) async {
    final now = DateTime.now();
    final item = SuperadminNotificationItem(
      id: 'pmik_tambah_${now.millisecondsSinceEpoch}',
      title: 'Akses PMIK Ditambahkan',
      message: 'Akun staf PMIK "$namaStaf" berhasil ditambahkan ke dalam sistem.',
      date: now,
      type: SuperadminNotificationType.pmik,
      actionType: SuperadminActionType.tambah,
      targetName: namaStaf,
    );
    await addNotification(item);
  }

  Future<void> notifyPmikUbah(String namaStaf) async {
    final now = DateTime.now();
    final item = SuperadminNotificationItem(
      id: 'pmik_ubah_${now.millisecondsSinceEpoch}',
      title: 'Akses PMIK Diperbarui',
      message: 'Data staf PMIK "$namaStaf" berhasil diperbarui.',
      date: now,
      type: SuperadminNotificationType.pmik,
      actionType: SuperadminActionType.edit,
      targetName: namaStaf,
    );
    await addNotification(item);
  }

  Future<void> notifyPmikHapus(String namaStaf) async {
    final now = DateTime.now();
    final item = SuperadminNotificationItem(
      id: 'pmik_hapus_${now.millisecondsSinceEpoch}',
      title: 'Akses PMIK Dihapus',
      message: 'Akses staf PMIK "$namaStaf" telah dihapus dari sistem.',
      date: now,
      type: SuperadminNotificationType.pmik,
      actionType: SuperadminActionType.hapus,
      targetName: namaStaf,
    );
    await addNotification(item);
  }

  // ===========================================================================
  // 5. UNDUH DATASET BERHASIL
  // ===========================================================================

  Future<void> notifyDatasetDownloaded({String? bulan}) async {
    final now = DateTime.now();
    final bulanStr = bulan != null && bulan.isNotEmpty ? ' bulan $bulan' : '';
    final item = SuperadminNotificationItem(
      id: 'dataset_unduh_${now.millisecondsSinceEpoch}',
      title: 'Unduh Dataset Berhasil',
      message:
          'Dataset hasil cek stunting$bulanStr berhasil diunduh sebagai laporan penggunaan aplikasi atau laporan kasus.',
      date: now,
      type: SuperadminNotificationType.unduhDataset,
      actionType: SuperadminActionType.unduh,
    );
    await addNotification(item);
  }

  // ===========================================================================
  // 6. PENGINGAT UNDUH DATASET BULANAN (Sesuai Teks Gambar Referensi)
  // ===========================================================================

  /// Mengecek dan membuat notifikasi pengingat unduh dataset bulanan jika belum ada.
  /// Format dan teks persis seperti pada gambar:
  /// - Judul: "Info Dataset Cek Stunting"
  /// - Pesan: "Segera unduh dataset hasil cek stunting pada bulan [Bulan Lalu] sebagai laporan penggunaan aplikasi atau laporan kasus"
  /// - Tanggal: 1 [Bulan Ini] [Tahun]
  Future<void> checkDatasetReminder({DateTime? mockDate}) async {
    final now = mockDate ?? DateTime.now();

    // Pengingat hanya aktif pada tanggal 1 setiap bulan
    if (now.day != 1) return;
    const indonesianMonths = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];

    // Hitung bulan & tahun sebelumnya
    final int prevMonth = now.month == 1 ? 12 : now.month - 1;
    final int prevYear  = now.month == 1 ? now.year - 1 : now.year;
    final String prevMonthName = indonesianMonths[prevMonth - 1];

    final key = 'dataset_reminder_${now.year}_${now.month}';
    final prefs = await SharedPreferences.getInstance();
    final reminded = prefs.getBool('${_reminderHistoryKey}_$key') ?? false;

    if (!reminded) {
      final item = SuperadminNotificationItem(
        id: 'reminder_dataset_${now.year}_${now.month}',
        title: 'Info Dataset Cek Stunting',
        message:
            'Segera unduh dataset hasil cek stunting pada bulan '
            '$prevMonthName $prevYear sebagai laporan penggunaan '
            'aplikasi atau laporan kasus.',
        date: now, // tanggal notifikasi = hari ini (tanggal 1)
        type: SuperadminNotificationType.pengingatDataset,
        actionType: SuperadminActionType.pengingat,
      );
      await addNotification(item);
      await prefs.setBool('${_reminderHistoryKey}_$key', true);
    }
  }
}
