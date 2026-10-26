import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipe pengirim pesan dalam sesi konsultasi.
enum MessageSender { user, dokter }

/// Tipe konten pesan dalam sesi konsultasi.
enum MessageType { text, image, formulir }

/// Model pesan individual dalam ruang obrolan konsultasi.
///
/// Struktur Firestore:
/// ```
/// konsultasi_sessions/{sessionId}/messages/{messageId}
/// ```
class ChatMessageModel {
  final String id;
  final String senderId;
  final MessageSender senderRole;
  final String? text;
  final String? imageUrl;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? replyToId;
  final String? replyToSender;
  final String? replyToText;
  final String? replyToType;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderRole,
    this.text,
    this.imageUrl,
    this.type = MessageType.text,
    required this.timestamp,
    this.isRead = false,
    this.replyToId,
    this.replyToSender,
    this.replyToText,
    this.replyToType,
  });

  /// Parsing dari dokumen Firestore.
  factory ChatMessageModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawTs = data['timestamp'] ?? data['serverTimestamp'];
    DateTime parsedTs = DateTime.now();
    if (rawTs is Timestamp) {
      parsedTs = rawTs.toDate();
    } else if (rawTs is int) {
      parsedTs = DateTime.fromMillisecondsSinceEpoch(rawTs);
    } else if (rawTs is String) {
      parsedTs = DateTime.tryParse(rawTs) ?? DateTime.now();
    }

    return ChatMessageModel(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      senderRole: _parseSender(data['senderRole'] as String? ?? 'user'),
      text: data['text'] as String?,
      imageUrl: data['imageUrl'] as String?,
      type: _parseType(data['type'] as String? ?? 'text'),
      timestamp: parsedTs,
      isRead: data['isRead'] as bool? ?? false,
      replyToId: data['replyToId'] as String?,
      replyToSender: data['replyToSender'] as String?,
      replyToText: data['replyToText'] as String?,
      replyToType: data['replyToType'] as String?,
    );
  }

  /// Konversi ke Map untuk disimpan ke Firestore.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'senderId': senderId,
      'senderRole': senderRole.name,
      'text': text,
      'imageUrl': imageUrl,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'serverTimestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
    if (replyToId != null) map['replyToId'] = replyToId;
    if (replyToSender != null) map['replyToSender'] = replyToSender;
    if (replyToText != null) map['replyToText'] = replyToText;
    if (replyToType != null) map['replyToType'] = replyToType;
    return map;
  }

  static MessageSender _parseSender(String raw) {
    return raw == 'dokter' ? MessageSender.dokter : MessageSender.user;
  }

  static MessageType _parseType(String raw) {
    switch (raw) {
      case 'image':
        return MessageType.image;
      case 'formulir':
        return MessageType.formulir;
      default:
        return MessageType.text;
    }
  }
}
