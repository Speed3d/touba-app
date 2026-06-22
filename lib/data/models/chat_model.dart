import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// 📝 HINT AR: محادثة بين طرفين (كابتن↔كابتن في التحدي). مُعمَّمة وقابلة للتوسعة.
/// نمط مُعاد من «حرفي»: `participants[2]` لاستعلام arrayContains (بلا فهرس مركّب)،
/// عدّاد غير مقروء + أسماء + صور كخرائط بمفتاح uid، آخر رسالة، وانتهاء صلاحية.
class ChatModel extends Equatable {
  final String id;
  final List<String> participants; // [uidA, uidB]
  final Map<String, String> names; // uid -> الاسم (الفريق/الكابتن)
  final Map<String, String?> photos; // uid -> صورة
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final Map<String, int> unread; // uid -> عدد غير المقروء
  final String? challengeId; // التحدي المرتبط (إن وُجد)
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  const ChatModel({
    required this.id,
    this.participants = const [],
    this.names = const {},
    this.photos = const {},
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.unread = const {},
    this.challengeId,
    this.isActive = true,
    this.createdAt,
    this.expiresAt,
  });

  String otherId(String myUid) =>
      participants.firstWhere((p) => p != myUid, orElse: () => myUid);
  String otherName(String myUid) => names[otherId(myUid)] ?? 'فريق';
  String? otherPhoto(String myUid) => photos[otherId(myUid)];
  int unreadFor(String myUid) => unread[myUid] ?? 0;

  factory ChatModel.fromJson(Map<String, dynamic> json, String id) {
    return ChatModel(
      id: id,
      participants: List<String>.from(json['participants'] ?? const []),
      names: (json['names'] as Map?)
              ?.map((k, v) => MapEntry(k.toString(), (v ?? '').toString())) ??
          const {},
      photos: (json['photos'] as Map?)
              ?.map((k, v) => MapEntry(k.toString(), v as String?)) ??
          const {},
      lastMessage: json['lastMessage'],
      lastMessageTime: _ts(json['lastMessageTime']),
      lastMessageSenderId: json['lastMessageSenderId'],
      unread: (json['unread'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0)) ??
          const {},
      challengeId: json['challengeId'],
      isActive: json['isActive'] ?? true,
      createdAt: _ts(json['createdAt']),
      expiresAt: _ts(json['expiresAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'participants': participants,
        'names': names,
        'photos': photos,
        'lastMessage': lastMessage,
        'lastMessageTime': lastMessageTime != null
            ? Timestamp.fromDate(lastMessageTime!)
            : FieldValue.serverTimestamp(),
        'lastMessageSenderId': lastMessageSenderId,
        'unread': unread,
        if (challengeId != null) 'challengeId': challengeId,
        'isActive': isActive,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      };

  @override
  List<Object?> get props => [
        id, participants, names, photos, lastMessage, lastMessageTime,
        lastMessageSenderId, unread, challengeId, isActive, createdAt, expiresAt,
      ];
}

DateTime? _ts(dynamic raw) {
  if (raw == null) return null;
  if (raw is Timestamp) return raw.toDate();
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}
