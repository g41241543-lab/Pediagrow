import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/fasyankes_model.dart';

/// Card item fasyankes dengan efek 3D shadow, border halus, dan typography Lato
class FasyankesCardItem extends StatelessWidget {
  final FasyankesModel fasyankes;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onOpenMaps;

  const FasyankesCardItem({
    super.key,
    required this.fasyankes,
    this.isSelected = false,
    required this.onTap,
    this.onOpenMaps,
  });

  Future<void> _launchMaps(BuildContext context) async {
    if (onOpenMaps != null) {
      onOpenMaps!();
      return;
    }

    // Prioritas 1: geo: URI — membuka aplikasi Maps native di Android/iOS
    // dengan pin bernamapersis di koordinat yang sesuai data
    final geoUri = Uri.parse(fasyankes.googleMapsDirectUrl);
    try {
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    // Prioritas 2: Web URL Google Maps dengan query nama + koordinat
    final encodedName = Uri.encodeComponent(fasyankes.name);
    final webUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=$encodedName+${fasyankes.latitude},${fasyankes.longitude}',
    );
    try {
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch maps: $e');
    }
  }


  Future<void> _callPhone(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Could not launch phone: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Warna teks & aksen sesuai desain referensi
    const colorTitle = Color(0xFF000000);
    const colorSubtitle = Color(0xFF8E8E93);
    const colorStar = Color(0xFFFBBF24); // Kuning keemasan hangat
    const colorPrimaryBlue = Color(0xFF2B7AE8);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? colorPrimaryBlue.withValues(alpha: 0.65)
              : const Color(0xFFE2E8F0),
          width: isSelected ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? colorPrimaryBlue.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: isSelected ? 14 : 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          splashColor: colorPrimaryBlue.withValues(alpha: 0.08),
          highlightColor: colorPrimaryBlue.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Card: Nama Fasyankes & Badge Kategori / Buka di Maps
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        fasyankes.name,
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorTitle,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tombol Aksi Cepat "Buka di Maps"
                    InkWell(
                      onTap: () => _launchMaps(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFBFDBFE),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.directions_outlined,
                              size: 14,
                              color: colorPrimaryBlue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Buka Maps',
                              style: GoogleFonts.lato(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colorPrimaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // 2. Alamat Lengkap
                Text(
                  fasyankes.address,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: colorSubtitle,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 10),

                // 3. Baris Bawah: Telepon, Rating, dan Jarak (Wrap agar bebas overflow)
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    // Nomor Telepon dengan Ikon Phone
                    GestureDetector(
                      onTap: () => _callPhone(fasyankes.phone),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 18,
                            color: colorSubtitle,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            fasyankes.phone,
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: colorSubtitle,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Rating dengan Ikon Star Kuning
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 20,
                          color: colorStar,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          fasyankes.rating.toStringAsFixed(1),
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: colorSubtitle,
                          ),
                        ),
                      ],
                    ),

                    // Jarak jika tersedia
                    if (fasyankes.distanceKm != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          fasyankes.formattedDistance,
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
