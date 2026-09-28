import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/resep_mpasi_service.dart';
import '../../../../models/resep_mpasi_model.dart';
import '../../../../shared/widgets/pedia_banner.dart';

/// Halaman "Ubah Resep" MPASI untuk Superadmin / PMIK.
///
/// Tampilan disesuaikan dengan gambar referensi 4:
/// - Header back + "Ubah Resep"
/// - Foto resep yang sudah ada dengan tombol "Ubah Foto"
/// - Tanggal resep
/// - Input Judul Resep (terisi data sebelumnya)
/// - Penulis ("Ditulis oleh Pego")
/// - 4 stat gizi & porsi (Energi kkal, Lemak gr, Protein gr, Porsi porsi) terisi
/// - Kategori Usia
/// - Dynamic list terisi dengan tombol tambah (+) dan hapus (x):
///   * Bahan
///   * Bahan Pelapis
///   * Buah
///   * Cara Membuat
/// - Tombol "Simpan" biru yang langsung memperbarui dokumen di Firestore
class EditResepMpasiPage extends StatefulWidget {
  final ResepMpasiModel resep;

  const EditResepMpasiPage({
    super.key,
    required this.resep,
  });

  @override
  State<EditResepMpasiPage> createState() => _EditResepMpasiPageState();
}

class _EditResepMpasiPageState extends State<EditResepMpasiPage> {
  final ResepMpasiService _service = ResepMpasiService();
  final ImagePicker _picker = ImagePicker();

  String? _imagePath;
  late final TextEditingController _tanggalController;
  late final TextEditingController _judulController;
  late final TextEditingController _penulisController;

  // Stat gizi & porsi
  late final TextEditingController _energiController;
  late final TextEditingController _lemakController;
  late final TextEditingController _proteinController;
  late final TextEditingController _porsiController;

  late String _selectedKategoriUsia;

  // Dynamic lists of controllers
  final List<TextEditingController> _bahanControllers = [];
  final List<TextEditingController> _bahanPelapisControllers = [];
  final List<TextEditingController> _buahControllers = [];
  final List<TextEditingController> _caraMembuatControllers = [];

  bool _isSaving = false;
  String? _judulError;

  static const Color _colorPrimaryBlue = Color(0xFF2A85FF);
  static const Color _colorDark = Color(0xFF0F172A);
  static const Color _colorMuted = Color(0xFF94A3B8);
  static const Color _colorGreen = Color(0xFF22C55E);

  @override
  void initState() {
    super.initState();
    final r = widget.resep;
    _imagePath = r.displayImage;
    _tanggalController = TextEditingController(text: r.tanggal);
    _judulController = TextEditingController(text: r.judul);
    _penulisController = TextEditingController(text: r.penulis ?? 'Pego');

    _energiController = TextEditingController(
      text: r.energiKkal != null ? _formatNum(r.energiKkal!) : '',
    );
    _lemakController = TextEditingController(
      text: r.lemakGr != null ? _formatNum(r.lemakGr!) : '',
    );
    _proteinController = TextEditingController(
      text: r.proteinGr != null ? _formatNum(r.proteinGr!) : '',
    );
    _porsiController = TextEditingController(
      text: r.porsi != null ? r.porsi.toString() : '',
    );

    _selectedKategoriUsia = r.kategoriUsia.isNotEmpty ? r.kategoriUsia : '6-8 bulan';

    // Isi daftar bahan
    if (r.bahan.isNotEmpty) {
      for (final b in r.bahan) {
        _bahanControllers.add(TextEditingController(text: b));
      }
    } else {
      _bahanControllers.add(TextEditingController());
    }

    // Isi daftar bahan pelapis
    if (r.bahanPelapis.isNotEmpty) {
      for (final b in r.bahanPelapis) {
        _bahanPelapisControllers.add(TextEditingController(text: b));
      }
    } else {
      _bahanPelapisControllers.add(TextEditingController());
    }

    // Isi daftar buah
    if (r.buah.isNotEmpty) {
      for (final b in r.buah) {
        _buahControllers.add(TextEditingController(text: b));
      }
    } else {
      _buahControllers.add(TextEditingController());
    }

    // Isi daftar cara membuat
    if (r.caraMembuat.isNotEmpty) {
      for (final c in r.caraMembuat) {
        _caraMembuatControllers.add(TextEditingController(text: c));
      }
    } else {
      _caraMembuatControllers.add(TextEditingController());
    }
  }

