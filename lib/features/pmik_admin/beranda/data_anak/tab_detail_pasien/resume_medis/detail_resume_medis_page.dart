import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../models/resume_medis_model.dart';

/// Halaman Detail Resume Medis.
/// Menampilkan rincian data resume medis yang diberikan oleh dokter
/// setelah sesi konsultasi selesai, sesuai dengan desain pada mockup.
class DetailResumeMedisPage extends StatelessWidget {
  final ResumeMedisModel resume;

  const DetailResumeMedisPage({
    super.key,
    required this.resume,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. Header Fixed 56dp ──────────────────────────────────────
            _buildFixedHeader(context),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // ── 2. Konten Scrollable ─────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── A. Card Dokter ──────────────────────────────────
                    _buildDoctorCard(),
                    const SizedBox(height: 16),

                    // ── B. Card Detail Konsultasi & Antropometri ────────
                    _buildConsultationInfoCard(),
                    const SizedBox(height: 20),

                    // ── C. Seksi Catatan / Text Area ─────────────────────
                    _buildTextSection(
                      label: 'Keluhan',
                      content: resume.complaint,
                    ),
                    const SizedBox(height: 16),

                    _buildTextSection(
                      label: 'Assesmen Dokter',
                      content: resume.doctorAssessment,
                    ),
                    const SizedBox(height: 16),

                    _buildTextSection(
                      label: 'Ringkasan',
                      content: resume.summary,
                    ),
                    const SizedBox(height: 16),

                    _buildRecommendationsSection(),
                    const SizedBox(height: 16),

                    _buildTextSection(
                      label: 'Resep/ Suplemen',
                      content: resume.prescription.isNotEmpty
                          ? resume.prescription
                          : '-',
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. HEADER FIXED 56dp
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFixedHeader(BuildContext context) {
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
              'Detail Resume Medis',
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
  // A. CARD DOKTER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDoctorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Foto Dokter / Avatar
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF2B7AE8).withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: resume.doctorPhoto != null && resume.doctorPhoto!.isNotEmpty
                  ? (resume.doctorPhoto!.startsWith('http')
                      ? Image.network(
                          resume.doctorPhoto!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackDoctorIcon(),
                        )
                      : Image.asset(
                          resume.doctorPhoto!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackDoctorIcon(),
                        ))
                  : _buildFallbackDoctorIcon(),
            ),
          ),
          const SizedBox(width: 14),

          // Nama & Spesialis
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  resume.doctorName,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  resume.doctorSpecialization,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackDoctorIcon() {
    return Container(
      color: const Color(0xFFEAF5FF),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person,
        size: 32,
        color: Color(0xFF2B7AE8),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // B. CARD DETAIL KONSULTASI & ANTROPOMETRI (Latar Biru Muda)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildConsultationInfoCard() {
    const divider = Divider(height: 18, color: Color(0xFFD7E7FA), thickness: 1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6E8FA), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header "Detail Konsultasi"
          Text(
            'Detail Konsultasi',
            style: GoogleFonts.lato(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),

          // Baris 1: Nama Anak
          _buildInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Nama anak',
            value: resume.childName,
          ),
          divider,

          // Baris 2: Usia Saat Konsultasi
          _buildInfoRow(
            icon: Icons.event_note_outlined,
            label: 'Usia Saat Konsultasi',
            value: resume.childAgeAtConsultation,
          ),
          divider,

          // Baris 3: Tanggal Konsultasi
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Tanggal Konsultasi',
            value: resume.consultationDate,
          ),
          divider,

          // Baris 4: Waktu Konsultasi
          _buildInfoRow(
            icon: Icons.access_time_outlined,
            label: 'Waktu Konsultasi',
            value: resume.consultationTime,
          ),
          divider,

          const SizedBox(height: 4),

          // Header "Data Antropometri"
          Text(
            'Data Antropometri',
            style: GoogleFonts.lato(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),

          // Grid Antropometri: BB Lahir, BB Saat Ini, TB Lahir, TB Saat Ini
          Row(
            children: [
              Expanded(
                child: _buildAntropoItem(
                  'BB lahir(kg):',
                  _formatNum(resume.bbLahir),
                ),
              ),
              Expanded(
                child: _buildAntropoItem(
                  'BB saat ini(kg):',
                  _formatNum(resume.bbSaatIni),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildAntropoItem(
                  'TB lahir(cm):',
                  _formatNum(resume.tbLahir),
                ),
              ),
              Expanded(
                child: _buildAntropoItem(
                  'TB saat ini(cm):',
                  _formatNum(resume.tbSaatIni),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 13.5,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.lato(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAntropoItem(String label, String value) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.lato(
          fontSize: 13.5,
          color: const Color(0xFF64748B),
        ),
        children: [
          TextSpan(text: '$label '),
          TextSpan(
            text: value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNum(double numVal) {
    if (numVal == numVal.toInt()) {
      return numVal.toInt().toString();
    }
    return numVal.toString();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // C. SEKSI TEKS (Keluhan, Assesmen, Ringkasan, Resep)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTextSection({
    required String label,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 14,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content.isNotEmpty ? content : '-',
          style: GoogleFonts.lato(
            fontSize: 14.5,
            color: const Color(0xFF1E293B),
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsSection() {
    final list = resume.recommendations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rekomendasi',
          style: GoogleFonts.lato(
            fontSize: 14,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(height: 4),
        if (list.isEmpty)
          Text(
            '-',
            style: GoogleFonts.lato(
              fontSize: 14.5,
              color: const Color(0xFF1E293B),
            ),
          )
        else
          ...list.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final text = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 3.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$idx. ',
                    style: GoogleFonts.lato(
                      fontSize: 14.5,
                      color: const Color(0xFF1E293B),
                      height: 1.45,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      text,
                      style: GoogleFonts.lato(
                        fontSize: 14.5,
                        color: const Color(0xFF1E293B),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
