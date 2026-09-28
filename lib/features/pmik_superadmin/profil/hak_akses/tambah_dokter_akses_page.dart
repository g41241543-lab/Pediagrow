import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/doctor_service.dart';
import '../../../../models/doctor_model.dart';

/// Halaman Tambah Dokter oleh Superadmin.
///
/// Superadmin mengisi:
/// - Data profil dokter (nama, spesialisasi, pengalaman, rumah sakit, biaya)
/// - Akun login dokter (email + password)
///
/// Ketika disimpan:
/// 1. Akun staff dengan role 'dokter' dibuat di collection 'staff_accounts'.
/// 2. Profil dokter disimpan di collection 'doctors'.
/// 3. Kedua dokumen dihubungkan via field 'staff_account_id'.
class TambahDokterAksesPage extends StatefulWidget {
  final String createdByEmail;

  const TambahDokterAksesPage({
    super.key,
    required this.createdByEmail,
  });

  @override
  State<TambahDokterAksesPage> createState() => _TambahDokterAksesPageState();
}

class _TambahDokterAksesPageState extends State<TambahDokterAksesPage> {
  final _formKey = GlobalKey<FormState>();

  // ─── Controllers ───────────────────────────────────────────
  final _namaCtrl = TextEditingController();
  final _spesialisasiCtrl = TextEditingController();
  final _pengalamanCtrl = TextEditingController();
  final _rumahSakitCtrl = TextEditingController();
  final _biayaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _konfirmasiPasswordCtrl = TextEditingController();

  bool _isOnline = true;
  bool _isPasswordVisible = false;
  bool _isKonfirmasiVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _spesialisasiCtrl.dispose();
    _pengalamanCtrl.dispose();
    _rumahSakitCtrl.dispose();
    _biayaCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _konfirmasiPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dokterProfile = DoctorModel(
        id: '',
        name: _namaCtrl.text.trim(),
        specialization: _spesialisasiCtrl.text.trim(),
        experienceYears: int.tryParse(_pengalamanCtrl.text.trim()) ?? 0,
        hospital: _rumahSakitCtrl.text.trim().isEmpty
            ? null
            : _rumahSakitCtrl.text.trim(),
        consultationFee: int.tryParse(
                _biayaCtrl.text.trim().replaceAll(RegExp(r'[^\d]'), '')) ??
            0,
        isOnline: _isOnline,
        staffAccountId: '',
      );

      final berhasil = await DoctorService().createDoctorWithAccount(
        profile: dokterProfile,
        email: _emailCtrl.text.trim().toLowerCase(),
        password: _passwordCtrl.text,
        createdByEmail: widget.createdByEmail,
      );

      if (!mounted) return;

