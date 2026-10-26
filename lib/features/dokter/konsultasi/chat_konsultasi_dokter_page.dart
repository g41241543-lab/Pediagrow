import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/chat_message_service.dart';
import '../../../core/services/konsultasi_service.dart';
import '../../../core/services/staff_auth_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../models/booking_consultation_model.dart';
import '../../../models/chat_message_model.dart';
import '../../../models/child_model.dart';
import '../../../models/doctor_model.dart';
import '../../../models/user_model.dart';
import '../../../shared/widgets/child_avatar.dart';
import 'buat_resume_medis_dokter_page.dart';

/// Halaman Ruang Obrolan Konsultasi dari POV DOKTER.
///
/// Tampilan diselaraskan persis dengan POV Pengguna:
/// - Header biru (#2A85FF) dengan nama anak, nama orang tua, avatar anak/pasien, dan online dot.
/// - Formulir Keluhan Pasien di sisi kiri (dikirim oleh orang tua), dapat diklik untuk
///   membuka rincian data formulir lengkap.
/// - Bubble pesan orang tua di sisi kiri, bubble balasan dokter di sisi kanan (biru).
/// - Input area bawah: Tombol [+] untuk foto/kamera, TextField pesan, tombol Akhiri Konsultasi
///   (icon bookmark/selesai merah muda), dan tombol kirim bulat biru.
/// - Tombol "Akhiri Konsultasi" memunculkan dialog konfirmasi. Jika "Ya, Akhiri" ditekan,
///   dokter langsung diarahkan ke [BuatResumeMedisDokterPage].
class ChatKonsultasiDokterPage extends StatefulWidget {
  final ChildModel? child;
  final UserModel? parentUser;
  final String? parentName;
  final String? doctorName;
  final DoctorModel? doctor;
  final String? complaint;
  final double? weightKg;
  final double? heightCm;
  final bool hasActiveSession;

  // ID sesi konsultasi aktif di Firestore
  final String? sessionId;

  /// Data booking konsultasi jika ada
  final BookingConsultationModel? booking;

  /// Apakah halaman ini disematkan di dalam Tab Ruang Obrolan Detail Anak
  final bool isEmbedded;

  /// Widget info jadwal konsultasi opsional yang ditampilkan di bagian paling atas chat list
  final Widget? topCard;

  const ChatKonsultasiDokterPage({
    super.key,
    this.child,
    this.parentUser,
    this.parentName,
    this.doctorName,
    this.doctor,
    this.complaint,
    this.weightKg,
    this.heightCm,
    this.hasActiveSession = true,
    this.sessionId,
    this.booking,
    this.isEmbedded = false,
    this.topCard,
  });

  @override
  State<ChatKonsultasiDokterPage> createState() =>
      _ChatKonsultasiDokterPageState();
}

