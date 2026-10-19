import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/child_model.dart';
import '../../../models/doctor_model.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/services/child_service.dart';
import '../../../core/services/jadwal_dokter_service.dart';
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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1014) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // -------------------------------------------------------------
            // 1. HEADER (56dp)
            // -------------------------------------------------------------
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

            // -------------------------------------------------------------
            // 2. KONTEN SCROLLABLE PROFIL DOKTER
            // -------------------------------------------------------------
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Kartu Utama Dokter (Avatar Overlapping di bagian atas)
                    _buildDoctorProfileCard(isDark),

                    const SizedBox(height: 28),

                    // Judul Section: Tempat Praktik
                    Text(
                      'Tempat Praktik',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Kartu Daftar Tempat Praktik
                    _buildPracticeLocationsCard(isDark),

                    const SizedBox(height: 28),

                    // Section Jadwal Praktik Dokter Terintegrasi
                    _buildJadwalPraktikSection(context, isDark),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // -------------------------------------------------------------
            // 3. BOTTOM BAR (Tombol Chat Dokter di Kanan)
            // -------------------------------------------------------------
            _buildBottomActionBar(context, isDark),
          ],
        ),
      ),
    );
  }

  /// Kartu utama profil dokter dengan foto bundar overlapping di atas
  Widget _buildDoctorProfileCard(bool isDark) {
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
                doctor.name,
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
                doctor.specialization,
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
                                '${doctor.experienceYears} tahun',
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
                                doctor.strNumber ?? '3511201402016252',
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
            child: ClipOval(child: _buildAvatarImage()),
          ),
        ),
      ],
    );
  }

  /// Kartu tempat praktik dengan daftar lokasi & divider horizontal
  Widget _buildPracticeLocationsCard(bool isDark) {
    final places = doctor.daftarTempatPraktik;

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

  Widget _buildAvatarImage() {
    if (doctor.assetImagePath != null && doctor.assetImagePath!.isNotEmpty) {
      return Image.asset(
        doctor.assetImagePath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallbackAvatar(),
      );
    }
    final url = doctor.avatarUrl;
    if (url != null && url.isNotEmpty) {
      // Path file lokal (dari image_picker di sisi dokter/superadmin)
      if (url.startsWith('/') || url.startsWith('file://')) {
        final file = File(url.replaceFirst('file://', ''));
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallbackAvatar(),
        );
      }
      // URL jaringan
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallbackAvatar(),
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

  /// Bagian Jadwal Praktik Dokter Terintegrasi secara Real-Time dengan role dokter
  Widget _buildJadwalPraktikSection(BuildContext context, bool isDark) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        JadwalDokterService().jadwalListNotifier,
        JadwalDokterService().cutiListNotifier,
        BookingService().bookingsNotifier,
      ]),
      builder: (context, _) {
        final badge = JadwalDokterService().getDoctorBadge(doctor.id);
        final cutis = JadwalDokterService().getCutiDokter(doctor.id);
        final jadwalMingguan = JadwalDokterService().getJadwalDokter(doctor.id);

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final activeCuti = cutis.where((c) => !c.tanggalSelesai.isBefore(today)).toList();

        // Kelompokkan jadwal per hari
        final Map<int, List<JadwalPraktikModel>> perHari = {};
        for (int d = 1; d <= 7; d++) {
          perHari[d] = jadwalMingguan.where((j) => j.hari == d && j.aktif).toList();
        }

        // Hari kerja aktif saat ini (weekday 1-7 → Senin-Minggu)
        final todayWeekday = now.weekday;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Header section ----
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Jadwal Praktik',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
                  ),
                ),
                _buildAvailabilityBadge(badge, isDark),
              ],
            ),
            const SizedBox(height: 14),

            // ---- Banner Cuti aktif ----
            if (activeCuti.isNotEmpty)
              for (final c in activeCuti)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF451A03).withValues(alpha: 0.35)
                        : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF92400E) : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.beach_access_rounded,
                        color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dokter Sedang Cuti / Berhalangan',
                              style: GoogleFonts.lato(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFFFDE68A)
                                    : const Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${c.formattedRentangTanggal} • ${c.alasan}',
                              style: GoogleFonts.lato(
                                fontSize: 11.5,
                                color: isDark
                                    ? const Color(0xFFFCD34D)
                                    : const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

            // ---- Kartu Jadwal Mingguan — 2 kolom grid ----
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2228) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2C363D)
                      : const Color(0xFFBFDBFE),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3985E7)
                        .withValues(alpha: isDark ? 0.03 : 0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Baris atas: Sen - Rab
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [1, 2, 3].map((day) {
                      return Expanded(
                        child: _buildHariCell(
                          day: day,
                          sessions: perHari[day] ?? [],
                          isToday: day == todayWeekday,
                          isDark: isDark,
                          isLast: day == 3,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 2),
                  Divider(
                    height: 16,
                    thickness: 0.8,
                    color: isDark
                        ? const Color(0xFF2C363D)
                        : const Color(0xFFE9EDEF),
                  ),
                  // Baris bawah: Kam - Sab
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [4, 5, 6].map((day) {
                      return Expanded(
                        child: _buildHariCell(
                          day: day,
                          sessions: perHari[day] ?? [],
                          isToday: day == todayWeekday,
                          isDark: isDark,
                          isLast: day == 6,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 2),
                  Divider(
                    height: 16,
                    thickness: 0.8,
                    color: isDark
                        ? const Color(0xFF2C363D)
                        : const Color(0xFFE9EDEF),
                  ),
                  // Baris Minggu full-width
                  _buildHariCellFull(
                    day: 7,
                    sessions: perHari[7] ?? [],
                    isToday: 7 == todayWeekday,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Cell jadwal per hari dalam grid 3-kolom
  Widget _buildHariCell({
    required int day,
    required List<JadwalPraktikModel> sessions,
    required bool isToday,
    required bool isDark,
    required bool isLast,
  }) {
    final namaHari = JadwalPraktikModel.getNamaHari(day);
    final short = namaHari.length > 3 ? namaHari.substring(0, 3) : namaHari;
    final hasSesi = sessions.isNotEmpty;

    // Warna aksen hari ini
    final Color dayLabelColor = isToday
        ? const Color(0xFF3985E7)
        : hasSesi
            ? (isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228))
            : (isDark ? const Color(0xFF4B5563) : const Color(0xFFADB5BD));

    return Padding(
      padding: EdgeInsets.only(right: isLast ? 0 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label hari + dot status
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasSesi
                      ? const Color(0xFF10B981)
                      : (isDark
                          ? const Color(0xFF374151)
                          : const Color(0xFFD1D5DB)),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                short,
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w700,
                  color: dayLabelColor,
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: 3),
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF3985E7),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          // Pill waktu atau label libur
          if (!hasSesi)
            Text(
              'Libur',
              style: GoogleFonts.lato(
                fontSize: 10.5,
                fontStyle: FontStyle.italic,
                color: isDark
                    ? const Color(0xFF4B5563)
                    : const Color(0xFFADB5BD),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sessions.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F2744)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF1E3A8A)
                            : const Color(0xFFBFDBFE),
                        width: 0.8,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${s.jamMulai}–${s.jamSelesai}',
                        style: GoogleFonts.lato(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  /// Cell jadwal full-width khusus hari Minggu
  Widget _buildHariCellFull({
    required int day,
    required List<JadwalPraktikModel> sessions,
    required bool isToday,
    required bool isDark,
  }) {
    final namaHari = JadwalPraktikModel.getNamaHari(day);
    final hasSesi = sessions.isNotEmpty;

    final Color dayLabelColor = isToday
        ? const Color(0xFF3985E7)
        : hasSesi
            ? (isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228))
            : (isDark ? const Color(0xFF4B5563) : const Color(0xFFADB5BD));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasSesi
                    ? const Color(0xFF10B981)
                    : (isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFD1D5DB)),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              namaHari,
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w700,
                color: dayLabelColor,
              ),
            ),
            if (isToday) ...[
              const SizedBox(width: 4),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF3985E7),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(width: 12),
        if (!hasSesi)
          Text(
            'Libur / Tidak Praktik',
            style: GoogleFonts.lato(
              fontSize: 10.5,
              fontStyle: FontStyle.italic,
              color: isDark ? const Color(0xFF4B5563) : const Color(0xFFADB5BD),
            ),
          )
        else
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: sessions.map((s) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F2744)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF1E3A8A)
                          : const Color(0xFFBFDBFE),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '${s.jamMulai}–${s.jamSelesai}',
                    style: GoogleFonts.lato(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF93C5FD)
                          : const Color(0xFF1D4ED8),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildAvailabilityBadge(DoctorBadgeInfo badge, bool isDark) {
    Color bg;
    Color text;
    Color border;

    switch (badge.type) {
      case DoctorBadgeType.tersediaHariIni:
        bg = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFDCFCE7);
        text = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
        border = isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC);
        break;
      case DoctorBadgeType.tersediaBesok:
        bg = isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.4) : const Color(0xFFDBEAFE);
        text = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
        border = isDark ? const Color(0xFF2563EB) : const Color(0xFF93C5FD);
        break;
      case DoctorBadgeType.jadwalTerdekat:
        bg = isDark ? const Color(0xFF134E4A).withValues(alpha: 0.4) : const Color(0xFFF0FDF4);
        text = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488);
        border = isDark ? const Color(0xFF0D9488) : const Color(0xFF99F6E4);
        break;
      case DoctorBadgeType.belumAdaJadwal:
        bg = isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF);
        text = isDark ? const Color(0xFFD1D7DB) : const Color(0xFF667781);
        border = isDark ? const Color(0xFF2C363D) : const Color(0xFFD1D7DB);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Text(
        badge.label,
        style: GoogleFonts.lato(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }
}
