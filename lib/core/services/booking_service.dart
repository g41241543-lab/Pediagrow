import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/booking_consultation_model.dart';

/// Service singleton untuk mengelola daftar jadwal booking konsultasi dokter
/// yang dibuat oleh pengguna, tersimpan dan tersinkronisasi di Firestore.
class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'consultation_bookings';

  BookingService._internal() {
    _initFirestoreListener();
  }

  /// Notifier daftar booking agar UI reaktif terhadap penambahan booking baru
  final ValueNotifier<List<BookingConsultationModel>> bookingsNotifier =
      ValueNotifier<List<BookingConsultationModel>>([]);

  List<BookingConsultationModel> get bookings => bookingsNotifier.value;

  void _initFirestoreListener() {
    try {
      _db
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
        (snapshot) {
          final items = snapshot.docs
              .map((doc) => BookingConsultationModel.fromDoc(doc))
              .toList();
          // Merge dengan memory jika ada data lokal
          final existingIds = items.map((i) => i.id).toSet();
          final localOnly =
              bookingsNotifier.value.where((b) => !existingIds.contains(b.id));
          bookingsNotifier.value = [...items, ...localOnly];
        },
        onError: (err) {
          debugPrint('BookingService Firestore error: $err');
        },
      );
    } catch (e) {
      debugPrint('BookingService init error: $e');
    }
  }

  /// Menambahkan booking konsultasi baru ke lokal notifier dan Firestore
  Future<void> addBooking(BookingConsultationModel booking) async {
    // 1. Update lokal langsung agar instan di UI
    if (!bookingsNotifier.value.any((b) => b.id == booking.id)) {
      bookingsNotifier.value = [booking, ...bookingsNotifier.value];
    }

    // 2. Simpan ke Firestore
    try {
      await _db.collection(_collection).doc(booking.id).set(booking.toMap());
    } catch (e) {
      debugPrint('Gagal menyimpan booking ke Firestore: $e');
    }
  }

  /// Menghapus booking berdasarkan ID
  Future<void> removeBooking(String bookingId) async {
    bookingsNotifier.value =
        bookingsNotifier.value.where((b) => b.id != bookingId).toList();

    try {
      await _db.collection(_collection).doc(bookingId).delete();
    } catch (e) {
      debugPrint('Gagal menghapus booking dari Firestore: $e');
    }
  }
}

