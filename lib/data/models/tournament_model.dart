import 'package:equatable/equatable.dart';

/// 📝 HINT AR: داعم/راعٍ للبطولة (لوغو + اسم) — يعرضه تبويب «شروط وقوانين».
/// قائمة منها تُحفظ على مستند البطولة (يكتبها المنظّم/الأدمن).
class Sponsor extends Equatable {
  final String name;
  final String logoUrl;

  const Sponsor({required this.name, this.logoUrl = ''});

  factory Sponsor.fromJson(Map<String, dynamic> json) => Sponsor(
        name: json['name'] ?? '',
        logoUrl: json['logoUrl'] ?? '',
      );

  Map<String, dynamic> toJson() => {'name': name, 'logoUrl': logoUrl};

  @override
  List<Object?> get props => [name, logoUrl];
}

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
  final String? cupImageUrl; // صورة الكأس (يضبطها الأدمن)
  final String? prizes; // وصف الجوائز
  final String? sponsorName;
  final String? sponsorLogo;
  final List<dynamic> standings;
  final bool isHomeAndAway; // ذهاب وإياب؟
  final String generationMode; // 'full_tree' or 'round_by_round'
  final int? numberOfGroups; // لبطولات المجموعات
  final int playerFormat; // عدد اللاعبين الأساسيين (5/7/11)
  final String? winnerTeamId; // الفريق الفائز (يكتبه النظام عند الانتهاء)
  final String? winnerTeamName; // اسم الفائز (denormalized للعرض الرخيص)
  final String? rules; // نص الشروط والقوانين (تبويب «شروط وقوانين»)
  final List<Sponsor> sponsors; // الداعمون (لوغو + اسم) — المنظّم/الأدمن
  final List<String> adBanners; // صور البانر المتحرك في تبويب الشروط
  final bool isFree; // بطولة مجانية (true) أو باشتراك (false) — يضبطه الأدمن/المنظّم
  final String? entryInfo; // نص رسوم/تواصل الدخول (يُعرض على البطولة المدفوعة)
  final int matchDuration; // مدّة الشوط بالدقائق (30 أو 45) — للمؤقّت الحيّ
  final int halvesCount; // عدد الأشواط (1 أو 2)

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
    this.cupImageUrl,
    this.prizes,
    this.sponsorName,
    this.sponsorLogo,
    this.standings = const [],
    this.isHomeAndAway = false,
    this.generationMode = 'full_tree',
    this.numberOfGroups,
    this.playerFormat = 6,
    this.winnerTeamId,
    this.winnerTeamName,
    this.rules,
    this.sponsors = const [],
    this.adBanners = const [],
    this.isFree = true,
    this.entryInfo,
    this.matchDuration = 45,
    this.halvesCount = 2,
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
      cupImageUrl: json['cupImageUrl'],
      prizes: json['prizes'],
      sponsorName: json['sponsorName'],
      sponsorLogo: json['sponsorLogo'],
      standings: json['standings'] ?? const [],
      isHomeAndAway: json['isHomeAndAway'] ?? false,
      generationMode: json['generationMode'] ?? 'full_tree',
      numberOfGroups: json['numberOfGroups'],
      playerFormat: json['playerFormat'] ?? 6,
      winnerTeamId: json['winnerTeamId'],
      winnerTeamName: json['winnerTeamName'],
      rules: json['rules'],
      sponsors: (json['sponsors'] as List?)
              ?.map((e) => Sponsor.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      adBanners: List<String>.from(json['adBanners'] ?? const []),
      isFree: json['isFree'] ?? true,
      entryInfo: json['entryInfo'],
      matchDuration: json['matchDuration'] ?? 45,
      halvesCount: json['halvesCount'] ?? 2,
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
      if (cupImageUrl != null) 'cupImageUrl': cupImageUrl,
      if (prizes != null) 'prizes': prizes,
      if (sponsorName != null) 'sponsorName': sponsorName,
      if (sponsorLogo != null) 'sponsorLogo': sponsorLogo,
      'standings': standings,
      'isHomeAndAway': isHomeAndAway,
      'generationMode': generationMode,
      if (numberOfGroups != null) 'numberOfGroups': numberOfGroups,
      'playerFormat': playerFormat,
      if (rules != null) 'rules': rules,
      if (sponsors.isNotEmpty)
        'sponsors': sponsors.map((s) => s.toJson()).toList(),
      if (adBanners.isNotEmpty) 'adBanners': adBanners,
      'isFree': isFree,
      if (entryInfo != null) 'entryInfo': entryInfo,
      'matchDuration': matchDuration,
      'halvesCount': halvesCount,
      // 📝 HINT AR: winnerTeamId يكتبه النظام (CF) عند الانتهاء — لا نرسله من العميل.
    };
  }

  @override
  List<Object?> get props => [
        id, name, type, organizerUid, teamIds, pointsRule, tiebreakers, rounds,
        startDate, endDate, city, status, logoUrl, cupImageUrl, prizes,
        sponsorName, sponsorLogo, standings, isHomeAndAway, generationMode,
        numberOfGroups, playerFormat, winnerTeamId, winnerTeamName,
        rules, sponsors, adBanners, isFree, entryInfo,
        matchDuration, halvesCount,
      ];
}
