import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'auth_choice_page.dart';
import 'register_page.dart';

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
/// 6. Tombol "Masuk" (350x52, #3985E7, Lato Bold 20 putih).
/// 7. Pemisah "atau" (Lato 16, #C5C5C5).
/// 8. Tombol "Masuk dengan Google" (350x52, border, Lato Bold 20 #000000).
/// 9. Footer: Belum memiliki Akun? Daftar (menuju RegisterPage).
/// 10. Seluruh batas konten berada 12dp dari pinggir kiri dan kanan layar.
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

  void _handleLogin() {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      // Validasi berhasil — navigasi ke beranda (placeholder snackbar dulu)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhasil masuk! Mengalihkan ke beranda...'),
          backgroundColor: Color(0xFF3985E7),
          duration: Duration(seconds: 2),
        ),
      );

      // TODO: ganti dengan navigasi ke BerandaPage setelah halaman tersebut dibuat
      // Future.delayed(const Duration(milliseconds: 900), () {
      //   if (!mounted) return;
      //   Navigator.of(context).pushAndRemoveUntil(
      //     MaterialPageRoute(builder: (_) => const BerandaPage()),
      //     (route) => false,
      //   );
      // });
    } else {
      setState(() {
        _autoValidateMode = AutovalidateMode.onUserInteraction;
      });
    }
  }

  void _showGoogleAccountPicker() {
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const _GoogleGLogo(size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Pilih akun Google',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'untuk masuk ke PediaGrow',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                _buildGoogleAccountTile(
                  ctx: ctx,
                  name: 'Pengguna PediaGrow',
                  email: 'pengguna.pediagrow@gmail.com',
                  initial: 'P',
                  avatarColor: const Color(0xFF3985E7),
                ),
                const Divider(height: 1),
                _buildGoogleAccountTile(
                  ctx: ctx,
                  name: 'Bunda Ceria',
                  email: 'bunda.ceria@gmail.com',
                  initial: 'B',
                  avatarColor: const Color(0xFF3CC3A6),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF1F5F9),
                    child: Icon(Icons.person_add_alt_1_outlined,
                        color: Color(0xFF475569)),
                  ),
                  title: Text(
                    'Gunakan akun lain',
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _completeGoogleSignIn('Akun Google Baru');
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoogleAccountTile({
    required BuildContext ctx,
    required String name,
    required String email,
    required String initial,
    required Color avatarColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: avatarColor,
        child: Text(
          initial,
          style: GoogleFonts.lato(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        name,
        style: GoogleFonts.lato(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1E293B),
        ),
      ),
      subtitle: Text(
        email,
        style: GoogleFonts.lato(
          fontSize: 13,
          color: const Color(0xFF64748B),
        ),
      ),
      onTap: () {
        Navigator.of(ctx).pop();
        _completeGoogleSignIn(email);
      },
    );
  }

  void _completeGoogleSignIn(String account) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Berhasil masuk dengan Google: $account'),
        backgroundColor: const Color(0xFF3985E7),
        duration: const Duration(seconds: 2),
      ),
    );

    // TODO: navigasi ke BerandaPage setelah halaman tersebut dibuat
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
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
                            fontSize: 16,
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
                            fontSize: 16,
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

                        // 4. Tombol Masuk (width: 350, height: 52)
                        Center(
                          child: SizedBox(
                            width: math.min(
                                350.0, MediaQuery.of(context).size.width - 24),
                            height: 52.0,
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
                                350.0, MediaQuery.of(context).size.width - 24),
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
                                      horizontal: 16.0),
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

                        // 6. Tombol Masuk dengan Google (width: 350, height: 52)
                        Center(
                          child: SizedBox(
                            width: math.min(
                                350.0, MediaQuery.of(context).size.width - 24),
                            height: 52.0,
                            child: OutlinedButton(
                              key: const Key('google_login_button'),
                              onPressed: _showGoogleAccountPicker,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0),
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
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                fontSize: 16,
                                color: const Color(0xFF000000),
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Belum memiliki Akun? ',
                                ),
                                TextSpan(
                                  text: 'Daftar',
                                  style: GoogleFonts.lato(
                                    fontSize: 16,
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
              child: Icon(
                Icons.arrow_back,
                color: Color(0xFF000000),
                size: 24,
              ),
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

  /// Judul setiap TextFormField (Lato reguler 18 #7F7F7F) + bintang merah (#B13535).
  Widget _buildFieldTitle(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: RichText(
        text: TextSpan(
          text: label,
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.normal,
            color: const Color(0xFF7F7F7F),
          ),
          children: [
            TextSpan(
              text: '*',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.normal,
                color: const Color(0xFFB13535),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dekorasi TextFormField dengan underline border:
  /// - Normal: abu-abu (#D1D5DB)
  /// - Fokus: biru (#3985E7)
  /// - Error: merah (#B13535)
  InputDecoration _buildInputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.only(top: 8, bottom: 8),
      hintText: hintText,
      hintStyle: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: const Color(0xFFC5C5C5),
      ),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      // Border normal (abu-abu)
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFD1D5DB), width: 1.0),
      ),
      // Border saat fokus (biru #3985E7)
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF3985E7), width: 2.0),
      ),
      // Border saat error (merah #B13535)
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFB13535), width: 1.5),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFB13535), width: 2.0),
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

/// Logo 'G' Google dengan 4 warna resmi (Biru, Merah, Kuning, Hijau).
class _GoogleGLogo extends StatelessWidget {
  final double size;
  const _GoogleGLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleGPainter(),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;
    const double strokeW = 0.22; // relatif terhadap radius

    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * strokeW
      ..strokeCap = StrokeCap.round;

    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * strokeW
      ..strokeCap = StrokeCap.round;

    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * strokeW
      ..strokeCap = StrokeCap.round;

    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * strokeW
      ..strokeCap = StrokeCap.round;

    // Lingkaran arc: mulai dari kanan (0°), berlawanan jarum jam
    // Merah: kanan-atas (dari ~315° ke 90°)
    final arcRect = Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78);

    canvas.drawArc(arcRect, -math.pi * 0.25, -math.pi * 1.0, false, paintRed);
    canvas.drawArc(arcRect, math.pi * 0.75, -math.pi * 0.5, false, paintBlue);
    canvas.drawArc(arcRect, math.pi * 0.25, math.pi * 0.5, false, paintGreen);
    canvas.drawArc(arcRect, -math.pi * 0.25, math.pi * 0.5, false, paintYellow);

    // Garis horizontal 'G' (bagian tengah)
    final double gLineY = cy;
    final double gLineX1 = cx;
    final double gLineX2 = cx + r * 0.7;
    canvas.drawLine(
      Offset(gLineX1, gLineY),
      Offset(gLineX2, gLineY),
      paintBlue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
