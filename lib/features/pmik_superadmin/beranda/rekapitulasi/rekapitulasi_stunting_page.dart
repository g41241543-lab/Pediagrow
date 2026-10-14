import 'package:flutter/material.dart';
import '../grafik_pengguna/grafik_pengguna_page.dart';

/// Halaman Rekapitulasi Stunting untuk Superadmin, Dokter, & PMIK.
/// Terintegrasi dalam 1 menu analitik bersama Grafik Pengguna
/// (Tab: Hasil Cek Stunting).
class RekapitulasiStuntingPage extends StatelessWidget {
  const RekapitulasiStuntingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GrafikPenggunaPage(initialTab: 1);
  }
}
