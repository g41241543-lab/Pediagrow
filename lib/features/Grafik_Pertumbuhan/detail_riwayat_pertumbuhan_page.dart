import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/child_model.dart';
import 'models/growth_record_model.dart';
import 'services/growth_service.dart';
import 'services/zscore_calculator.dart';

/// Halaman Detail Entri Riwayat Pertumbuhan.
///
/// Menampilkan rincian pengukuran antropometri, evaluasi Z-score
/// menurut standar WHO/Permenkes RI No. 2 Tahun 2020, serta rekomendasi.
class DetailRiwayatPertumbuhanPage extends StatelessWidget {
  final ChildModel child;
  final GrowthRecordModel record;

  const DetailRiwayatPertumbuhanPage({
    super.key,
    required this.child,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = ZScoreCalculator.getStatusColor(record.statusGizi);
    final statusBgColor = ZScoreCalculator.getStatusBgColor(record.statusGizi);
    final statusDesc = ZScoreCalculator.getStatusDescription(record.statusGizi);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1014) : Colors.white,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // 1. Header (56dp dari atas layar)
            _buildHeader(context, isDark),

            // 2. Konten Utama
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Profil & Waktu Pengukuran
                    _buildChildInfoCard(isDark),

                    const SizedBox(height: 16),

                    // Tiga Kartu Nilai Antropometri
                    _buildMeasurementValues(isDark),

                    const SizedBox(height: 20),

                    // Card Evaluasi Z-Score & Status Gizi
                    _buildZScoreCard(statusColor, statusBgColor, statusDesc, isDark),

                    const SizedBox(height: 20),

                    // Card Catatan / Sumber Pengukuran
                    _buildNotesCard(isDark),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF0B1014) : Colors.white,
      padding: const EdgeInsets.only(top: 56.0, bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.only(left: 12.0, right: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.arrow_back,
                  color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Detail Pengukuran',
                style: GoogleFonts.lato(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000),
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildInfoCard(bool isDark) {
    final isGirl = child.gender.toLowerCase().contains('perempuan');
    final avatarBg = isGirl
        ? (isDark ? const Color(0xFF831843).withValues(alpha: 0.35) : const Color(0xFFFFD8E4))
        : (isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.35) : const Color(0xFFD6EEFF));
    final avatarColor =
        isGirl ? const Color(0xFFF472B6) : const Color(0xFF60A5FA);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: avatarBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.child_care_rounded,
              color: avatarColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: GoogleFonts.lato(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Usia saat pengukuran: ${record.ageFormatted}',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tanggal: ${formatTanggalIndonesia(record.date)}',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3985E7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementValues(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildValueTile(
            title: 'Berat Badan',
            value: '${record.weightKg.toStringAsFixed(1)} kg',
            icon: Icons.monitor_weight_outlined,
            color: const Color(0xFF0284C7),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildValueTile(
            title: 'Tinggi Badan',
            value: '${record.heightCm.toStringAsFixed(1)} cm',
            icon: Icons.straighten_outlined,
            color: const Color(0xFF16A34A),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildValueTile(
            title: 'Lingkar Kepala',
            value: '${record.headCircumferenceCm.toStringAsFixed(1)} cm',
            icon: Icons.face_outlined,
            color: const Color(0xFF9333EA),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildValueTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.lato(
              fontSize: 11,
              color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.lato(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZScoreCard(
    Color statusColor,
    Color statusBgColor,
    String statusDesc,
    bool isDark,
  ) {
    final effectiveBg = isDark ? const Color(0xFF1A2228) : Colors.white;
    final effectiveStatusBg = isDark
        ? (record.statusGizi == 'Gizi Normal'
            ? const Color(0xFF064E3B).withValues(alpha: 0.35)
            : const Color(0xFF7F1D1D).withValues(alpha: 0.35))
        : statusBgColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analisis Antropometri (Permenkes RI No. 2/2020)',
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014),
            ),
          ),
          const SizedBox(height: 12),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: effectiveStatusBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  record.statusGizi == 'Gizi Normal'
                      ? Icons.check_circle_rounded
                      : Icons.warning_rounded,
                  color: statusColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  record.statusGizi,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Text(
            statusDesc,
            style: GoogleFonts.lato(
              fontSize: 13,
              height: 1.5,
              color: isDark ? const Color(0xFFD1D7DB) : const Color(0xFF2C363D),
            ),
          ),

          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF),
          ),
          const SizedBox(height: 14),

          // Rincian Z-Scores
          _buildZScoreRow(
            'BB menurut TB (BB/TB)',
            record.zScoreWeightForHeight,
            isDark,
          ),
          const SizedBox(height: 8),
          _buildZScoreRow(
            'BB menurut Umur (BB/U)',
            record.zScoreWeightForAge,
            isDark,
          ),
          const SizedBox(height: 8),
          _buildZScoreRow(
            'TB menurut Umur (TB/U)',
            record.zScoreHeightForAge,
            isDark,
          ),
          const SizedBox(height: 8),
          _buildZScoreRow(
            'LK menurut Umur (LK/U)',
            record.zScoreHeadForAge,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildZScoreRow(String label, double zScore, bool isDark) {
    final isNormal = zScore >= -2.0 && zScore <= 2.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 12,
            color: isDark ? const Color(0xFFD1D7DB) : const Color(0xFF2C363D),
          ),
        ),
        Text(
          '${zScore >= 0 ? '+' : ''}${zScore.toStringAsFixed(2)} SD',
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isNormal
                ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF2E7D32))
                : (isDark ? const Color(0xFFF87171) : const Color(0xFFB13535)),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
              ),
              const SizedBox(width: 6),
              Text(
                'Sumber Pengukuran',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF2C363D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            record.notes ??
                (record.isBirthRecord
                    ? 'Data awal dicatat dari profil kelahiran anak.'
                    : 'Pengukuran dicatat melalui fitur Cek Stunting.'),
            style: GoogleFonts.lato(
              fontSize: 12,
              color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
            ),
          ),
        ],
      ),
    );
  }
}
