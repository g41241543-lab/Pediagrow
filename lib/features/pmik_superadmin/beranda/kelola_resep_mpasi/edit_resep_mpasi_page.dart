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
/// Tampilan disesuaikan dengan permintaan user & gambar referensi:
/// - Header back + "Ubah Resep"
/// - Foto resep dengan border putus-putus dan tombol teks "Ubah Foto"
/// - Tanggal real-time & paten (teks warna #C5C5C5 seperti pada kelola artikel)
/// - Input "Isi Judul" dalam kotak garis putus-putus (Dashed Border)
/// - Penulis ("Ditulis oleh Pego")
/// - 4 stat gizi & porsi (Energi, Lemak, Protein, Porsi) masing-masing dalam kotak garis putus-putus
/// - Kategori Usia
/// - Dynamic list (kartu putih rounded, penanda di kiri, teks di tengah dengan garis putus-putus,
///   tombol (-) merah di kanan, dan tombol (+) biru di header):
///   * Bahan          → penanda bullet (•) seperti di Detail Resep
///   * Bahan Pelapis  → penanda bullet (•)
///   * Buah           → penanda bullet (•)
///   * Cara Membuat   → penanda nomor (1. 2. 3.) seperti di Detail Resep
/// - Tombol "Simpan" biru yang langsung memperbarui dokumen di Firestore
class EditResepMpasiPage extends StatefulWidget {
  final ResepMpasiModel resep;

  const EditResepMpasiPage({super.key, required this.resep});

  @override
  State<EditResepMpasiPage> createState() => _EditResepMpasiPageState();
}

class _EditResepMpasiPageState extends State<EditResepMpasiPage> {
  final ResepMpasiService _service = ResepMpasiService();
  final ImagePicker _picker = ImagePicker();

  String? _imagePath;
  late final String _tanggal;
  late final TextEditingController _judulController;
  late final TextEditingController _penulisController;

  // Stat gizi & porsi
  late final TextEditingController _energiController;
  late final TextEditingController _lemakController;
  late final TextEditingController _proteinController;
  late final TextEditingController _porsiController;

  final FocusNode _judulFocusNode = FocusNode();

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
  static const Color _colorGray = Color(0xFF7F7F7F);
  static const Color _colorGreen = Color(0xFF22C55E);

  // Warna penanda bullet/nomor — sama dengan Detail Resep (#262626)
  static const Color _colorMarker = Color(0xFF262626);

