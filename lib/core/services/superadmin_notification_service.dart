import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/superadmin_notification_model.dart';
import 'local_push_service.dart';
import 'staff_auth_service.dart';
import 'user_service.dart';

/// Service singleton untuk mengelola sistem notifikasi Superadmin & Staf PediaGrow.
/// Notifikasi staf disimpan secara persisten per akun staf (`staff_notifications_{staffId}`),
/// sehingga notifikasi terikat ke akun penerimanya dan tidak bocor saat logout/ganti akun.
class SuperadminNotificationService {
  static final SuperadminNotificationService _instance =
      SuperadminNotificationService._internal();
  factory SuperadminNotificationService() => _instance;
  SuperadminNotificationService._internal();

  static const String _storageKey = 'superadmin_notifications_v2';
  static const String _reminderHistoryKey =
      'superadmin_dataset_reminder_history_v2';

  /// State daftar notifikasi Superadmin secara reaktif
  final ValueNotifier<List<SuperadminNotificationItem>> notificationsNotifier =
      ValueNotifier<List<SuperadminNotificationItem>>([]);

  /// Jumlah notifikasi yang belum dibaca (untuk badge di ikon lonceng Superadmin)
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  bool _isInitialized = false;
  String _lastKnownStaffId = '';

  /// Menghasilkan kunci penyimpanan terisolasi per akun staf
  String _getStorageKeyForStaff([String? customId]) {
    final staffId = customId ?? StaffAuthService().currentStaff?.id;
    if (staffId != null && staffId.isNotEmpty) {
      return 'staff_notifications_$staffId';
    }
    final currentStaff = StaffAuthService().currentStaff;
    if (currentStaff != null && currentStaff.email.isNotEmpty) {
      return 'staff_notifications_${currentStaff.email.replaceAll('@', '_').replaceAll('.', '_')}';
    }
    return _storageKey;
  }

