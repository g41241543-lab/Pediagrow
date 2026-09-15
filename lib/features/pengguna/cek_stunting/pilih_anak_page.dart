import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/child_service.dart';
import '../../../models/child_model.dart';
import 'form_cek_stunting_page.dart';

/// Helper function global untuk menghitung umur anak secara presisi kalender
/// (tahun, bulan, hari). Tidak membagi selisih hari dengan 365 agar
/// perhitungan bulan dan hari tetap akurat.
String calculateAge(DateTime birthDate, [DateTime? referenceDate]) {
  final now = referenceDate ?? DateTime.now();
  int years = now.year - birthDate.year;
  int months = now.month - birthDate.month;
  int days = now.day - birthDate.day;

  if (days < 0) {
    // Ambil jumlah hari di bulan sebelumnya
    final prevMonth = DateTime(now.year, now.month, 0);
    days += prevMonth.day;
    months -= 1;
  }

  if (months < 0) {
    years -= 1;
    months += 12;
  }

  return '$years tahun $months bulan $days Hari';
}

/// Halaman & Widget Pilih Anak untuk Cek Stunting PediaGrow.
///
/// Menggunakan latar belakang transparan sehingga halaman Beranda tetap terlihat
/// di belakangnya tanpa berganti atau melompat. Memberikan efek fade overlay 50%
/// dan animasi slide-up card berdurasi 350 ms secara halus.
class PilihAnakPage extends StatefulWidget {
  /// Daftar profil anak dari ChildService.
  /// Jika null, akan mengambil dari ChildService secara otomatis.
  final List<ChildModel>? children;

  /// Callback opsional saat salah satu profil anak dipilih
  final ValueChanged<ChildModel>? onChildSelected;

  /// Callback opsional ketika daftar anak kosong
  final VoidCallback? onAddChild;

  /// Callback opsional ketika tombol cancel (X) atau overlay ditekan
  final VoidCallback? onCancel;

  const PilihAnakPage({
    super.key,
    this.children,
    this.onChildSelected,
    this.onAddChild,
    this.onCancel,
  });

  /// Menampilkan snackbar warning merah jika pengguna belum memiliki profil anak.
  static void showWarningNoChild(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Silahkan isi profil anak terlebih dahulu!',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFB13535),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Menampilkan bottom sheet Cek Stunting secara transparan langsung di atas
  /// halaman Beranda yang sedang aktif.
  ///
  /// Jika pengguna belum memiliki profil anak, request ditolak dan ditampilkan
  /// warning "Silahkan isi profil anak terlebih dahulu!".
  static Future<void> show(
    BuildContext context, {
    List<ChildModel>? children,
    ValueChanged<ChildModel>? onChildSelected,
    VoidCallback? onAddChild,
  }) async {
    // Selalu ambil data real dari ChildService
    final effectiveChildren = children ?? ChildService().children;

    // Jika pengguna belum memiliki profil anak (kosong)
    if (effectiveChildren.isEmpty) {
      showWarningNoChild(context);
      return;
    }

    // Buka route transparan (halaman Beranda tetap terlihat di belakangnya)
    await Navigator.of(context).push(
      route(
        children: effectiveChildren,
        onChildSelected: onChildSelected,
        onAddChild: onAddChild,
      ),
    );
  }

  /// PageRouteBuilder transparan dengan durasi animasi 350 ms
  static Route<ChildModel?> route({
    List<ChildModel>? children,
    ValueChanged<ChildModel>? onChildSelected,
    VoidCallback? onAddChild,
    VoidCallback? onCancel,
  }) {
    return PageRouteBuilder<ChildModel?>(
      opaque: false, // Beranda tetap tampil di belakang
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) {
        return PilihAnakPage(
          children: children,
          onChildSelected: onChildSelected,
          onAddChild: onAddChild,
          onCancel: onCancel,
        );
      },
    );
  }

  @override
  State<PilihAnakPage> createState() => _PilihAnakPageState();
}