  @override
  void initState() {
    super.initState();
    final r = widget.resep;
    _imagePath = r.displayImage;

    // Tanggal paten / real-time sesuai data atau hari ini
    if (r.tanggal.isNotEmpty) {
      _tanggal = r.tanggal;
    } else {
      final now = DateTime.now();
      _tanggal = '${now.day} ${_getNamaBulan(now.month)} ${now.year}';
    }

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

    _selectedKategoriUsia = r.kategoriUsia.isNotEmpty
        ? r.kategoriUsia
        : '6-8 bulan';

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

  String _getNamaBulan(int bulan) {
    const namaBulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    if (bulan >= 1 && bulan <= 12) return namaBulan[bulan - 1];
    return '';
  }

  String _formatNum(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toString();
  }

  @override
  void dispose() {
    _judulController.dispose();
    _penulisController.dispose();
    _judulFocusNode.dispose();
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
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
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
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: _colorPrimaryBlue,
                      size: 22.0,
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
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: _colorPrimaryBlue,
                      size: 22.0,
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

      final bool isAsset =
          _imagePath != null && _imagePath!.startsWith('assets/');

      final updatedResep = ResepMpasiModel(
        id: widget.resep.id,
        judul: judul,
        kategoriUsia: _selectedKategoriUsia,
        tanggal: _tanggal,
        assetImagePath: isAsset ? _imagePath : (widget.resep.assetImagePath),
        imageUrl: !isAsset && _imagePath != null
            ? _imagePath
            : widget.resep.imageUrl,
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
      PediaBanner.showError(context, message: 'Gagal memperbarui resep: $e');
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
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12.0),
                    _buildPhotoUploadArea(),
                    const SizedBox(height: 12.0),
                    Center(
                      child: GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 4.0,
                          ),
                          child: Text(
                            'Ubah Foto',
                            style: GoogleFonts.lato(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                              color: _colorPrimaryBlue,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    // Tanggal Real-Time & Paten (Abu muda seperti artikel)
                    Text(
                      _tanggal,
                      style: GoogleFonts.lato(
                        fontSize: 13.0,
                        color: const Color(0xFFC5C5C5),
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    // Label & Kotak Putus-putus Isi Judul
                    Text(
                      'Isi Judul',
                      style: GoogleFonts.lato(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    _buildDashedInputField(
                      controller: _judulController,
                      focusNode: _judulFocusNode,
                      placeholder: 'Judul Resep',
                      hasError: _judulError != null,
                      onChanged: (val) {
                        if (_judulError != null && val.trim().isNotEmpty) {
                          setState(() => _judulError = null);
                        }
                      },
                    ),
                    if (_judulError != null) ...[
                      const SizedBox(height: 4.0),
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Text(
                          _judulError!,
                          style: GoogleFonts.lato(
                            fontSize: 12.0,
                            color: const Color(0xFFE53935),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16.0),
                    _buildPenulisField(),
                    const SizedBox(height: 20.0),
                    // Grid 4 zat gizi & porsi dalam kotak putus-putus
                    _buildNutrisiGrid(),
                    const SizedBox(height: 20.0),
                    _buildKategoriUsiaSelector(),
                    const SizedBox(height: 24.0),
                    // Dynamic section (penanda bullet / nomor seperti Detail Resep)
                    _buildDynamicSection(
                      title: 'Bahan',
                      controllers: _bahanControllers,
                      hintText: 'Nama Bahan',
                    ),
                    const SizedBox(height: 20.0),
                    _buildDynamicSection(
                      title: 'Bahan Pelapis',
                      controllers: _bahanPelapisControllers,
                      hintText: 'Nama Bahan Pelapis',
                    ),
                    const SizedBox(height: 20.0),
                    _buildDynamicSection(
                      title: 'Buah',
                      controllers: _buahControllers,
                      hintText: 'Nama Buah',
                    ),
                    const SizedBox(height: 20.0),
                    _buildDynamicSection(
                      title: 'Cara Membuat',
                      controllers: _caraMembuatControllers,
                      hintText: 'Cara Membuat',
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
                  child: Icon(
                    Icons.arrow_back,
                    size: 24.0,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          Text(
            'Ubah Resep',
            style: GoogleFonts.lato(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoUploadArea() {
    return GestureDetector(
      onTap: _showImagePickerOptions,
      child: _DashedBorderCard(
        radius: 12.0,
        height: 200.0,
        color: _colorGray,
        child: _imagePath != null && _imagePath!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: _buildImageWidget(_imagePath!),
              )
            : const Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 64.0,
                  color: _colorGray,
                ),
              ),
      ),
    );
  }

  Widget _buildImageWidget(String path) {
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    if (kIsWeb || path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

  Widget _buildPenulisField() {
    return Row(
      children: [
        Text(
          'Ditulis oleh ',
          style: GoogleFonts.lato(fontSize: 13.0, color: _colorMuted),
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

  Widget _buildDashedInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String placeholder,
    bool hasError = false,
    ValueChanged<String>? onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return _DashedBorderContainer(
      radius: 10.0,
      height: 48.0,
      color: hasError ? const Color(0xFFE53935) : _colorGray,
      strokeWidth: 1.0,
      dashWidth: 5.0,
      dashSpace: 3.5,
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Center(
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          keyboardType: keyboardType,
          style: GoogleFonts.lato(fontSize: 14.0, color: Colors.black),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.lato(
              fontSize: 14.0,
              color: _colorGray,
              fontWeight: FontWeight.normal,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
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
            const SizedBox(width: 12.0),
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
            const SizedBox(width: 12.0),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14.0, color: _colorGreen),
            const SizedBox(width: 4.0),
            Text(
              '$label ($unit)',
              style: GoogleFonts.lato(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6.0),
        _DashedBorderContainer(
          radius: 10.0,
          height: 44.0,
          color: _colorGray,
          strokeWidth: 1.0,
          dashWidth: 5.0,
          dashSpace: 3.5,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Center(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: GoogleFonts.lato(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: _colorDark,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: GoogleFonts.lato(
                  fontSize: 14.0,
                  color: const Color(0xFFCBD5E1),
                  fontWeight: FontWeight.bold,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
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
          runSpacing: 6.0,
          children: listUsia.map((usia) {
            final isSelected = _selectedKategoriUsia == usia;
            return GestureDetector(
              onTap: () => setState(() => _selectedKategoriUsia = usia),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEBF5FF) : Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: isSelected
                        ? _colorPrimaryBlue
                        : const Color(0xFFCBD5E1),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Text(
                  usia,
                  style: GoogleFonts.lato(
                    fontSize: 12.0,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? _colorPrimaryBlue : _colorMuted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Penanda di sebelah kiri tiap item, disamakan dengan Detail Resep:
  /// - bullet bulat kecil (5x5, #262626) untuk Bahan / Bahan Pelapis / Buah
  /// - nomor bold ("1.", "2.", ...) untuk Cara Membuat
  Widget _buildItemMarker(int index, bool isNumbered) {
    if (isNumbered) {
      return SizedBox(
        width: 24.0,
        child: Text(
          '${index + 1}.',
          style: GoogleFonts.lato(
            fontSize: 15.0,
            fontWeight: FontWeight.bold,
            color: _colorMarker,
            height: 1.4,
          ),
        ),
      );
    }
    return const SizedBox(
      width: 24.0,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(left: 4.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _colorMarker,
              shape: BoxShape.circle,
            ),
            child: SizedBox(width: 5.0, height: 5.0),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicSection({
    required String title,
    required List<TextEditingController> controllers,
    required String hintText,
    bool isNumbered = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section: Judul di kiri, Icon (+) lingkaran biru di kanan
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
                size: 26.0,
                color: _colorPrimaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        // Kotak Card Putih Melengkung dengan bayangan halus
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: List.generate(controllers.length, (index) {
              final isLast = index == controllers.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      crossAxisAlignment: isNumbered
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.center,
                      children: [
                        // Penanda bullet / nomor di sebelah kiri (sama dengan Detail Resep)
                        _buildItemMarker(index, isNumbered),
                        const SizedBox(width: 6.0),
                        // TextField di tengah
                        Expanded(
                          child: TextField(
                            controller: controllers[index],
                            maxLines: isNumbered ? null : 1,
                            style: GoogleFonts.lato(
                              fontSize: 13.5,
                              color: _colorDark,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 2.0,
                              ),
                              hintText: isNumbered
                                  ? 'Langkah ${index + 1}...'
                                  : '$hintText...',
                              hintStyle: GoogleFonts.lato(
                                fontSize: 13.0,
                                color: const Color(0xFFCBD5E1),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        // Tombol (-) lingkaran merah di sebelah kanan item
                        if (controllers.length > 1)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                final removed = controllers.removeAt(index);
                                removed.dispose();
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Icon(
                                Icons.remove_circle_outline_rounded,
                                size: 22.0,
                                color: Color(0xFFEF5350),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Garis putus-putus di bawah item
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0),
                      child: SizedBox(
                        height: 1.0,
                        child: CustomPaint(
                          painter: const _DashedLinePainter(),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
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

// =============================================================================
// SHARED PRIVATE WIDGETS
// =============================================================================

class _DashedBorderContainer extends StatelessWidget {
  final Widget child;
  final double radius;
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final EdgeInsetsGeometry? padding;
  final double? height;

  const _DashedBorderContainer({
    required this.child,
    this.radius = 10.0,
    this.color = const Color(0xFF7F7F7F),
    this.strokeWidth = 1.0,
    this.dashWidth = 5.0,
    this.dashSpace = 3.5,
    this.padding,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(
        color: color,
        radius: radius,
        strokeWidth: strokeWidth,
        dashWidth: dashWidth,
        dashSpace: dashSpace,
      ),
      child: Container(
        height: height,
        padding: padding,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius)),
        child: child,
      ),
    );
  }
}

class _DashedBorderCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final Color color;
  final double? height;

  const _DashedBorderCard({
    required this.child,
    this.radius = 12.0,
    this.color = const Color(0xFF7F7F7F),
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
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius)),
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
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashSpace != dashSpace;
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 5.0, 0), paint);
      x += 5.0 + 3.0;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => false;
}
