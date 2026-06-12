import 'package:equatable/equatable.dart';

class TournamentModel extends Equatable {
  final String id;
  final String name;
  final String type; // league, knockout, groups
  final String organizerUid;
  final List<String> teamIds;
  final DateTime? startDate;
  final DateTime? endDate;
  final String city;
  final String status; // upcoming, ongoing, finished
  final List<dynamic> standings;

  const TournamentModel({
    required this.id,
    required this.name,
    required this.type,
    required this.organizerUid,
    this.teamIds = const [],
    this.startDate,
    this.endDate,
    required this.city,
    this.status = 'upcoming',
    this.standings = const [],
  });

  factory TournamentModel.fromJson(Map<String, dynamic> json, String documentId) {
    return TournamentModel(
      id: documentId,
      name: json['name'] ?? '',
      type: json['type'] ?? 'league',
      organizerUid: json['organizerUid'] ?? '',
      teamIds: List<String>.from(json['teamIds'] ?? []),
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'].toString()) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'].toString()) : null,
      city: json['city'] ?? '',
      status: json['status'] ?? 'upcoming',
      standings: json['standings'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'organizerUid': organizerUid,
      'teamIds': teamIds,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'city': city,
      'status': status,
      'standings': standings,
    };
  }

  @override
  List<Object?> get props => [id, name, type, organizerUid, teamIds, startDate, endDate, city, status, standings];
}
