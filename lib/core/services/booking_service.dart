import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/booking_consultation_model.dart';
import '../../models/child_model.dart';
import '../../models/doctor_model.dart';
import 'google_calendar_service.dart';
import 'jadwal_dokter_service.dart';
import 'notification_service.dart';
import 'user_service.dart';

/// Service singleton untuk mengelola pemesanan jadwal (Booking) konsultasi dokter anak
/// dan integrasi pengingat ke Google Kalender serta Cloud Firestore realtime.
class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;

  static const String _collectionName = 'consultation_booking';

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _bookingsSub;
  Timer? _cleanupTimer;

  BookingService._internal() {
    _initFirestoreListener();
    _startAutoCleanupTimer();
  }

  /// Inisialisasi listener real-time dari Cloud Firestore
  void _initFirestoreListener() {
    try {
      _bookingsSub = _db
          .collection(_collectionName)
          .snapshots()
          .listen(
        (snapshot) async {
          final allList = snapshot.docs.map((doc) {
            return BookingConsultationModel.fromDoc(doc);
          }).toList();

          // Dokter valid di Firestore hanya dr. Reny dan dr. Zaskia
          // Otomatis hapus booking yang fiktif, bukan dokter resmi, atau sudah lewat dari Firebase Firestore
          final validList = <BookingConsultationModel>[];
          for (final b in allList) {
            final docName = b.doctor.name.toLowerCase();
            final childName = b.child.name.toLowerCase();

            final isAllowedDoctor = docName.contains('reny') || docName.contains('zaskia');
            final isFake = !isAllowedDoctor ||
                b.id == 'book_1' ||
                b.id == 'book_2' ||
                b.id == 'book_3' ||
                childName.contains('devaro') ||
                childName.contains('anita'); // Anita di riwayat booking lama yang kadaluarsa

            if (isFake) {
              try {
                await _db.collection(_collectionName).doc(b.id).delete();
                debugPrint('[BookingService] Otomatis menghapus booking fiktif dari Firestore: ${b.id} (${b.doctor.name})');
              } catch (e) {
                debugPrint('[BookingService] Gagal menghapus booking fiktif: $e');
              }
              continue;
            }

            if (b.isExpired) {
              try {
                await _db.collection(_collectionName).doc(b.id).delete();
                debugPrint('[BookingService] Otomatis menghapus booking yang sudah lewat dari Firestore: ${b.id} (${b.doctor.name})');
              } catch (e) {
                debugPrint('[BookingService] Gagal menghapus booking expired: $e');
              }
            } else {
              validList.add(b);
            }
          }

          // Urutkan jadwal: yang sedang berlangsung atau terdekat di masa depan di paling atas
          _sortBookings(validList);

          final distinctList = _deduplicateBookings(validList);
          bookingsNotifier.value = distinctList;

          // Perbarui activeBookingNotifier jika ada booking yang sedang aktif
          _updateActiveBooking(distinctList);

          // Sinkronisasi pengingat jadwal booking ke NotificationService HANYA untuk akun yang sedang login
          final currentUid = UserService().currentUser.id;
          if (currentUid.isNotEmpty) {
            final userBookings = distinctList.where((b) {
              return b.userId == currentUid || b.child.ownerId == currentUid;
            }).toList();
            NotificationService().syncActiveBookings(userBookings);
          }
        },
        onError: (e) {
          debugPrint('[BookingService] Firestore listener error: $e');
        },
      );
    } catch (e) {
      debugPrint('[BookingService] Gagal memasang Firestore listener: $e');
    }
  }

  /// Menghilangkan duplikasi booking berdasarkan ID atau slot waktu yang identik
  List<BookingConsultationModel> _deduplicateBookings(List<BookingConsultationModel> list) {
    final seenIds = <String>{};
    final seenSlotKeys = <String>{};
    final result = <BookingConsultationModel>[];

    for (final b in list) {
      // Hanya skip jika benar-benar expired (bukan selesai)
      if (b.isExpired) continue;

      // 1. Cek duplikasi ID dokumen
      if (!seenIds.add(b.id)) continue;

      // 2. Cek duplikasi slot identik (anak yang sama, dokter yang sama, tanggal dan jam yang sama)
      final dateKey = '${b.scheduledDate.year}-${b.scheduledDate.month}-${b.scheduledDate.day}';
      final childKey = b.child.id.isNotEmpty ? b.child.id : b.child.name.toLowerCase().trim();
      final doctorKey = b.doctor.id.isNotEmpty ? b.doctor.id : b.doctor.name.toLowerCase().trim();
      final slotKey = '$childKey|$doctorKey|$dateKey|${b.scheduledTimeSlot.trim()}';

      if (!seenSlotKeys.add(slotKey)) {
        continue;
      }

      result.add(b);
    }
    return result;
  }

  /// Timer pembersihan berkala untuk menghapus jadwal yang baru saja lewat
  void _startAutoCleanupTimer() {
    if (bookingsNotifier.value.isEmpty) return;
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _cleanupExpiredBookings();
    });
  }

  /// Menghapus booking yang telah lewat jadwalnya dari memori dan Firestore.
  /// Booking berstatus 'Selesai' TIDAK dihapus karena digunakan sebagai riwayat.
  Future<void> _cleanupExpiredBookings() async {
    final current = bookingsNotifier.value;
    if (current.isEmpty) {
      _cleanupTimer?.cancel();
      _cleanupTimer = null;
      return;
    }
    // Hanya hapus yang benar-benar expired (bukan selesai)
    final expired = current.where((b) => b.isExpired).toList();
    if (expired.isEmpty) return;

    final remaining = current.where((b) => !b.isExpired).toList();
    _sortBookings(remaining);
    bookingsNotifier.value = remaining;
    _updateActiveBooking(remaining);

    for (final b in expired) {
      try {
        await _db.collection(_collectionName).doc(b.id).delete();
        debugPrint('[BookingService] Auto-cleanup: berhasil menghapus booking expired ${b.id}');
      } catch (e) {
        debugPrint('[BookingService] Auto-cleanup: gagal hapus ${b.id}: $e');
      }
    }
  }


  /// Mengurutkan daftar booking berdasarkan prioritas:
  /// 1. Sedang Berlangsung / Dalam rentang waktu konsultasi aktif (paling atas)
  /// 2. Terjadwal di masa depan (kronologis: tanggal & jam mulai terdekat lebih dulu)
  /// 3. Selesai / Lewat (di bagian akhir)
  void _sortBookings(List<BookingConsultationModel> list) {
    list.sort((a, b) {
      // Prioritaskan yang sedang aktif saat ini
      final aActive = (a.isInTimeWindow || a.status == 'Sedang Berlangsung') && !a.isExpired;
      final bActive = (b.isInTimeWindow || b.status == 'Sedang Berlangsung') && !b.isExpired;
      if (aActive && !bActive) return -1;
      if (!aActive && bActive) return 1;

      // Keduanya sama-sama aktif atau sama-sama mendatang: urutkan tanggal & jam mulai terdekat (ascending)
      return a.scheduledStartDateTime.compareTo(b.scheduledStartDateTime);
    });
  }

  void _updateActiveBooking(List<BookingConsultationModel> list) {
    if (list.isEmpty) {
      activeBookingNotifier.value = null;
      return;
    }
    // Prioritaskan booking yang sedang dalam time window atau sedang berlangsung
    final active = list.where((b) => (b.isInTimeWindow || b.status == 'Sedang Berlangsung') && !b.isExpired);
    if (active.isNotEmpty) {
      activeBookingNotifier.value = active.first;
      return;
    }
    // Jika tidak ada yang sedang aktif saat ini, ambil booking terjadwal terdekat di masa depan
    final upcoming = list.where((b) => b.isBeforeStart && b.status != 'Dibatalkan' && !b.isExpired);
    if (upcoming.isNotEmpty) {
      activeBookingNotifier.value = upcoming.first;
    } else {
      activeBookingNotifier.value = list.where((b) => !b.isExpired).firstOrNull;
    }
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _bookingsSub?.cancel();
  }

  /// Daftar semua riwayat / jadwal booking pengguna (tersinkronkan realtime ke Firestore)
  final ValueNotifier<List<BookingConsultationModel>> bookingsNotifier =
      ValueNotifier<List<BookingConsultationModel>>([]);

  /// Booking yang sedang aktif saat ini
  final ValueNotifier<BookingConsultationModel?> activeBookingNotifier =
      ValueNotifier<BookingConsultationModel?>(null);

  List<BookingConsultationModel> get bookings => bookingsNotifier.value;

  /// Menambahkan booking baru dan menyimpannya langsung ke Firestore
  Future<void> addBooking(BookingConsultationModel booking) async {
    // Pastikan userId terisi dengan ID pengguna yang sedang login jika belum ada
    BookingConsultationModel modelToSave = booking;
    if (modelToSave.userId == null || modelToSave.userId!.isEmpty) {
      try {
        final currentUid = UserService().currentUser.id;
        if (currentUid.isNotEmpty) {
          modelToSave = modelToSave.copyWith(userId: currentUid);
        }
      } catch (_) {}
    }

    // 1. Validasi jadwal dokter: cuti, hari libur praktik, dan ketersediaan slot
    final scheduledDate = booking.scheduledDate;
    final doctorId = booking.doctor.id;

    // Cek cuti dokter
    final cuti = JadwalDokterService().getCutiPadaTanggal(doctorId, scheduledDate);
    if (cuti != null && cuti.isSeharian) {
      throw StateError('Dokter ${booking.doctor.name} sedang cuti pada tanggal ini (${cuti.alasan}).');
    }

    // Cek apakah dokter berpraktik pada hari tersebut
    final jadwalDokter = JadwalDokterService().getJadwalDokter(doctorId);
    if (jadwalDokter.any((j) => j.aktif)) {
      final isPraktik = JadwalDokterService().isDokterPraktikPadaHari(doctorId, scheduledDate.weekday);
      if (!isPraktik) {
        final namaHari = JadwalPraktikModel.getNamaHari(scheduledDate.weekday);
        throw StateError('Dokter ${booking.doctor.name} tidak berpraktik pada hari $namaHari.');
      }
    }

    // Cek ketersediaan slot agar tidak terjadi tabrakan / double booking
    final currentSlots = JadwalDokterService().hitungSemuaSlot(
      dokterId: doctorId,
      tanggal: scheduledDate,
    );
    if (currentSlots.isNotEmpty) {
      final matchingSlot = currentSlots.where(
        (s) => s.timeLabel.contains(booking.scheduledTimeSlot) ||
            booking.scheduledTimeSlot.contains(s.timeLabel),
      ).firstOrNull;
      if (matchingSlot != null && !matchingSlot.isAvailable) {
        throw StateError('Slot jadwal ${booking.scheduledTimeSlot} sudah terisi atau tidak tersedia.');
      }
    }

    // 2. Simpan ke Firestore koleksi consultation_booking TERLEBIH DAHULU
    try {
      await _db.collection(_collectionName).doc(modelToSave.id).set(modelToSave.toMap());
      debugPrint('[BookingService] ✓ Sukses menulis booking ${modelToSave.id} ke Firestore ($_collectionName)');
    } catch (e, stack) {
      debugPrint('[BookingService] ✗ Gagal simpan booking ke Firestore ($_collectionName): $e\n$stack');
      rethrow;
    }

    // 2. Update in-memory dengan pengurutan kronologis dan deduplikasi aman
    final currentList = List<BookingConsultationModel>.from(bookingsNotifier.value);
    currentList.removeWhere((b) => b.id == modelToSave.id);
    currentList.add(modelToSave);
    _sortBookings(currentList);
    final distinctList = _deduplicateBookings(currentList);
    bookingsNotifier.value = distinctList;
    if (activeBookingNotifier.value == null || activeBookingNotifier.value!.id == modelToSave.id) {
      activeBookingNotifier.value = modelToSave;
    }

    // 3. Otomatis sinkronisasi event & alarm pengingat ke Google Kalender pengguna
    GoogleCalendarService().syncBookingToGoogleCalendar(modelToSave);

    // 4. Kirim notifikasi bahwa booking dokter berhasil dilakukan
    NotificationService().addBookingSuccessNotification(
      doctorName: modelToSave.doctor.name,
      childName: modelToSave.child.name,
      dateFormatted: modelToSave.formattedDate,
      timeSlot: modelToSave.scheduledTimeSlot,
      scheduledTime: modelToSave.scheduledStartDateTime,
    );

    // 5. Jadwalkan pengingat saat waktu konsultasi tiba
    NotificationService().addBookingReminderNotification(
      doctorName: modelToSave.doctor.name,
      childName: modelToSave.child.name,
      dateFormatted: modelToSave.formattedDate,
      timeSlot: modelToSave.scheduledTimeSlot,
      scheduledTime: modelToSave.scheduledStartDateTime,
      bookingId: modelToSave.id,
    );
  }

  /// Menghasilkan slot waktu yang tersedia untuk dokter pada tanggal tertentu
  /// Dihitung dinamis dari JadwalDokterService dikurangi Cuti dan Booking.
  /// Slot yang sudah terisi dikembalikan dengan isAvailable = false agar UI
  /// dapat menampilkan badge '(Penuh)' dan mencegah pemilihan.
  List<DoctorTimeSlot> getAvailableSlotsForDoctor({
    required DoctorModel doctor,
    required DateTime date,
  }) {
    final slots = JadwalDokterService().hitungSemuaSlot(
      dokterId: doctor.id,
      tanggal: date,
    );

    return slots.map((slot) {
      final hour = slot.startDateTime.hour;
      String period = 'Pagi';
      if (hour >= 11 && hour < 15) {
        period = 'Siang';
      } else if (hour >= 15 && hour < 18) {
        period = 'Sore';
      } else if (hour >= 18) {
        period = 'Malam';
      }

      return DoctorTimeSlot(
        time: slot.timeLabel,
        startHour: slot.startDateTime.hour,
        startMinute: slot.startDateTime.minute,
        period: period,
        isAvailable: slot.isAvailable,
      );
    }).toList();
  }

  /// Membuat booking baru dengan validasi race condition dan persistensi ke Cloud Firestore
  Future<BookingConsultationModel> createBooking({
    required DoctorModel doctor,
    required ChildModel child,
    required DateTime date,
    required DoctorTimeSlot slot,
    String? userId,
  }) async {
    // 1. Cek Cuti dokter (seharian maupun parsial)
    final cuti = JadwalDokterService().getCutiPadaTanggal(doctor.id, date);
    if (cuti != null) {
      if (cuti.isSeharian) {
        throw StateError(
          'Dokter ${doctor.name} sedang cuti pada tanggal ini (${cuti.alasan}). Silakan pilih tanggal lain.',
        );
      } else if (cuti.jamMulai != null && cuti.jamSelesai != null) {
        final slotStartMin = (slot.startHour * 60) + slot.startMinute;
        final slotEndMin = slotStartMin + 30;
        final cStart = _timeToMinutes(cuti.jamMulai!) ?? 0;
        final cEnd = _timeToMinutes(cuti.jamSelesai!) ?? (24 * 60);
        if (slotStartMin < cEnd && slotEndMin > cStart) {
          throw StateError(
            'Dokter ${doctor.name} sedang berhalangan pada jam ${cuti.jamMulai} - ${cuti.jamSelesai} (${cuti.alasan}).',
          );
        }
      }
    }

    // 2. Cek apakah dokter berpraktik pada hari tersebut
    final jadwalDokter = JadwalDokterService().getJadwalDokter(doctor.id);
    if (jadwalDokter.any((j) => j.aktif)) {
      final isPraktik = JadwalDokterService().isDokterPraktikPadaHari(doctor.id, date.weekday);
      if (!isPraktik) {
        final namaHari = JadwalPraktikModel.getNamaHari(date.weekday);
        throw StateError(
          'Dokter ${doctor.name} tidak memiliki jadwal praktik pada hari $namaHari.',
        );
      }
    }

    // 3. Validasi race condition: cek ketersediaan slot terkini
    final currentSlots = JadwalDokterService().hitungSemuaSlot(
      dokterId: doctor.id,
      tanggal: date,
    );
    if (currentSlots.isNotEmpty) {
      final matchingSlot = currentSlots.where((s) => s.timeLabel == slot.time).firstOrNull;
      if (matchingSlot != null && !matchingSlot.isAvailable) {
        throw StateError('Slot waktu ${slot.time} sudah dipesan atau tidak tersedia, silakan pilih jam lain.');
      }
    }

    final startDt = DateTime(
      date.year,
      date.month,
      date.day,
      slot.startHour,
      slot.startMinute,
    );
    final endDt = startDt.add(const Duration(minutes: 30));

    final id = 'booking-${DateTime.now().millisecondsSinceEpoch}';
    final calUrl = generateGoogleCalendarUrl(
      doctor: doctor,
      child: child,
      startTime: startDt,
      endTime: endDt,
    );

    // Resolusi userId: prioritas userId parameter, lalu ownerId anak, lalu user login
    String resolvedUserId = userId ?? child.ownerId;
    if (resolvedUserId.isEmpty) {
      try {
        resolvedUserId = UserService().currentUser.id;
      } catch (_) {}
    }

    final newBooking = BookingConsultationModel(
      id: id,
      userId: resolvedUserId.isNotEmpty ? resolvedUserId : null,
      doctor: doctor,
      child: child,
      bookingDate: date,
      timeSlot: slot.time,
      scheduledStartDateTime: startDt,
      scheduledEndDateTime: endDt,
      status: 'Terjadwal',
      googleCalendarUrl: calUrl,
      createdAt: DateTime.now(),
    );

    // Simpan ke Cloud Firestore TERLEBIH DAHULU (prioritas utama)
    try {
      await _db.collection(_collectionName).doc(newBooking.id).set(newBooking.toMap());
      debugPrint('[BookingService] ✓ Sukses menulis booking ${newBooking.id} ke Firestore ($_collectionName)');
    } catch (e, stack) {
      debugPrint('[BookingService] ✗ Gagal menulis booking ke Firestore: $e\n$stack');
      rethrow; // Lempar ulang agar UI bisa menampilkan pesan error
    }

    // Simpan ke in-memory (setelah Firestore berhasil) dengan pengurutan kronologis dan deduplikasi aman
    final currentList = List<BookingConsultationModel>.from(bookingsNotifier.value);
    currentList.removeWhere((b) => b.id == newBooking.id);
    currentList.add(newBooking);
    _sortBookings(currentList);
    final distinctList = _deduplicateBookings(currentList);
    bookingsNotifier.value = distinctList;
    activeBookingNotifier.value = newBooking;

    // Otomatis sinkronisasi event & alarm pengingat ke Google Kalender pengguna
    GoogleCalendarService().syncBookingToGoogleCalendar(newBooking);

    // Kirim notifikasi bahwa booking dokter berhasil dilakukan
    NotificationService().addBookingSuccessNotification(
      doctorName: newBooking.doctor.name,
      childName: newBooking.child.name,
      dateFormatted: newBooking.formattedDate,
      timeSlot: newBooking.scheduledTimeSlot,
      scheduledTime: newBooking.scheduledStartDateTime,
    );

    // Jadwalkan pengingat saat waktu konsultasi tiba
    NotificationService().addBookingReminderNotification(
      doctorName: newBooking.doctor.name,
      childName: newBooking.child.name,
      dateFormatted: newBooking.formattedDate,
      timeSlot: newBooking.scheduledTimeSlot,
      scheduledTime: newBooking.scheduledStartDateTime,
      bookingId: newBooking.id,
    );

    return newBooking;
  }

  /// Memperbarui booking dengan data formulir konsultasi (BB, TB, Keluhan, dan sessionId)
  /// dan menyinkronkan pembaruan langsung ke Firestore
  void updateBookingForm({
    required String bookingId,
    required double weightKg,
    required double heightCm,
    required String complaint,
    String? sessionId,
  }) {
    final list = List<BookingConsultationModel>.from(bookingsNotifier.value);
    final idx = list.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      final current = list[idx];
      // Hanya jadikan 'Sedang Berlangsung' jika waktu sesi sudah masuk jendela konsultasi
      final targetStatus = current.isInTimeWindow ? 'Sedang Berlangsung' : 'Siap Konsultasi';
      final updated = current.copyWith(
        weightKg: weightKg,
        heightCm: heightCm,
        complaint: complaint,
        sessionId: sessionId ?? current.sessionId,
        status: targetStatus,
      );
      list[idx] = updated;
      bookingsNotifier.value = list;

      if (activeBookingNotifier.value?.id == bookingId) {
        activeBookingNotifier.value = updated;
      }
    }

    // Update di Cloud Firestore
    final currentBooking = list.where((b) => b.id == bookingId).firstOrNull;
    final targetStatus = (currentBooking != null && currentBooking.isInTimeWindow)
        ? 'Sedang Berlangsung'
        : 'Siap Konsultasi';

    final updateData = <String, dynamic>{
      'weightKg': weightKg,
      'heightCm': heightCm,
      'complaint': complaint,
      'status': targetStatus,
    };
    if (sessionId != null && sessionId.isNotEmpty) {
      updateData['sessionId'] = sessionId;
    }
    _db.collection(_collectionName).doc(bookingId).update(updateData).catchError((e) {
      debugPrint('[BookingService] Gagal updateBookingForm di Firestore: $e');
    });
  }

  /// Mengubah status booking (misalnya 'Dibatalkan' atau 'Selesai')
  /// dan menyinkronkan status tersebut ke Firestore.
  void updateBookingStatus(String bookingId, String newStatus) {
    final list = List<BookingConsultationModel>.from(bookingsNotifier.value);
    final idx = list.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      final updated = list[idx].copyWith(status: newStatus);
      list[idx] = updated;
      bookingsNotifier.value = list;

      if (activeBookingNotifier.value?.id == bookingId) {
        activeBookingNotifier.value = updated;
      }
    }

    // Update di Cloud Firestore
    _db.collection(_collectionName).doc(bookingId).update({
      'status': newStatus,
    }).catchError((e) {
      debugPrint('[BookingService] Gagal updateBookingStatus di Firestore: $e');
    });
  }

  /// Membatalkan booking konsultasi dan menyelaraskannya ke Firestore serta notifier
  Future<void> cancelBooking(String bookingId) async {
    updateBookingStatus(bookingId, 'Dibatalkan');
    try {
      await _db.collection(_collectionName).doc(bookingId).delete();
      debugPrint('[BookingService] Sukses menghapus booking $bookingId yang dibatalkan');
    } catch (e) {
      debugPrint('[BookingService] Gagal menghapus booking dari Firestore: $e');
    }
  }


  /// Format URL Google Calendar (Render Template Action)
  /// Menyertakan nama dokter, nama anak, waktu janji temu, dan pengingat
  String generateGoogleCalendarUrl({
    required DoctorModel doctor,
    required ChildModel child,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    // Format UTC: YYYYMMDDTHHmmssZ
    final startUtc = startTime.toUtc();
    final endUtc = endTime.toUtc();

    String formatUtc(DateTime dt) {
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      final s = dt.second.toString().padLeft(2, '0');
      return '$y$m${d}T$h$min${s}Z';
    }

    final datesParam = '${formatUtc(startUtc)}/${formatUtc(endUtc)}';
    final title = 'Konsultasi Dokter: ${doctor.name} - PediaGrow';
    final details =
        'Jadwal konsultasi kesehatan anak: ${child.name} '
        'bersama ${doctor.name} (${doctor.specialization}) '
        'melalui sesi chat aplikasi PediaGrow.';
    const location = 'Aplikasi PediaGrow (Online Chat)';

    return 'https://calendar.google.com/calendar/render?'
        'action=TEMPLATE&'
        'text=${Uri.encodeComponent(title)}&'
        'dates=$datesParam&'
        'details=${Uri.encodeComponent(details)}&'
        'location=${Uri.encodeComponent(location)}';
  }

  /// Membuka Google Kalender secara langsung
  Future<bool> launchGoogleCalendar(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('[BookingService] Error launchGoogleCalendar: $e');
    }
    return false;
  }

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
}

class DoctorTimeSlot {
  final String time;
  final int startHour;
  final int startMinute;
  final String period; // Pagi, Siang, Sore, Malam
  final bool isAvailable;

  const DoctorTimeSlot({
    required this.time,
    required this.startHour,
    required this.startMinute,
    required this.period,
    this.isAvailable = true,
  });

  DoctorTimeSlot copyWith({
    String? time,
    int? startHour,
    int? startMinute,
    String? period,
    bool? isAvailable,
  }) {
    return DoctorTimeSlot(
      time: time ?? this.time,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      period: period ?? this.period,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
