import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static const Color colorPrimary = Color(0xFF3985E7);
  static const Color colorPediaBlue = Color(0xFF4B83D6);
  static const Color colorGrowGreen = Color(0xFF3CC3A6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Masuk',
          style: GoogleFonts.lato(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Pedia',
                      style: GoogleFonts.baloo2(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: colorPediaBlue,
                      ),
                    ),
                    TextSpan(
                      text: 'Grow',
                      style: GoogleFonts.baloo2(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: colorGrowGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selamat datang kembali! Silakan masuk ke akun Anda.',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  color: const Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              Center(
                child: Text(
                  'Halaman Masuk (Login)',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
