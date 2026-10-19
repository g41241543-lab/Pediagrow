import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/child_model.dart';
import '../../../../shared/widgets/child_avatar.dart';
import '../../../../models/user_model.dart';
import 'pilih_anak_button_sheet.dart';
import 'superadmin_grafik_page.dart';
import 'tab_detail_pasien/resume_medis/daftar_resume_medis_page.dart';
import '../../../../core/services/booking_service.dart';
import '../../../../core/services/konsultasi_service.dart';
import '../../../../core/services/staff_auth_service.dart';
import '../../../../models/booking_consultation_model.dart';
import '../../../../models/konsultasi_session_model.dart';
import '../../konsultasi/chat_konsultasi_dokter_page.dart';

/// Halaman Data Pasien Anak untuk POV Superadmin.
///
/// Fitur Utama yang disesuaikan:
/// - Header fixed putih tanpa perbedaan warna latar belakang:
///   Tombol kembali & judul "Data Pasien Anak".
/// - Nama Pengguna (Orang Tua) dengan avatar dinamis dari Firestore & font bold.
/// - Tab Bar:
///   1. "Detail Pasien" (aktif dengan indikator garis biru).
///   2. "Ruang Obrolan" (dengan ikon gembok kecil).
/// - Header Profil Anak: Avatar anak dinamis dari database Firestore (collection 'children' atau 'users')
///   + Nama Anak + Usia akurat.
/// - 2 Menu Button Berdampingan yang lebih compact & proporsional (spaceEvenly):
///   1. "Grafik Pertumbuhan" (logo grafik_pertumbuhan_logo.png).
///   2. "Resume Medis" (logo data_pasien_logo.png).
/// - Tabel "Biodata Anak" dengan header biru muda lembut dan 8 baris field TANPA tanda bintang (*):
///   1. Nama Lengkap
///   2. Tanggal Lahir (format bahasa Indonesia: Hari, DD Bulan YYYY)
///   3. Jenis Kelamin
///   4. Prematur (Ya, Minggu ke-XX / -)
///   5. Berat Badan Saat Lahir (kg)
///   6. Tinggi Badan Saat Lahir (cm)
///   7. Lingkar Kepala Saat Lahir (cm)
///   8. Alergi
/// - Latar belakang putih bersih konsisten di seluruh halaman tanpa perbedaan warna.
/// - Tanpa Navigation Bar di Scaffold bawah.
class DetailAnakPage extends StatefulWidget {
  final ChildModel child;
  final UserModel? user;
  final int initialTabIndex;
  final String? sessionId;
  final BookingConsultationModel? booking;

  const DetailAnakPage({
    super.key,
    required this.child,
    this.user,
    this.initialTabIndex = 0,
    this.sessionId,
    this.booking,
  });

  @override
  State<DetailAnakPage> createState() => _DetailAnakPageState();
}

class _DetailAnakPageState extends State<DetailAnakPage> {
  static const Color _colorPrimaryBlue = Color(0xFF2B7AE8);
  static const Color _colorButtonBg = Color(0xFFEBF5FF);
  static const Color _colorTableBorder = Color(0xFFE9EDEF);
  static const Color _colorTableHeader = Color(0xFFE9F4FF);
  static const Color _colorLabelGrey = Color(0xFF667781);
  static const Color _colorTextBlack = Color(0xFF000000);

  late int _selectedTabIndex;
  UserModel? _parentUser;
  late ChildModel _currentChild;
  String? _childPhotoUrl;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _currentChild = widget.child;
    _parentUser = widget.user;
    _childPhotoUrl = widget.child.photoUrl;

