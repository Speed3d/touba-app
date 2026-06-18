import 'package:equatable/equatable.dart';

/// 📝 HINT AR: البطولة. الترتيب (standings) يحسبه النظام (Cloud Functions)؛
/// المنظّم يكتب البيانات التعريفية والفرق المشاركة فقط.
class TournamentModel extends Equatable {
  final String id;
  final String name;
  final String type; // league | knockout | groups
  final String organizerUid;
  final List<String> teamIds;
  final Map<String, int> pointsRule; // {win:3, draw:1, loss:0}
  final List<String> tiebreakers;
  final int? rounds;
  final DateTime? startDate;
  final DateTime? endDate;
  final String city;
  final String status; // upcoming | ongoing | finished
  final String? logoUrl;
  final String? sponsorName;
  final String? sponsorLogo;
  final List<dynamic> standings;
  final bool isHomeAndAway; // ذهاب وإياب؟
  final String generationMode; // 'full_tree' or 'round_by_round'
  final int? numberOfGroups; // لبطولات المجموعات
  final int playerFormat; // عدد اللاعبين الأساسيين (5/7/11)
  final String? winnerTeamId; // الفريق الفائز (يكتبه النظام عند الانتهاء)
  final String? winnerTeamName; // اسم الفائز (denormalized للعرض الرخيص)

  const TournamentModel({
    required this.id,
    required this.name,
    this.type = 'league',
    required this.organizerUid,
    this.teamIds = const [],
    this.pointsRule = const {'win': 3, 'draw': 1, 'loss': 0},
    this.tiebreakers = const ['points', 'goalDiff', 'goalsFor', 'h2h'],
    this.rounds,
    this.startDate,
    this.endDate,
    required this.city,
    this.status = 'upcoming',
    this.logoUrl,
    this.sponsorName,
    this.sponsorLogo,
    this.standings = const [],
    this.isHomeAndAway = false,
    this.generationMode = 'full_tree',
    this.numberOfGroups,
    this.playerFormat = 7,
    this.winnerTeamId,
    this.winnerTeamName,
  });

  factory TournamentModel.fromJson(Map<String, dynamic> json, String id) {
    return TournamentModel(
      id: id,
      name: json['name'] ?? '',
      type: json['type'] ?? 'league',
      organizerUid: json['organizerUid'] ?? '',
      teamIds: List<String>.from(json['teamIds'] ?? const []),
      pointsRule: Map<String, int>.from(
          json['pointsRule'] ?? const {'win': 3, 'draw': 1, 'loss': 0}),
      tiebreakers: List<String>.from(json['tiebreakers'] ??
          const ['points', 'goalDiff', 'goalsFor', 'h2h']),
      rounds: json['rounds'],
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
      city: json['city'] ?? '',
      status: json['status'] ?? 'upcoming',
      logoUrl: json['logoUrl'],
      sponsorName: json['sponsorName'],
      sponsorLogo: json['sponsorLogo'],
      standings: json['standings'] ?? const [],
      isHomeAndAway: json['isHomeAndAway'] ?? false,
      generationMode: json['generationMode'] ?? 'full_tree',
      numberOfGroups: json['numberOfGroups'],
      playerFormat: json['playerFormat'] ?? 7,
      winnerTeamId: json['winnerTeamId'],
      winnerTeamName: json['winnerTeamName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'organizerUid': organizerUid,
      'teamIds': teamIds,
      'pointsRule': pointsRule,
      'tiebreakers': tiebreakers,
      if (rounds != null) 'rounds': rounds,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'city': city,
      'status': status,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (sponsorName != null) 'sponsorName': sponsorName,
      if (sponsorLogo != null) 'sponsorLogo': sponsorLogo,
      'standings': standings,
      'isHomeAndAway': isHomeAndAway,
      'generationMode': generationMode,
      if (numberOfGroups != null) 'numberOfGroups': numberOfGroups,
      'playerFormat': playerFormat,
      // 📝 HINT AR: winnerTeamId يكتبه النظام (CF) عند الانتهاء — لا نرسله من العميل.
    };
  }

  @override
  List<Object?> get props => [
        id, name, type, organizerUid, teamIds, pointsRule, tiebreakers, rounds,
        startDate, endDate, city, status, logoUrl, sponsorName, sponsorLogo,
        standings, isHomeAndAway, generationMode, numberOfGroups,
        playerFormat, winnerTeamId, winnerTeamName,
      ];
}
