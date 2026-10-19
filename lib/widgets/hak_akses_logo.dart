import 'package:flutter/material.dart';

/// Widget logo kustom modern "Ponsel dengan Gembok" (Hak Akses).
///
/// Dibuat secara vektor murni agar memiliki resolusi tajam di semua DPI layar,
/// tidak memerlukan aset gambar eksternal, dan mendukung status aktif maupun disabled.
class HakAksesLogo extends StatelessWidget {
  final bool isDisabled;
  final double size;

  const HakAksesLogo({
    super.key,
    this.isDisabled = false,
    this.size = 38.0,
  }) : assert(size > 0, 'size must be greater than 0');

  @override
  Widget build(BuildContext context) {
    // Skala proporsional relatif terhadap ukuran dasar 38dp
    final scale = size / 38.0;

    final phoneBorderColor = isDisabled
        ? const Color(0xFF8696A0)
        : const Color(0xFF0369A1); // Sky 700
    final phoneScreenColors = isDisabled
        ? [const Color(0xFFE9EDEF), const Color(0xFFD1D7DB)]
        : [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)]; // Sky 100 -> Sky 200
    final phoneDetailColor = isDisabled
        ? const Color(0xFF8696A0)
        : const Color(0xFF0284C7);

    final shackleColor = isDisabled
        ? const Color(0xFF667781)
        : const Color(0xFFD97706); // Golden Amber 600
    final lockBodyColor = isDisabled
        ? const Color(0xFF8696A0)
        : const Color(0xFFF59E0B); // Golden Amber 500
    final lockBorderColor = isDisabled
        ? const Color(0xFF667781)
        : const Color(0xFFB45309); // Amber 700

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: SizedBox(
          width: 26 * scale,
          height: 36 * scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. BODI PONSEL
              Container(
                width: 26 * scale,
                height: 36 * scale,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: phoneScreenColors,
                  ),
                  borderRadius: BorderRadius.circular(6 * scale),
                  border: Border.all(
                    color: phoneBorderColor,
                    width: 1.6 * scale,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDisabled ? 0.04 : 0.12,
                      ),
                      blurRadius: 3 * scale,
                      offset: Offset(0, 1.5 * scale),
                    ),
                  ],
                ),
              ),

              // 2. SPEAKER / NOTCH ATAS
              Positioned(
                top: 2.8 * scale,
                child: Container(
                  width: 7 * scale,
                  height: 1.4 * scale,
                  decoration: BoxDecoration(
                    color: phoneDetailColor,
                    borderRadius: BorderRadius.circular(1 * scale),
                  ),
                ),
              ),

              // 3. HOME INDICATOR BAWAH
              Positioned(
                bottom: 2.8 * scale,
                child: Container(
                  width: 9 * scale,
                  height: 1.4 * scale,
                  decoration: BoxDecoration(
                    color: phoneDetailColor,
                    borderRadius: BorderRadius.circular(1 * scale),
                  ),
                ),
              ),

              // 4. GEMBOK KEAMANAN (TENGAH LAYAR)
              Positioned(
                top: 8.5 * scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tangkai gembok (Shackle)
                    Container(
                      width: 10.5 * scale,
                      height: 7.5 * scale,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(5.5 * scale),
                        ),
                        border: Border(
                          top: BorderSide(
                            color: shackleColor,
                            width: 2.2 * scale,
                          ),
                          left: BorderSide(
                            color: shackleColor,
                            width: 2.2 * scale,
                          ),
                          right: BorderSide(
                            color: shackleColor,
                            width: 2.2 * scale,
                          ),
                        ),
                      ),
                    ),
                    // Badan gembok (Lock Body)
                    Container(
                      width: 15 * scale,
                      height: 11 * scale,
                      decoration: BoxDecoration(
                        color: lockBodyColor,
                        borderRadius: BorderRadius.circular(3 * scale),
                        border: Border.all(
                          color: lockBorderColor,
                          width: 0.8 * scale,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 2 * scale,
                            offset: Offset(0, 1 * scale),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Titik lubang kunci
                            Container(
                              width: 3.2 * scale,
                              height: 3.2 * scale,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            // Batang lubang kunci
                            Container(
                              width: 1.4 * scale,
                              height: 2.2 * scale,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  0.6 * scale,
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
            ],
          ),
        ),
      ),
    );
  }
}
