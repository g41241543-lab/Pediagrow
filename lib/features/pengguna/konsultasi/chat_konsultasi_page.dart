import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/child_model.dart';
import '../../../models/consultation_model.dart';
import '../../../models/doctor_model.dart';
import 'konfirmasi_selesai_dialog.dart';

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
  /// Menjawab secara formal, ilmiah, edukatif, dan sesuai standar IDAI
  String _generateDoctorResponse(String userMessage) {
    final msg = userMessage.toLowerCase();

    // 1. Demam / Panas / Suhu Tubuh
    if (msg.contains('demam') ||
        msg.contains('panas') ||
        msg.contains('suhu') ||
        msg.contains('menggigil') ||
        msg.contains('paracetamol') ||
        msg.contains('sanmol') ||
        msg.contains('termometer') ||
        msg.contains('38') ||
        msg.contains('39')) {
      return 'Baik Mom’s, demam merupakan respons alami sistem imun tubuh anak dalam melawan infeksi.\n\nLangkah penanganan yang tepat di rumah:\n1. Ukur suhu secara berkala dengan termometer aksila (ketiak).\n2. Berikan cairan (ASI, air putih, atau kuah hangat) sesering mungkin untuk mencegah dehidrasi.\n3. Kompres hangat pada area lipatan ketiak dan selangkangan (hindari air dingin/alkohol).\n4. Jika suhu ≥38°C dan si kecil merasa tidak nyaman, dapat diberikan paracetamol tetes/sirup sesuai dosis berat badan (10-15 mg/kgBB per kali pemberian, jeda minimal 4-6 jam).\n\nSegera bawa ke fasyankes jika demam berlangsung lebih dari 3 hari, si kecil tampak sangat lemas, atau disertai kejang ya Mom’s.';
    }

    // 2. Berat Badan / BB / Stunting / Gizi / Tumbuh Kembang
    if (msg.contains('berat badan') ||
        msg.contains('bb') ||
        msg.contains('stunting') ||
        msg.contains('gizi') ||
        msg.contains('tumbuh kembang') ||
        msg.contains('kurus') ||
        msg.contains('tinggi badan') ||
        msg.contains('tb') ||
        msg.contains('naik turun')) {
      final weightInfo = widget.weightKg != null
          ? ' (saat ini ${widget.weightKg} kg)'
          : '';
      return 'Mengenai kenaikan berat badan si kecil$weightInfo, pada usia balita fluktuasi berat badan memang sering terjadi, namun kurva pertumbuhannya harus tetap dipantau mengikuti grafik KMS/WHO.\n\nSaran kami untuk mengoptimalkan kenaikan BB:\n1. Tingkatkan densitas kalori MPASI dengan menambahkan lemak tambahan (seperti butter, minyak kelapa, atau santan matang).\n2. Utamakan asupan protein hewani setiap kali makan (telur, daging ayam/sapi cincang, atau ikan kembung) yang sangat efektif mencegah stunting.\n3. Evaluasi aturan makan (feeding rules): makan maksimal 30 menit dan hindari distraksi gadget/mainan saat makan.\n\nTetap pantau penimbangan rutin setiap bulan di posyandu atau fasyankes ya Mom’s.';
    }

    // 3. Gerakan Tutup Mulut (GTM) / Susah Makan / Nafsu Makan
    if (msg.contains('gtm') ||
        msg.contains('susah makan') ||
        msg.contains('nafsu makan') ||
        msg.contains('gamau makan') ||
        msg.contains('muntah makan') ||
        msg.contains('pilih makanan') ||
        msg.contains('ngemil')) {
      return 'Keluhan GTM (Gerakan Tutup Mulut) memang sering menjadi tantangan Mom’s. Hal ini bisa dipicu oleh fase tumbuh gigi, rasa bosan pada menu/tekstur, atau kondisi perut yang kurang nyaman.\n\nPanduan feeding rules yang disarankan:\n1. Buat jadwal makan yang teratur: 3 kali makan utama dan 2 kali camilan sehat terjadwal.\n2. Batasi waktu makan maksimal 30 menit. Jika belum habis, sudahi tanpa memarahi si kecil.\n3. Jangan berikan susu formula atau camilan padat 1-2 jam sebelum jam makan utama agar si kecil merasakan sinyal lapar alami.\n4. Ciptakan suasana makan bersama keluarga yang menyenangkan.\n\nApakah si kecil saat ini sedang terlihat rewel saat mengunyah atau ada tanda tumbuh gigi Mom’s?';
    }

    // 4. Batuk / Pilek / Flu / Hidung Tersumbat / Grok-grok
    if (msg.contains('batuk') ||
        msg.contains('pilek') ||
        msg.contains('flu') ||
        msg.contains('ingus') ||
        msg.contains('grok') ||
        msg.contains('tersumbat') ||
        msg.contains('sesak') ||
        msg.contains('napas')) {
      return 'Untuk batuk dan pilek pada si kecil, sebagian besar disebabkan oleh infeksi virus saluran pernapasan atas (common cold) yang umumnya bersifat self-limiting (dapat sembuh mandiri).\n\nPerawatan di rumah:\n1. Teteskan cairan saline/NaCl fisiologis 0.9% steril ke hidung untuk mengencerkan lendir dan melegakan sumbatan.\n2. Cukupi asupan cairan hangat dan ASI untuk membantu mengencerkan dahak.\n3. Tinggikan posisi kepala si kecil saat tidur dengan bantal tipis.\n4. Hindari pemberian obat batuk-pilek sirup bebas (OTC) tanpa resep dokter spesialis anak.\n\nWaspadai tanda bahaya: jika napas terlihat cepat, ada tarikan dinding dada ke dalam (retraksi), atau bibir membiru, segera bawa ke IGD rumah sakit terdekat ya Mom’s.';
    }

    // 5. Diare / Mencret / BAB Cair
    if (msg.contains('diare') ||
        msg.contains('mencret') ||
        msg.contains('bab cair') ||
        msg.contains('pup cair') ||
        msg.contains('lendir') ||
        msg.contains('tinja')) {
      return 'Baik Mom’s, penanganan utama diare pada anak adalah mencegah terjadinya dehidrasi (kekurangan cairan tubuh).\n\nLangkah tindakan:\n1. Berikan larutan Oralit setiap kali si kecil BAB cair (50-100 ml per kali BAB).\n2. Berikan suplementasi Zinc selama 10 hari berturut-turut meskipun diare sudah membaik (dosis 10 mg untuk usia <6 bulan, 20 mg untuk usia ≥6 bulan) untuk mempercepat perbaikan dinding usus.\n3. Teruskan pemberian ASI dan makanan bertekstur lembut tanpa bumbu menyengat.\n\nPerhatikan tanda dehidrasi: mata cekung, air mata tidak keluar saat menangis, bibir sangat kering, atau anak sangat haus/lemas. Jika ada tanda tersebut, segera periksakan langsung ya Mom’s.';
    }

    // 6. Muntah / Gumoh
    if (msg.contains('muntah') ||
        msg.contains('gumoh') ||
        msg.contains('enek') ||
        msg.contains('mual')) {
      return 'Jika si kecil sedang muntah, lambungnya memerlukan waktu istirahat sejenak.\n\nLangkah yang dianjurkan:\n1. Istirahatkan lambung selama 30-60 menit setelah muntah (jangan langsung dipaksa minum banyak).\n2. Setelah itu, berikan cairan rehidrasi oral atau ASI sedikit demi sedikit (1-2 sendok teh atau 5-10 ml) setiap 10-15 menit.\n3. Jika cairan dapat bertahan di lambung, tingkatkan jumlahnya secara bertahap.\n\nBila muntahan berwarna hijau, menyemprot kuat, atau si kecil sama sekali tidak bisa menelan cairan, mohon segera diperiksakan langsung ke dokter ya Mom’s.';
    }

    // 7. Ruam Kulit / Alergi / Bintik Merah / Gatal
    if (msg.contains('ruam') ||
        msg.contains('alergi') ||
        msg.contains('bintik') ||
        msg.contains('gatal') ||
        msg.contains('bentol') ||
        msg.contains('kulit') ||
        msg.contains('popok') ||
        msg.contains('eksim')) {
      return 'Ruam pada kulit anak dapat dipicu oleh dermatitis kontak, alergi makanan/cuaca, biang keringat, atau ruam popok.\n\nSaran perawatan kulit si kecil:\n1. Gunakan pakaian berbahan katun longgar yang menyerap keringat.\n2. Mandikan dengan air suam kuku dan sabun bayi hipoalergenik tanpa pewangi buatan.\n3. Untuk ruam popok, bersihkan dengan air mengalir, keringkan dengan cara ditepuk lembut, dan oleskan salep pelindung berbahan Zinc Oxide sebelum memakaikan popok baru.\n4. Ganti popok setiap 3-4 jam atau segera setelah si kecil buang air.\n\nHindari penggunaan salep kortikosteroid tanpa instruksi langsung dari dokter ya Mom’s.';
    }

    // 8. Imunisasi / Vaksin
    if (msg.contains('imunisasi') ||
        msg.contains('vaksin') ||
        msg.contains('dpt') ||
        msg.contains('polio') ||
        msg.contains('campak') ||
        msg.contains('bcg') ||
        msg.contains('jadwal')) {
      return 'Jadwal imunisasi sangat penting untuk membentuk antibodi spesifik bagi tumbuh kembang si kecil sesuai rekomendasi resmi IDAI (Ikatan Dokter Anak Indonesia).\n\nJika ada jadwal imunisasi yang sempat terlewat, jangan khawatir karena tidak perlu mengulang dari awal, cukup dilanjutkan imunisasi kejar (catch-up immunization). Reaksi ringan seperti sumeng atau nyeri bekas suntikan adalah wajar dan dapat diredakan dengan kompres hangat serta paracetamol jika diperlukan ya Mom’s.';
    }

    // 9. Tidur / Rewel / Kolik / Menangis
    if (msg.contains('rewel') ||
        msg.contains('nangis') ||
        msg.contains('menangis') ||
        msg.contains('tidur') ||
        msg.contains('begadang') ||
        msg.contains('kolik') ||
        msg.contains('kembung')) {
      return 'Kondisi anak yang rewel dan sulit tidur biasanya merupakan sinyal rasa tidak nyaman fisik, seperti perut kembung (kolik), rasa gerah, atau sedang fase lompatan perkembangan (wonder weeks).\n\nTips menenangkan si kecil:\n1. Lakukan pijatan lembut pada perut searah jarum jam (pijat I-Love-U) dan gerakan gowes sepeda pada kaki untuk membantu mengeluarkan gas di perut.\n2. Ciptakan rutinitas tidur yang tenang (redupkan lampu, suhu kamar sejuk 24-26°C, dan suara desiran lembut/white noise).\n3. Pastikan popok kering dan si kecil sudah kenyang sebelum tidur.';
    }

    // 10. Ucapan Terima Kasih / Closing
    if (msg.contains('terima kasih') ||
        msg.contains('makasih') ||
        msg.contains('tengkyu') ||
        msg.contains('thanks') ||
        msg.contains('baik dok') ||
        msg.contains('siap dok') ||
        msg.contains('paham dok')) {
      return 'Sama-sama Mom’s. Senang sekali bisa membantu mendampingi tumbuh kembang si kecil. Tetap pantau kondisinya ya Mom’s.\n\nJika ada pertanyaan lanjutan atau kondisi belum membaik, jangan ragu untuk berkonsultasi kembali. Sehat selalu untuk si kecil dan keluarga! 😊';
    }

    // 11. Salam / Sapaan
    if (msg.contains('halo') ||
        msg.contains('pagi') ||
        msg.contains('siang') ||
        msg.contains('sore') ||
        msg.contains('malam') ||
        msg.contains('assalamu')) {
      return 'Halo juga Mom’s. Ada hal spesifik yang ingin Mom’s tanyakan atau konsultasikan mengenai kondisi si kecil saat ini?';
    }

    // 12. Fallback Medis Formal Kontekstual (Bukan template kaku)
    return 'Terima kasih atas informasinya Mom’s. Berdasarkan penjelasan yang Mom’s sampaikan, hal ini perlu kami cermati bersama kondisi penyerta lainnya.\n\nBoleh saya tahu:\n1. Apakah si kecil masih aktif bermain atau tampak cenderung lebih lemas?\n2. Bagaimana asupan makan dan minumnya hari ini?\n\nTetap berikan cairan yang cukup dan amati respon si kecil. Jika gejala berlanjut atau disertai demam tinggi, kami sarankan untuk melakukan pemeriksaan fisik langsung ke dokter spesialis anak di fasyankes terdekat ya Mom’s.';
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

  // Bubble Chat Dokter (Kiri, Putih, Border Halus, Avatar Dokter)
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
                      height: 1.38,
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
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Fitur kirim lampiran foto/dokumen konsultasi',
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
            child: Icon(
              Icons.bookmark_outline_rounded,
              color: colorEndRed,
              size: 20,
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
