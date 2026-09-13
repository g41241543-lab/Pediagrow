import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/fasyankes_model.dart';

enum MapDisplayType {
  standard,
  satellite,
}

/// Widget Peta Interaktif Fasyankes menggunakan flutter_map + OpenStreetMap tile.
///
/// Fitur:
/// - Tile Map standar (OpenStreetMap) & Satellite (Esri World Imagery)
/// - Toggle Map / Satellite di kiri atas
/// - Zoom In (+) / Zoom Out (-) & Pusatkan ke Lokasi Saya
/// - Pinch-to-zoom & pan gesture native flutter_map
/// - Marker merah palang kesehatan untuk setiap fasyankes
/// - Marker biru pulsing untuk posisi pengguna
/// - Info callout saat fasyankes dipilih
class FasyankesMapWidget extends StatefulWidget {
  final List<FasyankesModel> fasyankesList;
  final FasyankesModel? selectedFasyankes;
  final double userLat;
  final double userLng;
  final ValueChanged<FasyankesModel>? onFasyankesSelected;
  final VoidCallback? onLocateUser;
  final double height;

  const FasyankesMapWidget({
    super.key,
    required this.fasyankesList,
    this.selectedFasyankes,
    required this.userLat,
    required this.userLng,
    this.onFasyankesSelected,
    this.onLocateUser,
    this.height = 270,
  });

  @override
  State<FasyankesMapWidget> createState() => _FasyankesMapWidgetState();
}

