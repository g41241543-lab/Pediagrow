import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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

  // Fast In-Memory Cache untuk akses instan (0ms delay)
  final Map<String, List<ResumeMedisModel>> _cache = {};

  /// Ambil data cache jika sudah pernah dimuat sebelumnya
  List<ResumeMedisModel>? getCached(String? childId, [String? childName]) {
    if (childId != null && childId.isNotEmpty && _cache.containsKey(childId)) {
      return _cache[childId];
    }
    if (childName != null && childName.isNotEmpty && _cache.containsKey(childName)) {
      return _cache[childName];
    }
    return null;
  }

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
      if (snapshot.docs.isEmpty) {
        if (child.id.isNotEmpty) _cache[child.id] = [];
        if (child.name.isNotEmpty) _cache[child.name] = [];
        return <ResumeMedisModel>[];
      }
      final items = snapshot.docs
          .map((doc) => ResumeMedisModel.fromFirestore(doc))
          .toList();

      // Sort terbaru di atas
      items.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      // Update cache
      if (child.id.isNotEmpty) _cache[child.id] = items;
      if (child.name.isNotEmpty) _cache[child.name] = items;

      return items;
    }).handleError((err) {
      debugPrint('[ResumeMedisService] stream error: $err');
      return getCached(child.id, child.name) ?? <ResumeMedisModel>[];
    });
  }

  /// Stream SEMUA resume medis (tanpa filter anak/user) — digunakan oleh admin.
  /// Data diurutkan berdasarkan 'created_at' (terbaru dulu).
  /// Jika Firestore kosong atau error, akan mengembalikan sample data gabungan.
  Stream<List<ResumeMedisModel>> streamAllResumeMedis() {
    final collection = _firestore.collection(_collectionName);
    return collection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _buildAdminSampleData();
      }
      return snapshot.docs
          .map((doc) => ResumeMedisModel.fromFirestore(doc))
          .toList();
    }).handleError((_) {
      // Jika index belum dibuat atau offline, fallback ke sample data
      return _buildAdminSampleData();
    });
  }

  /// Sample data gabungan untuk tampilan admin saat Firestore belum ada data.
  List<ResumeMedisModel> _buildAdminSampleData() {
    final List<ResumeMedisModel> combined = [];
    final names = [
      ('Arfa Zivano Kayfan', 2.4, 44.0),
      ('Kaia Anastasya', 3.1, 48.0),
      ('Devaro Ramadhan', 2.9, 46.0),
      ('Amara Adiratna', 3.0, 47.0),
    ];
    for (final entry in names) {
      combined.addAll(ResumeMedisModel.getSampleData(
        childName: entry.$1,
        bbLahir: entry.$2,
        tbLahir: entry.$3,
      ));
    }
    return combined;
  }

  /// Tambah dokumen resume medis ke Firestore
  /// Mengembalikan ID dokumen yang baru dibuat
  Future<String> addResumeMedis(ResumeMedisModel resume) async {
    final ref = await _firestore.collection(_collectionName).add(resume.toMap());
    final created = ResumeMedisModel(
      id: ref.id,
      childId: resume.childId,
      userId: resume.userId,
      doctorName: resume.doctorName,
      doctorSpecialization: resume.doctorSpecialization,
      doctorPhoto: resume.doctorPhoto,
      childName: resume.childName,
      childAgeAtConsultation: resume.childAgeAtConsultation,
      consultationDate: resume.consultationDate,
      consultationTime: resume.consultationTime,
      bbLahir: resume.bbLahir,
      bbSaatIni: resume.bbSaatIni,
      tbLahir: resume.tbLahir,
      tbSaatIni: resume.tbSaatIni,
      complaint: resume.complaint,
      complaintShort: resume.complaintShort,
      doctorAssessment: resume.doctorAssessment,
      summary: resume.summary,
      recommendations: resume.recommendations,
      prescription: resume.prescription,
      status: resume.status,
      sessionId: resume.sessionId,
      createdAt: resume.createdAt ?? DateTime.now(),
    );

    // Update cache langsung
    if (resume.childId.isNotEmpty) {
      final list = _cache[resume.childId] ?? [];
      _cache[resume.childId] = [created, ...list];
    }
    if (resume.childName.isNotEmpty) {
      final list = _cache[resume.childName] ?? [];
      _cache[resume.childName] = [created, ...list];
    }

    return ref.id;
  }

  /// Simpan atau perbarui resume medis berdasarkan sessionId.
  /// Jika sudah ada dokumen dengan sessionId yang sama, lakukan update agar tidak terjadi duplikasi.
  /// Jika belum ada, buat dokumen baru.
  Future<String> saveOrUpdateResumeMedis(ResumeMedisModel resume) async {
    final sessId = resume.sessionId;
    if (sessId != null && sessId.isNotEmpty) {
      try {
        final querySnap = await _firestore
            .collection(_collectionName)
            .where('session_id', isEqualTo: sessId)
            .limit(1)
            .get();

        if (querySnap.docs.isNotEmpty) {
          final docId = querySnap.docs.first.id;
          final updateData = resume.toMap();
          updateData['updated_at'] = FieldValue.serverTimestamp();
          await _firestore.collection(_collectionName).doc(docId).set(
                updateData,
                SetOptions(merge: true),
              );

          final updatedModel = ResumeMedisModel(
            id: docId,
            childId: resume.childId,
            userId: resume.userId,
            doctorId: resume.doctorId,
            doctorName: resume.doctorName,
            doctorSpecialization: resume.doctorSpecialization,
            doctorPhoto: resume.doctorPhoto,
            childName: resume.childName,
            childAgeAtConsultation: resume.childAgeAtConsultation,
            consultationDate: resume.consultationDate,
            consultationTime: resume.consultationTime,
            bbLahir: resume.bbLahir,
            bbSaatIni: resume.bbSaatIni,
            tbLahir: resume.tbLahir,
            tbSaatIni: resume.tbSaatIni,
            complaint: resume.complaint,
            complaintShort: resume.complaintShort,
            doctorAssessment: resume.doctorAssessment,
            summary: resume.summary,
            recommendations: resume.recommendations,
            prescription: resume.prescription,
            status: resume.status,
            sessionId: resume.sessionId,
            createdAt: resume.createdAt ?? DateTime.now(),
          );

          // Update cache
          for (final key in _cache.keys) {
            final list = _cache[key];
            if (list != null) {
              final idx = list.indexWhere((r) => r.id == docId || r.sessionId == sessId);
              if (idx != -1) {
                list[idx] = updatedModel;
              } else {
                list.insert(0, updatedModel);
              }
            }
          }

          return docId;
        }
      } catch (e) {
        debugPrint('[ResumeMedisService] Error checking existing session_id: $e');
      }
    }

    return addResumeMedis(resume);
  }

  /// Update dokumen resume medis yang sudah ada (untuk fitur Edit oleh Dokter)
  Future<void> updateResumeMedis(String resumeId, Map<String, dynamic> data) async {
    await _firestore.collection(_collectionName).doc(resumeId).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });

    // Update di cache lokal jika ada
    for (final key in _cache.keys) {
      final list = _cache[key];
      if (list != null) {
        final idx = list.indexWhere((r) => r.id == resumeId);
        if (idx != -1) {
          final old = list[idx];
          list[idx] = ResumeMedisModel(
            id: old.id,
            childId: old.childId,
            userId: old.userId,
            doctorName: old.doctorName,
            doctorSpecialization: old.doctorSpecialization,
            doctorPhoto: old.doctorPhoto,
            childName: old.childName,
            childAgeAtConsultation: old.childAgeAtConsultation,
            consultationDate: old.consultationDate,
            consultationTime: old.consultationTime,
            bbLahir: old.bbLahir,
            bbSaatIni: old.bbSaatIni,
            tbLahir: old.tbLahir,
            tbSaatIni: old.tbSaatIni,
            complaint: old.complaint,
            complaintShort: old.complaintShort,
            doctorAssessment: data['doctor_assessment'] ?? old.doctorAssessment,
            summary: data['summary'] ?? old.summary,
            recommendations: (data['recommendations'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                old.recommendations,
            prescription: data['prescription'] ?? old.prescription,
            status: old.status,
            sessionId: old.sessionId,
            createdAt: old.createdAt,
          );
        }
      }
    }
  }

  /// Hapus dokumen resume medis dari Firestore
  Future<void> deleteResumeMedis(String resumeId) async {
    await _firestore.collection(_collectionName).doc(resumeId).delete();

    // Hapus dari cache lokal jika ada
    for (final key in _cache.keys) {
      _cache[key]?.removeWhere((r) => r.id == resumeId);
    }
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
