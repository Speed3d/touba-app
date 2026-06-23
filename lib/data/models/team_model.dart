import 'package:equatable/equatable.dart';

/// 📝 HINT AR: إحصائيات الفريق المجمّعة مسبقاً — تُكتب من Cloud Functions حصراً.
class TeamStats extends Equatable {
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int points;
  final int goalsFor;
  final int goalsAgainst;

  const TeamStats({
    this.played = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.points = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
  });

  int get goalDiff => goalsFor - goalsAgainst;

  factory TeamStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TeamStats();
    return TeamStats(
      played: json['played'] ?? 0,
      wins: json['wins'] ?? 0,
      draws: json['draws'] ?? 0,
      losses: json['losses'] ?? 0,
      points: json['points'] ?? 0,
      goalsFor: json['goalsFor'] ?? 0,
      goalsAgainst: json['goalsAgainst'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'played': played,
        'wins': wins,
        'draws': draws,
        'losses': losses,
        'points': points,
        'goalsFor': goalsFor,
        'goalsAgainst': goalsAgainst,
      };

  @override
  List<Object?> get props =>
      [played, wins, draws, losses, points, goalsFor, goalsAgainst];
}

/// 📝 HINT AR: ملخّص لاعب مصغّر داخل مستند الفريق (denormalization) — لعرض
/// قائمة التشكيلة بقراءة مستند واحد بدل قراءة كل لاعب (ترشيد الاستهلاك).
/// يُحدَّث تلقائياً عبر Cloud Function عند تغيّر اللاعب.
class RosterEntry extends Equatable {
  final String playerId;
  final String name;
  final String? photoUrl;
  final String position;
  final int? shirtNumber;

  const RosterEntry({
    required this.playerId,
    required this.name,
    this.photoUrl,
    this.position = 'غير محدد',
    this.shirtNumber,
  });

  factory RosterEntry.fromJson(Map<String, dynamic> json) {
    return RosterEntry(
      playerId: json['playerId'] ?? '',
      name: json['name'] ?? '',
      photoUrl: json['photoUrl'],
      position: json['position'] ?? 'غير محدد',
      shirtNumber: json['shirtNumber'],
    );
  }

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'name': name,
        'photoUrl': photoUrl,
        'position': position,
        'shirtNumber': shirtNumber,
      };

  @override
  List<Object?> get props => [playerId, name, photoUrl, position, shirtNumber];
}

/// 📝 HINT AR: الفريق. الحقول المحسوبة (ratingPoints, stats, badges, roster)
/// يكتبها النظام (Cloud Functions)؛ الكابتن يكتب البيانات التعريفية فقط.
class TeamModel extends Equatable {
  final String id;
  final String name;
  final String nameLower; // للبحث وكشف التكرار
  final String? logoUrl;
  final String city;
  final String? area;
  final int? foundedYear;
  final String? colorPrimary;
  final String? colorSecondary;
  final String? description;
  final String captainId;
  final String? managerPhone; // خاص
  final int ratingPoints; // التصنيف العام
  final List<String> badges;
  final TeamStats stats;
  final List<RosterEntry> roster;
  final int playerCount;
  final String? formation; // خطة الفريق الأساسية «1-2-2-1» (يختارها الكابتن)
  final List<String> photos; // معرض صور الفريق (حتى 5) — يديره الكابتن
  // 📝 HINT AR: تعيين الكابتن الصريح للاعبين على خانات الخطة (playerId لكل خانة
  // بترتيب formationSlots) — للتشكيلة التفاعلية على الملعب.
  final List<String> lineupSlots;

  const TeamModel({
    required this.id,
    required this.name,
    String? nameLower,
    this.logoUrl,
    required this.city,
    this.area,
    this.foundedYear,
    this.colorPrimary,
    this.colorSecondary,
    this.description,
    required this.captainId,
    this.managerPhone,
    this.ratingPoints = 1200,
    this.badges = const [],
    this.stats = const TeamStats(),
    this.roster = const [],
    this.playerCount = 0,
    this.formation,
    this.photos = const [],
    this.lineupSlots = const [],
  }) : nameLower = nameLower ?? name;

