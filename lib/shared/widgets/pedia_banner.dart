import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/local_push_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/superadmin_notification_service.dart';
import '../../models/notification_model.dart';
import '../../models/superadmin_notification_model.dart';

/// Helper fungsi untuk mendeteksi judul notifikasi yang akurat sesuai aksi pengguna.
String resolveActionTitle(
  String message, {
  String? defaultTitle,
  bool isError = false,
}) {
  if (isError) {
    final lower = message.toLowerCase();
    if (lower.contains('batas') &&
        (lower.contains('pertumbuhan') || lower.contains('input'))) {
      return 'Batas Input Data Pertumbuhan';
    }
    if (lower.contains('batas') && lower.contains('stunting')) {
      return 'Batas Cek Stunting';
    }
    if (lower.contains('gagal')) {
      if (lower.contains('anak')) return 'Gagal Menyimpan Data Anak';
      if (lower.contains('profil')) return 'Gagal Memperbarui Profil';
      if (lower.contains('sandi') || lower.contains('password')) {
        return 'Gagal Mengubah Kata Sandi';
      }
      if (lower.contains('artikel')) return 'Gagal Menyimpan Artikel';
      if (lower.contains('resep')) return 'Gagal Menyimpan Resep';
      return 'Gagal Memproses Data';
    }
    return defaultTitle?.isNotEmpty == true ? defaultTitle! : 'Peringatan';
  }

  final lower = message.toLowerCase();

  // 0. Aksi: BATAS KUOTA / LIMIT
  if (lower.contains('batas') &&
      (lower.contains('pertumbuhan') || lower.contains('input'))) {
    return 'Batas Input Data Pertumbuhan';
  }
  if (lower.contains('batas') && lower.contains('stunting')) {
    return 'Batas Cek Stunting';
  }

  // 1. Aksi: HAPUS
  if (lower.contains('hapus') || lower.contains('dihapus')) {
    if (lower.contains('anak')) return 'Berhasil Menghapus Data Anak';
    if (lower.contains('artikel')) return 'Berhasil Menghapus Artikel';
    if (lower.contains('resep') || lower.contains('mpasi')) {
      return 'Berhasil Menghapus Resep MPASI';
    }
    if (lower.contains('dokter')) return 'Berhasil Menghapus Data Dokter';
    if (lower.contains('pmik') || lower.contains('staf')) {
      return 'Berhasil Menghapus Akses PMIK';
    }
    if (lower.contains('cuti')) return 'Cuti Dokter Dihapus';
    if (lower.contains('notifikasi')) return 'Berhasil Menghapus Notifikasi';
    return 'Berhasil Menghapus Data';
  }

  // 2. Aksi: UBAH / PERBARUI / EDIT
  if (lower.contains('ubah') ||
      lower.contains('perbarui') ||
      lower.contains('diperbarui') ||
      lower.contains('edit')) {
    if (lower.contains('anak')) return 'Berhasil Mengubah Data Anak';
    if (lower.contains('sandi') || lower.contains('password')) {
      return 'Berhasil Mengubah Kata Sandi';
    }
    if (lower.contains('profil') ||
        lower.contains('ibu') ||
        lower.contains('foto')) {
      return 'Berhasil Mengubah Profil';
    }
    if (lower.contains('artikel')) return 'Berhasil Mengubah Artikel';
    if (lower.contains('resep') || lower.contains('mpasi')) {
      return 'Berhasil Mengubah Resep MPASI';
    }
    if (lower.contains('dokter')) return 'Berhasil Mengubah Data Dokter';
    if (lower.contains('pmik') || lower.contains('staf')) {
      return 'Berhasil Mengubah Akses PMIK';
    }
    if (lower.contains('jadwal')) return 'Berhasil Mengubah Jadwal';
    return 'Berhasil Mengubah Data';
  }

  // 3. Aksi: TAMBAH / BUAT / SIMPAN
  if (lower.contains('tambah') ||
      lower.contains('ditambahkan') ||
      lower.contains('buat') ||
      lower.contains('simpan') ||
      lower.contains('tersimpan')) {
    if (lower.contains('anak')) return 'Berhasil Menambahkan Data Anak';
    if (lower.contains('booking') ||
        lower.contains('konsultasi') ||
        lower.contains('janji')) {
      return 'Berhasil Membuat Janji Konsultasi';
    }
    if (lower.contains('artikel')) return 'Berhasil Menambahkan Artikel';
    if (lower.contains('resep') || lower.contains('mpasi')) {
      return 'Berhasil Menambahkan Resep MPASI';
    }
    if (lower.contains('dokter')) return 'Berhasil Menambahkan Data Dokter';
    if (lower.contains('pmik') || lower.contains('staf')) {
      return 'Berhasil Menambahkan Akses PMIK';
    }
    if (lower.contains('cuti')) return 'Cuti Dokter Berhasil Ditambahkan';
    if (lower.contains('resume')) return 'Resume Medis Disimpan';
    return 'Berhasil Menambahkan Data';
  }

  // 4. Aksi: UNDUH / DOWNLOAD
  if (lower.contains('unduh') || lower.contains('download')) {
    return 'Berhasil Mengunduh Data';
  }

  // 5. Konteks: STUNTING
  if (lower.contains('stunting') || lower.contains('pemeriksaan')) {
    return 'Pemeriksaan Stunting';
  }

  // 6. Konteks: KONSULTASI
  if (lower.contains('konsultasi') || lower.contains('booking')) {
    return 'Konsultasi Dokter';
  }

  if (defaultTitle != null &&
      defaultTitle.isNotEmpty &&
      defaultTitle != 'PediaGrow') {
    return defaultTitle;
  }

  return 'PediaGrow';
}

