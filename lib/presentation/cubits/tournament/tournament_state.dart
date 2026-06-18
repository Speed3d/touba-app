import 'package:equatable/equatable.dart';
import '../../../data/models/tournament_model.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/team_model.dart';

abstract class TournamentState extends Equatable {
  const TournamentState();
  @override
  List<Object?> get props => [];
}

class TournamentInitial extends TournamentState {}

class TournamentLoading extends TournamentState {}

class TournamentsLoaded extends TournamentState {
  final List<TournamentModel> tournaments;
  const TournamentsLoaded(this.tournaments);
  @override
  List<Object?> get props => [tournaments];
}

class TournamentDetailsLoaded extends TournamentState {
  final TournamentModel tournament;
  final List<MatchModel> matches;
  final Map<String, TeamModel> teamsById;
  const TournamentDetailsLoaded(this.tournament, this.matches, this.teamsById);
  @override
  List<Object?> get props => [tournament, matches, teamsById];
}

class TournamentActionSuccess extends TournamentState {
  final String message;
  const TournamentActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class TournamentError extends TournamentState {
  final String message;
  const TournamentError(this.message);
  @override
  List<Object?> get props => [message];
}
