import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/booking_service.dart';
import '../../../core/services/chat_message_service.dart';
import '../../../core/services/child_service.dart';
import '../../../core/services/konsultasi_service.dart';
import '../../../core/services/resume_medis_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/user_service.dart';
import '../../../models/booking_consultation_model.dart';
import '../../../models/chat_message_model.dart';
import '../../../models/child_model.dart';
import '../../../models/consultation_model.dart';
import '../../../models/doctor_model.dart';
import '../../../models/resume_medis_model.dart';
import '../../../shared/widgets/doctor_live_avatar.dart';
import 'konfirmasi_selesai_dialog.dart';
import 'konsultasi_selesai_dialog.dart';
import '../../../shared/widgets/pedia_banner.dart';

/// Halaman Chat Konsultasi Dokter PediaGrow.
///
/// Fitur dan layout:
/// - Header dokter fixed berwarna biru (#2A85FF) meluas ke area status bar, tidak sempit.
/// - Data dokter (nama, spesialisasi, foto) diambil dinamis dari dokter yang dipilih pengguna.
/// - Disclaimer medis fixed (dapat ditutup dengan tombol X) dengan sudut atas melengkung.
/// - Dokumen 'Formulir Keluhan Pasien' otomatis terkirim menjadi chat paling awal di kanan.
/// - Mengetuk dokumen formulir menampilkan rincian data formulir anak & keluhan.
/// - Animasi tiga titik (...) bergerak halus saat dokter sedang mengetik balasan.
/// - Sistem dialog medis anak terstruktur & kontekstual: respons disesuaikan dengan pertanyaan
///   pengguna secara formal, edukatif, dan empatik (bukan template ngarang).
class ChatKonsultasiPage extends StatefulWidget {
  final String? namaDokter;
  final String? spesialisDokter;
  final String? fotoDokter;

  // Parameter data integrasi
  final DoctorModel? doctor;
  final ConsultationModel? consultation;
  final ChildModel? child;
  final double? weightKg;
  final double? heightCm;
  final String? complaint;
  final BookingConsultationModel? booking;

  // ID sesi konsultasi aktif di Firestore (opsional; jika null pakai mode offline)
  final String? sessionId;
  // ID pengguna yang login (Firebase Auth UID)
  final String? userId;
  final bool autoGreet;

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
    this.booking,
    this.sessionId,
    this.userId,
    this.autoGreet = false,
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
  static const Color colorBorder = Color(0xFFE9EDEF);
  static const Color colorEndRed = Color(0xFFE53E3E);
  static const Color colorOnlineGreen = Color(0xFF48BB78);

  // Controllers
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  // Animation controller untuk typing indicator 3 titik
  late AnimationController _typingAnimController;

  // State
  bool _isDoctorTyping = false;

  // Data Dokter Teresolusi
  late String _effectiveDoctorName;
  late String _effectiveDoctorSpecialist;
  late String? _effectiveDoctorPhoto;

  // Data Anak Teresolusi
  late String _effectiveChildName;
  late String _effectiveChildAge;
  late String _effectiveChildGender;

  // List pesan lokal (fallback offline)
  late List<Map<String, dynamic>> _messages;

  // Stream Firestore – aktif jika sessionId tersedia
  Stream<List<ChatMessageModel>>? _messageStream;

  // Listener status sesi (untuk deteksi pengakhiran dari pihak dokter)
  StreamSubscription<dynamic>? _sessionSub;
  // Flag: true jika kita sendiri yang mengakhiri (hindari reaksi ganda)
  bool _sessionEndedByUs = false;

  Timer? _sessionExpiryTimer;
  Timer? _initialGreetingTimer;
  Timer? _initialGreetingTypingTimer;
  Timer? _doctorResponseTimer;
  Timer? _doctorResponseTypingTimer;

  BookingConsultationModel? get _effectiveBooking =>
      widget.booking ?? BookingService().activeBookingNotifier.value;

  String get _effectiveSessionId =>
      widget.sessionId ??
      _effectiveBooking?.sessionId ??
      'session_${_effectiveBooking?.id ?? 'default'}';

