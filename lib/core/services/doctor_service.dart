import 'package:flutter/foundation.dart';

import '../../models/doctor_model.dart';

/// Service repositori untuk mengelola data Dokter pada PediaGrow.
///
/// Bertindak sebagai sumber data terpusat (single source of truth) yang
/// digunakan oleh:
/// - Sisi Pengguna: `DaftarDokterPage`, `ProfilDokterPage`, `FormulirKonsultasiPage`
/// - Sisi PMIK/Superadmin: Pengelolaan data dokter (tambah, ubah, hapus)
///
/// Mendukung pembaruan reaktif via [doctorsNotifier] sehingga saat PMIK
/// mengubah atau menambahkan dokter baru di database/API, tampilan di HP
/// pengguna otomatis terbarui tanpa perlu refresh manual.
class DoctorService {
  static final DoctorService _instance = DoctorService._internal();
  factory DoctorService() => _instance;

  DoctorService._internal() {
    // Inisialisasi awal dengan data PMIK terverifikasi
    _doctorsNotifier = ValueNotifier<List<DoctorModel>>(
      List<DoctorModel>.from(DoctorModel.dummyList),
    );
  }

  late final ValueNotifier<List<DoctorModel>> _doctorsNotifier;

  /// Notifier untuk mendengarkan perubahan daftar dokter secara real-time
  ValueListenable<List<DoctorModel>> get doctorsNotifier => _doctorsNotifier;

  /// Mengambil daftar seluruh dokter saat ini
  List<DoctorModel> get currentDoctors =>
      List<DoctorModel>.unmodifiable(_doctorsNotifier.value);

  /// Mengambil daftar dokter (asinkron untuk kompatibilitas API/database di masa depan)
  Future<List<DoctorModel>> getDoctors() async {
    // Simulasi delay jaringan minimal jika nantinya dihubungkan ke REST API/Database
    await Future.delayed(const Duration(milliseconds: 50));
    return currentDoctors;
  }

  /// Pencarian dokter berdasarkan nama atau spesialis secara dinamis
  List<DoctorModel> filterDoctors(String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return currentDoctors;
    }

    return currentDoctors.where((doc) {
      final nameMatches = doc.name.toLowerCase().contains(cleanQuery);
      final specMatches = doc.specialization.toLowerCase().contains(cleanQuery);
      final hospitalMatches =
          doc.hospital?.toLowerCase().contains(cleanQuery) ?? false;
      final placesMatch = doc.placesOfPractice
          .any((p) => p.toLowerCase().contains(cleanQuery));

      return nameMatches || specMatches || hospitalMatches || placesMatch;
    }).toList();
  }

  /// Mengambil profil dokter berdasarkan ID unik
  Future<DoctorModel?> getDoctorById(String id) async {
    try {
      return currentDoctors.firstWhere((doc) => doc.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Menambahkan dokter baru (oleh PMIK Superadmin)
  Future<void> addDoctor(DoctorModel doctor) async {
    final updated = List<DoctorModel>.from(_doctorsNotifier.value)..add(doctor);
    _doctorsNotifier.value = updated;
  }

  /// Memperbarui informasi dokter (oleh PMIK Superadmin)
  Future<void> updateDoctor(DoctorModel doctor) async {
    final list = List<DoctorModel>.from(_doctorsNotifier.value);
    final index = list.indexWhere((item) => item.id == doctor.id);
    if (index != -1) {
      list[index] = doctor;
      _doctorsNotifier.value = list;
    }
  }

  /// Menghapus dokter dari daftar (oleh PMIK Superadmin)
  Future<void> deleteDoctor(String id) async {
    final updated = List<DoctorModel>.from(_doctorsNotifier.value)
      ..removeWhere((item) => item.id == id);
    _doctorsNotifier.value = updated;
  }

  /// Mengosongkan daftar dokter (untuk skenario pengujian database kosong)
  void clearAllDoctors() {
    _doctorsNotifier.value = [];
  }

  /// Mengembalikan data ke daftar default PMIK
  void resetToDefault() {
    _doctorsNotifier.value = List<DoctorModel>.from(DoctorModel.dummyList);
  }
}
