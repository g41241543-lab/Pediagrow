import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/booking_consultation_model.dart';
import '../../models/jadwal_praktik_model.dart';
import '../../models/notification_model.dart';

export '../../models/jadwal_praktik_model.dart';
import 'booking_service.dart';
import 'doctor_service.dart';
import 'notification_service.dart';
import 'staff_auth_service.dart';
import 'superadmin_notification_service.dart';

/// Service utama untuk mengelola jadwal praktik dokter, cuti, dan kalkulasi slot reservasi.
class JadwalDokterService {
  static final JadwalDokterService _instance = JadwalDokterService._internal();
  factory JadwalDokterService() => _instance;
  JadwalDokterService._internal() {
    _initListeners();
  }

  static const String _colJadwal = 'jadwal_praktik';
  static const String _colCuti = 'cuti_dokter';

  FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  // Cache in-memory
  final ValueNotifier<List<JadwalPraktikModel>> jadwalListNotifier =
      ValueNotifier<List<JadwalPraktikModel>>([]);
  final ValueNotifier<List<CutiDokterModel>> cutiListNotifier =
      ValueNotifier<List<CutiDokterModel>>([]);

  StreamSubscription? _subJadwal;
  StreamSubscription? _subCuti;

  void _initListeners() {
    final db = _db;
    if (db == null) return;

    try {
      _subJadwal = db.collection(_colJadwal).snapshots().listen(
        (snap) {
          final list = snap.docs
              .map((d) => JadwalPraktikModel.fromMap(d.data(), id: d.id))
              .toList();
          jadwalListNotifier.value = list;
        },
        onError: (e) => debugPrint('Error listener jadwal_praktik: $e'),
      );

      _subCuti = db.collection(_colCuti).snapshots().listen(
        (snap) {
          final list = snap.docs
              .map((d) => CutiDokterModel.fromMap(d.data(), id: d.id))
              .toList();
          cutiListNotifier.value = list;
        },
        onError: (e) => debugPrint('Error listener cuti_dokter: $e'),
      );
    } catch (e) {
      debugPrint('Error init listeners JadwalDokterService: $e');
    }
  }

  void dispose() {
    _subJadwal?.cancel();
    _subCuti?.cancel();
  }

  // ---------------------------------------------------------------------------
  // JADWAL PRAKTIK STANDAR & SEED
  // ---------------------------------------------------------------------------

  /// Mengumpulkan alias identitas dokter (ID dokter, StaffAccountId, dan Email)
  /// agar integrasi antara role dokter dan role pengguna selalu sinkron tanpa kendala ID mismatch.
  Set<String> getDoctorIdAliases(String dokterId) {
    final cleanId = dokterId.trim();
    final aliases = <String>{cleanId};
    final lowerClean = cleanId.toLowerCase();

    // Normalisasi pemisah tanda hubung dan garis bawah (misal: doc-reny <-> doc_reny)
    if (cleanId.contains('-')) aliases.add(cleanId.replaceAll('-', '_'));
    if (cleanId.contains('_')) aliases.add(cleanId.replaceAll('_', '-'));

    // 1. Cek dari daftar dokter yang terdaftar di DoctorService
    try {
      final doctors = DoctorService().currentDoctors;
      for (final doc in doctors) {
        final matches = doc.id == cleanId ||
            doc.staffAccountId == cleanId ||
            (doc.email != null && doc.email!.trim().toLowerCase() == lowerClean) ||
            doc.name.trim().toLowerCase() == lowerClean;
        if (matches) {
          aliases.add(doc.id);
          if (doc.id.contains('-')) aliases.add(doc.id.replaceAll('-', '_'));
          if (doc.id.contains('_')) aliases.add(doc.id.replaceAll('_', '-'));

          if (doc.staffAccountId.isNotEmpty) {
            aliases.add(doc.staffAccountId);
            if (doc.staffAccountId.contains('-')) aliases.add(doc.staffAccountId.replaceAll('-', '_'));
            if (doc.staffAccountId.contains('_')) aliases.add(doc.staffAccountId.replaceAll('_', '-'));
          }
          if (doc.email != null && doc.email!.isNotEmpty) {
            aliases.add(doc.email!.trim());
            aliases.add(doc.email!.trim().toLowerCase());
          }
        }
      }
    } catch (_) {}

    // 2. Cek dari staff account yang sedang aktif
    try {
      final staff = StaffAuthService().currentStaff;
      if (staff != null) {
        if (staff.id == cleanId ||
            staff.email.trim().toLowerCase() == lowerClean ||
            staff.name.trim().toLowerCase() == lowerClean) {
          aliases.add(staff.id);
          if (staff.id.contains('-')) aliases.add(staff.id.replaceAll('-', '_'));
          if (staff.id.contains('_')) aliases.add(staff.id.replaceAll('_', '-'));
          aliases.add(staff.email.trim());
          aliases.add(staff.email.trim().toLowerCase());
        }
      }
    } catch (_) {}

    return aliases;
  }