class _FasyankesMapWidgetState extends State<FasyankesMapWidget>
    with TickerProviderStateMixin {
  MapDisplayType _mapType = MapDisplayType.standard;
  late final MapController _mapController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Tile URL templates
  static const String _osmTile =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String _satelliteTile =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
  static const String _hybridLabelTile =
      'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Animasi pulsing untuk marker user
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant FasyankesMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animasikan kamera ke fasyankes yang dipilih
    if (widget.selectedFasyankes != null &&
        widget.selectedFasyankes != oldWidget.selectedFasyankes) {
      _animatedMove(
        LatLng(widget.selectedFasyankes!.latitude,
            widget.selectedFasyankes!.longitude),
        15.5,
      );
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Animasi gerak kamera (fly-to) menggunakan AnimationController
  void _animatedMove(LatLng destCenter, double destZoom) {
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destCenter.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destCenter.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    final animation =
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  void _zoomIn() {
    _mapController.move(
      _mapController.camera.center,
      (_mapController.camera.zoom + 1).clamp(3.0, 18.0),
    );
  }

  void _zoomOut() {
    _mapController.move(
      _mapController.camera.center,
      (_mapController.camera.zoom - 1).clamp(3.0, 18.0),
    );
  }

  void _locateUser() {
    _animatedMove(LatLng(widget.userLat, widget.userLng), 15.0);
    widget.onLocateUser?.call();
  }

  @override
  Widget build(BuildContext context) {
    final userLatLng = LatLng(widget.userLat, widget.userLng);
    final isSatellite = _mapType == MapDisplayType.satellite;

    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: Stack(
        children: [
          // --------------------------------------------------------
          // 1. PETA TILE ASLI (flutter_map)
          // --------------------------------------------------------
          ClipRect(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: userLatLng,
                initialZoom: 14.5,
                minZoom: 5.0,
                maxZoom: 18.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom |
                      InteractiveFlag.drag |
                      InteractiveFlag.doubleTapZoom |
                      InteractiveFlag.scrollWheelZoom,
                ),
              ),
              children: [
                // Tile layer utama
                TileLayer(
                  urlTemplate:
                      isSatellite ? _satelliteTile : _osmTile,
                  userAgentPackageName: 'com.pediagrow.app',
                  maxZoom: 18,
                  tileBuilder: isSatellite
                      ? null
                      : _osmTileBuilder,
                ),
                // Label overlay di atas satellite (agar nama jalan tetap terlihat)
                if (isSatellite)
                  TileLayer(
                    urlTemplate: _hybridLabelTile,
                    userAgentPackageName: 'com.pediagrow.app',
                    maxZoom: 18,
                  ),

                // --------------------------------------------------------
                // 2. MARKERS FASYANKES
                // --------------------------------------------------------
                MarkerLayer(
                  markers: [
                    // Marker Pengguna
                    Marker(
                      point: userLatLng,
                      width: 44,
                      height: 44,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Lingkaran pulsing aura
                              Container(
                                width: 36 * _pulseAnimation.value,
                                height: 36 * _pulseAnimation.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0x442563EB),
                                ),
                              ),
                              // Dot putih border
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              // Titik biru pusat
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Markers Fasyankes
                    ...widget.fasyankesList.map((fasyankes) {
                      final isSelected =
                          fasyankes.id == widget.selectedFasyankes?.id;
                      return Marker(
                        point:
                            LatLng(fasyankes.latitude, fasyankes.longitude),
                        width: isSelected ? 42 : 34,
                        height: isSelected ? 52 : 44,
                        alignment: Alignment.bottomCenter,
                        child: GestureDetector(
                          onTap: () =>
                              widget.onFasyankesSelected?.call(fasyankes),
                          child: _buildFasyankesMarker(isSelected),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),

          // --------------------------------------------------------
          // 3. KONTROL MAP / SATELLITE TOGGLE (Kiri Atas)
          // --------------------------------------------------------
          Positioned(
            left: 10,
            top: 10,
            child: _buildMapTypeToggle(),
          ),

          // --------------------------------------------------------
          // 4. KONTROL ZOOM & LOKASI (Kanan Atas)
          // --------------------------------------------------------
          Positioned(
            right: 10,
            top: 10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildControlBox(
                  children: [
                    _buildIconBtn(Icons.add, _zoomIn, 'Zoom In'),
                    Container(height: 1, width: 28, color: const Color(0xFFE5E7EB)),
                    _buildIconBtn(Icons.remove, _zoomOut, 'Zoom Out'),
                  ],
                ),
                const SizedBox(height: 6),
                _buildControlBox(
                  children: [
                    _buildIconBtn(
                      Icons.my_location_rounded,
                      _locateUser,
                      'Lokasi Saya',
                      color: const Color(0xFF2563EB),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --------------------------------------------------------
          // 5. CALLOUT INFO WINDOW saat fasyankes dipilih
          // --------------------------------------------------------
          if (widget.selectedFasyankes != null)
            Positioned(
              left: 10,
              right: 58,
              bottom: 10,
              child: _buildCallout(widget.selectedFasyankes!),
            ),

          // --------------------------------------------------------
          // 6. ATTRIBUTION (Kanan Bawah)
          // --------------------------------------------------------
          Positioned(
            right: 6,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                isSatellite ? '© Esri' : '© OpenStreetMap',
                style: GoogleFonts.lato(
                  fontSize: 8,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tile builder: tambahkan brightness sedikit agar OSM terlihat lebih bersih
  Widget _osmTileBuilder(BuildContext context, Widget tile, TileImage tileImage) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        // Slight desaturation + brightness boost untuk tampilan lebih clean
        0.93, 0.04, 0.03, 0, 5,
        0.03, 0.93, 0.04, 0, 5,
        0.02, 0.02, 0.93, 0, 5,
        0,    0,    0,    1, 0,
      ]),
      child: tile,
    );
  }

  Widget _buildFasyankesMarker(bool isSelected) {
    final pinColor =
        isSelected ? const Color(0xFFDC2626) : const Color(0xFFE11D48);
    final size = isSelected ? 42.0 : 34.0;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Shadow elips di bawah pin
        Positioned(
          bottom: 0,
          child: Container(
            width: size * 0.55,
            height: size * 0.18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.22),
            ),
          ),
        ),
        // Badan Pin
        CustomPaint(
          size: Size(size, size * 1.2),
          painter: _PinPainter(color: pinColor, isSelected: isSelected),
        ),
      ],
    );
  }

  Widget _buildMapTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD1D5DB), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleBtn('Map', _mapType == MapDisplayType.standard, () {
            setState(() => _mapType = MapDisplayType.standard);
          }),
          Container(width: 1, height: 26, color: const Color(0xFFE5E7EB)),
          _buildToggleBtn('Satellite', _mapType == MapDisplayType.satellite,
              () {
            setState(() => _mapType = MapDisplayType.satellite);
          }),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(
      String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        color: isActive
            ? const Color(0xFFEFF6FF)
            : Colors.transparent,
        child: Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive
                ? const Color(0xFF1D4ED8)
                : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildControlBox({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD1D5DB), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _buildIconBtn(
    IconData icon,
    VoidCallback onTap,
    String tooltip, {
    Color color = const Color(0xFF374151),
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _buildCallout(FasyankesModel fasyankes) {
    return GestureDetector(
      onTap: () async {
        // Buka di Google Maps dengan nama + koordinat akurat
        final uri = Uri.parse(fasyankes.googleMapsUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF93C5FD), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_hospital_rounded,
                  color: Color(0xFFDC2626), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fasyankes.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${fasyankes.category} • ${fasyankes.formattedDistance}',
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Buka Maps',
                style: GoogleFonts.lato(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------
// CustomPainter untuk pin marker fasyankes berbentuk drop/teardrop
// -----------------------------------------------------------------------
class _PinPainter extends CustomPainter {
  final Color color;
  final bool isSelected;

  _PinPainter({required this.color, required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Badan pin
    final pinPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Shadow pin
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final path = ui.Path();
    path.moveTo(cx, h * 0.95); // ujung bawah
    path.cubicTo(
      cx - w * 0.08, h * 0.7,
      0, h * 0.42,
      0, h * 0.35,
    );
    path.arcToPoint(
      Offset(w, h * 0.35),
      radius: Radius.circular(w / 2),
      clockwise: false,
    );
    path.cubicTo(
      w, h * 0.42,
      cx + w * 0.08, h * 0.7,
      cx, h * 0.95,
    );
    path.close();

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, pinPaint);

    // Lingkaran putih dalam pin
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, h * 0.34), w * 0.22, innerPaint);

    // Ikon palang kesehatan (+)
    final crossPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final crossW = w * 0.12;
    final crossH = w * 0.28;
    // Horizontal
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, h * 0.34),
          width: crossH,
          height: crossW,
        ),
        const Radius.circular(2),
      ),
      crossPaint,
    );
    // Vertikal
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, h * 0.34),
          width: crossW,
          height: crossH,
        ),
        const Radius.circular(2),
      ),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PinPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isSelected != isSelected;
}