    _fetchData();
  }


  /// Sinkronisasi data terbaru dari Firestore untuk collection 'users' dan 'children'
  Future<void> _fetchData() async {
    final userId = _parentUser?.id.isNotEmpty == true
        ? _parentUser!.id
        : _currentChild.ownerId;

    if (userId.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (doc.exists && doc.data() != null && mounted) {
          final data = doc.data()!;
          setState(() {
            _parentUser = UserModel.fromMap({...data, 'id': doc.id});
            final pPhoto =
                data['photoUrl'] ??
                data['photo_url'] ??
                data['avatarPath'] ??
                data['avatar_path'] ??
                data['avatar'];
            if (pPhoto != null && pPhoto.toString().trim().isNotEmpty) {
              _parentUser = _parentUser?.copyWith(
                avatarPath: pPhoto.toString(),
              );
            }

            final uChildPhoto =
                data['childPhoto'] ??
                data['child_photo'] ??
                data['childPhotoUrl'] ??
                data['child_photo_url'];
            if (uChildPhoto != null &&
                uChildPhoto.toString().trim().isNotEmpty &&
                (_childPhotoUrl == null || _childPhotoUrl!.isEmpty)) {
              _childPhotoUrl = uChildPhoto.toString();
            }
          });
        }
      } catch (_) {}
    }

    if (_currentChild.id.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('children')
            .doc(_currentChild.id)
            .get();

        if (doc.exists && doc.data() != null && mounted) {
          final data = doc.data()!;
          setState(() {
            _currentChild = ChildModel.fromMap({...data, 'id': doc.id});
            final cPhoto =
                data['photoUrl'] ??
                data['photo_url'] ??
                data['avatar'] ??
                data['avatarPath'] ??
                data['foto'] ??
                data['foto_url'];
            if (cPhoto != null && cPhoto.toString().trim().isNotEmpty) {
              _childPhotoUrl = cPhoto.toString();
            }
          });
        }
      } catch (_) {}
    }
  }

  /// Helper untuk merender foto avatar baik berupa URL Network, File Lokal,
  /// maupun Asset Path, dengan widget fallback yang aman jika foto kosong/gagal muat.
  Widget _buildAvatarImage({
    required String? imagePath,
    required double size,
    required Widget fallback,
  }) {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return fallback;
    }

    final trimmed = imagePath.trim();

    // 1. Base64
    if (trimmed.startsWith('data:image')) {
      try {
        final commaIdx = trimmed.indexOf(',');
        final base64Str = commaIdx != -1
            ? trimmed.substring(commaIdx + 1)
            : trimmed;
        final bytes = base64Decode(base64Str.trim());
        return Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        );
      } catch (_) {}
    }

    if (trimmed.startsWith('/9j/') || trimmed.startsWith('iVBORw0KGgo')) {
      try {
        final bytes = base64Decode(trimmed);
        return Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        );
      } catch (_) {}
    }

    // 2. URL Jaringan (Network)
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(
        trimmed,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }

    // 2. Aset Lokal Flutter
    if (trimmed.startsWith('assets/')) {
      return Image.asset(
        trimmed,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }

    // 3. File Path di Perangkat
    try {
      final file = File(trimmed);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        );
      }
    } catch (_) {}

    return fallback;
  }

  /// Format tanggal lahir dalam bahasa Indonesia: "Selasa, 12 April 2026"
  String _formatTanggalIndonesia(DateTime? date) {
    if (date == null) return '-';
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  String _formatNumber(double? value) {
    if (value == null) return '-';
    return value % 1 == 0 ? value.toInt().toString() : value.toString();
  }

  void _navigateToResumeMedis() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, _, _) =>
            DaftarResumeMedisPage(child: _currentChild, user: widget.user),
        transitionsBuilder: (_, animation, _, childWidget) =>
            FadeTransition(opacity: animation, child: childWidget),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Bar Fixed (56dp)
            _buildAppBar(),

            // 2. Info Nama Orang Tua (Tanpa icon, font lebih kecil & warna abu-abu)
            _buildParentHeader(),

            // 3. Tab Bar (Detail Pasien | Ruang Obrolan)
            _buildTabBar(),

            // 4. Konten Tab (Scrollable)
            Expanded(
              child: _selectedTabIndex == 0
                  ? _buildDetailPasienContent()
                  : _buildRuangObrolanDokterContent(),
            ),
          ],
        ),
      ),
      // Sesuai permintaan: Halaman detail anak dibuat tanpa navigation bar
      bottomNavigationBar: null,
    );
  }

  // ===========================================================================
  // 1. APP BAR (PUTIH BERSIH TANPA PERBEDAAN WARNA)
  // ===========================================================================
  Widget _buildAppBar() {
    return Container(
      width: double.infinity,
      height: 56,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.arrow_back, color: _colorTextBlack, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Data Pasien Anak',
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _colorTextBlack,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. INFO PENGGUNA (ORANG TUA)
  // Tanpa icon di sampingnya, font lebih kecil & warna teks abu-abu
  // ===========================================================================
  Widget _buildParentHeader() {
    final parentName = _parentUser?.name.isNotEmpty == true
        ? _parentUser!.name
        : 'Susanti Saputri Dewi';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFD1D7DB),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildAvatarImage(
              imagePath: _parentUser?.avatarPath,
              size: 44,
              fallback: const Center(
                child: Icon(Icons.person, color: Color(0xFF667781), size: 28),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              parentName,
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _colorTextBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. TAB BAR: "Detail Pasien" & "🔒 Ruang Obrolan"
  // ===========================================================================
  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE9EDEF), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // Tab 1: Detail Pasien
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedTabIndex != 0) {
                  setState(() => _selectedTabIndex = 0);
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Detail Pasien',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        fontWeight: _selectedTabIndex == 0
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: _selectedTabIndex == 0
                            ? _colorTextBlack
                            : const Color(0xFF667781),
                      ),
                    ),
                  ),
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: _selectedTabIndex == 0
                          ? _colorPrimaryBlue
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab 2: Ruang Obrolan (Dapat diakses oleh dokter tanpa digembok)
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedTabIndex != 1) {
                  setState(() => _selectedTabIndex = 1);
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Ruang Obrolan',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        fontWeight: _selectedTabIndex == 1
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: _selectedTabIndex == 1
                            ? _colorTextBlack
                            : const Color(0xFF667781),
                      ),
                    ),
                  ),
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: _selectedTabIndex == 1
                          ? _colorPrimaryBlue
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. KONTEN TAB "DETAIL PASIEN"
  // ===========================================================================
  Widget _buildDetailPasienContent() {
    // Usia akurat: "0 tahun 4 bulan 14 hari"
    String usiaText = _currentChild.ageDescription;
    if (_currentChild.birthDate != null) {
      usiaText = calculateAge(_currentChild.birthDate!).formatted;
    }
    if (usiaText.isEmpty) {
      usiaText = '0 tahun 4 bulan 14 hari';
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A. Header Profil Anak (Avatar Wajah + Nama & Usia)
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ChildAvatar.bgColorFor(gender: widget.child.gender),
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildAvatarImage(
                  imagePath: _childPhotoUrl,
                  size: 48,
                  fallback: ChildAvatar(
                    gender: widget.child.gender,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentChild.name.isNotEmpty
                          ? _currentChild.name
                          : 'Arfa Zivano Kayfan',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _colorTextBlack,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      usiaText,
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: _colorLabelGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // B. Dua Tombol Menu Berdampingan: "Grafik Pertumbuhan" & "Resume Medis"
          // Dibuat agak kecil, proporsional, dan jarak kanan, tengah, serta kiri simetris
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Grafik Pertumbuhan (Menggunakan logo resmi grafik_pertumbuhan_logo.png)
              _buildFeatureButton(
                title: 'Grafik\nPertumbuhan',
                imageAsset: 'assets/images/grafik_pertumbuhan_logo.png',
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (_, _, _) =>
                          SuperadminGrafikPage(child: _currentChild),
                      transitionsBuilder: (_, animation, _, childWidget) =>
                          FadeTransition(
                            opacity: animation,
                            child: childWidget,
                          ),
                      transitionDuration: const Duration(milliseconds: 200),
                    ),
                  );
                },
              ),

              const SizedBox(width: 48),

              // 2. Resume Medis (Menggunakan logo resmi data_pasien_logo.png)
              _buildFeatureButton(
                title: 'Resume\nMedis',
                imageAsset: 'assets/images/data_pasien_logo.png',
                onTap: _navigateToResumeMedis,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // C. Tabel "Biodata Anak" (Termasuk Lingkar Kepala)
          _buildBiodataAnakCard(),
        ],
      ),
    );
  }

  // ===========================================================================
  // FEATURE BUTTON KOTAK (GRAFIK PERTUMBUHAN & RESUME MEDIS)
  // Ukuran compact, proporsional, background biru muda lembut
  // ===========================================================================
  Widget _buildFeatureButton({
    required String title,
    required String imageAsset,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            splashColor: _colorPrimaryBlue.withValues(alpha: 0.12),
            child: Container(
              width: 82,
              height: 74,
              decoration: BoxDecoration(
                color: _colorButtonBg,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Image.asset(
                imageAsset,
                width: 36,
                height: 36,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.insert_chart_outlined,
                  size: 32,
                  color: _colorPrimaryBlue,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: _colorTextBlack,
            height: 1.25,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // C. TABEL BIODATA ANAK
  // Menyajikan 8 field lengkap (tanpa tanda bintang):
  // 1. Nama Lengkap
  // 2. Tanggal Lahir
  // 3. Jenis Kelamin
  // 4. Prematur (Ya, Minggu ke-XX / -)
  // 5. Berat Badan Saat Lahir (kg)
  // 6. Tinggi Badan Saat Lahir (cm)
  // 7. Lingkar Kepala Saat Lahir (cm)
  // 8. Alergi
  // ===========================================================================
  Widget _buildBiodataAnakCard() {
    final child = _currentChild;

    final String namaLengkap = child.name.isNotEmpty ? child.name : '-';
    final String tanggalLahir = _formatTanggalIndonesia(child.birthDate);
    final String jenisKelamin = child.gender.isNotEmpty ? child.gender : '-';

    // Prematur: jika ada data isPremature
    String prematur;
    if (child.isPremature == null) {
      prematur = '-';
    } else if (child.isPremature == true) {
      final minggu = child.gestationalAgeWeeks;
      prematur = minggu != null ? 'Ya, Lahir di minggu ke-$minggu' : 'Ya';
    } else {
      prematur = '-';
    }

    final String bbLahir = _formatNumber(child.birthWeightKg ?? child.weightKg);
    final String tbLahir = _formatNumber(child.birthHeightCm ?? child.heightCm);
    final String lkLahir = _formatNumber(child.headCircumferenceCm);
    final String alergi =
        child.allergies != null && child.allergies!.trim().isNotEmpty
        ? child.allergies!.trim()
        : '-';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFBAE6FD).withValues(alpha: 0.8),
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Tabel: Background Biru Muda Lembut
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: _colorTableHeader,
            child: Text(
              'Biodata Anak',
              style: GoogleFonts.lato(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _colorTextBlack,
              ),
            ),
          ),

          const Divider(height: 1, color: _colorTableBorder),

          // Baris 1: Nama Lengkap
          _buildTableRow(label: 'Nama Lengkap', value: namaLengkap),
          const Divider(height: 1, color: _colorTableBorder),

          // Baris 2: Tanggal Lahir
          _buildTableRow(label: 'Tanggal Lahir', value: tanggalLahir),
          const Divider(height: 1, color: _colorTableBorder),

          // Baris 3: Jenis Kelamin
          _buildTableRow(label: 'Jenis Kelamin', value: jenisKelamin),
          const Divider(height: 1, color: _colorTableBorder),

          // Baris 4: Prematur
          _buildTableRow(label: 'Prematur', value: prematur),
          const Divider(height: 1, color: _colorTableBorder),

          // Baris 5: Berat Badan Saat Lahir (kg)
          _buildTableRow(label: 'Berat Badan Saat Lahir (kg)', value: bbLahir),
          const Divider(height: 1, color: _colorTableBorder),

          // Baris 6: Tinggi Badan Saat Lahir (cm)
          _buildTableRow(label: 'Tinggi Badan Saat Lahir (cm)', value: tbLahir),
          const Divider(height: 1, color: _colorTableBorder),

          // Baris 7: Lingkar Kepala Saat Lahir (cm)
          _buildTableRow(
            label: 'Lingkar Kepala Saat Lahir (cm)',
            value: lkLahir,
          ),
          const Divider(height: 1, color: _colorTableBorder),

          // Baris 8: Alergi
          _buildTableRow(label: 'Alergi', value: alergi),
        ],
      ),
    );
  }

  /// Baris dalam tabel biodata anak:
  /// - Label abu-abu
  /// - Nilai di bawahnya (font semi-bold hitam 14)
  Widget _buildTableRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: _colorLabelGrey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isNotEmpty ? value : '-',
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _colorTextBlack,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ===========================================================================
  // 5. KONTEN TAB "RUANG OBROLAN" (POV DOKTER)
  // Dapat diakses oleh dokter; menampilkan sesi jika ada, atau state info kosong jika tidak ada
  // ===========================================================================
  Widget _buildRuangObrolanDokterContent() {
    return StreamBuilder<List<KonsultasiSessionModel>>(
      stream: KonsultasiService.instance.streamSemuaSesiAktif(),
      builder: (context, sessionSnap) {
        final activeSessions = sessionSnap.data ?? [];
        final currentStaff = StaffAuthService().currentStaff;
        final docName = currentStaff?.name.toLowerCase() ?? '';
        final childName = _currentChild.name.toLowerCase();
        final childId = _currentChild.id;

        // Cari sesi Firestore aktif untuk anak ini
        KonsultasiSessionModel? matchedSession;
        for (final s in activeSessions) {
          final sDocName = s.doctorName.toLowerCase();
          final matchDoc = docName.isEmpty ||
              sDocName.contains(docName) ||
              docName.contains(sDocName);
          final matchChild = (childId.isNotEmpty && s.childId == childId) ||
              s.childName.toLowerCase() == childName;
          final matchSessionId = widget.sessionId != null &&
              widget.sessionId!.isNotEmpty &&
              s.id == widget.sessionId;
          if ((matchDoc && matchChild) || matchSessionId) {
            matchedSession = s;
            break;
          }
        }

        return ValueListenableBuilder<List<BookingConsultationModel>>(
          valueListenable: BookingService().bookingsNotifier,
          builder: (context, bookings, _) {
            // Cari jadwal booking yang cocok untuk anak ini
            BookingConsultationModel? matchedBooking = widget.booking;
            if (matchedBooking == null) {
              for (final b in bookings) {
                final bChildName = b.child.name.toLowerCase();
                final bChildId = b.child.id;
                final bDocName = b.doctor.name.toLowerCase();

                final matchDoctor = docName.isEmpty ||
                    bDocName.contains(docName) ||
                    docName.contains(bDocName);
                final matchChild = (childId.isNotEmpty && bChildId == childId) ||
                    bChildName == childName;

                if (matchDoctor && matchChild && b.status != 'Dibatalkan') {
                  matchedBooking = b;
                  break;
                }
              }
            }

            final bool isBookingBeforeStart = matchedBooking?.isBeforeStart ?? false;

            // Jika sesi masih berstatus menunggu saat dokter masuk, aktifkan sesi otomatis
            // HANYA jika waktu jadwal sudah tiba (jangan aktifkan sebelum waktu konsultasi)
            if (matchedSession != null &&
                matchedSession.status == KonsultasiStatus.menunggu &&
                !isBookingBeforeStart) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                KonsultasiService.instance.mulaiSesi(matchedSession!.id);
              });
            }

            // 1. Cek apakah ada sesi konsultasi aktif/menunggu di Firestore
            final bool isFirestoreActive = matchedSession != null &&
                (matchedSession.status == KonsultasiStatus.aktif ||
                    matchedSession.status == KonsultasiStatus.menunggu) &&
                !isBookingBeforeStart;

            // 2. Cek apakah jadwal booking sedang berlangsung saat ini
            final bool isBookingActive =
                matchedBooking != null && _isBookingActiveNow(matchedBooking);

            // 3. Status aktif riil (aktif jika ada sesi di firestore atau booking aktif, dan bukan sebelum jadwal)
            final bool isCurrentlyActive = !isBookingBeforeStart &&
                (isFirestoreActive ||
                    isBookingActive ||
                    (widget.sessionId != null && widget.sessionId!.isNotEmpty && matchedBooking == null));

            final effectiveSessionId = widget.sessionId ??
                matchedBooking?.sessionId ??
                (matchedBooking != null ? 'session_${matchedBooking.id}' : null) ??
                (widget.booking?.sessionId ?? (widget.booking != null ? 'session_${widget.booking!.id}' : null)) ??
                matchedSession?.id;

            if (matchedSession != null ||
                matchedBooking != null ||
                (effectiveSessionId != null && effectiveSessionId.isNotEmpty)) {
              final parentDisplayName = matchedSession?.parentName.isNotEmpty == true
                  ? matchedSession!.parentName
                  : _parentUser?.name.isNotEmpty == true
                      ? _parentUser!.name
                      : 'Orang Tua ${_currentChild.name}';

              // Ruang Obrolan = Ruang Chat langsung tanpa tombol Masuk Ruang Chat lagi.
              // Dokter dapat langsung mengirim pesan & foto saat konsultasi berlangsung.
              return ChatKonsultasiDokterPage(
                isEmbedded: true,
                topCard: _buildJadwalInfoCard(
                  booking: matchedBooking,
                  session: matchedSession,
                  parentDisplayName: parentDisplayName,
                  isActive: isCurrentlyActive,
                ),
                child: _currentChild,
                parentUser: _parentUser,
                parentName: parentDisplayName,
                doctorName: currentStaff?.name ?? 'Dokter',
                complaint: matchedSession?.keluhanAwal ?? matchedBooking?.complaint,
                weightKg: matchedSession?.weightKg ?? matchedBooking?.weightKg ?? _currentChild.weightKg,
                heightCm: matchedSession?.heightCm ?? matchedBooking?.heightCm ?? _currentChild.heightCm,
                sessionId: effectiveSessionId,
                booking: matchedBooking,
                hasActiveSession: isCurrentlyActive,
              );
            }

            // State kosong jika sedang tidak ada sesi konsultasi/booking
            return _buildEmptyConsultationSessionView();
          },
        );
      },
    );
  }

  /// Mengecek apakah suatu booking konsultasi sedang berlangsung pada saat ini
  bool _isBookingActiveNow(BookingConsultationModel booking) {
    if (booking.status == 'Selesai' ||
        booking.status == 'Dibatalkan' ||
        booking.isExpired) {
      return false;
    }
    if (booking.isBeforeStart) {
      return false;
    }
    if (booking.status == 'Sedang Berlangsung' && !booking.isExpired) {
      return true;
    }
    return booking.isInTimeWindow;
  }

  /// Kartu info jadwal konsultasi yang disematkan di atas ruang obrolan (tanpa tombol Masuk Ruang Chat)
  Widget _buildJadwalInfoCard({
    BookingConsultationModel? booking,
    KonsultasiSessionModel? session,
    required String parentDisplayName,
    required bool isActive,
  }) {
    final scheduleText = session != null
        ? 'Sesi Konsultasi Langsung Sedang Berlangsung'
        : booking != null
            ? '${booking.formattedDate} (${booking.scheduledTimeSlot})'
            : 'Sesi Aktif Sedang Berlangsung';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? const Color(0xFFBFDBFE) : const Color(0xFFE9EDEF),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header badge sesi aktif / konsultasi terjadwal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFFA7F3D0)
                        : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isActive) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Sesi Konsultasi Aktif',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF047857),
                        ),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.event_available_rounded,
                        size: 13,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Konsultasi Terjadwal',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1D4ED8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chat_rounded,
                size: 18,
                color: isActive ? _colorPrimaryBlue : const Color(0xFF8696A0),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Info Pasien & Orang Tua
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.child_care_rounded,
                  color: _colorPrimaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentChild.name,
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _colorTextBlack,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      parentDisplayName,
                      style: GoogleFonts.lato(
                        fontSize: 12.5,
                        color: _colorLabelGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE9EDEF)),
          const SizedBox(height: 10),

          // Jadwal
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 15,
                color: Color(0xFF3B82F6),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  scheduleText,
                  style: GoogleFonts.lato(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A2228),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tampilan saat tidak ada sesi konsultasi/booking yang sedang berlangsung
  Widget _buildEmptyConsultationSessionView() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(28, 48, 28, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 40,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Tidak Ada Sesi Konsultasi Aktif',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _colorTextBlack,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Saat ini belum ada jadwal booking atau sesi obrolan konsultasi yang sedang berlangsung untuk pasien ${_currentChild.name}.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 13,
              color: _colorLabelGrey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE9EDEF)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: Color(0xFF3B82F6),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ruang obrolan akan terbuka dan aktif secara otomatis saat orang tua pasien melakukan booking jadwal konsultasi dengan Anda dan waktu sesi telah tiba.',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: const Color(0xFF2C363D),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