class _PilihAnakPageState extends State<PilihAnakPage>
    with SingleTickerProviderStateMixin {
  static const Color colorPrimaryBlue = Color(0xFF4B83D6);
  static const Color colorTextBlack = Color(0xFF000000);
  static const Color colorDividerGrey = Color(0xFFC5C5C5);

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String? _tappedChildId;
  late List<ChildModel> _childList;

  @override
  void initState() {
    super.initState();

    // Selalu ambil dari ChildService jika tidak ada children yang diteruskan
    _childList = widget.children ?? ChildService().children;

    // Jika daftar anak kosong, tolak dan tampilkan warning
    if (_childList.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pop();
        PilihAnakPage.showWarningNoChild(context);
      });
    }

    // Durasi animasi 350 ms sesuai permintaan
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 350),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    // Jalankan animasi slide-up secara lambat dan halus
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Menutup bottom sheet dengan animasi slide-down 350 ms dan fade-out,
  /// lalu kembali ke halaman Beranda tanpa mengubah rute latar belakang.
  void _dismissAndPop() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    }
    _animController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  /// Memilih profil anak, memberikan feedback visual singkat,
  /// lalu menutup card ke bawah dengan animasi 350 ms dan berpindah ke form_cek_stunting_page.dart
  void _onSelectChild(ChildModel child) async {
    setState(() => _tappedChildId = child.id);

    // Feedback visual singkat
    await Future.delayed(const Duration(milliseconds: 140));

    // Animasi slide-down dengan durasi yang sama (350 ms)
    await _animController.reverse();

    if (!mounted) return;

    if (widget.onChildSelected != null) {
      Navigator.of(context).pop();
      widget.onChildSelected!(child);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FormCekStuntingPage(child: child),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _dismissAndPop();
      },
      child: Scaffold(
        // Background transparan agar Beranda asli tetap terlihat utuh di belakang
        // (PageRouteBuilder menggunakan opaque: false sehingga halaman Beranda
        //  tetap dapat dilihat penuh di belakang overlay hitam 50%)
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // -----------------------------------------------------------------
            // 1. FADE OVERLAY BERWARNA HITAM 50% TRANSPARANSI
            //    Menutupi halaman Beranda secara halus
            // -----------------------------------------------------------------
            FadeTransition(
              opacity: _fadeAnimation,
              child: GestureDetector(
                onTap: _dismissAndPop,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withValues(alpha: 0.50),
                ),
              ),
            ),

            // -----------------------------------------------------------------
            // 2. BOTTOM SHEET CARD SLIDE-UP DARI BAWAH (350 ms)
            // -----------------------------------------------------------------
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildBottomSheetCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BOTTOM SHEET CARD
  // ===========================================================================

  Widget _buildBottomSheetCard() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris Judul "Cek Stunting" & Tombol 'X' / Cancel
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Cek Stunting',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorTextBlack,
                    letterSpacing: -0.2,
                  ),
                ),
                GestureDetector(
                  onTap: _dismissAndPop,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: colorTextBlack,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),

            // Teks Subtitle "Pilih Profil Anak"
            Text(
              'Pilih Profil Anak',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorTextBlack,
              ),
            ),

            const SizedBox(height: 12),

            // Garis Pembatas (Divider) Warna #C5C5C5 Setebal 1 dp
            Container(
              width: double.infinity,
              height: 1,
              color: colorDividerGrey,
            ),

            const SizedBox(height: 6),

            // Daftar Profil Anak Dinamis
            _buildChildrenList(),
          ],
        ),
      ),
    );
  }

  /// Menampilkan daftar profil anak
  Widget _buildChildrenList() {
    if (_childList.isEmpty) {
      return const SizedBox.shrink();
    }

    // Kondisi 1 Anak: Cukup 1 profil tanpa divider
    if (_childList.length == 1) {
      return _buildChildRow(_childList.first);
    }

    // Kondisi 2 Anak: 2 profil dengan divider di antara profil (Sesuai Gambar)
    if (_childList.length == 2) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildChildRow(_childList[0]),
          Container(
            width: double.infinity,
            height: 1,
            color: colorDividerGrey,
          ),
          _buildChildRow(_childList[1]),
        ],
      );
    }

    // Kondisi >2 Anak: Area daftar anak scrollable secara vertikal,
    // ukuran dan posisi card tetap stabil di bagian bawah
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 250,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: _childList.length,
        separatorBuilder: (context, index) => Container(
          width: double.infinity,
          height: 1,
          color: colorDividerGrey,
        ),
        itemBuilder: (context, index) {
          return _buildChildRow(_childList[index]);
        },
      ),
    );
  }

  /// Satu baris profil anak yang dapat ditekan seluruhnya
  Widget _buildChildRow(ChildModel child) {
    final isTapped = _tappedChildId == child.id;
    final isGirl = child.gender.toLowerCase().contains('perempuan');

    // Umur dihitung otomatis berdasarkan tanggal lahir
    final String ageString = child.birthDate != null
        ? calculateAge(child.birthDate!)
        : child.ageDescription;

    return AnimatedScale(
      scale: isTapped ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _onSelectChild(child),
          splashColor: colorPrimaryBlue.withValues(alpha: 0.12),
          highlightColor: colorPrimaryBlue.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar Bulat (Pink untuk Perempuan, Biru Langit untuk Laki-Laki)
                _buildBabyAvatar(isGirl),

                const SizedBox(width: 14),

                // Nama & Umur Anak
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nama Anak (Lato 18, Bold, #000000)
                      Text(
                        child.name,
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorTextBlack,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      // Umur Anak (Lato 18, Normal, #000000)
                      Text(
                        ageString,
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                          color: colorTextBlack,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Ikon Arrow di Kanan dalam Lingkaran Abu-Abu Lembut
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF1E293B),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Avatar lingkaran bergambar wajah ceria anak
  Widget _buildBabyAvatar(bool isGirl) {
    final bgColor = isGirl ? const Color(0xFFFFE2E2) : const Color(0xFFDCEEFE);
    final borderColor =
        isGirl ? const Color(0xFFFCA5A5) : const Color(0xFF93C5FD);

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(36, 36),
          painter: CuteBabyFacePainter(isGirl: isGirl),
        ),
      ),
    );
  }
}

