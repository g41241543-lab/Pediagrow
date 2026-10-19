import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/konsultasi_session_model.dart';

/// Service untuk mengelola sesi konsultasi di Firestore.
///
/// Koleksi Firestore: `konsultasi_sessions`
///
/// Gunakan service ini untuk:
/// - Membuat sesi baru dari pengguna (setelah submit formulir keluhan)
/// - Mengambil sesi aktif berdasarkan userId atau doctorId
/// - Mengubah status sesi (menunggu → aktif → selesai)
class KonsultasiService {
  KonsultasiService._();
  static final KonsultasiService instance = KonsultasiService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'konsultasi_sessions';

  // ─── PENGGUNA (User POV) ────────────────────────────────────────────────────

  /// Membuat sesi konsultasi baru dari pengguna.
  /// Dipanggil setelah pengguna submit [FormulirKonsultasiPage].
  ///
  /// Mengembalikan ID dokumen yang baru dibuat.
  Future<String> buatSesi({
    String? customSessionId,
    required String childId,
    required String childName,
    required String userId,
    required String parentName,
    required String doctorId,
    required String doctorName,
    String? keluhanAwal,
    double? weightKg,
    double? heightCm,
    String? childPhotoUrl,
    String? childGender,
    String? childAge,
  }) async {
    final ref = (customSessionId != null && customSessionId.isNotEmpty)
        ? _db.collection(_collection).doc(customSessionId)
        : _db.collection(_collection).doc();
    final data = KonsultasiSessionModel(
      id: ref.id,
      childId: childId,
      childName: childName,
      userId: userId,
      parentName: parentName,
      doctorId: doctorId,
      doctorName: doctorName,
      status: KonsultasiStatus.menunggu,
      createdAt: DateTime.now(),
      keluhanAwal: keluhanAwal,
      weightKg: weightKg,
      heightCm: heightCm,
      childPhotoUrl: childPhotoUrl,
      childGender: childGender,
      childAge: childAge,
    );
    await ref.set(data.toMap(), SetOptions(merge: true));
    return ref.id;
  }

  /// Stream sesi aktif/menunggu milik pengguna (userId) untuk anak tertentu.
  Stream<KonsultasiSessionModel?> streamSesiAktifPengguna({
    required String userId,
    String? childId,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['menunggu', 'aktif'])
        .orderBy('createdAt', descending: true)
        .limit(1);

    if (childId != null && childId.isNotEmpty) {
      query = _db
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('childId', isEqualTo: childId)
          .where('status', whereIn: ['menunggu', 'aktif'])
          .orderBy('createdAt', descending: true)
          .limit(1);
    }

    return query.snapshots().map((snap) {
      if (snap.docs.isEmpty) return null;
      return KonsultasiSessionModel.fromDoc(
        snap.docs.first as DocumentSnapshot<Map<String, dynamic>>,
      );
    });
  }

  /// Stream semua sesi (aktif/selesai) milik pengguna untuk riwayat.
  Stream<List<KonsultasiSessionModel>> streamRiwayatPengguna(String userId) {
    return _db
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => KonsultasiSessionModel.fromDoc(
                  d as DocumentSnapshot<Map<String, dynamic>>,
                ),
              )
              .toList(),
        );
  }

  // ─── DOKTER (Doctor POV) ────────────────────────────────────────────────────

  /// Stream sesi yang sedang aktif / menunggu untuk dokter yang login.
  Stream<List<KonsultasiSessionModel>> streamSesiAktifDokter(String doctorId) {
    return _db
        .collection(_collection)
        .where('doctorId', isEqualTo: doctorId)
        .where('status', whereIn: ['menunggu', 'aktif'])
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => KonsultasiSessionModel.fromDoc(
                  d as DocumentSnapshot<Map<String, dynamic>>,
                ),
              )
              .toList(),
        );
  }

  /// Stream semua sesi aktif / menunggu dari Firestore
  Stream<List<KonsultasiSessionModel>> streamSemuaSesiAktif() {
    return _db
        .collection(_collection)
        .where('status', whereIn: ['menunggu', 'aktif'])
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => KonsultasiSessionModel.fromDoc(
                  d as DocumentSnapshot<Map<String, dynamic>>,
                ),
              )
              .toList(),
        );
  }

  /// Stream satu sesi berdasarkan sessionId (untuk ruang chat real-time).
  Stream<KonsultasiSessionModel?> streamSesi(String sessionId) {
    return _db
        .collection(_collection)
        .doc(sessionId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return KonsultasiSessionModel.fromDoc(doc);
    });
  }

  // ─── UPDATE STATUS SESI ─────────────────────────────────────────────────────

  /// Dokter memulai sesi (status: menunggu → aktif).
  Future<void> mulaiSesi(String sessionId) async {
    try {
      await _db.collection(_collection).doc(sessionId).set({
        'status': KonsultasiStatus.aktif.name,
        'startedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[KonsultasiService] Gagal mulaiSesi($sessionId): $e');
    }
  }

  /// Dokter mengakhiri sesi (status: aktif → selesai).
  Future<void> akhiriSesi(String sessionId) async {
    try {
      await _db.collection(_collection).doc(sessionId).set({
        'status': KonsultasiStatus.selesai.name,
        'endedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[KonsultasiService] Gagal akhiriSesi($sessionId): $e');
    }
  }

  /// Ambil data sesi sekali (tanpa stream) berdasarkan sessionId.
  Future<KonsultasiSessionModel?> getSesi(String sessionId) async {
    final doc = await _db.collection(_collection).doc(sessionId).get();
    if (!doc.exists || doc.data() == null) return null;
    return KonsultasiSessionModel.fromDoc(doc);
  }

}
