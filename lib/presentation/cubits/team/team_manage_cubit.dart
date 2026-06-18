import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'team_manage_state.dart';
import '../../../data/models/player_model.dart';
import '../../../data/models/join_request_model.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../data/repositories/player_repository.dart';

/// 📝 HINT AR: إدارة فريق واحد (للكابتن): التشكيلة + طلبات الانضمام + الدعوات.
/// مُخصّص لشاشة الإدارة (يُوفَّر محلياً عبر BlocProvider).
class TeamManageCubit extends Cubit<TeamManageState> {
  final TeamRepository _teamRepo;
  final PlayerRepository _playerRepo;
  final String teamId;

  TeamManageCubit(this._teamRepo, this._playerRepo, this.teamId)
      : super(TeamManageLoading());

  Future<void> load() async {
    emit(TeamManageLoading());
    await _refresh();
  }

  // 📝 HINT AR: إعادة تحميل صامتة (بلا حالة Loading) بعد كل إجراء.
  Future<void> _refresh() async {
    try {
      final players = await _playerRepo.getPlayersByTeam(teamId);
      final requests = await _teamRepo.getPendingJoinRequests(teamId);
      emit(TeamManageLoaded(requests, players));
    } catch (e) {
      emit(TeamManageError(e.toString()));
    }
  }

  Future<void> addPlayer({
    required String captainId,
    required String name,
    required String position,
    int? shirtNumber,
    String? preferredFoot,
  }) async {
    try {
      final player = PlayerModel(
        id: const Uuid().v4(),
        name: name,
        position: position,
        shirtNumber: shirtNumber,
        preferredFoot: preferredFoot,
        currentTeamId: teamId,
        createdByUid: captainId,
      );
      await _playerRepo.createPlayer(player);
      emit(const TeamManageActionSuccess('تمت إضافة اللاعب للتشكيلة'));
      await _refresh();
    } catch (e) {
      emit(TeamManageError(e.toString()));
      await _refresh();
    }
  }

  Future<void> acceptRequest(JoinRequestModel r) async {
    try {
      await _teamRepo.setJoinRequestStatus(r.id, 'accepted');
      emit(const TeamManageActionSuccess(
          'تم قبول الطلب — سيُضاف اللاعب للتشكيلة تلقائياً'));
      // 📝 HINT AR: إنشاء سجل اللاعب يتم في Cloud Function (onJoinRequestAccepted)
      // بعد لحظات — ننتظر قليلاً ثم نُحدّث لتظهر البطاقة الجديدة فوراً.
      await Future.delayed(const Duration(milliseconds: 1500));
      await _refresh();
    } catch (e) {
      emit(TeamManageError(e.toString()));
      await _refresh();
    }
  }

  Future<void> rejectRequest(JoinRequestModel r) async {
    try {
      await _teamRepo.setJoinRequestStatus(r.id, 'rejected');
      emit(const TeamManageActionSuccess('تم رفض الطلب'));
      await _refresh();
    } catch (e) {
      emit(TeamManageError(e.toString()));
      await _refresh();
    }
  }

  // 📝 HINT AR: تبديل حالة اللاعب أساسي/احتياط (للكابتن).
  Future<void> toggleStarter(PlayerModel p) async {
    try {
      await _playerRepo.setStarter(p.id, !p.isStarter);
      await _refresh();
    } catch (e) {
      emit(TeamManageError(e.toString()));
      await _refresh();
    }
  }

  Future<void> generateInvite(PlayerModel p) async {
    try {
      final code = await _playerRepo.createClaimInvite(p.id, teamId);
      emit(TeamManageInviteReady(code, p.name));
      await _refresh();
    } catch (e) {
      emit(TeamManageError(e.toString()));
    }
  }
}
