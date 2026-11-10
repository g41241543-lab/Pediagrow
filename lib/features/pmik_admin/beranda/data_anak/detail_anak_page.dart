import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/storage_service.dart';
import '../../../../models/child_model.dart';
import '../../../../shared/widgets/child_avatar.dart';
import '../../../../models/user_model.dart';
import 'pilih_anak_button_sheet.dart';
import 'superadmin_grafik_page.dart';
import 'tab_detail_pasien/resume_medis/daftar_resume_medis_page.dart';
import 'detail_pengguna_page.dart';
import '../../../../widgets/data_orangtua_logo.dart';

/// Halaman Data Pasien Anak untuk POV Admin.
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
  static const Color _colorLabelGrey = Color(0xFF667781);
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
    return StorageService.buildImageWidget(
      imagePath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: fallback,
      errorWidget: fallback,
    );
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

  Future<void> _navigateToDataOrangtua() async {
    UserModel? userToOpen = _parentUser;
    if (userToOpen == null || userToOpen.name.isEmpty || userToOpen.name == 'Orang Tua' || userToOpen.name == 'Orang Tua Pasien') {
      try {
        final db = FirebaseFirestore.instance;
        if (_currentChild.ownerId.isNotEmpty) {
          final doc = await db.collection('users').doc(_currentChild.ownerId).get();
          if (doc.exists && doc.data() != null) {
            userToOpen = UserModel.fromMap({...doc.data()!, 'id': doc.id});
          } else if (_currentChild.ownerId.contains('@')) {
            final q = await db.collection('users').where('email', isEqualTo: _currentChild.ownerId).limit(1).get();
            if (q.docs.isNotEmpty) {
              userToOpen = UserModel.fromMap({...q.docs.first.data(), 'id': q.docs.first.id});
            }
          }
        }
        if (userToOpen == null && _currentChild.parentIds.isNotEmpty) {
          for (final pid in _currentChild.parentIds) {
            final doc = await db.collection('users').doc(pid).get();
            if (doc.exists && doc.data() != null) {
              userToOpen = UserModel.fromMap({...doc.data()!, 'id': doc.id});
              break;
            }
          }
        }
        if (userToOpen == null && _currentChild.noKk != null && _currentChild.noKk!.trim().isNotEmpty) {
          final q = await db.collection('users').where('no_kk', isEqualTo: _currentChild.noKk!.trim()).limit(1).get();
          if (q.docs.isNotEmpty) {
            userToOpen = UserModel.fromMap({...q.docs.first.data(), 'id': q.docs.first.id});
          }
        }
      } catch (_) {}
    }

    userToOpen ??= UserModel(
      id: _currentChild.ownerId,
      name: 'Orang Tua Pasien',
      email: '-',
    );

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailPenggunaPage(user: userToOpen!),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Bar Fixed (56dp)
            _buildAppBar(),

            // 2. Tab Bar (Detail Anak | Ruang Obrolan)
            _buildTabBar(),

            // 3. Konten Tab (Scrollable)
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: 56,
      color: isDark ? const Color(0xFF1A2228) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                Icons.arrow_back,
                color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Data Pasien Anak',
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF),
            width: 1.0,
          ),
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
                      'Detail Anak',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        fontWeight: _selectedTabIndex == 0
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: _selectedTabIndex == 0
                            ? (isDark ? const Color(0xFFE9EDEF) : _colorTextBlack)
                            : (isDark ? const Color(0xFF8696A0) : const Color(0xFF667781)),
                      ),
                    ),
                  ),
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: _selectedTabIndex == 0
                          ? (isDark ? const Color(0xFF3985E7) : _colorPrimaryBlue)
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
                        Icon(
                          Icons.lock_rounded,
                          size: 15,
                          color: isDark ? const Color(0xFF8696A0) : const Color(0xFF8696A0),
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
                                ? (isDark ? const Color(0xFFE9EDEF) : _colorTextBlack)
                                : (isDark ? const Color(0xFF8696A0) : const Color(0xFF667781)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: _selectedTabIndex == 1
                          ? (isDark ? const Color(0xFF3985E7) : _colorPrimaryBlue)
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Usia akurat: "0 tahun 4 bulan 14 hari"
    String usiaText = _currentChild.ageDescription;
    if (_currentChild.birthDate != null) {
      usiaText = calculateAge(_currentChild.birthDate!).formatted;
    }
    if (usiaText.isEmpty) {
      usiaText = '0 tahun 4 bulan 14 hari';
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
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
                        color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      usiaText,
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF8696A0) : _colorLabelGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // B. Tiga Tombol Menu Berdampingan: "Grafik Pertumbuhan", "Resume Medis", & "Data Orangtua"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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

              // 2. Resume Medis (Menggunakan logo resmi data_pasien_logo.png)
              _buildFeatureButton(
                title: 'Resume\nMedis',
                imageAsset: 'assets/images/data_pasien_logo.png',
                onTap: _navigateToResumeMedis,
              ),

              // 3. Data Orangtua
              _buildFeatureButton(
                title: 'Data\nOrangtua',
                imageAsset: 'assets/images/data_orangtua_logo.png',
                customIcon: const DataOrangtuaLogo(size: 36),
                onTap: _navigateToDataOrangtua,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // C. Tabel "Biodata Anak" (Termasuk Lingkar Kepala)
          _buildBiodataAnakCard(),
        ],
      ),
    ),
    );
  }

  // ===========================================================================
  // FEATURE BUTTON KOTAK (GRAFIK PERTUMBUHAN & RESUME MEDIS)
  // Ukuran compact, proporsional, background biru muda lembut
  // ===========================================================================
  Widget _buildFeatureButton({
    required String title,
    String? imageAsset,
    IconData? icon,
    Widget? customIcon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget iconWidget;
    if (customIcon != null) {
      if (imageAsset != null && imageAsset.isNotEmpty) {
        iconWidget = Image.asset(
          imageAsset,
          width: 36,
          height: 36,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => customIcon,
        );
      } else {
        iconWidget = customIcon;
      }
    } else if (imageAsset != null && imageAsset.isNotEmpty) {
      iconWidget = Image.asset(
        imageAsset,
        width: 36,
        height: 36,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(
          Icons.insert_chart_outlined,
          size: 32,
          color: isDark ? const Color(0xFF3985E7) : _colorPrimaryBlue,
        ),
      );
    } else {
      iconWidget = Icon(
        icon ?? Icons.badge_outlined,
        size: 34,
        color: isDark ? const Color(0xFF3985E7) : _colorPrimaryBlue,
      );
    }

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
                color: isDark ? const Color(0xFF1A2228) : _colorButtonBg,
                borderRadius: BorderRadius.circular(16),
                border: isDark ? Border.all(color: const Color(0xFF2C363D), width: 1) : null,
              ),
              alignment: Alignment.center,
              child: iconWidget,
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
            color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
            height: 1.25,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // C. TABEL BIODATA ANAK
  // Menyajikan 10 field lengkap (format sama persis dengan tabel Biodata Orangtua):
  // 1. Nama Lengkap
  // 2. Nomor Kartu Keluarga (KK)
  // 3. NIK Anak
  // 4. Tanggal Lahir
  // 5. Jenis Kelamin
  // 6. Prematur (Ya, Minggu ke-XX / -)
  // 7. Berat Badan Saat Lahir (kg)
  // 8. Tinggi Badan Saat Lahir (cm)
  // 9. Lingkar Kepala Saat Lahir (cm)
  // 10. Alergi
  // ===========================================================================
  Widget _buildBiodataAnakCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

    final rows = <_TableChildRowData>[
      _TableChildRowData(
        label: 'Nama Lengkap',
        value: namaLengkap,
      ),
      _TableChildRowData(
        label: 'Nomor Kartu Keluarga (KK)',
        value: child.noKk?.isNotEmpty == true ? child.noKk! : '-',
      ),
      _TableChildRowData(
        label: 'NIK Anak',
        value: child.nik?.isNotEmpty == true ? child.nik! : '-',
      ),
      _TableChildRowData(
        label: 'Tanggal Lahir',
        value: tanggalLahir,
      ),
      _TableChildRowData(
        label: 'Jenis Kelamin',
        value: jenisKelamin,
      ),
      _TableChildRowData(
        label: 'Prematur',
        value: prematur,
      ),
      _TableChildRowData(
        label: 'Berat Badan Saat Lahir (kg)',
        value: bbLahir,
      ),
      _TableChildRowData(
        label: 'Tinggi Badan Saat Lahir (cm)',
        value: tbLahir,
      ),
      _TableChildRowData(
        label: 'Lingkar Kepala Saat Lahir (cm)',
        value: lkLahir,
      ),
      _TableChildRowData(
        label: 'Alergi',
        value: alergi,
      ),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : const Color(0xFFD6E4FF),
          width: 1.5,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card: Judul
          Text(
            'Biodata Anak',
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
            ),
          ),

          const SizedBox(height: 14),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF),
          ),
          const SizedBox(height: 14),

          // Baris-baris Data Key-Value
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: 10),
              Divider(
                height: 1,
                thickness: 0.7,
                color: isDark
                    ? const Color(0xFF242E35)
                    : const Color(0xFFF1F5F9),
              ),
              const SizedBox(height: 10),
            ],
            _buildTableRow(rows[i]),
          ],
        ],
      ),
    );
  }

  /// Baris dalam tabel biodata anak: dua kolom (label di kiri, nilai di kanan)
  Widget _buildTableRow(_TableChildRowData item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 4),
        SizedBox(
          width: 140,
          child: Text(
            item.label,
            style: GoogleFonts.lato(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF8696A0) : _colorLabelGrey,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.value,
            style: GoogleFonts.lato(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
            ),
          ),
        ),
      ],
    );
  }
  // ===========================================================================
  // 5. KONTEN TAB "RUANG OBROLAN" (TERKUNCI)
  // ===========================================================================
  Widget _buildRuangObrolanLockedContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF242E35) : const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_rounded,
              size: 36,
              color: Color(0xFF8696A0),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ruang Obrolan Terkunci',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFE9EDEF) : _colorTextBlack,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ruang obrolan konsultasi dengan orang tua pasien hanya dapat diakses oleh dokter dan saat sesi konsultasi sedang aktif.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 13,
              color: isDark ? const Color(0xFF8696A0) : _colorLabelGrey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableChildRowData {
  final String label;
  final String value;

  _TableChildRowData({
    required this.label,
    required this.value,
  });
}
