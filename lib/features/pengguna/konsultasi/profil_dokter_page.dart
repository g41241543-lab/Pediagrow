import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/child_model.dart';
import '../../../models/doctor_model.dart';
import '../../../core/services/child_service.dart';
import '../../../core/services/doctor_service.dart';
import '../../../core/services/storage_service.dart';
import 'booking_konsultasi_page.dart';

/// Halaman Profil Dokter Anak pada fitur Konsultasi PediaGrow.
///
/// Alur booking: Profil Dokter → [BookingKonsultasiPage] → [StatusBookingPage] → [FormulirKonsultasiPage] → [ChatKonsultasiPage]
class ProfilDokterPage extends StatelessWidget {
  final DoctorModel doctor;
  final ChildModel? child;

  const ProfilDokterPage({super.key, required this.doctor, this.child});

  void _onBookingDokterPressed(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            BookingKonsultasiPage(
              doctor: doctor,
              initialChild: child ?? ChildService().activeChild,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.15, 0.0),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Bungkus dengan ValueListenableBuilder agar foto dokter
    // otomatis sinkron saat dokter memperbarui foto profilnya.
    return ValueListenableBuilder<List<DoctorModel>>(
      valueListenable: DoctorService().doctorsNotifier,
      builder: (context, doctors, _) {
        // Cari dokter terkini dari DoctorService berdasarkan id atau nama
        final liveDoctor = doctors.firstWhere(
          (d) =>
              d.id == doctor.id ||
              d.name.trim().toLowerCase() ==
                  doctor.name.trim().toLowerCase(),
          orElse: () => doctor,
        );

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0B1014) : Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // ---------------------------------------------------------
                // 1. HEADER (56dp)
                // ---------------------------------------------------------
                SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Icon(
                              Icons.arrow_back,
                              color: isDark ? Colors.white : const Color(0xFF000000),
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Profil Dokter Anak',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lato(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ---------------------------------------------------------
                // 2. KONTEN SCROLLABLE PROFIL DOKTER
                // ---------------------------------------------------------
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),

                        // Kartu Utama Dokter
                        _buildDoctorProfileCard(liveDoctor, isDark),

                        const SizedBox(height: 28),

                        // Section Pendidikan
                        Text(
                          'Pendidikan',
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
                          ),
                        ),

                        const SizedBox(height: 14),

                        _buildEducationCard(liveDoctor, isDark),

                        const SizedBox(height: 28),

                        // Section Tempat Praktik
                        Text(
                          'Tempat Praktik',
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
                          ),
                        ),

                        const SizedBox(height: 14),

