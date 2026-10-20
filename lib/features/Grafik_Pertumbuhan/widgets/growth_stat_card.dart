import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget baris 2 kartu statistik ringkas berdampingan untuk
/// Berat (kg) dan Tinggi (cm).
class GrowthStatCardsRow extends StatelessWidget {
  final double? weightKg;
  final double? heightCm;

  const GrowthStatCardsRow({
    super.key,
    required this.weightKg,
    required this.heightCm,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF),
          width: 1.0,
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
                  color: isDark ? iconColor.withValues(alpha: 0.2) : iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
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
                  color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: GoogleFonts.lato(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF8696A0) : const Color(0xFF8696A0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
