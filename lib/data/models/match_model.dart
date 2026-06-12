import 'package:equatable/equatable.dart';

class MatchModel extends Equatable {
  final String id;
  final String tournamentId;
  final String homeTeamId;
  final String awayTeamId;
  final DateTime? dateTime;
  final String status; // upcoming, live, finished
  final int homeScore;
  final int awayScore;
  final List<dynamic> events; // goals, cards
  final bool resultConfirmed;

  const MatchModel({
    required this.id,
    required this.tournamentId,
    required this.homeTeamId,
    required this.awayTeamId,
    this.dateTime,
    this.status = 'upcoming',
    this.homeScore = 0,
    this.awayScore = 0,
    this.events = const [],
    this.resultConfirmed = false,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json, String documentId) {
    return MatchModel(
      id: documentId,
      tournamentId: json['tournamentId'] ?? '',
      homeTeamId: json['homeTeamId'] ?? '',
      awayTeamId: json['awayTeamId'] ?? '',
      dateTime: json['dateTime'] != null ? DateTime.tryParse(json['dateTime'].toString()) : null,
      status: json['status'] ?? 'upcoming',
      homeScore: json['homeScore'] ?? 0,
      awayScore: json['awayScore'] ?? 0,
      events: json['events'] ?? [],
      resultConfirmed: json['resultConfirmed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tournamentId': tournamentId,
      'homeTeamId': homeTeamId,
      'awayTeamId': awayTeamId,
      'dateTime': dateTime?.toIso8601String(),
      'status': status,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'events': events,
      'resultConfirmed': resultConfirmed,
    };
  }

  @override
  List<Object?> get props => [id, tournamentId, homeTeamId, awayTeamId, dateTime, status, homeScore, awayScore, events, resultConfirmed];
}
