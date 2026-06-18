import 'package:equatable/equatable.dart';
import '../../../data/models/team_model.dart';
import '../../../data/models/player_model.dart';

abstract class TeamState extends Equatable {
  const TeamState();

  @override
  List<Object?> get props => [];
}

class TeamInitial extends TeamState {}

class TeamLoading extends TeamState {}

class TeamsLoaded extends TeamState {
  final List<TeamModel> teams;

  const TeamsLoaded(this.teams);

  @override
  List<Object?> get props => [teams];
}

class TeamDetailsLoaded extends TeamState {
  final TeamModel team;
  final List<PlayerModel> players; // سجلات لاعبي الفريق

  const TeamDetailsLoaded(this.team, this.players);

  @override
  List<Object?> get props => [team, players];
}

class TeamActionSuccess extends TeamState {
  final String message;
  const TeamActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class TeamError extends TeamState {
  final String message;

  const TeamError(this.message);

  @override
  List<Object?> get props => [message];
}
