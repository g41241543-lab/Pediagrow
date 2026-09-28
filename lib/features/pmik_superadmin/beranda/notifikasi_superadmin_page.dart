import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/superadmin_notification_service.dart';
import '../../../models/superadmin_notification_model.dart';
import 'kelola_artikel/daftar_artikel_admin_page.dart';
import 'kelola_resep_mpasi/daftar_resep_mpasi_admin_page.dart';
import 'rekapitulasi/rekapitulasi_stunting_page.dart';
import '../profil/hak_akses/daftar_dokter_akses_page.dart';
import '../profil/hak_akses/daftar_pmik_akses_page.dart';
import 'beranda_superadmin_page.dart';


/// Halaman Notifikasi Superadmin PediaGrow.
///
/// Spesifikasi:
/// 1. Disimpan di `lib/features/pmik_superadmin/beranda/notifikasi_superadmin_page.dart`.
/// 2. Header berada di posisi atas (tinggi 56dp, tombol back 12dp dari pinggir kiri,
///    judul "Notifikasi" 12dp setelah tombol back, tanpa garis/border di bawahnya).
/// 3. Jika BELUM ada notifikasi:
///    - Menampilkan Empty State persis seperti pada halaman notifikasi pengguna:
///      lonceng kuning dengan garis getar, pendulum, dan teks "Belum ada notifikasi" (#C4C4C4).
/// 4. Notifikasi Otomatis oleh Sistem:
///    - CRUD Artikel Kesehatan (tambah, edit, hapus).
///    - CRUD Resep MPASI (tambah, edit, hapus).
///    - CRUD Dokter (tambah, edit, hapus).
///    - CRUD PMIK (tambah, edit, hapus).
///    - Notifikasi ketika superadmin berhasil unduh dataset.
///    - Notifikasi pengingat unduh dataset bulanan ("Info Dataset Cek Stunting").
///    - Hanya dibuat jika superadmin melakukan hal-hal tersebut atau jadwal sistem aktif.
class NotifikasiSuperadminPage extends StatefulWidget {
  const NotifikasiSuperadminPage({super.key});

  @override
  State<NotifikasiSuperadminPage> createState() =>
      _NotifikasiSuperadminPageState();
}

class _NotifikasiSuperadminPageState extends State<NotifikasiSuperadminPage> {
  final SuperadminNotificationService _notifService =
      SuperadminNotificationService();

