import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportReason {
  offensiveContent,
  inappropriateBehavior,
  misleadingInfo,
  other;

  String get label {
    switch (this) {
      case ReportReason.offensiveContent: return 'محتوى مسيء';
      case ReportReason.inappropriateBehavior: return 'سلوك غير لائق';
      case ReportReason.misleadingInfo: return 'معلومات مضلّلة';
      case ReportReason.other: return 'أخرى';
    }
  }

  static ReportReason fromString(String? s) {
    switch (s) {
      case 'offensiveContent': return ReportReason.offensiveContent;
      case 'inappropriateBehavior': return ReportReason.inappropriateBehavior;
      case 'misleadingInfo': return ReportReason.misleadingInfo;
      default: return ReportReason.other;
    }
  }
}

enum ReportStatus { pending, reviewed, dismissed }

enum ReportTargetType {
  player,
  team,
  user;

  String get label {
    switch (this) {
      case ReportTargetType.player: return 'لاعب';
      case ReportTargetType.team: return 'فريق';
      case ReportTargetType.user: return 'مستخدم';
    }
  }

  static ReportTargetType fromString(String? s) {
    switch (s) {
      case 'player': return ReportTargetType.player;
      case 'team': return ReportTargetType.team;
      default: return ReportTargetType.user;
    }
  }
}

class ReportModel {
  final String id;
  final String reporterId;
  final ReportTargetType targetType;
  final String targetId;
  final String targetName;
  final ReportReason reason;
  final String description;
  final ReportStatus status;
  final DateTime createdAt;

  const ReportModel({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.targetName,
    required this.reason,
    required this.description,
    this.status = ReportStatus.pending,
    required this.createdAt,
  });

  factory ReportModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return ReportModel(
      id: doc.id,
      reporterId: d['reporterId'] ?? '',
      targetType: ReportTargetType.fromString(d['targetType'] as String?),
      targetId: d['targetId'] ?? '',
      targetName: d['targetName'] ?? '',
      reason: ReportReason.fromString(d['reason'] as String?),
      description: d['description'] ?? '',
      status: _parseStatus(d['status'] as String?),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'reporterId': reporterId,
        'targetType': targetType.name,
        'targetId': targetId,
        'targetName': targetName,
        'reason': reason.name,
        'description': description,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  static ReportStatus _parseStatus(String? s) {
    switch (s) {
      case 'reviewed': return ReportStatus.reviewed;
      case 'dismissed': return ReportStatus.dismissed;
      default: return ReportStatus.pending;
    }
  }
}
