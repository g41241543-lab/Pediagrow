import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'riwayat_konsultasi_admin_model.dart';

/// Service untuk memuat dan menyinkronkan data Riwayat Konsultasi secara Real-Time
/// dari database Firebase Firestore untuk PMIK Superadmin dan Dokter.
///
/// Sumber data yang digabungkan secara real-time:
/// 1. Collection 'resume_medis'      — sumber UTAMA (konsultasi yang sudah selesai)
/// 2. Collection 'consultation_booking' — sumber pendukung (booking berstatus 'Selesai')
/// 3. Collection 'riwayat_konsultasi'   — sumber legacy jika ada
/// 4. Collection 'children'             — untuk data anak (jenis kelamin, tanggal lahir)
///
/// CATATAN: BookingService otomatis menghapus booking dari 'consultation_booking'
/// setelah expired, sehingga 'resume_medis' adalah sumber utama riwayat yang sudah selesai.
class RiwayatKonsultasiAdminService {
  static final RiwayatKonsultasiAdminService _instance =
      RiwayatKonsultasiAdminService._internal();
  factory RiwayatKonsultasiAdminService() => _instance;
  RiwayatKonsultasiAdminService._internal();

  FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Stream daftar riwayat konsultasi lengkap secara real-time.
  /// Menggabungkan data dari resume_medis, consultation_booking, dan riwayat_konsultasi.
  Stream<List<RiwayatKonsultasiAdminItem>> streamRiwayatKonsultasi() {
    final db = _db;
    if (db == null) {
      return Stream.value([]);
    }

    final controller =
        StreamController<List<RiwayatKonsultasiAdminItem>>.broadcast();

    // Cache lokal untuk menggabungkan stream dari beberapa collections
    Map<String, Map<String, dynamic>> childrenMap = {};
    List<Map<String, dynamic>> resumeDocs = [];
    List<Map<String, dynamic>> bookingDocs = [];
    List<Map<String, dynamic>> riwayatDocs = [];

    StreamSubscription? subChildren;
    StreamSubscription? subResumes;
    StreamSubscription? subBookings;
    StreamSubscription? subRiwayat;

    void emitCombined() {
      if (controller.isClosed) return;

      try {
        final List<RiwayatKonsultasiAdminItem> items = [];
        final Set<String> processedKeys = {};

        // ──────────────────────────────────────────────────────────────────────
        // SUMBER 1 (UTAMA): resume_medis — ini adalah sumber paling andal karena
        // consultation_booking dihapus otomatis setelah sesi berakhir.
        // ──────────────────────────────────────────────────────────────────────
        for (final r in resumeDocs) {
          final id = r['id']?.toString() ?? '';
          final childName =
              (r['child_name'] ?? r['childName'] ?? 'Anak').toString();
          final childId =
              (r['child_id'] ?? r['childId'] ?? '').toString();
          final doctorId =
              (r['doctor_id'] ?? r['doctorId'] ?? '').toString();
          final doctorName = (r['doctor_name'] ??
                  r['doctorName'] ??
                  'Dokter Spesialis Anak')
              .toString();

          // Normalisasi status: hanya tampilkan yang selesai
          final rawStatus = (r['status'] ?? 'Selesai').toString().toLowerCase();
          if (rawStatus.contains('jadwal') ||
              rawStatus.contains('terjadwal') ||
              rawStatus.contains('booking') ||
              rawStatus.contains('dibatalkan') ||
              rawStatus.contains('cancel')) {
            continue;
          }

          final rawDate = r['consultation_date'] ??
              r['consultationDate'] ??
              r['created_at'];
          final parsedDate = parseAnyDate(rawDate);
          final formattedDate = parsedDate != null
              ? formatIndonesianDate(parsedDate)
              : (r['consultation_date']?.toString() ??
                  r['consultationDate']?.toString() ??
                  '');

          final childData = childrenMap[childId] ??
              childrenMap[childName.toLowerCase().trim()];
          String gender =
              childData?['gender'] ?? r['child_gender'] ?? 'Perempuan';
          DateTime? birthDate = parseAnyDate(
            childData?['birth_date'] ?? childData?['tanggal_lahir'],
          );

          final complaint =
              (r['complaint'] ?? r['complaint_short'] ?? '').toString();
          final summary = (r['summary'] ?? '').toString();
          final sessionId = r['session_id']?.toString() ?? r['sessionId']?.toString();

          final itemKey =
              '${childName.toLowerCase().trim()}_${doctorName.toLowerCase().trim()}_$formattedDate';
          if (!processedKeys.contains(itemKey)) {
            processedKeys.add(itemKey);
            items.add(
              RiwayatKonsultasiAdminItem(
                id: id.isNotEmpty ? id : 'resume_${items.length}',
                childId: childId,
                childName: childName,
                childGender: gender,
                childBirthDate: birthDate,
                childAge: r['child_age_at_consultation']?.toString(),
                doctorId: doctorId,
                doctorName: doctorName,
                consultationDate: parsedDate,
                formattedDate: formattedDate,
                status: 'Selesai',
                complaint: complaint,
                summary: summary,
                resumeMedisId: id,
                sessionId: sessionId,
                createdAt: parseAnyDate(r['created_at']),
              ),
            );
          }
        }

        // ──────────────────────────────────────────────────────────────────────
        // SUMBER 2: consultation_booking — booking yang masih berstatus 'Selesai'
        // (sebelum dihapus otomatis oleh BookingService)
        // ──────────────────────────────────────────────────────────────────────
        for (final b in bookingDocs) {
          final rawStatus = b['status']?.toString() ?? '';
          if (!rawStatus.toLowerCase().contains('selesai') &&
              !rawStatus.toLowerCase().contains('completed')) {
            continue;
          }

          final id = b['id']?.toString() ?? '';
          final childMap = b['child'] is Map ? b['child'] as Map : {};
          final doctorMap = b['doctor'] is Map ? b['doctor'] as Map : {};

          final childName =
              (childMap['name'] ?? b['child_name'] ?? 'Anak').toString();
          final childId =
              (childMap['id'] ?? b['child_id'] ?? '').toString();
          final doctorId =
              (doctorMap['id'] ?? b['doctor_id'] ?? '').toString();
          final doctorName = (doctorMap['name'] ??
                  b['doctor_name'] ??
                  'Dokter Spesialis Anak')
              .toString();

          final rawDate = b['scheduledDate'] ??
              b['scheduled_date'] ??
              b['bookingDate'] ??
              b['createdAt'];
          final parsedDate = parseAnyDate(rawDate);
          final formattedDate = parsedDate != null
              ? formatIndonesianDate(parsedDate)
              : '';

          final childData = childrenMap[childId] ??
              childrenMap[childName.toLowerCase().trim()];
          String gender = childData?['gender'] ??
              childMap['gender'] ??
              b['child_gender'] ??
              'Perempuan';
          DateTime? birthDate = parseAnyDate(
            childData?['birth_date'] ??
                childData?['tanggal_lahir'] ??
                childMap['birthDate'],
          );

          final complaint =
              (b['complaint'] ?? b['keluhan'] ?? '').toString();

          final itemKey =
              '${childName.toLowerCase().trim()}_${doctorName.toLowerCase().trim()}_$formattedDate';
          if (!processedKeys.contains(itemKey)) {
            processedKeys.add(itemKey);
            items.add(
              RiwayatKonsultasiAdminItem(
                id: id.isNotEmpty ? id : 'book_${items.length}',
                childId: childId,
                childName: childName,
                childGender: gender,
                childBirthDate: birthDate,
                doctorId: doctorId,
                doctorName: doctorName,
                consultationDate: parsedDate,
                formattedDate: formattedDate,
                status: 'Selesai',
                complaint: complaint,
                sessionId: b['sessionId']?.toString(),
                createdAt: parseAnyDate(b['createdAt']),
              ),
            );
          }
        }

        // ──────────────────────────────────────────────────────────────────────
        // SUMBER 3 (LEGACY): riwayat_konsultasi
        // ──────────────────────────────────────────────────────────────────────
        for (final data in riwayatDocs) {
          final rawStatus =
              data['status']?.toString().toLowerCase() ?? 'selesai';
          if (rawStatus.contains('jadwal') ||
              rawStatus.contains('terjadwal') ||
              rawStatus.contains('booking')) {
            continue;
          }

          final id = data['id']?.toString() ?? '';
          final childName =
              data['child_name'] ?? data['child']?['name'] ?? 'Anak';
          final childId = data['child_id']?.toString() ??
              data['child']?['id']?.toString() ??
              '';
          final doctorId = data['doctor_id']?.toString() ??
              data['doctor']?['id']?.toString() ??
              '';
          final doctorName =
              data['doctor_name'] ?? data['doctor']?['name'] ?? 'Dokter';
          final rawDate = data['consultation_date'] ??
              data['tanggal_konsultasi'] ??
              data['created_at'];
          final parsedDate = parseAnyDate(rawDate);
          final formattedDate = data['formatted_date'] ??
              (parsedDate != null ? formatIndonesianDate(parsedDate) : '');

          final childData = childrenMap[childId] ??
              childrenMap[childName.toString().toLowerCase().trim()];
          String gender =
              childData?['gender'] ?? data['child_gender'] ?? 'Perempuan';
          DateTime? birthDate = parseAnyDate(
            childData?['birth_date'] ??
                childData?['tanggal_lahir'] ??
                data['birth_date'],
          );

          final complaint =
              (data['complaint'] ?? data['keluhan'] ?? '').toString();
          final summary = (data['summary'] ?? data['ringkasan'] ?? '').toString();

          final itemKey =
              '${childName.toString().toLowerCase().trim()}_${doctorName.toString().toLowerCase().trim()}_$formattedDate';
          if (!processedKeys.contains(itemKey)) {
            processedKeys.add(itemKey);
            items.add(
              RiwayatKonsultasiAdminItem(
                id: id.isNotEmpty ? id : 'riwayat_${items.length}',
                childId: childId,
                childName: childName.toString(),
                childGender: gender,
                childBirthDate: birthDate,
                childAge: data['child_age']?.toString(),
                doctorId: doctorId,
                doctorName: doctorName.toString(),
                consultationDate: parsedDate,
                formattedDate: formattedDate,
                status: 'Selesai',
                complaint: complaint,
                summary: summary,
                resumeMedisId: data['resume_medis_id']?.toString(),
                createdAt: parseAnyDate(data['created_at']),
              ),
            );
          }
        }

        // Urutkan terbaru di atas
        items.sort((a, b) {
          final aDate = a.consultationDate ?? a.createdAt ?? DateTime(2000);
          final bDate = b.consultationDate ?? b.createdAt ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });

        controller.add(items);
      } catch (e) {
        debugPrint('[RiwayatKonsultasiAdminService] emitCombined error: $e');
        controller.add([]);
      }
    }

    // ─── Listeners ke Firestore Collections ───
    try {
      // 1. Data Anak dari Firestore
      subChildren = db.collection('children').snapshots().listen((snap) {
        childrenMap.clear();
        for (final doc in snap.docs) {
          final data = doc.data();
          childrenMap[doc.id] = data;
          final name = data['name']?.toString().toLowerCase().trim();
          if (name != null && name.isNotEmpty) {
            childrenMap[name] = data;
          }
        }
        emitCombined();
      }, onError: (_) => emitCombined());

      // 2. Resume Medis — sumber UTAMA riwayat konsultasi yang sudah selesai
      subResumes = db.collection('resume_medis').snapshots().listen((snap) {
        resumeDocs = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        emitCombined();
      }, onError: (_) => emitCombined());

      // 3. Consultation Booking — sumber pendukung (booking berstatus Selesai)
      subBookings = db
          .collection('consultation_booking')
          .snapshots()
          .listen((snap) {
        bookingDocs = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        emitCombined();
      }, onError: (_) => emitCombined());

      // 4. Riwayat Konsultasi (legacy) — jika collection ini ada
      subRiwayat = db
          .collection('riwayat_konsultasi')
          .snapshots()
          .listen((snap) {
        riwayatDocs = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        emitCombined();
      }, onError: (_) => emitCombined());
    } catch (e) {
      debugPrint('[RiwayatKonsultasiAdminService] listener error: $e');
      controller.add([]);
    }

    controller.onListen = () {
      emitCombined();
    };

    controller.onCancel = () {
      subChildren?.cancel();
      subResumes?.cancel();
      subBookings?.cancel();
      subRiwayat?.cancel();
      controller.close();
    };

    return controller.stream;
  }
}
