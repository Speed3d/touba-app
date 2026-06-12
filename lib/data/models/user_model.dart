import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? profileImage;
  final String role; // 'player', 'captain', 'admin'
  final String? teamId;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.profileImage,
    this.role = 'player',
    this.teamId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    return UserModel(
      id: id,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      profileImage: json['profileImage'],
      role: json['role'] ?? 'player',
      teamId: json['teamId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      if (profileImage != null) 'profileImage': profileImage,
      'role': role,
      if (teamId != null) 'teamId': teamId,
    };
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? profileImage,
    String? role,
    String? teamId,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      teamId: teamId ?? this.teamId,
    );
  }

  @override
  List<Object?> get props => [id, name, phone, profileImage, role, teamId];
}
