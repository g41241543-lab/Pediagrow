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

  /// Stream daftar resume medis untuk anak tertentu.
  /// Jika di database Firestore belum ada dokumen, akan mengembalikan data default/sample
  /// yang sudah disesuaikan dengan nama anak dan data kelahiran anak.
  Stream<List<ResumeMedisModel>> streamResumeMedis({
    required ChildModel child,
    String? userId,
  }) {
    final collection = _firestore.collection(_collectionName);

    // Filter berdasarkan child_id bila child.id tersedia
    Query<Map<String, dynamic>> query = collection;
    if (child.id.isNotEmpty) {
      query = query.where('child_id', isEqualTo: child.id);
    } else if (userId != null && userId.isNotEmpty) {
      query = query.where('user_id', isEqualTo: userId);
    }

    return query.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        // Fallback ke data template contoh sesuai desain
        return ResumeMedisModel.getSampleData(
          childName: child.name.isNotEmpty ? child.name : 'Arfa Zivano Kayfan',
          childId: child.id,
          userId: userId ?? '',
          bbLahir: (child.birthWeightKg != null && child.birthWeightKg! > 0)
              ? child.birthWeightKg!
              : 2.4,
          tbLahir: (child.birthHeightCm != null && child.birthHeightCm! > 0)
              ? child.birthHeightCm!
              : 44.0,
        );
      }

      return snapshot.docs
          .map((doc) => ResumeMedisModel.fromFirestore(doc))
          .toList();
    }).handleError((error) {
      // Jika terjadi error (misal index Firestore belum dibuat / offline),
      // kembalikan sample data agar UI tetap tampil rapi sesuai desain
      return ResumeMedisModel.getSampleData(
        childName: child.name.isNotEmpty ? child.name : 'Arfa Zivano Kayfan',
        childId: child.id,
        userId: userId ?? '',
        bbLahir: (child.birthWeightKg != null && child.birthWeightKg! > 0)
            ? child.birthWeightKg!
            : 2.4,
        tbLahir: (child.birthHeightCm != null && child.birthHeightCm! > 0)
            ? child.birthHeightCm!
            : 44.0,
      );
    });
  }

  /// Tambah dokumen resume medis ke Firestore
  Future<void> addResumeMedis(ResumeMedisModel resume) async {
    await _firestore.collection(_collectionName).add(resume.toMap());
  }
}
