import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pediagrow/core/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/user_service.dart';
import '../../core/services/child_service.dart';
import '../../core/services/google_auth_service.dart';
import '../../models/user_model.dart';

import 'auth_choice_page.dart';
import 'register_page.dart';
import 'widgets/google_auth_dialog.dart';
import '../pengguna/beranda/beranda_page.dart';
import '../../shared/widgets/pedia_banner.dart';

/// Halaman Masuk (Login Page) PediaGrow.
///
/// Spesifikasi:
/// 1. Dapat diakses oleh semua role setelah klik "Masuk" di AuthChoicePage
///    atau setelah klik teks "Masuk" berwarna biru di RegisterPage.
/// 2. Header (tombol kembali + judul "Masuk") TETAP DI ATAS (56dp).
///    - Tombol kembali: 12dp dari pinggir kiri.
///    - Judul: 12dp setelah tombol kembali, Lato Bold 20 (#000000).
/// 3. Ilustrasi login (width: 291, height: 163).
/// 4. 2 TextFormField:
///    - Email (valid Gmail)
///    - Kata Sandi (min 6 karakter)
/// 5. Visual border: normal abu-abu, fokus biru (#3985E7), error merah (#B13535).
/// 6. Tombol "Masuk" (350x46, #3985E7, Lato Bold 20 putih).
/// 7. Pemisah "atau" (Lato 16, #C5C5C5).
/// 8. Tombol "Masuk dengan Google" (350x46, border, Lato Bold 20 #000000).
/// 9. Footer: Belum memiliki Akun? Daftar (menuju RegisterPage).
/// 10. Seluruh batas konten berada 16dp dari pinggir kiri dan kanan layar.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // FocusNodes untuk visual border state
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // Toggle visibilitas kata sandi
  bool _obscurePassword = true;

  // Loading state untuk tombol Google Sign-In (cegah double-tap)
  bool _isGoogleLoading = false;

  // Mode validasi otomatis setelah tombol Masuk pertama kali ditekan
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      final hasil = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (hasil['status'] == 'sukses') {
        final int idAkun = int.tryParse(hasil['id']?.toString() ?? '0') ?? 0;
        final String namaUser = hasil['nama']?.toString() ?? 'Pengguna';
        final String emailUser =
            (hasil['email']?.toString() ?? _emailController.text).trim();
        final String? fotoUrl = hasil['foto_url']?.toString();

        // Simpan token & profil pengguna ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', hasil['token']?.toString() ?? '');
        await prefs.setString(
          'peran',
          hasil['peran']?.toString() ?? 'orang_tua',
        );
        await prefs.setInt('id_akun', idAkun);
        await prefs.setString('nama', namaUser);
        await prefs.setString('email', emailUser);
        if (fotoUrl != null) {
          await prefs.setString('foto_url', fotoUrl);
        }

        // Perbarui UserService reaktif agar profil di UI langsung sesuai akun database
        UserService().currentUserNotifier.value = UserModel(
          id: idAkun.toString(),
          name: namaUser,
          email: emailUser,
          avatarPath: fotoUrl,
        );

        // Muat data profil anak milik user dari database MySQL
        if (idAkun > 0) {
          await ChildService().loadChildrenFromApi(idAkun);
        }

        if (!mounted) return;

        PediaBanner.showSuccess(
          context,
          message: 'Berhasil masuk! Mengalihkan ke beranda...',
        );

        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const BerandaPage(showLengkapiProfilBanner: true),
            ),
            (route) => false,
          );
        });
      } else {
        PediaBanner.showError(
          context,
          message: hasil['pesan'] ?? 'Email atau kata sandi salah.',
        );
      }
    } else {
      setState(() {
        _autoValidateMode = AutovalidateMode.onUserInteraction;
      });
    }
  }

  /// Memulai alur Google Sign-In menggunakan [GoogleAuthService].
  /// Menampilkan native OS account picker — pengguna memilih akun Google
  /// yang terdaftar di perangkat mereka sendiri.
  Future<void> _handleGoogleSignIn() async {
    FocusScope.of(context).unfocus();

    if (_isGoogleLoading) return; // Cegah double-tap

    setState(() => _isGoogleLoading = true);

    try {
      final result = await GoogleAuthService().signIn();

      if (!mounted) return;

      if (result.isCancelled) {
        // Pengguna membatalkan dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Masuk dengan Google dibatalkan.',
              style: GoogleFonts.lato(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF64748B),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      if (!result.isSuccess) {
        showGoogleAuthErrorDialog(
          context,
          errorMessage: result.errorMessage ?? 'Gagal masuk dengan Google.',
          statusCode: result.statusCode,
        );
        return;
      }

      final account = result.account!;

      // Berhasil — tampilkan pesan sambutan lalu navigasi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selamat datang, ${account.displayName ?? account.email}!',
            style: GoogleFonts.lato(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF3985E7),
          duration: const Duration(milliseconds: 1500),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const BerandaPage(showLengkapiProfilBanner: true),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      showGoogleAuthErrorDialog(
        context,
        errorMessage: 'Gagal masuk dengan Google: $e',
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              // ---------------------------------------------------------------
              // HEADER TETAP BERADA PADA POSISI ATAS (56dp)
              // ---------------------------------------------------------------
              _buildFixedHeader(context),

              // ---------------------------------------------------------------
              // KONTEN YANG DAPAT DI-SCROLL (keyboard-aware)
              // ---------------------------------------------------------------
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _autoValidateMode,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),

                        // 1. Ilustrasi Login (width: 291, height: 163)
                        Center(
                          child: SizedBox(
                            width: 291,
                            height: 163,
                            child: Image.asset(
                              'assets/images/login_illustration.jpg',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/family_illustration.png',
                                  fit: BoxFit.contain,
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 2. Field: Email
                        _buildFieldTitle('Email'),
                        TextFormField(
                          key: const Key('login_email_field'),
                          controller: _emailController,
                          focusNode: _emailFocus,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: const Color(0xFF1E293B),
                          ),
                          decoration: _buildInputDecoration(
                            hintText: 'Masukkan email aktif anda',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email wajib diisi';
                            }
                            final trimmed = value.trim();
                            final gmailRegex = RegExp(
                              r'^[a-zA-Z0-9._%+-]+@gmail\.com$',
                            );
                            if (!gmailRegex.hasMatch(trimmed)) {
                              return 'Email harus berupa akun Gmail yang valid (@gmail.com)';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // 3. Field: Kata Sandi
                        _buildFieldTitle('Kata Sandi'),
                        TextFormField(
                          key: const Key('login_password_field'),
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleLogin(),
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: const Color(0xFF1E293B),
                          ),
                          decoration: _buildInputDecoration(
                            hintText: 'Kata Sandi min. 6 karakter',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF94A3B8),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Kata sandi wajib diisi';
                            }
                            if (value.length < 6) {
                              return 'Kata sandi minimal 6 karakter';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 32),

                        // 4. Tombol Masuk (width: 350, height: 46)
                        Center(
                          child: SizedBox(
                            width: math.min(
                              350.0,
                              MediaQuery.of(context).size.width - 32,
                            ),
                            height: 46.0,
                            child: ElevatedButton(
                              key: const Key('login_button'),
                              onPressed: _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3985E7),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Masuk',
                                  style: GoogleFonts.lato(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFFFFFF),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 5. Garis Pemisah "atau"
                        Center(
                          child: SizedBox(
                            width: math.min(
                              350.0,
                              MediaQuery.of(context).size.width - 32,
                            ),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Divider(
                                    color: Color(0xFFC5C5C5),
                                    thickness: 1.0,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Text(
                                    'atau',
                                    style: GoogleFonts.lato(
                                      fontSize: 16,
                                      fontWeight: FontWeight.normal,
                                      color: const Color(0xFFC5C5C5),
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: Divider(
                                    color: Color(0xFFC5C5C5),
                                    thickness: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 6. Tombol Masuk dengan Google (width: 350, height: 46)
                        Center(
                          child: SizedBox(
                            width: math.min(
                              350.0,
                              MediaQuery.of(context).size.width - 32,
                            ),
                            height: 46.0,
                            child: OutlinedButton(
                              key: const Key('google_login_button'),
                              // Gunakan _handleGoogleSignIn() yang real; nonaktifkan saat loading
                              onPressed: _isGoogleLoading
                                  ? null
                                  : _handleGoogleSignIn,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                ),
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF000000),
                                side: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                  width: 1.0,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                              ),
                              child: _isGoogleLoading
                                  // Loading spinner saat menunggu Google account picker
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFF3985E7),
                                            ),
                                      ),
                                    )
                                  : FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const _GoogleGLogo(size: 24),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Masuk dengan Google',
                                            style: GoogleFonts.lato(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF000000),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 7. Teks "Belum memiliki Akun? Daftar"
                        Center(
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: const Color(0xFF000000),
                              ),
                              children: [
                                const TextSpan(text: 'Belum memiliki Akun? '),
                                TextSpan(
                                  text: 'Daftar',
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    color: const Color(0xFF3985E7),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const RegisterPage(),
                                        ),
                                      );
                                    },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Header yang TETAP BERADA PADA POSISI ATAS (56dp) saat konten di-scroll.
  Widget _buildFixedHeader(BuildContext context) {
    return Container(
      height: 56.0,
      color: Colors.white,
      padding: const EdgeInsets.only(left: 12.0, right: 12.0),
      child: Row(
        children: [
          // Tombol back: 12dp dari pinggir kiri layar
          GestureDetector(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AuthChoicePage()),
                );
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Icon(Icons.arrow_back, color: Color(0xFF000000), size: 24),
            ),
          ),
          // Nama halaman: 12dp setelah tombol back
          const SizedBox(width: 12.0),
          Text(
            'Masuk',
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

  /// Judul setiap TextFormField (Lato reguler 16 #7F7F7F) + bintang merah (#B13535).
  Widget _buildFieldTitle(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          text: label,
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: const Color(0xFF000000),
          ),
          children: [
            TextSpan(
              text: '*',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: const Color(0xFFB13535),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dekorasi TextFormField:
  /// - Bentuk: Kotak (OutlineInputBorder) dengan radius 10dp
  /// - Normal: border abu-abu (#CBD5E1)
  /// - Fokus: border biru (#3985E7)
  /// - Error: border merah (#B13535)
  InputDecoration _buildInputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintText: hintText,
      hintStyle: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: const Color(0xFF94A3B8),
      ),
      suffixIcon: suffixIcon,
      // Border normal (kotak dengan corner radius 10)
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      // Border saat fokus (biru #3985E7)
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF3985E7), width: 1.5),
      ),
      // Border saat error (merah #B13535)
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFB13535), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFB13535), width: 2.0),
      ),
      // Pesan error di bawah dengan warna #B13535
      errorStyle: GoogleFonts.lato(
        color: const Color(0xFFB13535),
        fontSize: 13,
        height: 1.25,
      ),
    );
  }
}

/// Logo 'G' Google resmi saat ini dengan 4 warna (Biru, Merah, Kuning, Hijau).
class _GoogleGLogo extends StatelessWidget {
  final double size;
  const _GoogleGLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: const _GoogleGPainter(),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24.0, size.height / 24.0);

    // 1. Biru (#4285F4) - Palang horizontal dan lengkungan kanan
    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final pathBlue = Path()
      ..moveTo(23.75, 12.27)
      ..cubicTo(23.75, 11.57, 23.69, 10.87, 23.56, 10.2)
      ..lineTo(12.0, 10.2)
      ..lineTo(12.0, 14.71)
      ..lineTo(18.6, 14.71)
      ..cubicTo(18.31, 16.23, 17.46, 17.53, 16.2, 18.39)
      ..lineTo(16.2, 21.44)
      ..lineTo(20.08, 21.44)
      ..cubicTo(22.35, 19.35, 23.75, 16.27, 23.75, 12.27)
      ..close();
    canvas.drawPath(pathBlue, paintBlue);

    // 2. Hijau (#34A853) - Lengkungan bawah
    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final pathGreen = Path()
      ..moveTo(12.0, 24.0)
      ..cubicTo(15.24, 24.0, 17.95, 22.92, 19.93, 21.09)
      ..lineTo(16.05, 18.04)
      ..cubicTo(14.97, 18.76, 13.6, 19.2, 12.0, 19.2)
      ..cubicTo(8.88, 19.2, 6.23, 17.1, 5.28, 14.27)
      ..lineTo(1.25, 14.27)
      ..lineTo(1.25, 17.42)
      ..cubicTo(3.26, 21.36, 7.33, 24.0, 12.0, 24.0)
      ..close();
    canvas.drawPath(pathGreen, paintGreen);

    // 3. Kuning (#FBBC05) - Lengkungan kiri
    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final pathYellow = Path()
      ..moveTo(5.28, 14.27)
      ..cubicTo(5.03, 13.55, 4.9, 12.78, 4.9, 12.0)
      ..cubicTo(4.9, 11.22, 5.03, 10.45, 5.28, 9.73)
      ..lineTo(5.28, 6.58)
      ..lineTo(1.25, 6.58)
      ..cubicTo(0.45, 8.18, 0.0, 9.99, 0.0, 12.0)
      ..cubicTo(0.0, 14.01, 0.45, 15.82, 1.25, 17.42)
      ..lineTo(5.28, 14.27)
      ..close();
    canvas.drawPath(pathYellow, paintYellow);

    // 4. Merah (#EA4335) - Lengkungan atas
    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    final pathRed = Path()
      ..moveTo(12.0, 4.75)
      ..cubicTo(13.77, 4.75, 15.35, 5.36, 16.6, 6.55)
      ..lineTo(20.02, 3.13)
      ..cubicTo(17.95, 1.19, 15.24, 0.0, 12.0, 0.0)
      ..cubicTo(7.33, 0.0, 3.26, 2.64, 1.25, 6.58)
      ..lineTo(5.28, 9.73)
      ..cubicTo(6.23, 6.9, 8.88, 4.75, 12.0, 4.75)
      ..close();
    canvas.drawPath(pathRed, paintRed);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
