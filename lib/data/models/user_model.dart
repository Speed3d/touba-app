import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// 📝 HINT AR: كود اللاعب الدائم — هويته الثابتة التي لا تتغيّر. يُولَّد مرة
  /// عند التسجيل كلاعب، يظهر في ملفه، ويُدخله الكابتن لدعوته/ربطه.
  final String? playerCode;

  // 📝 HINT AR: الاشتراك (للكابتن فقط) — تُكتب من Cloud Functions/الأدمن حصراً
  // (جدار المصداقية). يفتح ميزة التحديات. المصدر الوحيد للحقيقة [subscriptionExpiresAt].
  final DateTime? subscriptionExpiresAt;
  final String? subscriptionStatus; // free_trial | active | expired (للعرض)
  final DateTime? subscriptionActivatedAt;

  const UserModel({
    required this.id,
    required this.name,
    this.email = '',
    required this.phone,
    this.profileImage,
    this.role = 'user',
    this.adminPermissions = const [],
    this.linkedPlayerId,
    this.playerCode,
    this.subscriptionExpiresAt,
    this.subscriptionStatus,
    this.subscriptionActivatedAt,
  });

  bool get isCaptain => role == 'captain';
  bool get isAdmin => role == 'admin';

  /// 📝 HINT AR: حكم — إمّا بدور حكم مباشر أو بصفة منحها الأدمن/التسجيل. نقبل
  /// الاثنين ليظهر بُعد الحكم فوراً بعد التسجيل قبل أن تنعكس صفة CF.
  bool get isReferee =>
      role == 'referee' || adminPermissions.contains('referee');

  /// 📝 HINT AR: الاشتراك فعّال إن لم ينتهِ تاريخه (يشمل التجربة المجانية).
  /// هذه هي قاعدة القفل الوحيدة (مقارنة لحظية، لا حاجة لقلب الحالة).
  bool get isSubscriptionActive =>
      subscriptionExpiresAt != null &&
      subscriptionExpiresAt!.isAfter(DateTime.now());

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
      playerCode: json['playerCode'],
      subscriptionExpiresAt: _parseDate(json['subscriptionExpiresAt']),
      subscriptionStatus: json['subscriptionStatus'],
      subscriptionActivatedAt: _parseDate(json['subscriptionActivatedAt']),
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
      if (playerCode != null) 'playerCode': playerCode,
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
    String? playerCode,
    DateTime? subscriptionExpiresAt,
    String? subscriptionStatus,
    DateTime? subscriptionActivatedAt,
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
      playerCode: playerCode ?? this.playerCode,
      subscriptionExpiresAt:
          subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionActivatedAt:
          subscriptionActivatedAt ?? this.subscriptionActivatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, name, email, phone, profileImage, role, adminPermissions,
        linkedPlayerId, playerCode, subscriptionExpiresAt, subscriptionStatus,
        subscriptionActivatedAt,
      ];
}

// 📝 HINT AR: Firestore يُرجع التواريخ كـ Timestamp — نحوّلها لـ DateTime.
DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is Timestamp) return raw.toDate();
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}
