import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/child_model.dart';
import '../../../models/doctor_model.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/services/child_service.dart';
import '../../../core/services/doctor_service.dart';
import '../../../core/services/jadwal_dokter_service.dart';
import '../../../core/services/storage_service.dart';
import 'booking_konsultasi_page.dart';

/// Halaman Profil Dokter Anak pada fitur Konsultasi PediaGrow.
///
/// Alur booking: Profil Dokter -> [BookingKonsultasiPage] -> [StatusBookingPage] -> [FormulirKonsultasiPage] -> [ChatKonsultasiPage]
class ProfilDokterPage extends StatelessWidget {
  final DoctorModel doctor;
  final ChildModel? child;

  const ProfilDokterPage({super.key, required this.doctor, this.child});

  void _onBookingDokterPressed(BuildContext context, DoctorModel liveDoctor) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            BookingKonsultasiPage(
              doctor: liveDoctor,
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
    return ValueListenableBuilder<List<DoctorModel>>(
      valueListenable: DoctorService().doctorsNotifier,
      builder: (context, doctors, _) {
        final liveDoctor = doctors.firstWhere(
          (d) =>
              d.id == doctor.id ||
              (d.staffAccountId.isNotEmpty &&
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
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
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
                        _buildPracticeLocationsCard(liveDoctor),
                        const SizedBox(height: 28),
                        _buildJadwalPraktikSection(context, liveDoctor),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                _buildBottomActionBar(context, liveDoctor),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDoctorProfileCard(DoctorModel liveDoctor) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
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
              Text(
                liveDoctor.specialization,
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: const Color(0xFF667781),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
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
                          child: const Icon(Icons.business_center_outlined, size: 20, color: Color(0xFF3985E7)),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pengalaman', style: GoogleFonts.lato(fontSize: 12, color: const Color(0xFF667781))),
                              const SizedBox(height: 2),
                              Text(
                                '${liveDoctor.experienceYears} tahun',
                                style: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A2228)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.badge_outlined, size: 20, color: Color(0xFF10B981)),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('No. STR', style: GoogleFonts.lato(fontSize: 12, color: const Color(0xFF667781))),
                              const SizedBox(height: 2),
                              Text(
                                liveDoctor.strNumber ?? '3511201402016252',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A2228)),
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

  Widget _buildPracticeLocationsCard(DoctorModel liveDoctor) {
    final places = liveDoctor.daftarTempatPraktik;

    if (places.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
          boxShadow: [BoxShadow(color: const Color(0xFF3985E7).withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: const Icon(Icons.apartment_rounded, size: 20, color: Color(0xFF8696A0)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text('Belum ada informasi tempat praktik.', style: GoogleFonts.lato(fontSize: 14, color: const Color(0xFF667781)))),
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
        boxShadow: [BoxShadow(color: const Color(0xFF3985E7).withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: List.generate(places.length, (index) {
          final place = places[index];
          final isLast = index == places.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.local_hospital_outlined, size: 20, color: Color(0xFF3985E7)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Text(place, style: GoogleFonts.lato(fontSize: 14.5, fontWeight: FontWeight.w500, color: const Color(0xFF1A2228)))),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 1, thickness: 1, color: Color(0xFFBFDBFE)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context, DoctorModel liveDoctor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFBFDBFE), width: 1.2)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [BoxShadow(color: const Color(0xFF3985E7).withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () => _onBookingDokterPressed(context, liveDoctor),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3985E7),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Booking Konsultasi', style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarImage(DoctorModel liveDoctor) {
    final url = liveDoctor.avatarUrl;
    if (url != null && url.isNotEmpty) {
      return StorageService.buildImageWidget(url, fit: BoxFit.cover, placeholder: _fallbackAvatar(), errorWidget: _fallbackAvatar());
    }
    if (liveDoctor.assetImagePath != null && liveDoctor.assetImagePath!.isNotEmpty) {
      return StorageService.buildImageWidget(liveDoctor.assetImagePath, fit: BoxFit.cover, placeholder: _fallbackAvatar(), errorWidget: _fallbackAvatar());
    }
    return _fallbackAvatar();
  }

  Widget _fallbackAvatar() {
    return Container(
      color: const Color(0xFFECF6FF),
      alignment: Alignment.center,
      child: const Icon(Icons.person_rounded, size: 42, color: Color(0xFF3985E7)),
    );
  }

  // =========================================================================
  // JADWAL PRAKTIK - Halodoc/Alodokter style: list per hari + chip jam
  // =========================================================================

  Widget _buildJadwalPraktikSection(BuildContext context, DoctorModel liveDoctor) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        JadwalDokterService().jadwalListNotifier,
        JadwalDokterService().cutiListNotifier,
        BookingService().bookingsNotifier,
      ]),
      builder: (context, _) {
        final badge = JadwalDokterService().getDoctorBadge(liveDoctor.id);
        final cutis = JadwalDokterService().getCutiDokter(liveDoctor.id);
        final jadwalMingguan = JadwalDokterService().getJadwalDokter(liveDoctor.id);

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final activeCuti = cutis.where((c) => !c.tanggalSelesai.isBefore(today)).toList();

        // Kumpulkan hanya hari yang aktif
        final List<_HariJadwal> hariAktif = [];
        for (int d = 1; d <= 7; d++) {
          final sessions = jadwalMingguan.where((j) => j.hari == d && j.aktif).toList();
          if (sessions.isNotEmpty) hariAktif.add(_HariJadwal(hari: d, sessions: sessions));
        }

        final todayWeekday = now.weekday;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Jadwal Praktik', style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF000000))),
                _buildAvailabilityBadge(badge),
              ],
            ),
            const SizedBox(height: 14),

            // Banner cuti
            if (activeCuti.isNotEmpty)
              for (final c in activeCuti)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.beach_access_rounded, color: Color(0xFFD97706), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dokter Sedang Cuti / Berhalangan', style: GoogleFonts.lato(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF92400E))),
                            Text(
                              c.alasan.isNotEmpty
                                  ? '${c.formattedRentangTanggal} • ${c.alasan}'
                                  : c.formattedRentangTanggal,
                              style: GoogleFonts.lato(fontSize: 11.5, color: const Color(0xFFB45309)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

            // Kartu jadwal
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                boxShadow: [BoxShadow(color: const Color(0xFF3985E7).withValues(alpha: 0.07), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: hariAktif.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(Icons.event_busy_outlined, size: 40, color: Color(0xFFD1D5DB)),
                          const SizedBox(height: 10),
                          Text('Belum ada jadwal praktik', style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF8696A0))),
                          const SizedBox(height: 4),
                          Text('Dokter belum mengatur jadwal mingguan.', style: GoogleFonts.lato(fontSize: 12.5, color: const Color(0xFFADB5BD)), textAlign: TextAlign.center),
                        ],
                      ),
                    )
                  : Column(
                      children: List.generate(hariAktif.length, (idx) {
                        final item = hariAktif[idx];
                        final isLast = idx == hariAktif.length - 1;
                        final isToday = item.hari == todayWeekday;
                        return _buildHariRow(item: item, isToday: isToday, isLast: isLast);
                      }),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHariRow({required _HariJadwal item, required bool isToday, required bool isLast}) {
    final namaHari = JadwalPraktikModel.getNamaHari(item.hari);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isToday ? const Color(0xFF3985E7) : const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        namaHari,
                        style: GoogleFonts.lato(
                          fontSize: 13.5,
                          fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                          color: isToday ? const Color(0xFF3985E7) : const Color(0xFF1A2228),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: item.sessions.map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isToday ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isToday ? const Color(0xFF93C5FD) : const Color(0xFFD1D5DB), width: 1),
                      ),
                      child: Text(
                        '${s.jamMulai}–${s.jamSelesai}',
                        style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w600, color: isToday ? const Color(0xFF2563EB) : const Color(0xFF374151)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),
      ],
    );
  }

  Widget _buildAvailabilityBadge(DoctorBadgeInfo badge) {
    Color bg; Color text; Color border;
    switch (badge.type) {
      case DoctorBadgeType.tersediaHariIni:
        bg = const Color(0xFFDCFCE7); text = const Color(0xFF16A34A); border = const Color(0xFF86EFAC); break;
      case DoctorBadgeType.tersediaBesok:
        bg = const Color(0xFFDBEAFE); text = const Color(0xFF2563EB); border = const Color(0xFF93C5FD); break;
      case DoctorBadgeType.jadwalTerdekat:
        bg = const Color(0xFFF0FDF4); text = const Color(0xFF0D9488); border = const Color(0xFF99F6E4); break;
      case DoctorBadgeType.belumAdaJadwal:
        bg = const Color(0xFFE9EDEF); text = const Color(0xFF667781); border = const Color(0xFFD1D7DB); break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: border, width: 0.8)),
      child: Text(badge.label, style: GoogleFonts.lato(fontSize: 11.5, fontWeight: FontWeight.bold, color: text)),
    );
  }
}

class _HariJadwal {
  final int hari;
  final List<JadwalPraktikModel> sessions;
  const _HariJadwal({required this.hari, required this.sessions});
}
