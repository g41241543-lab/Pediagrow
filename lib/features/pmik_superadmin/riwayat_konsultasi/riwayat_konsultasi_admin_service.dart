import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'riwayat_konsultasi_admin_model.dart';

/// Service untuk memuat dan menyinkronkan data Riwayat Konsultasi secara Real-Time
/// dari database Firebase Firestore.
///
/// Mengambil data dari:
/// 1. Tabel/Collection 'riwayat_konsultasi' (atau 'consultation_booking' / 'resume_medis')
/// 2. Data anak dari collection 'children' (nama, jenis kelamin, tanggal lahir)
/// 3. Data dokter dari collection 'doctors' (nama dokter, spesialisasi)
/// 4. Resume medis dari collection 'resume_medis' (keluhan, ringkasan konsultasi)
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

  /// Stream daftar riwayat konsultasi lengkap secara real-time
  Stream<List<RiwayatKonsultasiAdminItem>> streamRiwayatKonsultasi() {
    final db = _db;
    if (db == null) {
      return Stream.value(RiwayatKonsultasiAdminItem.getMockData());
    }

    final controller =
        StreamController<List<RiwayatKonsultasiAdminItem>>.broadcast();

    // Cache lokal untuk menggabungkan stream dari beberapa collections
    Map<String, Map<String, dynamic>> childrenMap = {};
    Map<String, Map<String, dynamic>> resumeMap = {};
    List<Map<String, dynamic>> riwayatDocs = [];
    List<Map<String, dynamic>> bookingDocs = [];
    List<Map<String, dynamic>> resumeDocs = [];

    StreamSubscription? subChildren;
    StreamSubscription? subResumes;
    StreamSubscription? subRiwayat;
    StreamSubscription? subBookings;

    void emitCombined() {
      if (controller.isClosed) return;

      try {
        final List<RiwayatKonsultasiAdminItem> items = [];
        final Set<String> processedKeys = {};

        // 1. Proses dari collection 'riwayat_konsultasi' jika ada
        for (final data in riwayatDocs) {
          final id = data['id']?.toString() ?? '';
          final childName =
              data['child_name'] ?? data['child']?['name'] ?? 'Anak';
          final childId = data['child_id']?.toString() ??
              data['child']?['id']?.toString() ??
              '';
          final doctorName =
              data['doctor_name'] ?? data['doctor']?['name'] ?? 'Dokter';
          final rawDate = data['consultation_date'] ??
              data['tanggal_konsultasi'] ??
              data['created_at'];
          final parsedDate = parseAnyDate(rawDate);
          final formattedDate = data['formatted_date'] ??
              (parsedDate != null
                  ? formatIndonesianDate(parsedDate)
                  : '26 Agustus 2026');

          // Normalisasi status — hanya masukkan yang sudah selesai
          String rawStatus = data['status']?.toString().toLowerCase() ?? 'selesai';
          if (rawStatus.contains('jadwal') || rawStatus.contains('terjadwal') || rawStatus.contains('booking')) {
            // Sesuai ketentuan: riwayat konsultasi hanya menampilkan yang selesai, yang dijadwalkan tidak perlu ditampilkan
            continue;
          }
          final status = 'Selesai';

          // Cari data anak dari collection 'children'
          final childData = childrenMap[childId] ??
              childrenMap[childName.toLowerCase().trim()];
          String gender =
              childData?['gender'] ?? data['child_gender'] ?? 'Perempuan';
          DateTime? birthDate = parseAnyDate(
            childData?['birth_date'] ??
                childData?['tanggal_lahir'] ??
                data['birth_date'],
          );

          // Cari resume medis yang terhubung
          final resumeId = data['resume_medis_id'] ?? data['session_id'];
          final resume = resumeMap[resumeId] ??
              resumeMap[id] ??
              resumeMap[childName.toLowerCase().trim()];

          final complaint = (data['complaint'] ??
                  data['keluhan'] ??
                  resume?['complaint'] ??
                  '')
              .toString();
          final summary = (data['summary'] ??
                  data['ringkasan'] ??
                  resume?['summary'] ??
                  '')
              .toString();

          final itemKey =
              '${childName.toLowerCase()}_${doctorName.toLowerCase()}_$formattedDate';
          if (!processedKeys.contains(itemKey)) {
            processedKeys.add(itemKey);
            items.add(
              RiwayatKonsultasiAdminItem(
                id: id.isNotEmpty ? id : 'riwayat_${items.length}',
                childId: childId,
                childName: childName,
                childGender: gender,
                childBirthDate: birthDate,
                childAge: data['child_age']?.toString(),
                doctorName: doctorName,
                consultationDate: parsedDate,
                formattedDate: formattedDate,
                status: status,
                complaint: complaint,
                summary: summary,
                resumeMedisId: resumeId?.toString(),
                createdAt: parseAnyDate(data['created_at']),
              ),
            );
          }
        }

        // 2. Gabungkan dari consultation_booking & resume_medis jika riwayat_konsultasi kosong / belum lengkap
        if (items.isEmpty) {
          // Ambil dari consultation_booking
          for (final b in bookingDocs) {
            final id = b['id']?.toString() ?? '';
            final childMap = b['child'] is Map ? b['child'] as Map : {};
            final doctorMap = b['doctor'] is Map ? b['doctor'] as Map : {};

            final childName = (childMap['name'] ?? b['child_name'] ?? 'Anak')
                .toString();
            final childId = (childMap['id'] ?? b['child_id'] ?? '').toString();
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
                : '26 Agustus 2026';

            String status = b['status']?.toString() ?? 'Dijadwalkan';
            if (!status.toLowerCase().contains('selesai') &&
                !status.toLowerCase().contains('completed')) {
              // Abaikan booking yang masih dijadwalkan / belum selesai
              continue;
            }
            status = 'Selesai';

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

            final resume = resumeMap[b['sessionId']] ??
                resumeMap[id] ??
                resumeMap[childName.toLowerCase().trim()];

            final complaint = (b['complaint'] ??
                    b['keluhan'] ??
                    resume?['complaint'] ??
                    '')
                .toString();
            final summary = (resume?['summary'] ?? '').toString();

            final itemKey =
                '${childName.toLowerCase()}_${doctorName.toLowerCase()}_$formattedDate';
            if (!processedKeys.contains(itemKey)) {
              processedKeys.add(itemKey);
              items.add(
                RiwayatKonsultasiAdminItem(
                  id: id.isNotEmpty ? id : 'book_${items.length}',
                  childId: childId,
                  childName: childName,
                  childGender: gender,
                  childBirthDate: birthDate,
                  doctorName: doctorName,
                  consultationDate: parsedDate,
                  formattedDate: formattedDate,
                  status: status,
                  complaint: complaint,
                  summary: summary,
                  sessionId: b['sessionId']?.toString(),
                  createdAt: parseAnyDate(b['createdAt']),
                ),
              );
            }
          }

          // Ambil dari resume_medis untuk riwayat yang sudah selesai
          for (final r in resumeDocs) {
            final id = r['id']?.toString() ?? '';
            final childName =
                (r['child_name'] ?? r['childName'] ?? 'Anak').toString();
            final childId =
                (r['child_id'] ?? r['childId'] ?? '').toString();
            final doctorName = (r['doctor_name'] ??
                    r['doctorName'] ??
                    'Dokter Spesialis Anak')
                .toString();

            final rawDate = r['consultation_date'] ??
                r['consultationDate'] ??
                r['created_at'];
            final parsedDate = parseAnyDate(rawDate);
            final formattedDate = parsedDate != null
                ? formatIndonesianDate(parsedDate)
                : (r['consultation_date']?.toString() ?? '26 Agustus 2026');

            String status = r['status']?.toString() ?? 'Selesai';
            if (status.toLowerCase().contains('jadwal')) {
              status = 'Dijadwalkan';
            } else {
              status = 'Selesai';
            }

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

            final itemKey =
                '${childName.toLowerCase()}_${doctorName.toLowerCase()}_$formattedDate';
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
                  doctorName: doctorName,
                  consultationDate: parsedDate,
                  formattedDate: formattedDate,
                  status: status,
                  complaint: complaint,
                  summary: summary,
                  resumeMedisId: id,
                  createdAt: parseAnyDate(r['created_at']),
                ),
              );
            }
          }
        }

        // 3. Jika database kosong (belum ada riwayat di Firestore), gunakan mock data sesuai desain
        if (items.isEmpty) {
          items.addAll(RiwayatKonsultasiAdminItem.getMockData());
        }

        controller.add(items);
      } catch (e) {
        debugPrint('[RiwayatKonsultasiAdminService] emitCombined error: $e');
        controller.add(RiwayatKonsultasiAdminItem.getMockData());
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

      // 2. Resume Medis dari Firestore
      subResumes = db.collection('resume_medis').snapshots().listen((snap) {
        resumeMap.clear();
        resumeDocs = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        for (final doc in snap.docs) {
          final data = doc.data();
          resumeMap[doc.id] = data;
          final sessId = data['session_id']?.toString();
          if (sessId != null && sessId.isNotEmpty) resumeMap[sessId] = data;
          final cName = data['child_name']?.toString().toLowerCase().trim();
          if (cName != null && cName.isNotEmpty) resumeMap[cName] = data;
        }
        emitCombined();
      }, onError: (_) => emitCombined());

      // 3. Riwayat Konsultasi dari Firestore
      subRiwayat = db
          .collection('riwayat_konsultasi')
          .snapshots()
          .listen((snap) {
        riwayatDocs = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        emitCombined();
      }, onError: (_) => emitCombined());

      // 4. Booking Konsultasi dari Firestore
      subBookings = db
          .collection('consultation_booking')
          .snapshots()
          .listen((snap) {
        bookingDocs = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        emitCombined();
      }, onError: (_) => emitCombined());
    } catch (e) {
      debugPrint('[RiwayatKonsultasiAdminService] listener error: $e');
      controller.add(RiwayatKonsultasiAdminItem.getMockData());
    }

    controller.onListen = () {
      emitCombined();
    };

    controller.onCancel = () {
      subChildren?.cancel();
      subResumes?.cancel();
      subRiwayat?.cancel();
      subBookings?.cancel();
      controller.close();
    };

    return controller.stream;
  }
}
