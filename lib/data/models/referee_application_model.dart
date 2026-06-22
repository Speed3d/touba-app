import 'package:equatable/equatable.dart';

/// 📝 HINT AR: طلب تحكيم لبطولة معيّنة — يقدّمه أي مستخدم (كابتن/لاعب). يستلمه
/// الأدمن وحده؛ عند موافقته يُمنح صفة حكم ويُحوَّل للمنظّم ليضيفه في بطولته.
class RefereeApplicationModel extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String tournamentId;
  final String tournamentName;
  final String organizerUid;
  final String status; // pending | approved | rejected

  const RefereeApplicationModel({
    required this.id,
    required this.userId,
    this.userName = '',
    this.userPhone = '',
    required this.tournamentId,
    this.tournamentName = '',
    this.organizerUid = '',
    this.status = 'pending',
  });

  factory RefereeApplicationModel.fromJson(
      Map<String, dynamic> json, String id) {
    return RefereeApplicationModel(
      id: id,
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userPhone: json['userPhone'] ?? '',
      tournamentId: json['tournamentId'] ?? '',
      tournamentName: json['tournamentName'] ?? '',
      organizerUid: json['organizerUid'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }

  @override
  List<Object?> get props => [
        id, userId, userName, userPhone, tournamentId, tournamentName,
        organizerUid, status,
      ];
}
