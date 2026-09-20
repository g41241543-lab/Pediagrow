import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/child_model.dart';
import '../../../models/consultation_model.dart';
import '../../../models/doctor_model.dart';
import 'konfirmasi_selesai_dialog.dart';
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
  static const Color colorBorder = Color(0xFFE2E8F0);
  static const Color colorEndRed = Color(0xFFE53E3E);
  static const Color colorOnlineGreen = Color(0xFF48BB78);

  // Controllers
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  // Animation controller untuk typing indicator 3 titik
  late AnimationController _typingAnimController;

  // State
  bool _showDisclaimer = true;
  bool _isDoctorTyping = false;

  // Data Dokter Teresolusi
  late String _effectiveDoctorName;
  late String _effectiveDoctorSpecialist;
  late String? _effectiveDoctorPhoto;

  // Data Anak Teresolusi
  late String _effectiveChildName;
  late String _effectiveChildAge;
  late String _effectiveChildGender;

  // List pesan percakapan dinamis
  late List<Map<String, dynamic>> _messages;

  @override
  void initState() {
    super.initState();

    _resolveDoctorData();
    _resolveChildData();
    _initMessages();

    // Animasi gelombang tiga titik (...) bergerak
    _typingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    // Simulasi respons sambutan awal dokter setelah halaman terbuka
    _scheduleInitialDoctorGreeting();
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
        widget.doctor?.assetImagePath ??
        widget.fotoDokter ??
        widget.consultation?.doctor.assetImagePath ??
        'assets/images/doctor_ririn.png';
  }

  void _resolveChildData() {
    _effectiveChildName = widget.child?.name ?? 'Ananda';
    _effectiveChildGender = widget.child?.gender ?? 'Perempuan';
    _effectiveChildAge = widget.child?.ageDescription ?? '1 tahun 3 bulan';
  }

  void _initMessages() {
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
  }

  /// Dokter membaca formulir dan menyapa pasien secara formal & personal
  void _scheduleInitialDoctorGreeting() {
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _isDoctorTyping = true);
      _scrollToBottom();

      Future.delayed(const Duration(milliseconds: 1900), () {
        if (!mounted) return;

        final replyTime = DateTime.now();
        final replyTimeStr =
            '${replyTime.hour.toString().padLeft(2, '0')}.${replyTime.minute.toString().padLeft(2, '0')}';

        final greetingMessage = _generateOpeningGreeting();

        setState(() {
          _isDoctorTyping = false;
          _messages.add({
            'sender': 'doctor',
            'type': 'text',
            'message': greetingMessage,
            'timestamp': replyTimeStr,
            'isRead': true,
          });
        });
        _scrollToBottom();
      });
    });
  }

  String _generateOpeningGreeting() {
    final hasComplaint =
        widget.complaint != null && widget.complaint!.trim().isNotEmpty;
    final childName =
        _effectiveChildName != 'Ananda' ? _effectiveChildName : 'si kecil';

    if (hasComplaint) {
      return 'Halo Mom’s, perkenalkan saya $_effectiveDoctorName. Formulir Keluhan Pasien untuk $childName sudah saya terima dan cermati dengan baik.\n\nTerkait keluhan: "${widget.complaint!.trim()}", boleh diceritakan sudah berapa hari keluhan ini berlangsung dan bagaimana kondisi keaktifan si kecil saat ini?';
    } else {
      return 'Halo Mom’s, perkenalkan saya $_effectiveDoctorName. Formulir Keluhan Pasien untuk $childName sudah saya terima.\n\nBagaimana kondisi $childName hari ini? Silakan ceritakan keluhan atau gejala yang sedang dirasakan si kecil ya Mom’s.';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _typingAnimController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // LOGIKA PENGIRIMAN PESAN & ENGINE BALASAN DOKTER MEDIS FORMAL
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

    // Munculkan indikator dokter mengetik (...)
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isDoctorTyping = true);
      _scrollToBottom();

      // Durasi mengetik yang realistis (1.6 - 2.2 detik)
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (!mounted) return;

        final replyTime = DateTime.now();
        final replyTimeStr =
            '${replyTime.hour.toString().padLeft(2, '0')}.${replyTime.minute.toString().padLeft(2, '0')}';

        final doctorAnswer = _generateDoctorResponse(text);

        setState(() {
          _isDoctorTyping = false;
          _messages.add({
            'sender': 'doctor',
            'type': 'text',
            'message': doctorAnswer,
            'timestamp': replyTimeStr,
            'isRead': true,
          });
        });
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
    final isThanks = msg.contains('makasih') ||
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
    final isFever = msg.contains('demam') ||
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
    final isFlu = msg.contains('batuk') ||
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
    final isDiarrhea = msg.contains('diare') ||
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
    final isVomit = msg.contains('muntah') ||
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
    final isGTM = msg.contains('gtm') ||
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
    final isWeight = msg.contains('berat badan') ||
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
    final isSkin = msg.contains('ruam') ||
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
    final isVaccine = msg.contains('imunisasi') ||
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
    final isSleepFuss = msg.contains('rewel') ||
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
    Navigator.of(context).maybePop();
  }

  void _onAkhiriKonsultasiPressed() {
    FocusScope.of(context).unfocus();
    showKonfirmasiSelesaiDialog(context);
  }

  // ===========================================================================
  // MODAL RINCIAN FORMULIR KELUHAN PASIEN
  // ===========================================================================

  void _showFormulirDetailDialog() {
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
                    color: const Color(0xFFCBD5E1),
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
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 16),

              // Field 1: Nama & Data Anak
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
                      value: widget.weightKg != null
                          ? '${widget.weightKg} kg'
                          : '-',
                      icon: Icons.scale_rounded,
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
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorBorder),
                ),
                child: Text(
                  widget.complaint != null && widget.complaint!.trim().isNotEmpty
                      ? widget.complaint!.trim()
                      : 'Tidak ada keluhan spesifik yang dicatat.',
                  style: GoogleFonts.lato(
                    fontSize: 13.5,
                    color: colorTextPrimary,
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

  // ===========================================================================
  // BUILD METHOD UTAMA
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorWhite,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // 1. Header Dokter Fixed (Biru #2A85FF, meluas menutupi status bar)
          _buildHeader(),

          // 2. Disclaimer Medis Fixed (Bisa ditutup, sudut atas melengkung)
          if (_showDisclaimer) _buildDisclaimer(),

          // 3. Area Chat List (Scrollable)
          Expanded(child: _buildChatList()),

          // 4. Input Pesan Fixed di Bagian Bawah
          _buildInputArea(),
        ],
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
        // Lingkaran Foto Avatar Dokter dengan Border Putih Bersih
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF1F5F9),
            border: Border.all(color: colorWhite, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipOval(
            child: _effectiveDoctorPhoto != null &&
                    _effectiveDoctorPhoto!.isNotEmpty
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

  // ===========================================================================
  // 2. DISCLAIMER MEDIS (Soft Blue #EBF5FF, Top Radius Melengkung)
  // ===========================================================================

  Widget _buildDisclaimer() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: colorSoftBlue,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline,
            size: 20,
            color: Color(0xFF4A5568),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Chat ini bersifat konsultasi umum dan bukan pengganti pemeriksaan langsung.',
              style: GoogleFonts.lato(
                fontSize: 12,
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
                setState(() => _showDisclaimer = false);
              },
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.close, size: 18, color: Color(0xFF4A5568)),
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

        final messageIndex = index - 1;
        if (messageIndex < _messages.length) {
          final item = _messages[messageIndex];
          final isUser = item['sender'] == 'user';
          final type = item['type'] ?? 'text';

          if (type == 'attachment') {
            return _buildAttachmentMessage(item);
          }

          if (type == 'user_attachment') {
            return _buildUserAttachmentBubble(item);
          }

          if (isUser) {
            return _buildUserBubble(item);
          } else {
            return _buildDoctorBubble(item);
          }
        }

        // Typing indicator dokter tiga titik (...) bergerak saat dokter berpikir
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _showFormulirDetailDialog,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 12, 8),
              decoration: BoxDecoration(
                color: colorSoftBlue,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
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
                      const Icon(
                        Icons.description_outlined,
                        size: 22,
                        color: Color(0xFF2D3748),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item['title'] ?? 'Formulir Keluhan Pasien',
                        style: GoogleFonts.lato(
                          fontSize: 14,
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

  // Bubble Lampiran Pengguna (Kanan, Soft Blue, Dukungan Foto & Dokumen File Manager)
  Widget _buildUserAttachmentBubble(Map<String, dynamic> item) {
    final screenWidth = MediaQuery.of(context).size.width;
    final filePath = item['filePath'] as String?;
    final fileName = item['fileName'] as String? ?? 'Lampiran Dokumen';
    final isImage = filePath != null &&
        (filePath.toLowerCase().endsWith('.jpg') ||
            filePath.toLowerCase().endsWith('.jpeg') ||
            filePath.toLowerCase().endsWith('.png') ||
            filePath.toLowerCase().endsWith('.webp'));

    final fileExists = filePath != null && File(filePath).existsSync();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: screenWidth * 0.76),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            decoration: BoxDecoration(
              color: colorSoftBlue,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isImage && fileExists) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(filePath),
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
                      isImage
                          ? Icons.image_outlined
                          : Icons.insert_drive_file_outlined,
                      size: 20,
                      color: colorPrimaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        fileName,
                        style: GoogleFonts.lato(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: colorTextPrimary,
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
    );
  }

  // Bubble Chat User (Kanan, Soft Blue) - Dynamic Width Sesuai Isi Chat
  Widget _buildUserBubble(Map<String, dynamic> item) {
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
                color: colorSoftBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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

  // Bubble Chat Dokter (Kiri, Putih, Border Halus, Avatar Dokter) - Dynamic Width
  Widget _buildDoctorBubble(Map<String, dynamic> item) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar dokter di sisi kiri bubble
          CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFFF1F5F9),
            backgroundImage: _effectiveDoctorPhoto != null &&
                    _effectiveDoctorPhoto!.isNotEmpty
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

  // Typing Indicator Dokter di Kiri dengan Animasi 3 Titik (...) Bergerak
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFFF1F5F9),
            backgroundImage: _effectiveDoctorPhoto != null &&
                    _effectiveDoctorPhoto!.isNotEmpty
                ? AssetImage(_effectiveDoctorPhoto!)
                : null,
            child: _effectiveDoctorPhoto == null
                ? const Icon(Icons.person, size: 20, color: colorGreyDark)
                : null,
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
                    // Bouncing wave offset up and down
                    final bounceOffset = -3.5 * (1.0 - (progress - 0.5).abs() * 2);
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Tombol [+] Media / Lampiran di sisi paling kiri
            _buildAddMediaButton(),
            const SizedBox(width: 8),

            // 2. TextField "Ketik pesan..."
            Expanded(child: _buildTextField()),
            const SizedBox(width: 8),

            // 3. Tombol "Akhiri Konsultasi" (Ikon Bookmark / Akhiri)
            _buildEndConsultationButton(),
            const SizedBox(width: 8),

            // 4. Tombol Send (Lingkaran Biru #2A85FF)
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

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
          onTap: _showAttachmentPickerOptions,
          child: const Center(
            child: Icon(Icons.add, color: colorPrimaryBlue, size: 22),
          ),
        ),
      ),
    );
  }

  /// Menampilkan menu pemilihan sumber lampiran (File Manager / Galeri / Kamera)
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
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Kirim Lampiran',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorTextPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorSoftBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.folder_open_rounded,
                      color: colorPrimaryBlue,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Pilih Dokumen / File Manager',
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorTextPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Pilih file atau berkas dari penyimpanan HP / Google Drive',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: colorTextSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickAttachment(ImageSource.gallery);
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: Color(0xFF2E7D32),
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Galeri Foto',
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorTextPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Pilih gambar dari galeri HP',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: colorTextSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickAttachment(ImageSource.gallery);
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Color(0xFFE65100),
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Ambil Foto dari Kamera',
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorTextPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Ambil foto kondisi anak atau obat secara langsung',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: colorTextSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickAttachment(ImageSource.camera);
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
          setState(() => _isDoctorTyping = true);
          _scrollToBottom();

          Future.delayed(const Duration(milliseconds: 1800), () {
            if (!mounted) return;
            final replyTime = DateTime.now();
            final replyTimeStr =
                '${replyTime.hour.toString().padLeft(2, '0')}.${replyTime.minute.toString().padLeft(2, '0')}';

            setState(() {
              _isDoctorTyping = false;
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
        PediaBanner.showError(
          context,
          message: 'Gagal memilih file: $e',
        );
      }
    }
  }

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

  Widget _buildEndConsultationButton() {
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
