import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/fasyankes_model.dart';

/// Bottom Sheet Interaktif Detail Fasyankes
/// Menampilkan informasi lengkap terverifikasi Google Maps:
/// foto fasilitas, ulasan pengguna asli, jam buka, layanan anak & KIA, telepon,
/// dan navigasi langsung ke Google Maps.
class FasyankesDetailBottomSheet extends StatelessWidget {
  final FasyankesModel fasyankes;

  const FasyankesDetailBottomSheet({
    super.key,
    required this.fasyankes,
  });

  static Future<void> show(BuildContext context, FasyankesModel fasyankes) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FasyankesDetailBottomSheet(fasyankes: fasyankes),
    );
  }

  Future<void> _launchGoogleMaps(BuildContext context) async {
    // 1. Coba buka via geo: URL (Native app Maps)
    final geoUri = Uri.parse(fasyankes.googleMapsDirectUrl);
    try {
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    // 2. Fallback ke URL Google Maps Web dengan titik koordinat resmi
    final webUrl = Uri.parse(fasyankes.googleMapsUrl);
    try {
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka Google Maps: $e')),
        );
      }
    }
  }

  Future<void> _callPhone(BuildContext context) async {
    final cleanPhone = fasyankes.phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Panggilan telepon tidak didukung di perangkat ini.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error call phone: $e');
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin ke clipboard!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSurface = isDark ? const Color(0xFF141C22) : Colors.white;
    final textTitle = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF111827);
    final textSubtitle = isDark ? const Color(0xFF8696A0) : const Color(0xFF6B7280);
    const colorPrimary = Color(0xFF2B7AE8);
    const colorStar = Color(0xFFFBBF24);

    final mediaQuery = MediaQuery.of(context);
    final maxSheetHeight = mediaQuery.size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: BoxDecoration(
        color: bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Konten Scrollable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A. Foto Fasilitas / Header Visual
                  _buildPhotoHeader(isDark),
                  const SizedBox(height: 16),

                  // B. Nama Fasyankes & Verified Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fasyankes.name,
                              style: GoogleFonts.lato(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textTitle,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 16,
                                  color: Color(0xFF10B981),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Terdaftar Resmi di Google Maps',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.lato(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Jarak dari posisi pengguna
                      if (fasyankes.distanceKm != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.4) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.5) : const Color(0xFFBFDBFE),
                            ),
                          ),
                          child: Text(
                            fasyankes.formattedDistance,
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFF93C5FD) : colorPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // C. Rating Google Maps & Total Ulasan
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A2228) : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          fasyankes.rating.toStringAsFixed(1),
                          style: GoogleFonts.lato(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: textTitle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: List.generate(5, (index) {
                                  final isFull = index < fasyankes.rating.floor();
                                  final isHalf = index == fasyankes.rating.floor() && (fasyankes.rating % 1.0) >= 0.5;
                                  return Icon(
                                    isFull
                                        ? Icons.star_rounded
                                        : (isHalf ? Icons.star_half_rounded : Icons.star_outline_rounded),
                                    size: 16,
                                    color: colorStar,
                                  );
                                }),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${fasyankes.userRatingsTotal} Ulasan di Google Maps',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.lato(
                                  fontSize: 11,
                                  color: textSubtitle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: fasyankes.isOpenNow ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: fasyankes.isOpenNow ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                            ),
                          ),
                          child: Text(
                            fasyankes.isOpenNow ? 'Buka Sekarang' : 'Tutup',
                            style: GoogleFonts.lato(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: fasyankes.isOpenNow ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // D. Tombol Aksi Cepat (Rute, Telepon, Salin)
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.directions_rounded,
                          label: 'Rute GMaps',
                          color: colorPrimary,
                          textColor: Colors.white,
                          onTap: () => _launchGoogleMaps(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.phone_rounded,
                          label: 'Telepon',
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
                          textColor: isDark ? const Color(0xFF93C5FD) : colorPrimary,
                          onTap: () => _callPhone(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.share_rounded,
                          label: 'Bagikan',
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
                          textColor: textTitle,
                          onTap: () => _copyToClipboard(context, fasyankes.shareText, 'Informasi Fasyankes'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // E. Informasi Plus Code & Jam Operasional
                  if (fasyankes.plusCode != null && fasyankes.plusCode!.isNotEmpty) ...[
                    _buildInfoRow(
                      icon: Icons.pin_drop_rounded,
                      title: 'Plus Code Google Maps',
                      content: fasyankes.plusCode!,
                      isDark: isDark,
                      trailingAction: () => _copyToClipboard(context, fasyankes.plusCode!, 'Plus Code'),
                      trailingLabel: 'Salin',
                    ),
                    const SizedBox(height: 12),
                  ],

                  _buildInfoRow(
                    icon: Icons.access_time_rounded,
                    title: 'Jam Operasional',
                    content: fasyankes.operatingHours,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 12),

                  _buildInfoRow(
                    icon: Icons.location_on_rounded,
                    title: 'Alamat Lengkap',
                    content: fasyankes.address,
                    isDark: isDark,
                    trailingAction: () => _copyToClipboard(context, fasyankes.address, 'Alamat'),
                    trailingLabel: 'Salin',
                  ),

                  const SizedBox(height: 12),

                  _buildInfoRow(
                    icon: Icons.call_rounded,
                    title: 'Nomor Telepon',
                    content: fasyankes.phone,
                    isDark: isDark,
                    trailingAction: () => _callPhone(context),
                    trailingLabel: 'Panggil',
                  ),

                  const SizedBox(height: 20),

                  // F. Layanan & Fasilitas Kesehatan (Pelayanan Anak & Stunting)
                  if (fasyankes.services.isNotEmpty) ...[
                    Text(
                      'Layanan & Fasilitas Kesehatan',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textTitle,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: fasyankes.services.map((service) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 14,
                                color: Color(0xFF10B981),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                service,
                                style: GoogleFonts.lato(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: textTitle,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),
                  ],

                  // G. Ulasan Google Maps
                  Text(
                    'Ulasan Pengguna Google Maps (${fasyankes.reviews.length})',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textTitle,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildReviewsList(isDark),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // 3. Bottom Sticky Bar: Tombol Buka di Google Maps
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: mediaQuery.padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: bgSurface,
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE5E7EB),
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                onPressed: () => _launchGoogleMaps(context),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.map_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Buka Rute di Google Maps',
                        style: GoogleFonts.lato(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoHeader(bool isDark) {
    String? photoUrl = fasyankes.imageUrl;
    try {
      final pList = fasyankes.photos;
      if ((photoUrl == null || photoUrl.isEmpty) && pList.isNotEmpty) {
        photoUrl = pList.first;
      }
    } catch (_) {}

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photoUrl != null && photoUrl.startsWith('http'))
              Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildFallbackPhotoHeader(isDark),
              )
            else
              _buildFallbackPhotoHeader(isDark),

            // Gradient Overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x99000000)],
                ),
              ),
            ),

            // Badge Kategori di Atas Kiri
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Text(
                  fasyankes.category,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Koordinat Terverifikasi di Bawah Kiri
            Positioned(
              left: 12,
              bottom: 12,
              child: Text(
                'Titik Koordinat: ${fasyankes.latitude.toStringAsFixed(6)}, ${fasyankes.longitude.toStringAsFixed(6)}',
                style: GoogleFonts.lato(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackPhotoHeader(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
              : [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_hospital_rounded,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 6),
            Text(
              fasyankes.category,
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: textColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String content,
    required bool isDark,
    VoidCallback? trailingAction,
    String? trailingLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF2B7AE8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF8696A0) : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF111827),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (trailingAction != null && trailingLabel != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: trailingAction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  trailingLabel,
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2B7AE8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewsList(bool isDark) {
    if (fasyankes.reviews.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2228) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Belum ada ulasan yang ditampilkan.',
            style: GoogleFonts.lato(
              fontSize: 13,
              color: isDark ? const Color(0xFF8696A0) : const Color(0xFF6B7280),
            ),
          ),
        ),
      );
    }

    return Column(
      children: fasyankes.reviews.map((review) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2228) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF2B7AE8),
                    child: Text(
                      review.authorName.isNotEmpty ? review.authorName[0].toUpperCase() : 'U',
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.authorName,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF111827),
                          ),
                        ),
                        Text(
                          review.relativeTime,
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF8696A0) : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: List.generate(review.rating.round().clamp(1, 5), (i) {
                      return const Icon(
                        Icons.star_rounded,
                        size: 15,
                        color: Color(0xFFFBBF24),
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                review.text,
                style: GoogleFonts.lato(
                  fontSize: 12.5,
                  color: isDark ? const Color(0xFFD1D7DB) : const Color(0xFF374151),
                  height: 1.35,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
