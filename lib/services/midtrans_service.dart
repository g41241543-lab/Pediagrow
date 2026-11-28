import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Service untuk berkomunikasi dengan backend Midtrans (Node.js Express).
///
/// PENTING:
/// - Server Key dan Client Key HANYA disimpan di backend demi keamanan.
/// - Jangan pernah menaruh Server Key atau Client Key di kode Flutter.
class MidtransService {
  static final MidtransService _instance = MidtransService._internal();
  factory MidtransService() => _instance;
  MidtransService._internal();

  /// Konfigurasi URL backend:
  /// - Emulator Android : 'http://10.0.2.2:4000'
  /// - HP Asli (Fisik)  : 'http://10.128.104.42:4000' (IP laptop Anda pada Wi-Fi saat ini)
  /// - iOS Simulator    : 'http://localhost:4000'
  ///
  /// Diatur otomatis ke IP laptop Anda untuk pengujian di HP fisik:
  static const String defaultBaseUrl = 'http://10.128.104.42:4000';

  String _baseUrl = defaultBaseUrl;

  /// Mendapatkan baseUrl saat ini
  String get baseUrl => _baseUrl;

  /// Mengubah baseUrl jika diperlukan secara dinamis
  set baseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Membuat transaksi baru via Midtrans Snap melalui backend.
  ///
  /// Parameter:
  /// - [orderId]: ID unik transaksi (misal: 'ORDER-1700000000000')
  /// - [amount]: Nominal tagihan dalam Rupiah (integer)
  /// - [customerName]: Nama pembayar/pengguna
  /// - [customerEmail]: Email pembayar/pengguna
  ///
  /// Mengembalikan:
  /// - [redirect_url]: URL Snap Midtrans yang dibuka di WebView.
  Future<String> buatTransaksi({
    required String orderId,
    required int amount,
    required String customerName,
    required String customerEmail,
  }) async {
    final uri = Uri.parse('$_baseUrl/midtrans/create-transaction');

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'orderId': orderId,
              'amount': amount,
              'customerName': customerName,
              'customerEmail': customerEmail,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        final redirectUrl = data['redirect_url'] as String?;
        if (redirectUrl != null && redirectUrl.isNotEmpty) {
          return redirectUrl;
        } else {
          throw Exception(
            'Backend tidak mengembalikan redirect_url Midtrans. Respons: ${response.body}',
          );
        }
      } else {
        String errorMsg = 'HTTP ${response.statusCode}';
        try {
          final dynamic errBody = jsonDecode(response.body);
          if (errBody is Map && errBody['message'] != null) {
            errorMsg = errBody['message'].toString();
          }
        } catch (_) {
          if (response.body.isNotEmpty) {
            errorMsg = response.body;
          }
        }
        throw Exception('Gagal membuat transaksi Midtrans: $errorMsg');
      }
    } on TimeoutException {
      throw Exception(
        'Koneksi timeout ke backend Midtrans ($baseUrl). Pastikan server backend Node.js sedang menyala di port 4000.',
      );
    } on SocketException catch (e) {
      throw Exception(
        'Tidak dapat terhubung ke backend Midtrans di $baseUrl.\n'
        '1. Pastikan backend Node.js telah dijalankan ("npm run dev" di folder android/midtrans-backend).\n'
        '2. Jika menggunakan HP fisik, ganti baseUrl dengan IP Laptop di MidtransService.defaultBaseUrl.\n'
        'Detail: ${e.message}',
      );
    } on http.ClientException catch (e) {
      throw Exception(
        'Gagal menghubungi server Midtrans di $baseUrl: ${e.message}',
      );
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan saat memproses transaksi: $e');
    }
  }

  /// Mengecek status transaksi ke backend Midtrans.
  ///
  /// Mengembalikan [transaction_status] dari Midtrans:
  /// - 'settlement' / 'capture' = Pembayaran berhasil
  /// - 'pending'                = Menunggu pembayaran
  /// - 'expire' / 'cancel' / 'deny' = Transaksi kadaluarsa / dibatalkan / ditolak
  Future<String> cekStatus(String orderId) async {
    final uri = Uri.parse('$_baseUrl/midtrans/status/$orderId');

    try {
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is Map && data.containsKey('transaction_status')) {
          return data['transaction_status']?.toString() ?? 'unknown';
        }
        return 'unknown';
      } else {
        String errorMsg = 'HTTP ${response.statusCode}';
        try {
          final dynamic errBody = jsonDecode(response.body);
          if (errBody is Map && errBody['message'] != null) {
            errorMsg = errBody['message'].toString();
          }
        } catch (_) {}
        throw Exception('Gagal mengecek status Midtrans: $errorMsg');
      }
    } on TimeoutException {
      throw Exception(
        'Koneksi timeout saat mengecek status Midtrans ($baseUrl).',
      );
    } on SocketException catch (e) {
      throw Exception(
        'Tidak dapat terhubung ke backend Midtrans di $baseUrl: ${e.message}',
      );
    } on http.ClientException catch (e) {
      throw Exception(
        'Gagal menghubungi server Midtrans di $baseUrl: ${e.message}',
      );
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Gagal mengecek status pembayaran: $e');
    }
  }

  /// Helper untuk memeriksa apakah transaksi berstatus lunas
  static bool isPaid(String status) {
    final s = status.toLowerCase();
    return s == 'settlement' || s == 'capture';
  }

  /// Helper untuk memeriksa apakah transaksi gagal / kadaluarsa
  static bool isFailed(String status) {
    final s = status.toLowerCase();
    return s == 'expire' || s == 'cancel' || s == 'deny';
  }
}
