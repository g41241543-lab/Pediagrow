import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/doctor_model.dart';
import '../../models/staff_account_model.dart';
import 'staff_auth_service.dart';

/// Service untuk mengelola data dokter di Firestore.
///
/// Sumber data dokter sepenuhnya berasal dari collection 'doctors'.
/// Dokter tidak dibuat secara default di dalam aplikasi.
///
/// Dipakai oleh:
/// - Sisi Pengguna:
///   - DaftarDokterPage
///   - ProfilDokterPage
///   - FormulirKonsultasiPage
///
/// - Sisi PMIK/Superadmin:
///   - Tambah dokter
///   - Ubah dokter
///   - Hapus dokter
///
/// Perubahan data dokter di Firestore dipantau secara real-time.
/// Jadi ketika PMIK menambah, mengubah, atau menghapus dokter,
/// daftar dokter pada sisi pengguna akan ikut diperbarui.
class DoctorService {
  // ============================================================
  // SINGLETON
  // ============================================================

  static final DoctorService _instance = DoctorService._internal();

  factory DoctorService() => _instance;

  DoctorService._internal();

  // ============================================================
  // FIRESTORE
  // ============================================================

  static const String _collection = 'doctors';

  FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // DOKTER NOTIFIER
  // ============================================================

  /// Daftar dokter yang berasal dari Firestore.
  ///
  /// Nilai awal kosong karena aplikasi tidak memiliki
  /// dokter bawaan/default.
  final ValueNotifier<List<DoctorModel>> _doctorsNotifier =
      ValueNotifier<List<DoctorModel>>([]);

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  // ============================================================
  // REAL-TIME LISTENER
  // ============================================================

