import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/resume_medis_model.dart';
import '../../../shared/widgets/child_avatar.dart';
import '../beranda/beranda_superadmin_page.dart';
import '../konsultasi/konsultasi_superadmin_page.dart';
import '../profil/profil_superadmin_page.dart';
import 'riwayat_konsultasi_admin_model.dart';

/// Halaman Detail Riwayat Konsultasi untuk PMIK Superadmin.
///
/// Fitur:
/// - Header 56dp dari atas layar dengan tombol back dan judul tebal
/// - Kartu profil pasien: avatar anak, nama pasien bold, usia anak "X tahun Y bulan Z hari"
/// - Kartu info konsultasi berlatar biru muda: Dokter, Tanggal Konsultasi, Status Konsultasi
/// - Section Keluhan dari resume medis
/// - Section Ringkasan Konsultasi dari resume medis
/// - Banner info mode nonaktif (read-only)
/// - Bottom Navigation Bar 4 menu dengan "Riwayat Konsultasi" aktif
class DetailRiwayatKonsultasiAdminPage extends StatefulWidget {
  final RiwayatKonsultasiAdminItem? item;
  final ResumeMedisModel? resume; // Backward compatibility

  const DetailRiwayatKonsultasiAdminPage({
    super.key,
    this.item,
    this.resume,
  });

  @override
  State<DetailRiwayatKonsultasiAdminPage> createState() =>
      _DetailRiwayatKonsultasiAdminPageState();
}