/// Service Notifikasi PediaGrow.
///
/// Seluruh notifikasi yang sebelumnya tampil sebagai banner melayang di dalam
/// aplikasi kini dialihkan sepenuhnya ke notifikasi handphone (system tray / status bar)
/// serta menu notifikasi di dalam aplikasi.
///
/// Setiap aksi dipastikan HANYA menghasilkan 1 notifikasi di HP dan 1 entri di
/// menu notifikasi aplikasi, dengan judul yang sesuai dengan aksi yang dilakukan.
class PediaBanner {
  /// Menampilkan notifikasi di status bar handphone secara real-time dan
  /// mencatatnya tepat 1 kali ke menu notifikasi aplikasi.
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismiss,
  }) {
    final activeRole = LocalPushService().activeRole;
    final resolvedTitle = resolveActionTitle(
      message,
      defaultTitle: isError ? 'Peringatan' : null,
      isError: isError,
    );

    // Kirim notifikasi tepat 1 kali melalui service terkait.
    // Service ini sudah otomatis mengurus push notifikasi HP dengan flag
    // recordInApp: false sehingga tidak terjadi duplikasi ganda.
    if (activeRole == null || activeRole == PushRole.pengguna) {
      final detectedType =
          NotificationService().detectType(resolvedTitle, message);
      NotificationService().addNotification(
        NotificationItem(
          id: 'pedia_banner_${DateTime.now().millisecondsSinceEpoch}',
          title: resolvedTitle,
          message: message,
          date: DateTime.now(),
          type: detectedType,
        ),
        showPush: true,
      );
    } else {
      final detectedType =
          SuperadminNotificationService().detectType(resolvedTitle, message);
      SuperadminNotificationService().addNotification(
        SuperadminNotificationItem(
          id: 'staff_pedia_banner_${DateTime.now().millisecondsSinceEpoch}',
          title: resolvedTitle,
          message: message,
          date: DateTime.now(),
          type: detectedType,
          actionType: SuperadminActionType.info,
          role: activeRole.name,
        ),
        showPush: true,
      );
    }

    if (onDismiss != null) {
      Timer(duration, onDismiss);
    }
  }

  /// Menampilkan notifikasi sukses di handphone
  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismiss,
  }) {
    show(
      context,
      message: message,
      isError: false,
      duration: duration,
      onDismiss: onDismiss,
    );
  }

  /// Menampilkan notifikasi error / peringatan di handphone
  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismiss,
  }) {
    show(
      context,
      message: message,
      isError: true,
      duration: duration,
      onDismiss: onDismiss,
    );
  }

  /// Menutup banner (kompatibilitas backward)
  static void hide() {}
}
