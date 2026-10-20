import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'menu_profil_page.dart';

/// Halaman Ubah Kata Sandi PediaGrow.
class UbahPasswordPage extends StatefulWidget {
  const UbahPasswordPage({super.key});

  @override
  State<UbahPasswordPage> createState() => _UbahPasswordPageState();
}

class _UbahPasswordPageState extends State<UbahPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSavePassword() {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() => _isLoading = false);

        // Kembali ke MenuProfilPage dengan membawa pesan sukses
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop('Berhasil Ubah Kata Sandi');
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const MenuProfilPage(
                showSuccessBanner: true,
                successMessage: 'Berhasil Ubah Kata Sandi',
              ),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0B1014) : Colors.white;
    final titleColor = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000);
    final subtitleColor = isDark ? const Color(0xFF8696A0) : const Color(0xFF667781);
    final labelColor = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF000000);
    final fieldBg = isDark ? const Color(0xFF1A2228) : Colors.white;
    final fieldBorder = isDark ? const Color(0xFF2C363D) : const Color(0xFFD1D7DB);
    final fieldTextColor = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228);
    final hintColor = isDark ? const Color(0xFF667781) : const Color(0xFF8696A0);
    final iconColor = isDark ? const Color(0xFF8696A0) : const Color(0xFF667781);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header tetap di atas (56dp)
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.arrow_back,
                          color: titleColor,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ubah Kata Sandi',
                      style: GoogleFonts.lato(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 20.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buat kata sandi baru yang kuat untuk menjaga keamanan akun Anda.',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: subtitleColor,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Kata Sandi Saat Ini
                      _buildPasswordField(
                        label: 'Kata Sandi Saat Ini',
                        hint: 'Masukkan kata sandi saat ini',
                        controller: _oldPasswordController,
                        obscureText: _obscureOld,
                        onToggleVisibility: () {
                          setState(() => _obscureOld = !_obscureOld);
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Kata sandi saat ini wajib diisi';
                          }
                          return null;
                        },
                        labelColor: labelColor,
                        fieldBg: fieldBg,
                        fieldBorder: fieldBorder,
                        fieldTextColor: fieldTextColor,
                        hintColor: hintColor,
                        iconColor: iconColor,
                      ),
                      const SizedBox(height: 18),

                      // Kata Sandi Baru
                      _buildPasswordField(
                        label: 'Kata Sandi Baru',
                        hint: 'Minimal 6 karakter',
                        controller: _newPasswordController,
                        obscureText: _obscureNew,
                        onToggleVisibility: () {
                          setState(() => _obscureNew = !_obscureNew);
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Kata sandi baru wajib diisi';
                          }
                          if (val.length < 6) {
                            return 'Kata sandi minimal 6 karakter';
                          }
                          return null;
                        },
                        labelColor: labelColor,
                        fieldBg: fieldBg,
                        fieldBorder: fieldBorder,
                        fieldTextColor: fieldTextColor,
                        hintColor: hintColor,
                        iconColor: iconColor,
                      ),
                      const SizedBox(height: 18),

                      // Konfirmasi Kata Sandi Baru
                      _buildPasswordField(
                        label: 'Konfirmasi Kata Sandi Baru',
                        hint: 'Ulangi kata sandi baru',
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        onToggleVisibility: () {
                          setState(() => _obscureConfirm = !_obscureConfirm);
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Konfirmasi kata sandi wajib diisi';
                          }
                          if (val != _newPasswordController.text) {
                            return 'Konfirmasi kata sandi tidak cocok';
                          }
                          return null;
                        },
                        labelColor: labelColor,
                        fieldBg: fieldBg,
                        fieldBorder: fieldBorder,
                        fieldTextColor: fieldTextColor,
                        hintColor: hintColor,
                        iconColor: iconColor,
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSavePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3985E7),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Ubah Kata Sandi',
                                  style: GoogleFonts.lato(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
    required Color labelColor,
    required Color fieldBg,
    required Color fieldBorder,
    required Color fieldTextColor,
    required Color hintColor,
    required Color iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: GoogleFonts.lato(fontSize: 15, color: fieldTextColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.lato(
              fontSize: 14,
              color: hintColor,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              size: 20,
              color: iconColor,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: iconColor,
              ),
              onPressed: onToggleVisibility,
            ),
            filled: true,
            fillColor: fieldBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: fieldBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: fieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF3985E7),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFDC2626)),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
