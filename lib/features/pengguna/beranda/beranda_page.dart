import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/child_service.dart';
import '../../../models/child_model.dart';
import 'notifikasi_page.dart';
import '../../../core/services/notification_service.dart';
import '../profil_anak/tambah_anak_page.dart';
import '../cek_stunting/pilih_anak_page.dart';
import '../grafik_pertumbuhan/pilih_anak_grafik_page.dart';
import '../mpasi/daftar_resep_page.dart';
import '../artikel/artikel_kesehatan_page.dart';
import '../fasyankes/lokasi_fasyankes_page.dart';
import '../game_edukasi/game_mulai_page.dart';
import '../konsultasi/daftar_dokter_page.dart';
import '../riwayat_konsultasi/daftar_riwayat_page.dart';
import '../profil/menu_profil_page.dart';

/// Halaman Beranda Pengguna PediaGrow.
///
/// Ditampilkan setelah login berhasil untuk pengguna yang BELUM memiliki profil anak.
/// Halaman scrollable secara penuh dengan Navigation Bar tetap (fixed di Scaffold).
class BerandaPage extends StatefulWidget {
  final bool showAddSuccessSnackbar;
  const BerandaPage({super.key, this.showAddSuccessSnackbar = false});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage>
    with SingleTickerProviderStateMixin {
  int _selectedNavIndex = 0;

  late AnimationController _ellipseController;
  late Animation<double> _ellipsePulse;
  late Animation<double> _cloudDrift;
  late Animation<double> _cloudFloat;

  @override
  void initState() {
    super.initState();

    if (widget.showAddSuccessSnackbar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profil anak berhasil ditambahkan',
              style: GoogleFonts.lato(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      });
    }

    _ellipseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _ellipsePulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _ellipseController, curve: Curves.easeInOut),
    );

    _cloudDrift = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _ellipseController, curve: Curves.easeInOut),
    );
    _cloudFloat = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _ellipseController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ellipseController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget page) {
    if (page is PilihAnakPage) {
      PilihAnakPage.show(context, children: page.children);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _onNavTap(int index) {
    if (index == _selectedNavIndex) return;
    switch (index) {
      case 0:
        setState(() => _selectedNavIndex = 0);
        break;
      case 1:
        _navigateTo(const DaftarDokterPage());
        break;
      case 2:
        _navigateTo(const DaftarRiwayatPage());
        break;
      case 3:
        _navigateTo(const MenuProfilPage());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------------------------------------------
            // 1. AREA BIRU SEAMLESS (Header + "Profil Anak" + Card MomDad)
            //    Satu container gradient menerus dari paling atas layar
            // -------------------------------------------------------------
            _buildSeamlessBlueArea(context),

            // -------------------------------------------------------------
            // 2. KONTEN PUTIH (6 Card Menu & Card PediaGrow)
            // -------------------------------------------------------------
            _buildWhiteContentSection(context),

            const SizedBox(height: 20), // jarak kecil sebelum ilustrasi footer
            // -------------------------------------------------------------
            // 3. ILUSTRASI PENUTUP FOOTER (Full-Bleed, Menempel ke Nav Bar)
            // -------------------------------------------------------------
            _buildFooterIllustration(),
          ],
        ),
      ),
      // Navigation Bar tetap di posisi Scaffold
      bottomNavigationBar: _buildFixedNavBar(),
    );
  }

  // ===================================================================
  // 1. AREA BIRU SEAMLESS
  // Gradient menerus dari atas layar (termasuk Safe Area).
  // Total tinggi sekitar 270-290dp.
  // ===================================================================
  Widget _buildSeamlessBlueArea(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5BA4F5), // Biru lebih terang di kiri-atas
            Color(0xFF4592F0),
            Color(0xFF2872E5), // Biru lebih pekat di kanan-bawah
          ],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // -----------------------------------------------------------
          // DIRECT NON-POSITIONED CHILD PERTAMA: Column konten utama
          // Memberi constraint ukuran alami tanpa loose constraint issue
          // -----------------------------------------------------------
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Safe area top + Header (56dp)
              SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // "Hai, Susanti" (Lato Bold 24, #FFFFFF)
                        Text(
                          'Hai, Susanti',
                          style: GoogleFonts.lato(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        // Lingkaran Notifikasi (31×31, #FFFFFF, 12dp dari kanan) + badge angka
                        ValueListenableBuilder<int>(
                          valueListenable:
                              NotificationService().unreadCountNotifier,
                          builder: (context, unreadCount, _) {
                            return GestureDetector(
                              onTap: () => _navigateTo(const NotifikasiPage()),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 31,
                                    height: 31,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x1F000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.notifications_none_rounded,
                                      color: Color(0xFF1E293B),
                                      size: 19,
                                    ),
                                  ),
                                  // Badge angka notifikasi belum dibaca
                                  if (unreadCount > 0)
                                    Positioned(
                                      top: -4,
                                      right: -4,
                                      child: Container(
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE53E3E),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.white, width: 1),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          unreadCount > 9
                                              ? '9+'
                                              : '$unreadCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            height: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Tulisan "Profil Anak" (Lato Regular 20, #FFFFFF)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  'Profil Anak',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    color: Colors.white,
                  ),
                ),
              ),

              // Jarak margin-top dari teks "Profil Anak" ke card: 16dp
              const SizedBox(height: 16),

              // Card MomDad atau Kartu Biodata Anak Real-Time
              ValueListenableBuilder<List<ChildModel>>(
                valueListenable: ChildService().childrenNotifier,
                builder: (context, children, _) {
                  if (children.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildMomDadCard(context),
                    );
                  }
                  return _buildChildrenHorizontalList(context, children);
                },
              ),

              // Jarak ±20-30dp dari bottom card MomDad ke batas transisi biru→putih
              const SizedBox(height: 24),
            ],
          ),

          // -----------------------------------------------------------
          // DEKORASI: 2 Elips Blur di Kiri Atas
          // -----------------------------------------------------------
          AnimatedBuilder(
            animation: _ellipsePulse,
            builder: (context, child) {
              final scale = _ellipsePulse.value;
              return Positioned(
                top: -45 * scale,
                left: -45 * scale,
                child: IgnorePointer(
                  child: _BlurredEllipse(
                    width: 175 * scale,
                    height: 175 * scale,
                    color: Colors.white.withValues(alpha: 0.05),
                    blurSigma: 22,
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _ellipsePulse,
            builder: (context, child) {
              final scale = _ellipsePulse.value;
              return Positioned(
                top: -15 * scale,
                left: -15 * scale,
                child: IgnorePointer(
                  child: _BlurredEllipse(
                    width: 115 * scale,
                    height: 115 * scale,
                    color: Colors.white.withValues(alpha: 0.10),
                    blurSigma: 14,
                  ),
                ),
              );
            },
          ),

          // -----------------------------------------------------------
          // DEKORASI AWAN BERGERAK / MENGAPUNG LEMBUT (Cloud Animations)
          // -----------------------------------------------------------
          // Awan 1 di Kanan Atas (di samping/belakang ikon notifikasi)
          AnimatedBuilder(
            animation: _ellipseController,
            builder: (context, child) {
              return Positioned(
                top: 24 + _cloudFloat.value,
                right: -10 + _cloudDrift.value,
                child: IgnorePointer(
                  child: _PuffyCloud(
                    width: 100,
                    height: 46,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
              );
            },
          ),
          // Awan 2 di Tengah Kiri (di atas teks "Profil Anak")
          AnimatedBuilder(
            animation: _ellipseController,
            builder: (context, child) {
              return Positioned(
                top: 70 - _cloudFloat.value,
                left: 115 - (_cloudDrift.value * 0.75),
                child: IgnorePointer(
                  child: _PuffyCloud(
                    width: 76,
                    height: 34,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              );
            },
          ),
          // Awan 3 di Kanan Bawah (mengapung lembut di belakang kartu)
          AnimatedBuilder(
            animation: _ellipseController,
            builder: (context, child) {
              return Positioned(
                bottom: 8 + (_cloudFloat.value * 0.6),
                right: 25 + (_cloudDrift.value * 0.5),
                child: IgnorePointer(
                  child: _PuffyCloud(
                    width: 88,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // CARD MOMDAD (Belum Punya Profil Anak)
  // Dimensi: lebar penuh sejajar margin 12dp x height 120, warna #FFFFFF, corner radius 15
  // ===================================================================
  Widget _buildMomDadCard(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ilustrasi Bayi Tidur di Atas Awan
          SizedBox(
            width: 72,
            height: 72,
            child: Image.asset(
              'assets/images/baby_cloud_illustration.jpg',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.child_friendly_rounded,
                size: 54,
                color: Color(0xFF3985E7),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Teks Informasi & Tombol Tambah Anak
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Mom Dad belum punya profil anak" (Lato Regular 15, #7F7F7F)
                Text(
                  'Mom and Dad belum punya profil anak',
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF7F7F7F),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Tombol "+ Tambah Anak" (width 232 x height 35, radius 10, #3985E7)
                GestureDetector(
                  onTap: () => _navigateTo(const TambahAnakPage()),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 232),
                    height: 35,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3985E7),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3985E7)
                              .withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '+ Tambah Anak',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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

  // ===================================================================
  // KARTU BIODATA ANAK (Real-Time saat sudah ada profil anak)
  // Horizontal Scrollable Cards sesuai desain:
  // - Margin kanan kiri list: 16 dp
  // - Jika perempuan: Banner & avatar berwarna soft pink/peach (#FDE8E4 / #FFDFD9)
  // - Jika laki-laki: Banner & avatar berwarna soft sky blue (#DDF0FF / #CFE8FF)
  // - Jumlah kartu sesuai jumlah profil anak pengguna
  // - Card terakhir adalah card "Tambah Profil Anak"
  // ===================================================================
  Widget _buildChildrenHorizontalList(
      BuildContext context, List<ChildModel> children) {
    final activeChild = ChildService().activeChild ?? children.first;

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: children.length + 1, // semua anak + 1 card tambah anak
        separatorBuilder: (_, __) => const SizedBox(width: 14.0),
        itemBuilder: (context, index) {
          if (index < children.length) {
            final child = children[index];
            final isActive = child.id == activeChild.id;
            return _buildChildCard(context, child, isActive);
          } else {
            return _buildAddChildCard(context);
          }
        },
      ),
    );
  }

  /// Kartu profil per anak (Pink untuk Perempuan, Biru untuk Laki-laki)
  Widget _buildChildCard(
      BuildContext context, ChildModel child, bool isActive) {
    final hasPhoto = child.photoUrl != null &&
        child.photoUrl!.isNotEmpty &&
        File(child.photoUrl!).existsSync();
    final isMale = child.gender.toLowerCase().contains('laki');

    // Warna Banner & Avatar berdasarkan Jenis Kelamin
    final bannerColor =
        isMale ? const Color(0xFFDDF0FF) : const Color(0xFFFDE8E4);
    final avatarBgColor =
        isMale ? const Color(0xFFCFE8FF) : const Color(0xFFFFDFD9);

    return Container(
      width: 200,
      height: 128,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isActive
            ? Border.all(
                color: isMale
                    ? const Color(0xFF60A5FA)
                    : const Color(0xFFF472B6),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ChildService().setActiveChild(child);
            },
            child: Stack(
              children: [
                // 1. Top Colored Banner (Pink/Peach untuk Perempuan, Sky Blue untuk Laki-laki)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      color: bannerColor,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                  ),
                ),

                // 2. Avatar Anak (Posisi kiri atas, overlapping banner & white card)
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: avatarBgColor,
                      border: Border.all(
                        color: Colors.white,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: hasPhoto
                          ? Image.file(
                              File(child.photoUrl!),
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              'assets/images/default_baby_avatar.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const CustomPaint(
                                painter: _BabyFacePainter(
                                  outlineColor: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),

                // 3. Nama Anak, Usia, dan Tombol Panah Kanan
                Positioned(
                  left: 14,
                  right: 12,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nama Anak
                      Text(
                        child.name,
                        style: GoogleFonts.lato(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // Baris Usia & Tombol Chevron Kanan
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              _formatChildAge(child),
                              style: GoogleFonts.lato(
                                fontSize: 12.5,
                                fontWeight: FontWeight.normal,
                                color: const Color(0xFF334155),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFCBD5E1),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Card untuk menambahkan profil anak baru di akhir list
  Widget _buildAddChildCard(BuildContext context) {
    return Container(
      width: 160,
      height: 128,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateTo(const TambahAnakPage()),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEBF5FF),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tambah Profil\nAnak',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Memformat deskripsi usia anak agar ringkas (misal: "1 tahun 3 bulan", "0 tahun 4 bulan")
  String _formatChildAge(ChildModel child) {
    if (child.birthDate != null) {
      final now = DateTime.now();
      final birth = child.birthDate!;
      int years = now.year - birth.year;
      int months = now.month - birth.month;
      int days = now.day - birth.day;

      if (days < 0) {
        months -= 1;
      }
      if (months < 0) {
        years -= 1;
        months += 12;
      }

      if (years >= 0 && months >= 0) {
        return '$years tahun $months bulan';
      }
    }

    final desc = child.ageDescription;
    final match = RegExp(r'(\d+\s*tahun\s*\d+\s*bulan)').firstMatch(desc);
    if (match != null) {
      return match.group(1)!;
    }
    return desc;
  }

  // ===================================================================
  // 2. KONTEN PUTIH (6 Card Menu & Card PediaGrow)
  // Margin 12dp dari sisi kiri & kanan layar
  // ===================================================================
  Widget _buildWhiteContentSection(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 24, bottom: 20),
      child: Column(
        children: [
          // 6 Card Menu (lebar penuh sejajar margin 12dp)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _build6MenuGrid(context),
          ),

          const SizedBox(height: 24),

          // Card PediaGrow (lebar penuh identik dengan Card MomDad & Menu, margin 12dp)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildPediaGrowCard(),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // 6 CARD MENU
  // Warna #ECF6FF, dimensi 3 kolom sejajar presisi, corner radius 10
  // ===================================================================
  Widget _build6MenuGrid(BuildContext context) {
    return Column(
      children: [
        // Baris 1: Cek Stunting, Grafik Pertumbuhan, Resep MPASI
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildMenuItem(
                title: 'Cek\nStunting',
                imageAsset: 'assets/images/cek_stunting_logo.png',
                onTap: () => _navigateTo(const PilihAnakPage()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                title: 'Grafik\nPertumbuhan',
                imageAsset: 'assets/images/grafik_pertumbuhan_logo.png',
                onTap: () => _navigateTo(const PilihAnakGrafikPage()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                title: 'Resep\nMPASI',
                imageAsset: 'assets/images/resep_mpasi_logo.png',
                onTap: () => _navigateTo(const DaftarResepPage()),
                logoOffsetX: 2,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Baris 2: Artikel Kesehatan, Lokasi Fasyankes, Permainan
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildMenuItem(
                title: 'Artikel\nKesehatan',
                imageAsset: 'assets/images/artikel_kesehatan_logo.png',
                onTap: () => _navigateTo(const ArtikelKesehatanPage()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                title: 'Lokasi\nFasyankes',
                imageAsset: 'assets/images/lokasi_fasyankes_logo.png',
                onTap: () => _navigateTo(const LokasiFasyankesPage()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuItem(
                title: 'Permainan\n',
                imageAsset: 'assets/images/permainan_logo.png',
                onTap: () => _navigateTo(const GameMulaiPage()),
                logoOffsetX: 5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required String title,
    required String imageAsset,
    required VoidCallback onTap,
    double cardInset =
        6, // seberapa "dikecilkan" card-nya (kiri-kanan dalam kolom)
    double imageSize = 40, // ukuran logo, dikecilkan mengikuti card
    double logoOffsetX = 0, // geser logo ke kanan/kiri kalau logo tidak center
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Menu: dikecilkan via padding horizontal, tetap kotak (1:1)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: cardInset),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFECF6FF),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3985E7).withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Transform.translate(
                  offset: Offset(logoOffsetX, 0),
                  child: Image.asset(
                    imageAsset,
                    height: imageSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Judul Menu (Lato Regular 14, #000000)
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: const Color(0xFF000000),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // CARD PEDIAGROW
  // Warna #ECF6FF, dimensi lebar penuh (margin 12dp) x height 115, corner radius 10
  // Sisi kiri: ilustrasi bayi pediagrow
  // Sisi kanan: "PediaGrow" + Tagline
  // ===================================================================
  Widget _buildPediaGrowCard() {
    return Container(
      width: double.infinity,
      height: 115,
      decoration: BoxDecoration(
        color: const Color(0xFFECF6FF),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3985E7).withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ilustrasi Bayi PediaGrow (gambar 7)
          SizedBox(
            width: 84,
            height: 94,
            child: Image.asset(
              'assets/images/bayi_pediagrow_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.child_care_rounded,
                size: 50,
                color: Color(0xFF3985E7),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Teks PediaGrow & Tagline
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Pedia" (#4B83D6) & "Grow" (#3CC3A6) Baloo 2 Bold 18
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Pedia',
                        style: GoogleFonts.baloo2(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4B83D6),
                        ),
                      ),
                      TextSpan(
                        text: 'Grow',
                        style: GoogleFonts.baloo2(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3CC3A6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Tagline "Pantau Pertumbuhan, Cegah Stunting untuk Masa Depan" (Lato Regular 16, #000000)
                Text(
                  'Pantau Pertumbuhan,\nCegah Stunting untuk Masa Depan',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF000000),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // 3. ILUSTRASI FOOTER FULL-BLEED
  // 100% width layar, tanpa margin/padding, menempel langsung ke Nav Bar
  // ===================================================================
  Widget _buildFooterIllustration() {
    return SizedBox(
      width: double.infinity,
      child: Image.asset(
        'assets/images/beranda_landscape_footer.jpg',
        width: double.infinity,
        fit: BoxFit.fitWidth,
        alignment: Alignment.bottomCenter,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 100,
          color: const Color(0xFFD1FAE5),
          alignment: Alignment.center,
          child: const Icon(
            Icons.park_outlined,
            size: 44,
            color: Color(0xFF34D399),
          ),
        ),
      ),
    );
  }

  // ===================================================================
  // 4. NAVIGATION BAR (Fixed di Scaffold)
  // Warna #F2EDED, tinggi 68dp (range 65-70dp)
  // Beranda aktif: bulatan putih dengan ikon biru #72A9F4 di dalamnya
  // ===================================================================
  Widget _buildFixedNavBar() {
    final navItems = [
      _NavData(icon: Icons.home_rounded, label: 'Beranda'),
      _NavData(icon: Icons.question_answer_rounded, label: 'Konsultasi'),
      _NavData(icon: Icons.manage_search_rounded, label: 'Riwayat Konsultasi'),
      _NavData(icon: Icons.person_outline_rounded, label: 'Profil Ibu'),
    ];

    return Container(
      width: double.infinity,
      height: 68,
      decoration: const BoxDecoration(
        color: Color(0xFFF2EDED),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(navItems.length, (i) {
          final isSelected = i == _selectedNavIndex;
          final item = navItems[i];

          return GestureDetector(
            onTap: () => _onNavTap(i),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 80,
              height: 68,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected) ...[
                    // State aktif: lingkaran putih dengan icon biru #72A9F4
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        item.icon,
                        size: 24,
                        color: const Color(0xFF72A9F4),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ] else ...[
                    // State tidak aktif: icon & label abu-abu #9E9E9E
                    Icon(item.icon, size: 24, color: const Color(0xFF9E9E9E)),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// =====================================================================
// DATA MODELS & HELPER WIDGETS
// =====================================================================

class _NavData {
  final IconData icon;
  final String label;

  const _NavData({required this.icon, required this.label});
}

/// Widget elips dekoratif dengan efek Gaussian blur
class _BlurredEllipse extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double blurSigma;

  const _BlurredEllipse({
    required this.width,
    required this.height,
    required this.color,
    required this.blurSigma,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _BlurredEllipsePainter(color: color, blurSigma: blurSigma),
    );
  }
}

class _BlurredEllipsePainter extends CustomPainter {
  final Color color;
  final double blurSigma;

  const _BlurredEllipsePainter({required this.color, required this.blurSigma});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
    canvas.drawOval(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _BlurredEllipsePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.blurSigma != blurSigma;
}

/// CustomPainter untuk menggambar ilustrasi wajah bayi seperti pada desain kartu
class _BabyFacePainter extends CustomPainter {
  final Color outlineColor;
  const _BabyFacePainter({this.outlineColor = const Color(0xFF1E293B)});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.32;

    // Telinga Kiri & Kanan
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx - r - 2, cy + 1), radius: 5),
      math.pi / 2,
      math.pi,
      false,
      stroke,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx + r + 2, cy + 1), radius: 5),
      -math.pi / 2,
      math.pi,
      false,
      stroke,
    );

    // Bentuk Kepala / Lingkaran Wajah
    canvas.drawCircle(Offset(cx, cy + 1), r, stroke);

    // Rambut / Poni Bayi
    final hairPath = Path();
    hairPath.moveTo(cx - r * 0.85, cy - r * 0.2);
    hairPath.quadraticBezierTo(cx - r * 0.4, cy - r * 0.9, cx, cy - r * 0.3);
    hairPath.quadraticBezierTo(
        cx + r * 0.4, cy - r * 0.9, cx + r * 0.85, cy - r * 0.2);
    hairPath.quadraticBezierTo(cx + r * 0.5, cy - r * 1.15, cx, cy - r * 1.05);
    hairPath.quadraticBezierTo(cx - r * 0.5, cy - r * 1.15, cx - r * 0.85, cy - r * 0.2);
    hairPath.close();
    canvas.drawPath(hairPath, fill);

    // Mata Kiri & Kanan
    canvas.drawCircle(Offset(cx - 7, cy), 2.2, fill);
    canvas.drawCircle(Offset(cx + 7, cy), 2.2, fill);

    // Hidung
    final nosePath = Path();
    nosePath.moveTo(cx - 1.5, cy + 3.5);
    nosePath.quadraticBezierTo(cx, cy + 5, cx + 1.5, cy + 3.5);
    canvas.drawPath(nosePath, stroke..strokeWidth = 1.8);

    // Senyuman
    final smilePath = Path();
    smilePath.moveTo(cx - 5.5, cy + 7);
    smilePath.quadraticBezierTo(cx, cy + 11.5, cx + 5.5, cy + 7);
    canvas.drawPath(smilePath, stroke..strokeWidth = 2.0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget awan puffy dekoratif dengan efek lembut dan mengapung
class _PuffyCloud extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const _PuffyCloud({
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _PuffyCloudPainter(color: color),
    );
  }
}

class _PuffyCloudPainter extends CustomPainter {
  final Color color;
  const _PuffyCloudPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.height * 0.18);

    final w = size.width;
    final h = size.height;

    // Badan awan utama (ellips bawah)
    canvas.drawOval(
      Rect.fromLTWH(w * 0.1, h * 0.45, w * 0.8, h * 0.5),
      paint,
    );

    // Gundukan kiri
    canvas.drawOval(
      Rect.fromLTWH(w * 0.05, h * 0.18, w * 0.38, h * 0.5),
      paint,
    );

    // Gundukan tengah (lebih tinggi)
    canvas.drawOval(
      Rect.fromLTWH(w * 0.28, h * 0.0, w * 0.44, h * 0.58),
      paint,
    );

    // Gundukan kanan
    canvas.drawOval(
      Rect.fromLTWH(w * 0.55, h * 0.15, w * 0.38, h * 0.50),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _PuffyCloudPainter oldDelegate) =>
      oldDelegate.color != color;
}
