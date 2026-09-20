import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/child_service.dart';
import '../../models/child_model.dart';
import 'pertumbuhan_grafik_page.dart';
import '../../shared/widgets/pedia_banner.dart';

/// Helper function global untuk menghitung umur anak secara presisi kalender
/// dalam format lengkap "X tahun Y bulan Z hari".
String calculateAgeString(DateTime birthDate, [DateTime? referenceDate]) {
  final now = referenceDate ?? DateTime.now();
  int years = now.year - birthDate.year;
  int months = now.month - birthDate.month;
  int days = now.day - birthDate.day;

  if (days < 0) {
    final prevMonth = DateTime(now.year, now.month, 0);
    days += prevMonth.day;
    months -= 1;
  }

  if (months < 0) {
    years -= 1;
    months += 12;
  }

  return '$years tahun $months bulan $days hari';
}

/// Bottom Sheet transparan slide dari bawah ke atas berjudul
/// "Grafik Tumbuh - Pilih Profil Anak".
///
/// Latar belakang Beranda tetap terlihat di baliknya dengan overlay hitam 50%.
class PilihAnakGrafikPage extends StatefulWidget {
  final List<ChildModel>? children;
  final ValueChanged<ChildModel>? onChildSelected;
  final VoidCallback? onCancel;

  const PilihAnakGrafikPage({
    super.key,
    this.children,
    this.onChildSelected,
    this.onCancel,
  });

  /// Menampilkan banner peringatan jika belum ada profil anak
  static void showWarningNoChild(BuildContext context) {
    PediaBanner.showError(
      context,
      message: 'Silahkan isi profil anak terlebih dahulu!',
    );
  }

  /// Menampilkan bottom sheet slide-up langsung di atas Beranda
  static Future<void> show(
    BuildContext context, {
    List<ChildModel>? children,
    ValueChanged<ChildModel>? onChildSelected,
  }) async {
    final effectiveChildren = children ?? ChildService().children;

    if (effectiveChildren.isEmpty) {
      showWarningNoChild(context);
      return;
    }

    await Navigator.of(context).push(
      route(
        children: effectiveChildren,
        onChildSelected: onChildSelected,
      ),
    );
  }

  /// PageRouteBuilder transparan dengan animasi slide-up halus (350 ms)
  static Route<ChildModel?> route({
    List<ChildModel>? children,
    ValueChanged<ChildModel>? onChildSelected,
    VoidCallback? onCancel,
  }) {
    return PageRouteBuilder<ChildModel?>(
      opaque: false, // Beranda tetap tampil di belakang
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) {
        return PilihAnakGrafikPage(
          children: children,
          onChildSelected: onChildSelected,
          onCancel: onCancel,
        );
      },
    );
  }

  @override
  State<PilihAnakGrafikPage> createState() => _PilihAnakGrafikPageState();
}

class _PilihAnakGrafikPageState extends State<PilihAnakGrafikPage>
    with SingleTickerProviderStateMixin {
  static const Color colorPrimaryBlue = Color(0xFF3985E7);
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
    _childList = widget.children ?? ChildService().children;

    if (_childList.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pop();
        PilihAnakGrafikPage.showWarningNoChild(context);
      });
    }

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

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

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

  void _onSelectChild(ChildModel child) async {
    setState(() => _tappedChildId = child.id);

    // Set child yang dipilih sebagai active child di ChildService
    ChildService().setActiveChild(child);

    // Efek feedback singkat
    await Future.delayed(const Duration(milliseconds: 120));

    // Animasi slide-down
    await _animController.reverse();

    if (!mounted) return;

    if (widget.onChildSelected != null) {
      Navigator.of(context).pop();
      widget.onChildSelected!(child);
    } else {
      // Tutup modal dan arahkan ke Halaman Pertumbuhan (Grafik)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PertumbuhanGrafikPage(child: child),
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
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // 1. Overlay Hitam 50% Transparansi (Tappable untuk dismiss)
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

            // 2. Bottom Sheet Card Slide-Up dari bawah
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
            // Header Bar: Judul "Grafik Tumbuh" & Tombol 'X'
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Grafik Tumbuh',
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

            // Subtitle "Pilih Profil Anak"
            Text(
              'Pilih Profil Anak',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorTextBlack,
              ),
            ),

            const SizedBox(height: 12),

            // Divider setebal 1 dp warna #C5C5C5
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

  Widget _buildChildrenList() {
    if (_childList.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_childList.length == 1) {
      return _buildChildRow(_childList.first);
    }

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

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 280,
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

  Widget _buildChildRow(ChildModel child) {
    final isTapped = _tappedChildId == child.id;
    final isGirl = child.gender.toLowerCase().contains('perempuan');

    final String ageString = child.birthDate != null
        ? calculateAgeString(child.birthDate!)
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
            padding:
                const EdgeInsets.symmetric(vertical: 14.0, horizontal: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar Bulat (Pink untuk Perempuan, Biru Langit untuk Laki-Laki)
                _buildBabyAvatar(isGirl, child.photoUrl),

                const SizedBox(width: 14),

                // Nama & Usia Anak
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                      Text(
                        ageString,
                        style: GoogleFonts.lato(
                          fontSize: 15,
                          fontWeight: FontWeight.normal,
                          color: const Color(0xFF475569),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Ikon panah ">" di ujung kanan tiap item
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF7F7F7F),
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBabyAvatar(bool isGirl, String? photoUrl) {
    final bgColor = isGirl ? const Color(0xFFFFD8E4) : const Color(0xFFD6EEFF);
    final iconColor = isGirl ? const Color(0xFFE83D84) : const Color(0xFF2B7AE8);

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: iconColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.child_care_rounded,
          color: iconColor,
          size: 26,
        ),
      ),
    );
  }
}
