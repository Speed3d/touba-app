import 'package:cloud_firestore/cloud_firestore.dart';

/// أنواع الإشعارات الخاصة بمنصة طوبة.
enum NotificationType {
  joinRequestAccepted,
  joinRequestRejected,
  matchResult,
  general;

  String get label {
    switch (this) {
      case NotificationType.joinRequestAccepted: return 'طلب انضمام مقبول';
      case NotificationType.joinRequestRejected: return 'طلب انضمام مرفوض';
      case NotificationType.matchResult: return 'نتيجة مباراة';
      case NotificationType.general: return 'إشعار';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.joinRequestAccepted: return '✅';
      case NotificationType.joinRequestRejected: return '❌';
      case NotificationType.matchResult: return '⚽';
      case NotificationType.general: return '🔔';
    }
  }

  static NotificationType fromString(String? s) {
    switch (s) {
      case 'joinRequestAccepted': return NotificationType.joinRequestAccepted;
      case 'joinRequestRejected': return NotificationType.joinRequestRejected;
      case 'matchResult': return NotificationType.matchResult;
      default: return NotificationType.general;
    }
  }
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return NotificationModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      type: NotificationType.fromString(d['type'] as String?),
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      data: d['data'] as Map<String, dynamic>?,
      isRead: d['isRead'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'type': type.name,
        'title': title,
        'body': body,
        if (data != null) 'data': data,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id, userId: userId, type: type, title: title,
        body: body, data: data, isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}