class _DetailRiwayatKonsultasiAdminPageState
    extends State<DetailRiwayatKonsultasiAdminPage> {
  // ─── Color Palette ─────────────────────────────────────────────────────────
  static const Color _colorNavBg = Color(0xFFF2EDED);
  static const Color _colorSecondaryGrey = Color(0xFF7F7F7F);
  static const Color _colorTextBlack = Color(0xFF000000);
  static const int _selectedNavIndex = 2; // Riwayat Konsultasi

  late RiwayatKonsultasiAdminItem _item;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _item = widget.item!;
    } else if (widget.resume != null) {
      final r = widget.resume!;
      _item = RiwayatKonsultasiAdminItem(
        id: r.id,
        childId: r.childId,
        childName: r.childName,
        childAge: r.childAgeAtConsultation,
        doctorName: r.doctorName,
        formattedDate: r.consultationDate,
        status: r.status,
        complaint: r.complaint,
        summary: r.summary,
        resumeMedisId: r.id,
        sessionId: r.sessionId,
      );
    } else {
      _item = RiwayatKonsultasiAdminItem.getMockData()[1]; // Kaia Anastasya
    }

    _listenRealTimeChildAndResume();
  }

  /// Sinkronisasi real-time jika ada pembaruan data anak atau resume medis di Firebase
  void _listenRealTimeChildAndResume() {
    try {
      final db = FirebaseFirestore.instance;

      // 1. Dengarkan pembaruan data anak jika childId tersedia
      if (_item.childId.isNotEmpty) {
        db.collection('children').doc(_item.childId).snapshots().listen((doc) {
          if (!mounted || !doc.exists || doc.data() == null) return;
          final data = doc.data()!;
          final birthDate = parseAnyDate(
            data['birth_date'] ?? data['tanggal_lahir'],
          );
          final gender = data['gender']?.toString() ?? _item.childGender;
          setState(() {
            _item = _item.copyWith(
              childBirthDate: birthDate ?? _item.childBirthDate,
              childGender: gender,
            );
          });
        });
      }

      // 2. Dengarkan pembaruan resume medis jika resumeMedisId tersedia
      if (_item.resumeMedisId != null && _item.resumeMedisId!.isNotEmpty) {
        db
            .collection('resume_medis')
            .doc(_item.resumeMedisId)
            .snapshots()
            .listen((doc) {
          if (!mounted || !doc.exists || doc.data() == null) return;
          final data = doc.data()!;
          final complaint =
              (data['complaint'] ?? data['complaint_short'] ?? '').toString();
          final summary = (data['summary'] ?? '').toString();
          final status = (data['status'] ?? _item.status).toString();
          setState(() {
            _item = _item.copyWith(
              complaint: complaint.isNotEmpty ? complaint : _item.complaint,
              summary: summary.isNotEmpty ? summary : _item.summary,
              status: status,
            );
          });
        });
      }
    } catch (_) {
      // Offline / fallback ke state yang ada
    }
  }

  void _onBottomNavTap(int index) {
    if (index == _selectedNavIndex) {
      Navigator.of(context).pop();
      return;
    }

    Widget targetPage;
    switch (index) {
      case 0:
        targetPage = const BerandaSuperadminPage();
        break;
      case 1:
        targetPage = const KonsultasiSuperadminPage();
        break;
      case 3:
        targetPage = const ProfilSuperadminPage();
        break;
      default:
        return;
    }

    final isLeft = index < _selectedNavIndex;
    final beginOffset = Offset(isLeft ? -0.25 : 0.25, 0.0);
    final route = PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) => targetPage,
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );

    if (index == 0) {
      Navigator.of(context).pushAndRemoveUntil(route, (r) => false);
    } else {
      Navigator.of(context).pushReplacement(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGirl = _item.isGirl;
    final isSelesai = _item.status.toLowerCase().contains('selesai');

    // Teks keluhan dan ringkasan dengan penanganan sopan jika belum ada resume
    final complaintText = _item.complaint.trim().isNotEmpty
        ? _item.complaint
        : 'Belum ada resume medis';

    final summaryText = _item.summary.trim().isNotEmpty
        ? _item.summary
        : 'Belum ada resume medis';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ─── HEADER (56dp dari atas layar) ───────────────────────────
          _buildHeader(),

          // ─── KONTEN SCROLLABLE (Padding horizontal 16dp) ────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14.0),

                  // 1. Banner Mode Nonaktif di BAGIAN ATAS (Konsisten & Seragam)
                  _buildReadOnlyBanner(),
                  const SizedBox(height: 16.0),

                  // 2. Kartu Profil Pasien
                  _buildPatientProfileCard(isGirl),
                  const SizedBox(height: 16.0),

                  // 3. Kartu Informasi Konsultasi (Latar biru muda)
                  _buildConsultationInfoCard(isSelesai),
                  const SizedBox(height: 20.0),

                  // 4. Section Keluhan
                  Text(
                    'Keluhan',
                    style: GoogleFonts.lato(
                      fontSize: 14.5,
                      color: _colorSecondaryGrey,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    complaintText,
                    style: GoogleFonts.lato(
                      fontSize: 14.5,
                      color: _colorTextBlack,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // 5. Section Ringkasan Konsultasi
                  Text(
                    'Ringkasan Konsultasi',
                    style: GoogleFonts.lato(
                      fontSize: 14.5,
                      color: _colorSecondaryGrey,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    summaryText,
                    style: GoogleFonts.lato(
                      fontSize: 14.5,
                      color: _colorTextBlack,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ─── HEADER ─────────────────────────────────────────────────────────────────
  /// Header diletakkan 56dp dari atas layar, berisi tombol back berjarak 12dp
  /// dari tepi kiri layar, dan judul halaman di sebelah kanannya berjarak 12dp.
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.only(top: 56.0, bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.only(left: 12.0, right: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 32.0,
                height: 32.0,
                child: Icon(
                  Icons.arrow_back,
                  size: 24.0,
                  color: _colorTextBlack,
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                'Detail Riwayat Konsultasi',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lato(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: _colorTextBlack,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── KARTU PROFIL PASIEN ───────────────────────────────────────────────────
  /// Kartu berlatar putih dengan sudut membulat dan shadow tipis,
  /// berisi avatar anak di kiri, nama pasien bold, dan usia anak di bawahnya.
  Widget _buildPatientProfileCard(bool isGirl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10.0,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar anak
          ChildAvatar(
            gender: _item.childGender,
            isGirl: isGirl,
            size: 48.0,
            backgroundColor:
                isGirl ? const Color(0xFFFFD1D6) : const Color(0xFFBBE4FF),
          ),
          const SizedBox(width: 14.0),
          // Nama Pasien & Usia Anak
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _item.childName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: _colorTextBlack,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  _item.calculatedAge,
                  style: GoogleFonts.lato(
                    fontSize: 14.0,
                    color: _colorTextBlack,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── KARTU INFORMASI KONSULTASI ───────────────────────────────────────────
  /// Kartu berlatar biru sangat muda dengan border biru muda,
  /// berisi 3 baris: Dokter, Tanggal Konsultasi, dan Status Konsultasi.
  Widget _buildConsultationInfoCard(bool isSelesai) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FE),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: const Color(0xFFBAE6FD),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          // 1. Baris Dokter
          _buildInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Dokter',
            value: _item.doctorName,
          ),
          const SizedBox(height: 14.0),

          // 2. Baris Tanggal Konsultasi
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Tanggal Konsultasi',
            value: _item.formattedDate,
          ),
          const SizedBox(height: 14.0),

          // 3. Baris Status Konsultasi
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.assignment_outlined,
                size: 20.0,
                color: _colorSecondaryGrey,
              ),
              const SizedBox(width: 10.0),
              Text(
                'Status Konsultasi',
                style: GoogleFonts.lato(
                  fontSize: 14.0,
                  color: _colorSecondaryGrey,
                ),
              ),
              const Spacer(),
              _buildStatusBadge(isSelesai),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 20.0,
          color: _colorSecondaryGrey,
        ),
        const SizedBox(width: 10.0),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 14.0,
            color: _colorSecondaryGrey,
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lato(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: _colorTextBlack,
            ),
          ),
        ),
      ],
    );
  }

  /// Badge Status Konsultasi
  Widget _buildStatusBadge(bool isSelesai) {
    if (isSelesai) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: const Color(0xFF33CCA6),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Text(
          'Selesai',
          style: GoogleFonts.lato(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEEA0),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Text(
          'Dijadwalkan',
          style: GoogleFonts.lato(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFE67E00),
          ),
        ),
      );
    }
  }

  // ─── READ-ONLY BANNER ───────────────────────────────────────────────────────
  Widget _buildReadOnlyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FD),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: const Color(0xFF72A9F4),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 22.0,
            color: Color(0xFF3985E7),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              'Mode nonaktif. Anda tidak dapat membalas atau mengubah riwayat konsultasi.',
              style: GoogleFonts.lato(
                fontSize: 13.5,
                color: const Color(0xFF2B7CD6),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM NAVIGATION BAR (4 MENU) ─────────────────────────────────────────
  Widget _buildBottomNavigationBar() {
    const navItems = [
      _NavItem(icon: Icons.home_rounded, label: 'Beranda'),
      _NavItem(icon: Icons.question_answer_rounded, label: 'Konsultasi'),
      _NavItem(icon: Icons.manage_search_rounded, label: 'Riwayat Konsultasi'),
      _NavItem(icon: Icons.person_rounded, label: 'Profil'),
    ];

    return Container(
      width: double.infinity,
      height: 68.0,
      decoration: const BoxDecoration(
        color: _colorNavBg,
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 8.0,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(navItems.length, (i) {
            final isSelected = i == _selectedNavIndex;
            final item = navItems[i];
            return Expanded(
              child: GestureDetector(
                onTap: () => _onBottomNavTap(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: 68.0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        // Lingkaran sorot di belakang ikon
                        Container(
                          width: 36.0,
                          height: 36.0,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 4.0,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            item.icon,
                            size: 22.0,
                            color: const Color(0xFF72A9F4),
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                fontSize: 11.0,
                                fontWeight: FontWeight.normal,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Icon(
                          item.icon,
                          size: 24.0,
                          color: const Color(0xFF9E9E9E),
                        ),
                        const SizedBox(height: 3.0),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lato(
                                fontSize: 11.0,
                                fontWeight: FontWeight.normal,
                                color: const Color(0xFF9E9E9E),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
