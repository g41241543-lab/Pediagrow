import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/doctor_service.dart';
import '../../../../core/services/staff_auth_service.dart';
import '../../../../models/doctor_model.dart';
import '../../../../models/staff_account_model.dart';

/// Halaman Edit Dokter oleh Superadmin.
///
/// Superadmin dapat:
/// - Mengubah data profil dokter (nama, spesialisasi, pengalaman, dll.)
/// - Mengaktifkan/menonaktifkan akun login dokter
/// - Mengubah password akun dokter
/// - Menghapus dokter dari sistem
class EditDokterAksesPage extends StatefulWidget {
  final DoctorModel doctor;
  final StaffAccount? staffAccount;

  const EditDokterAksesPage({
    super.key,
    required this.doctor,
    this.staffAccount,
  });

  @override
  State<EditDokterAksesPage> createState() => _EditDokterAksesPageState();
}

class _EditDokterAksesPageState extends State<EditDokterAksesPage> {
  final _formKey = GlobalKey<FormState>();

  // ─── Controllers ───────────────────────────────────────────
  late final TextEditingController _namaCtrl;
  late final TextEditingController _spesialisasiCtrl;
  late final TextEditingController _pengalamanCtrl;
  late final TextEditingController _rumahSakitCtrl;
  late final TextEditingController _biayaCtrl;
  final _passwordBaruCtrl = TextEditingController();
  final _konfirmasiPasswordCtrl = TextEditingController();

  late bool _isOnline;
  late bool _isActive;
  bool _isPasswordVisible = false;
  bool _isKonfirmasiVisible = false;
  bool _isLoading = false;
  bool _isGantiPassword = false;