class _ChatKonsultasiDokterPageState extends State<ChatKonsultasiDokterPage>
    with TickerProviderStateMixin {
  // Design Tokens Resmi PediaGrow
  static const Color colorPrimaryBlue = Color(0xFF2A85FF);
  static const Color colorWhite = Color(0xFFFFFFFF);
  static const Color colorSoftBlue = Color(0xFFEBF5FF);
  static const Color colorSoftGrey = Color(0xFFF8FAFC);
  static const Color colorTextPrimary = Color(0xFF1A202C);
  static const Color colorTextSecondary = Color(0xFF718096);
  static const Color colorBorder = Color(0xFFE9EDEF);
  static const Color colorOnlineGreen = Color(0xFF48BB78);
  static const Color colorEndRed = Color(0xFFE53E3E);

  final TextEditingController _textController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  late AnimationController _typingAnimController;

  bool _isParentTyping = false;
  Map<String, dynamic>? _replyingTo;
  late String _effectiveChildName;
  late String _effectiveChildAge;
  late String _effectiveChildGender;
  late String _effectiveParentName;
  late String _effectiveDoctorName;

  double? _liveWeightKg;
  double? _liveHeightCm;
  String? _liveComplaint;

  late List<Map<String, dynamic>> _messages;

  // Stream Firestore – aktif jika sessionId tersedia
  Stream<List<ChatMessageModel>>? _messageStream;

  // Listener status sesi (untuk deteksi pengakhiran dari pihak pengguna dan sinkronisasi data)
  StreamSubscription<dynamic>? _sessionSub;
  // Flag: true jika kita sendiri yang mengakhiri (hindari reaksi ganda)
  bool _sessionEndedByUs = false;

  @override
  void initState() {
    super.initState();
    _resolveData();
    _initMessages();

    // Aktifkan stream Firestore jika sessionId tersedia
    if (widget.sessionId != null && widget.sessionId!.isNotEmpty) {
      _messageStream = ChatMessageService.instance.streamPesan(
        widget.sessionId!,
      );

      // Dengarkan perubahan status & data sesi dari Firestore
      _sessionSub = KonsultasiService.instance
          .streamSesi(widget.sessionId!)
          .listen((sesi) {
            if (!mounted) return;
            if (sesi != null) {
              bool updated = false;
              if (sesi.weightKg != null &&
                  sesi.weightKg! > 0 &&
                  _liveWeightKg != sesi.weightKg) {
                _liveWeightKg = sesi.weightKg;
                updated = true;
              }
              if (sesi.heightCm != null &&
                  sesi.heightCm! > 0 &&
                  _liveHeightCm != sesi.heightCm) {
                _liveHeightCm = sesi.heightCm;
                updated = true;
              }
              if (sesi.keluhanAwal != null &&
                  sesi.keluhanAwal!.trim().isNotEmpty &&
                  _liveComplaint != sesi.keluhanAwal!.trim()) {
                _liveComplaint = sesi.keluhanAwal!.trim();
                updated = true;
              }
              if (updated) {
                setState(() {});
              }
            }
            if (_sessionEndedByUs) return; // kita yang mengakhiri, abaikan
            if (sesi != null && sesi.isSelesai) {
              // Pengguna mengakhiri konsultasi → dokter langsung ke buat resume
              _sessionEndedByUs = true;
              _sessionSub?.cancel();
              _navigateToBuatResume();
            }
          });
    }

    _typingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant ChatKonsultasiDokterPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId) {
      if (widget.sessionId != null && widget.sessionId!.isNotEmpty) {
        setState(() {
          _messageStream = ChatMessageService.instance.streamPesan(
            widget.sessionId!,
          );
        });
      } else {
        setState(() {
          _messageStream = null;
        });
      }
    }
    if (widget.weightKg != null && widget.weightKg != oldWidget.weightKg) {
      _liveWeightKg = widget.weightKg;
    }
    if (widget.heightCm != null && widget.heightCm != oldWidget.heightCm) {
      _liveHeightCm = widget.heightCm;
    }
    if (widget.complaint != null && widget.complaint != oldWidget.complaint) {
      _liveComplaint = widget.complaint;
    }
  }

  void _resolveData() {
    final c = widget.child;
    _effectiveChildName = c?.name.isNotEmpty == true
        ? c!.name
        : 'Arfa Zivano Kayfan';
    _effectiveChildAge = c?.ageDescription.isNotEmpty == true
        ? c!.ageDescription
        : '0 tahun 4 bulan 23 hari';
    _effectiveChildGender = c?.gender.isNotEmpty == true
        ? c!.gender
        : 'Laki-laki';

    final p = widget.parentUser;
    _effectiveParentName = p?.name.isNotEmpty == true
        ? p!.name
        : widget.parentName ?? 'Susanti Saputri Dewi';

    final staff = StaffAuthService().currentStaff;
    _effectiveDoctorName =
        staff?.name ??
        widget.doctorName ??
        widget.doctor?.name ??
        'dr. Spesialis Anak';

    _liveWeightKg =
        widget.weightKg ?? widget.booking?.weightKg ?? widget.child?.weightKg;
    _liveHeightCm =
        widget.heightCm ?? widget.booking?.heightCm ?? widget.child?.heightCm;
    _liveComplaint = widget.complaint ?? widget.booking?.complaint;
  }

  void _initMessages() {
    // Tidak ada pesan dummy formulir/teks palsu.
    // Ruang obrolan hanya menampilkan pesan riil yang dikirim oleh dokter dan orang tua.
    _messages = [];
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    _textController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    _typingAnimController.dispose();
    super.dispose();
  }

  /// Navigasi ke BuatResumeMedisDokterPage (dipanggil baik saat dokter
  /// mengakhiri sendiri maupun saat terdeteksi pengguna mengakhiri).
  void _navigateToBuatResume() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BuatResumeMedisDokterPage(
          child: widget.child,
          parentUser: widget.parentUser,
          parentName: _effectiveParentName,
          doctorName: _effectiveDoctorName,
          complaint:
              _liveComplaint ?? widget.complaint ?? widget.booking?.complaint,
          weightKg:
              _liveWeightKg ?? widget.weightKg ?? widget.booking?.weightKg,
          heightCm:
              _liveHeightCm ?? widget.heightCm ?? widget.booking?.heightCm,
          sessionId: widget.sessionId,
          booking: widget.booking,
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? customText]) {
    final text = customText ?? _textController.text.trim();
    if (text.isEmpty) return;

    final replyTarget = _replyingTo;
    if (replyTarget != null && customText == null) {
      setState(() {
        _replyingTo = null;
      });
    }

    final replyId = replyTarget?['id'] as String?;
    final replySender = replyTarget != null
        ? (replyTarget['sender'] == 'doctor' ? 'Anda' : _effectiveParentName)
        : null;
    final replyType = replyTarget?['type'] as String?;
    String? replyText = replyTarget?['message'] as String?;
    if (replyType == 'attachment_image' || replyType == 'user_attachment') {
      replyText = (replyText != null && replyText.isNotEmpty)
          ? replyText
          : '📷 Foto';
    } else if (replyType == 'attachment') {
      replyText = '📋 Formulir Keluhan Pasien';
    }

    // Kirim ke Firestore jika sessionId tersedia
    if (widget.sessionId != null && widget.sessionId!.isNotEmpty) {
      final staffId = StaffAuthService().currentStaff?.id ?? '';
      ChatMessageService.instance.kirimTeks(
        sessionId: widget.sessionId!,
        senderId: staffId,
        senderRole: MessageSender.dokter,
        text: text,
        replyToId: replyId,
        replyToSender: replySender,
        replyToText: replyText,
        replyToType: replyType,
      );
      // Tandai pesan user sebagai sudah dibaca
      ChatMessageService.instance.tandaiSudahDibaca(
        sessionId: widget.sessionId!,
        readerRole: MessageSender.dokter,
      );
      if (customText == null) _textController.clear();
      return;
    }

    // Fallback offline (tanpa sessionId) — seperti semula
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _messages.add({
        'sender': 'doctor',
        'type': 'text',
        'message': text,
        'timestamp': timeStr,
        'isRead': true,
        'replyToId': replyId,
        'replyToSender': replySender,
        'replyToText': replyText,
        'replyToType': replyType,
      });
      if (customText == null) {
        _textController.clear();
      }
    });

    _scrollToBottom();
    _triggerSimulatedParentReply(text);
  }

  void _triggerSimulatedParentReply(String doctorMsg) {
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _isParentTyping = true);
      _scrollToBottom();

      Future.delayed(const Duration(milliseconds: 2200), () {
        if (!mounted) return;

        final replyTime = DateTime.now();
        final replyTimeStr =
            '${replyTime.hour.toString().padLeft(2, '0')}.${replyTime.minute.toString().padLeft(2, '0')}';

        String parentReply =
            'Baik Dok, terima kasih banyak atas penjelasannya. Akan segera saya terapkan arahan dari Dokter.';

        final lower = doctorMsg.toLowerCase();
        if (lower.contains('suhu') ||
            lower.contains('demam') ||
            lower.contains('panas')) {
          parentReply = 'Tadi siang dicek suhunya 38.3°C Dok. Sekarang si kecil sedang tidur pulas setelah saya kompres air hangat.';
        } else if (lower.contains('makan') ||
            lower.contains('minum') ||
            lower.contains('cairan')) {
          parentReply = 'Untuk ASI masih mau minum sedikit-sedikit Dok, tapi makannya memang agak menolak.';
        } else if (lower.contains('obat') || lower.contains('paracetamol')) {
          parentReply = 'Siap Dok, saya sudah siapkan paracetamol sirup di rumah. Segera saya berikan sesuai takaran dosis BB.';
        }

        setState(() {
          _isParentTyping = false;
          _messages.add({
            'sender': 'user', // Balasan orang tua -> tampil di sebelah KIRI
            'type': 'text',
            'message': parentReply,
            'timestamp': replyTimeStr,
            'isRead': true,
          });
        });

        _scrollToBottom();
      });
    });
  }

  // Menampilkan menu pemilihan sumber lampiran (Kamera / Galeri)
  void _showAttachmentPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D7DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Kirim Foto / Lampiran',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0B1014),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: colorPrimaryBlue,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Ambil Foto dari Kamera',
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0B1014),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickAttachment(ImageSource.camera);
                  },
                ),
                const Divider(height: 1, color: Color(0xFFE9EDEF)),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: colorPrimaryBlue,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Pilih Foto dari Galeri',
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0B1014),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickAttachment(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAttachment(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (file != null) {
        final replyTarget = _replyingTo;
        if (replyTarget != null) {
          setState(() {
            _replyingTo = null;
          });
        }

        final replyId = replyTarget?['id'] as String?;
        final replySender = replyTarget != null
            ? (replyTarget['sender'] == 'doctor'
                  ? 'Anda'
                  : _effectiveParentName)
            : null;
        final replyType = replyTarget?['type'] as String?;
        String? replyText = replyTarget?['message'] as String?;
        if (replyType == 'attachment_image' || replyType == 'user_attachment') {
          replyText = (replyText != null && replyText.isNotEmpty)
              ? replyText
              : '📷 Foto';
        } else if (replyType == 'attachment') {
          replyText = '📋 Formulir Keluhan Pasien';
        }

        if (widget.sessionId != null && widget.sessionId!.isNotEmpty) {
          final staffId = StaffAuthService().currentStaff?.id ?? '';
          await ChatMessageService.instance.kirimGambar(
            sessionId: widget.sessionId!,
            senderId: staffId,
            senderRole: MessageSender.dokter,
            imageFile: File(file.path),
            replyToId: replyId,
            replyToSender: replySender,
            replyToText: replyText,
            replyToType: replyType,
          );
          return;
        }

        final now = DateTime.now();
        final timeStr =
            '${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')}';

        setState(() {
          _messages.add({
            'sender': 'doctor',
            'type': 'attachment_image',
            'filePath': file.path,
            'timestamp': timeStr,
            'isRead': true,
            'replyToId': replyId,
            'replyToSender': replySender,
            'replyToText': replyText,
            'replyToType': replyType,
          });
        });

        _scrollToBottom();
      }
    } catch (_) {}
  }

  // Modal Rincian Formulir Keluhan Pasien persis seperti POV Pengguna
  void _showFormulirDetailDialog([String? customComplaint]) {
    final effectiveWeight =
        _liveWeightKg ??
        widget.weightKg ??
        widget.booking?.weightKg ??
        widget.child?.weightKg;
    final String weightStr = (effectiveWeight != null && effectiveWeight > 0)
        ? (effectiveWeight % 1 == 0
              ? '${effectiveWeight.toInt()} kg'
              : '$effectiveWeight kg')
        : '-';

    final effectiveHeight =
        _liveHeightCm ??
        widget.heightCm ??
        widget.booking?.heightCm ??
        widget.child?.heightCm;
    final String heightStr = (effectiveHeight != null && effectiveHeight > 0)
        ? (effectiveHeight % 1 == 0
              ? '${effectiveHeight.toInt()} cm'
              : '$effectiveHeight cm')
        : '-';

    final effectiveComp =
        (customComplaint != null && customComplaint.trim().isNotEmpty)
        ? customComplaint.trim()
        : ((_liveComplaint != null && _liveComplaint!.trim().isNotEmpty)
              ? _liveComplaint!.trim()
              : ((widget.complaint != null &&
                        widget.complaint!.trim().isNotEmpty)
                    ? widget.complaint!.trim()
                    : (widget.booking?.complaint?.trim().isNotEmpty == true
                          ? widget.booking!.complaint!.trim()
                          : '-')));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D7DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header Modal
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colorSoftBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: colorPrimaryBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Formulir Keluhan Pasien',
                          style: GoogleFonts.lato(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: colorTextPrimary,
                          ),
                        ),
                        Text(
                          'Data yang dikirimkan sebelum konsultasi',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: colorTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE9EDEF)),
              const SizedBox(height: 16),

              // Field 1: Nama Anak
              _buildDetailItem(
                label: 'Nama Anak',
                value: '$_effectiveChildName ($_effectiveChildGender)',
                icon: Icons.child_care_rounded,
              ),
              const SizedBox(height: 12),

              // Field 2: Usia
              _buildDetailItem(
                label: 'Usia Anak',
                value: _effectiveChildAge,
                icon: Icons.calendar_today_rounded,
              ),
              const SizedBox(height: 12),

              // Field 3: Berat & Tinggi Badan
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      label: 'Berat Badan',
                      value: weightStr,
                      icon: Icons.scale_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailItem(
                      label: 'Tinggi Badan',
                      value: heightStr,
                      icon: Icons.straighten_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Field 4: Keluhan Pasien
              Text(
                'Keluhan yang Dilaporkan',
                style: GoogleFonts.lato(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorBorder),
                ),
                child: Text(
                  effectiveComp,
                  style: GoogleFonts.lato(
                    fontSize: 13.5,
                    color: colorTextPrimary,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorPrimaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: colorTextSecondary,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.lato(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: colorTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dialog Konfirmasi Akhiri Konsultasi -> Mengarahkan ke Buat Resume Medis
  void _onAkhiriKonsultasiPressed() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ikon Peringatan Segitiga Merah dalam Lingkaran Soft Red
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFECEC),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFE53E3E),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Judul
                Text(
                  'Akhiri Konsultasi ini?',
                  style: GoogleFonts.lato(
                    fontSize: 18.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A202C),
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Deskripsi
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'Setelah konsultasi diakhiri, Anda akan langsung diarahkan ke halaman pembuatan Resume Medis untuk pasien anak ini.',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: const Color(0xFF4A5568),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),

                // Tombol Batal & Ya, Akhiri
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE9EDEF),
                            foregroundColor: const Color(0xFF718096),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Batal',
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx); // Tutup dialog

                            // Jika ada sesi Firestore, tandai sebagai selesai
                            if (widget.sessionId != null &&
                                widget.sessionId!.isNotEmpty) {
                              _sessionEndedByUs = true; // kita yang mengakhiri
                              KonsultasiService.instance.akhiriSesi(
                                widget.sessionId!,
                              );
                            }

                            // Navigasi ke halaman Buat Resume Medis Dokter
                            _navigateToBuatResume();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53E3E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Ya, Akhiri',
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── BUILD UTAMA ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bodyContent = Column(
      children: [
        // 1. Header Pasien POV Dokter (Biru #2A85FF) - hanya tampil jika tidak embedded
        if (!widget.isEmbedded) _buildDoctorHeader(),

        // 2. Kolom Chat (Expanded)
        Expanded(child: _buildChatList()),

        // 3. Input Area Pesan di Bawah
        // Dokter hanya dapat mengirim pesan, foto/lampiran, dan akhiri konsul saat sesi aktif / jadwal booking tiba!
        if (widget.hasActiveSession)
          _buildInputArea()
        else
          _buildLockedChatBar(),
      ],
    );

    if (widget.isEmbedded) {
      return Container(color: colorWhite, child: bodyContent);
    }

    return Scaffold(
      backgroundColor: colorWhite,
      resizeToAvoidBottomInset: true,
      body: bodyContent,
    );
  }

  /// Tampilan footer terkunci ketika konsultasi belum memasuki waktu jadwal booking
  Widget _buildLockedChatBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: Color(0xFFE9EDEF))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_clock_rounded,
              size: 16,
              color: Color(0xFF667781),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Ruang chat aktif saat jadwal konsultasi tiba',
                style: GoogleFonts.lato(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF667781),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. HEADER PASIEN POV DOKTER (Biru #2A85FF Sesuai Screenshot)
  // ===========================================================================
  Widget _buildDoctorHeader() {
    return Container(
      width: double.infinity,
      color: colorPrimaryBlue,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 2),

              // Avatar Pasien / Anak dengan Border Putih & Online Dot Hijau
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE9EDEF),
                      border: Border.all(color: colorWhite, width: 2.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child:
                        widget.child?.photoUrl != null &&
                            widget.child!.photoUrl!.isNotEmpty
                        ? Image.network(
                            widget.child!.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                ChildAvatar(child: widget.child, size: 44),
                          )
                        : ChildAvatar(child: widget.child, size: 44),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: colorOnlineGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: colorWhite, width: 1.8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Teks: Nama Anak & Orang Tua
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _effectiveChildName,
                      style: GoogleFonts.lato(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: colorWhite,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Orang Tua: $_effectiveParentName',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: const Color(0xFFDCE8FD),
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper konversi ChatMessageModel (Firestore) → Map lokal yang dipakai widget
  Map<String, dynamic> _firestoreToLocal(ChatMessageModel msg) {
    final t = msg.timestamp;
    final timeStr =
        '${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}';
    return {
      'id': msg.id,
      'sender': msg.senderRole == MessageSender.dokter ? 'doctor' : 'user',
      'type': msg.type == MessageType.formulir
          ? 'attachment'
          : msg.type == MessageType.image
          ? 'attachment_image'
          : 'text',
      'message': msg.text ?? '',
      // imageUrl diteruskan ke map — dipakai oleh _buildImageBubble
      'imageUrl': msg.imageUrl,
      // filePath diisi hanya jika imageUrl adalah path lokal (bukan base64/URL)
      'filePath':
          (msg.imageUrl != null &&
              !msg.imageUrl!.startsWith('data:image/') &&
              !msg.imageUrl!.startsWith('http'))
          ? msg.imageUrl
          : null,
      // Jangan simpan nama potongan base64 sebagai fileName
      'fileName':
          (msg.imageUrl != null &&
              !msg.imageUrl!.startsWith('data:image/') &&
              !msg.imageUrl!.startsWith('http'))
          ? msg.imageUrl!.split('/').last
          : '',
      'title': 'Formulir Keluhan Pasien',
      'timestamp': timeStr,
      'isRead': msg.isRead,
      'replyToId': msg.replyToId,
      'replyToSender': msg.replyToSender,
      'replyToText': msg.replyToText,
      'replyToType': msg.replyToType,
    };
  }

  // ===========================================================================
  // 4. AREA CHAT LIST
  // ===========================================================================
  Widget _buildChatList() {
    // Mode real-time Firestore
    if (_messageStream != null) {
      return StreamBuilder<List<ChatMessageModel>>(
        stream: _messageStream,
        builder: (context, snap) {
          final firestoreMsgs = snap.data ?? [];
          if (firestoreMsgs.isNotEmpty) _scrollToBottom();
          final items = firestoreMsgs.map(_firestoreToLocal).toList();
          return _buildMessageListView(items);
        },
      );
    }
    // Mode offline / fallback
    return _buildMessageListView(_messages);
  }

  Widget _buildMessageListView(List<Map<String, dynamic>> items) {
    final bool hasTopCard = widget.topCard != null;

    // Jika belum ada pesan nyata sama sekali
    if (items.isEmpty) {
      return ListView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          if (hasTopCard)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: widget.topCard!,
            ),
          const SizedBox(height: 24),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: widget.hasActiveSession
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.hasActiveSession
                          ? Icons.chat_bubble_outline_rounded
                          : Icons.event_available_rounded,
                      size: 28,
                      color: widget.hasActiveSession
                          ? const Color(0xFF10B981)
                          : const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.hasActiveSession
                        ? 'Sesi Konsultasi Telah Aktif'
                        : 'Konsultasi Belum Dimulai',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: colorTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.hasActiveSession
                        ? 'Belum ada pesan. Silakan menyapa orang tua pasien untuk memulai sesi.'
                        : 'Dokter hanya dapat melakukan konsultasi (mengirim pesan, lampiran, dan resume medis) saat jadwal konsultasi tiba.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 12.5,
                      color: colorTextSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Jika ada pesan riil
    final int topCardCount = hasTopCard ? 1 : 0;
    final int headerCount = topCardCount + 1; // +1 untuk badge 'Hari ini'
    final int typingCount = _isParentTyping ? 1 : 0;
    final int totalCount = headerCount + items.length + typingCount;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        // Index 0: Top Card info jadwal konsultasi (jika disematkan)
        if (hasTopCard && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: widget.topCard!,
          );
        }

        // Badge Tanggal "Hari ini" hanya saat ada pesan riil
        if (index == topCardCount) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 4),
              child: Text(
                'Hari ini',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  color: colorTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }

        final messageIndex = index - headerCount;
        if (messageIndex < items.length) {
          final item = items[messageIndex];
          final isDoctor = item['sender'] == 'doctor';
          final type = item['type'] ?? 'text';

          Widget bubble;
          if (type == 'attachment') {
            bubble = _buildFormulirAttachmentBubble(item);
          } else if (type == 'attachment_image') {
            bubble = _buildImageBubble(item, isDoctor);
          } else if (isDoctor) {
            bubble = _buildDoctorBubble(item);
          } else {
            bubble = _buildParentBubble(item);
          }

          return _SwipeToReplyWrapper(
            onReply: () => _setReplyingTo(item),
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(item),
              child: bubble,
            ),
          );
        }

        // Typing indicator orang tua di sebelah kiri
        if (_isParentTyping) {
          return _buildParentTypingIndicator();
        }

        return const SizedBox.shrink();
      },
    );
  }

  // Formulir Keluhan Pasien di Kiri
  Widget _buildFormulirAttachmentBubble(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showFormulirDetailDialog(item['message'] as String?),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 12, 8),
              decoration: BoxDecoration(
                color: colorSoftBlue,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 22,
                        color: Color(0xFF2D3748),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          item['title'] ?? 'Formulir Keluhan Pasien',
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item['timestamp'] ?? '22.12',
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          color: colorTextSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.done_all,
                        size: 15,
                        color: colorPrimaryBlue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Bubble Chat Dokter (Kanan, Biru #2A85FF)
  Widget _buildDoctorBubble(Map<String, dynamic> item) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: screenWidth * 0.74),
          child: IntrinsicWidth(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 7),
              decoration: BoxDecoration(
                color: colorPrimaryBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item['replyToText'] != null &&
                      (item['replyToText'] as String).isNotEmpty)
                    _buildQuotedMessagePreview(item, isDocSender: true),
                  Text(
                    item['message'] ?? '',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: colorWhite,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item['timestamp'] ?? '',
                        style: GoogleFonts.lato(
                          fontSize: 10.5,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.done_all, size: 14, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Bubble Chat Orang Tua Pasien (Kiri, Putih, Border Halus)
  Widget _buildParentBubble(Map<String, dynamic> item) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFFE9EDEF),
            child: const Icon(Icons.person, size: 20, color: Color(0xFF667781)),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: screenWidth * 0.72),
            child: IntrinsicWidth(
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 7),
                decoration: BoxDecoration(
                  color: colorWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorBorder, width: 1.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item['replyToText'] != null &&
                        (item['replyToText'] as String).isNotEmpty)
                      _buildQuotedMessagePreview(item, isDocSender: false),
                    Text(
                      item['message'] ?? '',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: colorTextPrimary,
                        height: 1.38,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item['timestamp'] ?? '',
                          style: GoogleFonts.lato(
                            fontSize: 10.5,
                            color: colorTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBubble(Map<String, dynamic> item, bool isDoctor) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageUrl = item['imageUrl'] as String?;
    final filePath = item['filePath'] as String?;
    final isRead = item['isRead'] as bool? ?? false;

    // Tidak ada sumber gambar sama sekali — jangan render
    final bool isBase64Image =
        imageUrl != null && imageUrl.startsWith('data:image/');
    final bool isNetworkImage =
        imageUrl != null &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));
    final bool isLocalImage = filePath != null && File(filePath).existsSync();

    if (!isBase64Image && !isNetworkImage && !isLocalImage) {
      return const SizedBox.shrink();
    }

    // Widget gambar yang digunakan di kedua sisi
    Widget imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: isBase64Image
          ? StorageService.buildImageWidget(
              imageUrl,
              width: 220,
              height: 165,
              fit: BoxFit.cover,
            )
          : isNetworkImage
          ? Image.network(
              imageUrl,
              width: 220,
              height: 165,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            )
          : Image.file(
              File(filePath!),
              width: 220,
              height: 165,
              fit: BoxFit.cover,
            ),
    );

    // ── Bubble DOKTER: Biru, kanan, centang putih ──────────────────────────────
    if (isDoctor) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: screenWidth * 0.74),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 7),
              decoration: BoxDecoration(
                color: colorPrimaryBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item['replyToText'] != null &&
                      (item['replyToText'] as String).isNotEmpty)
                    _buildQuotedMessagePreview(item, isDocSender: true),
                  GestureDetector(
                    onTap: () => _showImagePreviewDialog(
                      imageUrl: item['imageUrl'] as String?,
                      filePath: item['filePath'] as String?,
                    ),
                    child: imageWidget,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item['timestamp'] ?? '',
                        style: GoogleFonts.lato(
                          fontSize: 10.5,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.done_all,
                        size: 14,
                        // Biru terang jika sudah dibaca, putih jika belum
                        color: isRead ? const Color(0xFF93C5FD) : Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ── Bubble ORANG TUA: Putih, kiri, dengan avatar ───────────────────────────
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFFE9EDEF),
            child: const Icon(Icons.person, size: 20, color: Color(0xFF667781)),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: screenWidth * 0.72),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 7),
              decoration: BoxDecoration(
                color: colorWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorBorder, width: 1.0),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item['replyToText'] != null &&
                      (item['replyToText'] as String).isNotEmpty)
                    _buildQuotedMessagePreview(item, isDocSender: false),
                  GestureDetector(
                    onTap: () => _showImagePreviewDialog(
                      imageUrl: item['imageUrl'] as String?,
                      filePath: item['filePath'] as String?,
                    ),
                    child: imageWidget,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item['timestamp'] ?? '',
                        style: GoogleFonts.lato(
                          fontSize: 10.5,
                          color: colorTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Typing indicator 3 titik (...) orang tua bergerak di kiri
  Widget _buildParentTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFFE9EDEF),
            child: const Icon(Icons.person, size: 20, color: Color(0xFF667781)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colorWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _typingAnimController,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (dotIndex) {
                    final progress =
                        (_typingAnimController.value + (dotIndex * 0.28)) % 1.0;
                    final bounceOffset =
                        -3.5 * (1.0 - (progress - 0.5).abs() * 2);
                    final scale =
                        0.75 + (0.35 * (1.0 - (progress - 0.5).abs() * 2));

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: Transform.translate(
                        offset: Offset(0, bounceOffset),
                        child: Transform.scale(
                          scale: scale.clamp(0.7, 1.15),
                          child: Container(
                            width: 6.5,
                            height: 6.5,
                            decoration: const BoxDecoration(
                              color: colorPrimaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. INPUT AREA BAWAH (Persis Seperti Screenshot Pengguna)
  // ===========================================================================
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: const BoxDecoration(
        color: colorWhite,
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyingTo != null) _buildReplyPreviewBar(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Tombol [+] Media / Kamera / Galeri di sisi paling kiri
                _buildAddMediaButton(),
                const SizedBox(width: 8),

                // 2. TextField "Ketik pesan..."
                Expanded(child: _buildTextField()),
                const SizedBox(width: 8),

                // 3. Tombol "Akhiri Konsultasi" (Ikon Bookmark / Akhiri Merah Muda)
                _buildEndConsultationButton(),
                const SizedBox(width: 8),

                // 4. Tombol Send Lingkaran Biru #2A85FF
                _buildSendButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _setReplyingTo(Map<String, dynamic> item) {
    HapticFeedback.lightImpact();
    setState(() {
      _replyingTo = item;
    });
    _inputFocusNode.requestFocus();
  }

  void _showMessageOptions(Map<String, dynamic> item) {
    final text = item['message'] as String? ?? '';
    final isDoctor = item['sender'] == 'doctor';
    final senderName = isDoctor ? 'Anda' : _effectiveParentName;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.reply_rounded,
                    color: colorPrimaryBlue,
                  ),
                  title: Text(
                    'Balas Pesan',
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.w600,
                      color: colorTextPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Balas pesan dari $senderName',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: colorTextSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _setReplyingTo(item);
                  },
                ),
                if (text.isNotEmpty) ...[
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ListTile(
                    leading: const Icon(
                      Icons.copy_rounded,
                      color: colorTextSecondary,
                    ),
                    title: Text(
                      'Salin Teks',
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.w600,
                        color: colorTextPrimary,
                      ),
                    ),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: text));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Pesan disalin ke clipboard',
                            style: GoogleFonts.lato(),
                          ),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReplyPreviewBar() {
    if (_replyingTo == null) return const SizedBox.shrink();

    final isDoctor = _replyingTo!['sender'] == 'doctor';
    final replySender = isDoctor ? 'Anda' : _effectiveParentName;
    final type = _replyingTo!['type'] as String? ?? 'text';
    final text = _replyingTo!['message'] as String? ?? '';
    final hasImage =
        type == 'attachment_image' ||
        type == 'user_attachment' ||
        _replyingTo!['imageUrl'] != null;
    final isFormulir = type == 'attachment';

    String previewContent = text;
    if (isFormulir) {
      previewContent = '📋 Formulir Keluhan Pasien';
    } else if (hasImage) {
      previewContent = text.isNotEmpty ? '📷 $text' : '📷 Foto';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F9),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: colorPrimaryBlue, width: 4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Membalas $replySender',
                  style: GoogleFonts.lato(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: colorPrimaryBlue,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  previewContent,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: colorTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: colorTextSecondary,
            ),
            splashRadius: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _replyingTo = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuotedMessagePreview(
    Map<String, dynamic> item, {
    required bool isDocSender,
  }) {
    final replySender = item['replyToSender'] as String? ?? 'Pesan';
    final replyText = item['replyToText'] as String? ?? '';
    if (replyText.isEmpty) return const SizedBox.shrink();

    final quoteBg = isDocSender
        ? Colors.black.withValues(alpha: 0.20)
        : const Color(0xFFF1F5F9);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: quoteBg,
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: colorPrimaryBlue, width: 3.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            replySender,
            style: GoogleFonts.lato(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: isDocSender ? Colors.white : colorPrimaryBlue,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            replyText,
            style: GoogleFonts.lato(
              fontSize: 11.5,
              color: isDocSender
                  ? Colors.white.withValues(alpha: 0.85)
                  : colorTextSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showImagePreviewDialog({String? imageUrl, String? filePath}) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) {
        final bool isBase64 =
            imageUrl != null && imageUrl.startsWith('data:image/');
        final bool isNetwork =
            imageUrl != null &&
            (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));

        Widget imgWidget;
        if (isBase64) {
          imgWidget = StorageService.buildImageWidget(
            imageUrl,
            fit: BoxFit.contain,
          );
        } else if (isNetwork) {
          imgWidget = Image.network(imageUrl, fit: BoxFit.contain);
        } else if (filePath != null && File(filePath).existsSync()) {
          imgWidget = Image.file(File(filePath), fit: BoxFit.contain);
        } else {
          imgWidget = const Center(
            child: Text(
              'Gambar tidak dapat dimuat',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                clipBehavior: Clip.none,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: imgWidget,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 26),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddMediaButton() {
    final isActive = widget.hasActiveSession;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorWhite,
        border: Border.all(
          color: isActive ? colorPrimaryBlue : const Color(0xFFD1D7DB),
          width: 1.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: isActive ? _showAttachmentPickerOptions : null,
          child: Center(
            child: Icon(
              Icons.add,
              color: isActive ? colorPrimaryBlue : const Color(0xFF8696A0),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField() {
    final isActive = widget.hasActiveSession;
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: isActive ? colorSoftGrey : const Color(0xFFE9EDEF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorBorder, width: 1.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      child: TextField(
        controller: _textController,
        enabled: isActive,
        style: GoogleFonts.lato(fontSize: 14, color: colorTextPrimary),
        textInputAction: TextInputAction.send,
        onSubmitted: isActive ? (_) => _sendMessage() : null,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          hintText: isActive
              ? 'Ketik pesan...'
              : 'Sedang tidak ada sesi konsultasi yang sedang berlangsung',
          hintStyle: GoogleFonts.lato(
            fontSize: isActive ? 13.5 : 12,
            color: const Color(0xFFA0AEC0),
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildEndConsultationButton() {
    if (!widget.hasActiveSession) {
      return const SizedBox.shrink();
    }
    return Tooltip(
      message: 'Akhiri Konsultasi',
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFFFECEC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFED7D7), width: 1.0),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _onAkhiriKonsultasiPressed,
            child: const Center(
              child: Icon(
                Icons.bookmark_outline_rounded,
                color: colorEndRed,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    final isActive = widget.hasActiveSession;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isActive ? colorPrimaryBlue : const Color(0xFFD1D7DB),
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: isActive ? () => _sendMessage() : null,
          child: const Center(
            child: Icon(Icons.send_rounded, color: colorWhite, size: 19),
          ),
        ),
      ),
    );
  }
}

/// Widget geser ke kanan untuk membalas pesan (WhatsApp-like Swipe-to-Reply)
class _SwipeToReplyWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;

  const _SwipeToReplyWrapper({required this.child, required this.onReply});

  @override
  State<_SwipeToReplyWrapper> createState() => _SwipeToReplyWrapperState();
}

class _SwipeToReplyWrapperState extends State<_SwipeToReplyWrapper> {
  double _dragOffset = 0.0;
  static const double _threshold = 45.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx > 0 || _dragOffset > 0) {
          setState(() {
            _dragOffset = (_dragOffset + details.delta.dx * 0.7).clamp(
              0.0,
              65.0,
            );
          });
        }
      },
      onHorizontalDragEnd: (details) {
        if (_dragOffset >= _threshold) {
          widget.onReply();
        }
        setState(() {
          _dragOffset = 0.0;
        });
      },
      onHorizontalDragCancel: () {
        setState(() {
          _dragOffset = 0.0;
        });
      },
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          if (_dragOffset > 5)
            Positioned(
              left: 4,
              child: Opacity(
                opacity: (_dragOffset / _threshold).clamp(0.0, 1.0),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A85FF).withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.reply_rounded,
                    color: Color(0xFF2A85FF),
                    size: 19,
                  ),
                ),
              ),
            ),
          AnimatedContainer(
            duration: _dragOffset == 0
                ? const Duration(milliseconds: 180)
                : Duration.zero,
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(_dragOffset, 0, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
