import 'package:flutter/material.dart';

import '../../../models/riwayat_konsultasi_model.dart';
import '../../../shared/widgets/pedia_bottom_nav_bar.dart';
import '../beranda/beranda_page.dart';
import 'detail_konsultasi_page.dart';
import 'widgets/riwayat_consultation_card.dart';
import 'widgets/riwayat_empty_state.dart';
import 'widgets/riwayat_header.dart';

/// Halaman "Riwayat Konsultasi" Pengguna PediaGrow.
///
/// Mendukung dua kondisi tampilan sesuai desain referensi:
/// 1. Kondisi Kosong (Empty State):
///    - Menampilkan ilustrasi folder 3D biru di tengah layar.
///    - Teks "Belum ada riwayat konsultasi" (Lato 16sp, #C5C5C5) berjarak 10dp.
///    - Ilustrasi pemandangan alam (IllustrationForestFooter) di bagian bawah.
/// 2. Kondisi Berisi Data (Populated State):
///    - Menampilkan daftar consultation card dengan margin 16dp dan jarak antar-kartu 12dp.
///    - Setiap kartu menampilkan foto dokter, nama dokter, nama anak, keluhan, badge "Selesai",
///      serta tanggal konsultasi rapi.
///    - Kartu dapat ditekan untuk membuka [DetailKonsultasiPage] dengan transisi animasi halus.
///    - Ilustrasi pemandangan alam (IllustrationForestFooter) di bagian bawah list.
///
/// Struktur halaman:
/// - Custom Header (56dp) di paling atas, permanen dan tidak ikut ter-scroll.
/// - Konten scrollable (ListView / SingleChildScrollView) bebas RenderFlex overflow.
/// - Scaffold.bottomNavigationBar permanen dengan menu "Riwayat Konsultasi" aktif (Index 2).
class DaftarRiwayatPage extends StatefulWidget {
  /// Opsional: daftar data awal untuk kemudahan pengujian state kosong maupun terisi
  final List<RiwayatKonsultasiModel>? initialRiwayatList;

  const DaftarRiwayatPage({super.key, this.initialRiwayatList});

  @override
  State<DaftarRiwayatPage> createState() => _DaftarRiwayatPageState();
}

class _DaftarRiwayatPageState extends State<DaftarRiwayatPage> {
  late List<RiwayatKonsultasiModel> _riwayatList;

  @override
  void initState() {
    super.initState();
    // Gunakan initialRiwayatList jika disediakan, jika tidak gunakan mockList default
    _riwayatList = widget.initialRiwayatList != null
        ? List.from(widget.initialRiwayatList!)
        : List.from(RiwayatKonsultasiModel.mockList);
  }

  /// Navigasi ke Halaman Detail Konsultasi dengan animasi transisi halus
  void _navigateToDetail(RiwayatKonsultasiModel riwayat) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DetailKonsultasiPage(riwayat: riwayat),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0.0),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  /// Penanganan tombol kembali pada header -> selalu kembali ke Beranda
  void _handleBack() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const BerandaPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        // 1. Custom Header permanen di paling atas
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: RiwayatHeader(
            title: 'Riwayat Konsultasi',
            onBackPressed: _handleBack,
          ),
        ),
        // 2. Konten Utama Scrollable
        body: SafeArea(
          top: false,
          bottom: false,
          child: _riwayatList.isEmpty
              ? _buildEmptyView()
              : _buildPopulatedView(),
        ),
        // 3. Bottom Navigation Bar permanen
        bottomNavigationBar: const PediaBottomNavBar(selectedIndex: 2),
      ),
    );
  }

  /// Tampilan Empty State ketika belum terdapat riwayat konsultasi
  Widget _buildEmptyView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // Area Tengah: Ilustrasi Folder & Teks Keterangan
                  const Expanded(child: Center(child: RiwayatEmptyState())),

                  // Ilustrasi Lanskap Hutan & Tenda (desain & peletakan persis beranda_page.dart)
                  _buildFooterIllustration(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Tampilan Daftar Kartu Konsultasi ketika data tersedia
  Widget _buildPopulatedView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16.0),

                  // Daftar Consultation Cards
                  ..._riwayatList.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: RiwayatConsultationCard(
                        riwayat: item,
                        onTap: () => _navigateToDetail(item),
                      ),
                    );
                  }),

                  // Spacer fleksibel: jika kartu sedikit, footer tetap menempel di bawah
                  // Jika kartu panjang, Spacer berukuran 0 dan footer berada tepat di bawah kartu terakhir
                  const Spacer(),

                  const SizedBox(height: 16.0),

                  // Ilustrasi Footer Landscape (sama persis seperti di beranda_page.dart)
                  _buildFooterIllustration(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Ilustrasi Footer Landscape Full-Bleed
  /// Mengikuti peletakan dan desain beranda_page.dart (BoxFit.fitWidth, tidak ada bagian terpotong)
  Widget _buildFooterIllustration() {
    return SizedBox(
      width: double.infinity,
      child: Image.asset(
        'assets/images/beranda_landscape_footer_fiks.png',
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
}
