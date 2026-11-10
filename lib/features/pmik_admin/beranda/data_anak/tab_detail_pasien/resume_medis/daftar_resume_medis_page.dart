import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../core/services/resume_medis_service.dart';
import '../../../../../../models/child_model.dart';
import '../../../../../../models/resume_medis_model.dart';
import '../../../../../../models/user_model.dart';
import '../../../../../../shared/widgets/doctor_live_avatar.dart';
import 'detail_resume_medis_page.dart';

/// Halaman Daftar Resume Medis.
/// Menampilkan daftar card resume medis pasien anak berdasarkan data di database Firestore.
/// Apabila card diklik, akan membuka [DetailResumeMedisPage].
class DaftarResumeMedisPage extends StatefulWidget {
  final ChildModel child;
  final UserModel? user;

  const DaftarResumeMedisPage({super.key, required this.child, this.user});

  @override
  State<DaftarResumeMedisPage> createState() => _DaftarResumeMedisPageState();
}

class _DaftarResumeMedisPageState extends State<DaftarResumeMedisPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  late final Stream<List<ResumeMedisModel>> _resumeStream;
  List<ResumeMedisModel>? _initialData;

  @override
  void initState() {
    super.initState();
    _initialData = ResumeMedisService().getCached(widget.child.id, widget.child.name);
    _resumeStream = ResumeMedisService().streamResumeMedis(
      child: widget.child,
      userId: widget.user?.id,
    );
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final text = _searchController.text.trim();
    if (_searchQuery != text) {
      setState(() {
        _searchQuery = text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1014) : Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // ── 1. Header Fixed 56dp ────────────────────────────────────
              _buildFixedHeader(),

              // ── 2. Search Bar ──────────────────────────────────────────
              _buildSearchBar(),

              // ── 3. List Resume Medis (Stream Firestore) ────────────────
              Expanded(
                child: StreamBuilder<List<ResumeMedisModel>>(
                  initialData: _initialData,
                  stream: _resumeStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2B7AE8),
                        ),
                      );
                    }

                    final allItems = snapshot.data ?? [];
                    final filteredItems = allItems.where((item) {
                      if (_searchQuery.isEmpty) return true;
                      final query = _searchQuery.toLowerCase();
                      return item.doctorName.toLowerCase().contains(query) ||
                          item.childName.toLowerCase().contains(query) ||
                          item.complaintShort.toLowerCase().contains(query) ||
                          item.complaint.toLowerCase().contains(query) ||
                          item.consultationDate.toLowerCase().contains(query);
                    }).toList();

                    if (filteredItems.isEmpty) {
                      return Center(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 64,
                                  color: isDark ? const Color(0xFF667781) : Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'Tidak ditemukan resume medis untuk "$_searchQuery"'
                                      : 'Belum ada data resume medis',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.lato(
                                    fontSize: 15,
                                    color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredItems.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final resume = filteredItems[index];
                        return _buildResumeCard(resume);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. HEADER FIXED 56dp
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFixedHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: 56,
      color: isDark ? const Color(0xFF1A2228) : Colors.white,
      padding: const EdgeInsets.only(left: 12, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                Icons.arrow_back,
                color: isDark ? const Color(0xFFE9EDEF) : Colors.black,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Resume Medis',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE9EDEF) : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. SEARCH BAR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2228) : const Color(0xFFEFF3F8),
          borderRadius: BorderRadius.circular(14),
          border: isDark ? Border.all(color: const Color(0xFF2C363D), width: 1) : null,
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(
              Icons.search_rounded,
              color: Color(0xFF8696A0),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: GoogleFonts.lato(
                  fontSize: 14.5,
                  color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228),
                ),
                decoration: InputDecoration(
                  hintText: 'Cari Resume Medis',
                  hintStyle: GoogleFonts.lato(
                    fontSize: 14.5,
                    color: const Color(0xFF8696A0),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  _searchFocusNode.unfocus();
                },
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.close_rounded,
                    color: Color(0xFF8696A0),
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. CARD RESUME MEDIS (Sesuai Gambar Mockup 1)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildResumeCard(ResumeMedisModel resume) {
    return _ResumeCardItem(
      resume: resume,
      doctorAvatar: DoctorLiveAvatar(
        doctorId: resume.doctorId,
        doctorName: resume.doctorName,
        fallbackPhoto: resume.doctorPhoto,
        size: 52,
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF2B7AE8).withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DetailResumeMedisPage(
              resume: resume,
              child: widget.child,
              parentUser: widget.user,
            ),
          ),
        );
      },
      onDelete: null,
    );
  }

}

/// Card Item Resume Medis dengan border biru muda lembut (seperti tema profil & jadwal dokter)
/// serta efek Hover interaktif (Web/Desktop) dan efek Aktif Sentuh (Mobile/Touchscreen).
class _ResumeCardItem extends StatefulWidget {
  final ResumeMedisModel resume;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final Widget doctorAvatar;

  const _ResumeCardItem({
    required this.resume,
    required this.onTap,
    this.onDelete,
    required this.doctorAvatar,
  });

  @override
  State<_ResumeCardItem> createState() => _ResumeCardItemState();
}

class _ResumeCardItemState extends State<_ResumeCardItem> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isActive => _isHovered || _isPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryBlue = Color(0xFF2B7AE8);
    final resume = widget.resume;

    // Latar belakang card: berubah menjadi biru muda lembut saat disentuh/di-hover
    final cardBgColor = _isActive
        ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F7FF))
        : (isDark ? const Color(0xFF1A2228) : Colors.white);

    // Garis tepi (border): biru muda lembut (#BFDBFE) saat normal, dan menyala biru tajam saat aktif
    final borderColor = _isActive
        ? primaryBlue
        : (isDark ? const Color(0xFF2C363D) : const Color(0xFFBFDBFE));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (mounted) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _isHovered = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isActive ? -3.0 : 0, 0),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: _isActive ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _isActive
                  ? primaryBlue.withValues(alpha: isDark ? 0.35 : 0.20)
                  : primaryBlue.withValues(alpha: isDark ? 0.25 : 0.08),
              blurRadius: _isActive ? 14 : 10,
              offset: _isActive ? const Offset(0, 5) : const Offset(0, 3),
            ),
            if (!_isActive)
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            onTapDown: (_) {
              if (mounted) setState(() => _isPressed = true);
            },
            onTapUp: (_) {
              if (mounted) setState(() => _isPressed = false);
            },
            onTapCancel: () {
              if (mounted) setState(() => _isPressed = false);
            },
            onHover: (hovering) {
              if (mounted) setState(() => _isHovered = hovering);
            },
            splashColor: primaryBlue.withValues(alpha: 0.12),
            highlightColor: primaryBlue.withValues(alpha: 0.08),
            hoverColor: primaryBlue.withValues(alpha: 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bagian Atas: Avatar Dokter, Nama Dokter, Info Anak & Keluhan
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      widget.doctorAvatar,
                      const SizedBox(width: 12),

                      // Teks Kanan
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nama Dokter (Bold)
                            Text(
                              resume.doctorName,
                              style: GoogleFonts.lato(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFFE9EDEF)
                                    : const Color(0xFF1A2228),
                              ),
                            ),
                            const SizedBox(height: 3),

                            // Nama Anak
                            Text(
                              'Anak: ${resume.childName}',
                              style: GoogleFonts.lato(
                                fontSize: 13,
                                color: isDark
                                    ? const Color(0xFFD1D7DB)
                                    : const Color(0xFF2C363D),
                              ),
                            ),
                            const SizedBox(height: 2),

                            // Keluhan
                            Text(
                              'Keluhan: ${resume.complaintShort}',
                              style: GoogleFonts.lato(
                                fontSize: 13,
                                color: isDark
                                    ? const Color(0xFF8696A0)
                                    : const Color(0xFF2C363D),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider tipis
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark
                      ? const Color(0xFF2C363D)
                      : const Color(0xFFE9EDEF),
                ),

                // Bagian Bawah: Tanggal & Badge "Selesai"
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tanggal Konsultasi berbingkai biru muda lembut (seperti di jadwal dokter)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFBFDBFE),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_month_outlined,
                              size: 15,
                              color: isDark
                                  ? const Color(0xFF93C5FD)
                                  : primaryBlue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              resume.consultationDate,
                              style: GoogleFonts.lato(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFFE9EDEF)
                                    : const Color(0xFF1A2228),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Badge Selesai (Hijau Toska) + Tombol Hapus opsional
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF26B89D),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              resume.status,
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (widget.onDelete != null) ...[
                            const SizedBox(width: 8),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: widget.onDelete,
                                borderRadius: BorderRadius.circular(8.0),
                                child: Container(
                                  width: 32.0,
                                  height: 32.0,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF3F1B1B)
                                        : const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(8.0),
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF7F1D1D)
                                          : const Color(0xFFFFCDD2),
                                      width: 1.0,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    color: isDark
                                        ? const Color(0xFFF87171)
                                        : const Color(0xFFE53935),
                                    size: 18.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
}

