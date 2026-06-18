import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'team_state.dart';
import '../../../data/models/team_model.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../data/repositories/player_repository.dart';

class TeamCubit extends Cubit<TeamState> {
  final TeamRepository _teamRepository;
  final PlayerRepository _playerRepository;

  TeamCubit(this._teamRepository, this._playerRepository)
      : super(TeamInitial());

  Future<void> fetchTeams() async {
    emit(TeamLoading());
    try {
      final teams = await _teamRepository.getTeams();
      emit(TeamsLoaded(teams));
    } catch (e) {
      emit(TeamError(e.toString()));
    }
  }

  // 📝 HINT AR: التشكيلة تُجلب من مجموعة players (سجلات اللاعبين) لا من users.
  Future<void> fetchTeamDetails(String teamId) async {
    emit(TeamLoading());
    try {
      final team = await _teamRepository.getTeamById(teamId);
      final players = await _playerRepository.getPlayersByTeam(teamId);
      emit(TeamDetailsLoaded(team, players));
    } catch (e) {
      emit(TeamError(e.toString()));
    }
  }

  Future<void> createTeam({
    required String name,
    required String city,
    String? area,
    required String captainId,
    File? logoFile,
  }) async {
    emit(TeamLoading());
    try {
      // 📝 HINT AR: قاعدة العمل — كابتن واحد = فريق واحد. نمنع إنشاء فريق ثانٍ.
      if (await _teamRepository.captainHasTeam(captainId)) {
        emit(const TeamError('لا يمكنك تأسيس أكثر من فريق واحد'));
        return;
      }

      final teamId = const Uuid().v4();
      // 📝 HINT AR: القيم المحسوبة (ratingPoints/stats) تأخذ افتراضياتها من النموذج.
      final team = TeamModel(
        id: teamId,
        name: name,
        city: city,
        area: area,
        captainId: captainId,
      );
      // 📝 HINT AR: نُنشئ مستند الفريق أولاً، فقاعدة Storage (isTeamCaptain)
      // تقرأ captainId من المستند — لذا يجب أن يوجد قبل رفع الشعار.
      await _teamRepository.createTeam(team);
      if (logoFile != null) {
        final logoUrl = await _teamRepository.uploadTeamLogo(teamId, logoFile);
        await _teamRepository.updateTeamLogo(teamId, logoUrl);
      }
      final teams = await _teamRepository.getTeams();
      emit(TeamsLoaded(teams));
    } catch (e) {
      emit(TeamError(e.toString()));
    }
  }

  Future<void> requestToJoinTeam(
      String teamId, String userId, String userName) async {
    final currentState = state;
    emit(TeamLoading());
    try {
      await _teamRepository.requestToJoin(teamId, userId, userName);
      emit(const TeamActionSuccess(
          'تم إرسال طلب الانضمام، بانتظار موافقة الكابتن'));
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