// =============================================================================
// CUSTOM PAINTER: WAJAH CERIA ANAK
// =============================================================================

class CuteBabyFacePainter extends CustomPainter {
  final bool isGirl;

  CuteBabyFacePainter({required this.isGirl});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final blushPaint = Paint()
      ..color = isGirl
          ? const Color(0xFFFB7185).withValues(alpha: 0.5)
          : const Color(0xFF60A5FA).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Lingkaran kepala
    final headCenter = Offset(w * 0.5, h * 0.52);
    final headRadius = w * 0.38;

    // Telinga Kiri & Kanan
    canvas.drawCircle(Offset(w * 0.12, h * 0.52), 4.5, strokePaint);
    canvas.drawCircle(Offset(w * 0.88, h * 0.52), 4.5, strokePaint);

    // Garis Kepala
    canvas.drawCircle(headCenter, headRadius, strokePaint);

    // Rambut Bayi
    final hairPath = Path()
      ..moveTo(w * 0.38, h * 0.18)
      ..cubicTo(w * 0.42, h * 0.05, w * 0.58, h * 0.05, w * 0.62, h * 0.18);
    canvas.drawPath(hairPath, strokePaint);

    // Mata Kiri & Kanan
    final leftEye = Path()
      ..moveTo(w * 0.32, h * 0.46)
      ..quadraticBezierTo(w * 0.38, h * 0.41, w * 0.44, h * 0.46);
    canvas.drawPath(leftEye, strokePaint..strokeWidth = 2.2);

    final rightEye = Path()
      ..moveTo(w * 0.56, h * 0.46)
      ..quadraticBezierTo(w * 0.62, h * 0.41, w * 0.68, h * 0.46);
    canvas.drawPath(rightEye, strokePaint);

    strokePaint.strokeWidth = 2.0;

    // Pipi Merah Merona
    canvas.drawCircle(Offset(w * 0.28, h * 0.55), 3.5, blushPaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.55), 3.5, blushPaint);

    // Hidung mungil
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.54),
      1.2,
      Paint()..color = const Color(0xFF1E293B),
    );

    // Senyuman Ceria
    final smilePath = Path()
      ..moveTo(w * 0.40, h * 0.64)
      ..quadraticBezierTo(w * 0.50, h * 0.76, w * 0.60, h * 0.64);
    canvas.drawPath(smilePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
