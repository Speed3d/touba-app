import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'tournament_state.dart';
import '../../../data/models/tournament_model.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/team_model.dart';
import '../../../data/models/user_model.dart';
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
    int playerFormat = 6,
    File? logoFile,
    DateTime? startDate,
    int roundIntervalDays = 7,
    String scheduleMode = 'rounds', // 'rounds' | 'daily'
    int matchesPerDay = 1,
    int matchGapMinutes = 90,
    int matchDuration = 45,
    int halvesCount = 2,
    List<UserModel> referees = const [],
    bool isFree = true,
    String? entryInfo,
    // 📝 HINT AR: الوجبة 7 — حسم تعادل الإقصائي + عدد المتأهّلين من كل مجموعة.
    String tieBreakMode = 'extratime_penalties',
    int qualifiersPerGroup = 2,
  }) async {
    emit(TournamentLoading());
    try {
      final id = const Uuid().v4();
      // 📝 HINT AR: رفع صورة البطولة (إن وُجدت) قبل إنشاء المستند.
      String? logoUrl;
      if (logoFile != null) {
        logoUrl = await _tournamentRepo.uploadTournamentImage(id, logoFile);
      }

      // 📝 HINT AR: توزيع المجموعات (قرعة) — يُحفظ على المستند ليُعرض في التفاصيل.
      Map<String, List<String>> groupsMap = const {};
      if (type == 'groups') {
        groupsMap = FixturesService.assignGroups(
            teams.map((t) => t.id).toList(), numberOfGroups ?? 2);
      }

      final tournament = TournamentModel(
        id: id,
        name: name,
        type: type,
        isHomeAndAway: isHomeAndAway,
        generationMode: generationMode,
        numberOfGroups: numberOfGroups,
        playerFormat: playerFormat,
        logoUrl: logoUrl,
        startDate: startDate,
        organizerUid: organizerUid,
        teamIds: teams.map((t) => t.id).toList(),
        city: city,
        status: 'ongoing',
        isFree: isFree,
        entryInfo: entryInfo,
        matchDuration: matchDuration,
        halvesCount: halvesCount,
        tieBreakMode: tieBreakMode,
        qualifiersPerGroup: qualifiersPerGroup,
        groups: groupsMap,
      );
      await _tournamentRepo.createTournament(tournament);

      final teamsById = {for (final t in teams) t.id: t};

      List<Fixture> fixtures = [];
      if (type == 'league') {
        fixtures = FixturesService.roundRobin(tournament.teamIds,
            isHomeAndAway: isHomeAndAway);
      } else if (type == 'knockout') {
        // 📝 HINT AR: شجرة كاملة بروابط ترقية + Bye (تصعد عبر CF عند التأكيد).
        fixtures = FixturesService.knockout(tournament.teamIds,
            isHomeAndAway: isHomeAndAway);
      } else if (type == 'groups') {
        // 📝 HINT AR: مرحلة المجموعات فقط؛ الإقصائي يُولَّد بعد اكتمالها (CF).
        fixtures = FixturesService.groupFixtures(groupsMap,
            isHomeAndAway: isHomeAndAway);
      }

      // 📝 HINT AR: معرّف ثابت لكل مفتاح شجرة (للربط feed بين مباريات الإقصائي).
      final idByKey = <String, String>{};
      for (final f in fixtures) {
        if (f.key.isNotEmpty) idByKey[f.key] = const Uuid().v4();
      }
      String nameOf(String teamId) =>
          teamId.isEmpty ? '' : (teamsById[teamId]?.name ?? '');

      // 📝 HINT AR: جدولة تلقائية — rounds (فاصل بين الجولات) أو daily (توقيت يومي).
      final matches = <MatchModel>[];
      for (var i = 0; i < fixtures.length; i++) {
        final f = fixtures[i];
        DateTime? dt;
        if (startDate != null) {
          if (scheduleMode == 'daily') {
            final day = i ~/ matchesPerDay;
            final slot = i % matchesPerDay;
            final base = DateTime(startDate.year, startDate.month,
                startDate.day, startDate.hour, startDate.minute);
            dt = base.add(
                Duration(days: day, minutes: slot * matchGapMinutes));
          } else {
            dt = startDate.add(
                Duration(days: (f.round - 1) * roundIntervalDays));
          }
        }
        final matchId =
            f.key.isNotEmpty ? idByKey[f.key]! : const Uuid().v4();
        matches.add(MatchModel(
          id: matchId,
          tournamentId: id,
          round: f.round,
          homeTeamId: f.homeId,
          awayTeamId: f.awayId,
          homeTeamName: nameOf(f.homeId),
          awayTeamName: nameOf(f.awayId),
          homeTeamLogo: teamsById[f.homeId]?.logoUrl,
          awayTeamLogo: teamsById[f.awayId]?.logoUrl,
          dateTime: dt,
          stage: f.stage,
          groupName: f.groupName,
          bracketRound: f.bracketRound,
          homeFeedFrom:
              f.homeFeedKey != null ? idByKey[f.homeFeedKey] : null,
          awayFeedFrom:
              f.awayFeedKey != null ? idByKey[f.awayFeedKey] : null,
        ));
      }

      // 📝 HINT AR: توزيع الحكّام عشوائياً — لا يتكرّر حكم في نفس التاريخ/الوقت.
      final withReferees = _distributeReferees(matches, referees);

      if (withReferees.isNotEmpty) {
        await _matchRepo.createMatchesBatch(withReferees);
      }

      final list = await _tournamentRepo.getTournaments();
      emit(TournamentsLoaded(list));
    } catch (e) {
      emit(TournamentError(e.toString()));
    }
  }

  // 📝 HINT AR: يوزّع الحكّام على المباريات عشوائياً مع منع تكرار الحكم في
  // نفس الفتحة الزمنية (نفس dateTime). إن زادت مباريات الفتحة عن عدد الحكّام
  // تبقى الزائدة بلا حكم (يعيّنها المنظّم يدوياً لاحقاً).
  List<MatchModel> _distributeReferees(
      List<MatchModel> matches, List<UserModel> referees) {
    if (referees.isEmpty || matches.isEmpty) return matches;
    final result = List<MatchModel>.from(matches);
    final bySlot = <String, List<int>>{};
    for (var i = 0; i < matches.length; i++) {
      final key = matches[i].dateTime?.millisecondsSinceEpoch.toString() ??
          'slot_${matches[i].round}';
      bySlot.putIfAbsent(key, () => []).add(i);
    }
    for (final indices in bySlot.values) {
      final pool = List<UserModel>.from(referees)..shuffle();
      for (var j = 0; j < indices.length; j++) {
        if (j >= pool.length) break; // مباريات أكثر من الحكّام في هذه الفتحة
        final ref = pool[j];
        result[indices[j]] =
            result[indices[j]].copyWith(refereeId: ref.id, refereeName: ref.name);
      }
    }
    return result;
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

  // 📝 HINT AR: بدء المباراة (status='live') — تظهر في تبويب «جارية» ويبدأ المؤقّت.
  Future<void> startMatch(String tournamentId, String matchId) async {
    try {
      await _matchRepo.startMatch(matchId);
      emit(const TournamentActionSuccess('بدأت المباراة'));
      await fetchDetails(tournamentId);
    } catch (e) {
      emit(TournamentError(e.toString()));
      await fetchDetails(tournamentId);
    }
  }

  // 📝 HINT AR: بدء الشوط التالي (يقوده المنظّم) — يُعيد ضبط بداية المؤقّت.
  Future<void> startNextHalf(
      String tournamentId, String matchId, int half) async {
    try {
      await _matchRepo.startNextHalf(matchId, half);
      emit(TournamentActionSuccess('بدأ الشوط $half'));
      await fetchDetails(tournamentId);
    } catch (e) {
      emit(TournamentError(e.toString()));
      await fetchDetails(tournamentId);
    }
  }

  // 📝 HINT AR: تغيير خطة الكابتن لمباراته (بند 8) ثم إعادة تحميل التفاصيل.
  Future<void> setMatchFormation(String tournamentId, String matchId,
      bool isHome, String formation) async {
    try {
      await _matchRepo.setCaptainFormation(matchId, isHome, formation);
      emit(const TournamentActionSuccess('تم تحديث خطة فريقك لهذه المباراة'));
      await fetchDetails(tournamentId);
    } catch (e) {
      emit(TournamentError(e.toString()));
      await fetchDetails(tournamentId);
    }
  }

  // 📝 HINT AR: تعيين/إلغاء حكم لمباراة (للمنظّم) ثم إعادة تحميل التفاصيل.
  Future<void> assignReferee(String tournamentId, String matchId,
      String? refereeId, String? refereeName) async {
    try {
      await _matchRepo.assignReferee(matchId, refereeId, refereeName);
      emit(TournamentActionSuccess(
          refereeId == null ? 'تم إلغاء تعيين الحكم' : 'تم تعيين الحكم'));
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
    List<Map<String, dynamic>> homeLineup = const [],
    List<Map<String, dynamic>> awayLineup = const [],
    String? homeFormation,
    String? awayFormation,
    // 📝 HINT AR: حسم تعادل الإقصائي (الوجبة 7).
    String? decidedBy,
    int? penaltyHome,
    int? penaltyAway,
    String? advancedTeamId,
  }) async {
    try {
      await _matchRepo.setResult(match.id, home, away,
          events: events,
          lineup: lineup,
          homeLineup: homeLineup,
          awayLineup: awayLineup,
          homeFormation: homeFormation,
          awayFormation: awayFormation,
          decidedBy: decidedBy,
          penaltyHome: penaltyHome,
          penaltyAway: penaltyAway,
          advancedTeamId: advancedTeamId);
      emit(const TournamentActionSuccess(
          'تم حفظ النتيجة — يُحدَّث الترتيب والإحصائيات خلال ثوانٍ'));
      await fetchDetails(tournamentId);
    } catch (e) {
      emit(TournamentError(e.toString()));
      await fetchDetails(tournamentId);
    }
  }
}
