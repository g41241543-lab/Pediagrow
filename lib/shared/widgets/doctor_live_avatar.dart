import 'package:flutter/material.dart';

import '../../core/services/doctor_service.dart';
import '../../core/services/staff_auth_service.dart';
import '../../core/services/storage_service.dart';
import '../../models/doctor_model.dart';
import '../../models/staff_account_model.dart';

/// Widget Avatar Dokter yang terhubung secara Real-Time ke koleksi `doctors` di Firestore.
///
/// Fitur:
/// - Mendengarkan perubahan data profil dokter secara real-time via [DoctorService.doctorsNotifier].
/// - Ketika dokter mengubah foto profil di HP mana pun, avatar di seluruh perangkat
///   pengguna yang mengakses Riwayat Konsultasi akan langsung ter-update otomatis.
/// - Mendukung URL Cloud (https://), Base64 Data URI (data:image/...), file lokal, maupun asset.
/// - Pencocokan cerdas berdasarkan ID dokter maupun nama dokter (toleran terhadap gelar dr., Sp.A, dll.).
/// - Menampilkan placeholder/fallback yang estetik dan adaptif terhadap tema (Mode Terang & Gelap).
class DoctorLiveAvatar extends StatelessWidget {
  final String? doctorId;
  final String doctorName;
  final String? fallbackPhoto;
  final double size;
  final BorderRadius? borderRadius;
  final BoxShape shape;
  final Border? border;