  String _formatNum(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toString();
  }

  @override
  void dispose() {
    _tanggalController.dispose();
    _judulController.dispose();
    _penulisController.dispose();
    _energiController.dispose();
    _lemakController.dispose();
    _proteinController.dispose();
    _porsiController.dispose();

    for (final c in _bahanControllers) {
      c.dispose();
    }
    for (final c in _bahanPelapisControllers) {
      c.dispose();
    }
    for (final c in _buahControllers) {
      c.dispose();
    }
    for (final c in _caraMembuatControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Ubah Foto Resep',
                  style: GoogleFonts.lato(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: _colorDark,
                  ),
                ),
                const SizedBox(height: 16.0),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECF6FF),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: _colorPrimaryBlue,
                      size: 24.0,
                    ),
                  ),
                  title: Text(
                    'Ambil Foto dari Kamera',
                    style: GoogleFonts.lato(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                      color: _colorDark,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                const Divider(height: 1.0, color: Color(0xFFF1F5F9)),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECF6FF),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: _colorPrimaryBlue,
                      size: 24.0,
                    ),
                  ),
                  title: Text(
                    'Pilih Foto dari Galeri',
                    style: GoogleFonts.lato(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                      color: _colorDark,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _imagePath = picked.path;
        });
      }
    } catch (e) {
      if (mounted) {
        PediaBanner.showError(context, message: 'Gagal memilih foto: $e');
      }
    }
  }

  Future<void> _handleSimpan() async {
    final judul = _judulController.text.trim();
    if (judul.isEmpty) {
      setState(() => _judulError = 'Judul resep wajib diisi');
      PediaBanner.showError(
        context,
        message: 'Mohon isi judul resep terlebih dahulu',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _judulError = null;
    });

    try {
      final bahanList = _bahanControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      final bahanPelapisList = _bahanPelapisControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      final buahList = _buahControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      final caraMembuatList = _caraMembuatControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final energi = double.tryParse(_energiController.text.trim());
      final lemak = double.tryParse(_lemakController.text.trim());
      final protein = double.tryParse(_proteinController.text.trim());
      final porsi = int.tryParse(_porsiController.text.trim());

      final bool isAsset = _imagePath != null && _imagePath!.startsWith('assets/');

      final updatedResep = ResepMpasiModel(
        id: widget.resep.id,
        judul: judul,
        kategoriUsia: _selectedKategoriUsia,
        tanggal: _tanggalController.text.trim().isNotEmpty
            ? _tanggalController.text.trim()
            : widget.resep.tanggal,
        assetImagePath: isAsset ? _imagePath : (widget.resep.assetImagePath),
        imageUrl: !isAsset && _imagePath != null ? _imagePath : widget.resep.imageUrl,
        penulis: _penulisController.text.trim().isNotEmpty
            ? _penulisController.text.trim()
            : widget.resep.penulis,
        energiKkal: energi,
        lemakGr: lemak,
        proteinGr: protein,
        porsi: porsi,
        bahan: bahanList,
        bahanPelapis: bahanPelapisList,
        buah: buahList,
        caraMembuat: caraMembuatList,
      );

      // Simpan pembaruan langsung ke database Firestore
      await _service.updateResep(updatedResep);

      if (!mounted) return;
      setState(() => _isSaving = false);

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      PediaBanner.showError(
        context,
        message: 'Gagal memperbarui resep: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12.0),
                    _buildPhotoUploadArea(),
                    const SizedBox(height: 20.0),
                    _buildTanggalField(),
                    const SizedBox(height: 16.0),
                    _buildJudulField(),
                    const SizedBox(height: 12.0),
                    _buildPenulisField(),
                    const SizedBox(height: 16.0),
                    _buildNutrisiGrid(),
                    const SizedBox(height: 20.0),
                    _buildKategoriUsiaSelector(),
                    const SizedBox(height: 24.0),
                    _buildDynamicSection(
                      title: 'Bahan',
                      controllers: _bahanControllers,
                      isNumbered: false,
                    ),
                    const SizedBox(height: 20.0),
                    _buildDynamicSection(
                      title: 'Bahan Pelapis',
                      controllers: _bahanPelapisControllers,
                      isNumbered: false,
                    ),
                    const SizedBox(height: 20.0),
                    _buildDynamicSection(
                      title: 'Buah',
                      controllers: _buahControllers,
                      isNumbered: false,
                    ),
                    const SizedBox(height: 20.0),
                    _buildDynamicSection(
                      title: 'Cara Membuat',
                      controllers: _caraMembuatControllers,
                      isNumbered: true,
                    ),
                    const SizedBox(height: 32.0),
                    _buildSimpanButton(),
                    const SizedBox(height: 36.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 56.0,
      width: double.infinity,
      color: Colors.white,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(24.0),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.arrow_back, size: 24.0, color: Colors.black),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          Text(
            'Ubah Resep',
            style: GoogleFonts.lato(
              fontSize: 19.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoUploadArea() {
    return Column(
      children: [
        GestureDetector(
          onTap: _showImagePickerOptions,
          child: _DashedBorderCard(
            radius: 14.0,
            height: 190.0,
            width: double.infinity,
            color: const Color(0xFFCBD5E1),
            child: _imagePath != null && _imagePath!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14.0),
                    child: _buildImageWidget(_imagePath!),
                  )
                : Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 56.0,
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8.0),
        GestureDetector(
          onTap: _showImagePickerOptions,
          child: Text(
            'Ubah Foto',
            style: GoogleFonts.lato(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: _colorPrimaryBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageWidget(String path) {
    if (kIsWeb || path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(path, fit: BoxFit.cover, width: double.infinity);
    }
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover, width: double.infinity);
    }
    return Image.file(File(path), fit: BoxFit.cover, width: double.infinity);
  }

  Widget _buildTanggalField() {
    return TextField(
      controller: _tanggalController,
      style: GoogleFonts.lato(
        fontSize: 13.0,
        color: _colorMuted,
        fontWeight: FontWeight.w500,
      ),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.only(bottom: 6.0),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: _colorPrimaryBlue),
        ),
      ),
    );
  }

  Widget _buildJudulField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _judulController,
          onChanged: (val) {
            if (_judulError != null && val.trim().isNotEmpty) {
              setState(() => _judulError = null);
            }
          },
          style: GoogleFonts.lato(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: _colorDark,
          ),
          decoration: InputDecoration(
            hintText: 'Judul Resep',
            hintStyle: GoogleFonts.lato(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFCBD5E1),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.only(bottom: 8.0),
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: _colorPrimaryBlue),
            ),
          ),
        ),
        if (_judulError != null) ...[
          const SizedBox(height: 4.0),
          Text(
            _judulError!,
            style: GoogleFonts.lato(fontSize: 12.0, color: Colors.red),
          ),
        ],
      ],
    );
  }

  Widget _buildPenulisField() {
    return Row(
      children: [
        Text(
          'Ditulis oleh ',
          style: GoogleFonts.lato(
            fontSize: 13.0,
            color: _colorMuted,
          ),
        ),
        Expanded(
          child: TextField(
            controller: _penulisController,
            style: GoogleFonts.lato(
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
              color: _colorDark,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNutrisiGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildNutrisiItem(
                icon: Icons.bolt_rounded,
                label: 'Energi',
                unit: 'kkal',
                controller: _energiController,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: _buildNutrisiItem(
                icon: Icons.grain_rounded,
                label: 'Lemak',
                unit: 'gr',
                controller: _lemakController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        Row(
          children: [
            Expanded(
              child: _buildNutrisiItem(
                icon: Icons.donut_small_rounded,
                label: 'Protein',
                unit: 'gr',
                controller: _proteinController,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: _buildNutrisiItem(
                icon: Icons.soup_kitchen_outlined,
                label: 'Porsi',
                unit: 'porsi',
                controller: _porsiController,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNutrisiItem({
    required IconData icon,
    required String label,
    required String unit,
    required TextEditingController controller,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32.0,
          height: 32.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _colorGreen.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Icon(icon, size: 18.0, color: _colorGreen),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.lato(fontSize: 11.0, color: _colorMuted),
              ),
              Row(
                children: [
                  IntrinsicWidth(
                    child: TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.lato(
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                        color: _colorDark,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: '0',
                        hintStyle: GoogleFonts.lato(
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFCBD5E1),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    unit,
                    style: GoogleFonts.lato(
                      fontSize: 13.0,
                      fontWeight: FontWeight.bold,
                      color: _colorDark,
                    ),
                  ),
                ],
              ),
              Container(height: 1.0, color: const Color(0xFFE2E8F0)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKategoriUsiaSelector() {
    const listUsia = ['6-8 bulan', '9-11 bulan', '12-23 bulan', '24+ bulan'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori Usia',
          style: GoogleFonts.lato(
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
            color: _colorDark,
          ),
        ),
        const SizedBox(height: 8.0),
        Wrap(
          spacing: 8.0,
          children: listUsia.map((usia) {
            final isSelected = _selectedKategoriUsia == usia;
            return ChoiceChip(
              label: Text(usia),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedKategoriUsia = usia);
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFEBF5FF),
              labelStyle: GoogleFonts.lato(
                fontSize: 12.0,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? _colorPrimaryBlue : _colorMuted,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
                side: BorderSide(
                  color: isSelected ? _colorPrimaryBlue : const Color(0xFFCBD5E1),
                ),
              ),
              elevation: 0,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDynamicSection({
    required String title,
    required List<TextEditingController> controllers,
    required bool isNumbered,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
                color: _colorDark,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  controllers.add(TextEditingController());
                });
              },
              child: const Icon(
                Icons.add_circle_outline_rounded,
                color: _colorPrimaryBlue,
                size: 22.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6.0),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controllers.length,
          separatorBuilder: (context, index) => const SizedBox(height: 6.0),
          itemBuilder: (context, index) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  isNumbered ? '${index + 1}. ' : '• ',
                  style: GoogleFonts.lato(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: _colorDark,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: controllers[index],
                    maxLines: isNumbered ? null : 1,
                    style: GoogleFonts.lato(fontSize: 13.5, color: _colorDark),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
                      hintText: 'Tuliskan ${title.toLowerCase()}...',
                      hintStyle: GoogleFonts.lato(
                        fontSize: 13.0,
                        color: const Color(0xFFCBD5E1),
                      ),
                      border: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFF1F5F9)),
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFF1F5F9)),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: _colorPrimaryBlue),
                      ),
                    ),
                  ),
                ),
                if (controllers.length > 1)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        final removed = controllers.removeAt(index);
                        removed.dispose();
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6.0),
                      child: Icon(
                        Icons.close,
                        size: 18.0,
                        color: _colorMuted,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSimpanButton() {
    return SizedBox(
      width: double.infinity,
      height: 48.0,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _handleSimpan,
        style: ElevatedButton.styleFrom(
          backgroundColor: _colorPrimaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22.0,
                height: 22.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Simpan',
                style: GoogleFonts.lato(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class _DashedBorderCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final Color color;
  final double? width;
  final double? height;

  const _DashedBorderCard({
    required this.child,
    this.radius = 12.0,
    this.color = const Color(0xFF94A3B8),
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(
        color: color,
        radius: radius,
        strokeWidth: 1.2,
        dashWidth: 6.0,
        dashSpace: 4.0,
      ),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
        ),
        child: child,
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  const _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final dashedPath = Path();

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = math.min(dashWidth, metric.length - distance);
        dashedPath.addPath(
          metric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth;
}
