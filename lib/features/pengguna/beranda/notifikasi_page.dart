import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/notification_service.dart';
import '../../../models/notification_model.dart';
import '../cek_stunting/pilih_anak_page.dart';
import '../riwayat_konsultasi/daftar_riwayat_page.dart';
import 'beranda_page.dart';

/// Halaman Notifikasi Pengguna PediaGrow.
///
/// Spesifikasi:
/// 1. Disimpan di `lib/features/pengguna/beranda/notifikasi_page.dart`.
/// 2. Halaman ini TIDAK DAPAT DI-SCROLL ke atas bawah.
/// 3. Header TETAP BERADA PADA POSISI ATAS:
///    - Tinggi 56dp dari atas layar hp (di bawah SafeArea).
///    - Tombol back terletak 12dp dari pinggir kiri layar.
///    - Nama halaman "Notifikasi" terletak 12dp setelah tombol back.
///    - Tombol back dapat diklik dan akan kembali ke BerandaPage.
///    - Garis atau border di bawah tombol back / header dihilangkan (tanpa garis).
/// 4. Tampilan awal adalah Tampilan Kosong (Empty State) seperti Gambar 1:
///    - Ilustrasi lonceng kuning dengan garis getar di atas, pendulum abu-abu di bawah,
///      lingkaran toska di samping kanan, dan bayangan oval abu-abu di bawahnya.
///    - Teks "Belum ada notifikasi" dengan warna abu-abu.
/// 5. Notifikasi Otomatis oleh Sistem (Gambar 2):
///    - Pengingat bulanan cek stunting pada rentang tanggal 1 - 10 setiap bulan.
///    - Dikirim 1 hari sekali berturut-turut hingga tanggal 10.
///    - Otomatis dihentikan jika pengguna telah melakukan cek stunting dalam rentang tanggal 1-10.
///    - Notifikasi cek stunting langsung terhubung ke halaman `PilihAnakPage`.
///    - Notifikasi konsultasi berakhir muncul setelah chat dengan dokter selesai dan
///      langsung terhubung ke halaman `DaftarRiwayatPage`.
class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  @override
  void initState() {
    super.initState();
    // Sistem otomatis mengecek jadwal pengingat bulanan (rentang tanggal 1-10)
    NotificationService().checkMonthlyStuntingReminder();
    // Tandai semua notifikasi sebagai sudah dibaca ─ badge angka di lonceng direset
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().markAllAsRead();
    });
  }

  void _onNotificationTap(NotificationItem item) {
    if (item.type == NotificationType.stunting) {
      // Terhubung langsung ke halaman Pilih Anak untuk cek stunting
      PilihAnakPage.show(context);
    } else if (item.type == NotificationType.consultation) {
      // Terhubung langsung ke halaman Riwayat Konsultasi
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const DaftarRiwayatPage()));
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
            // HEADER (Ukuran 56dp dari atas, tanpa garis/border di bawahnya)
            // -----------------------------------------------------------------
            _buildHeader(context),

            // -----------------------------------------------------------------
            // KONTEN NOTIFIKASI (Non-scrollable)
            // -----------------------------------------------------------------
            Expanded(
              child: ValueListenableBuilder<List<NotificationItem>>(
                valueListenable: NotificationService().notificationsNotifier,
                builder: (context, notifications, _) {
                  if (notifications.isEmpty) {
                    // Tampilan kosong (Gambar 1)
                    return _buildEmptyState();
                  }

                  // Tampilan daftar notifikasi (Gambar 2)
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
                  MaterialPageRoute(builder: (_) => const BerandaPage()),
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

  /// Tampilan Empty State (Gambar 1):
  /// Ilustrasi lonceng kuning & teks "Belum ada notifikasi" di tengah halaman.
  Widget _buildEmptyState() {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(
          top: 140,
        ), // atur angka ini untuk naik/turun
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

  /// Tampilan Daftar Notifikasi (Gambar 2):
  /// Scrollable agar semua notifikasi dapat dibaca meski banyak.
  Widget _buildNotificationList(List<NotificationItem> items) {
    return ListView.separated(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildNotificationItem(context, item);
      },
    );
  }

  /// Item notifikasi dengan leading amplop hitam dalam lingkaran abu-abu
  Widget _buildNotificationItem(BuildContext context, NotificationItem item) {
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
                  // Judul Notifikasi
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

                  // Tanggal Notifikasi (misal: "13 Juli 2026", "09 Mei 2026")
                  Text(
                    item.formattedDate,
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: const Color(0xFF9CA3AF),
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

/// CustomPainter untuk menggambar ilustrasi lonceng notifikasi persis seperti Gambar 1:
/// - 3 garis getar/sinar di atas lonceng (abu-abu gelap)
/// - Handle melengkung di atas lonceng (kuning)
/// - Badan lonceng kuning emas
/// - Bulatan aksen toska/teal di samping kanan badan lonceng
/// - Pendulum/clapper lonceng di bagian bawah (abu-abu gelap)
/// - Bayangan oval abu-abu muda di bawah lonceng
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

    // 3. Pendulum / clapper lonceng di bagian bawah (abu-abu gelap #3F4D5A)
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

    // 4. Handle atas lonceng (kubah bulat kecil warna kuning #F6C138)
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
    // Mulai dari puncak badan lonceng
    bellPath.moveTo(cx - 10, cy - 24);
    bellPath.lineTo(cx + 10, cy - 24);

    // Sisi kanan: kurva mengembang ke bawah
    bellPath.cubicTo(cx + 14, cy - 4, cx + 16, cy + 8, cx + 44, cy + 24);
    // Sudut kanan bawah membulat
    bellPath.quadraticBezierTo(cx + 47, cy + 29, cx + 40, cy + 30);

    // Dasar lonceng: sedikit melengkung lembut
    bellPath.quadraticBezierTo(cx, cy + 31, cx - 40, cy + 30);

    // Sudut kiri bawah membulat
    bellPath.quadraticBezierTo(cx - 47, cy + 29, cx - 44, cy + 24);

    // Sisi kiri: kurva mengembang ke atas
    bellPath.cubicTo(cx - 16, cy + 8, cx - 14, cy - 4, cx - 10, cy - 24);
    bellPath.close();

    canvas.drawPath(bellPath, bellPaint);

    // 6. Bulatan toska/cyan di sisi kanan lonceng (#38B8A6)
    final tealPaint = Paint()
      ..color = const Color(0xFF38B8A6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx + 31, cy + 8), 9.0, tealPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
