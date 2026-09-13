import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/doctor_model.dart';
import 'menunggu_persetujuan_page.dart';

/// Halaman Profil Dokter Anak pada fitur Konsultasi PediaGrow.
///
/// Alur navigasi: Profil Dokter → [MenungguPersetujuanPage] → [FormulirKonsultasiPage] → [ChatKonsultasiPage]
///
/// Disesuaikan persis dengan acuan desain:
/// 1. Header: Tombol kembali + judul "Profil Dokter Anak"
/// 2. Kartu Utama Profil Dokter:
///    - Foto avatar sirkular yang overlapping di bagian atas kartu
///    - Indikator badge hijau di sudut avatar
///    - Nama dokter (center, bold)
///    - Spesialisasi "Spesialis Anak" (center)
///    - Bagian statistik: Pengalaman (tahun) di sisi kiri, garis pemisah vertikal,
///      dan Nomor STR di sisi kanan
/// 3. Bagian "Tempat Praktik":
///    - Judul section "Tempat Praktik"
///    - Kartu berisikan daftar rumah sakit/klinik praktik dokter dengan ikon fasyankes
///      dan garis divider horizontal
/// 4. Bottom Action Bar:
///    - Tombol oranye "Chat Dokter" → navigasi ke [MenungguPersetujuanPage]
class ProfilDokterPage extends StatelessWidget {
  final DoctorModel doctor;

  const ProfilDokterPage({super.key, required this.doctor});

  void _onChatDokterPressed(BuildContext context) {
    // Alur resmi: Profil Dokter → Menunggu Persetujuan (otomatis 3.5s) → Formulir → Chat
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MenungguPersetujuanPage(doctor: doctor),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    _buildDoctorProfileCard(),

                    const SizedBox(height: 28),

                    // Judul Section: Tempat Praktik
                    Text(
                      'Tempat Praktik',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF000000),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Kartu Daftar Tempat Praktik
                    _buildPracticeLocationsCard(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // -------------------------------------------------------------
            // 3. BOTTOM BAR (Tombol Chat Dokter di Kanan)
            // -------------------------------------------------------------
            _buildBottomActionBar(context),
          ],
        ),
      ),
    );
  }

  /// Kartu utama profil dokter dengan foto bundar overlapping di atas
  Widget _buildDoctorProfileCard() {
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
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Nama Dokter (Lato Bold 18, #000000, Center)
              Text(
                doctor.name,
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
                doctor.specialization,
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 22),

              // Baris Statistik: Pengalaman & No. STR dipisahkan garis vertikal
              Row(
                children: [
                  // Sisi Kiri: Pengalaman Kerja
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                                '${doctor.experienceYears} tahun',
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

                  // Garis Pemisah Vertikal
                  Container(
                    width: 1,
                    height: 38,
                    color: const Color(0xFFE2E8F0),
                  ),

                  // Sisi Kanan: No. STR
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                                doctor.strNumber ?? '3511201402016252',
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

        // Avatar Bulat Overlapping di bagian atas kartu dengan Badge Hijau
        Positioned(
          top: 0,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _buildAvatarImage(),
                ),
              ),
              // Indikator Titik Hijau di sudut atas kanan avatar
              Positioned(
                top: 3,
                right: 3,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Kartu tempat praktik dengan daftar lokasi & divider horizontal
  Widget _buildPracticeLocationsCard() {
    final places = doctor.daftarTempatPraktik;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
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
                  color: Color(0xFFE2E8F0),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () => _onChatDokterPressed(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA000),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Chat Dokter',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
    if (doctor.avatarUrl != null && doctor.avatarUrl!.isNotEmpty) {
      return Image.network(
        doctor.avatarUrl!,
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
}