  @override
  void initState() {
    super.initState();
    _notifService.init();
    // Tandai seluruh notifikasi sebagai sudah dibaca ketika halaman ini dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifService.markAllAsRead();
    });
  }

  void _onNotificationTap(SuperadminNotificationItem item) {
    switch (item.type) {
      case SuperadminNotificationType.artikel:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DaftarArtikelAdminPage()),
        );
        break;
      case SuperadminNotificationType.resepMpasi:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DaftarResepMpasiAdminPage()),
        );
        break;
      case SuperadminNotificationType.dokter:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DaftarDokterAksesPage()),
        );
        break;
      case SuperadminNotificationType.pmik:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DaftarPmikAksesPage()),
        );
        break;
      case SuperadminNotificationType.pengingatDataset:
      case SuperadminNotificationType.unduhDataset:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RekapitulasiStuntingPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // -----------------------------------------------------------------
            // HEADER (Tinggi 56dp dari atas, tanpa garis border di bawah)
            // -----------------------------------------------------------------
            _buildHeader(context),

            // -----------------------------------------------------------------
            // KONTEN NOTIFIKASI
            // -----------------------------------------------------------------
            Expanded(
              child: ValueListenableBuilder<List<SuperadminNotificationItem>>(
                valueListenable: _notifService.notificationsNotifier,
                builder: (context, notifications, _) {
                  if (notifications.isEmpty) {
                    // Tampilan kosong identik dengan notifikasi pengguna
                    return _buildEmptyState();
                  }

                  // Tampilan daftar notifikasi
                  return _buildNotificationList(notifications);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header 56dp tanpa border/divider di bawahnya.
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 56.0,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tombol back 12dp dari pinggir kiri
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const BerandaSuperadminPage()),
                );
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Icon(Icons.arrow_back, color: Color(0xFF000000), size: 24),
            ),
          ),
          // Nama halaman berjarak 12dp setelah tombol back
          const SizedBox(width: 12.0),
          Text(
            'Notifikasi',
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF000000),
            ),
          ),
        ],
      ),
    );
  }

  /// Tampilan Empty State:
  /// Identik dengan notifikasi pengguna: lonceng kuning & teks "Belum ada notifikasi" abu-abu.
  Widget _buildEmptyState() {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 140),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 225,
              child: Image.asset(
                'assets/images/lonceng_notif.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const CustomPaint(painter: _NotificationBellEmptyPainter()),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum ada notifikasi',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: const Color(0xFFC4C4C4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tampilan Daftar Notifikasi (Scrollable, sesuai gambar referensi pengguna)
  Widget _buildNotificationList(List<SuperadminNotificationItem> items) {
    return Column(
      children: [
        // Garis pemisah atas (tepat di bawah header)
        const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
        Expanded(
          child: ListView.separated(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildNotificationItem(context, item);
            },
          ),
        ),
      ],
    );
  }

  /// Item notifikasi dengan leading amplop hitam dalam lingkaran abu-abu
  Widget _buildNotificationItem(
      BuildContext context, SuperadminNotificationItem item) {
    return InkWell(
      onTap: () => _onNotificationTap(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lingkaran abu-abu dengan ikon amplop / surat hitam bergaris
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.mail_outline_rounded,
                color: Color(0xFF000000),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Teks Notifikasi (Judul, Isi Pesan, Tanggal)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul Notifikasi (Bold)
                  Text(
                    item.title,
                    style: GoogleFonts.lato(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 3),

                  // Isi Pesan Notifikasi
                  Text(
                    item.message,
                    style: GoogleFonts.lato(
                      fontSize: 13.5,
                      fontWeight: FontWeight.normal,
                      color: const Color(0xFF374151),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Tanggal Notifikasi (misal: "1 September 2026")
                  Text(
                    item.formattedDate,
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fallback CustomPainter untuk ilustrasi Lonceng Notifikasi Empty State
/// jika aset gambar `assets/images/lonceng_notif.png` belum dimuat.
class _NotificationBellEmptyPainter extends CustomPainter {
  const _NotificationBellEmptyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // 1. Bayangan oval abu-abu di bagian bawah
    final shadowPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 46), width: 104, height: 10),
      shadowPaint,
    );

    // 2. Tiga garis getar di atas lonceng (abu-abu gelap #3F4D5A)
    final ringPaint = Paint()
      ..color = const Color(0xFF3F4D5A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // Garis tengah (vertikal)
    canvas.drawLine(Offset(cx, cy - 64), Offset(cx, cy - 48), ringPaint);

    // Garis kiri (miring -35 derajat)
    canvas.drawLine(
      Offset(cx - 15, cy - 56),
      Offset(cx - 28, cy - 42),
      ringPaint,
    );

    // Garis kanan (miring +35 derajat)
    canvas.drawLine(
      Offset(cx + 15, cy - 56),
      Offset(cx + 28, cy - 42),
      ringPaint,
    );

    // 3. Pendulum / clapper lonceng di bagian bawah
    final clapperPaint = Paint()
      ..color = const Color(0xFF3F4D5A)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 30), width: 18, height: 18),
        const Radius.circular(9),
      ),
      clapperPaint,
    );

    // 4. Handle atas lonceng
    final bellColor = const Color(0xFFF6C138);
    final handlePaint = Paint()
      ..color = bellColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - 30), width: 18, height: 18),
        const Radius.circular(8),
      ),
      handlePaint,
    );

    // 5. Badan lonceng kuning (#F6C138)
    final bellPaint = Paint()
      ..color = bellColor
      ..style = PaintingStyle.fill;

    final bellPath = Path();
    bellPath.moveTo(cx - 10, cy - 24);
    bellPath.lineTo(cx + 10, cy - 24);
    bellPath.cubicTo(cx + 14, cy - 4, cx + 16, cy + 8, cx + 44, cy + 24);
    bellPath.quadraticBezierTo(cx + 47, cy + 29, cx + 40, cy + 30);
    bellPath.quadraticBezierTo(cx, cy + 31, cx - 40, cy + 30);
    bellPath.quadraticBezierTo(cx - 47, cy + 29, cx - 44, cy + 24);
    bellPath.cubicTo(cx - 16, cy + 8, cx - 14, cy - 4, cx - 10, cy - 24);
    bellPath.close();

    canvas.drawPath(bellPath, bellPaint);

    // 6. Bulatan toska di sisi kanan lonceng (#38B8A6)
    final tealPaint = Paint()
      ..color = const Color(0xFF38B8A6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx + 31, cy + 8), 9.0, tealPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
