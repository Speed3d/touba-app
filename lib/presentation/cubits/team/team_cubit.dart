import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'team_state.dart';
import '../../../data/models/team_model.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../data/repositories/user_repository.dart';

class TeamCubit extends Cubit<TeamState> {
  final TeamRepository _teamRepository;
  final UserRepository _userRepository;

  TeamCubit(this._teamRepository, this._userRepository) : super(TeamInitial());

  Future<void> fetchTeams() async {
    emit(TeamLoading());
    try {
      final teams = await _teamRepository.getTeams();
      emit(TeamsLoaded(teams));
    } catch (e) {
      emit(TeamError(e.toString()));
    }
  }

  Future<void> fetchTeamDetails(String teamId) async {
    emit(TeamLoading());
    try {
      final team = await _teamRepository.getTeamById(teamId);
      
      // We must fetch the captain too since captainId might not be in playersIds
      List<String> userIdsToFetch = [team.captainId, ...team.playersIds];
      // Remove duplicates just in case
      userIdsToFetch = userIdsToFetch.toSet().toList();

      final players = await _userRepository.getPlayersByIds(userIdsToFetch);
      
      emit(TeamDetailsLoaded(team, players));
    } catch (e) {
      emit(TeamError(e.toString()));
    }
  }

  Future<void> createTeam({
    required String name,
    required String city,
    required String captainId,
    File? logoFile,
  }) async {
    emit(TeamLoading());
    try {
      final teamId = const Uuid().v4();
      String? logoUrl;

      if (logoFile != null) {
        logoUrl = await _teamRepository.uploadTeamLogo(teamId, logoFile);
      }

      final team = TeamModel(
        id: teamId,
        name: name,
        city: city,
        logoUrl: logoUrl,
        captainId: captainId,
        playersIds: const [], // initially empty, captain is recognized by captainId
      );

      await _teamRepository.createTeam(team);
      
      // Refresh teams list
      final teams = await _teamRepository.getTeams();
      emit(TeamsLoaded(teams));
    } catch (e) {
      emit(TeamError(e.toString()));
    }
  }

  Future<void> requestToJoinTeam(String teamId, String userId) async {
    final currentState = state;
    emit(TeamLoading());
    try {
      await _teamRepository.requestToJoin(teamId, userId);
      emit(const TeamActionSuccess('تم إرسال طلب الانضمام بنجاح، بانتظار موافقة الكابتن'));
      // Restore previous state after success so UI doesn't break
      if (currentState is TeamsLoaded) {
        emit(TeamsLoaded(currentState.teams));
      } else if (currentState is TeamDetailsLoaded) {
        emit(TeamDetailsLoaded(currentState.team, currentState.players));
      } else {
        fetchTeams();
      }
    } catch (e) {
      emit(TeamError(e.toString()));
      if (currentState is TeamsLoaded || currentState is TeamDetailsLoaded) {
        emit(currentState);
      }
    }
  }
}