  /// Mengambil jadwal mingguan dokter (Senin - Minggu)
  List<JadwalPraktikModel> getJadwalDokter(String dokterId) {
    final aliases = getDoctorIdAliases(dokterId);
    final list = jadwalListNotifier.value
        .where((j) => aliases.contains(j.dokterId))
        .toList();
    if (list.isNotEmpty) return list;

    // Fallback jadwal default (Senin - Jumat 08:30-11:30 dan 15:00-17:00)
    return _generateDefaultJadwal(dokterId);
  }

  List<JadwalPraktikModel> _generateDefaultJadwal(String dokterId) {
    final List<JadwalPraktikModel> defaults = [];
    for (int day = 1; day <= 7; day++) {
      final isWeekday = day <= 5;
      defaults.add(
        JadwalPraktikModel(
          id: '${dokterId}_day_${day}_pagi',
          dokterId: dokterId,
          hari: day,
          jamMulai: '08:30',
          jamSelesai: '11:30',
          durasiSlotMenit: 30,
          aktif: isWeekday,
          dibuatOleh: 'superadmin',
        ),
      );
      defaults.add(
        JadwalPraktikModel(
          id: '${dokterId}_day_${day}_sore',
          dokterId: dokterId,
          hari: day,
          jamMulai: '15:00',
          jamSelesai: '17:00',
          durasiSlotMenit: 30,
          aktif: isWeekday,
          dibuatOleh: 'superadmin',
        ),
      );
    }
    return defaults;
  }

  // ---------------------------------------------------------------------------
  // VALIDASI SESI JADWAL
  // ---------------------------------------------------------------------------

  /// Validasi sesi:
  /// 1. Jam selesai harus lebih besar dari jam mulai.
  /// 2. Lama sesi harus habis dibagi durasi slot.
  /// 3. Tolak sesi yang tumpang tindih pada hari yang sama.
  String? validateSesi({
    required int hari,
    required String jamMulai,
    required String jamSelesai,
    required int durasiSlotMenit,
    required List<JadwalPraktikModel> existingSessionsOnDay,
    String? currentEditingId,
  }) {
    final startMinutes = _timeToMinutes(jamMulai);
    final endMinutes = _timeToMinutes(jamSelesai);

    if (startMinutes == null || endMinutes == null) {
      return 'Format jam tidak valid (gunakan HH:mm)';
    }

    if (endMinutes <= startMinutes) {
      return 'Jam selesai harus lebih besar dari jam mulai';
    }

    final duration = endMinutes - startMinutes;
    if (duration % durasiSlotMenit != 0) {
      return 'Lama sesi ($duration menit) harus habis dibagi durasi slot ($durasiSlotMenit menit)';
    }

    // Cek tumpang tindih dengan sesi lain pada hari yang sama
    for (final other in existingSessionsOnDay) {
      if (!other.aktif) continue;
      if (currentEditingId != null && other.id == currentEditingId) continue;

      final otherStart = _timeToMinutes(other.jamMulai);
      final otherEnd = _timeToMinutes(other.jamSelesai);
      if (otherStart == null || otherEnd == null) continue;

      // Overlap condition: start < otherEnd && end > otherStart
      if (startMinutes < otherEnd && endMinutes > otherStart) {
        return 'Sesi bentrok dengan sesi lain (${other.jamMulai} - ${other.jamSelesai}) pada hari yang sama';
      }
    }

    return null; // Valid
  }

