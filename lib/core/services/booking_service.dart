import 'package:flutter/foundation.dart';

import '../../models/booking_consultation_model.dart';
import '../../models/child_model.dart';
import '../../models/doctor_model.dart';

/// Service singleton untuk mengelola daftar jadwal booking konsultasi dokter
/// yang dibuat oleh pengguna.
class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;

  BookingService._internal() {
    _initDefaultBookings();
  }

  /// Notifier daftar booking agar UI reaktif terhadap penambahan booking baru
  final ValueNotifier<List<BookingConsultationModel>> bookingsNotifier =
      ValueNotifier<List<BookingConsultationModel>>([]);

  List<BookingConsultationModel> get bookings => bookingsNotifier.value;

  void addBooking(BookingConsultationModel booking) {
    bookingsNotifier.value = [booking, ...bookingsNotifier.value];
  }

  void _initDefaultBookings() {
    // Mock sample bookings awal dengan 2 profil anak berbeda
    // untuk memperlihatkan diferensiasi jika pengguna memiliki >1 anak
    final child1 = ChildModel(
      id: 'child_mock_1',
      name: 'Devaro Ramadhan',
      gender: 'Laki-laki',
      ageDescription: '1 tahun 2 bulan 13 hari',
      birthDate: DateTime.now().subtract(const Duration(days: 440)),
      photoUrl: null,
    );

    final child2 = ChildModel(
      id: 'child_mock_2',
      name: 'Naya Seiza Putri',
      gender: 'Perempuan',
      ageDescription: '0 tahun 8 bulan 20 hari',
      birthDate: DateTime.now().subtract(const Duration(days: 260)),
      photoUrl: null,
    );

    const doc1 = DoctorModel(
      id: 'doc_1',
      name: 'dr. Ahmad Nuri, Sp. A',
      specialization: 'Spesialis Anak',
      experienceYears: 12,
      isOnline: true,
      strNumber: 'STR-33.1.1.100.2.20.123456',
      placesOfPractice: ['RS Hermina Pasteur', 'Klinik Tumbuh Kembang'],
    );

    const doc2 = DoctorModel(
      id: 'doc_2',
      name: 'dr. Ririn Esterina, Sp.A',
      specialization: 'Spesialis Anak',
      experienceYears: 8,
      isOnline: true,
      strNumber: 'STR-33.1.1.100.2.20.654321',
      placesOfPractice: ['RSIA Melinda Bandung', 'Puskesmas Garuda'],
    );

    const doc3 = DoctorModel(
      id: 'doc_3',
      name: 'dr. B. Gebyar Tri Baskoro, Sp.A',
      specialization: 'Spesialis Anak',
      experienceYears: 10,
      isOnline: true,
      strNumber: 'STR-33.1.1.100.2.20.789101',
      placesOfPractice: ['RS Santo Borromeus'],
    );

    bookingsNotifier.value = [
      BookingConsultationModel(
        id: 'book_1',
        doctor: doc1,
        child: child1,
        scheduledDate: DateTime.now().add(const Duration(days: 2)),
        scheduledTimeSlot: '09:00 - 09:30 WIB',
        status: 'Terjadwal',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      BookingConsultationModel(
        id: 'book_2',
        doctor: doc2,
        child: child2,
        scheduledDate: DateTime.now().add(const Duration(days: 4)),
        scheduledTimeSlot: '13:30 - 14:00 WIB',
        status: 'Terjadwal',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      BookingConsultationModel(
        id: 'book_3',
        doctor: doc3,
        child: child1,
        scheduledDate: DateTime.now().add(const Duration(days: 7)),
        scheduledTimeSlot: '10:30 - 11:00 WIB',
        status: 'Terjadwal',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}
