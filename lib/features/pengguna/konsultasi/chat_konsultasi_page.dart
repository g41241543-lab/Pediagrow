import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/child_model.dart';
import '../../../models/consultation_model.dart';
import '../../../models/doctor_model.dart';
import 'konfirmasi_selesai_dialog.dart';

/// Halaman Chat Konsultasi Dokter PediaGrow.
///
/// Mengikuti desain acuan secara presisi:
/// - Header dokter fixed (biru #2A85FF, 56dp, tombol back 12dp dari kiri, 12dp ke avatar)
/// - Disclaimer medis fixed (bisa ditutup dengan tombol silang)
/// - Area chat scrollable (bubble user di kanan soft blue, bubble dokter di kiri putih)
/// - Attachment formulir keluhan pasien di awal percakapan
/// - Input chat fixed di bawah dengan tombol [+], TextField, [Akhiri Konsultasi], dan [Send]
/// - Simulasi typing indicator dokter dan auto-scroll
/// - Aman dari overflow keyboard Android (resizeToAvoidBottomInset: true)
class ChatKonsultasiPage extends StatefulWidget {
  final String? namaDokter;
  final String? spesialisDokter;
  final String? fotoDokter;

  // Parameter data tambahan untuk integrasi dari halaman sebelumnya
  final DoctorModel? doctor;
  final ConsultationModel? consultation;
  final ChildModel? child;
  final double? weightKg;
  final double? heightCm;
  final String? complaint;

  const ChatKonsultasiPage({
    super.key,
    this.namaDokter,
    this.spesialisDokter,
    this.fotoDokter,
    this.doctor,
    this.consultation,
    this.child,
    this.weightKg,
    this.heightCm,
    this.complaint,
  });

  @override
  State<ChatKonsultasiPage> createState() => _ChatKonsultasiPageState();
}

