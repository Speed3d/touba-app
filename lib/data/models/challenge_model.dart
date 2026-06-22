import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// 📝 HINT AR: فريق متقدّم على تحدٍّ (وافق على اللعب ضد صاحب الطلب).
class ChallengeApplicant extends Equatable {
  final String teamId;
  final String teamName;
  final String captainId;
  final String? logoUrl;

  const ChallengeApplicant({
    required this.teamId,
    required this.teamName,
    required this.captainId,
    this.logoUrl,
  });

  factory ChallengeApplicant.fromJson(Map<String, dynamic> j) =>
      ChallengeApplicant(
        teamId: j['teamId'] ?? '',
        teamName: j['teamName'] ?? '',
        captainId: j['captainId'] ?? '',
        logoUrl: j['logoUrl'],
      );

  Map<String, dynamic> toJson() => {
        'teamId': teamId,
        'teamName': teamName,
        'captainId': captainId,
        if (logoUrl != null) 'logoUrl': logoUrl,
      };

  @override
  List<Object?> get props => [teamId, teamName, captainId, logoUrl];
}

/// 📝 HINT AR: طلب تحدٍّ ودّي (المرحلة 7) — فريق يطلب مباراة ودّية، تتقدّم فرق
/// أخرى، وصاحب الطلب يختار خصمه فتُفتح محادثة بين الكابتنين. بلا إحصائيات.
class ChallengeModel extends Equatable {
  final String id;
  final String requesterTeamId;
  final String requesterTeamName;
  final String requesterCaptainId;
  final String? requesterLogo;
  final String city;
  final String? note;
  final DateTime? matchDate;
  final String status; // open | matched | cancelled
  final List<ChallengeApplicant> applicants;
  final List<String> applicantCaptainIds; // لاستعلام arrayContains (تحدياتي)
  final String? matchedTeamId;
  final String? matchedTeamName;
  final String? matchedCaptainId;
  final String? chatId;
  final DateTime? createdAt;

  const ChallengeModel({
    required this.id,
    required this.requesterTeamId,
    required this.requesterTeamName,
    required this.requesterCaptainId,
    this.requesterLogo,
    required this.city,
    this.note,
    this.matchDate,
    this.status = 'open',
    this.applicants = const [],
    this.applicantCaptainIds = const [],
    this.matchedTeamId,
    this.matchedTeamName,
    this.matchedCaptainId,
    this.chatId,
    this.createdAt,
  });

  bool get isOpen => status == 'open';
  bool get isMatched => status == 'matched';

  factory ChallengeModel.fromJson(Map<String, dynamic> json, String id) {
    return ChallengeModel(
      id: id,
      requesterTeamId: json['requesterTeamId'] ?? '',
      requesterTeamName: json['requesterTeamName'] ?? '',
      requesterCaptainId: json['requesterCaptainId'] ?? '',
      requesterLogo: json['requesterLogo'],
      city: json['city'] ?? '',
      note: json['note'],
      matchDate: _ts(json['matchDate']),
      status: json['status'] ?? 'open',
      applicants: (json['applicants'] as List?)
              ?.map((e) =>
                  ChallengeApplicant.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      applicantCaptainIds:
          List<String>.from(json['applicantCaptainIds'] ?? const []),
      matchedTeamId: json['matchedTeamId'],
      matchedTeamName: json['matchedTeamName'],
      matchedCaptainId: json['matchedCaptainId'],
      chatId: json['chatId'],
      createdAt: _ts(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'requesterTeamId': requesterTeamId,
        'requesterTeamName': requesterTeamName,
        'requesterCaptainId': requesterCaptainId,
        if (requesterLogo != null) 'requesterLogo': requesterLogo,
        'city': city,
        if (note != null) 'note': note,
        if (matchDate != null) 'matchDate': Timestamp.fromDate(matchDate!),
        'status': status,
        'applicants': applicants.map((e) => e.toJson()).toList(),
        'applicantCaptainIds': applicantCaptainIds,
        if (matchedTeamId != null) 'matchedTeamId': matchedTeamId,
        if (matchedTeamName != null) 'matchedTeamName': matchedTeamName,
        if (matchedCaptainId != null) 'matchedCaptainId': matchedCaptainId,
        if (chatId != null) 'chatId': chatId,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  @override
  List<Object?> get props => [
        id, requesterTeamId, requesterTeamName, requesterCaptainId,
        requesterLogo, city, note, matchDate, status, applicants,
        applicantCaptainIds, matchedTeamId, matchedTeamName, matchedCaptainId,
        chatId, createdAt,
      ];
}

DateTime? _ts(dynamic raw) {
  if (raw == null) return null;
  if (raw is Timestamp) return raw.toDate();
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}
