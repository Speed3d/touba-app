import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';


/// 📝 HINT AR: لاعب ضمن لقطة تشكيلة المباراة (snapshot يُلتقط لحظة إدخال النتيجة)
/// — حتى تبقى تشكيلة كل مباراة محفوظة بذاتها ولا تتغيّر بتغيّر الفريق لاحقاً.
class LineupPlayer extends Equatable {
  final String playerId;
  final String name;
  final String? photoUrl;
  final String position; // حارس/مدافع/وسط/مهاجم
  final int? shirtNumber;

  const LineupPlayer({
    required this.playerId,
    required this.name,
    this.photoUrl,
    this.position = 'غير محدد',
    this.shirtNumber,
  });

  factory LineupPlayer.fromJson(Map<String, dynamic> json) => LineupPlayer(
        playerId: json['playerId'] ?? '',
        name: json['name'] ?? '',
        photoUrl: json['photoUrl'],
        position: json['position'] ?? 'غير محدد',
        shirtNumber: json['shirtNumber'],
      );

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'name': name,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'position': position,
        if (shirtNumber != null) 'shirtNumber': shirtNumber,
      };

  @override
  List<Object?> get props => [playerId, name, photoUrl, position, shirtNumber];
}

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
  final String? homeTeamLogo; // denormalized لعرض الشعار بلا قراءة الفريق
  final String? awayTeamLogo;
  final DateTime? dateTime;
  final String? stadiumId;
  final String? refereeId;
  final String? refereeName; // denormalized للعرض الرخيص
  final String status; // upcoming | live | finished | postponed | cancelled
  final DateTime? matchStartedAt; // 📝 HINT AR: لحظة بدء الشوط الحالي (مؤقّت خادمي)
  final int currentHalf; // الشوط الحالي (1 أو 2) أثناء المباراة الحيّة
  final int homeScore;
  final int awayScore;
  final List<dynamic> events; // {type, playerId, teamId, minute}
  final List<String> lineup; // 📝 HINT AR: لاعبو المباراة (لاحتساب «مباريات»)
  // 📝 HINT AR: لقطة تشكيلة كل فريق + خطته لحظة إدخال النتيجة (محفوظة بالمباراة).
  final List<LineupPlayer> homeLineup;
  final List<LineupPlayer> awayLineup;
  final String? homeFormation; // صيغة الخطة «1-2-2-1»
  final String? awayFormation;
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
    this.homeTeamLogo,
    this.awayTeamLogo,
    this.dateTime,
    this.stadiumId,
    this.refereeId,
    this.refereeName,
    this.status = 'upcoming',
    this.matchStartedAt,
    this.currentHalf = 1,
    this.homeScore = 0,
    this.awayScore = 0,
    this.events = const [],
    this.lineup = const [],
    this.homeLineup = const [],
    this.awayLineup = const [],
    this.homeFormation,
    this.awayFormation,
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
      homeTeamLogo: json['homeTeamLogo'],
      awayTeamLogo: json['awayTeamLogo'],
      dateTime: _parseDateTime(json['dateTime']),
      stadiumId: json['stadiumId'],
      refereeId: json['refereeId'],
      refereeName: json['refereeName'],
      status: json['status'] ?? 'upcoming',
      matchStartedAt: _parseDateTime(json['matchStartedAt']),
      currentHalf: json['currentHalf'] ?? 1,
      homeScore: json['homeScore'] ?? 0,
      awayScore: json['awayScore'] ?? 0,
      events: json['events'] ?? const [],
      lineup: List<String>.from(json['lineup'] ?? const []),
      homeLineup: (json['homeLineup'] as List?)
              ?.map((e) => LineupPlayer.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      awayLineup: (json['awayLineup'] as List?)
              ?.map((e) => LineupPlayer.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      homeFormation: json['homeFormation'],
      awayFormation: json['awayFormation'],
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
      if (homeTeamLogo != null) 'homeTeamLogo': homeTeamLogo,
      if (awayTeamLogo != null) 'awayTeamLogo': awayTeamLogo,
      'dateTime': dateTime?.toIso8601String(),
      if (stadiumId != null) 'stadiumId': stadiumId,
      if (refereeId != null) 'refereeId': refereeId,
      if (refereeName != null) 'refereeName': refereeName,
      'status': status,
      if (matchStartedAt != null)
        'matchStartedAt': matchStartedAt!.toIso8601String(),
      'currentHalf': currentHalf,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'events': events,
      'lineup': lineup,
      if (homeLineup.isNotEmpty)
        'homeLineup': homeLineup.map((e) => e.toJson()).toList(),
      if (awayLineup.isNotEmpty)
        'awayLineup': awayLineup.map((e) => e.toJson()).toList(),
      if (homeFormation != null) 'homeFormation': homeFormation,
      if (awayFormation != null) 'awayFormation': awayFormation,
      'resultConfirmed': resultConfirmed,
    };
  }

  MatchModel copyWith({
    DateTime? dateTime,
    String? refereeId,
    String? refereeName,
    String? status,
    DateTime? matchStartedAt,
    int? currentHalf,
  }) {
    return MatchModel(
      id: id,
      tournamentId: tournamentId,
      round: round,
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      homeTeamName: homeTeamName,
      awayTeamName: awayTeamName,
      homeTeamLogo: homeTeamLogo,
      awayTeamLogo: awayTeamLogo,
      dateTime: dateTime ?? this.dateTime,
      stadiumId: stadiumId,
      refereeId: refereeId ?? this.refereeId,
      refereeName: refereeName ?? this.refereeName,
      status: status ?? this.status,
      matchStartedAt: matchStartedAt ?? this.matchStartedAt,
      currentHalf: currentHalf ?? this.currentHalf,
      homeScore: homeScore,
      awayScore: awayScore,
      events: events,
      lineup: lineup,
      homeLineup: homeLineup,
      awayLineup: awayLineup,
      homeFormation: homeFormation,
      awayFormation: awayFormation,
      resultConfirmed: resultConfirmed,
      statsApplied: statsApplied,
    );
  }

  @override
  List<Object?> get props => [
        id, tournamentId, round, homeTeamId, awayTeamId, homeTeamName,
        awayTeamName, homeTeamLogo, awayTeamLogo, dateTime, stadiumId,
        refereeId, refereeName, status, matchStartedAt, currentHalf,
        homeScore, awayScore, events, lineup,
        homeLineup, awayLineup, homeFormation, awayFormation,
        resultConfirmed, statsApplied,
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