  factory TeamModel.fromJson(Map<String, dynamic> json, String id) {
    return TeamModel(
      id: id,
      name: json['name'] ?? '',
      nameLower: json['nameLower'] ?? (json['name'] ?? '').toString(),
      logoUrl: json['logoUrl'],
      city: json['city'] ?? '',
      area: json['area'],
      foundedYear: json['foundedYear'],
      colorPrimary: json['colorPrimary'],
      colorSecondary: json['colorSecondary'],
      description: json['description'],
      captainId: json['captainId'] ?? '',
      managerPhone: json['managerPhone'],
      ratingPoints: json['ratingPoints'] ?? 1200,
      badges: List<String>.from(json['badges'] ?? const []),
      stats: TeamStats.fromJson(json['stats']),
      roster: (json['roster'] as List<dynamic>? ?? const [])
          .map((e) => RosterEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      playerCount: json['playerCount'] ?? 0,
      formation: json['formation'],
      photos: List<String>.from(json['photos'] ?? const []),
      lineupSlots: List<String>.from(json['lineupSlots'] ?? const []),
    );
  }

  /// 📝 HINT AR: عند الإنشاء نرسل القيم الافتراضية الصريحة (تطابق قواعد الأمان).
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'nameLower': nameLower,
      if (logoUrl != null) 'logoUrl': logoUrl,
      'city': city,
      if (area != null) 'area': area,
      if (foundedYear != null) 'foundedYear': foundedYear,
      if (colorPrimary != null) 'colorPrimary': colorPrimary,
      if (colorSecondary != null) 'colorSecondary': colorSecondary,
      if (description != null) 'description': description,
      'captainId': captainId,
      if (managerPhone != null) 'managerPhone': managerPhone,
      'ratingPoints': ratingPoints,
      'badges': badges,
      'stats': stats.toJson(),
      'roster': roster.map((e) => e.toJson()).toList(),
      'playerCount': playerCount,
      if (formation != null) 'formation': formation,
      'photos': photos,
      'lineupSlots': lineupSlots,
    };
  }

  TeamModel copyWith({
    String? name,
    String? logoUrl,
    String? city,
    String? area,
    int? foundedYear,
    String? colorPrimary,
    String? colorSecondary,
    String? description,
    String? captainId,
    String? managerPhone,
    int? ratingPoints,
    List<String>? badges,
    TeamStats? stats,
    List<RosterEntry>? roster,
    int? playerCount,
    String? formation,
    List<String>? photos,
    List<String>? lineupSlots,
  }) {
    return TeamModel(
      id: id,
      name: name ?? this.name,
      nameLower: (name ?? this.name),
      logoUrl: logoUrl ?? this.logoUrl,
      city: city ?? this.city,
      area: area ?? this.area,
      foundedYear: foundedYear ?? this.foundedYear,
      colorPrimary: colorPrimary ?? this.colorPrimary,
      colorSecondary: colorSecondary ?? this.colorSecondary,
      description: description ?? this.description,
      captainId: captainId ?? this.captainId,
      managerPhone: managerPhone ?? this.managerPhone,
      ratingPoints: ratingPoints ?? this.ratingPoints,
      badges: badges ?? this.badges,
      stats: stats ?? this.stats,
      roster: roster ?? this.roster,
      playerCount: playerCount ?? this.playerCount,
      formation: formation ?? this.formation,
      photos: photos ?? this.photos,
      lineupSlots: lineupSlots ?? this.lineupSlots,
    );
  }

  @override
  List<Object?> get props => [
        id, name, nameLower, logoUrl, city, area, foundedYear, colorPrimary,
        colorSecondary, description, captainId, managerPhone, ratingPoints,
        badges, stats, roster, playerCount, formation, photos, lineupSlots,
      ];
}
