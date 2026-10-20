import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../core/services/resume_medis_service.dart';
import '../../../../../../models/child_model.dart';
import '../../../../../../models/resume_medis_model.dart';
import '../../../../../../models/user_model.dart';
import '../../../../../../shared/widgets/doctor_live_avatar.dart';
import '../../../../../../shared/widgets/pedia_banner.dart';
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

  Future<void> _confirmDeleteResume(ResumeMedisModel resume) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.54),
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          elevation: 8,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hapus Data',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Mohon pastikan ulang sebelum menghapus resume medis. Apakah anda yakin ingin menghapus?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: const Color(0xFF7F7F7F),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(true),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(
                              color: Color(0xFFC5C5C5),
                              width: 1.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            'Ya',
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3985E7),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            'Tidak',
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        await ResumeMedisService().deleteResumeMedis(resume.id);
        if (mounted) {
          PediaBanner.showSuccess(
            context,
            message: 'Berhasil Menghapus Resume Medis',
          );
        }
      } catch (e) {
        if (mounted) {
          PediaBanner.showError(
            context,
            message: 'Gagal menghapus resume medis: $e',
          );
        }
      }
    }
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // â”€â”€ 1. Header Fixed 56dp â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _buildFixedHeader(),

              // â”€â”€ 2. Search Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _buildSearchBar(),

              // â”€â”€ 3. List Resume Medis (Stream Firestore) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'Tidak ditemukan resume medis untuk "$_searchQuery"'
                                      : 'Belum ada data resume medis',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.lato(
                                    fontSize: 15,
                                    color: const Color(0xFF667781),
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // 1. HEADER FIXED 56dp
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildFixedHeader() {
    return Container(
      width: double.infinity,
      height: 56,
      color: Colors.white,
      padding: const EdgeInsets.only(left: 12, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.arrow_back, color: Colors.black, size: 24),
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
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // 2. SEARCH BAR
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF3F8),
          borderRadius: BorderRadius.circular(14),
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
                  color: const Color(0xFF1A2228),
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // 3. CARD RESUME MEDIS (Sesuai Gambar Mockup 1)
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildResumeCard(ResumeMedisModel resume) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DetailResumeMedisPage(
                resume: resume,
                child: widget.child,
                parentUser: widget.user,
              ),
            ),
          );
          if (result == 'deleted' && mounted) {
            PediaBanner.showSuccess(
              context,
              message: 'Berhasil Menghapus Resume Medis',
            );
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE9EDEF), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian Atas: Avatar Dokter, Nama Dokter, Info Anak & Keluhan
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar Dokter Real-Time
                    DoctorLiveAvatar(
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
                              color: const Color(0xFF1A2228),
                            ),
                          ),
                          const SizedBox(height: 3),

                          // Nama Anak
                          Text(
                            'Anak: ${resume.childName}',
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              color: const Color(0xFF2C363D),
                            ),
                          ),
                          const SizedBox(height: 2),

                          // Keluhan
                          Text(
                            'Keluhan: ${resume.complaintShort}',
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              color: const Color(0xFF2C363D),
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
              const Divider(height: 1, thickness: 1, color: Color(0xFFE9EDEF)),

              // Bagian Bawah: Tanggal & Badge "Selesai"
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tanggal Konsultasi
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 18,
                          color: Color(0xFF667781),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          resume.consultationDate,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A2228),
                          ),
                        ),
                      ],
                    ),

                    // Badge Selesai (Hijau Toska) + Tombol Hapus
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
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _confirmDeleteResume(resume),
                            borderRadius: BorderRadius.circular(8.0),
                            child: Container(
                              width: 32.0,
                              height: 32.0,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(
                                  color: const Color(0xFFFFCDD2),
                                  width: 1.0,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: Color(0xFFE53935),
                                size: 18.0,
                              ),
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
    );
  }
}

