import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/google_auth_config.dart';
import '../../../core/services/google_auth_service.dart';
import '../../pengguna/beranda/beranda_page.dart';

/// Menampilkan dialog bantuan saat Google Sign-In gagal karena masalah konfigurasi
/// (misalnya SHA-1 belum didaftarkan di Google Cloud Console).
void showGoogleAuthErrorDialog(
  BuildContext context, {
  required String errorMessage,
  int? statusCode,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFDC2626),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusCode == 10
                  ? 'Konfigurasi Google API'
                  : 'Gagal Terhubung ke Google',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              statusCode == 10
                  ? 'Agar akun Google di HP Anda bisa tersambung, Google Cloud Console memerlukan pendaftaran sertifikat SHA-1 aplikasi ini.'
                  : errorMessage,
              style: GoogleFonts.lato(
                fontSize: 13,
                color: const Color(0xFF475569),
                height: 1.4,
              ),
            ),
            if (statusCode == 10) ...[
              const SizedBox(height: 14),
              _buildInfoTile(
                context,
                title: 'Package Name',
                value: GoogleAuthConfig.androidPackageName,
              ),
              const SizedBox(height: 8),
              _buildInfoTile(
                context,
                title: 'SHA-1 Fingerprint',
                value: GoogleAuthConfig.debugSha1,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Langkah di Google Cloud Console:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '1. Buka console.cloud.google.com\n'
                      '2. Pilih project PediaGrow\n'
                      '3. APIs & Services → Credentials → Create Credentials → OAuth client ID\n'
                      '4. Pilih Android, lalu masukkan Package Name & SHA-1 di atas.',
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (statusCode == 10)
          TextButton(
            onPressed: () {
              Clipboard.setData(
                const ClipboardData(text: GoogleAuthConfig.debugSha1),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('SHA-1 disalin ke clipboard!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              'Salin SHA-1',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3985E7),
              ),
            ),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            // Izinkan user tetap melanjutkan dengan akun demo agar tidak terhambat
            GoogleAuthService().loginWithDemoUser();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const BerandaPage()),
              (route) => false,
            );
          },
          child: Text(
            'Lanjutkan (Mode Demo)',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF10B981),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            'Tutup',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildInfoTile(
  BuildContext context, {
  required String title,
  required String value,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 16, color: Color(0xFF64748B)),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$title disalin ke clipboard!'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          tooltip: 'Salin',
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(4),
        ),
      ],
    ),
  );
}
