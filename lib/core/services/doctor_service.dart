import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/doctor_model.dart';
import '../../models/staff_account_model.dart';
import 'staff_auth_service.dart';
import 'storage_service.dart';
import 'superadmin_notification_service.dart';

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

  /// Dokter default untuk fallback demonstrasi atau saat belum ada dokter di Firestore.
  static const List<DoctorModel> defaultDoctors = [
    DoctorModel(
      id: 'doc_1',
      name: 'dr. Ahmad Nuri, Sp. A',
      specialization: 'Spesialis Anak',
      experienceYears: 12,
      isOnline: true,
      strNumber: 'STR-33.1.1.100.2.20.123456',
      placesOfPractice: ['Klinik Tumbuh Kembang PediaGrow', 'RS Hermina Pasteur'],
      hospital: 'Klinik Tumbuh Kembang PediaGrow',
      email: 'dokter@pediagrow.com',
    ),
    DoctorModel(
      id: 'doc_2',
      name: 'dr. Ririn Esterina, Sp.A',
      specialization: 'Spesialis Anak',
      experienceYears: 8,
      isOnline: true,
      strNumber: 'STR-33.1.1.100.2.20.654321',
      placesOfPractice: ['RSIA Melinda Bandung', 'Puskesmas Garuda'],
      hospital: 'RSIA Melinda Bandung',
    ),
    DoctorModel(
      id: 'doc_3',
      name: 'dr. B. Gebyar Tri Baskoro, Sp.A',
      specialization: 'Spesialis Anak',
      experienceYears: 10,
      isOnline: true,
      strNumber: 'STR-33.1.1.100.2.20.789101',
      placesOfPractice: ['RS Santo Borromeus'],
      hospital: 'RS Santo Borromeus',
    ),
  ];

  /// Mengambil daftar dokter yang saat ini tersedia.
  ///
  /// Data berasal dari Firestore dengan fallback ke defaultDoctors jika kosong.
  List<DoctorModel> get currentDoctors {
    _startListening();

    if (_doctorsNotifier.value.isNotEmpty) {
      return List<DoctorModel>.unmodifiable(_doctorsNotifier.value);
    }
    return defaultDoctors;
  }

  /// Menemukan profil DoctorModel yang berpasangan dengan akun StaffAccount yang login.
  DoctorModel? findDoctorForStaff(StaffAccount? staff) {
    if (staff == null) return null;
    final staffId = staff.id;
    final email = staff.email.trim().toLowerCase();
    final name = staff.name.trim().toLowerCase();
    final list = currentDoctors;

    if (staffId.isNotEmpty) {
      final match = list.where((d) => d.staffAccountId == staffId).firstOrNull;
      if (match != null) return match;
    }
    if (email.isNotEmpty) {
      final match = list
          .where((d) => (d.email ?? '').trim().toLowerCase() == email)
          .firstOrNull;
      if (match != null) return match;
    }
    if (name.isNotEmpty) {
      final match = list
          .where((d) => d.name.trim().toLowerCase() == name)
          .firstOrNull;
      if (match != null) return match;
    }
    return null;
  }

  /// Mencari dokter berdasarkan ID, StaffAccountId, atau Email
  DoctorModel? findDoctorByIdOrStaffOrEmail(String identifier) {
    final clean = identifier.trim().toLowerCase();
    if (clean.isEmpty) return null;
    for (final d in currentDoctors) {
      if (d.id == identifier ||
          d.staffAccountId == identifier ||
          (d.email != null && d.email!.trim().toLowerCase() == clean) ||
          d.name.trim().toLowerCase() == clean) {
        return d;
      }
    }
    return null;
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

      final String? persistableAvatar = profile.avatarUrl != null &&
              profile.avatarUrl!.isNotEmpty
          ? await StorageService.toPersistableString(profile.avatarUrl)
          : null;
      final DoctorModel profileToSave =
          profile.copyWith(avatarUrl: persistableAvatar);

      final String? staffId = await StaffAuthService().createStaffAccount(
        name: profileToSave.name,
        email: email,
        password: password,
        role: StaffRole.dokter,
        createdByEmail: createdByEmail,
        avatarPath: persistableAvatar,
      );

      // Jika akun gagal dibuat, proses dihentikan.
      if (staffId == null) {
        return false;
      }

      try {
        // --------------------------------------------------------
        // 2. SIAPKAN DATA PROFIL DOKTER
        // --------------------------------------------------------

        final Map<String, dynamic> data = profileToSave.toMap()
          ..remove('id')
          ..['staff_account_id'] = staffId;

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
        await SuperadminNotificationService().notifyDokterTambah(profile.name);

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

      final String? persistableAvatar = doctor.avatarUrl != null &&
              doctor.avatarUrl!.isNotEmpty
          ? await StorageService.toPersistableString(doctor.avatarUrl)
          : null;
      final DoctorModel doctorToSave =
          doctor.copyWith(avatarUrl: persistableAvatar);

      final Map<String, dynamic> data = doctorToSave.toMap()..remove('id');

      await db.collection(_collection).doc(doctorToSave.id).update(data);

      // Sinkronkan juga avatar ke staff_accounts jika staffAccountId ada
      if (doctorToSave.staffAccountId != null &&
          doctorToSave.staffAccountId!.isNotEmpty &&
          persistableAvatar != null) {
        try {
          await StaffAuthService().updateStaffAccount(
            doctorToSave.staffAccountId!,
            avatarPath: persistableAvatar,
          );
        } catch (_) {}
      }

      await SuperadminNotificationService().notifyDokterUbah(doctorToSave.name);
    } catch (e) {
      debugPrint('[DoctorService] updateDoctor error: $e');
    }
  }

  /// Memperbarui status online dokter di Firestore
  Future<void> updateOnlineStatus(String doctorId, bool isOnline) async {
    try {
      final db = _db;
      if (db == null) return;

      await db.collection(_collection).doc(doctorId).update({
        'is_online': isOnline,
      });

      final currentList = List<DoctorModel>.from(_doctorsNotifier.value);
      final idx = currentList.indexWhere((d) => d.id == doctorId);
      if (idx != -1) {
        currentList[idx] = currentList[idx].copyWith(isOnline: isOnline);
        _doctorsNotifier.value = currentList;
      }
    } catch (e) {
      debugPrint('[DoctorService] updateOnlineStatus error: $e');
    }
  }

  /// Mencari dokter berdasarkan staff account ID
  Future<DoctorModel?> findDoctorByStaffAccountId(String staffAccountId) async {
    _startListening();
    try {
      final cached = _doctorsNotifier.value.firstWhere(
        (d) => d.staffAccountId == staffAccountId,
      );
      return cached;
    } catch (_) {}

    final db = _db;
    if (db == null) return null;
    try {
      final query = await db
          .collection(_collection)
          .where('staff_account_id', isEqualTo: staffAccountId)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return DoctorModel.fromMap({...doc.data(), 'id': doc.id});
      }
    } catch (e) {
      debugPrint('[DoctorService] findDoctorByStaffAccountId error: $e');
    }
    return null;
  }

  /// Mencari dokter berdasarkan email
  Future<DoctorModel?> findDoctorByEmail(String email) async {
    _startListening();
    try {
      final cached = _doctorsNotifier.value.firstWhere(
        (d) => d.email?.toLowerCase() == email.toLowerCase(),
      );
      return cached;
    } catch (_) {}

    final db = _db;
    if (db == null) return null;
    try {
      final query = await db
          .collection(_collection)
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return DoctorModel.fromMap({...doc.data(), 'id': doc.id});
      }
    } catch (e) {
      debugPrint('[DoctorService] findDoctorByEmail error: $e');
    }
    return null;
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

      final String doctorName = snapshot.data()?['name'] as String? ?? 'Dokter';
      final String? staffId = snapshot.data()?['staff_account_id'] as String?;

      // ----------------------------------------------------------
      // 2. HAPUS PROFIL DOKTER
      // ----------------------------------------------------------

      await ref.delete();
      await SuperadminNotificationService().notifyDokterHapus(doctorName);

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
