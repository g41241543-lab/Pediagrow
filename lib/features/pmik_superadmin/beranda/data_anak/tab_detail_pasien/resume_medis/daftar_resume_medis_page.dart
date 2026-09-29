import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../core/services/resume_medis_service.dart';
import '../../../../../../models/child_model.dart';
import '../../../../../../models/resume_medis_model.dart';
import '../../../../../../models/user_model.dart';
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

  @override
  void initState() {
    super.initState();
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
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
                  stream: ResumeMedisService().streamResumeMedis(
                    child: widget.child,
                    userId: widget.user?.id,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
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
                                    color: const Color(0xFF64748B),
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
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
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

  // ─────────────────────────────────────────────────────────────────────────
  // 2. SEARCH BAR
  // ─────────────────────────────────────────────────────────────────────────
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
              color: Color(0xFF94A3B8),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: GoogleFonts.lato(
                  fontSize: 14.5,
                  color: const Color(0xFF1E293B),
                ),
                decoration: InputDecoration(
                  hintText: 'Cari Resume Medis',
                  hintStyle: GoogleFonts.lato(
                    fontSize: 14.5,
                    color: const Color(0xFF94A3B8),
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
                    color: Color(0xFF94A3B8),
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DetailResumeMedisPage(resume: resume),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
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
                    // Avatar Dokter
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF2B7AE8)
                              .withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child:
                            resume.doctorPhoto != null &&
                                resume.doctorPhoto!.isNotEmpty
                            ? (resume.doctorPhoto!.startsWith('http')
                                  ? Image.network(
                                      resume.doctorPhoto!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _buildDoctorAvatarFallback(),
                                    )
                                  : Image.asset(
                                      resume.doctorPhoto!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _buildDoctorAvatarFallback(),
                                    ))
                            : _buildDoctorAvatarFallback(),
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
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 3),

                          // Nama Anak
                          Text(
                            'Anak: ${resume.childName}',
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 2),

                          // Keluhan
                          Text(
                            'Keluhan: ${resume.complaintShort}',
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              color: const Color(0xFF475569),
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
              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

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
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          resume.consultationDate,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),

                    // Badge Selesai (Hijau Toska)
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorAvatarFallback() {
    return Container(
      color: const Color(0xFFEAF5FF),
      alignment: Alignment.center,
      child: const Icon(Icons.person, size: 30, color: Color(0xFF2B7AE8)),
    );
  }
}
