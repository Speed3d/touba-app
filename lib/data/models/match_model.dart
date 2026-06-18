import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';


/// 📝 HINT AR: المباراة (مجموعة top-level `matches`). إدخال النتيجة وتأكيدها
/// (resultConfirmed) بيد منظّم البطولة؛ عند التأكيد تُشغّل Cloud Function التي
/// تحدّث الإحصائيات ذرّياً وتضبط statsApplied (لا يُكتب من العميل).
class MatchModel extends Equatable {
  final String id;
  final String tournamentId;
  final int round;
  final String homeTeamId;
  final String awayTeamId;
  final String homeTeamName; // denormalized للعرض الرخيص
  final String awayTeamName;
  final DateTime? dateTime;
  final String? stadiumId;
  final String? refereeId;
  final String status; // upcoming | live | finished | postponed | cancelled
  final int homeScore;
  final int awayScore;
  final List<dynamic> events; // {type, playerId, teamId, minute}
  final List<String> lineup; // 📝 HINT AR: لاعبو المباراة (لاحتساب «مباريات»)
  final bool resultConfirmed;
  final bool statsApplied; // علم النظام (CF) — للعرض فقط

  const MatchModel({
    required this.id,
    required this.tournamentId,
    this.round = 1,
    required this.homeTeamId,
    required this.awayTeamId,
    this.homeTeamName = '',
    this.awayTeamName = '',
    this.dateTime,
    this.stadiumId,
    this.refereeId,
    this.status = 'upcoming',
    this.homeScore = 0,
    this.awayScore = 0,
    this.events = const [],
    this.lineup = const [],
    this.resultConfirmed = false,
    this.statsApplied = false,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json, String id) {
    return MatchModel(
      id: id,
      tournamentId: json['tournamentId'] ?? '',
      round: json['round'] ?? 1,
      homeTeamId: json['homeTeamId'] ?? '',
      awayTeamId: json['awayTeamId'] ?? '',
      homeTeamName: json['homeTeamName'] ?? '',
      awayTeamName: json['awayTeamName'] ?? '',
      dateTime: _parseDateTime(json['dateTime']),
      stadiumId: json['stadiumId'],
      refereeId: json['refereeId'],
      status: json['status'] ?? 'upcoming',
      homeScore: json['homeScore'] ?? 0,
      awayScore: json['awayScore'] ?? 0,
      events: json['events'] ?? const [],
      lineup: List<String>.from(json['lineup'] ?? const []),
      resultConfirmed: json['resultConfirmed'] ?? false,
      statsApplied: json['statsApplied'] ?? false,
    );
  }

  /// 📝 HINT AR: لا نُرسل statsApplied من العميل (يكتبه النظام فقط).
  Map<String, dynamic> toJson() {
    return {
      'tournamentId': tournamentId,
      'round': round,
      'homeTeamId': homeTeamId,
      'awayTeamId': awayTeamId,
      'homeTeamName': homeTeamName,
      'awayTeamName': awayTeamName,
      'dateTime': dateTime?.toIso8601String(),
      if (stadiumId != null) 'stadiumId': stadiumId,
      if (refereeId != null) 'refereeId': refereeId,
      'status': status,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'events': events,
      'lineup': lineup,
      'resultConfirmed': resultConfirmed,
    };
  }

  @override
  List<Object?> get props => [
        id, tournamentId, round, homeTeamId, awayTeamId, homeTeamName,
        awayTeamName, dateTime, stadiumId, refereeId, status, homeScore,
        awayScore, events, lineup, resultConfirmed, statsApplied,
      ];
}

/// 📝 HINT AR: Firestore يُخزَّن dateTime كـ ISO String لكن يُرجعه
/// أحياناً كـ Timestamp (حسب طريقة الكتابة). هذه الدالة تتعامل مع الحالتين.
DateTime? _parseDateTime(dynamic raw) {
  if (raw == null) return null;
  if (raw is Timestamp) return raw.toDate();
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}
