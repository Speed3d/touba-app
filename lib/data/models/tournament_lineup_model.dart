import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'match_model.dart';

/// 📝 HINT AR: تشكيلة فريق في بطولة (بند 8). واحدة لكل (بطولة، فريق) — مُعرّفها
/// `${tournamentId}_${teamId}`. يُدخلها الكابتن (أساسيون + احتياط + خطة) ويرسلها،
/// ثم يراجعها المنظّم (قبول/رفض) قبل بدء البطولة.
class TournamentLineupModel extends Equatable {
  final String id; // ${tournamentId}_${teamId}
  final String tournamentId;
  final String teamId;
  final String teamName;
  final String captainId;
  final List<LineupPlayer> starters; // مرتّبون حسب خانات الخطة
  final List<LineupPlayer> subs;
  final String? formation; // «1-2-2-1» (قد تكون مخصّصة)
  final String status; // pending | approved | rejected
  final String? reviewNote; // ملاحظة المنظّم عند الرفض
  final DateTime? createdAt;

  const TournamentLineupModel({
    required this.id,
    required this.tournamentId,
    required this.teamId,
    required this.teamName,
    required this.captainId,
    this.starters = const [],
    this.subs = const [],
    this.formation,
    this.status = 'pending',
    this.reviewNote,
    this.createdAt,
  });

  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isPending => status == 'pending';

  factory TournamentLineupModel.fromJson(Map<String, dynamic> json, String id) {
    return TournamentLineupModel(
      id: id,
      tournamentId: json['tournamentId'] ?? '',
      teamId: json['teamId'] ?? '',
      teamName: json['teamName'] ?? '',
      captainId: json['captainId'] ?? '',
      starters: (json['starters'] as List?)
              ?.map((e) => LineupPlayer.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      subs: (json['subs'] as List?)
              ?.map((e) => LineupPlayer.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      formation: json['formation'],
      status: json['status'] ?? 'pending',
      reviewNote: json['reviewNote'],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  // 📝 HINT AR: الكابتن يكتب هذه الحقول فقط (status=pending عند الإرسال).
  // مراجعة المنظّم (status/reviewNote) تتم عبر تحديث منفصل تسمح به القاعدة.
  Map<String, dynamic> toJson() => {
        'tournamentId': tournamentId,
        'teamId': teamId,
        'teamName': teamName,
        'captainId': captainId,
        'starters': starters.map((e) => e.toJson()).toList(),
        'subs': subs.map((e) => e.toJson()).toList(),
        if (formation != null) 'formation': formation,
        'status': status,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  @override
  List<Object?> get props => [
        id, tournamentId, teamId, teamName, captainId, starters, subs,
        formation, status, reviewNote, createdAt,
      ];
}
