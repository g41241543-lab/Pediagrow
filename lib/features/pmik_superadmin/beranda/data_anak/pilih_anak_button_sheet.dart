import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/child_model.dart';
import '../../../../models/user_model.dart';
import '../../../Grafik_Pertumbuhan/pertumbuhan_grafik_page.dart';
import 'detail_pengguna_page.dart';

// =============================================================================
// HELPER: Hitung umur anak secara akurat berdasarkan tanggal lahir
// Menggunakan kalender nyata (tahun → bulan → hari), bukan sekadar 365/30.
// =============================================================================

/// Representasi umur anak dalam format tahun, bulan, dan hari.
class ChildAge {
  final int years;
  final int months;
  final int days;

  const ChildAge({
    required this.years,
    required this.months,
    required this.days,
  });

  /// Teks umur lengkap: "X tahun Y bulan Z hari"
  String get formatted => '$years tahun $months bulan $days hari';
}

/// Menghitung umur anak secara akurat berdasarkan [birthDate] dan hari ini.
///
/// Algoritma ini memperhitungkan jumlah hari nyata per bulan dan tahun kabisat,
/// tidak hanya membagi selisih hari dengan 365 atau 30.
ChildAge calculateAge(DateTime birthDate) {
  final now = DateTime.now();
  int years = now.year - birthDate.year;
  int months = now.month - birthDate.month;
  int days = now.day - birthDate.day;

  // Koreksi hari negatif: mundur satu bulan dan tambahkan hari bulan sebelumnya
  if (days < 0) {
    months -= 1;
    final lastDayPrevMonth = DateTime(now.year, now.month, 0);
    days += lastDayPrevMonth.day;
  }

  // Koreksi bulan negatif: mundur satu tahun
  if (months < 0) {
    years -= 1;
    months += 12;
  }

  if (years < 0) years = 0;
  if (months < 0) months = 0;
  if (days < 0) days = 0;

  return ChildAge(years: years, months: months, days: days);
}

// =============================================================================
// PILIH ANAK BOTTOM SHEET
// =============================================================================

/// Modal bottom sheet "Pilih Profil Anak" dengan animasi slide-up smooth dan
/// backdrop overlay hitam 50%.
///
/// Dapat digunakan dari berbagai titik navigasi menggunakan [onChildSelected]
/// callback, sehingga tidak hardcode destinasi halaman tertentu.
///
/// Contoh penggunaan dari Beranda (Grafik Pertumbuhan):
/// ```dart
/// PilihAnakBottomSheet.showForGrafik(context);
/// ```
/// Atau dari Daftar Pengguna:
/// ```dart
/// PilihAnakBottomSheet.showForDetail(context, user: user, children: children);
/// ```
class PilihAnakBottomSheet extends StatefulWidget {
  /// Data akun pengguna / orang tua pemilik anak (opsional).
  final UserModel? user;

  /// Daftar anak yang ditampilkan.
  final List<ChildModel> children;

  /// Judul header (misal: 'Data Pengguna' atau 'Grafik Tumbuh').
  final String title;

  /// Subtitle header (default: 'Pilih Profil Anak').
  final String subtitle;

  /// Callback ketika salah satu profil anak dipilih.
  /// Bottom sheet sudah ditutup sebelum callback ini dipanggil.
  final void Function(ChildModel child)? onChildSelected;

  /// Callback ketika tombol "Tambah Profil Anak" ditekan (state kosong).
  final VoidCallback? onAddChild;

  const PilihAnakBottomSheet({
    super.key,
    this.user,
    required this.children,
    this.title = 'Data Pengguna',
    this.subtitle = 'Pilih Profil Anak',
    this.onChildSelected,
    this.onAddChild,
  });

