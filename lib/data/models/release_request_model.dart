import 'package:equatable/equatable.dart';

/// 📝 HINT AR: طلب خروج لاعب من فريقه الحالي. يقدّمه اللاعب، ويبتّه كابتن الفريق
/// (قبول=فكّ ارتباط، رفض). عند الرفض يستطيع اللاعب التصعيد للأدمن (escalated)
/// الذي يفكّ الارتباط قسرياً. القبول/الفكّ يتم في Cloud Function (ذرّي).
class ReleaseRequestModel extends Equatable {
  final String id;
  final String playerId;
  final String teamId;
  final String teamName;
  final String userId; // حساب اللاعب مقدّم الطلب
  final String userName;
  final String status; // pending | accepted | rejected
  final bool escalated; // صُعّد للأدمن بعد الرفض؟

  const ReleaseRequestModel({
    required this.id,
    required this.playerId,
    required this.teamId,
    this.teamName = '',
    required this.userId,
    this.userName = 'لاعب',
    this.status = 'pending',
    this.escalated = false,
  });

  factory ReleaseRequestModel.fromJson(Map<String, dynamic> json, String id) {
    return ReleaseRequestModel(
      id: id,
      playerId: json['playerId'] ?? '',
      teamId: json['teamId'] ?? '',
      teamName: json['teamName'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'لاعب',
      status: json['status'] ?? 'pending',
      escalated: json['escalated'] ?? false,
    );
  }

  @override
  List<Object?> get props =>
      [id, playerId, teamId, teamName, userId, userName, status, escalated];
}