      if (berhasil) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Dokter "${_namaCtrl.text.trim()}" berhasil ditambahkan.',
              style: GoogleFonts.lato(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.of(context).pop();
      } else {
        _showErrorSnackBar(
          'Gagal menambahkan dokter. Pastikan email belum dipakai.',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Terjadi kesalahan: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.lato(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: _buildHeader(context),
      ),
      body: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              children: [
                // ─── Seksi Profil Dokter ─────────────────────
                _buildSectionLabel(
                  icon: Icons.person_outline_rounded,
                  label: 'Data Profil Dokter',
                  color: const Color(0xFF3985E7),
                ),
                const SizedBox(height: 12),

                _buildField(
                  controller: _namaCtrl,
                  label: 'Nama Lengkap Dokter',
                  hint: 'cth. dr. Budi Santoso, Sp.A',
                  icon: Icons.badge_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nama dokter wajib diisi'
                      : null,
                ),
                const SizedBox(height: 14),

                _buildField(
                  controller: _spesialisasiCtrl,
                  label: 'Spesialisasi',
                  hint: 'cth. Dokter Spesialis Anak',
                  icon: Icons.medical_services_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Spesialisasi wajib diisi'
                      : null,
                ),
                const SizedBox(height: 14),

                _buildField(
                  controller: _pengalamanCtrl,
                  label: 'Tahun Pengalaman',
                  hint: 'cth. 5',
                  icon: Icons.business_center_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Tahun pengalaman wajib diisi';
                    }
                    if (int.tryParse(v.trim()) == null) {
                      return 'Masukkan angka yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                _buildField(
                  controller: _rumahSakitCtrl,
                  label: 'Rumah Sakit / Klinik (opsional)',
                  hint: 'cth. RSUD Dr. Soetomo',
                  icon: Icons.local_hospital_outlined,
                ),
                const SizedBox(height: 14),

                _buildField(
                  controller: _biayaCtrl,
                  label: 'Biaya Konsultasi (Rp)',
                  hint: 'cth. 50000',
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Biaya konsultasi wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Toggle Status Online
                _buildOnlineToggle(),

                const SizedBox(height: 24),
                const Divider(
                  color: Color(0xFFF1F5F9),
                  thickness: 1,
                ),
                const SizedBox(height: 16),

                // ─── Seksi Akun Login ────────────────────────
                _buildSectionLabel(
                  icon: Icons.lock_outline_rounded,
                  label: 'Akun Login Dokter',
                  color: const Color(0xFF7C3AED),
                ),
                const SizedBox(height: 4),
                Text(
                  'Email dan password ini digunakan dokter untuk masuk ke aplikasi.',
                  style: GoogleFonts.lato(
                    fontSize: 12.5,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),

                _buildField(
                  controller: _emailCtrl,
                  label: 'Email Login',
                  hint: 'cth. budi.santoso@pediagrow.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Email wajib diisi';
                    }
                    if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.\w+$')
                        .hasMatch(v.trim())) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                _buildPasswordField(
                  controller: _passwordCtrl,
                  label: 'Password',
                  hint: 'Minimal 6 karakter',
                  isVisible: _isPasswordVisible,
                  onToggle: () => setState(
                    () => _isPasswordVisible = !_isPasswordVisible,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password wajib diisi';
                    if (v.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                _buildPasswordField(
                  controller: _konfirmasiPasswordCtrl,
                  label: 'Konfirmasi Password',
                  hint: 'Ulangi password',
                  isVisible: _isKonfirmasiVisible,
                  onToggle: () => setState(
                    () => _isKonfirmasiVisible = !_isKonfirmasiVisible,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Konfirmasi password wajib diisi';
                    }
                    if (v != _passwordCtrl.text) {
                      return 'Password tidak cocok';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Tombol Simpan
                _buildSimpanButton(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // WIDGETS HELPER
  // ─────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56.0,
          child: Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 36.0,
                    height: 36.0,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_back,
                      size: 24.0,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    'Tambah Dokter Baru',
                    style: GoogleFonts.lato(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.lato(
        fontSize: 14.5,
        color: const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
        labelStyle: GoogleFonts.lato(
          fontSize: 13.5,
          color: const Color(0xFF64748B),
        ),
        hintStyle: GoogleFonts.lato(
          fontSize: 13.5,
          color: const Color(0xFFCBD5E1),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3985E7), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      validator: validator,
      style: GoogleFonts.lato(
        fontSize: 14.5,
        color: const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          size: 20,
          color: Color(0xFF94A3B8),
        ),
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Icon(
            isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: const Color(0xFF94A3B8),
          ),
        ),
        labelStyle: GoogleFonts.lato(
          fontSize: 13.5,
          color: const Color(0xFF64748B),
        ),
        hintStyle: GoogleFonts.lato(
          fontSize: 13.5,
          color: const Color(0xFFCBD5E1),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3985E7), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildOnlineToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_rounded,
            size: 20,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Online',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  _isOnline
                      ? 'Dokter terlihat online di aplikasi'
                      : 'Dokter terlihat offline di aplikasi',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isOnline,
            activeColor: const Color(0xFF10B981),
            onChanged: (val) => setState(() => _isOnline = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpanButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _simpan,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3985E7),
          disabledBackgroundColor: const Color(0xFF3985E7).withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'Simpan Dokter',
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