  // ---------------------------------------------------------------------------
  // SIMPAN JADWAL MINGGUAN
  // ---------------------------------------------------------------------------

  Future<void> simpanSemuaJadwalDokter({
    required String dokterId,
    required List<JadwalPraktikModel> jadwalList,
    required String rolePelaku, // 'superadmin' atau 'dokter'
  }) async {
    final db = _db;
    final aliases = getDoctorIdAliases(dokterId);
    final newIds = jadwalList.map((j) => j.id).toSet();

    if (db != null) {
      final batch = db.batch();

      // 1. Bersihkan dokumen jadwal lama milik dokter ini di Firestore yang sudah dihapus
      try {
        final existingSnap = await db.collection(_colJadwal).get();
        for (final doc in existingSnap.docs) {
          final docDokterId = doc.data()['dokterId']?.toString() ?? '';
          if (aliases.contains(docDokterId) && !newIds.contains(doc.id)) {
            batch.delete(doc.reference);
          }
        }
      } catch (e) {
        debugPrint('[JadwalDokterService] Error cleaning old schedule docs: $e');
      }

      // 2. Tulis/perbarui semua jadwal terbaru
      for (final j in jadwalList) {
        final ref = db.collection(_colJadwal).doc(j.id);
        batch.set(ref, j.toMap(), SetOptions(merge: true));
      }
      await batch.commit();
    }

    // 3. Update in-memory: hapus semua jadwal dengan dokterId atau aliases-nya
    final current = List<JadwalPraktikModel>.from(jadwalListNotifier.value)
      ..removeWhere((j) => aliases.contains(j.dokterId))
      ..addAll(jadwalList);
    jadwalListNotifier.value = current;

    // 4. Deteksi dan batalkan booking pasien di masa depan yang terdampak oleh sesi yang dinonaktifkan/dihapus
    try {
      final affectedBookings = cariBookingTerdampakPerubahanJadwal(
        dokterId: dokterId,
        jadwalBaru: jadwalList,
      );

      for (final b in affectedBookings) {
        BookingService().updateBookingStatus(b.id, 'Dibatalkan');
        NotificationService().addNotification(
          NotificationItem(
            id: 'cancel_sched_${b.id}_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Penyesuaian Jadwal Praktik Dokter',
            message:
                'Jadwal konsultasi bersama ${b.doctor.name} pada ${b.formattedDate} (${b.scheduledTimeSlot}) dibatalkan karena penyesuaian jam kerja dokter. Silakan jadwalkan ulang.',
            date: DateTime.now(),
            type: NotificationType.consultation,
          ),
        );
      }
    } catch (e) {
      debugPrint('[JadwalDokterService] Error updating affected bookings: $e');
    }

    // Jika Superadmin yang mengubah jadwal dokter, kirim notifikasi ke dokter
    if (rolePelaku.toLowerCase() == 'superadmin') {
      NotificationService().addNotification(
        NotificationItem(
          id: 'jadwal_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Jadwal Praktik Diperbarui',
          message:
              'Superadmin telah memperbarui jadwal konsultasi standar Anda.',
          date: DateTime.now(),
          type: NotificationType.consultation,
        ),
      );
    }
  }

