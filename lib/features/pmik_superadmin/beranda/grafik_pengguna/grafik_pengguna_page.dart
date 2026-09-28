import 'package:flutter/material.dart';

import '../../../../models/child_model.dart';
import '../../../Grafik_Pertumbuhan/pertumbuhan_grafik_page.dart';
import '../data_anak/pilih_anak_button_sheet.dart';

/// Halaman Grafik Pengguna POV Superadmin.
/// Menampilkan grafik pertumbuhan untuk anak yang dipilih.
/// Jika belum ada anak yang diteruskan, otomatis memunculkan bottom sheet pemilihan anak.
class GrafikPenggunaPage extends StatefulWidget {
  final ChildModel? child;

  const GrafikPenggunaPage({super.key, this.child});

  @override
  State<GrafikPenggunaPage> createState() => _GrafikPenggunaPageState();
}

class _GrafikPenggunaPageState extends State<GrafikPenggunaPage> {
  ChildModel? _selectedChild;

  @override
  void initState() {
    super.initState();
    _selectedChild = widget.child;

    if (_selectedChild == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        PilihAnakBottomSheet.showForGrafik(
          context,
        ).then((_) {
          // Jika bottom sheet ditutup tanpa memilih dan belum ada anak yang dipilih, kembali ke halaman sebelumnya
          if (mounted && _selectedChild == null) {
            Navigator.of(context).maybePop();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedChild != null) {
      return PertumbuhanGrafikPage(child: _selectedChild!);
    }

    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
