import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget baris 3 kartu statistik ringkas berdampingan untuk
/// Berat (kg), Tinggi (cm), dan Lingkar Kepala (cm).
class GrowthStatCardsRow extends StatelessWidget {
  final double? weightKg;
  final double? heightCm;
  final double? headCircumferenceCm;

  const GrowthStatCardsRow({
    super.key,
    required this.weightKg,
    required this.heightCm,
    required this.headCircumferenceCm,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 1. Kartu Berat
        Expanded(
          child: _StatCard(
            title: 'Berat',
            value: weightKg != null ? weightKg!.toStringAsFixed(1) : '-',
            unit: 'kg',
            icon: Icons.monitor_weight_outlined,
            iconColor: const Color(0xFF0284C7),
            iconBgColor: const Color(0xFFE0F2FE),
          ),
        ),
        const SizedBox(width: 10),

        // 2. Kartu Tinggi
        Expanded(
          child: _StatCard(
            title: 'Tinggi',
            value: heightCm != null ? heightCm!.toStringAsFixed(1) : '-',
            unit: 'cm',
            icon: Icons.straighten_outlined,
            iconColor: const Color(0xFF16A34A),
            iconBgColor: const Color(0xFFDCFCE7),
          ),
        ),
        const SizedBox(width: 10),

        // 3. Kartu L. Kepala
        Expanded(
          child: _StatCard(
            title: 'L. Kepala',
            value: headCircumferenceCm != null
                ? headCircumferenceCm!.toStringAsFixed(1)
                : '-',
            unit: 'cm',
            icon: Icons.face_outlined,
            iconColor: const Color(0xFF9333EA),
            iconBgColor: const Color(0xFFF3E8FF),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon dengan lingkaran background soft
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Nilai & Satuan
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: GoogleFonts.lato(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