  // ---------------------------------------------------------------------------
  // ENTRY POINT UTAMA — Callback kustom [onChildSelected]
  // ---------------------------------------------------------------------------
  static Future<void> show(
    BuildContext context, {
    UserModel? user,
    required List<ChildModel> children,
    String title = 'Data Pengguna',
    String subtitle = 'Pilih Profil Anak',
    void Function(ChildModel child)? onChildSelected,
    VoidCallback? onAddChild,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.50),
      backgroundColor: Colors.transparent,
      builder: (_) => PilihAnakBottomSheet(
        user: user,
        children: children,
        title: title,
        subtitle: subtitle,
        onChildSelected: onChildSelected,
        onAddChild: onAddChild,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ENTRY POINT SHORTCUT — Navigasi ke DetailPenggunaPage
  // Digunakan dari DaftarPenggunaPage saat memilih anak dari card pengguna.
  // ---------------------------------------------------------------------------
  static Future<void> showForDetail(
    BuildContext context, {
    required UserModel user,
    required List<ChildModel> children,
    VoidCallback? onAddChild,
  }) {
    return show(
      context,
      user: user,
      title: 'Data Pengguna',
      subtitle: 'Pilih Profil Anak',
      children: children,
      onAddChild: onAddChild,
      onChildSelected: (child) {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) =>
                DetailPenggunaPage(user: user, child: child),
            transitionsBuilder: (_, animation, __, childWidget) =>
                FadeTransition(opacity: animation, child: childWidget),
            transitionDuration: const Duration(milliseconds: 200),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // ENTRY POINT SHORTCUT — Navigasi ke PertumbuhanGrafikPage (Grafik Tumbuh)
  // Digunakan dari Beranda Superadmin menu "Grafik Pengguna" / "Grafik Pertumbuhan".
  // Jika [children] null, akan mengambil seluruh data anak dari Firestore.
  // ---------------------------------------------------------------------------
  static Future<void> showForGrafik(
    BuildContext context, {
    List<ChildModel>? children,
    UserModel? user,
    VoidCallback? onAddChild,
  }) async {
    List<ChildModel> childList = children ?? [];
    if (children == null) {
      try {
        final query =
            await FirebaseFirestore.instance.collection('children').get();
        childList = query.docs
            .map((doc) => ChildModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList();
      } catch (e) {
        debugPrint('[PilihAnakBottomSheet] error loading children for grafik: $e');
      }
    }

    if (!context.mounted) return;

    return show(
      context,
      user: user,
      title: 'Grafik Tumbuh',
      subtitle: 'Pilih Profil Anak',
      children: childList,
      onAddChild: onAddChild,
      onChildSelected: (child) {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) =>
                PertumbuhanGrafikPage(child: child),
            transitionsBuilder: (_, animation, __, childWidget) =>
                FadeTransition(opacity: animation, child: childWidget),
            transitionDuration: const Duration(milliseconds: 200),
          ),
        );
      },
    );
  }

  @override
  State<PilihAnakBottomSheet> createState() => _PilihAnakBottomSheetState();
}

class _PilihAnakBottomSheetState extends State<PilihAnakBottomSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Tutup bottom sheet dengan animasi slide-down (durasi ~250ms).
  Future<void> _close() async {
    await _controller.animateBack(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInCubic,
    );
    if (mounted) Navigator.of(context).pop();
  }

  /// Pilih anak → animasi keluar → panggil callback.
  Future<void> _selectChild(ChildModel child) async {
    await _close();
    widget.onChildSelected?.call(child);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: _SheetContent(
          user: widget.user,
          children: widget.children,
          title: widget.title,
          subtitle: widget.subtitle,
          onClose: _close,
          onSelectChild: _selectChild,
          onAddChild: () async {
            await _close();
            widget.onAddChild?.call();
          },
        ),
      ),
    );
  }
}

// =============================================================================
// _SheetContent — UI murni, stateless sesuai referensi desain
// =============================================================================
class _SheetContent extends StatelessWidget {
  final UserModel? user;
  final List<ChildModel> children;
  final String title;
  final String subtitle;
  final Future<void> Function() onClose;
  final Future<void> Function(ChildModel) onSelectChild;
  final VoidCallback onAddChild;

  const _SheetContent({
    this.user,
    required this.children,
    required this.title,
    required this.subtitle,
    required this.onClose,
    required this.onSelectChild,
    required this.onAddChild,
  });

