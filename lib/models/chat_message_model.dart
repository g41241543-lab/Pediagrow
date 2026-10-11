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

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderRole,
    this.text,
    this.imageUrl,
    this.type = MessageType.text,
    required this.timestamp,
    this.isRead = false,
  });

  /// Parsing dari dokumen Firestore.
  factory ChatMessageModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ChatMessageModel(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      senderRole: _parseSender(data['senderRole'] as String? ?? 'user'),
      text: data['text'] as String?,
      imageUrl: data['imageUrl'] as String?,
      type: _parseType(data['type'] as String? ?? 'text'),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
    );
  }

  /// Konversi ke Map untuk disimpan ke Firestore.
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderRole': senderRole.name,
      'text': text,
      'imageUrl': imageUrl,
      'type': type.name,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
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
