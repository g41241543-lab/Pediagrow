import 'package:flutter/material.dart';

import '../../core/services/doctor_service.dart';
import '../../core/services/storage_service.dart';
import '../../models/doctor_model.dart';

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

        // Prioritas foto:
        // 1. Foto avatarUrl dokter terkini dari Firestore (real-time dari profil dokter)
        // 2. Asset image dokter terkini
        // 3. Fallback foto dari dokumen riwayat/resume medis
        final livePhoto = (doctor?.avatarUrl != null &&
                doctor!.avatarUrl!.trim().isNotEmpty)
            ? doctor.avatarUrl!.trim()
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
              color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF),
              width: 1.0,
            );

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: shape,
            borderRadius: effectiveBorderRadius,
            color: isDark ? const Color(0xFF0B1014) : const Color(0xFFE9EDEF),
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

  /// Pencocokan cerdas dokter dari daftar real-time
  DoctorModel? _findDoctor(List<DoctorModel> doctors) {
    if (doctors.isEmpty) return null;

    // 1. Cocokkan berdasarkan ID dokter
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

    // 3. Normalisasi pembersihan gelar (dr., drg., Sp.A, Prof., dll.)
    String normalize(String text) {
      return text
          .toLowerCase()
          .replaceAll(
            RegExp(
              r'\b(dr|drg|dokter|sp\.?[a-z]+|m\.?[a-z]+|prof|ph\.?d|subsp\.?[a-z]+)\b',
              caseSensitive: false,
            ),
            '',
          )
          .replaceAll(RegExp(r'[^a-z0-9]'), '')
          .trim();
    }

    final cleanTarget = normalize(rawName);
    if (cleanTarget.isNotEmpty) {
      // 3a. Normalized match persis
      for (final d in doctors) {
        final cleanDoc = normalize(d.name);
        if (cleanDoc == cleanTarget) {
          return d;
        }
      }

      // 3b. Normalized match saling mengandung (contains)
      for (final d in doctors) {
        final cleanDoc = normalize(d.name);
        if (cleanDoc.isNotEmpty &&
            (cleanDoc.contains(cleanTarget) || cleanTarget.contains(cleanDoc))) {
          return d;
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
        color: isDark ? const Color(0xFF3985E7) : const Color(0xFF72A9F4),
      ),
    );
  }
}
