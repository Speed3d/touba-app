import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'tournament_state.dart';
import '../../../data/models/tournament_model.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/team_model.dart';
import '../../../data/repositories/tournament_repository.dart';
import '../../../data/repositories/match_repository.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../data/services/fixtures_service.dart';

class TournamentCubit extends Cubit<TournamentState> {
  final TournamentRepository _tournamentRepo;
  final MatchRepository _matchRepo;
  final TeamRepository _teamRepo;

  TournamentCubit(this._tournamentRepo, this._matchRepo, this._teamRepo)
      : super(TournamentInitial());

  Future<void> fetchTournaments() async {
    emit(TournamentLoading());
    try {
      final list = await _tournamentRepo.getTournaments();
      emit(TournamentsLoaded(list));
    } catch (e) {
      emit(TournamentError(e.toString()));
    }
  }

  // 📝 HINT AR: ينشئ بطولة دوري ويولّد جدولها تلقائياً (Round-Robin) دفعة واحدة.
  Future<void> createTournament({
    required String name,
    required String city,
    required String organizerUid,
    required List<TeamModel> teams,
    String type = 'league',
    bool isHomeAndAway = false,
    String generationMode = 'full_tree',
    int? numberOfGroups,
    int playerFormat = 7,
  }) async {
    emit(TournamentLoading());
    try {
      final id = const Uuid().v4();
      final tournament = TournamentModel(
        id: id,
        name: name,
        type: type,
        isHomeAndAway: isHomeAndAway,
        generationMode: generationMode,
        numberOfGroups: numberOfGroups,
        playerFormat: playerFormat,
        organizerUid: organizerUid,
        teamIds: teams.map((t) => t.id).toList(),
        city: city,
        status: 'ongoing',
      );
      await _tournamentRepo.createTournament(tournament);

      final teamsById = {for (final t in teams) t.id: t};
      
      List<Fixture> fixtures = [];
      if (type == 'league') {
        fixtures = FixturesService.roundRobin(tournament.teamIds, isHomeAndAway: isHomeAndAway);
      } else if (type == 'knockout') {
        fixtures = FixturesService.knockout(tournament.teamIds, isHomeAndAway: isHomeAndAway, generationMode: generationMode);
      } else if (type == 'groups') {
        fixtures = FixturesService.groups(tournament.teamIds, numberOfGroups: numberOfGroups ?? 2, isHomeAndAway: isHomeAndAway);
      }

      final matches = fixtures
          .map((f) => MatchModel(
                id: const Uuid().v4(),
                tournamentId: id,
                round: f.round,
                homeTeamId: f.homeId,
                awayTeamId: f.awayId,
                homeTeamName: teamsById[f.homeId]?.name ?? (f.homeId.startsWith('TBD') ? f.homeId : ''),
                awayTeamName: teamsById[f.awayId]?.name ?? (f.awayId.startsWith('TBD') ? f.awayId : ''),
              ))
          .toList();
      if (matches.isNotEmpty) await _matchRepo.createMatchesBatch(matches);

      final list = await _tournamentRepo.getTournaments();
      emit(TournamentsLoaded(list));
    } catch (e) {
      emit(TournamentError(e.toString()));
    }
  }

  Future<void> fetchDetails(String tournamentId) async {
    emit(TournamentLoading());
    try {
      final tournament = await _tournamentRepo.getTournamentById(tournamentId);
      final matches = await _matchRepo.getMatchesByTournament(tournamentId);
      final teams = await _teamRepo.getTeamsByIds(tournament.teamIds);
      final teamsById = {for (final t in teams) t.id: t};
      emit(TournamentDetailsLoaded(tournament, matches, teamsById));
    } catch (e) {
      emit(TournamentError(e.toString()));
    }
  }

  // 📝 HINT AR: جدولة موعد مباراة (للمنظّم) — يحدّث dateTime فقط ثم يُعيد
  // تحميل تفاصيل البطولة لتنعكس التغييرات في الواجهة فوراً.
  Future<void> scheduleMatch(
      String tournamentId, String matchId, DateTime dateTime) async {
    try {
      await _matchRepo.scheduleMatch(matchId, dateTime);
      emit(const TournamentActionSuccess('تم تحديد موعد المباراة بنجاح'));
      await fetchDetails(tournamentId);
    } catch (e) {
      emit(TournamentError(e.toString()));
      await fetchDetails(tournamentId);
    }
  }

  // 📝 HINT AR: إدخال النتيجة + أحداثها (للمنظّم) — يؤكّدها فتُشغّل CF التي
  // تحدّث الترتيب وإحصائيات اللاعبين (من الأحداث).
  Future<void> enterResult(
    String tournamentId,
    MatchModel match,
    int home,
    int away, {
    List<Map<String, dynamic>> events = const [],
    List<String> lineup = const [],
  }) async {
    try {
      await _matchRepo.setResult(match.id, home, away,
          events: events, lineup: lineup);
      emit(const TournamentActionSuccess(
          'تم حفظ النتيجة — يُحدَّث الترتيب والإحصائيات خلال ثوانٍ'));
      await fetchDetails(tournamentId);
    } catch (e) {
      emit(TournamentError(e.toString()));
      await fetchDetails(tournamentId);
    }
  }
}