                        _buildPracticeLocationsCard(liveDoctor, isDark),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // ---------------------------------------------------------
                // 3. BOTTOM BAR
                // ---------------------------------------------------------
                _buildBottomActionBar(context, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Kartu utama profil dokter dengan foto bundar overlapping di atas
  Widget _buildDoctorProfileCard(DoctorModel liveDoctor, bool isDark) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Kontainer kartu putih dengan border dan shadow
        Container(
          margin: const EdgeInsets.only(top: 42),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 52, 16, 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2228) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF2C363D) : const Color(0xFFBFDBFE),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3985E7).withValues(alpha: isDark ? 0.03 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Nama Dokter (Lato Bold 18, Center)
              Text(
                liveDoctor.name,
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
                ),
              ),

              const SizedBox(height: 6),

              // Spesialisasi (Lato 14, Center)
              Text(
                liveDoctor.specialization,
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 22),

              // Baris Statistik: Pengalaman & No. STR
              Row(
                children: [
                  // Sisi kiri: Pengalaman Kerja (rata kiri)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0B1014) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.business_center_outlined,
                            size: 20,
                            color: Color(0xFF3985E7),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pengalaman',
                                style: GoogleFonts.lato(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${liveDoctor.experienceYears} tahun',
                                style: GoogleFonts.lato(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // No. STR (rata kiri di sisi kanan)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.badge_outlined,
                            size: 20,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No. STR',
                                style: GoogleFonts.lato(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                liveDoctor.strNumber ?? '3511201402016252',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.lato(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Avatar Bulat Overlapping di bagian atas kartu
        Positioned(
          top: 0,
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1A2228) : Colors.white,
              border: Border.all(
                color: isDark ? const Color(0xFF2C363D) : const Color(0xFFBFDBFE),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3985E7).withValues(alpha: isDark ? 0.05 : 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(child: _buildAvatarImage(liveDoctor)),
          ),
        ),
      ],
    );
  }

  /// Kartu riwayat pendidikan dengan daftar gelar/institusi & divider horizontal
  Widget _buildEducationCard(DoctorModel liveDoctor, bool isDark) {
    final educations = liveDoctor.daftarPendidikan;

    if (educations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2228) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF2C363D) : const Color(0xFFBFDBFE),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3985E7).withValues(alpha: isDark ? 0.03 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0B1014) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.school_outlined,
                size: 20,
                color: isDark ? const Color(0xFF667781) : const Color(0xFF8696A0),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Belum ada informasi pendidikan.',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : const Color(0xFFBFDBFE),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3985E7).withValues(alpha: isDark ? 0.03 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: List.generate(educations.length, (index) {
          final edu = educations[index];
          final isLast = index == educations.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0B1014) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.school_outlined,
                        size: 20,
                        color: Color(0xFF3985E7),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        edu,
                        style: GoogleFonts.lato(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? const Color(0xFF2C363D) : const Color(0xFFBFDBFE),
                ),
            ],
          );
        }),
      ),
    );
  }

  /// Kartu tempat praktik dengan daftar lokasi & divider horizontal
  Widget _buildPracticeLocationsCard(DoctorModel liveDoctor, bool isDark) {
    final places = liveDoctor.daftarTempatPraktik.isNotEmpty
        ? liveDoctor.daftarTempatPraktik
        : doctor.daftarTempatPraktik;

    if (places.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2228) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF2C363D) : const Color(0xFFBFDBFE),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3985E7).withValues(alpha: isDark ? 0.03 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0B1014) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.apartment_rounded,
                size: 20,
                color: isDark ? const Color(0xFF667781) : const Color(0xFF8696A0),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Belum ada informasi tempat praktik.',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : const Color(0xFFBFDBFE),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3985E7).withValues(alpha: isDark ? 0.03 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: List.generate(places.length, (index) {
          final place = places[index];
          final isLast = index == places.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0B1014) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.local_hospital_outlined,
                        size: 20,
                        color: Color(0xFF3985E7),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        place,
                        style: GoogleFonts.lato(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark ? const Color(0xFF2C363D) : const Color(0xFFBFDBFE),
                ),
            ],
          );
        }),
      ),
    );
  }

  /// Bottom Bar dengan Tombol "Chat Dokter" di sisi kanan
  Widget _buildBottomActionBar(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2C363D) : const Color(0xFFBFDBFE),
            width: 1.2,
          ),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3985E7).withValues(alpha: isDark ? 0.03 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () => _onBookingDokterPressed(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3985E7),
                elevation: 0,
                shadowColor: const Color(0xFF3985E7).withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Booking Konsultasi',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Menampilkan foto dokter dari data live (DoctorService).
  /// Mendukung Base64 Data URI, URL jaringan, dan path asset.
  Widget _buildAvatarImage(DoctorModel liveDoctor) {
    // Prioritaskan avatarUrl (diperbarui saat dokter mengganti foto profil)
    final url = liveDoctor.avatarUrl;
    if (url != null && url.isNotEmpty) {
      return StorageService.buildImageWidget(
        url,
        fit: BoxFit.cover,
        placeholder: _fallbackAvatar(),
        errorWidget: _fallbackAvatar(),
      );
    }
    // Fallback ke assetImagePath jika avatarUrl belum diatur
    if (liveDoctor.assetImagePath != null &&
        liveDoctor.assetImagePath!.isNotEmpty) {
      return StorageService.buildImageWidget(
        liveDoctor.assetImagePath,
        fit: BoxFit.cover,
        placeholder: _fallbackAvatar(),
        errorWidget: _fallbackAvatar(),
      );
    }
    return _fallbackAvatar();
  }

  Widget _fallbackAvatar() {
    return Container(
      color: const Color(0xFFECF6FF),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_rounded,
        size: 42,
        color: Color(0xFF3985E7),
      ),
    );
  }
}
