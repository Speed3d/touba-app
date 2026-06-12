import 'package:equatable/equatable.dart';

class TeamModel extends Equatable {
  final String id;
  final String name;
  final String logoUrl;
  final String city;
  final String area;
  final int foundedYear;
  final String primaryColor;
  final String secondaryColor;
  final String managerName;
  final String managerPhone;
  final String ownerUid;
  final int ratingPoints;
  final Map<String, dynamic> stats;

  const TeamModel({
    required this.id,
    required this.name,
    this.logoUrl = '',
    required this.city,
    required this.area,
    this.foundedYear = 0,
    this.primaryColor = '',
    this.secondaryColor = '',
    required this.managerName,
    this.managerPhone = '',
    required this.ownerUid,
    this.ratingPoints = 1200,
    this.stats = const {
      'played': 0, 'wins': 0, 'draws': 0, 'losses': 0, 'goalsFor': 0, 'goalsAgainst': 0,
    },
  });

  factory TeamModel.fromJson(Map<String, dynamic> json, String documentId) {
    return TeamModel(
      id: documentId,
      name: json['name'] ?? '',
      logoUrl: json['logoUrl'] ?? '',
      city: json['city'] ?? '',
      area: json['area'] ?? '',
      foundedYear: json['foundedYear'] ?? 0,
      primaryColor: json['primaryColor'] ?? '',
      secondaryColor: json['secondaryColor'] ?? '',
      managerName: json['managerName'] ?? '',
      managerPhone: json['managerPhone'] ?? '',
      ownerUid: json['ownerUid'] ?? '',
      ratingPoints: json['ratingPoints'] ?? 1200,
      stats: json['stats'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'logoUrl': logoUrl,
      'city': city,
      'area': area,
      'foundedYear': foundedYear,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'managerName': managerName,
      'managerPhone': managerPhone,
      'ownerUid': ownerUid,
      'ratingPoints': ratingPoints,
      'stats': stats,
    };
  }

  @override
  List<Object?> get props => [id, name, logoUrl, city, area, foundedYear, primaryColor, secondaryColor, managerName, managerPhone, ownerUid, ratingPoints, stats];
}
