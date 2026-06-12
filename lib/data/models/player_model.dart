import 'package:equatable/equatable.dart';

class PlayerModel extends Equatable {
  final String id;
  final String name;
  final String photoUrl;
  final DateTime? birthDate;
  final String position;
  final int shirtNumber;
  final String preferredFoot;
  final String status; // active, suspended, injured
  final String currentTeamId;
  final Map<String, dynamic> careerStats;

  const PlayerModel({
    required this.id,
    required this.name,
    this.photoUrl = '',
    this.birthDate,
    required this.position,
    this.shirtNumber = 0,
    this.preferredFoot = 'right',
    this.status = 'active',
    required this.currentTeamId,
    this.careerStats = const {
      'matches': 0, 'goals': 0, 'assists': 0, 'yellowCards': 0, 'redCards': 0,
    },
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json, String documentId) {
    return PlayerModel(
      id: documentId,
      name: json['name'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      birthDate: json['birthDate'] != null ? DateTime.tryParse(json['birthDate'].toString()) : null,
      position: json['position'] ?? '',
      shirtNumber: json['shirtNumber'] ?? 0,
      preferredFoot: json['preferredFoot'] ?? 'right',
      status: json['status'] ?? 'active',
      currentTeamId: json['currentTeamId'] ?? '',
      careerStats: json['careerStats'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'photoUrl': photoUrl,
      'birthDate': birthDate?.toIso8601String(),
      'position': position,
      'shirtNumber': shirtNumber,
      'preferredFoot': preferredFoot,
      'status': status,
      'currentTeamId': currentTeamId,
      'careerStats': careerStats,
    };
  }

  @override
  List<Object?> get props => [id, name, photoUrl, birthDate, position, shirtNumber, preferredFoot, status, currentTeamId, careerStats];
}
