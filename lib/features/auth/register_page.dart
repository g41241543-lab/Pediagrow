import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'auth_choice_page.dart';
import 'login_page.dart';
import 'terms_page.dart';
import '../../shared/widgets/pedia_banner.dart';

/// Halaman Pendaftaran Akun Baru (Register Page) PediaGrow.
///
/// Spesifikasi:
/// 1. Khusus untuk role pengguna setelah klik "Daftar Akun Baru".
/// 2. Header (tombol kembali + judul "Daftar Akun Baru") TETAP DI ATAS (pinned 56dp).
///    - Tombol kembali: 12dp dari pinggir kiri.
///    - Judul: 12dp setelah tombol kembali, Lato Bold 20 (#000000).
/// 3. Ilustrasi keluarga (width: 247, height: 155).
/// 4. 4 TextFormField dengan label Lato 16 (#7F7F7F) + bintang merah (#B13535):
///    - Nama Pengguna (huruf saja)
///    - Email (valid Gmail)
///    - Kata Sandi (min 6 karakter, kombinasi huruf, angka, simbol)
///    - Konfirmasi Kata Sandi (harus cocok)
/// 5. Visual border: normal abu-abu, fokus biru (#3985E7), error merah (#B13535).
/// 6. Tombol "Daftar" (350x46, #3985E7, Lato Bold 20 putih).
/// 7. Pemisah "atau" (Lato 16, #C5C5C5).
/// 8. Tombol "Daftar dengan Google" (350x46, border, Lato Bold 20 #000000)
///    dengan dialog/bottom sheet pemilihan akun Google.
/// 9. Footer: Syarat & Ketentuan (menuju TermsPage) dan Masuk (menuju LoginPage).
/// 10. Seluruh batas konten berada 16dp dari pinggir kiri dan kanan layar.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Controller
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // FocusNode untuk visual border state & dismiss keyboard
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  // Toggle visibilitas kata sandi
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Mode validasi otomatis setelah tombol Daftar pertama kali ditekan
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    // Listener untuk memperbarui border fokus secara reaktif
    _nameFocus.addListener(() => setState(() {}));
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
    _confirmPasswordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _handleRegister() {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      // Validasi berhasil
      PediaBanner.showSuccess(
        context,
        message:
            'Pendaftaran berhasil! Mengalihkan ke halaman pilihan akun...',
      );

      // Otomatis mengarahkan ke AuthChoicePage
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthChoicePage()),
          (route) => false,
        );
      });
    } else {
      // Aktifkan validasi interaktif saat pengguna mengoreksi isian
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
                  'untuk mendaftar ke PediaGrow',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                _buildGoogleAccountTile(
                  name: 'Pengguna PediaGrow',
                  email: 'pengguna.pediagrow@gmail.com',
                  initial: 'P',
                  avatarColor: const Color(0xFF3985E7),
                ),
                const Divider(height: 1),
                _buildGoogleAccountTile(
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
                    child: Icon(
                      Icons.person_add_alt_1_outlined,
                      color: Color(0xFF475569),
                    ),
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
        style: GoogleFonts.lato(fontSize: 13, color: const Color(0xFF64748B)),
      ),
      onTap: () {
        Navigator.of(context).pop();
        _completeGoogleSignIn(email);
      },
    );
  }

  void _completeGoogleSignIn(String account) {
    PediaBanner.showSuccess(
      context,
      message: 'Berhasil terhubung dengan Google: $account',
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthChoicePage()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold dengan resizeToAvoidBottomInset: true agar terdorong keyboard
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
              // KONTEN FORMULIR YANG DAPAT DI-SCROLL
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

                        // 1. Gambar Ilustrasi Keluarga (weight/width 247, height 155)
                        Center(
                          child: SizedBox(
                            width: 247,
                            height: 155,
                            child: Image.asset(
                              'assets/images/register_family.png',
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

                        const SizedBox(height: 20),

                        // 2. Field: Nama Pengguna
                        _buildFieldTitle('Nama Pengguna'),
                        TextFormField(
                          key: const Key('name_field'),
                          controller: _nameController,
                          focusNode: _nameFocus,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: const Color(0xFF1E293B),
                          ),
                          decoration: _buildInputDecoration(
                            hintText: 'Masukkan nama lengkap anda',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama pengguna wajib diisi';
                            }
                            // Harus huruf saja (spasi diperbolehkan)
                            final regex = RegExp(r'^[a-zA-Z\s]+$');
                            if (!regex.hasMatch(value.trim())) {
                              return 'Nama pengguna harus diisikan dengan huruf saja';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // 3. Field: Email
                        _buildFieldTitle('Email'),
                        TextFormField(
                          key: const Key('email_field'),
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
                            // Format email valid dan harus domain Gmail
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

                        // 4. Field: Kata Sandi
                        _buildFieldTitle('Kata Sandi'),
                        TextFormField(
                          key: const Key('password_field'),
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
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
                            final hasLetter = RegExp(r'[a-zA-Z]')
                                .hasMatch(value);
                            final hasNumber = RegExp(r'[0-9]').hasMatch(value);
                            final hasSymbol = RegExp(
                              r'[!@#\$%^&*(),.?":{}|<>\-_=+/\\~`\[\]]',
                            ).hasMatch(value);

                            if (!hasLetter || !hasNumber || !hasSymbol) {
                              return 'Kata sandi harus kombinasi huruf, angka, dan simbol';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // 5. Field: Konfirmasi Kata Sandi
                        _buildFieldTitle('Konfirmasi Kata Sandi'),
                        TextFormField(
                          key: const Key('confirm_password_field'),
                          controller: _confirmPasswordController,
                          focusNode: _confirmPasswordFocus,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleRegister(),
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: const Color(0xFF1E293B),
                          ),
                          decoration: _buildInputDecoration(
                            hintText: 'Ulangi kata sandi yang dimasukkan',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF94A3B8),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Konfirmasi kata sandi wajib diisi';
                            }
                            if (value != _passwordController.text) {
                              return 'Konfirmasi kata sandi tidak cocok dengan kata sandi';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 28),

                        // 6. Tombol Daftar (weight/width 350, height 46)
                        Center(
                          child: SizedBox(
                            width: math.min(
                              350.0,
                              MediaQuery.of(context).size.width - 32,
                            ),
                            height: 46.0,
                            child: ElevatedButton(
                              key: const Key('register_button'),
                              onPressed: _handleRegister,
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
                                  'Daftar',
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

                        // 7. Garis Pemisah "atau"
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

                        // 8. Tombol Daftar dengan Google (weight/width 350, height 46)
                        Center(
                          child: SizedBox(
                            width: math.min(
                              350.0,
                              MediaQuery.of(context).size.width - 32,
                            ),
                            height: 46.0,
                            child: OutlinedButton(
                              key: const Key('google_register_button'),
                              onPressed: _showGoogleAccountPicker,
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
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const _GoogleGLogo(size: 24),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Daftar dengan Google',
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

                        // 9. Teks Syarat & Ketentuan
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  height: 1.4,
                                  fontWeight: FontWeight.normal,
                                  color: const Color(0xFF000000),
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'Dengan mendaftar anda telah membaca dan menyetujui ',
                                  ),
                                  TextSpan(
                                    text: 'Syarat & Ketentuan',
                                    style: GoogleFonts.lato(
                                      fontSize: 14,
                                      color: const Color(0xFF3985E7),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const TermsPage(),
                                          ),
                                        );
                                      },
                                  ),
                                  const TextSpan(text: ' dari Tim PediaGrow'),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 10. Teks Sudah memiliki Akun? Masuk
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
                                const TextSpan(text: 'Sudah memiliki Akun? '),
                                TextSpan(
                                  text: 'Masuk',
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    color: const Color(0xFF3985E7),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const LoginPage(),
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
          // Button back terletak 12dp dari pinggir kiri layar
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
          // Nama halaman terletak 12dp setelah button back
          const SizedBox(width: 12.0),
          Text(
            'Daftar Akun Baru',
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
  /// - Error: border merah (#B13535) + pesan error #B13535
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

  const _GoogleGLogo({this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: const _GoogleGLogoPainter(),
    );
  }
}

class _GoogleGLogoPainter extends CustomPainter {
  const _GoogleGLogoPainter();

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
