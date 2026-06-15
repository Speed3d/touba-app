import 'package:equatable/equatable.dart';

class TeamStats extends Equatable {
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int points;
  final int goalsFor;
  final int goalsAgainst;

  const TeamStats({
    this.played = 0,
    this.won = 0,
    this.drawn = 0,
    this.lost = 0,
    this.points = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
  });

  factory TeamStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TeamStats();
    return TeamStats(
      played: json['played'] ?? 0,
      won: json['won'] ?? 0,
      drawn: json['drawn'] ?? 0,
      lost: json['lost'] ?? 0,
      points: json['points'] ?? 0,
      goalsFor: json['goalsFor'] ?? 0,
      goalsAgainst: json['goalsAgainst'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'played': played,
      'won': won,
      'drawn': drawn,
      'lost': lost,
      'points': points,
      'goalsFor': goalsFor,
      'goalsAgainst': goalsAgainst,
    };
  }

  @override
  List<Object?> get props => [
        played,
        won,
        drawn,
        lost,
        points,
        goalsFor,
        goalsAgainst,
      ];
}

class TeamModel extends Equatable {
  final String id;
  final String name;
  final String? logoUrl;
  final String city;
  final String captainId;
  final List<String> playersIds;
  final TeamStats stats;

  const TeamModel({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.city,
    required this.captainId,
    this.playersIds = const [],
    this.stats = const TeamStats(),
  });

  factory TeamModel.fromJson(Map<String, dynamic> json, String id) {
    return TeamModel(
      id: id,
      name: json['name'] ?? '',
      logoUrl: json['logoUrl'],
      city: json['city'] ?? '',
      captainId: json['captainId'] ?? '',
      playersIds: List<String>.from(json['playersIds'] ?? []),
      stats: TeamStats.fromJson(json['stats']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (logoUrl != null) 'logoUrl': logoUrl,
      'city': city,
      'captainId': captainId,
      'playersIds': playersIds,
      'stats': stats.toJson(),
    };
  }

  TeamModel copyWith({
    String? name,
    String? logoUrl,
    String? city,
    String? captainId,
    List<String>? playersIds,
    TeamStats? stats,
  }) {
    return TeamModel(
      id: id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      city: city ?? this.city,
      captainId: captainId ?? this.captainId,
      playersIds: playersIds ?? this.playersIds,
      stats: stats ?? this.stats,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        logoUrl,
        city,
        captainId,
        playersIds,
        stats,
      ];
}