  /// Mencari booking masa depan yang terdampak akibat dokter menghapus sesi atau menonaktifkan hari praktik
  List<BookingConsultationModel> cariBookingTerdampakPerubahanJadwal({
    required String dokterId,
    required List<JadwalPraktikModel> jadwalBaru,
  }) {
    final now = DateTime.now();
    final allBookings = BookingService().bookings;
    final aliases = getDoctorIdAliases(dokterId);
    final affected = <BookingConsultationModel>[];

    final upcoming = allBookings.where((b) {
      if (!aliases.contains(b.doctor.id)) return false;
      if (b.status.toLowerCase() == 'dibatalkan') return false;
      return b.scheduledStartDateTime.isAfter(now);
    });

    for (final b in upcoming) {
      final weekday = b.bookingDate.weekday;
      final activeSessionsOnDay = jadwalBaru
          .where((j) => j.hari == weekday && j.aktif)
          .toList();

      if (activeSessionsOnDay.isEmpty) {
        // Hari praktik dinonaktifkan
        affected.add(b);
        continue;
      }

      // Cek apakah jam booking masih berada di dalam salah satu sesi aktif
      final bStartMin = _timeToMinutes(
        '${b.scheduledStartDateTime.hour.toString().padLeft(2, '0')}:${b.scheduledStartDateTime.minute.toString().padLeft(2, '0')}',
      );
      final bEndMin = _timeToMinutes(
        '${b.scheduledEndDateTime.hour.toString().padLeft(2, '0')}:${b.scheduledEndDateTime.minute.toString().padLeft(2, '0')}',
      );

      if (bStartMin == null || bEndMin == null) continue;

      bool stillCovered = false;
      for (final s in activeSessionsOnDay) {
        final sStart = _timeToMinutes(s.jamMulai) ?? 0;
        final sEnd = _timeToMinutes(s.jamSelesai) ?? (24 * 60);
        if (bStartMin >= sStart && bEndMin <= sEnd) {
          stillCovered = true;
          break;
        }
      }

      if (!stillCovered) {
        affected.add(b);
      }
    }

    return affected;
  }

  // ---------------------------------------------------------------------------
  // MANAJEMEN CUTI DOKTER DENGAN ANALISIS DAMPAK PASIEN
  // ---------------------------------------------------------------------------

  /// Mengambil daftar cuti dokter
  List<CutiDokterModel> getCutiDokter(String dokterId) {
    final aliases = getDoctorIdAliases(dokterId);
    return cutiListNotifier.value.where((c) => aliases.contains(c.dokterId)).toList();
  }

  /// Menghitung berapa banyak booking pasien yang terdampak oleh cuti baru
  List<BookingConsultationModel> cariBookingTerdampak({
    required String dokterId,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
    String? jamMulai,
    String? jamSelesai,
  }) {
    final allBookings = BookingService().bookings;
    final affected = <BookingConsultationModel>[];
    final aliases = getDoctorIdAliases(dokterId);

    final startDay = DateTime(
      tanggalMulai.year,
      tanggalMulai.month,
      tanggalMulai.day,
    );
    final endDay = DateTime(
      tanggalSelesai.year,
      tanggalSelesai.month,
      tanggalSelesai.day,
    );

    final cutiStartMin = jamMulai != null ? _timeToMinutes(jamMulai) : null;
    final cutiEndMin = jamSelesai != null ? _timeToMinutes(jamSelesai) : null;
    final isSeharian = cutiStartMin == null || cutiEndMin == null;

    for (final b in allBookings) {
      if (!aliases.contains(b.doctor.id)) continue;
      if (b.status.toLowerCase() == 'dibatalkan') continue;

      final bDate = DateTime(
        b.bookingDate.year,
        b.bookingDate.month,
        b.bookingDate.day,
      );
      if (bDate.isBefore(startDay) || bDate.isAfter(endDay)) continue;

      if (isSeharian) {
        affected.add(b);
      } else {
        // Cek overlap jam booking
        final bStartMin = _timeToMinutes(
          '${b.scheduledStartDateTime.hour.toString().padLeft(2, '0')}:${b.scheduledStartDateTime.minute.toString().padLeft(2, '0')}',
        );
        final bEndMin = _timeToMinutes(
          '${b.scheduledEndDateTime.hour.toString().padLeft(2, '0')}:${b.scheduledEndDateTime.minute.toString().padLeft(2, '0')}',
        );
        if (bStartMin != null && bEndMin != null) {
          if (bStartMin < cutiEndMin && bEndMin > cutiStartMin) {
            affected.add(b);
          }
        }
      }
    }

    return affected;
  }

