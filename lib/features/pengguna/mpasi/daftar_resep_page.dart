import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DaftarResepPage extends StatelessWidget {
  const DaftarResepPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Icon(Icons.arrow_back, color: Color(0xFF000000), size: 24),
          ),
        ),
        title: Text(
          'Resep MPASI',
          style: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF000000),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu_outlined,
                size: 64, color: Color(0xFF3985E7)),
            const SizedBox(height: 16),
            Text(
              'Halaman Resep MPASI\n(Akan segera hadir)',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 16,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
