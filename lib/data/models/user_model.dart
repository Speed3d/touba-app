import 'package:equatable/equatable.dart';

/// 📝 HINT AR: حساب المستخدم الشخصي فقط (الهوية الكروية والإحصائيات في
/// [PlayerModel]). يحتوي على بيانات الدخول والتواصل والدور والصلاحيات.
/// عند «المطالبة» بسجل لاعب يُربط الحساب به عبر [linkedPlayerId].
class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;

  /// الدور الأساسي: user | captain | admin
  final String role;

  /// صلاحيات إضافية يمنحها الأدمن (organizer, referee, ...) — للعرض فقط؛
  /// الفرض الأمني يتم عبر Custom Claims في قواعد Firestore.
  final List<String> adminPermissions;

  /// سجل اللاعب المرتبط بهذا الحساب (إن طالب المستخدم بملفه).
  final String? linkedPlayerId;

  const UserModel({
    required this.id,
    required this.name,
    this.email = '',
    required this.phone,
    this.profileImage,
    this.role = 'user',
    this.adminPermissions = const [],
    this.linkedPlayerId,
  });

  bool get isCaptain => role == 'captain';
  bool get isAdmin => role == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    return UserModel(
      id: id,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profileImage: json['profileImage'],
      role: json['role'] ?? 'user',
      adminPermissions:
          List<String>.from(json['adminPermissions'] ?? const []),
      linkedPlayerId: json['linkedPlayerId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      if (profileImage != null) 'profileImage': profileImage,
      'role': role,
      'adminPermissions': adminPermissions,
      if (linkedPlayerId != null) 'linkedPlayerId': linkedPlayerId,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    String? role,
    List<String>? adminPermissions,
    String? linkedPlayerId,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      adminPermissions: adminPermissions ?? this.adminPermissions,
      linkedPlayerId: linkedPlayerId ?? this.linkedPlayerId,
    );
  }

  @override
  List<Object?> get props => [
        id, name, email, phone, profileImage, role, adminPermissions,
        linkedPlayerId,
      ];
}
