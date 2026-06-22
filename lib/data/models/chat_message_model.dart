import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// نوع الرسالة: نصية عادية أو رسالة نظام (ترحيب/إشعار داخل المحادثة).
enum ChatMessageType { text, system }

/// 📝 HINT AR: رسالة واحدة داخل محادثة (`chats/{id}/messages`). بسيطة (نص فقط)
/// — يمكن توسعتها لاحقاً (صور/موقع) كما في نمط «حرفي».
class ChatMessageModel extends Equatable {
  final String id;
  final String senderId; // uid المرسل أو 'system'
  final String senderName;
  final String content;
  final ChatMessageType type;
  final DateTime? sentAt;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.type = ChatMessageType.text,
    this.sentAt,
  });

  bool isFromMe(String uid) => senderId == uid;
  bool get isSystem => type == ChatMessageType.system;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json, String id) {
    return ChatMessageModel(
      id: id,
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] == 'system'
          ? ChatMessageType.system
          : ChatMessageType.text,
      sentAt: json['sentAt'] is Timestamp
          ? (json['sentAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
        'type': type.name,
        'sentAt': sentAt != null
            ? Timestamp.fromDate(sentAt!)
            : FieldValue.serverTimestamp(),
      };

  @override
  List<Object?> get props => [id, senderId, senderName, content, type, sentAt];
}