  /// Inisialisasi service: memuat data yang tersimpan dari SharedPreferences.
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    _lastKnownStaffId = StaffAuthService().currentStaff?.id ?? '';
    _attachStaffListener();
    await _loadFromPrefs();
  }

  /// Memuat notifikasi untuk akun staf tertentu (misal saat login/restore sesi)
  Future<void> loadForStaff(String staffId) async {
    _lastKnownStaffId = staffId;
    await _loadFromPrefs();
  }

  void _attachStaffListener() {
    StaffAuthService().currentStaffNotifier.addListener(() async {
      final currentStaff = StaffAuthService().currentStaff;
      final newStaffId = currentStaff?.id ?? '';
      if (newStaffId != _lastKnownStaffId) {
        _lastKnownStaffId = newStaffId;
        if (newStaffId.isEmpty) {
          // Staf keluar / ganti akun: kosongkan notifikasi aktif agar tidak bocor
          notificationsNotifier.value = [];
          unreadCountNotifier.value = 0;
        } else {
          await _loadFromPrefs();
        }
      }
    });
  }

  /// Memuat notifikasi dari local storage.
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getStorageKeyForStaff();
      var jsonList = prefs.getStringList(key);

      // Migrasi data legacy jika ada data di 'superadmin_notifications_v2'
      if ((jsonList == null || jsonList.isEmpty) && key != _storageKey) {
        final legacyList = prefs.getStringList(_storageKey);
        if (legacyList != null && legacyList.isNotEmpty) {
          final isSuperadmin =
              StaffAuthService().currentStaff?.isSuperAdmin == true;
          if (isSuperadmin) {
            jsonList = legacyList;
            await prefs.setStringList(key, legacyList);
          }
        }
      }

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

        // Saring hanya notifikasi yang sesuai akun aktif (jika recipientId diisi)
        final activeStaffId = StaffAuthService().currentStaff?.id;
        final filtered = loaded.where((item) {
          if (item.recipientId == null || item.recipientId!.isEmpty) return true;
          if (activeStaffId == null || activeStaffId.isEmpty) return true;
          return item.recipientId == activeStaffId;
        }).toList();

        notificationsNotifier.value = filtered;
        unreadCountNotifier.value =
            filtered.where((item) => !item.isRead).length;
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
      await prefs.setStringList(_getStorageKeyForStaff(), jsonList);
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

  PushRole _getPushRole(String? roleStr) {
    if (roleStr == 'dokter') return PushRole.dokter;
    if (roleStr == 'pmik') return PushRole.pmik;
    return PushRole.superadmin;
  }

  /// Mengambil daftar notifikasi khusus untuk role staf tertentu dan akun aktif
  List<SuperadminNotificationItem> getNotificationsForRole(
    PushRole role, {
    String? targetUserId,
  }) {
    final activeStaffId = targetUserId ?? StaffAuthService().currentStaff?.id;
    return notificationsNotifier.value.where((item) {
      final matchesRole = (role == PushRole.superadmin &&
              (item.role == null || item.role == 'superadmin')) ||
          (role == PushRole.dokter && item.role == 'dokter') ||
          (role == PushRole.pmik && item.role == 'pmik');
      if (!matchesRole) return false;

      // Filter akun penerima: hanya tampil jika recipientId cocok dengan akun aktif
      if (item.recipientId != null && item.recipientId!.isNotEmpty) {
        if (activeStaffId != null && activeStaffId.isNotEmpty) {
          if (item.recipientId != activeStaffId) return false;
        }
      }
      return true;
    }).toList();
  }

  /// Menghitung unread count untuk role staf tertentu dan akun aktif
  int getUnreadCountForRole(PushRole role, {String? targetUserId}) {
    return getNotificationsForRole(role, targetUserId: targetUserId)
        .where((item) => !item.isRead)
        .length;
  }

  /// Tandai notifikasi role tertentu sudah dibaca
  Future<void> markRoleAsRead(PushRole role, {String? targetUserId}) async {
    final current = notificationsNotifier.value;
    if (current.isEmpty) return;

    final activeStaffId = targetUserId ?? StaffAuthService().currentStaff?.id;
    final roleName = role.name;
    final updated = current.map((item) {
      final matchesRole = (role == PushRole.superadmin &&
              (item.role == null || item.role == 'superadmin')) ||
          item.role == roleName;
      final matchesRecipient = item.recipientId == null ||
          item.recipientId!.isEmpty ||
          activeStaffId == null ||
          activeStaffId.isEmpty ||
          item.recipientId == activeStaffId;

      if (matchesRole && matchesRecipient) {
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();

    notificationsNotifier.value = updated;
    unreadCountNotifier.value = updated.where((item) => !item.isRead).length;
    await _saveToPrefs();
  }

  /// Menghapus notifikasi spesifik berdasarkan ID
  Future<void> deleteNotification(String id) async {
    final currentList =
        List<SuperadminNotificationItem>.from(notificationsNotifier.value);
    currentList.removeWhere((element) => element.id == id);
    notificationsNotifier.value = currentList;
    unreadCountNotifier.value =
        currentList.where((element) => !element.isRead).length;
    await _saveToPrefs();
  }

  /// Menghapus seluruh notifikasi untuk role tertentu atau semua jika role == null
  Future<void> clearNotificationsForRole([PushRole? role]) async {
    if (role == null) {
      notificationsNotifier.value = [];
      unreadCountNotifier.value = 0;
    } else {
      final currentList =
          List<SuperadminNotificationItem>.from(notificationsNotifier.value);
      final roleName = role.name;
      currentList.removeWhere((item) {
        if (role == PushRole.superadmin) {
          return item.role == null || item.role == 'superadmin';
        } else if (role == PushRole.dokter) {
          return item.role == 'dokter';
        } else if (role == PushRole.pmik) {
          return item.role == 'pmik';
        }
        return item.role == roleName;
      });
      notificationsNotifier.value = currentList;
      unreadCountNotifier.value =
          currentList.where((element) => !element.isRead).length;
    }
    await _saveToPrefs();
  }

  /// Menambahkan notifikasi baru ke daftar (di posisi paling atas).
  /// Sekaligus menampilkan notifikasi sistem (status bar HP) via [LocalPushService].
  Future<void> addNotification(
    SuperadminNotificationItem item, {
    bool showPush = true,
  }) async {
    final currentStaff = StaffAuthService().currentStaff;
    final defaultRecipientId = currentStaff?.id ??
        (UserService().currentUser.id.isNotEmpty
            ? UserService().currentUser.id
            : (item.role == 'dokter'
                ? 'dokter_default'
                : 'superadmin_default'));

    final effectiveRecipientId = item.recipientId ?? defaultRecipientId;
    final effectiveRole = item.role ??
        (currentStaff != null
            ? (currentStaff.isSuperAdmin
                ? 'superadmin'
                : currentStaff.role.name)
            : 'superadmin');

    final itemToSave = item.copyWith(
      recipientId: effectiveRecipientId,
      role: effectiveRole,
    );

    final currentList =
        List<SuperadminNotificationItem>.from(notificationsNotifier.value);

    // 1. Abaikan jika ID sudah pernah tercatat (TUGAS 1: cegah duplikasi per kejadian)
    if (currentList.any((element) => element.id == itemToSave.id)) {
      debugPrint('[SuperadminNotificationService] Notifikasi ID ${itemToSave.id} sudah tercatat, abaikan.');
      return;
    }

    // 2. Cegah duplikasi notifikasi (title & message sama dalam 2 detik)
    final now = itemToSave.date;
    final isDuplicate = currentList.any((element) {
      final sameText = element.title.trim() == itemToSave.title.trim() &&
          element.message.trim() == itemToSave.message.trim();
      final diffSeconds = (element.date.difference(now)).inSeconds.abs();
      return sameText && diffSeconds <= 2;
    });

    if (isDuplicate) {
      debugPrint('[SuperadminNotificationService] Notifikasi duplikat diabaikan: "${itemToSave.title}"');
      return;
    }

    currentList.insert(0, itemToSave);
    notificationsNotifier.value = currentList;

    // Pastikan angka badge dihitung akurat dari baris yang belum dibaca (TUGAS 1)
    unreadCountNotifier.value = currentList.where((e) => !e.isRead).length;
    await _saveToPrefs();

    if (showPush) {
      // Tampilkan notifikasi sistem (push lokal) dengan judul persis
      LocalPushService().showWithExactTitle(
        title: itemToSave.title,
        body: itemToSave.message,
        targetRole: _getPushRole(itemToSave.role),
        targetUserId: itemToSave.recipientId,
        recordInApp: false,
      );
    }
  }

  /// Menambahkan notifikasi yang dipicu dari LocalPushService.show ke daftar in-app
  Future<void> addNotificationFromPush({
    required String title,
    required String message,
    required PushRole role,
    SuperadminNotificationType? type,
  }) async {
    final now = DateTime.now();
    final detectedType = type ?? detectType(title, message);
    final staff = StaffAuthService().currentStaff;
    final item = SuperadminNotificationItem(
      id: 'staff_push_${now.millisecondsSinceEpoch}',
      title: title,
      message: message,
      date: now,
      type: detectedType,
      actionType: SuperadminActionType.info,
      role: role.name,
      recipientId: staff?.id,
    );
    await addNotification(item, showPush: false);
  }

  SuperadminNotificationType detectType(String title, String message) {
    final lower = '${title.toLowerCase()} ${message.toLowerCase()}';
    if (lower.contains('artikel')) return SuperadminNotificationType.artikel;
    if (lower.contains('resep') || lower.contains('mpasi')) {
      return SuperadminNotificationType.resepMpasi;
    }
    if (lower.contains('dokter')) return SuperadminNotificationType.dokter;
    if (lower.contains('pmik') || lower.contains('staf')) {
      return SuperadminNotificationType.pmik;
    }
    if (lower.contains('dataset') ||
        lower.contains('unduh') ||
        lower.contains('rekapitulasi')) {
      return SuperadminNotificationType.unduhDataset;
    }
    if (lower.contains('jadwal')) return SuperadminNotificationType.jadwal;
    if (lower.contains('konsultasi') || lower.contains('pasien')) {
      return SuperadminNotificationType.konsultasi;
    }
    if (lower.contains('profil') || lower.contains('foto')) {
      return SuperadminNotificationType.profil;
    }
    return SuperadminNotificationType.umum;
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

  Future<void> notifyArtikelTambah(
    String judul, {
    String? recipientId,
    String? role,
  }) async {
    final now = DateTime.now();
    final item = SuperadminNotificationItem(
      id: 'artikel_tambah_${now.millisecondsSinceEpoch}',
      title: 'Berhasil Menambahkan Artikel',
      message: 'Artikel "$judul" berhasil ditambahkan ke dalam sistem.',
      date: now,
      type: SuperadminNotificationType.artikel,
      actionType: SuperadminActionType.tambah,
      targetName: judul,
      recipientId: recipientId,
      role: role,
    );
    await addNotification(item);
  }

  Future<void> notifyArtikelUbah(
    String judul, {
    String? recipientId,
    String? role,
  }) async {
    final now = DateTime.now();
    final item = SuperadminNotificationItem(
      id: 'artikel_ubah_${now.millisecondsSinceEpoch}',
      title: 'Berhasil Mengubah Artikel',
      message: 'Artikel "$judul" berhasil diperbarui.',
      date: now,
      type: SuperadminNotificationType.artikel,
      actionType: SuperadminActionType.edit,
      targetName: judul,
      recipientId: recipientId,
      role: role,
    );
    await addNotification(item);
  }

  Future<void> notifyArtikelHapus(
    String judul, {
    String? recipientId,
    String? role,
  }) async {
    final now = DateTime.now();
    final item = SuperadminNotificationItem(
      id: 'artikel_hapus_${now.millisecondsSinceEpoch}',
      title: 'Berhasil Menghapus Artikel',
      message: 'Artikel "$judul" telah dihapus dari sistem.',
      date: now,
      type: SuperadminNotificationType.artikel,
      actionType: SuperadminActionType.hapus,
      targetName: judul,
      recipientId: recipientId,
      role: role,
    );
    await addNotification(item);
  }

  // ===========================================================================
  // 2. CRUD RESEP MPASI
  // ===========================================================================

  Future<void> notifyResepTambah(
    String judul, {
    String? recipientId,
    String? role,
  }) async {
    final now = DateTime.now();
    final item = SuperadminNotificationItem(
      id: 'resep_tambah_${now.millisecondsSinceEpoch}',
      title: 'Berhasil Menambahkan Resep MPASI',
      message: 'Resep MPASI "$judul" berhasil ditambahkan ke dalam sistem.',
      date: now,
      type: SuperadminNotificationType.resepMpasi,
      actionType: SuperadminActionType.tambah,
      targetName: judul,
      recipientId: recipientId,
      role: role,
    );
    await addNotification(item);
  }

  Future<void> notifyResepUbah(
    String judul, {
    String? recipientId,
    String? role,
  }) async {
    final now = DateTime.now();
    final item = SuperadminNotificationItem(
      id: 'resep_ubah_${now.millisecondsSinceEpoch}',
      title: 'Berhasil Mengubah Resep MPASI',
      message: 'Resep MPASI "$judul" berhasil diperbarui.',
      date: now,
      type: SuperadminNotificationType.resepMpasi,
      actionType: SuperadminActionType.edit,
      targetName: judul,
      recipientId: recipientId,
      role: role,
    );
    await addNotification(item);
  }

  Future<void> notifyResepHapus(
    String judul, {
    String? recipientId,
    String? role,
  }) async {
    final now = DateTime.now();
    final item = SuperadminNotificationItem(
      id: 'resep_hapus_${now.millisecondsSinceEpoch}',
      title: 'Berhasil Menghapus Resep MPASI',
      message: 'Resep MPASI "$judul" telah dihapus dari sistem.',
      date: now,
      type: SuperadminNotificationType.resepMpasi,
      actionType: SuperadminActionType.hapus,
      targetName: judul,
      recipientId: recipientId,
      role: role,
    );
    await addNotification(item);
  }

  // ===========================================================================
  // 3. CRUD DOKTER
  // ===========================================================================

  Future<void> notifyDokterTambah(
    String namaDokter, {
    String? recipientId,
    String? role,
  }) async {
    final now = DateTime.now();
    final item = SuperadminNotificationItem(
      id: 'dokter_tambah_${now.millisecondsSinceEpoch}',
      title: 'Berhasil Menambahkan Data Dokter',
      message:
          'Akun dan data dokter "$namaDokter" berhasil ditambahkan ke dalam sistem.',
      date: now,
      type: SuperadminNotificationType.dokter,
      actionType: SuperadminActionType.tambah,
      targetName: namaDokter,
      recipientId: recipientId,
      role: role,
    );
    await addNotification(item);
  }

  Future<void> notifyDokterUbah(
    String namaDokter, {
    String? recipientId,
    String? role,
  }) async {
    final now = DateTime.now();
    final item = SuperadminNotificationItem(
      id: 'dokter_ubah_${now.millisecondsSinceEpoch}',
      title: 'Berhasil Mengubah Data Dokter',
      message: 'Data profil dokter "$namaDokter" berhasil diperbarui.',
      date: now,
      type: SuperadminNotificationType.dokter,
      actionType: SuperadminActionType.edit,
      targetName: namaDokter,
      recipientId: recipientId,
      role: role,
    );
    await addNotification(item);
  }

  Future<void> notifyDokterHapus(
    String namaDokter, {
    String? recipientId,
    String? role,
  }) async {
    final now = DateTime.now();
    final item = SuperadminNotificationItem(
      id: 'dokter_hapus_${now.millisecondsSinceEpoch}',
      title: 'Berhasil Menghapus Data Dokter',
      message: 'Data dan akun dokter "$namaDokter" telah dihapus dari sistem.',
      date: now,
      type: SuperadminNotificationType.dokter,
      actionType: SuperadminActionType.hapus,
      targetName: namaDokter,
      recipientId: recipientId,
      role: role,
    );
    await addNotification(item);
  }

  // ===========================================================================
  // 4. CRUD PMIK / STAF ADMIN
  // ===========================================================================

  Future<void> notifyPmikTambah(
    String namaStaf, {
    String? recipientId,
    String? role,
  }) async {
    final now = DateTime.now();
    final item = SuperadminNotificationItem(
      id: 'pmik_tambah_${now.millisecondsSinceEpoch}',
      title: 'Berhasil Menambahkan Akses PMIK',
      message: 'Akun staf PMIK "$namaStaf" berhasil ditambahkan ke dalam sistem.',
      date: now,
      type: SuperadminNotificationType.pmik,
      actionType: SuperadminActionType.tambah,
      targetName: namaStaf,
      recipientId: recipientId,
      role: role,
    );
    await addNotification(item);
  }

  Future<void> notifyPmikUbah(
    String namaStaf, {
    String? recipientId,
    String? role,
  }) async {
    final now = DateTime.now();
    final item = SuperadminNotificationItem(
      id: 'pmik_ubah_${now.millisecondsSinceEpoch}',
      title: 'Berhasil Mengubah Akses PMIK',
      message: 'Data staf PMIK "$namaStaf" berhasil diperbarui.',
      date: now,
      type: SuperadminNotificationType.pmik,
      actionType: SuperadminActionType.edit,
      targetName: namaStaf,
      recipientId: recipientId,
      role: role,
    );
    await addNotification(item);
  }

  Future<void> notifyPmikHapus(
    String namaStaf, {
    String? recipientId,
    String? role,
  }) async {
    final now = DateTime.now();
    final item = SuperadminNotificationItem(
      id: 'pmik_hapus_${now.millisecondsSinceEpoch}',
      title: 'Berhasil Menghapus Akses PMIK',
      message: 'Akses staf PMIK "$namaStaf" telah dihapus dari sistem.',
      date: now,
      type: SuperadminNotificationType.pmik,
      actionType: SuperadminActionType.hapus,
      targetName: namaStaf,
      recipientId: recipientId,
      role: role,
    );
    await addNotification(item);
  }

  // ===========================================================================
  // 5. UNDUH DATASET BERHASIL
  // ===========================================================================

  Future<void> notifyDatasetDownloaded({
    String? bulan,
    String? recipientId,
    String? role,
  }) async {
    final now = DateTime.now();
    final bulanStr = bulan != null && bulan.isNotEmpty ? ' bulan $bulan' : '';
    final item = SuperadminNotificationItem(
      id: 'dataset_unduh_${now.millisecondsSinceEpoch}',
      title: 'Berhasil Mengunduh Dataset',
      message:
          'Dataset hasil cek stunting$bulanStr berhasil diunduh sebagai laporan penggunaan aplikasi atau laporan kasus.',
      date: now,
      type: SuperadminNotificationType.unduhDataset,
      actionType: SuperadminActionType.unduh,
      recipientId: recipientId,
      role: role,
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
  Future<void> checkDatasetReminder({
    DateTime? mockDate,
    String? recipientId,
  }) async {
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
        recipientId: recipientId,
        role: 'superadmin',
      );
      await addNotification(item);
      await prefs.setBool('${_reminderHistoryKey}_$key', true);
    }
  }

  /// Notifikasi ketika terjadi override/perubahan jadwal dokter atau pembatalan booking akibat cuti.
  Future<void> notifyJadwalOverride(
    String message, {
    String? recipientId,
    String? role,
  }) async {
    final now = DateTime.now();
    final item = SuperadminNotificationItem(
      id: 'jadwal_override_${now.millisecondsSinceEpoch}',
      title: 'Perubahan Jadwal Dokter',
      message: message,
      date: now,
      type: SuperadminNotificationType.dokter,
      actionType: SuperadminActionType.edit,
      recipientId: recipientId,
      role: role,
    );
    await addNotification(item);
  }
}