  /// Menambah cuti dokter, secara otomatis membatalkan booking yang terdampak
  /// dan mengirim notifikasi reschedule ke pasien.
  Future<int> tambahCuti({
    required CutiDokterModel cuti,
  }) async {
    // 1. Simpan cuti
    final db = _db;
    if (db != null) {
      await db.collection(_colCuti).doc(cuti.id).set(cuti.toMap());
    }
    final updatedCuti = List<CutiDokterModel>.from(cutiListNotifier.value)
      ..add(cuti);
    cutiListNotifier.value = updatedCuti;

    // 2. Batalkan booking terdampak
    final affectedBookings = cariBookingTerdampak(
      dokterId: cuti.dokterId,
      tanggalMulai: cuti.tanggalMulai,
      tanggalSelesai: cuti.tanggalSelesai,
      jamMulai: cuti.jamMulai,
      jamSelesai: cuti.jamSelesai,
    );

    for (final b in affectedBookings) {
      // Perbarui status di BookingService dan Firestore
      BookingService().updateBookingStatus(b.id, 'Dibatalkan');

      // Kirim notifikasi ke pasien agar menjadwalkan ulang
      NotificationService().addNotification(
        NotificationItem(
          id: 'cancel_${b.id}_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Jadwal Konsultasi Dibatalkan',
          message:
              'Konsultasi bersama ${b.doctor.name} pada ${b.formattedDate} (${b.scheduledTimeSlot}) dibatalkan karena dokter berhalangan (${cuti.alasan}). Silakan pilih jadwal lain.',
          date: DateTime.now(),
          type: NotificationType.consultation,
        ),
      );
    }

    if (affectedBookings.isNotEmpty) {
      await SuperadminNotificationService().notifyJadwalOverride(
        'Dokter mengajukan cuti, ${affectedBookings.length} jadwal pasien dialihkan.',
      );
    }

    return affectedBookings.length;
  }

  Future<void> hapusCuti(String cutiId) async {
    final db = _db;
    if (db != null) {
      await db.collection(_colCuti).doc(cutiId).delete();
    }
    final updated = List<CutiDokterModel>.from(cutiListNotifier.value)
      ..removeWhere((c) => c.id == cutiId);
    cutiListNotifier.value = updated;
  }

  // ---------------------------------------------------------------------------
  // LOGIKA MENGHITUNG SLOT KOSONG
  // ---------------------------------------------------------------------------

