import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/local_push_service.dart';
import '../../core/services/notification_service.dart';
import '../../models/notification_model.dart';

/// Service Notifikasi PediaGrow.
///
/// Seluruh notifikasi yang sebelumnya tampil sebagai banner melayang di dalam
/// aplikasi (seperti banner biru di atas layar) kini dialihkan sepenuhnya ke
/// notifikasi handphone (system tray / status bar) sesuai permintaan pengguna.
/// Notifikasi ditampilkan real-time dan disesuaikan dengan role dan akun masing-masing.
class PediaBanner {
  /// Menampilkan notifikasi di status bar handphone secara real-time.
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismiss,
  }) {
    final title = isError ? 'Peringatan' : 'PediaGrow';
    final activeRole = LocalPushService().activeRole;

    // 1. Tampilkan di status bar handphone (system tray)
    LocalPushService().show(
      title: title,
      body: message,
      targetRole: activeRole,
    );

    // 2. Jika akun yang aktif adalah pengguna, catat juga di pusat notifikasi aplikasi
    if (activeRole == PushRole.pengguna) {
      NotificationService().addNotification(
        NotificationItem(
          id: 'pedia_banner_${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          message: message,
          date: DateTime.now(),
          type: NotificationType.consultation,
        ),
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
