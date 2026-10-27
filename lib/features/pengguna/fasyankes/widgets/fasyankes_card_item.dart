import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/fasyankes_model.dart';
import 'fasyankes_detail_bottom_sheet.dart';

/// Card item fasyankes dengan informasi Google Maps terverifikasi:
/// ulasan bintang, jumlah ulasan, foto thumbnail, nomor telepon, jarak,
/// serta akses cepat ke detail bottom sheet dan navigasi Google Maps.
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
    final geoUri = Uri.parse(fasyankes.googleMapsDirectUrl);
    try {
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    // Prioritas 2: Web URL Google Maps dengan titik koordinat resmi
    final webUrl = Uri.parse(fasyankes.googleMapsUrl);
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

  void _openDetailSheet(BuildContext context) {
    FasyankesDetailBottomSheet.show(context, fasyankes);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Warna tema
    final colorTitle = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF111827);
    final colorSubtitle = isDark ? const Color(0xFF8696A0) : const Color(0xFF6B7280);
    const colorStar = Color(0xFFFBBF24);
    const colorPrimaryBlue = Color(0xFF2B7AE8);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? colorPrimaryBlue.withValues(alpha: isDark ? 0.9 : 0.7)
              : (isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF)),
          width: isSelected ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? colorPrimaryBlue.withValues(alpha: isDark ? 0.25 : 0.12)
                : Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            onTap();
            _openDetailSheet(context);
          },
          splashColor: colorPrimaryBlue.withValues(alpha: 0.08),
          highlightColor: colorPrimaryBlue.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Baris Atas: Thumbnail Foto / Ikon + Info Utama
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail Foto Fasyankes
                    _buildThumbnail(isDark),
                    const SizedBox(width: 12),

                    // Info: Nama & Kategori
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
                                      : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  fasyankes.category,
                                  style: GoogleFonts.lato(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFF93C5FD) : colorPrimaryBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (fasyankes.isOpenNow)
                                Flexible(
                                  child: Text(
                                    '• Buka Sekarang',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.lato(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fasyankes.name,
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorTitle,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // 2. Alamat Fasyankes
                Text(
                  fasyankes.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: colorSubtitle,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 10),

                // 3. Metadata: Rating Google Maps, Ulasan, dan Jarak
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    // Rating & Ulasan GMaps
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: colorStar,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          fasyankes.rating.toStringAsFixed(1),
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colorTitle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${fasyankes.userRatingsTotal} ulasan)',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: colorSubtitle,
                          ),
                        ),
                      ],
                    ),

                    // Nomor Telepon
                    GestureDetector(
                      onTap: () => _callPhone(fasyankes.phone),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 15,
                            color: colorSubtitle,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            fasyankes.phone,
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: colorSubtitle,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Jarak dinamis dari lokasi perangkat
                    if (fasyankes.distanceKm != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C363D) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          fasyankes.formattedDistance,
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFD1D7DB) : const Color(0xFF475569),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // 4. Baris Tombol Aksi: "Detail & Ulasan" + "Buka Maps"
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.6) : const Color(0xFFBFDBFE),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _openDetailSheet(context),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.rate_review_outlined,
                                size: 14,
                                color: isDark ? const Color(0xFF93C5FD) : colorPrimaryBlue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Detail & Ulasan',
                                style: GoogleFonts.lato(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFF93C5FD) : colorPrimaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorPrimaryBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        onPressed: () => _launchMaps(context),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.directions_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Buka Maps',
                                style: GoogleFonts.lato(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildThumbnail(bool isDark) {
    String? photoUrl = fasyankes.imageUrl;
    try {
      final pList = fasyankes.photos;
      if ((photoUrl == null || photoUrl.isEmpty) && pList.isNotEmpty) {
        photoUrl = pList.first;
      }
    } catch (_) {}

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 52,
        height: 52,
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
        child: photoUrl != null && photoUrl.startsWith('assets/')
            ? Image.asset(
                photoUrl,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildFallbackThumbnail(isDark),
              )
            : (photoUrl != null && photoUrl.startsWith('http')
                ? Image.network(
                    photoUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildFallbackThumbnail(isDark),
                  )
                : _buildFallbackThumbnail(isDark)),
      ),
    );
  }

  Widget _buildFallbackThumbnail(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFDBEAFE),
      child: const Center(
        child: Icon(
          Icons.local_hospital_rounded,
          color: Color(0xFF2B7AE8),
          size: 26,
        ),
      ),
    );
  }
}
