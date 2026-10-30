import 'package:flutter/material.dart';
import '../grafik_pengguna/grafik_pengguna_page.dart';

/// Halaman Rekapitulasi untuk PMIK Superadmin & Admin.
/// Memiliki 2 tab: Grafik Pengguna dan Grafik Stunting.
class RekapitulasiStuntingPage extends StatelessWidget {
  final int initialTab;
  const RekapitulasiStuntingPage({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    return GrafikPenggunaPage(initialTab: initialTab);
  }
}