class _ChatKonsultasiPageState extends State<ChatKonsultasiPage>
    with TickerProviderStateMixin {
  // Design Tokens Resmi PediaGrow & Acuan Visual
  static const Color colorPrimaryBlue = Color(0xFF2A85FF);
  static const Color colorWhite = Color(0xFFFFFFFF);
  static const Color colorSoftGrey = Color(0xFFF8FAFC);
  static const Color colorSoftBlue = Color(0xFFEBF5FF);
  static const Color colorTextPrimary = Color(0xFF1A202C);
  static const Color colorTextSecondary = Color(0xFF718096);
  static const Color colorGreyDark = Color(0xFF7F7F7F);
  static const Color colorGreyLight = Color(0xFFC5C5C5);
  static const Color colorBorder = Color(0xFFE2E8F0);
  static const Color colorEndRed = Color(0xFFE53E3E);
  static const Color colorOnlineGreen = Color(0xFF48BB78);

  // Controllers
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Animation controller untuk typing indicator
  late AnimationController _typingAnimController;

  // State
  bool _showDisclaimer = true;
  bool _isDoctorTyping = false;

  // Data Dokter Teresolusi
  late String _effectiveDoctorName;
  late String _effectiveDoctorSpecialist;
  late String? _effectiveDoctorPhoto;

  // List pesan simulasi awal sesuai desain
  late List<Map<String, dynamic>> _messages;

  @override
  void initState() {
    super.initState();

    _resolveDoctorData();
    _initMessages();

    _typingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  void _resolveDoctorData() {
    _effectiveDoctorName =
        widget.namaDokter ??
        widget.doctor?.name ??
        widget.consultation?.doctor.name ??
        'dr. Ririn Esterina, Sp.A';

    _effectiveDoctorSpecialist =
        widget.spesialisDokter ??
        widget.doctor?.specialization ??
        widget.consultation?.doctor.specialization ??
        'Dokter Spesialis Anak';

    _effectiveDoctorPhoto =
        widget.fotoDokter ??
        widget.doctor?.assetImagePath ??
        widget.consultation?.doctor.assetImagePath ??
        'assets/images/doctor_ririn.png';
  }

  void _initMessages() {
    // Menyiapkan pesan awal sesuai desain screenshot
    _messages = [
      // 1. Attachment Formulir Keluhan Pasien
      {
        'sender': 'user',
        'type': 'attachment',
        'title': 'Formulir Keluhan Pasien',
        'timestamp': '15.59',
        'isRead': true,
      },
      // 2. Pesan User Pertama
      {
        'sender': 'user',
        'type': 'text',
        'message': 'Dok, anak saya umur 18 bulan, BB-nya naik turun terus. Nafsu makannya juga kadang kurang. Apakah ini berpengaruh ke pertumbuhannya?',
        'timestamp': '16.00',
        'isRead': true,
      },
      // 3. Balasan Dokter Pertama
      {
        'sender': 'doctor',
        'type': 'text',
        'message': 'Halo Mom’s\nTerima kasih sudah menghubungi. Naik turun BB pada anak bisa dipengaruhi oleh pola makan, aktivitas, dan kondisi kesehatan. Boleh saya tahu tinggi dan berat badan terakhir si kecil?',
        'timestamp': '16.02',
        'isRead': true,
      },
      // 4. Jawaban User Kedua
      {
        'sender': 'user',
        'type': 'text',
        'message': widget.weightKg != null && widget.heightCm != null
            ? 'Terakhir ${widget.weightKg} kg dan tinggi ${widget.heightCm} cm dok. Diperiksa 2 minggu yang lalu.'
            : 'Terakhir 10 kg dan tinggi 80 cm dok. Diperiksa 2 minggu yang lalu.',
        'timestamp': '16.05',
        'isRead': true,
      },
      // 5. Penjelasan Dokter Kedua
      {
        'sender': 'doctor',
        'type': 'text',
        'message': 'Baik Mom’s, berdasarkan usia 18 bulan,  BB 10kg dan TB 80cm masih dalam batas normal, namun tetap perlu dipantau ya.\n\nPastikan asupan gizi seimbang dan stimulasi tumbuh kembangnya dilakukan rutin.',
        'timestamp': '16.07',
        'isRead': true,
      },
      // 6. Pesan User Ketiga
      {
        'sender': 'user',
        'type': 'text',
        'message': 'Terima kasih dok penjelasannya',
        'timestamp': '16.08',
        'isRead': true,
      },
    ];
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _typingAnimController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // LOGIKA PENGIRIMAN PESAN & SIMULASI BALASAN DOKTER
  // ===========================================================================

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _messages.add({
        'sender': 'user',
        'type': 'text',
        'message': text,
        'timestamp': timeStr,
        'isRead': true,
      });
      _textController.clear();
    });

    _scrollToBottom();

    // Tampilkan typing indicator dokter setelah 800ms
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _isDoctorTyping = true;
      });
      _scrollToBottom();

      // Hilangkan typing indicator dan tambahkan balasan dokter setelah 2000ms
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (!mounted) return;

        final replyTime = DateTime.now();
        final replyTimeStr =
            '${replyTime.hour.toString().padLeft(2, '0')}.${replyTime.minute.toString().padLeft(2, '0')}';

        setState(() {
          _isDoctorTyping = false;
          _messages.add({
            'sender': 'doctor',
            'type': 'text',
            'message': 'Sama-sama Mom’s. Jika ada keluhan lanjutan atau si kecil demam, segera konsultasikan kembali ya. Sehat selalu untuk si kecil!',
            'timestamp': replyTimeStr,
            'isRead': true,
          });
        });
        _scrollToBottom();
      });
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _onBackPressed() {
    Navigator.of(context).maybePop();
  }

  void _onAkhiriKonsultasiPressed() {
    // Tutup keyboard terlebih dahulu
    FocusScope.of(context).unfocus();

    // Tampilkan Dialog Konfirmasi dari file konfirmasi_selesai_dialog.dart
    showKonfirmasiSelesaiDialog(context);
  }

  // ===========================================================================
  // BUILD METHOD UTAMA
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorWhite,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Dokter Fixed (Tinggi 56dp, Biru #2A85FF)
            _buildHeader(),

            // 2. Disclaimer Medis Fixed (Bisa ditutup)
            if (_showDisclaimer) _buildDisclaimer(),

            // 3. Area Chat List (Satu-satunya area yang scroll)
            Expanded(child: _buildChatList()),

            // 4. Input Pesan Fixed di Bagian Bawah
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. HEADER DOKTER (Fixed 56dp, #2A85FF)
  // ===========================================================================

  Widget _buildHeader() {
    return Container(
      height: 56,
      width: double.infinity,
      color: colorPrimaryBlue,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tombol back 12dp dari pinggir kiri layar
          const SizedBox(width: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _onBackPressed,
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: Icon(Icons.arrow_back, color: colorWhite, size: 24),
                ),
              ),
            ),
          ),
          // Jarak 12dp antara tombol back dengan identitas dokter
          const SizedBox(width: 12),

          // Avatar Dokter + Indikator Online Hijau
          _buildDoctorAvatarWithOnlineDot(),
          const SizedBox(width: 12),

          // Nama Dokter & Spesialisasi
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _effectiveDoctorName,
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorWhite,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _effectiveDoctorSpecialist,
                  style: GoogleFonts.lato(
                    fontSize: 12.5,
                    color: const Color(0xFFDCE8FD),
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildDoctorAvatarWithOnlineDot() {
    const double avatarSize = 40;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Lingkaran Foto Avatar Dokter
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF1F5F9),
            border: Border.all(color: colorWhite.withOpacity(0.4), width: 1.2),
          ),
          child: ClipOval(
            child: _effectiveDoctorPhoto != null
                ? Image.asset(
                    _effectiveDoctorPhoto!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildDefaultDoctorIcon(),
                  )
                : _buildDefaultDoctorIcon(),
          ),
        ),

        // Indikator Online Hijau di pojok kanan atas avatar
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: colorOnlineGreen,
              shape: BoxShape.circle,
              border: Border.all(color: colorWhite, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultDoctorIcon() {
    return const Center(
      child: Icon(Icons.person, size: 24, color: colorGreyDark),
    );
  }

  // ===========================================================================
  // 2. DISCLAIMER MEDIS (Fixed, Soft Blue #EBF5FF, Dismissible)
  // ===========================================================================

  Widget _buildDisclaimer() {
    return Container(
      width: double.infinity,
      color: colorSoftBlue,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 20, color: colorTextSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Chat ini bersifat konsultasi umum dan bukan pengganti pemeriksaan langsung.',
              style: GoogleFonts.lato(
                fontSize: 12.5,
                color: const Color(0xFF4A5568),
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  _showDisclaimer = false;
                });
              },
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.close, size: 19, color: colorTextSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. AREA CHAT LIST (Scrollable)
  // ===========================================================================

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      itemCount: _messages.length + (_isDoctorTyping ? 2 : 1),
      itemBuilder: (context, index) {
        // Item index 0: Badge Tanggal "Hari ini"
        if (index == 0) {
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

        // Pesan-pesan chat
        final messageIndex = index - 1;
        if (messageIndex < _messages.length) {
          final item = _messages[messageIndex];
          final isUser = item['sender'] == 'user';
          final type = item['type'] ?? 'text';

          if (type == 'attachment') {
            return _buildAttachmentMessage(item);
          }

          if (isUser) {
            return _buildUserBubble(item);
          } else {
            return _buildDoctorBubble(item);
          }
        }

        // Typing indicator dokter di bagian paling bawah jika aktif
        if (_isDoctorTyping) {
          return _buildTypingIndicator();
        }

        return const SizedBox.shrink();
      },
    );
  }

  // Attachment "Formulir Keluhan Pasien" di sisi kanan
  Widget _buildAttachmentMessage(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 8),
          decoration: BoxDecoration(
            color: colorSoftBlue,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 20,
                    color: Color(0xFF2D3748),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item['title'] ?? 'Formulir Keluhan Pasien',
                    style: GoogleFonts.lato(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: colorTextPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item['timestamp'] ?? '15.59',
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: colorTextSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all, size: 15, color: colorPrimaryBlue),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Bubble Chat User (Kanan, Soft Blue)
  Widget _buildUserBubble(Map<String, dynamic> item) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: screenWidth * 0.74),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            decoration: BoxDecoration(
              color: colorSoftBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item['message'] ?? '',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: colorTextPrimary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item['timestamp'] ?? '',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Bubble Chat Dokter (Kiri, Putih, Border Halus, Avatar di Sisi Kiri)
  Widget _buildDoctorBubble(Map<String, dynamic> item) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar kecil dokter di sisi kiri bubble
          CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFFF1F5F9),
            backgroundImage: _effectiveDoctorPhoto != null
                ? AssetImage(_effectiveDoctorPhoto!)
                : null,
            child: _effectiveDoctorPhoto == null
                ? const Icon(Icons.person, size: 20, color: colorGreyDark)
                : null,
          ),
          const SizedBox(width: 8),

          // Bubble Putih Dokter
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: screenWidth * 0.72),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
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
                  Text(
                    item['message'] ?? '',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: colorTextPrimary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      item['timestamp'] ?? '',
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        color: colorTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Typing Indicator Dokter di Kiri
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFFF1F5F9),
            backgroundImage: _effectiveDoctorPhoto != null
                ? AssetImage(_effectiveDoctorPhoto!)
                : null,
            child: _effectiveDoctorPhoto == null
                ? const Icon(Icons.person, size: 20, color: colorGreyDark)
                : null,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorBorder),
            ),
            child: AnimatedBuilder(
              animation: _typingAnimController,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (dotIndex) {
                    final progress =
                        (_typingAnimController.value + (dotIndex * 0.25)) % 1.0;
                    final scale =
                        0.6 + (0.5 * (1.0 - (progress - 0.5).abs() * 2));

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: Transform.scale(
                        scale: scale.clamp(0.6, 1.1),
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: colorPrimaryBlue,
                            shape: BoxShape.circle,
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
  // 4. INPUT AREA (Fixed di Bagian Bawah, Responsif Keyboard)
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Tombol [+] Media / Lampiran di sisi paling kiri
          _buildAddMediaButton(),
          const SizedBox(width: 8),

          // 2. TextField "Ketik pesan..."
          Expanded(child: _buildTextField()),
          const SizedBox(width: 8),

          // 3. Tombol "Akhiri Konsultasi" (Merah #E53E3E)
          _buildEndConsultationButton(),
          const SizedBox(width: 8),

          // 4. Tombol Send (Lingkaran Biru #2A85FF)
          _buildSendButton(),
        ],
      ),
    );
  }

  // Tombol [+] Biru di sisi kiri
  Widget _buildAddMediaButton() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorWhite,
        border: Border.all(color: colorPrimaryBlue, width: 1.8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Fitur kirim lampiran foto/dokumen',
                  style: GoogleFonts.lato(),
                ),
                duration: const Duration(seconds: 1),
                backgroundColor: colorPrimaryBlue,
              ),
            );
          },
          child: const Center(
            child: Icon(Icons.add, color: colorPrimaryBlue, size: 22),
          ),
        ),
      ),
    );
  }

  // Field Input Teks
  Widget _buildTextField() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: colorSoftGrey,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorBorder, width: 1.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      child: TextField(
        controller: _textController,
        style: GoogleFonts.lato(fontSize: 14, color: colorTextPrimary),
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _sendMessage(),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          hintText: 'Ketik pesan...',
          hintStyle: GoogleFonts.lato(
            fontSize: 13.5,
            color: const Color(0xFFA0AEC0),
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // Tombol "Akhiri Konsultasi" (Warna #E53E3E, Memanggil KonfirmasiSelesaiDialog)
  Widget _buildEndConsultationButton() {
    return Container(
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
            child: Icon(Icons.call_end_rounded, color: colorEndRed, size: 20),
          ),
        ),
      ),
    );
  }

  // Tombol Send (Lingkaran Biru #2A85FF)
  Widget _buildSendButton() {
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        color: colorPrimaryBlue,
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: _sendMessage,
          child: const Center(
            child: Icon(Icons.send_rounded, color: colorWhite, size: 19),
          ),
        ),
      ),
    );
  }
}