  @override
  void initState() {
    super.initState();

    _resolveDoctorData();
    _resolveChildData();
    _initMessages();

    // Jika waktu booking konsultasi sudah habis saat masuk, tutup ruangan
    if (_effectiveBooking != null) {
      if (_effectiveBooking!.isExpired) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _handleAlreadyExpired();
        });
      } else {
        // Timer cek realtime apakah waktu konsultasi telah habis
        _sessionExpiryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted &&
              _effectiveBooking != null &&
              _effectiveBooking!.isExpired) {
            _handleTimeExpired();
          }
        });
      }
    }

    // Jika sessionId ada, gunakan stream Firestore (real-time)
    final effSession = _effectiveSessionId;
    if (effSession.isNotEmpty && !effSession.endsWith('default')) {
      _messageStream = ChatMessageService.instance.streamPesan(effSession);

      // Dengarkan perubahan status sesi agar tahu jika DOKTER mengakhiri
      _sessionSub = KonsultasiService.instance
          .streamSesi(effSession)
          .listen((sesi) {
        if (!mounted) return;
        if (_sessionEndedByUs) return; // kita yang mengakhiri, abaikan
        if (sesi != null && sesi.isSelesai) {
          // Dokter mengakhiri konsultasi → proses dari sisi pengguna
          _sessionEndedByUs = true;
          _sessionSub?.cancel();
          _selesaikanKonsultasiDanBuatRiwayat().then((_) {
            if (mounted) showKonsultasiSelesaiDialog(context);
          });
        }
      });
    } else if (widget.autoGreet) {
      // Mode offline: simulasi dokter menyapa jika belum ada sapaan
      final hasDoctorGreeting = _messages.any((m) => m['sender'] == 'doctor');
      if (!hasDoctorGreeting) {
        _scheduleInitialDoctorGreeting();
      }
    }

    // Animasi gelombang tiga titik (...) bergerak
    _typingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  void _setDoctorTyping(bool typing) {
    if (!mounted) return;
    setState(() {
      _isDoctorTyping = typing;
      if (typing) {
        if (!_typingAnimController.isAnimating) {
          _typingAnimController.repeat();
        }
      } else {
        if (_typingAnimController.isAnimating) {
          _typingAnimController.stop();
          _typingAnimController.reset();
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant ChatKonsultasiPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId ||
        oldWidget.booking?.sessionId != widget.booking?.sessionId) {
      final effSession = _effectiveSessionId;
      if (effSession.isNotEmpty && !effSession.endsWith('default')) {
        setState(() {
          _messageStream = ChatMessageService.instance.streamPesan(effSession);
        });
      }
    }
  }

  @override
  void dispose() {
    _sessionExpiryTimer?.cancel();
    _sessionSub?.cancel();
    _initialGreetingTimer?.cancel();
    _initialGreetingTypingTimer?.cancel();
    _doctorResponseTimer?.cancel();
    _doctorResponseTypingTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _typingAnimController.dispose();
    super.dispose();
  }

  void _resolveDoctorData() {
    _effectiveDoctorName =
        widget.doctor?.name ??
        widget.namaDokter ??
        widget.consultation?.doctor.name ??
        'dr. Ririn Esterina, Sp.A';

    _effectiveDoctorSpecialist =
        widget.doctor?.specialization ??
        widget.spesialisDokter ??
        widget.consultation?.doctor.specialization ??
        'Dokter Spesialis Anak';

    _effectiveDoctorPhoto =
        // Prioritas: avatarUrl (Firebase/lokal dari image_picker) > assetImagePath
        widget.doctor?.avatarUrl ??
        widget.doctor?.assetImagePath ??
        widget.fotoDokter ??
        widget.consultation?.doctor.avatarUrl ??
        widget.consultation?.doctor.assetImagePath ??
        'assets/images/doctor_ririn.png';
  }

  void _resolveChildData() {
    final active = widget.child ?? ChildService().activeChild;
    _effectiveChildName = active?.name ?? 'Ananda';
    _effectiveChildGender = active?.gender ?? 'Perempuan';
    _effectiveChildAge = active?.ageDescription ?? '1 tahun 3 bulan';
  }

  void _initMessages() {
    final cached = ChatMessageService.instance.getCachedMessages(
      _effectiveSessionId,
    );
    if (cached != null && cached.isNotEmpty) {
      _messages = List<Map<String, dynamic>>.from(cached);
      return;
    }

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')}';

    // Sesuai screenshot acuan: chat paling awal HANYA dokumen Formulir Keluhan Pasien
    _messages = [
      {
        'sender': 'user',
        'type': 'attachment',
        'title': 'Formulir Keluhan Pasien',
        'timestamp': timeStr,
        'isRead': true,
      },
    ];
    ChatMessageService.instance.saveCachedMessages(
      _effectiveSessionId,
      _messages,
    );
  }

  /// Dokter membaca formulir dan menyapa pasien secara formal & personal
  void _scheduleInitialDoctorGreeting() {
    _initialGreetingTimer?.cancel();
    _initialGreetingTypingTimer?.cancel();
    _initialGreetingTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      _setDoctorTyping(true);
      _scrollToBottom();

      _initialGreetingTypingTimer = Timer(const Duration(milliseconds: 1900), () {
        if (!mounted) return;

        final replyTime = DateTime.now();
        final replyTimeStr =
            '${replyTime.hour.toString().padLeft(2, '0')}.${replyTime.minute.toString().padLeft(2, '0')}';

        final greetingMessage = _generateOpeningGreeting();

        _setDoctorTyping(false);
        setState(() {
          _messages.add({
            'sender': 'doctor',
            'type': 'text',
            'message': greetingMessage,
            'timestamp': replyTimeStr,
            'isRead': true,
          });
        });
        ChatMessageService.instance.saveCachedMessages(
          _effectiveSessionId,
          _messages,
        );
        _scrollToBottom();
      });
    });
  }

  String _generateOpeningGreeting() {
    final hasComplaint =
        widget.complaint != null && widget.complaint!.trim().isNotEmpty;
    final childName = _effectiveChildName != 'Ananda'
        ? _effectiveChildName
        : 'si kecil';

    if (hasComplaint) {
      return 'Halo Mom’s, perkenalkan saya $_effectiveDoctorName. Formulir Keluhan Pasien untuk $childName sudah saya terima dan cermati dengan baik.\n\nTerkait keluhan: "${widget.complaint!.trim()}", boleh diceritakan sudah berapa hari keluhan ini berlangsung dan bagaimana kondisi keaktifan si kecil saat ini?';
    } else {
      return 'Halo Mom’s, perkenalkan saya $_effectiveDoctorName. Formulir Keluhan Pasien untuk $childName sudah saya terima.\n\nBagaimana kondisi $childName hari ini? Silakan ceritakan keluhan atau gejala yang sedang dirasakan si kecil ya Mom’s.';
    }
  }

  // ===========================================================================
  // LOGIKA PENGIRIMAN PESAN & ENGINE BALASAN DOKTER MEDIS FORMAL
  // ===========================================================================

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();

    // Jika ada sessionId → kirim ke Firestore (real-time, dokter menerima)
    final effSession = _effectiveSessionId;
    if (effSession.isNotEmpty && !effSession.endsWith('default')) {
      final uid = widget.userId ?? UserService().currentUser.id;
      ChatMessageService.instance.kirimTeks(
        sessionId: effSession,
        senderId: uid,
        senderRole: MessageSender.user,
        text: text,
      );
      // Tandai pesan dokter sebagai sudah dibaca
      ChatMessageService.instance.tandaiSudahDibaca(
        sessionId: effSession,
        readerRole: MessageSender.user,
      );
      return;
    }

    // Fallback offline (tanpa sessionId) — seperti semula
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
    });

    ChatMessageService.instance.saveCachedMessages(
      _effectiveSessionId,
      _messages,
    );

    _scrollToBottom();

    // Munculkan indikator dokter mengetik (...)
    _doctorResponseTimer?.cancel();
    _doctorResponseTypingTimer?.cancel();
    _doctorResponseTimer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _setDoctorTyping(true);
      _scrollToBottom();

      // Durasi mengetik yang realistis (1.6 - 2.2 detik)
      _doctorResponseTypingTimer = Timer(const Duration(milliseconds: 1800), () {
        if (!mounted) return;

        final replyTime = DateTime.now();
        final replyTimeStr =
            '${replyTime.hour.toString().padLeft(2, '0')}.${replyTime.minute.toString().padLeft(2, '0')}';

        final doctorAnswer = _generateDoctorResponse(text);

        _setDoctorTyping(false);
        setState(() {
          _messages.add({
            'sender': 'doctor',
            'type': 'text',
            'message': doctorAnswer,
            'timestamp': replyTimeStr,
            'isRead': true,
          });
        });
        ChatMessageService.instance.saveCachedMessages(
          _effectiveSessionId,
          _messages,
        );
        _scrollToBottom();
      });
    });
  }

  /// Engine Analisis Pertanyaan Medis Anak (Pediatric Clinical Response Engine)
  /// Menjawab secara ramah, komunikatif, empatik, dan memahami typo/bahasa santai
  String _generateDoctorResponse(String userMessage) {
    final raw = userMessage.trim();
    final msg = raw.toLowerCase();

    // 1. UCAPAN TERIMA KASIH & CLOSING (Menangani typos & singkatan: makasih, mksih, mksh, makasii, dll.)
    final isThanks =
        msg.contains('makasih') ||
        msg.contains('makasi') ||
        msg.contains('mksih') ||
        msg.contains('mksh') ||
        msg.contains('terima kasih') ||
        msg.contains('trimakasih') ||
        msg.contains('tengkyu') ||
        msg.contains('thanks') ||
        msg.contains('thx') ||
        msg.contains('tq') ||
        msg.contains('matur nuwun');

    if (isThanks) {
      return 'Sama-sama Mom’s! Senang sekali bisa membantu Mom’s dan mendampingi si kecil. '
          'Tetap pantau kondisinya ya. Semoga si kecil lekas pulih, sehat selalu, dan kembali ceria bermain. '
          'Kalau nanti ada keluhan lain atau ada hal yang perlu ditanyakan lagi, jangan ragu untuk berkonsultasi kembali ya Mom’s! 😊';
    }

    // 2. KONFIRMASI / RESPON SINGKAT (baik dok, siap dok, paham, oke dok)
    if (msg == 'baik dok' ||
        msg == 'siap dok' ||
        msg == 'paham dok' ||
        msg == 'oke dok' ||
        msg == 'ok dok' ||
        msg == 'sip dok' ||
        msg == 'iya dok' ||
        msg == 'ya dok') {
      return 'Baik Mom’s, tetap semangat ya dalam merawat si kecil. Jangan lupa pastikan kebutuhan cairan dan istirahatnya terpenuhi dengan baik. '
          'Bila ada perubahan kondisi sewaktu-waktu, segera kabari saya ya Mom’s.';
    }

    // 3. SALAM & SAPAAN (halo, pagi, siang, assalamualaikum)
    if (msg.startsWith('halo') ||
        msg.startsWith('hai') ||
        msg.contains('assalamu') ||
        msg.contains('selamat pagi') ||
        msg.contains('selamat siang') ||
        msg.contains('selamat sore') ||
        msg.contains('selamat malam')) {
      return 'Halo juga Mom’s! Selamat datang di sesi konsultasi kita. '
          'Bagaimana kondisi si kecil saat ini? Boleh diceritakan keluhan atau gejala apa yang sedang dialami si kecil hari ini?';
    }

    // 4. DEMAM / SUHU TINGGI / PANAS (Menangani: dmm, panas, suhu, menggigil, paracetamol, dll.)
    final isFever =
        msg.contains('demam') ||
        msg.contains('dmm') ||
        msg.contains('panas') ||
        msg.contains('suhu') ||
        msg.contains('sumeng') ||
        msg.contains('menggigil') ||
        msg.contains('paracetamol') ||
        msg.contains('tempra') ||
        msg.contains('sanmol') ||
        msg.contains('termometer') ||
        msg.contains('38') ||
        msg.contains('39');

    if (isFever) {
      return 'Wajar sekali kalau Mom’s merasa khawatir saat si kecil demam. Sebenarnya demam adalah reaksi alami dan tanda positif bahwa daya tahan tubuh si kecil sedang aktif melawan kuman atau virus.\n\n'
          'Saran perawatan yang bisa Mom’s lakukan langsung di rumah:\n'
          '• Berikan cairan (ASI, susu, atau air putih hangat) sesering mungkin untuk mencegah dehidrasi.\n'
          '• Kompres lipatan ketiak dan selangkangan dengan air hangat suam kuku (hindari kompres es atau alkohol ya Mom’s).\n'
          '• Kenakan pakaian katun tipis yang longgar dan menyerap keringat.\n'
          '• Jika suhu mencapai ≥38°C dan si kecil tampak gelisah/kurang nyaman, berikan paracetamol sesuai dosis berat badannya.\n\n'
          'Boleh saya tahu sudah berapa hari demamnya berlangsung dan apakah si kecil masih mau minum serta aktif bermain Mom’s?';
    }

    // 5. BATUK, PILEK, FLU, SESAK, GROK-GROK (Menangani: btk, plk, ingus, meler, grok, dll.)
    final isFlu =
        msg.contains('batuk') ||
        msg.contains('pilek') ||
        msg.contains('btk') ||
        msg.contains('plk') ||
        msg.contains('flu') ||
        msg.contains('ingus') ||
        msg.contains('meler') ||
        msg.contains('grok') ||
        msg.contains('tersumbat') ||
        msg.contains('sesak') ||
        msg.contains('bersin');

    if (isFlu) {
      return 'Keluhan batuk dan pilek pada anak memang sering kali bikin si kecil tidak nyaman dan rewel saat tidur ya Mom’s. Sebagian besar kasus disebabkan oleh infeksi virus ringan yang dapat membaik dengan sendirinya.\n\n'
          'Langkah pertolongan pertama di rumah:\n'
          '• Teteskan cairan saline/NaCl 0.9% steril ke rongga hidung si kecil untuk membantu mengencerkan lendir dan melegakan napas.\n'
          '• Perbanyak asupan cairan hangat dan ASI untuk menjaga tenggorokan tetap lembap.\n'
          '• Posisikan kepala si kecil sedikit lebih tinggi saat tidur menggunakan bantal tipis.\n'
          '• Sebaiknya hindari pemberian obat sirup batuk-pilek bebas tanpa resep langsung dokter ya Mom’s.\n\n'
          'Perhatikan juga tanda bahaya: bila napas si kecil terlihat sangat cepat atau ada tarikan di dada saat bernapas, segera bawa ke fasyankes terdekat ya Mom’s.';
    }

    // 6. DIARE, MENCRET, PUP CAIR (Menangani: mencret, bab cair, pup cair, lendir, dll.)
    final isDiarrhea =
        msg.contains('diare') ||
        msg.contains('mencret') ||
        msg.contains('bab cair') ||
        msg.contains('pup cair') ||
        msg.contains('pup mencret') ||
        msg.contains('pup terus') ||
        msg.contains('tinja') ||
        msg.contains('berak');

    if (isDiarrhea) {
      return 'Kunci utama penanganan diare pada anak adalah memastikan si kecil tidak kekurangan cairan (dehidrasi) ya Mom’s.\n\n'
          'Langkah yang perlu segera dilakukan:\n'
          '• Berikan larutan Oralit atau cairan rehidrasi setiap kali si kecil buang air besar cair (sekitar 50-100 ml per kali BAB).\n'
          '• Tetap teruskan pemberian ASI dan makanan dengan tekstur lembut yang mudah dicerna.\n'
          '• Berikan suplemen Zinc selama 10 hari berturut-turut untuk membantu memperbaiki sel dinding usus si kecil.\n\n'
          'Bagaimana frekuensi BAB-nya hari ini Mom’s? Apakah si kecil buang air kecilnya masih teratur (popok basah setiap 4-6 jam)?';
    }

    // 7. MUNTAH, GUMOH, MUAL (Menangani: muntah, gumoh, enek, mual, dll.)
    final isVomit =
        msg.contains('muntah') ||
        msg.contains('gumoh') ||
        msg.contains('mual') ||
        msg.contains('enek') ||
        msg.contains('muntah2');

    if (isVomit) {
      return 'Saat si kecil muntah, lambungnya sedang sensitif dan butuh istirahat sejenak Mom’s.\n\n'
          'Tips penanganan aman:\n'
          '• Istirahatkan lambung si kecil selama 30-60 menit setelah muntah (jangan langsung dipaksa minum banyak sekaligus).\n'
          '• Setelah itu, berikan cairan oralit atau ASI sedikit demi sedikit (1-2 sendok teh) setiap 10-15 menit.\n'
          '• Bila cairan tidak dimuntahkan kembali, barulah jumlahnya bisa ditingkatkan bertahap.\n\n'
          'Apakah muntahnya menyemprot atau disertai demam Mom’s? Tetap pantau agar si kecil tidak lemas ya.';
    }

    // 8. GTM, SUSAH MAKAN, NAFSU MAKAN (Menangani: gtm, gamau makan, ga mau makan, gak mau makan, dll.)
    final isGTM =
        msg.contains('gtm') ||
        msg.contains('susah makan') ||
        msg.contains('gamau') ||
        msg.contains('ga mau') ||
        msg.contains('gak mau') ||
        msg.contains('nafsu makan') ||
        msg.contains('pilih makan') ||
        msg.contains('ngemil terus') ||
        msg.contains('lepeh');

    if (isGTM) {
      return 'Fase GTM (Gerakan Tutup Mulut) memang sering kali menguras energi orang tua ya Mom’s. Biasanya hal ini dipicu oleh proses tumbuh gigi, rasa bosan pada variasi menu/tekstur, atau rasa kenyang karena susu/camilan sebelum jam makan.\n\n'
          'Strategi yang sangat dianjurkan:\n'
          '• Terapkan feeding rules: batasi waktu makan maksimal 30 menit. Jika si kecil menolak setelah 30 menit, sudahi dengan tenang tanpa memaksa.\n'
          '• Berikan jeda minimal 2 jam bebas susu/camilan sebelum jam makan utama agar rasa lapar alaminya muncul.\n'
          '• Variasikan tekstur atau warna makanan, dan ajak makan bersama anggota keluarga di meja makan.\n\n'
          'Apakah si kecil saat ini sedang tumbuh gigi atau gusi tampak bengkak kemerahan Mom’s?';
    }

    // 9. BERAT BADAN, KURUS, STUNTING, GIZI (Menangani: bb seret, berat badan, kurus, stunting, dll.)
    final isWeight =
        msg.contains('berat badan') ||
        msg.contains('bb') ||
        msg.contains('kurus') ||
        msg.contains('stunting') ||
        msg.contains('gizi') ||
        msg.contains('tumbuh kembang') ||
        msg.contains('timbangan');

    if (isWeight) {
      final weightDetail = widget.weightKg != null
          ? ' (berat saat ini ${widget.weightKg} kg)'
          : '';
      return 'Kenaikan berat badan si kecil$weightDetail memang perlu kita pantau konsistensinya di grafik KMS/WHO setiap bulan Mom’s.\n\n'
          'Tips praktis untuk mengoptimalkan kenaikan berat badan:\n'
          '• Tambahkan sumber lemak sehat berkalori tinggi ke dalam menu MPASI/makanan (seperti unsalted butter, minyak kelapa, santan matang, atau keju).\n'
          '• Utamakan protein hewani ganda di setiap porsi makan (kombinasi telur, hati ayam, daging cincang, atau ikan kembung) yang terbukti efektif mencegah stunting.\n'
          '• Batasi konsumsi air putih atau camilan manis berlebih yang membuat si kecil cepat kenyang palsu.\n\n'
          'Bulan ini apakah kenaikan berat badannya sudah sempat dicek di posyandu atau fasyankes Mom’s?';
    }

    // 10. RUAM KULIT, BINTIK MERAH, GATAL, ALERGI (Menangani: ruam, bintik, merah, gatal, alergi, popok, dll.)
    final isSkin =
        msg.contains('ruam') ||
        msg.contains('bintik') ||
        msg.contains('gatal') ||
        msg.contains('alergi') ||
        msg.contains('merah') ||
        msg.contains('bentol') ||
        msg.contains('popok') ||
        msg.contains('eksim') ||
        msg.contains('biang keringat');

    if (isSkin) {
      return 'Keluhan ruam atau bintik kemerahan pada kulit si kecil bisa timbul karena biang keringat, ruam popok, dermatitis kontak, atau reaksi alergi makanan/cuaca Mom’s.\n\n'
          'Perawatan kulit sensitif si kecil:\n'
          '• Mandikan dengan air suam kuku dan sabun bayi hipoalergenik tanpa SLS dan tanpa wewangian tajam.\n'
          '• Jangan digosok saat mengeringkan, cukup ditepuk-tepuk lembut dengan handuk katun.\n'
          '• Bila ruam ada di area popok, oleskan salep pelindung Zinc Oxide dan ganti popok tiap 3-4 jam atau segera setelah si kecil buang air.\n'
          '• Hindari penggunaan salep kortikosteroid sembarangan tanpa resep ya Mom’s.\n\n'
          'Apakah bintik merahnya terasa gatal atau si kecil tampak sering menggaruk area tersebut Mom’s?';
    }

    // 11. IMUNISASI & VAKSINASI
    final isVaccine =
        msg.contains('imunisasi') ||
        msg.contains('vaksin') ||
        msg.contains('dpt') ||
        msg.contains('campak') ||
        msg.contains('polio') ||
        msg.contains('bcg') ||
        msg.contains('jadwal vaksin');

    if (isVaccine) {
      return 'Jadwal imunisasi sangat krusial untuk membentengi si kecil dari berbagai penyakit berbahaya sesuai panduan resmi IDAI Mom’s.\n\n'
          'Bila ada imunisasi yang sempat terlewat, Mom’s tidak perlu mengulang dari awal, cukup lakukan imunisasi kejar (catch-up) sesegera mungkin di fasyankes terdekat. '
          'Reaksi pasca-imunisasi seperti sumeng ringan atau nyeri di bekas suntikan adalah hal yang wajar dan bisa diredakan dengan kompres hangat serta paracetamol bila si kecil rewel ya Mom’s.';
    }

    // 12. TIDUR, REWEL, MENANGIS, KEMBUNG
    final isSleepFuss =
        msg.contains('rewel') ||
        msg.contains('nangis') ||
        msg.contains('menangis') ||
        msg.contains('tidur') ||
        msg.contains('begadang') ||
        msg.contains('kembung') ||
        msg.contains('kolik');

    if (isSleepFuss) {
      return 'Kondisi si kecil yang rewel dan susah tidur biasanya menandakan adanya rasa tidak nyaman di tubuhnya, seperti perut kembung, kegerahan, atau sedang melewati fase lonjakan tumbuh kembang (growth spurt) Mom’s.\n\n'
          'Tips menenangkan si kecil:\n'
          '• Lakukan pijatan lembut pada perut searah jarum jam (pijat I-Love-U) dan gerakan kaki mengayuh sepeda untuk membantu mengeluarkan gas di perut.\n'
          '• Ciptakan suasana kamar yang tenang, redup, dan sejuk (suhu ideal 24-26°C).\n'
          '• Pastikan popoknya bersih dan si kecil sudah kenyang sebelum tidur ya Mom’s.';
    }

    // 13. FALLBACK DINAMIS & RESPONSIF (Merujuk langsung ke pertanyaan pengguna secara natural)
    return 'Terima kasih atas pertanyaannya Mom’s. Terkait "$raw", kami sangat memahami kekhawatiran Mom’s terhadap kesehatan si kecil.\n\n'
        'Secara umum, yang terpenting adalah mengamati keaktifan si kecil dan memastikan kebutuhan nutrisi serta cairannya tetap masuk. '
        'Boleh diceritakan lebih detail sejak kapan keluhan ini muncul, dan apakah ada gejala lain seperti demam, batuk, atau perubahan nafsu makan si kecil Mom’s?';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 90,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _onBackPressed() {
    _showStayInChatDialog();
  }

  /// Menampilkan dialog bahwa pengguna tidak dapat kembali ke halaman formulir
  /// dan harus tetap di ruang konsultasi sampai sesi diakhiri secara resmi.
  void _showStayInChatDialog() {
    FocusScope.of(context).unfocus();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1A2228) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                      : const Color(0xFFEBF5FF),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2A85FF),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sesi Konsultasi Berlangsung',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE9EDEF) : colorTextPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Anda tidak dapat kembali ke halaman sebelumnya selama sesi konsultasi berlangsung. Harap tetap di room konsultasi sampai percakapan diakhiri.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 13.5,
                  color: isDark ? const Color(0xFF8696A0) : colorTextSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _onAkhiriKonsultasiPressed();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorEndRed,
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF7F1D1D)
                              : const Color(0xFFFEB2B2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      child: Text(
                        'Akhiri Sesi',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorPrimaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      child: Text(
                        'Tetap di Chat',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onAkhiriKonsultasiPressed() {
    FocusScope.of(context).unfocus();
    showKonfirmasiSelesaiDialog(
      context,
      onConfirmed: () async {
        _sessionEndedByUs = true; // Kita yang mengakhiri → abaikan stream
        await _selesaikanKonsultasiDanBuatRiwayat();
        if (mounted) {
          showKonsultasiSelesaiDialog(context);
        }
      },
    );
  }

  /// Dipanggil saat timer mendeteksi waktu booking habis secara realtime
  void _handleTimeExpired() {
    _sessionExpiryTimer?.cancel();
    if (!mounted) return;
    final booking = _effectiveBooking;
    if (booking != null) {
      BookingService().updateBookingStatus(booking.id, 'Selesai');
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A2228) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Waktu Konsultasi Berakhir',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228),
          ),
        ),
        content: Text(
          'Waktu sesi konsultasi telah habis. Ruang chat ini ditutup secara otomatis.',
          style: TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B7AE8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Dipanggil segera saat masuk ke chat room namun booking sudah expired
  void _handleAlreadyExpired() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A2228) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Sesi Tidak Tersedia',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228),
            ),
          ),
          content: Text(
            'Waktu sesi konsultasi ini telah berakhir. Ruang chat tidak dapat dibuka lagi.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF2C363D)
                    : const Color(0xFF667781),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                if (mounted) Navigator.of(context).pop();
              },
              child: const Text('Kembali'),
            ),
          ],
        ),
      );
    });
  }

  /// Membuat dan menyimpan Resume Medis
  Future<void> _selesaikanKonsultasiDanBuatRiwayat() async {
    try {
      final now = DateTime.now();
      const monthNames = [
        '',
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
      final formattedDate = '${now.day} ${monthNames[now.month]} ${now.year}';
      final hourStr = now.hour.toString().padLeft(2, '0');
      final minStr = now.minute.toString().padLeft(2, '0');
      final formattedTime = '$hourStr.$minStr WIB';

      final effectiveChild = widget.child ?? ChildService().activeChild;
      final effectiveUserId =
          widget.userId ??
          effectiveChild?.ownerId ??
          UserService().currentUser.id;

      final complaintText = (widget.complaint?.trim().isNotEmpty == true)
          ? widget.complaint!.trim()
          : 'Konsultasi keluhan kesehatan dan pemantauan tumbuh kembang anak';

      final shortComplaint = complaintText.length > 60
          ? '${complaintText.substring(0, 60)}...'
          : complaintText;

      final resume = ResumeMedisModel(
        id: '',
        childId: effectiveChild?.id ?? '',
        userId: effectiveUserId,
        doctorId: widget.doctor?.id ?? '',
        doctorName: _effectiveDoctorName,
        doctorSpecialization: _effectiveDoctorSpecialist,
        doctorPhoto: _effectiveDoctorPhoto,
        childName: _effectiveChildName,
        childAgeAtConsultation: _effectiveChildAge,
        consultationDate: formattedDate,
        consultationTime: formattedTime,
        bbLahir: effectiveChild?.birthWeightKg ?? 0.0,
        bbSaatIni: widget.weightKg ?? effectiveChild?.weightKg ?? 0.0,
        tbLahir: effectiveChild?.birthHeightCm ?? 0.0,
        tbSaatIni: widget.heightCm ?? effectiveChild?.heightCm ?? 0.0,
        complaint: complaintText,
        complaintShort: shortComplaint,
        // Field di bawah ini hanya boleh diisi oleh dokter melalui BuatResumeMedisDokterPage.
        // Dibiarkan kosong/strip agar tidak ada isian palsu.
        doctorAssessment: '',
        summary: '',
        recommendations: const [],
        prescription: '-',
        status: 'Selesai',
        sessionId: widget.sessionId,
        createdAt: now,
      );

      await ResumeMedisService().saveOrUpdateResumeMedis(resume);

      // Tandai sesi sebagai selesai di Firestore (koleksi konsultasi_sessions)
      final effSession = _effectiveSessionId;
      if (effSession.isNotEmpty && !effSession.endsWith('default')) {
        await KonsultasiService.instance.akhiriSesi(effSession);
      }

      // Perbarui status booking jika ada
      final booking = _effectiveBooking;
      if (booking != null) {
        BookingService().updateBookingStatus(booking.id, 'Selesai');
      }
    } catch (e) {
      debugPrint(
        '[ChatKonsultasi] Error selesaikanKonsultasiDanBuatRiwayat: $e',
      );
    }
  }

  // ===========================================================================
  // MODAL RINCIAN FORMULIR KELUHAN PASIEN
  // ===========================================================================

  void _showFormulirDetailDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2228) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: isDark ? const Color(0xFF2C363D) : const Color(0xFFD1D7DB),
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
                      color: isDark
                          ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                          : colorSoftBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      color: isDark ? const Color(0xFF60A5FA) : colorPrimaryBlue,
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
                            color: isDark ? const Color(0xFFE9EDEF) : colorTextPrimary,
                          ),
                        ),
                        Text(
                          'Data yang dikirimkan sebelum konsultasi',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF8696A0) : colorTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF1A2228),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(
                height: 1,
                color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF),
              ),
              const SizedBox(height: 16),

              // Field 1: Nama & Data Anak
              _buildDetailItem(
                label: 'Nama Anak',
                value: '$_effectiveChildName ($_effectiveChildGender)',
                icon: Icons.child_care_rounded,
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              // Field 2: Usia
              _buildDetailItem(
                label: 'Usia Anak',
                value: _effectiveChildAge,
                icon: Icons.calendar_today_rounded,
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              // Field 3: Berat & Tinggi Badan
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      label: 'Berat Badan',
                      value: widget.weightKg != null
                          ? '${widget.weightKg} kg'
                          : '-',
                      icon: Icons.scale_rounded,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailItem(
                      label: 'Tinggi Badan',
                      value: widget.heightCm != null
                          ? '${widget.heightCm} cm'
                          : '-',
                      icon: Icons.straighten_rounded,
                      isDark: isDark,
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
                  color: isDark ? const Color(0xFF8696A0) : colorTextSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0B1014) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2C363D) : colorBorder,
                  ),
                ),
                child: Text(
                  widget.complaint != null &&
                          widget.complaint!.trim().isNotEmpty
                      ? widget.complaint!.trim()
                      : 'Tidak ada keluhan spesifik yang dicatat.',
                  style: GoogleFonts.lato(
                    fontSize: 13.5,
                    color: isDark ? const Color(0xFFE9EDEF) : colorTextPrimary,
                    height: 1.4,
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
    bool isDark = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1014) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : colorBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? const Color(0xFF60A5FA) : colorPrimaryBlue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF8696A0) : colorTextSecondary,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.lato(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFE9EDEF) : colorTextPrimary,
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

  // ===========================================================================
  // BUILD METHOD UTAMA
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showStayInChatDialog();
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1014) : colorWhite,
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            // 1. Header Dokter Fixed (Biru #2A85FF, meluas menutupi status bar)
            _buildHeader(),

            // 2. Disclaimer Medis Fixed
            _buildDisclaimer(isDark),

            // 3. Area Chat List (Scrollable)
            Expanded(child: _buildChatList(isDark)),

            // 4. Input Pesan Fixed di Bagian Bawah
            _buildInputArea(isDark),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. HEADER DOKTER (Biru #2A85FF, Meluas Menutupi Status Bar)
  // ===========================================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: colorPrimaryBlue,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Tombol back 12dp
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _onBackPressed,
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: Icon(
                        Icons.arrow_back,
                        color: colorWhite,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Avatar Dokter + Indikator Online Hijau
              _buildDoctorAvatarWithOnlineDot(),
              const SizedBox(width: 12),

              // Nama Dokter & Spesialisasi
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _effectiveDoctorName,
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
                      _effectiveDoctorSpecialist,
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

  Widget _buildDoctorAvatarWithOnlineDot() {
    const double avatarSize = 44;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Lingkaran Foto Avatar Dokter Real-Time dengan Border Putih Bersih
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: DoctorLiveAvatar(
            doctorId: widget.doctor?.id ?? widget.consultation?.doctor.id,
            doctorName: _effectiveDoctorName,
            fallbackPhoto: _effectiveDoctorPhoto,
            size: avatarSize,
            shape: BoxShape.circle,
            border: Border.all(color: colorWhite, width: 2.0),
          ),
        ),

        // Indikator Online Hijau di pojok kanan atas avatar
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
    );
  }

  Widget _buildDefaultDoctorIcon() {
    return const Center(
      child: Icon(Icons.person, size: 24, color: colorGreyDark),
    );
  }

  /// Menampilkan foto dokter dari berbagai sumber:
  /// - Firebase URL (http/https) → Image.network
  /// - File lokal dari image_picker (path absolut) → Image.file
  /// - Asset bawaan aplikasi → Image.asset
  /// - Tidak ada foto → ikon person default
  Widget _buildDoctorPhotoWidget(String? photoPath, double size) {
    if (photoPath == null || photoPath.isEmpty) {
      return _buildDefaultDoctorIcon();
    }
    // URL jaringan (Firebase Storage / http)
    if (photoPath.startsWith('http://') || photoPath.startsWith('https://')) {
      return Image.network(
        photoPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultDoctorIcon(),
      );
    }
    // File lokal dari image_picker (path absolut seperti /data/user/...)
    if (photoPath.startsWith('/') || photoPath.startsWith('file://')) {
      return Image.file(
        File(photoPath.replaceFirst('file://', '')),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultDoctorIcon(),
      );
    }
    // Asset bawaan aplikasi
    return Image.asset(
      photoPath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildDefaultDoctorIcon(),
    );
  }

  // ===========================================================================
  // 2. DISCLAIMER MEDIS (Soft Blue #EBF5FF, Tepi Datar Tidak Lengkung, Stay Tanpa Button X)
  // ===========================================================================

  // ===========================================================================
  // 2. DISCLAIMER MEDIS (Soft Blue #EBF5FF, Tepi Datar Tidak Lengkung, Stay Tanpa Button X)
  // ===========================================================================

  Widget _buildDisclaimer(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : colorSoftBlue,
        borderRadius: BorderRadius.zero,
        border: isDark ? const Border(bottom: BorderSide(color: Color(0xFF2C363D))) : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: isDark ? const Color(0xFF8696A0) : const Color(0xFF4A5568),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Chat ini bersifat konsultasi umum dan bukan pengganti pemeriksaan langsung.',
              style: GoogleFonts.lato(
                fontSize: 12,
                color: isDark ? const Color(0xFF8696A0) : const Color(0xFF4A5568),
                height: 1.35,
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

  // Helper konversi ChatMessageModel (Firestore) → Map lokal yang dipakai widget
  Map<String, dynamic> _firestoreToLocal(ChatMessageModel msg) {
    final t = msg.timestamp;
    final timeStr =
        '${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}';
    return {
      'sender': msg.senderRole == MessageSender.dokter ? 'doctor' : 'user',
      'type': msg.type == MessageType.formulir
          ? 'attachment'
          : msg.type == MessageType.image
          ? 'user_attachment'
          : 'text',
      'message': msg.text ?? '',
      // imageUrl diteruskan ke map — dipakai oleh _buildUserAttachmentBubble
      'imageUrl': msg.imageUrl,
      // filePath diisi hanya jika imageUrl adalah path lokal (bukan base64/URL)
      'filePath': (msg.imageUrl != null &&
              !msg.imageUrl!.startsWith('data:image/') &&
              !msg.imageUrl!.startsWith('http'))
          ? msg.imageUrl
          : null,
      'fileName': msg.imageUrl != null ? msg.imageUrl!.split('/').last : '',
      'title': 'Formulir Keluhan Pasien',
      'timestamp': timeStr,
      'isRead': msg.isRead,
    };
  }

  Widget _buildChatList(bool isDark) {
    // Mode real-time Firestore
    if (_messageStream != null) {
      return StreamBuilder<List<ChatMessageModel>>(
        stream: _messageStream,
        builder: (context, snap) {
          final firestoreMsgs = snap.data ?? [];
          // Scroll to bottom saat pesan baru datang
          if (firestoreMsgs.isNotEmpty) {
            _scrollToBottom();
          }
          final items = firestoreMsgs.map(_firestoreToLocal).toList();
          return _buildMessageListView(items, isDark);
        },
      );
    }

    // Mode offline / fallback
    return _buildMessageListView(_messages, isDark);
  }

  Widget _buildMessageListView(List<Map<String, dynamic>> items, bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      itemCount: items.length + (_isDoctorTyping ? 2 : 1),
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
                  color: isDark ? const Color(0xFF667781) : colorTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }

        final messageIndex = index - 1;
        if (messageIndex < items.length) {
          final item = items[messageIndex];
          final isUser = item['sender'] == 'user';
          final type = item['type'] ?? 'text';

          if (type == 'attachment') {
            return _buildAttachmentMessage(item, isDark);
          }

          if (type == 'user_attachment') {
            return _buildUserAttachmentBubble(item, isDark, isUserSender: isUser);
          }

          if (isUser) {
            return _buildUserBubble(item, isDark);
          } else {
            return _buildDoctorBubble(item, isDark);
          }
        }

        // Typing indicator dokter tiga titik (...) bergerak saat dokter berpikir
        if (_isDoctorTyping) {
          return _buildTypingIndicator(isDark);
        }

        return const SizedBox.shrink();
      },
    );
  }

  // Attachment "Formulir Keluhan Pasien" di sisi kanan
  Widget _buildAttachmentMessage(Map<String, dynamic> item, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _showFormulirDetailDialog,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 12, 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2228) : colorSoftBlue,
                borderRadius: BorderRadius.circular(16),
                border: isDark ? Border.all(color: const Color(0xFF2C363D)) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 22,
                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2D3748),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          item['title'] ?? 'Formulir Keluhan Pasien',
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFE9EDEF) : colorTextPrimary,
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
                        item['timestamp'] ?? '15.59',
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF8696A0) : colorTextSecondary,
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

  // Bubble Lampiran Gambar (Kanan jika user, Kiri jika dokter)
  Widget _buildUserAttachmentBubble(
    Map<String, dynamic> item,
    bool isDark, {
    bool isUserSender = true,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageUrl = item['imageUrl'] as String?;
    final filePath = item['filePath'] as String?;
    final fileName = item['fileName'] as String? ?? 'Lampiran Gambar';

    // Tentukan apakah konten adalah gambar
    final bool isBase64Image =
        imageUrl != null && imageUrl.startsWith('data:image/');
    final bool isNetworkImage = imageUrl != null &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));
    final bool isLocalImage = filePath != null &&
        (filePath.toLowerCase().endsWith('.jpg') ||
            filePath.toLowerCase().endsWith('.jpeg') ||
            filePath.toLowerCase().endsWith('.png') ||
            filePath.toLowerCase().endsWith('.webp')) &&
        File(filePath).existsSync();
    final bool hasImage = isBase64Image || isNetworkImage || isLocalImage;

    // Widget konten bubble gambar (dipakai untuk kedua sisi)
    Widget bubbleContent = Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: isUserSender
            ? (isDark
                ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
                : colorSoftBlue)
            : (isDark ? const Color(0xFF1A2228) : colorWhite),
        borderRadius: BorderRadius.circular(16),
        border: isUserSender
            ? (isDark
                ? Border.all(
                    color: const Color(0xFF1E40AF).withValues(alpha: 0.5))
                : null)
            : Border.all(
                color: isDark ? const Color(0xFF2C363D) : colorBorder,
                width: 1.0,
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            isUserSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isBase64Image
                  ? StorageService.buildImageWidget(
                      imageUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    )
                  : isNetworkImage
                  ? Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    )
                  : Image.file(
                      File(filePath!),
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasImage
                    ? Icons.image_outlined
                    : Icons.insert_drive_file_outlined,
                size: 20,
                color: isDark ? const Color(0xFF60A5FA) : colorPrimaryBlue,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  fileName.isNotEmpty ? fileName : 'Gambar',
                  style: GoogleFonts.lato(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark ? const Color(0xFFE9EDEF) : colorTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item['timestamp'] ?? '',
                style: GoogleFonts.lato(
                  fontSize: 11,
                  color: isDark
                      ? const Color(0xFF8696A0)
                      : colorTextSecondary,
                ),
              ),
              if (isUserSender) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.done_all,
                  size: 15,
                  color: colorPrimaryBlue,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    // --- Dokter mengirim gambar: tampil di KIRI dengan avatar ---
    if (!isUserSender) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor:
                  isDark ? const Color(0xFF0B1014) : const Color(0xFFE9EDEF),
              child: ClipOval(
                child: _buildDoctorPhotoWidget(_effectiveDoctorPhoto, 34),
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: screenWidth * 0.72),
              child: bubbleContent,
            ),
          ],
        ),
      );
    }

    // --- Pengguna mengirim gambar: tampil di KANAN ---
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: screenWidth * 0.76),
          child: bubbleContent,
        ),
      ),
    );
  }

  // Bubble Chat User (Kanan, Soft Blue) - Dynamic Width Sesuai Isi Chat
  Widget _buildUserBubble(Map<String, dynamic> item, bool isDark) {
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
                color: isDark
                    ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
                    : colorSoftBlue,
                borderRadius: BorderRadius.circular(16),
                border: isDark
                    ? Border.all(color: const Color(0xFF1E40AF).withValues(alpha: 0.5))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item['message'] ?? '',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: isDark ? const Color(0xFFE9EDEF) : colorTextPrimary,
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
                          color: isDark ? const Color(0xFF8696A0) : colorTextSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.done_all,
                        size: 14,
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

  // Bubble Chat Dokter (Kiri, Putih/Gelap, Border Halus, Avatar Dokter) - Dynamic Width
  Widget _buildDoctorBubble(Map<String, dynamic> item, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar dokter di sisi kiri bubble
          CircleAvatar(
            radius: 17,
            backgroundColor: isDark ? const Color(0xFF0B1014) : const Color(0xFFE9EDEF),
            child: ClipOval(
              child: _buildDoctorPhotoWidget(_effectiveDoctorPhoto, 34),
            ),
          ),
          const SizedBox(width: 8),

          // Bubble Dokter
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: screenWidth * 0.72),
            child: IntrinsicWidth(
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 7),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A2228) : colorWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2C363D) : colorBorder,
                    width: 1.0,
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item['message'] ?? '',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: isDark ? const Color(0xFFE9EDEF) : colorTextPrimary,
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
                            color: isDark ? const Color(0xFF8696A0) : colorTextSecondary,
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

  // Typing Indicator Dokter di Kiri dengan Animasi 3 Titik (...) Bergerak
  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: isDark ? const Color(0xFF0B1014) : const Color(0xFFE9EDEF),
            child: ClipOval(
              child: _buildDoctorPhotoWidget(_effectiveDoctorPhoto, 34),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2228) : colorWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF2C363D) : colorBorder,
              ),
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
                    // Bouncing wave offset up and down
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
  // 4. INPUT AREA (Fixed di Bagian Bawah)
  // ===========================================================================

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1014) : colorWhite,
        border: isDark ? const Border(top: BorderSide(color: Color(0xFF2C363D))) : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Tombol [+] Media / Lampiran di sisi paling kiri
            _buildAddMediaButton(isDark),
            const SizedBox(width: 8),

            // 2. TextField "Ketik pesan..."
            Expanded(child: _buildTextField(isDark)),
            const SizedBox(width: 8),

            // 3. Tombol "Akhiri Konsultasi" (Ikon Bookmark / Akhiri)
            _buildEndConsultationButton(isDark),
            const SizedBox(width: 8),

            // 4. Tombol Send (Lingkaran Biru #2A85FF)
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMediaButton(bool isDark) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF1A2228) : colorWhite,
        border: Border.all(color: colorPrimaryBlue, width: 1.8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: () => _showAttachmentPickerOptions(isDark),
          child: const Center(
            child: Icon(Icons.add, color: colorPrimaryBlue, size: 22),
          ),
        ),
      ),
    );
  }

  /// Menampilkan menu pemilihan sumber lampiran (Kamera / Galeri)
  void _showAttachmentPickerOptions(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A2228) : Colors.white,
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
                    color: isDark ? const Color(0xFF2C363D) : const Color(0xFFD1D7DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Kirim Foto',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0B1014)
                          : const Color(0xFFECF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Color(0xFF3985E7),
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Ambil Foto dari Kamera',
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickAttachment(ImageSource.camera);
                  },
                ),
                Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF2C363D) : const Color(0xFFE9EDEF),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0B1014)
                          : const Color(0xFFECF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: Color(0xFF3985E7),
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Pilih Foto dari Galeri',
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFE9EDEF) : const Color(0xFF0B1014),
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
        final effSession = _effectiveSessionId;
        if (effSession.isNotEmpty && !effSession.endsWith('default')) {
          final uid = widget.userId ?? UserService().currentUser.id;
          await ChatMessageService.instance.kirimGambar(
            sessionId: effSession,
            senderId: uid,
            senderRole: MessageSender.user,
            imageFile: File(file.path),
          );
          return;
        }

        final now = DateTime.now();
        final timeStr =
            '${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')}';

        setState(() {
          _messages.add({
            'sender': 'user',
            'type': 'user_attachment',
            'fileName': file.name,
            'filePath': file.path,
            'timestamp': timeStr,
            'isRead': true,
          });
        });

        _scrollToBottom();

        // Respon dokter terhadap lampiran yang dikirim pengguna
        Future.delayed(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          _setDoctorTyping(true);
          _scrollToBottom();

          Future.delayed(const Duration(milliseconds: 1800), () {
            if (!mounted) return;
            final replyTime = DateTime.now();
            final replyTimeStr =
                '${replyTime.hour.toString().padLeft(2, '0')}.${replyTime.minute.toString().padLeft(2, '0')}';

            _setDoctorTyping(false);
            setState(() {
              _messages.add({
                'sender': 'doctor',
                'type': 'text',
                'message':
                    'Terima kasih Mom’s sudah melampirkan berkas (${file.name}). Saya sudah mencermati lampiran tersebut. Boleh ceritakan lebih lanjut bagaimana gejala atau kondisi yang tampak pada lampiran ini Mom’s?',
                'timestamp': replyTimeStr,
                'isRead': true,
              });
            });
            _scrollToBottom();
          });
        });
      }
    } catch (e) {
      if (mounted) {
        PediaBanner.showError(context, message: 'Gagal memilih file: $e');
      }
    }
  }

  Widget _buildTextField(bool isDark) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2228) : colorSoftGrey,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF2C363D) : colorBorder,
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      child: TextField(
        controller: _textController,
        style: GoogleFonts.lato(
          fontSize: 14,
          color: isDark ? const Color(0xFFE9EDEF) : colorTextPrimary,
        ),
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _sendMessage(),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          hintText: 'Ketik pesan...',
          hintStyle: GoogleFonts.lato(
            fontSize: 13.5,
            color: isDark ? const Color(0xFF667781) : const Color(0xFFA0AEC0),
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildEndConsultationButton(bool isDark) {
    return Tooltip(
      message: 'Akhiri Konsultasi',
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFFECEC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFED7D7),
            width: 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _onAkhiriKonsultasiPressed,
            child: const Center(
              child: Icon(
                Icons.comments_disabled_rounded,
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