  /// Mulai mendengarkan perubahan collection 'doctors'.
  ///
  /// Listener hanya dibuat satu kali.
  void _startListening() {
    if (_subscription != null) return;

    final db = _db;
    if (db == null) return;

    try {
      _subscription = db
          .collection(_collection)
          .snapshots()
          .listen(
            (snapshot) {
              final List<DoctorModel> list = snapshot.docs
                  .map(
                    (doc) => DoctorModel.fromMap({...doc.data(), 'id': doc.id}),
                  )
                  .toList();

              // Urutkan berdasarkan nama dokter.
              list.sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );

              _doctorsNotifier.value = list;
            },
            onError: (error) {
              debugPrint('[DoctorService] listen error: $error');
            },
          );
    } catch (e) {
      debugPrint('[DoctorService] start listening error: $e');
    }
  }

  /// Membantu inject dokter saat testing widget
  @visibleForTesting
  void setDoctorsForTesting(List<DoctorModel> doctors) {
    _doctorsNotifier.value = doctors;
  }

  // ============================================================
  // GETTERS
  // ============================================================

  /// Notifier untuk mendengarkan daftar dokter secara real-time.
  ///
  /// Jika Firestore kosong, nilai yang diterima adalah [].
  ValueListenable<List<DoctorModel>> get doctorsNotifier {
    _startListening();
    return _doctorsNotifier;
  }

  /// Mengambil daftar dokter yang saat ini tersedia.
  ///
  /// Data berasal dari Firestore.
  /// Tidak ada dokter dummy/default.
  List<DoctorModel> get currentDoctors {
    _startListening();

    return List<DoctorModel>.unmodifiable(_doctorsNotifier.value);
  }

  /// Mengambil daftar dokter.
  Future<List<DoctorModel>> getDoctors() async {
    return currentDoctors;
  }

  // ============================================================
  // SEARCH DOKTER
  // ============================================================

  /// Mencari dokter berdasarkan:
  /// - Nama
  /// - Spesialisasi
  /// - Rumah sakit
  /// - Tempat praktik
  ///
  /// Pencarian dilakukan hanya terhadap dokter
  /// yang sudah ada di Firestore.
  List<DoctorModel> filterDoctors(String query) {
    final String cleanQuery = query.trim().toLowerCase();

    // Jika pencarian kosong, tampilkan semua dokter.
    if (cleanQuery.isEmpty) {
      return currentDoctors;
    }

    return currentDoctors.where((doctor) {
      final bool nameMatches = doctor.name.toLowerCase().contains(cleanQuery);

      final bool specializationMatches = doctor.specialization
          .toLowerCase()
          .contains(cleanQuery);

      final bool hospitalMatches =
          doctor.hospital?.toLowerCase().contains(cleanQuery) ?? false;

      final bool placesMatch = doctor.placesOfPractice.any(
        (place) => place.toLowerCase().contains(cleanQuery),
      );

      return nameMatches ||
          specializationMatches ||
          hospitalMatches ||
          placesMatch;
    }).toList();
  }

  // ============================================================
  // GET DOKTER BERDASARKAN ID
  // ============================================================

  /// Mengambil satu profil dokter berdasarkan ID dokumen Firestore.
  Future<DoctorModel?> getDoctorById(String id) async {
    try {
      final db = _db;
      if (db == null) return null;

      final DocumentSnapshot<Map<String, dynamic>> doc = await db
          .collection(_collection)
          .doc(id)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data();

      if (data == null) {
        return null;
      }

      return DoctorModel.fromMap({...data, 'id': doc.id});
    } catch (e) {
      debugPrint('[DoctorService] getDoctorById error: $e');

      return null;
    }
  }

  // ============================================================
  // TAMBAH DOKTER + AKUN LOGIN
  // ============================================================

  /// Membuat dokter baru sekaligus membuat akun login dokter.
  ///
  /// Proses:
  ///
  /// 1. PMIK/Superadmin memasukkan data dokter.
  /// 2. Sistem membuat akun pada collection 'staff_accounts'.
  /// 3. Sistem mendapatkan staffAccountId.
  /// 4. Profil dokter disimpan pada collection 'doctors'.
  /// 5. Profil dokter dihubungkan dengan akun melalui
  ///    field 'staff_account_id'.
  ///
  /// Tidak ada dokter default.
  /// Dokter hanya akan muncul setelah PMIK/Superadmin
  /// berhasil menambahkan dokter.
  ///
  /// Return:
  /// - true  = berhasil
  /// - false = gagal
  Future<bool> createDoctorWithAccount({
    required DoctorModel profile,
    required String email,
    required String password,
    required String createdByEmail,
  }) async {
    try {
      final db = _db;
      if (db == null) return false;

      // ----------------------------------------------------------
      // 1. BUAT AKUN STAFF DOKTER
      // ----------------------------------------------------------

      final String? staffId = await StaffAuthService().createStaffAccount(
        name: profile.name,
        email: email,
        password: password,
        role: StaffRole.dokter,
        createdByEmail: createdByEmail,
        permissions: profile.permissions,
        avatarPath: profile.avatarUrl,
      );

      // Jika akun gagal dibuat, proses dihentikan.
      if (staffId == null) {
        return false;
      }

      try {
        // --------------------------------------------------------
        // 2. SIAPKAN DATA PROFIL DOKTER
        // --------------------------------------------------------

        final Map<String, dynamic> data = profile.toMap()
          ..remove('id')
          ..['staff_account_id'] = staffId
          ..['email'] = email;

        // --------------------------------------------------------
        // 3. SIMPAN PROFIL DOKTER KE FIRESTORE
        // --------------------------------------------------------
        //
        // Menggunakan add() agar Firestore membuat ID dokumen
        // secara otomatis.
        //
        // ID tersebut nantinya akan dimasukkan kembali oleh
        // DoctorModel.fromMap() sebagai doctor.id.

        await db.collection(_collection).add(data);

        return true;
      } catch (e) {
        debugPrint('[DoctorService] create doctor profile error: $e');

        // --------------------------------------------------------
        // 4. JIKA PROFIL GAGAL DISIMPAN
        // --------------------------------------------------------
        //
        // Akun dokter yang sudah dibuat dinonaktifkan agar
        // tidak meninggalkan akun aktif tanpa profil dokter.

        await StaffAuthService().setAccountActive(staffId, false);

        return false;
      }
    } catch (e) {
      debugPrint('[DoctorService] createDoctorWithAccount error: $e');

      return false;
    }
  }

  // ============================================================
  // UPDATE DOKTER
  // ============================================================

  /// Memperbarui profil dokter.
  ///
  /// Dokter yang diperbarui adalah dokter yang sudah ada
  /// di collection 'doctors'.
  Future<void> updateDoctor(DoctorModel doctor) async {
    try {
      final db = _db;
      if (db == null) return;

      final Map<String, dynamic> data = doctor.toMap()..remove('id');

      await db.collection(_collection).doc(doctor.id).update(data);

      if (doctor.staffAccountId.isNotEmpty) {
        await StaffAuthService().updateStaffAccount(
          doctor.staffAccountId,
          name: doctor.name,
          email: doctor.email,
          permissions: doctor.permissions,
          avatarPath: doctor.avatarUrl,
        );
      }
    } catch (e) {
      debugPrint('[DoctorService] updateDoctor error: $e');
    }
  }

  // ============================================================
  // DELETE DOKTER
  // ============================================================

  /// Menghapus profil dokter.
  ///
  /// Selain menghapus profil dari collection 'doctors',
  /// akun login dokter juga dinonaktifkan.
  Future<void> deleteDoctor(String id) async {
    try {
      final db = _db;
      if (db == null) return;

      // ----------------------------------------------------------
      // 1. AMBIL DATA DOKTER
      // ----------------------------------------------------------

      final DocumentReference<Map<String, dynamic>> ref = db
          .collection(_collection)
          .doc(id);

      final DocumentSnapshot<Map<String, dynamic>> snapshot = await ref.get();

      if (!snapshot.exists) {
        return;
      }

      final String? staffId = snapshot.data()?['staff_account_id'] as String?;

      // ----------------------------------------------------------
      // 2. HAPUS PROFIL DOKTER
      // ----------------------------------------------------------

      await ref.delete();

      // ----------------------------------------------------------
      // 3. NONAKTIFKAN AKUN LOGIN DOKTER
      // ----------------------------------------------------------

      if (staffId != null && staffId.isNotEmpty) {
        await StaffAuthService().setAccountActive(staffId, false);
      }
    } catch (e) {
      debugPrint('[DoctorService] deleteDoctor error: $e');
    }
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  /// Menghentikan listener Firestore dan membersihkan notifier.
  ///
  /// Dipakai jika service memang perlu dihentikan secara manual.
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;

    _doctorsNotifier.value = [];
  }
}
