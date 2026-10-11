import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/child_model.dart';
import '../../models/resume_medis_model.dart';

/// Service untuk membaca dan mengelola data Resume Medis dari Cloud Firestore.
/// Collection: 'resume_medis'
class ResumeMedisService {
  static final ResumeMedisService _instance = ResumeMedisService._internal();
  factory ResumeMedisService() => _instance;
  ResumeMedisService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'resume_medis';

  /// Stream daftar resume medis untuk anak tertentu dari Firestore.
  /// Mengembalikan list kosong apabila belum ada data resume medis untuk anak tersebut.
  Stream<List<ResumeMedisModel>> streamResumeMedis({
    required ChildModel child,
    String? userId,
  }) {
    final collection = _firestore.collection(_collectionName);

    // Filter berdasarkan child_id bila child.id tersedia.
    // Sengaja tidak pakai orderBy di Firestore agar tidak perlu composite index.
    // Sorting dilakukan di sisi Dart setelah data diterima.
    Query<Map<String, dynamic>> query = collection;
    if (child.id.isNotEmpty) {
      query = query.where('child_id', isEqualTo: child.id);
    } else if (userId != null && userId.isNotEmpty) {
      query = query.where('user_id', isEqualTo: userId);
    }

    return query.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return <ResumeMedisModel>[];
      final items = snapshot.docs
          .map((doc) => ResumeMedisModel.fromFirestore(doc))
          .toList();
      // Sort terbaru di atas
      items.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return items;
    }).handleError((_) => <ResumeMedisModel>[]);
  }

  /// Tambah dokumen resume medis ke Firestore
  /// Mengembalikan ID dokumen yang baru dibuat
  Future<String> addResumeMedis(ResumeMedisModel resume) async {
    final ref = await _firestore.collection(_collectionName).add(resume.toMap());
    return ref.id;
  }

  /// Update dokumen resume medis yang sudah ada (untuk fitur Edit oleh Dokter)
  Future<void> updateResumeMedis(String resumeId, Map<String, dynamic> data) async {
    await _firestore.collection(_collectionName).doc(resumeId).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Ambil satu dokumen resume medis berdasarkan ID
  Future<ResumeMedisModel?> getResumeMedisById(String resumeId) async {
    final doc = await _firestore.collection(_collectionName).doc(resumeId).get();
    if (!doc.exists || doc.data() == null) return null;
    return ResumeMedisModel.fromFirestore(doc);
  }

  /// Stream resume medis berdasarkan sessionId (untuk langsung menampilkan
  /// resume setelah dokter menyimpannya dari halaman Buat Resume Medis)
  Stream<ResumeMedisModel?> streamResumeMedisBySessionId(String sessionId) {
    return _firestore
        .collection(_collectionName)
        .where('session_id', isEqualTo: sessionId)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return ResumeMedisModel.fromFirestore(snap.docs.first);
    });
  }
}
