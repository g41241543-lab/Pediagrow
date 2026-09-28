import 'dart:convert';

/// Kategori notifikasi untuk Superadmin.
enum SuperadminNotificationType {
  artikel,
  resepMpasi,
  dokter,
  pmik,
  unduhDataset,
  pengingatDataset,
}

/// Jenis aksi sistem / CRUD yang memicu notifikasi.
enum SuperadminActionType {
  tambah,
  edit,
  hapus,
  unduh,
  pengingat,
}

/// Model untuk item notifikasi Superadmin PediaGrow.
class SuperadminNotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final SuperadminNotificationType type;
  final SuperadminActionType actionType;
  final String? targetName;
  final bool isRead;

  const SuperadminNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.type,
    required this.actionType,
    this.targetName,
    this.isRead = false,
  });

  /// Mengembalikan tanggal terformat bahasa Indonesia (contoh: "1 September 2026", "28 September 2026").
  String get formattedDate {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final day = date.day.toString();
    final month = months[(date.month - 1).clamp(0, 11)];
    final year = date.year.toString();
    return '$day $month $year';
  }

  SuperadminNotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? date,
    SuperadminNotificationType? type,
    SuperadminActionType? actionType,
    String? targetName,
    bool? isRead,
  }) {
    return SuperadminNotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      date: date ?? this.date,
      type: type ?? this.type,
      actionType: actionType ?? this.actionType,
      targetName: targetName ?? this.targetName,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'date': date.toIso8601String(),
      'type': type.name,
      'actionType': actionType.name,
      'targetName': targetName,
      'isRead': isRead,
    };
  }

  factory SuperadminNotificationItem.fromMap(Map<String, dynamic> map) {
    return SuperadminNotificationItem(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      date: map['date'] != null
          ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      type: SuperadminNotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => SuperadminNotificationType.pengingatDataset,
      ),
      actionType: SuperadminActionType.values.firstWhere(
        (e) => e.name == map['actionType'],
        orElse: () => SuperadminActionType.pengingat,
      ),
      targetName: map['targetName'] as String?,
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory SuperadminNotificationItem.fromJson(String source) =>
      SuperadminNotificationItem.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );
}