  /// Menghitung slot kosong seorang dokter pada tanggal tertentu berurutan:
  /// 1. Ambil jadwal mingguan yang harinya sesuai tanggal dan berstatus aktif.
  /// 2. Jika ada cuti seharian pada tanggal itu, kembalikan daftar kosong.
  /// 3. Pecah tiap sesi menjadi slot sesuai durasi slot.
  /// 4. Buang slot yang bentrok dengan cuti parsial.
  /// 5. Buang slot yang sudah dibooking (status selain dibatalkan).
  /// 6. Jika tanggalnya hari ini, buang slot yang sudah lewat atau kurang dari 30 menit lagi.
  List<SlotWaktuDokter> hitungSlotKosong({
    required String dokterId,
    required DateTime tanggal,
  }) {
    final targetDate = DateTime(tanggal.year, tanggal.month, tanggal.day);
    final now = DateTime.now();

    // 1. Ambil jadwal mingguan yang harinya sesuai tanggal dan berstatus aktif
    final weekday = targetDate.weekday; // 1: Senin .. 7: Minggu
    final activeSessions = getJadwalDokter(dokterId)
        .where((j) => j.hari == weekday && j.aktif)
        .toList();

    if (activeSessions.isEmpty) {
      return [];
    }

    // 2. Cek apakah ada cuti dokter pada tanggal ini
    final cutiDokter = getCutiDokter(dokterId);
    final cutiOnDate = cutiDokter.where((c) => c.berlakuPada(targetDate)).toList();

    // Jika ada cuti seharian pada tanggal itu, kembalikan daftar kosong
    final hasAllDayCuti = cutiOnDate.any((c) => c.isSeharian);
    if (hasAllDayCuti) {
      return [];
    }

    // 3. Pecah tiap sesi menjadi slot sesuai durasi slot
    final List<SlotWaktuDokter> allSlots = [];

    for (final session in activeSessions) {
      final startMin = _timeToMinutes(session.jamMulai) ?? (8 * 60);
      final endMin = _timeToMinutes(session.jamSelesai) ?? (11 * 60);
      final slotDuration = session.durasiSlotMenit > 0 ? session.durasiSlotMenit : 30;

      for (int current = startMin; current + slotDuration <= endMin; current += slotDuration) {
        final slotStartStr = _minutesToTime(current);
        final slotEndStr = _minutesToTime(current + slotDuration);

        final slotStartDt = DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          current ~/ 60,
          current % 60,
        );
        final slotEndDt = slotStartDt.add(Duration(minutes: slotDuration));

        // 4. Buang slot yang bentrok dengan cuti parsial
        bool isCutiClash = false;
        for (final c in cutiOnDate) {
          if (!c.isSeharian && c.jamMulai != null && c.jamSelesai != null) {
            final cStart = _timeToMinutes(c.jamMulai!) ?? 0;
            final cEnd = _timeToMinutes(c.jamSelesai!) ?? (24 * 60);
            if (current < cEnd && (current + slotDuration) > cStart) {
              isCutiClash = true;
              break;
            }
          }
        }
        if (isCutiClash) continue;

        // 5. Buang slot yang sudah dibooking (status selain dibatalkan)
        final aliases = getDoctorIdAliases(dokterId);
        final isBooked = BookingService().bookings.any((b) {
          if (!aliases.contains(b.doctor.id)) return false;
          if (b.status.toLowerCase() == 'dibatalkan') return false;

          final bDate = DateTime(
            b.bookingDate.year,
            b.bookingDate.month,
            b.bookingDate.day,
          );
          if (bDate != targetDate) return false;

          // Cek apakah waktu sama atau bentrok
          final bStartMin = _timeToMinutes(
            '${b.scheduledStartDateTime.hour.toString().padLeft(2, '0')}:${b.scheduledStartDateTime.minute.toString().padLeft(2, '0')}',
          );
          final bEndMin = _timeToMinutes(
            '${b.scheduledEndDateTime.hour.toString().padLeft(2, '0')}:${b.scheduledEndDateTime.minute.toString().padLeft(2, '0')}',
          );

          if (bStartMin != null && bEndMin != null) {
            return current < bEndMin && (current + slotDuration) > bStartMin;
          }
          return b.timeSlot.contains(slotStartStr);
        });

        if (isBooked) continue;

        // 6. Jika tanggalnya hari ini, buang slot yang sudah lewat atau kurang dari 30 menit lagi
        final isToday = targetDate.year == now.year &&
            targetDate.month == now.month &&
            targetDate.day == now.day;

        if (isToday) {
          final diffMinutes = slotStartDt.difference(now).inMinutes;
          if (diffMinutes < 30) {
            continue; // Sudah lewat atau kurang dari 30 menit lagi
          }
        }

        allSlots.add(
          SlotWaktuDokter(
            jamMulai: slotStartStr,
            jamSelesai: slotEndStr,
            timeLabel: '$slotStartStr - $slotEndStr WIB',
            startDateTime: slotStartDt,
            endDateTime: slotEndDt,
            isAvailable: true,
          ),
        );
      }
    }

