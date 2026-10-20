import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/child_model.dart';
import '../../../models/doctor_model.dart';
import '../../../core/services/child_service.dart';
import '../../../core/services/doctor_service.dart';
import '../../../core/services/jadwal_dokter_service.dart';
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
    // Bungkus dengan ValueListenableBuilder agar foto dokter
    // otomatis sinkron saat dokter memperbarui foto profilnya.
    return ValueListenableBuilder<List<DoctorModel>>(
      valueListenable: DoctorService().doctorsNotifier,
      builder: (context, doctors, _) {
        // Cari dokter terkini dari DoctorService berdasarkan id atau nama
        final liveDoctor = doctors.firstWhere(
          (d) =>
              d.id == doctor.id ||
              (d.staffAccountId != null &&
                  d.staffAccountId == doctor.staffAccountId) ||
              d.name.trim().toLowerCase() ==
                  doctor.name.trim().toLowerCase(),
          orElse: () => doctor,
        );

        return Scaffold(
          backgroundColor: Colors.white,
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
                          child: const Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Icon(
                              Icons.arrow_back,
                              color: Color(0xFF000000),
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
                              color: const Color(0xFF000000),
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
                        _buildDoctorProfileCard(liveDoctor),

                        const SizedBox(height: 28),

                        Text(
                          'Tempat Praktik',
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF000000),
                          ),
                        ),

                        const SizedBox(height: 14),

                        _buildPracticeLocationsCard(),

                        const SizedBox(height: 28),

                        _buildJadwalPraktikSection(context),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // ---------------------------------------------------------
                // 3. BOTTOM BAR
                // ---------------------------------------------------------
                _buildBottomActionBar(context),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Kartu utama profil dokter dengan foto bundar overlapping di atas
  Widget _buildDoctorProfileCard(DoctorModel liveDoctor) {
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3985E7).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Nama Dokter (Lato Bold 18, #000000, Center)
              Text(
                liveDoctor.name,
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF000000),
                ),
              ),

              const SizedBox(height: 6),

              // Spesialisasi (Lato 14, #64748B, Center)
              Text(
                liveDoctor.specialization,
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 22),

              // Baris Statistik: Pengalaman (digeser ke kiri) & No. STR (di sisi kanan) tanpa garis pemisah
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
                            color: const Color(0xFFEFF6FF),
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
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${liveDoctor.experienceYears} tahun',
                                style: GoogleFonts.lato(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
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
                            color: const Color(0xFFECFDF5),
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
                                  color: const Color(0xFF64748B),
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
                                  color: const Color(0xFF1E293B),
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
              color: Colors.white,
              border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3985E7).withValues(alpha: 0.12),
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

  /// Kartu tempat praktik dengan daftar lokasi & divider horizontal
  Widget _buildPracticeLocationsCard() {
    final places = doctor.daftarTempatPraktik;

    if (places.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3985E7).withValues(alpha: 0.08),
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
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.apartment_rounded,
                size: 20,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Belum ada informasi tempat praktik.',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3985E7).withValues(alpha: 0.08),
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
                    // Ikon Fasyankes / Rumah Sakit dengan sentuhan warna PediaGrow
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
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
                    // Nama Lokasi Praktik
                    Expanded(
                      child: Text(
                        place,
                        style: GoogleFonts.lato(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFBFDBFE),
                ),
            ],
          );
        }),
      ),
    );
  }

  /// Bottom Bar dengan Tombol "Chat Dokter" di sisi kanan
  Widget _buildBottomActionBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFBFDBFE), width: 1.2),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3985E7).withValues(alpha: 0.08),
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

  /// Bagian Jadwal Praktik Dokter Terintegrasi secara Real-Time dengan role dokter
  Widget _buildJadwalPraktikSection(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        JadwalDokterService().jadwalListNotifier,
        JadwalDokterService().cutiListNotifier,
      ]),
      builder: (context, _) {
        final badge = JadwalDokterService().getDoctorBadge(doctor.id);
        final cutis = JadwalDokterService().getCutiDokter(doctor.id);
        final jadwalMingguan = JadwalDokterService().getJadwalDokter(doctor.id);

        // Cek cuti yang sedang aktif hari ini atau akan datang
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final activeCuti = cutis.where((c) => !c.tanggalSelesai.isBefore(today)).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Jadwal Praktik Dokter',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF000000),
                    ),
                  ),
                ),
                _buildAvailabilityBadge(badge),
              ],
            ),
            const SizedBox(height: 14),

            // Peringatan Cuti jika ada
            if (activeCuti.isNotEmpty) ...[
              for (final c in activeCuti) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.beach_access_rounded,
                          color: Color(0xFFD97706),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dokter Sedang Cuti / Berhalangan',
                              style: GoogleFonts.lato(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${c.formattedRentangTanggal} • ${c.alasan}',
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            // Kartu Jadwal Mingguan
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3985E7).withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: List.generate(7, (idx) {
                  final day = idx + 1; // 1: Senin .. 7: Minggu
                  final namaHari = JadwalPraktikModel.getNamaHari(day);
                  final sessions = jadwalMingguan
                      .where((j) => j.hari == day && j.aktif)
                      .toList();
                  final isLast = idx == 6;
                  final isPraktik = sessions.isNotEmpty;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isPraktik
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 65,
                              child: Text(
                                namaHari,
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isPraktik
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: isPraktik
                                  ? Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: sessions.map((s) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: const Color(0xFFBFDBFE),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            '${s.jamMulai} - ${s.jamSelesai} WIB',
                                            style: GoogleFonts.lato(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF1D4ED8),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    )
                                  : Text(
                                      'Libur / Tidak Praktik',
                                      style: GoogleFonts.lato(
                                        fontSize: 12.5,
                                        fontStyle: FontStyle.italic,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFBFDBFE),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvailabilityBadge(DoctorBadgeInfo badge) {
    Color bg;
    Color text;
    Color border;

    switch (badge.type) {
      case DoctorBadgeType.tersediaHariIni:
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF16A34A);
        border = const Color(0xFF86EFAC);
        break;
      case DoctorBadgeType.tersediaBesok:
        bg = const Color(0xFFDBEAFE);
        text = const Color(0xFF2563EB);
        border = const Color(0xFF93C5FD);
        break;
      case DoctorBadgeType.jadwalTerdekat:
        bg = const Color(0xFFF0FDF4);
        text = const Color(0xFF0D9488);
        border = const Color(0xFF99F6E4);
        break;
      case DoctorBadgeType.belumAdaJadwal:
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF64748B);
        border = const Color(0xFFCBD5E1);
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
