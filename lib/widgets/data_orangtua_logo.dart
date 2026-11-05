import 'package:flutter/material.dart';

/// Widget logo kustom modern "ID Card / Badge Orang Tua" (Data Orangtua).
///
/// Didesain selaras secara visual dengan ikon "Grafik Pertumbuhan"
/// (aksen kuning, ungu/biru, cyan dan garis bingkai tegas) dan "Resume Medis"
/// (buku/kartu bergradien teal-kebiruan dengan siluet avatar putih).
///
/// Memuat gambar aset 3D 'assets/images/data_orangtua_logo.png' dan memiliki
/// fallback vektor mandiri jika aset belum termuat atau saat development/hot reload.
class DataOrangtuaLogo extends StatelessWidget {
  final double size;

  const DataOrangtuaLogo({
    super.key,
    this.size = 36.0,
  }) : assert(size > 0, 'size must be greater than 0');

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/data_orangtua_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => _buildVectorBadge(),
    );
  }

  Widget _buildVectorBadge() {
    // Rasio skala terhadap ukuran standar 36dp
    final scale = size / 36.0;

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: SizedBox(
          width: 32 * scale,
          height: 36 * scale,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // 1. KLIP LANYARD / GANTUNGAN BADGE (Paling atas)
              Positioned(
                top: 0,
                child: Container(
                  width: 11 * scale,
                  height: 4.5 * scale,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B), // Slate gelap
                    borderRadius: BorderRadius.circular(1.8 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 1.5 * scale,
                        offset: Offset(0, 1 * scale),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 5 * scale,
                    height: 1.8 * scale,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(0.9 * scale),
                    ),
                  ),
                ),
              ),

              // 2. BADAN KARTU BADGE ORANG TUA
              Positioned(
                top: 3.5 * scale,
                child: Container(
                  width: 29 * scale,
                  height: 32.5 * scale,
                  decoration: BoxDecoration(
                    // Gradien selaras dengan Resume Medis (Teal to Blue)
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0D9488), // Teal tajam
                        Color(0xFF0284C7), // Sky blue
                        Color(0xFF2563EB), // Royal blue
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                        blurRadius: 4 * scale,
                        offset: Offset(0, 2 * scale),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      // Aksen garis lengkung bawah seperti punggung buku Resume Medis
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3.5 * scale,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D4ED8),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(6 * scale),
                              bottomRight: Radius.circular(6 * scale),
                            ),
                          ),
                        ),
                      ),

                      // Area Siluet Avatar Orang Tua (Kepala + Pundak)
                      Positioned(
                        top: 3.5 * scale,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Kepala bulat
                            Container(
                              width: 8.5 * scale,
                              height: 8.5 * scale,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(height: 1.5 * scale),
                            // Pundak / Torso melengkung
                            Container(
                              width: 14 * scale,
                              height: 6 * scale,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(7 * scale),
                                  bottom: Radius.circular(2.5 * scale),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Baris Data / Garis Kredensial Identitas
                      // Baris 1: Kuning cerah (selaras dengan batang kuning grafik pertumbuhan)
                      Positioned(
                        bottom: 9 * scale,
                        child: Container(
                          width: 16 * scale,
                          height: 2.2 * scale,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE047), // Yellow-300
                            borderRadius: BorderRadius.circular(1.2 * scale),
                          ),
                        ),
                      ),

                      // Baris 2: Cyan / Biru lembut (selaras dengan batang cyan grafik)
                      Positioned(
                        bottom: 5.2 * scale,
                        child: Container(
                          width: 11 * scale,
                          height: 1.8 * scale,
                          decoration: BoxDecoration(
                            color: const Color(0xFFBAE6FD), // Sky-200
                            borderRadius: BorderRadius.circular(1 * scale),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

