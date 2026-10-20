import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/chat_message_model.dart';
import 'storage_service.dart';

/// Service untuk mengelola pesan real-time dalam sesi konsultasi.
///
/// Sub-koleksi Firestore: `konsultasi_sessions/{sessionId}/messages`
///
/// Gunakan service ini untuk:
/// - Mengirim pesan teks dari pengguna atau dokter
/// - Mengunggah dan mengirim gambar
/// - Mengirim formulir keluhan (type: formulir)
/// - Mendengarkan (stream) pesan secara real-time
class ChatMessageService {
  ChatMessageService._();
  static final ChatMessageService instance = ChatMessageService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _messages(String sessionId) {
    return _db
        .collection('konsultasi_sessions')
        .doc(sessionId)
        .collection('messages');
  }

  // ─── STREAM PESAN REAL-TIME ─────────────────────────────────────────────────

  /// Mendengarkan semua pesan dalam sesi secara real-time.
  /// Pesan diurutkan dari yang terlama ke terbaru.
  Stream<List<ChatMessageModel>> streamPesan(String sessionId) {
    return _messages(sessionId)
        .snapshots()
        .map(
          (snap) {
            final list = snap.docs
                .map(
                  (d) => ChatMessageModel.fromDoc(
                    d as DocumentSnapshot<Map<String, dynamic>>,
                  ),
                )
                .toList();
            list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            return list;
          },
        );
  }

  // ─── KIRIM PESAN TEKS ───────────────────────────────────────────────────────

  /// Mengirim pesan teks biasa.
  ///
  /// [senderId] : UID Firebase pengirim (userId atau staffId).
  /// [senderRole] : Peran pengirim (user / dokter).
  Future<void> kirimTeks({
    required String sessionId,
    required String senderId,
    required MessageSender senderRole,
    required String text,
  }) async {
    final ref = _messages(sessionId).doc();
    await ref.set(
      ChatMessageModel(
        id: ref.id,
        senderId: senderId,
        senderRole: senderRole,
        text: text,
        type: MessageType.text,
        timestamp: DateTime.now(),
        isRead: false,
      ).toMap(),
    );
  }

  // ─── KIRIM FORMULIR KELUHAN ─────────────────────────────────────────────────

  /// Mengirim pesan khusus bertipe 'formulir' (dokumen keluhan dari pengguna).
  /// Biasanya dipanggil sekali saat sesi pertama kali dibuat.
  Future<void> kirimFormulir({
    required String sessionId,
    required String senderId,
    required String keluhanText,
  }) async {
    final ref = _messages(sessionId).doc();
    await ref.set(
      ChatMessageModel(
        id: ref.id,
        senderId: senderId,
        senderRole: MessageSender.user,
        text: keluhanText,
        type: MessageType.formulir,
        timestamp: DateTime.now(),
        isRead: false,
      ).toMap(),
    );
  }

  // ─── KIRIM GAMBAR ───────────────────────────────────────────────────────────

  /// Mengirim pesan bertipe 'image' dengan gambar yang dipilih.
  ///
  /// [imageFile] : File gambar dari kamera / galeri (dart:io File).
  /// Gambar dikonversi ke Base64 Data URI agar dapat dibaca lintas perangkat.
  /// Mengembalikan string imageUrl (Base64 atau path fallback).
  Future<String> kirimGambar({
    required String sessionId,
    required String senderId,
    required MessageSender senderRole,
    required File imageFile,
  }) async {
    // Konversi ke Base64 agar bisa disimpan di Firestore & dibaca lintas perangkat
    final imageUrl = await StorageService.toPersistableString(imageFile.path);
    // Jika konversi gagal (misal file tidak ditemukan), gunakan path asli sebagai fallback
    final persistedUrl = imageUrl.isNotEmpty ? imageUrl : imageFile.path;

    // Simpan pesan ke Firestore
    final ref = _messages(sessionId).doc();
    await ref.set(
      ChatMessageModel(
        id: ref.id,
        senderId: senderId,
        senderRole: senderRole,
        imageUrl: persistedUrl,
        type: MessageType.image,
        timestamp: DateTime.now(),
        isRead: false,
      ).toMap(),
    );

    return persistedUrl;
  }


  // ─── MARK AS READ ───────────────────────────────────────────────────────────

  /// Menandai semua pesan dari pihak lain sebagai sudah dibaca.
  ///
  /// [readerRole] : Peran pembaca saat ini (user / dokter).
  ///   Pesan milik pihak lain akan ditandai isRead: true.
  Future<void> tandaiSudahDibaca({
    required String sessionId,
    required MessageSender readerRole,
  }) async {
    // Tentukan role pengirim yang pesannya perlu ditandai
    final senderRoleStr = readerRole == MessageSender.user
        ? MessageSender.dokter.name
        : MessageSender.user.name;

    final unread = await _messages(sessionId)
        .where('senderRole', isEqualTo: senderRoleStr)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Menghitung jumlah pesan yang belum dibaca dari pihak lain.
  Stream<int> streamUnreadCount({
    required String sessionId,
    required MessageSender readerRole,
  }) {
    final senderRoleStr = readerRole == MessageSender.user
        ? MessageSender.dokter.name
        : MessageSender.user.name;

    return _messages(sessionId)
        .where('senderRole', isEqualTo: senderRoleStr)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ─── CACHE PESAN LOKAL (PERSISTEN SAAT BACK, HAPUS SAAT AKHIRI SESI) ──────

  final Map<String, List<Map<String, dynamic>>> _sessionMessagesCache = {};

  /// Mengambil riwayat pesan lokal untuk sesi tertentu jika ada
  List<Map<String, dynamic>>? getCachedMessages(String sessionId) {
    if (_sessionMessagesCache.containsKey(sessionId)) {
      return List<Map<String, dynamic>>.from(_sessionMessagesCache[sessionId]!);
    }
    return null;
  }

  /// Menyimpan pesan sesi lokal agar tidak hilang saat pengguna menekan tombol back
  void saveCachedMessages(
      String sessionId, List<Map<String, dynamic>> messages) {
    _sessionMessagesCache[sessionId] =
        List<Map<String, dynamic>>.from(messages);
  }

  /// Menghapus pesan sesi ketika pengguna memilih mengakhiri percakapan
  void clearCachedMessages(String sessionId) {
    _sessionMessagesCache.remove(sessionId);
  }
}