    return allSlots;
  }

  /// Menghitung SEMUA slot waktu dokter pada tanggal tertentu beserta status ketersediaannya.
  ///
  /// Berbeda dengan [hitungSlotKosong], method ini mengembalikan seluruh slot dari jadwal
  /// termasuk slot yang sudah terbooked (isAvailable = false). Cocok dipakai UI booking
  /// agar pengguna bisa melihat gambaran penuh slot mana yang masih kosong vs penuh.
  ///
  /// Slot yang dibuang (tidak dikembalikan sama sekali):
  ///   - Slot pada hari cuti seharian
  ///   - Slot yang bentrok dengan cuti parsial
  ///   - Slot yang sudah lewat / kurang dari 30 menit pada hari ini
  List<SlotWaktuDokter> hitungSemuaSlot({
    required String dokterId,
    required DateTime tanggal,
  }) {
    final targetDate = DateTime(tanggal.year, tanggal.month, tanggal.day);
    final now = DateTime.now();

    final weekday = targetDate.weekday;
    final activeSessions = getJadwalDokter(dokterId)
        .where((j) => j.hari == weekday && j.aktif)
        .toList();

    if (activeSessions.isEmpty) return [];

    final cutiDokter = getCutiDokter(dokterId);
    final cutiOnDate = cutiDokter.where((c) => c.berlakuPada(targetDate)).toList();

    final hasAllDayCuti = cutiOnDate.any((c) => c.isSeharian);
    if (hasAllDayCuti) return [];

    final aliases = getDoctorIdAliases(dokterId);
    final List<SlotWaktuDokter> allSlots = [];

    for (final session in activeSessions) {
      final startMin = _timeToMinutes(session.jamMulai) ?? (8 * 60);
      final endMin = _timeToMinutes(session.jamSelesai) ?? (11 * 60);
      final slotDuration = session.durasiSlotMenit > 0 ? session.durasiSlotMenit : 30;

      for (int current = startMin; current + slotDuration <= endMin; current += slotDuration) {
        final slotStartStr = _minutesToTime(current);
        final slotEndStr = _minutesToTime(current + slotDuration);

        final slotStartDt = DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          current ~/ 60,
          current % 60,
        );
        final slotEndDt = slotStartDt.add(Duration(minutes: slotDuration));

        // Buang slot yang bentrok dengan cuti parsial
        bool isCutiClash = false;
        for (final c in cutiOnDate) {
          if (!c.isSeharian && c.jamMulai != null && c.jamSelesai != null) {
            final cStart = _timeToMinutes(c.jamMulai!) ?? 0;
            final cEnd = _timeToMinutes(c.jamSelesai!) ?? (24 * 60);
            if (current < cEnd && (current + slotDuration) > cStart) {
              isCutiClash = true;
              break;
            }
          }
        }
        if (isCutiClash) continue;

        // Buang slot yang sudah lewat / kurang dari 30 menit pada hari ini
        final isToday = targetDate.year == now.year &&
            targetDate.month == now.month &&
            targetDate.day == now.day;
        if (isToday) {
          final diffMinutes = slotStartDt.difference(now).inMinutes;
          if (diffMinutes < 30) continue;
        }

        // Cek apakah slot sudah dibooking (tandai saja, jangan buang)
        final isBooked = BookingService().bookings.any((b) {
          if (!aliases.contains(b.doctor.id)) return false;
          if (b.status.toLowerCase() == 'dibatalkan') return false;

          final bDate = DateTime(b.bookingDate.year, b.bookingDate.month, b.bookingDate.day);
          if (bDate != targetDate) return false;

          final bStartMin = _timeToMinutes(
            '${b.scheduledStartDateTime.hour.toString().padLeft(2, '0')}:${b.scheduledStartDateTime.minute.toString().padLeft(2, '0')}',
          );
          final bEndMin = _timeToMinutes(
            '${b.scheduledEndDateTime.hour.toString().padLeft(2, '0')}:${b.scheduledEndDateTime.minute.toString().padLeft(2, '0')}',
          );

          if (bStartMin != null && bEndMin != null) {
            return current < bEndMin && (current + slotDuration) > bStartMin;
          }
          return b.timeSlot.contains(slotStartStr);
        });

        allSlots.add(
          SlotWaktuDokter(
            jamMulai: slotStartStr,
            jamSelesai: slotEndStr,
            timeLabel: '$slotStartStr - $slotEndStr WIB',
            startDateTime: slotStartDt,
            endDateTime: slotEndDt,
            isAvailable: !isBooked,
          ),
        );
      }
    }

    return allSlots;
  }

  // ---------------------------------------------------------------------------
  // BADGE KETERSEDIAAN DI DAFTAR DOKTER
  // ---------------------------------------------------------------------------

  /// Mengembalikan badge ketersediaan dokter:
  /// - Ada slot kosong hari ini: "Tersedia Hari Ini" (hijau).
  /// - Besok: "Tersedia Besok" (biru).
  /// - Tanggal terdekat maksimal 14 hari: "Jadwal Terdekat: [hari, tanggal]".
  /// - Tidak ada slot dalam 14 hari: "Belum Ada Jadwal" (abu-abu).
  DoctorBadgeInfo getDoctorBadge(String dokterId) {
    final now = DateTime.now();

    // Cek hari ini (day 0)
    final todaySlots = hitungSlotKosong(dokterId: dokterId, tanggal: now);
    if (todaySlots.isNotEmpty) {
      return const DoctorBadgeInfo(
        type: DoctorBadgeType.tersediaHariIni,
        label: 'Tersedia Hari Ini',
      );
    }

    // Cek besok (day 1)
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowSlots =
        hitungSlotKosong(dokterId: dokterId, tanggal: tomorrow);
    if (tomorrowSlots.isNotEmpty) {
      return DoctorBadgeInfo(
        type: DoctorBadgeType.tersediaBesok,
        label: 'Tersedia Besok',
        tanggalTersedia: tomorrow,
      );
    }

    // Cek hingga 14 hari ke depan (day 2 .. 14)
    for (int i = 2; i <= 14; i++) {
      final nextDate = now.add(Duration(days: i));
      final nextSlots =
          hitungSlotKosong(dokterId: dokterId, tanggal: nextDate);
      if (nextSlots.isNotEmpty) {
        final namaHari = JadwalPraktikModel.getNamaHari(nextDate.weekday);
        final formatTgl = '$namaHari, ${nextDate.day} ${_getNamaBulan(nextDate.month)}';
        return DoctorBadgeInfo(
          type: DoctorBadgeType.jadwalTerdekat,
          label: 'Jadwal Terdekat: $formatTgl',
          tanggalTersedia: nextDate,
        );
      }
    }

    return const DoctorBadgeInfo(
      type: DoctorBadgeType.belumAdaJadwal,
      label: 'Belum Ada Jadwal',
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER INTEGRASI JADWAL UNTUK UI
  // ---------------------------------------------------------------------------

  /// Mengambil Cuti yang aktif pada tanggal tertentu jika ada
  CutiDokterModel? getCutiPadaTanggal(String dokterId, DateTime tanggal) {
    final targetDate = DateTime(tanggal.year, tanggal.month, tanggal.day);
    final cutis = getCutiDokter(dokterId);
    for (final c in cutis) {
      if (c.berlakuPada(targetDate)) {
        return c;
      }
    }
    return null;
  }

  /// Cek apakah dokter memiliki sesi praktik aktif pada hari tersebut (1: Senin .. 7: Minggu)
  bool isDokterPraktikPadaHari(String dokterId, int weekday) {
    final sessions = getJadwalDokter(dokterId);
    return sessions.any((j) => j.hari == weekday && j.aktif);
  }

  /// Mengelompokkan jadwal mingguan per hari (1: Senin .. 7: Minggu)
  Map<int, List<JadwalPraktikModel>> getJadwalPerHari(String dokterId) {
    final all = getJadwalDokter(dokterId);
    final Map<int, List<JadwalPraktikModel>> map = {};
    for (int day = 1; day <= 7; day++) {
      map[day] = all.where((j) => j.hari == day).toList();
    }
    return map;
  }

  // ---------------------------------------------------------------------------
  // HELPER FORMAT WAKTU
  // ---------------------------------------------------------------------------

  static int? _timeToMinutes(String timeStr) {
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length >= 2) {
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        return (h * 60) + m;
      }
    } catch (_) {}
    return null;
  }

  static String _minutesToTime(int totalMinutes) {
    final h = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final m = (totalMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _getNamaBulan(int month) {
    const list = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return (month >= 1 && month <= 12) ? list[month] : '';
  }
}
