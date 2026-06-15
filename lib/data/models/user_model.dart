import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? profileImage;
  final String role; // 'player', 'captain', 'admin'
  final String? teamId;
  
  // Football specific fields
  final String? position;
  final String? preferredFoot;
  final int? height;
  final int? weight;
  final String? bio;

  // Stats
  final int goals;
  final int assists;
  final double rating;
  final int matchesPlayed;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.profileImage,
    this.role = 'player',
    this.teamId,
    this.position,
    this.preferredFoot,
    this.height,
    this.weight,
    this.bio,
    this.goals = 0,
    this.assists = 0,
    this.rating = 0.0,
    this.matchesPlayed = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    return UserModel(
      id: id,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      profileImage: json['profileImage'],
      role: json['role'] ?? 'player',
      teamId: json['teamId'],
      position: json['position'],
      preferredFoot: json['preferredFoot'],
      height: json['height'],
      weight: json['weight'],
      bio: json['bio'],
      goals: json['goals'] ?? 0,
      assists: json['assists'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      matchesPlayed: json['matchesPlayed'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      if (profileImage != null) 'profileImage': profileImage,
      'role': role,
      if (teamId != null) 'teamId': teamId,
      if (position != null) 'position': position,
      if (preferredFoot != null) 'preferredFoot': preferredFoot,
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (bio != null) 'bio': bio,
      'goals': goals,
      'assists': assists,
      'rating': rating,
      'matchesPlayed': matchesPlayed,
    };
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? profileImage,
    String? role,
    String? teamId,
    String? position,
    String? preferredFoot,
    int? height,
    int? weight,
    String? bio,
    int? goals,
    int? assists,
    double? rating,
    int? matchesPlayed,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      teamId: teamId ?? this.teamId,
      position: position ?? this.position,
      preferredFoot: preferredFoot ?? this.preferredFoot,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bio: bio ?? this.bio,
      goals: goals ?? this.goals,
      assists: assists ?? this.assists,
      rating: rating ?? this.rating,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        profileImage,
        role,
        teamId,
        position,
        preferredFoot,
        height,
        weight,
        bio,
        goals,
        assists,
        rating,
        matchesPlayed,
      ];
}