  const DoctorLiveAvatar({
    super.key,
    this.doctorId,
    required this.doctorName,
    this.fallbackPhoto,
    this.size = 52.0,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<List<DoctorModel>>(
      valueListenable: DoctorService().doctorsNotifier,
      builder: (context, doctors, _) {
        final doctor = _findDoctor(doctors) ?? _findDoctor(DoctorService.defaultDoctors);

        // Ambil staff account aktif jika relevan (misal dokter yang login saat ini)
        final currentStaff = StaffAuthService().currentStaff;
        final isMatchingStaff = currentStaff != null &&
            currentStaff.role == StaffRole.dokter &&
            _isStaffMatchingDoctor(currentStaff, doctor);

        // Prioritas foto real-time dokter:
        // 1. Foto avatarUrl dokter terkini dari Firestore (collection `doctors`)
        // 2. Foto avatarPath dokter terkini dari Firestore (collection `staff_accounts`)
        // 3. Asset image dokter terkini
        // 4. Fallback foto dari dokumen riwayat/resume medis
        final livePhoto = (doctor?.avatarUrl != null &&
                doctor!.avatarUrl!.trim().isNotEmpty)
            ? doctor.avatarUrl!.trim()
            : (isMatchingStaff &&
                    currentStaff.avatarPath != null &&
                    currentStaff.avatarPath!.trim().isNotEmpty)
                ? currentStaff.avatarPath!.trim()
                : (doctor?.assetImagePath != null &&
                        doctor!.assetImagePath!.trim().isNotEmpty)
                    ? doctor.assetImagePath!.trim()
                    : (fallbackPhoto != null && fallbackPhoto!.trim().isNotEmpty)
                        ? fallbackPhoto!.trim()
                        : null;

        final effectiveBorderRadius = shape == BoxShape.circle
            ? null
            : (borderRadius ?? BorderRadius.circular(8.0));

        final defaultBorder = border ??
            Border.all(
              color: isDark
                  ? const Color(0xFF2C363D)
                  : const Color(0xFF2B7AE8).withValues(alpha: 0.25),
              width: 1.5,
            );

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: shape,
            borderRadius: effectiveBorderRadius,
            color: isDark ? const Color(0xFF1E2835) : const Color(0xFFEAF5FF),
            border: defaultBorder,
          ),
          clipBehavior: Clip.antiAlias,
          child: StorageService.buildImageWidget(
            livePhoto,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: _buildFallbackIcon(isDark),
            errorWidget: _buildFallbackIcon(isDark),
          ),
        );
      },
    );
  }

  /// Cek apakah current staff yang sedang aktif login cocok dengan target dokter ini
  bool _isStaffMatchingDoctor(StaffAccount staff, DoctorModel? doc) {
    if (staff.id.isNotEmpty) {
      if (doctorId != null && doctorId == staff.id) return true;
      if (doc?.staffAccountId.isNotEmpty == true && doc!.staffAccountId == staff.id) return true;
      if (doc?.id.isNotEmpty == true && doc!.id == staff.id) return true;
    }
    final rawName = doctorName.trim();
    if (rawName.isNotEmpty) {
      final cleanStaff = _normalizeDoctorName(staff.name);
      final cleanTarget = _normalizeDoctorName(rawName);
      if (cleanStaff == cleanTarget) return true;
      if (cleanStaff.isNotEmpty &&
          (cleanStaff.contains(cleanTarget) || cleanTarget.contains(cleanStaff))) {
        return true;
      }
    }
    return false;
  }

  /// Normalisasi pembersihan gelar dokter (dr., Sp.A, Sp. Anak, M.Kes, S.Ked, dll.)
  static String _normalizeDoctorName(String text) {
    return text
        .toLowerCase()
        // Bersihkan gelar dokter, spesialisasi, dan akademik
        .replaceAll(
          RegExp(
            r'\b(dr|drg|dokter|prof|ph\.?d|subsp\.?\s*[a-z]+|sp\.?\s*[a-z]+|m\.?\s*[a-z]+|s\.?\s*tr\.?\s*[a-z]*|s\.?\s*ked)\b',
            caseSensitive: false,
          ),
          '',
        )
        // Bersihkan karakter selain huruf dan angka
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  /// Ekstraksi kata-kata kunci unik (nama panggilan/utama >= 4 karakter)
  static List<String> _extractNameTokens(String text) {
    final clean = text
        .toLowerCase()
        .replaceAll(
          RegExp(
            r'\b(dr|drg|dokter|prof|ph\.?d|subsp|sp|m|kes|ked|rmik|str)\b',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    return clean
        .split(RegExp(r'\s+'))
        .map((s) => s.trim())
        .where((s) => s.length >= 4)
        .toList();
  }

  /// Pencocokan cerdas dokter dari daftar real-time
  DoctorModel? _findDoctor(List<DoctorModel> doctors) {
    if (doctors.isEmpty) return null;

    // 1. Cocokkan berdasarkan ID dokter atau staffAccountId
    if (doctorId != null && doctorId!.trim().isNotEmpty) {
      final targetId = doctorId!.trim();
      for (final d in doctors) {
        if (d.id == targetId || d.staffAccountId == targetId) {
          return d;
        }
      }
    }

    final rawName = doctorName.trim();
    if (rawName.isEmpty) return null;

    // 2. Cocokkan nama persis (case-insensitive)
    final lowerName = rawName.toLowerCase();
    for (final d in doctors) {
      if (d.name.trim().toLowerCase() == lowerName) {
        return d;
      }
    }

    // 3. Normalisasi pembersihan gelar
    final cleanTarget = _normalizeDoctorName(rawName);
    if (cleanTarget.isNotEmpty) {
      // 3a. Normalized match persis
      for (final d in doctors) {
        final cleanDoc = _normalizeDoctorName(d.name);
        if (cleanDoc == cleanTarget) {
          return d;
        }
      }

      // 3b. Normalized match saling mengandung (contains)
      for (final d in doctors) {
        final cleanDoc = _normalizeDoctorName(d.name);
        if (cleanDoc.isNotEmpty &&
            (cleanDoc.contains(cleanTarget) || cleanTarget.contains(cleanDoc))) {
          return d;
        }
      }
    }

    // 4. Token Matching (mencocokkan nama depan/panggilan khas seperti "reny", "zaskia")
    final targetTokens = _extractNameTokens(rawName);
    if (targetTokens.isNotEmpty) {
      for (final d in doctors) {
        final docTokens = _extractNameTokens(d.name);
        for (final tToken in targetTokens) {
          if (docTokens.contains(tToken)) {
            return d;
          }
        }
      }
    }

    return null;
  }

  Widget _buildFallbackIcon(bool isDark) {
    return Center(
      child: Icon(
        Icons.person_rounded,
        size: size * 0.58,
        color: isDark ? const Color(0xFF3985E7) : const Color(0xFF2B7AE8),
      ),
    );
  }
}
