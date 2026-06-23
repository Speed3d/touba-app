import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'team_manage_state.dart';
import '../../../data/models/player_model.dart';
import '../../../data/models/join_request_model.dart';
import '../../../data/models/release_request_model.dart';
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
      final team = await _teamRepo.getTeamById(teamId);
      final players = await _playerRepo.getPlayersByTeam(teamId);
      final requests = await _teamRepo.getPendingJoinRequests(teamId);
      final releases = await _teamRepo.getPendingReleaseRequests(teamId);
      emit(TeamManageLoaded(team, requests, players, releaseRequests: releases));
    } catch (e) {
      emit(TeamManageError(e.toString()));
    }
  }

  // 📝 HINT AR: حفظ خطة الفريق الأساسية (يختارها الكابتن من القوالب الثابتة).
  Future<void> setFormation(String formation) async {
    try {
      await _teamRepo.setFormation(teamId, formation);
      emit(const TeamManageActionSuccess('تم حفظ خطة الفريق'));
      await _refresh();
    } catch (e) {
      emit(TeamManageError(e.toString()));
      await _refresh();
    }
  }

  // 📝 HINT AR: حفظ الخطة + تعيين اللاعبين الصريح على خاناتها (تشكيلة تفاعلية).
  Future<void> setLineup(String formation, List<String> slots) async {
    try {
      await _teamRepo.setLineup(teamId, formation, slots);
      emit(const TeamManageActionSuccess('تم حفظ تشكيلة الفريق'));
      await _refresh();
    } catch (e) {
      emit(TeamManageError(e.toString()));
      await _refresh();
    }
  }

  // 📝 HINT AR: تعيين رقم قميص للاعب مع منع تكرار الرقم داخل الفريق.
  Future<void> setShirtNumber(PlayerModel p, int? number) async {
    final st = state;
    if (number != null && st is TeamManageLoaded) {
      final dup =
          st.players.any((o) => o.id != p.id && o.shirtNumber == number);
      if (dup) {
        emit(TeamManageError('الرقم $number مستخدم من لاعب آخر'));
        await _refresh();
        return;
      }
    }
    try {
      await _playerRepo.setShirtNumber(p.id, number);
      emit(const TeamManageActionSuccess('تم تحديث رقم اللاعب'));
      await _refresh();
    } catch (e) {
      emit(TeamManageError(e.toString()));
      await _refresh();
    }
  }

  // 📝 HINT AR: قبول طلب خروج = فكّ ارتباط (CF يحذف السجل ويحرّر الحساب).
  Future<void> acceptRelease(ReleaseRequestModel r) async {
    try {
      await _teamRepo.setReleaseRequestStatus(r.id, 'accepted');
      emit(const TeamManageActionSuccess('تم قبول الخروج وفكّ ارتباط اللاعب'));
      await Future.delayed(const Duration(milliseconds: 1200));
      await _refresh();
    } catch (e) {
      emit(TeamManageError(e.toString()));
      await _refresh();
    }
  }

  Future<void> rejectRelease(ReleaseRequestModel r) async {
    try {
      await _teamRepo.setReleaseRequestStatus(r.id, 'rejected');
      emit(const TeamManageActionSuccess('تم رفض طلب الخروج'));
      await _refresh();
    } catch (e) {
      emit(TeamManageError(e.toString()));
      await _refresh();
    }
  }

  Future<void> addPlayer({
    required String captainId,
    required String name,
    required String position,
    int? shirtNumber,
    String? preferredFoot,
  }) async {
    // 📝 HINT AR: منع تكرار رقم القميص داخل الفريق.
    final st = state;
    if (shirtNumber != null &&
        st is TeamManageLoaded &&
        st.players.any((o) => o.shirtNumber == shirtNumber)) {
      emit(TeamManageError('الرقم $shirtNumber مستخدم — اختر رقماً آخر'));
      await _refresh();
      return;
    }
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

  // 📝 HINT AR: تعيين مركز اللاعب (للكابتن).
  Future<void> setPosition(PlayerModel p, String position) async {
    try {
      await _playerRepo.setPosition(p.id, position);
      await _refresh();
    } catch (e) {
      emit(TeamManageError(e.toString()));
      await _refresh();
    }
  }

}