  @override
  void initState() {
    super.initState();
    final d = widget.doctor;
    _namaCtrl = TextEditingController(text: d.name);
    _spesialisasiCtrl = TextEditingController(text: d.specialization);
    _pengalamanCtrl = TextEditingController(
      text: d.experienceYears.toString(),
    );
    _rumahSakitCtrl = TextEditingController(text: d.hospital ?? '');
    _biayaCtrl = TextEditingController(
      text: d.consultationFee.toString(),
    );
    _isOnline = d.isOnline;
    _isActive = widget.staffAccount?.isActive ?? true;
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _spesialisasiCtrl.dispose();
    _pengalamanCtrl.dispose();
    _rumahSakitCtrl.dispose();
    _biayaCtrl.dispose();
    _passwordBaruCtrl.dispose();
    _konfirmasiPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Update profil dokter di collection 'doctors'
      final updatedDoctor = DoctorModel(
        id: widget.doctor.id,
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
        staffAccountId: widget.doctor.staffAccountId,
        avatarUrl: widget.doctor.avatarUrl,
        assetImagePath: widget.doctor.assetImagePath,
        strNumber: widget.doctor.strNumber,
        placesOfPractice: widget.doctor.placesOfPractice,
      );

      await DoctorService().updateDoctor(updatedDoctor);

      // 2. Update status aktif akun staff
      final staffId = widget.doctor.staffAccountId;
      if (staffId.isNotEmpty) {
        final currentActive = widget.staffAccount?.isActive ?? true;
        if (_isActive != currentActive) {
          await StaffAuthService().setAccountActive(staffId, _isActive);
        }

        // 3. Ganti password jika diaktifkan
        if (_isGantiPassword && _passwordBaruCtrl.text.isNotEmpty) {
          await StaffAuthService().changePassword(
            staffId,
            _passwordBaruCtrl.text,
          );
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Data dokter berhasil diperbarui.',
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memperbarui data: $e',
              style: GoogleFonts.lato(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _konfirmasiHapus() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Dokter',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus dokter "${widget.doctor.name}"?\n\nAkun login dokter juga akan dinonaktifkan.',
          style: GoogleFonts.lato(fontSize: 14, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Batal',
              style: GoogleFonts.lato(color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Hapus',
              style: GoogleFonts.lato(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (konfirmasi != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await DoctorService().deleteDoctor(widget.doctor.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Dokter "${widget.doctor.name}" telah dihapus.',
            style: GoogleFonts.lato(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF64748B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menghapus: $e',
              style: GoogleFonts.lato(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
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
                // ─── Info email (read-only) ──────────────────
                if (widget.staffAccount != null) ...[
                  _buildEmailInfoBox(),
                  const SizedBox(height: 20),
                ],

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

                _buildOnlineToggle(),

                const SizedBox(height: 24),
                const Divider(color: Color(0xFFF1F5F9), thickness: 1),
                const SizedBox(height: 16),

                // ─── Seksi Status Akun ───────────────────────
                _buildSectionLabel(
                  icon: Icons.manage_accounts_rounded,
                  label: 'Status Akun',
                  color: const Color(0xFF0284C7),
                ),
                const SizedBox(height: 12),

                _buildActiveToggle(),

                const SizedBox(height: 20),

                // ─── Ganti Password ──────────────────────────
                _buildGantiPasswordSection(),

                const SizedBox(height: 28),

                // Tombol Simpan
                _buildSimpanButton(),

                const SizedBox(height: 16),

                // Tombol Hapus
                _buildHapusButton(),

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
                    'Edit Dokter',
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

  Widget _buildEmailInfoBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFF0284C7),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email Login Dokter',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0284C7),
                  ),
                ),
                Text(
                  widget.staffAccount!.email,
                  style: GoogleFonts.lato(
                    fontSize: 13.5,
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
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
      style: GoogleFonts.lato(fontSize: 14.5, color: const Color(0xFF0F172A)),
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
          const Icon(Icons.wifi_rounded, size: 20, color: Color(0xFF94A3B8)),
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

  Widget _buildActiveToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isActive
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isActive
              ? const Color(0xFFBBF7D0)
              : const Color(0xFFFECACA),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isActive
                ? Icons.check_circle_outline_rounded
                : Icons.cancel_outlined,
            size: 20,
            color: _isActive
                ? const Color(0xFF16A34A)
                : const Color(0xFFDC2626),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Akun Dokter',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  _isActive
                      ? 'Dokter dapat login ke aplikasi'
                      : 'Akun dokter dinonaktifkan (tidak bisa login)',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: _isActive
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            activeColor: const Color(0xFF16A34A),
            inactiveThumbColor: const Color(0xFFDC2626),
            inactiveTrackColor: const Color(0xFFFECACA),
            onChanged: (val) => setState(() => _isActive = val),
          ),
        ],
      ),
    );
  }

  Widget _buildGantiPasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle ganti password
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _isGantiPassword = !_isGantiPassword),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isGantiPassword
                    ? const Color(0xFF7C3AED).withValues(alpha: 0.4)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.key_rounded,
                  size: 20,
                  color: Color(0xFF7C3AED),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ganti Password Dokter',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Icon(
                  _isGantiPassword
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),

        // Field password (muncul jika toggle aktif)
        if (_isGantiPassword) ...[
          const SizedBox(height: 12),
          _buildPasswordField(
            controller: _passwordBaruCtrl,
            label: 'Password Baru',
            hint: 'Minimal 6 karakter',
            isVisible: _isPasswordVisible,
            onToggle: () =>
                setState(() => _isPasswordVisible = !_isPasswordVisible),
            validator: (v) {
              if (!_isGantiPassword) return null;
              if (v == null || v.isEmpty) return 'Password baru wajib diisi';
              if (v.length < 6) return 'Password minimal 6 karakter';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildPasswordField(
            controller: _konfirmasiPasswordCtrl,
            label: 'Konfirmasi Password',
            hint: 'Ulangi password baru',
            isVisible: _isKonfirmasiVisible,
            onToggle: () =>
                setState(() => _isKonfirmasiVisible = !_isKonfirmasiVisible),
            validator: (v) {
              if (!_isGantiPassword) return null;
              if (v != _passwordBaruCtrl.text) return 'Password tidak cocok';
              return null;
            },
          ),
        ],
      ],
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
      style: GoogleFonts.lato(fontSize: 14.5, color: const Color(0xFF0F172A)),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
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

  Widget _buildSimpanButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _simpan,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3985E7),
          disabledBackgroundColor:
              const Color(0xFF3985E7).withValues(alpha: 0.5),
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
                'Simpan Perubahan',
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildHapusButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _konfirmasiHapus,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFDC2626),
          side: const BorderSide(color: Color(0xFFFCA5A5), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.delete_outline_rounded, size: 20),
        label: Text(
          'Hapus Dokter',
          style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
