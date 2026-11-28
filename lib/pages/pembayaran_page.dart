import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Halaman WebView untuk menampilkan antarmuka pembayaran Midtrans Snap.
///
/// Pengguna dapat memilih metode bayar yang tersedia di Snap (QRIS, GoPay, Transfer Bank, dll).
/// Ketika selesai atau menutup halaman, halaman ini akan kembali dan mengembalikan nilai ke halaman pemanggil
/// agar status pembayaran segera diverifikasi.
class PembayaranPage extends StatefulWidget {
  final String redirectUrl;
  final String orderId;

  const PembayaranPage({
    super.key,
    required this.redirectUrl,
    required this.orderId,
  });

  @override
  State<PembayaranPage> createState() => _PembayaranPageState();
}

class _PembayaranPageState extends State<PembayaranPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initWebViewController();
  }

  void _initWebViewController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _progress = progress / 100.0;
                if (progress >= 100) {
                  _isLoading = false;
                }
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('[Midtrans WebView] Error (${error.errorCode}): ${error.description}');
            if (error.isForMainFrame ?? true) {
              if (mounted && _isLoading) {
                setState(() {
                  _errorMessage = error.description;
                  _isLoading = false;
                });
              }
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Tutup Pembayaran?',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          'Jika Anda sudah melakukan pembayaran (misalnya via QRIS atau Transfer Bank), status transaksi akan dicek secara otomatis di halaman berikutnya.',
          style: GoogleFonts.lato(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Lanjutkan Bayar',
              style: GoogleFonts.lato(color: Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3985E7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Sudah Bayar / Tutup',
              style: GoogleFonts.lato(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldExit = await _confirmExit();
        if (shouldExit && mounted) {
          navigator.pop(true);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1A2228)),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final shouldExit = await _confirmExit();
              if (shouldExit && mounted) {
                navigator.pop(true);
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pembayaran',
                style: GoogleFonts.lato(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A2228),
                ),
              ),
              Text(
                widget.orderId,
                style: GoogleFonts.lato(
                  fontSize: 11,
                  color: const Color(0xFF667781),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: Color(0xFF3985E7), size: 20),
              tooltip: 'Salin Link Pembayaran',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.redirectUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Link Snap pembayaran berhasil disalin!',
                      style: GoogleFonts.lato(fontSize: 13),
                    ),
                    backgroundColor: const Color(0xFF1E293B),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.open_in_browser_rounded, color: Color(0xFF3985E7), size: 22),
              tooltip: 'Buka di Browser Luar (Chrome)',
              onPressed: () async {
                final uri = Uri.parse(widget.redirectUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF3985E7)),
              tooltip: 'Muat Ulang',
              onPressed: () => _controller.reload(),
            ),
          ],
          bottom: _isLoading
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(3.0),
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    backgroundColor: const Color(0xFFE9EDEF),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3985E7)),
                    minHeight: 3.0,
                  ),
                )
              : null,
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading && _progress < 0.2)
              const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF3985E7),
                ),
              ),
            if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text(
                        'Gagal Memuat Halaman Pembayaran',
                        style: GoogleFonts.lato(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(fontSize: 12.5, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                            _isLoading = true;
                          });
                          _controller.reload();
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Coba Lagi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3985E7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
    );
  }
}