  // ── Warna Referensi Desain ────────────────────────────────────────────────
  static const Color _black = Color(0xFF000000);
  static const Color _divider = Color(0xFFC5C5C5);
  static const Color _subtitleColor = Color(0xFF64748B);
  static const Color _blue = Color(0xFF2B7AE8);

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;

    return Container(
      // Kompak: maksimum 65% tinggi layar agar tidak full-screen di Android
      constraints: BoxConstraints(maxHeight: screenH * 0.65),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 28,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── HEADER ────────────────────────────────────────────────────
            _buildHeader(),

            // ── GARIS PEMBATAS ────────────────────────────────────────────
            const Divider(height: 1, thickness: 1, color: _divider),

            // ── DAFTAR ANAK / STATE KOSONG ────────────────────────────────
            if (children.isNotEmpty)
              Flexible(child: _buildList())
            else
              _buildEmptyState(context),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────
  // Title (Lato Bold 20, #000000) + Subtitle (Lato Medium 14) + Close X
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Judul utama: "Data Pengguna" atau "Grafik Tumbuh"
                Text(
                  title,
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _black,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                // Subtitle: "Pilih Profil Anak"
                Text(
                  subtitle,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _subtitleColor,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // Tombol X / Close
          GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(6.0),
              child: Icon(Icons.close_rounded, size: 22, color: _black),
            ),
          ),
        ],
      ),
    );
  }

  // ── DAFTAR ANAK ────────────────────────────────────────────────────────────
  Widget _buildList() {
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      physics: const BouncingScrollPhysics(),
      itemCount: children.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFFE2E8F0),
      ),
      itemBuilder: (_, index) => _buildRow(children[index]),
    );
  }

  Widget _buildRow(ChildModel child) {
    final isBoy = child.gender.toLowerCase().contains('laki');

    // Hitung umur otomatis dari tanggal lahir; fallback ke ageDescription
    String ageText;
    if (child.birthDate != null) {
      ageText = calculateAge(child.birthDate!).formatted;
    } else if (child.ageDescription.isNotEmpty) {
      ageText = child.ageDescription;
    } else {
      ageText = '—';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelectChild(child),
        splashColor: _blue.withValues(alpha: 0.06),
        highlightColor: _blue.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── AVATAR ──────────────────────────────────────────────
              _buildAvatar(child, isBoy),

              const SizedBox(width: 14),

              // ── NAMA & USIA ──────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nama Anak — Lato SemiBold 18 #000000
                    Text(
                      child.name.isNotEmpty ? child.name : 'Anak',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _black,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Usia — Lato Regular 14 #000000 (sesuai desain referensi)
                    Text(
                      ageText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: _black,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ── IKON PANAH > (Dalam kontainer lingkaran abu-abu sesuai desain) ──
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ChildModel child, bool isBoy) {
    final bgColor =
        isBoy ? const Color(0xFFDBEAFE) : const Color(0xFFFCE7F3);
    final iconColor =
        isBoy ? const Color(0xFF2563EB) : const Color(0xFFDB2777);
    final hasPhoto =
        child.photoUrl != null && child.photoUrl!.trim().isNotEmpty;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: iconColor.withValues(alpha: 0.22),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: hasPhoto
          ? Image.network(
              child.photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.face_rounded, size: 26, color: iconColor),
            )
          : Icon(Icons.face_rounded, size: 26, color: iconColor),
    );
  }

  // ── STATE KOSONG ────────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            ),
            child: const Icon(
              Icons.child_care_rounded,
              size: 34,
              color: Color(0xFF94A3B8),
            ),
          ),

          const SizedBox(height: 14),

          // Judul — Lato Bold 18 #000000
          Text(
            'Belum Ada Data Anak',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _black,
            ),
          ),

          const SizedBox(height: 6),

          // Deskripsi — Lato Regular 14 #000000
          Text(
            user != null && user!.name.isNotEmpty
                ? 'Pengguna ${user!.name} belum memiliki\ndata profil anak yang terdaftar.'
                : 'Belum ada data profil anak yang terdaftar di sistem.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: _black,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 20),

          // Tombol tutup
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: onClose,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _divider, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Tutup',
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _subtitleColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
