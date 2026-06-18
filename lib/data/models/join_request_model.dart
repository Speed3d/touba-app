import 'package:equatable/equatable.dart';

/// 📝 HINT AR: طلب انضمام لاعب لديه حساب إلى فريق — يقبله/يرفضه الكابتن.
/// عند القبول تتولّى Cloud Function `onJoinRequestAccepted` إنشاء سجل اللاعب.
class JoinRequestModel extends Equatable {
  final String id;
  final String teamId;
  final String userId;
  final String userName;
  final String status; // pending | accepted | rejected

  const JoinRequestModel({
    required this.id,
    required this.teamId,
    required this.userId,
    this.userName = 'لاعب',
    this.status = 'pending',
  });

  factory JoinRequestModel.fromJson(Map<String, dynamic> json, String id) {
    return JoinRequestModel(
      id: id,
      teamId: json['teamId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'لاعب',
      status: json['status'] ?? 'pending',
    );
  }

  @override
  List<Object?> get props => [id, teamId, userId, userName, status];
}
