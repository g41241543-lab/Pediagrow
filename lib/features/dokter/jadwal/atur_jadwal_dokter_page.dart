import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/doctor_service.dart';
import '../../../core/services/jadwal_dokter_service.dart';
import '../../../core/services/staff_auth_service.dart';
import '../../../shared/widgets/pedia_banner.dart';
import '../beranda/beranda_dokter_page.dart';

/// Halaman Atur Jadwal Dokter:
/// - Saklar aktif/nonaktif per hari (Senin sampai Minggu)
/// - Pengaturan sesi jam kerja (misal: Pagi 08:30-11:30 dan Sore 15:00-17:00) beserta durasi slot
/// - Pengaturan cuti/libur pada tanggal tertentu (seharian atau jam tertentu) lengkap dengan alasan
/// - Deteksi & pembatalan otomatis booking yang terdampak cuti dengan notifikasi reschedule
class AturJadwalDokterPage extends StatefulWidget {
  final String? dokterId;
  final String? doctorName;
  final bool isSuperadmin;

  const AturJadwalDokterPage({
    super.key,
    this.dokterId,
    this.doctorName,
    this.isSuperadmin = false,
  });

  @override
  State<AturJadwalDokterPage> createState() => _AturJadwalDokterPageState();
}

class _AturJadwalDokterPageState extends State<AturJadwalDokterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final JadwalDokterService _jadwalService = JadwalDokterService();

  late String _targetDoctorId;
  String? _targetDoctorName;
  List<JadwalPraktikModel> _currentJadwal = [];
  bool _isLoading = true;

  static const Color _primaryBlue = Color(0xFF0284C7);
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg =>
      _isDark ? const Color(0xFF1A2228) : Colors.white;
  Color get _borderColor =>
      _isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF);
  Color get _textBlack =>
      _isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014);
  Color get _textGrey =>
      _isDark ? const Color(0xFF8696A0) : const Color(0xFF667781);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _targetDoctorId = widget.dokterId ?? '';
    _targetDoctorName = widget.doctorName;
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    String resolvedId = widget.dokterId ?? '';
    String? resolvedName = widget.doctorName;

    if (resolvedId.isEmpty) {
      final staff = StaffAuthService().currentStaff;
      if (staff != null) {
        resolvedName ??= staff.name;
        final doc = DoctorService().findDoctorForStaff(staff);
        if (doc != null) {
          resolvedId = doc.id;
          resolvedName = doc.name;
        } else {
          resolvedId = staff.id;
        }
      } else {
        resolvedId = 'doc_1';
      }
    }

    _targetDoctorId = resolvedId;
    _targetDoctorName = resolvedName;
    final jadwal = _jadwalService.getJadwalDokter(_targetDoctorId);

    if (mounted) {
      setState(() {
        _currentJadwal = List.from(jadwal);
        _isLoading = false;
      });
    }
  }

  Future<void> _saveJadwal() async {
    setState(() => _isLoading = true);
    final role = widget.isSuperadmin ? 'superadmin' : 'dokter';

    await _jadwalService.simpanSemuaJadwalDokter(
      dokterId: _targetDoctorId,
      jadwalList: _currentJadwal,
      rolePelaku: role,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      PediaBanner.showSuccess(
        context,
        message: 'Jadwal praktik berhasil disimpan dan disinkronkan ke menu konsultasi!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final docDisplayName = _targetDoctorName ?? widget.doctorName;
    final title = docDisplayName != null
        ? 'Jadwal Praktik - $docDisplayName'
        : 'Atur Jadwal Praktik';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const BerandaDokterPage()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: _isDark ? const Color(0xFF0B1014) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: _isDark ? const Color(0xFF0B1014) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: _textBlack),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const BerandaDokterPage()),
                );
              }
            },
          ),
        title: Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _textBlack,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _primaryBlue,
          unselectedLabelColor: _textGrey,
          indicatorColor: _primaryBlue,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.lato(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Jadwal Mingguan', icon: Icon(Icons.calendar_month_outlined, size: 20)),
            Tab(text: 'Atur Cuti / Libur', icon: Icon(Icons.beach_access_outlined, size: 20)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryBlue))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildJadwalMingguanTab(),
                _buildCutiTab(),
              ],
            ),
      bottomNavigationBar: _tabController.index == 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _isDark ? const Color(0xFF1A2228) : Colors.white,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveJadwal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Simpan Jadwal Praktik',
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
      ),
    );
  }

  // ===========================================================================
  // TAB 1: JADWAL MINGGUAN
  // ===========================================================================

  Widget _buildJadwalMingguanTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: _primaryBlue, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Aktifkan hari kerja dan atur sesi konsultasi. Pasien hanya dapat memesan slot pada jam yang aktif.',
                  style: GoogleFonts.lato(
                    fontSize: 12.5,
                    color: _isDark ? const Color(0xFF93C5FD) : const Color(0xFF0369A1),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (int day = 1; day <= 7; day++) _buildHariCard(day),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildHariCard(int day) {
    final namaHari = JadwalPraktikModel.getNamaHari(day);
    final sessions = _currentJadwal.where((j) => j.hari == day).toList();
    final isDayActive = sessions.any((j) => j.aktif);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDayActive
              ? (_isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD))
              : _borderColor,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isDayActive
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF8696A0),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      namaHari,
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textBlack,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: isDayActive,
                  activeThumbColor: _primaryBlue,
                  onChanged: (val) {
                    setState(() {
                      if (val) {
                        // Jika hari diaktifkan dan belum punya sesi, buat sesi default
                        if (sessions.isEmpty) {
                          _currentJadwal.add(
                            JadwalPraktikModel(
                              id: '${_targetDoctorId}_day_${day}_1',
                              dokterId: _targetDoctorId,
                              hari: day,
                              jamMulai: '08:30',
                              jamSelesai: '11:30',
                              durasiSlotMenit: 30,
                              aktif: true,
                              dibuatOleh: widget.isSuperadmin ? 'superadmin' : 'dokter',
                            ),
                          );
                        } else {
                          for (int i = 0; i < _currentJadwal.length; i++) {
                            if (_currentJadwal[i].hari == day) {
                              _currentJadwal[i] =
                                  _currentJadwal[i].copyWith(aktif: true);
                            }
                          }
                        }
                      } else {
                        // Nonaktifkan semua sesi pada hari ini
                        for (int i = 0; i < _currentJadwal.length; i++) {
                          if (_currentJadwal[i].hari == day) {
                            _currentJadwal[i] =
                                  _currentJadwal[i].copyWith(aktif: false);
                          }
                        }
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          if (isDayActive) ...[
            Divider(height: 1, color: _borderColor),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (final s in sessions)
                    if (s.aktif)
                      _buildSesiRow(
                        sesi: s,
                        onEdit: () => _showDialogEditSesi(s),
                        onDelete: () {
                          setState(() {
                            _currentJadwal.removeWhere((item) => item.id == s.id);
                          });
                        },
                      ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _showDialogTambahSesi(day),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_circle_outline, size: 18, color: _primaryBlue),
                          const SizedBox(width: 6),
                          Text(
                            'Tambah Sesi Jam Kerja',
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSesiRow({
    required JadwalPraktikModel sesi,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF222C33) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded, size: 16, color: _primaryBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${sesi.jamMulai} - ${sesi.jamSelesai} WIB',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _textBlack,
                  ),
                ),
                Text(
                  'Durasi slot: ${sesi.durasiSlotMenit} menit',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: _textGrey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: _primaryBlue),
            onPressed: onEdit,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
            onPressed: onDelete,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
        ],
      ),
    );
  }

  void _showDialogTambahSesi(int day) {
    _showSesiFormDialog(
      day: day,
      initialStart: '08:30',
      initialEnd: '11:30',
      initialDuration: 30,
      onSave: (start, end, duration) {
        final newSesi = JadwalPraktikModel(
          id: '${_targetDoctorId}_day_${day}_${DateTime.now().millisecondsSinceEpoch}',
          dokterId: _targetDoctorId,
          hari: day,
          jamMulai: start,
          jamSelesai: end,
          durasiSlotMenit: duration,
          aktif: true,
          dibuatOleh: widget.isSuperadmin ? 'superadmin' : 'dokter',
        );
        setState(() => _currentJadwal.add(newSesi));
      },
    );
  }

  void _showDialogEditSesi(JadwalPraktikModel sesi) {
    _showSesiFormDialog(
      day: sesi.hari,
      initialStart: sesi.jamMulai,
      initialEnd: sesi.jamSelesai,
      initialDuration: sesi.durasiSlotMenit,
      currentId: sesi.id,
      onSave: (start, end, duration) {
        setState(() {
          final idx = _currentJadwal.indexWhere((item) => item.id == sesi.id);
          if (idx != -1) {
            _currentJadwal[idx] = sesi.copyWith(
              jamMulai: start,
              jamSelesai: end,
              durasiSlotMenit: duration,
              aktif: true,
            );
          }
        });
      },
    );
  }

  void _showSesiFormDialog({
    required int day,
    required String initialStart,
    required String initialEnd,
    required int initialDuration,
    String? currentId,
    required void Function(String start, String end, int duration) onSave,
  }) {
    final startCtrl = TextEditingController(text: initialStart);
    final endCtrl = TextEditingController(text: initialEnd);
    int selectedDuration = initialDuration;
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            currentId == null ? 'Tambah Sesi Kerja' : 'Ubah Sesi Kerja',
            style: GoogleFonts.lato(fontWeight: FontWeight.bold, color: _textBlack),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startCtrl,
                      style: GoogleFonts.lato(color: _textBlack),
                      decoration: InputDecoration(
                        labelText: 'Jam Mulai',
                        labelStyle: GoogleFonts.lato(color: _textGrey),
                        hintText: '08:30',
                        hintStyle: GoogleFonts.lato(color: _textGrey),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _borderColor)),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: endCtrl,
                      style: GoogleFonts.lato(color: _textBlack),
                      decoration: InputDecoration(
                        labelText: 'Jam Selesai',
                        labelStyle: GoogleFonts.lato(color: _textGrey),
                        hintText: '11:30',
                        hintStyle: GoogleFonts.lato(color: _textGrey),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _borderColor)),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Durasi Slot Konsultasi:',
                style: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.bold, color: _textBlack),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                initialValue: selectedDuration,
                dropdownColor: _cardBg,
                style: GoogleFonts.lato(color: _textBlack),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _borderColor)),
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(value: 15, child: Text('15 Menit', style: GoogleFonts.lato(color: _textBlack))),
                  DropdownMenuItem(value: 30, child: Text('30 Menit', style: GoogleFonts.lato(color: _textBlack))),
                  DropdownMenuItem(value: 45, child: Text('45 Menit', style: GoogleFonts.lato(color: _textBlack))),
                  DropdownMenuItem(value: 60, child: Text('60 Menit', style: GoogleFonts.lato(color: _textBlack))),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedDuration = val);
                },
              ),
              if (errorText != null) ...[
                const SizedBox(height: 10),
                Text(
                  errorText!,
                  style: GoogleFonts.lato(fontSize: 12, color: const Color(0xFFEF4444)),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Batal', style: GoogleFonts.lato(color: _textGrey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue),
              onPressed: () {
                final validationError = _jadwalService.validateSesi(
                  hari: day,
                  jamMulai: startCtrl.text.trim(),
                  jamSelesai: endCtrl.text.trim(),
                  durasiSlotMenit: selectedDuration,
                  existingSessionsOnDay: _currentJadwal.where((j) => j.hari == day).toList(),
                  currentEditingId: currentId,
                );

                if (validationError != null) {
                  setDialogState(() => errorText = validationError);
                  return;
                }

                onSave(startCtrl.text.trim(), endCtrl.text.trim(), selectedDuration);
                Navigator.of(ctx).pop();
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 2: ATUR CUTI / LIBUR
  // ===========================================================================

  Widget _buildCutiTab() {
    return ValueListenableBuilder<List<CutiDokterModel>>(
      valueListenable: _jadwalService.cutiListNotifier,
      builder: (context, allCuti, _) {
        final list = allCuti.where((c) => c.dokterId == _targetDoctorId).toList();

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isDark ? const Color(0xFF2D2305) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.beach_access, color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tambahkan cuti jika berhalangan praktik. Booking pasien yang bertabrakan akan dibatalkan otomatis dan dikirimi notifikasi untuk menjadwalkan ulang.',
                      style: GoogleFonts.lato(
                        fontSize: 12.5,
                        color: _isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _showTambahCutiDialog,
                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                label: Text(
                  'Tambah Cuti / Hari Libur',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Daftar Cuti Terdaftar',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _textBlack,
              ),
            ),
            const SizedBox(height: 10),
            if (list.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Text(
                  'Belum ada jadwal cuti atau libur.',
                  style: GoogleFonts.lato(color: _textGrey),
                ),
              )
            else
              for (final c in list) _buildCutiCard(c),
          ],
        );
      },
    );
  }

  Widget _buildCutiCard(CutiDokterModel cuti) {
    final tglStart = '${cuti.tanggalMulai.day}/${cuti.tanggalMulai.month}/${cuti.tanggalMulai.year}';
    final tglEnd = '${cuti.tanggalSelesai.day}/${cuti.tanggalSelesai.month}/${cuti.tanggalSelesai.year}';
    final dateLabel = tglStart == tglEnd ? tglStart : '$tglStart - $tglEnd';
    final timeLabel = cuti.isSeharian ? 'Libur Seharian' : '${cuti.jamMulai} - ${cuti.jamSelesai} WIB';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF3B1818) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.event_busy, color: Color(0xFFEF4444), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _textBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeLabel,
                  style: GoogleFonts.lato(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Alasan: ${cuti.alasan}',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: _textGrey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
            onPressed: () => _confirmHapusCuti(cuti),
          ),
        ],
      ),
    );
  }

  void _showTambahCutiDialog() {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    bool isSeharian = true;
    final jamMulaiCtrl = TextEditingController(text: '08:30');
    final jamSelesaiCtrl = TextEditingController(text: '11:30');
    final alasanCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          // Hitung pasien terdampak secara langsung untuk preview
          final affected = _jadwalService.cariBookingTerdampak(
            dokterId: _targetDoctorId,
            tanggalMulai: selectedDate,
            tanggalSelesai: selectedDate,
            jamMulai: isSeharian ? null : jamMulaiCtrl.text.trim(),
            jamSelesai: isSeharian ? null : jamSelesaiCtrl.text.trim(),
          );

          return AlertDialog(
            backgroundColor: _cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Tambah Cuti / Libur Dokter',
              style: GoogleFonts.lato(fontWeight: FontWeight.bold, color: _textBlack),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih Tanggal:',
                    style: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.bold, color: _textBlack),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _isDark ? const Color(0xFF222C33) : Colors.transparent,
                        border: Border.all(color: _borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: _primaryBlue),
                          const SizedBox(width: 8),
                          Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            style: GoogleFonts.lato(fontSize: 14, color: _textBlack),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Libur Seharian:',
                        style: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.bold, color: _textBlack),
                      ),
                      Switch(
                        value: isSeharian,
                        activeThumbColor: _primaryBlue,
                        onChanged: (val) => setDialogState(() => isSeharian = val),
                      ),
                    ],
                  ),
                  if (!isSeharian) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: jamMulaiCtrl,
                            style: GoogleFonts.lato(color: _textBlack),
                            decoration: InputDecoration(
                              labelText: 'Jam Mulai',
                              labelStyle: GoogleFonts.lato(color: _textGrey),
                              isDense: true,
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _borderColor)),
                            ),
                            onChanged: (_) => setDialogState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: jamSelesaiCtrl,
                            style: GoogleFonts.lato(color: _textBlack),
                            decoration: InputDecoration(
                              labelText: 'Jam Selesai',
                              labelStyle: GoogleFonts.lato(color: _textGrey),
                              isDense: true,
                              border: const OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _borderColor)),
                            ),
                            onChanged: (_) => setDialogState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextField(
                    controller: alasanCtrl,
                    style: GoogleFonts.lato(color: _textBlack),
                    decoration: InputDecoration(
                      labelText: 'Alasan Cuti',
                      labelStyle: GoogleFonts.lato(color: _textGrey),
                      hintText: 'Contoh: Seminar medis / dinas luar',
                      hintStyle: GoogleFonts.lato(color: _textGrey),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: _borderColor)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (affected.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isDark ? const Color(0xFF3B1818) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Perhatian: Terdapat ${affected.length} booking pasien terdampak yang akan otomatis dibatalkan.',
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                color: _isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Batal', style: GoogleFonts.lato(color: _textGrey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue),
                onPressed: () async {
                  if (alasanCtrl.text.trim().isEmpty) {
                    PediaBanner.showError(dialogCtx, message: 'Harap isi alasan cuti!');
                    return;
                  }

                  final newCuti = CutiDokterModel(
                    id: 'cuti_${DateTime.now().millisecondsSinceEpoch}',
                    dokterId: _targetDoctorId,
                    tanggalMulai: selectedDate,
                    tanggalSelesai: selectedDate,
                    jamMulai: isSeharian ? null : jamMulaiCtrl.text.trim(),
                    jamSelesai: isSeharian ? null : jamSelesaiCtrl.text.trim(),
                    alasan: alasanCtrl.text.trim(),
                    dibuatOleh: widget.isSuperadmin ? 'superadmin' : 'dokter',
                  );

                  final affectedCount = await _jadwalService.tambahCuti(cuti: newCuti);
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }
                  if (!mounted) return;
                  if (affectedCount > 0) {
                    PediaBanner.showSuccess(
                      context,
                      message: 'Cuti disimpan. $affectedCount pasien terdampak telah dibatalkan & diberitahu.',
                    );
                  } else {
                    PediaBanner.showSuccess(context, message: 'Cuti dokter berhasil ditambahkan!');
                  }
                },
                child: const Text('Simpan Cuti'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmHapusCuti(CutiDokterModel cuti) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Cuti?', style: GoogleFonts.lato(fontWeight: FontWeight.bold, color: _textBlack)),
        content: Text(
          'Jadwal dokter pada tanggal ini akan kembali aktif sesuai jadwal mingguan.',
          style: GoogleFonts.lato(color: _textBlack),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Batal', style: GoogleFonts.lato(color: _textGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              await _jadwalService.hapusCuti(cuti.id);
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
              if (mounted) {
                PediaBanner.showSuccess(context, message: 'Cuti dokter dihapus.');
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
