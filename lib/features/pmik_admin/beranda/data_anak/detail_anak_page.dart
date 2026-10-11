import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/child_model.dart';
import '../../../../models/user_model.dart';
import 'pilih_anak_button_sheet.dart';
import 'superadmin_grafik_page.dart';
import 'tab_detail_pasien/resume_medis/daftar_resume_medis_page.dart';

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

  const DetailAnakPage({super.key, required this.child, this.user});

  @override
  State<DetailAnakPage> createState() => _DetailAnakPageState();
}

class _DetailAnakPageState extends State<DetailAnakPage> {
  static const Color _colorPrimaryBlue = Color(0xFF2B7AE8);
  static const Color _colorButtonBg = Color(0xFFEBF5FF);
  static const Color _colorTableBorder = Color(0xFFE2E8F0);
  static const Color _colorTableHeader = Color(0xFFE9F4FF);
  static const Color _colorLabelGrey = Color(0xFF64748B);
  static const Color _colorTextBlack = Color(0xFF000000);

  int _selectedTabIndex = 0;
  UserModel? _parentUser;
  late ChildModel _currentChild;
  String? _childPhotoUrl;

  @override
  void initState() {
    super.initState();
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
                  : _buildRuangObrolanLockedContent(),
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
              color: Color(0xFFCBD5E1),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildAvatarImage(
              imagePath: _parentUser?.avatarPath,
              size: 44,
              fallback: const Center(
                child: Icon(Icons.person, color: Color(0xFF64748B), size: 28),
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
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
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
                            : const Color(0xFF64748B),
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

          // Tab 2: Ruang Obrolan (dengan ikon gembok kecil)
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_rounded,
                          size: 15,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Ruang Obrolan',
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: _selectedTabIndex == 1
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: _selectedTabIndex == 1
                                ? _colorTextBlack
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
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
                decoration: const BoxDecoration(
                  color: Color(0xFFDCEEFF),
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildAvatarImage(
                  imagePath: _childPhotoUrl,
                  size: 48,
                  fallback: Image.asset(
                    'assets/images/default_baby_avatar.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(
                        Icons.face_rounded,
                        size: 32,
                        color: Color(0xFF2B7AE8),
                      ),
                    ),
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
  // 5. KONTEN TAB "RUANG OBROLAN" (TERKUNCI)
  // ===========================================================================
  Widget _buildRuangObrolanLockedContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_rounded,
              size: 36,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ruang Obrolan Terkunci',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _colorTextBlack,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ruang obrolan konsultasi dengan orang tua pasien hanya dapat diakses oleh dokter dan saat sesi konsultasi sedang aktif.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 13,
              color: _colorLabelGrey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
