import 'package:equatable/equatable.dart';
import '../../../data/models/player_model.dart';
import '../../../data/models/join_request_model.dart';

abstract class TeamManageState extends Equatable {
  const TeamManageState();
  @override
  List<Object?> get props => [];
}

class TeamManageLoading extends TeamManageState {}

class TeamManageLoaded extends TeamManageState {
  final List<JoinRequestModel> requests;
  final List<PlayerModel> players;
  const TeamManageLoaded(this.requests, this.players);
  @override
  List<Object?> get props => [requests, players];
}

class TeamManageActionSuccess extends TeamManageState {
  final String message;
  const TeamManageActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

/// 📝 HINT AR: حالة خاصة لعرض رمز دعوة المطالبة بعد توليده.
class TeamManageInviteReady extends TeamManageState {
  final String code;
  final String playerName;
  const TeamManageInviteReady(this.code, this.playerName);
  @override
  List<Object?> get props => [code, playerName];
}

class TeamManageError extends TeamManageState {
  final String message;
  const TeamManageError(this.message);
  @override
  List<Object?> get props => [message];
}
