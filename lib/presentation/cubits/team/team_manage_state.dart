import 'package:equatable/equatable.dart';
import '../../../data/models/player_model.dart';
import '../../../data/models/team_model.dart';
import '../../../data/models/join_request_model.dart';
import '../../../data/models/release_request_model.dart';

abstract class TeamManageState extends Equatable {
  const TeamManageState();
  @override
  List<Object?> get props => [];
}

class TeamManageLoading extends TeamManageState {}

class TeamManageLoaded extends TeamManageState {
  final TeamModel team;
  final List<JoinRequestModel> requests;
  final List<ReleaseRequestModel> releaseRequests;
  final List<PlayerModel> players;
  const TeamManageLoaded(this.team, this.requests, this.players,
      {this.releaseRequests = const []});
  @override
  List<Object?> get props => [team, requests, releaseRequests, players];
}

class TeamManageActionSuccess extends TeamManageState {
  final String message;
  const TeamManageActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class TeamManageError extends TeamManageState {
  final String message;
  const TeamManageError(this.message);
  @override
  List<Object?> get props => [message];
}
