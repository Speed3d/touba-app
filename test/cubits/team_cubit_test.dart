import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:popular_football/data/models/team_model.dart';
import 'package:popular_football/data/repositories/player_repository.dart';
import 'package:popular_football/data/repositories/team_repository.dart';
import 'package:popular_football/presentation/cubits/team/team_cubit.dart';
import 'package:popular_football/presentation/cubits/team/team_state.dart';

class MockTeamRepository extends Mock implements TeamRepository {}

class MockPlayerRepository extends Mock implements PlayerRepository {}

void main() {
  late MockTeamRepository mockTeamRepo;
  late MockPlayerRepository mockPlayerRepo;

  const testTeam = TeamModel(
    id: 'team-1',
    name: 'النسور',
    city: 'بغداد',
    captainId: 'captain-1',
  );

  setUp(() {
    mockTeamRepo = MockTeamRepository();
    mockPlayerRepo = MockPlayerRepository();
  });

  TeamCubit buildCubit() => TeamCubit(mockTeamRepo, mockPlayerRepo);

  group('fetchTeams', () {
    test('emits TeamLoading → TeamsLoaded on success', () async {
      when(() => mockTeamRepo.getTeams())
          .thenAnswer((_) async => [testTeam]);

      final cubit = buildCubit();
      addTearDown(cubit.close);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<TeamLoading>(), isA<TeamsLoaded>()]),
      );

      await cubit.fetchTeams();
      await expectation;

      expect((cubit.state as TeamsLoaded).teams, [testTeam]);
    });

    test('emits TeamLoading → TeamError on failure', () async {
      when(() => mockTeamRepo.getTeams())
          .thenThrow(Exception('حدث خطأ أثناء جلب الفرق'));

      final cubit = buildCubit();
      addTearDown(cubit.close);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<TeamLoading>(), isA<TeamError>()]),
      );

      await cubit.fetchTeams();
      await expectation;
    });

    test('TeamsLoaded contains empty list when no teams exist', () async {
      when(() => mockTeamRepo.getTeams()).thenAnswer((_) async => []);

      final cubit = buildCubit();
      addTearDown(cubit.close);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<TeamLoading>(), isA<TeamsLoaded>()]),
      );

      await cubit.fetchTeams();
      await expectation;

      expect((cubit.state as TeamsLoaded).teams, isEmpty);
    });
  });

  group('fetchTeamDetails', () {
    test('emits TeamLoading → TeamDetailsLoaded on success', () async {
      when(() => mockTeamRepo.getTeamById('team-1'))
          .thenAnswer((_) async => testTeam);
      when(() => mockPlayerRepo.getPlayersByTeam('team-1'))
          .thenAnswer((_) async => []);

      final cubit = buildCubit();
      addTearDown(cubit.close);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<TeamLoading>(), isA<TeamDetailsLoaded>()]),
      );

      await cubit.fetchTeamDetails('team-1');
      await expectation;

      final loaded = cubit.state as TeamDetailsLoaded;
      expect(loaded.team, testTeam);
      expect(loaded.players, isEmpty);
    });

    test('emits TeamLoading → TeamError on repository failure', () async {
      when(() => mockTeamRepo.getTeamById(any()))
          .thenThrow(Exception('الفريق غير موجود'));
      when(() => mockPlayerRepo.getPlayersByTeam(any()))
          .thenAnswer((_) async => []);

      final cubit = buildCubit();
      addTearDown(cubit.close);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<TeamLoading>(), isA<TeamError>()]),
      );

      await cubit.fetchTeamDetails('nonexistent');
      await expectation;
    });
  });

  group('requestToJoinTeam', () {
    test('emits TeamActionSuccess then restores TeamsLoaded on success',
        () async {
      when(() => mockTeamRepo.getTeams()).thenAnswer((_) async => [testTeam]);
      when(() => mockTeamRepo.requestToJoin('team-1', 'user-1', 'علي'))
          .thenAnswer((_) async {});

      final cubit = buildCubit();
      addTearDown(cubit.close);

      // Load teams first
      await cubit.fetchTeams();
      await Future.delayed(Duration.zero);
      expect(cubit.state, isA<TeamsLoaded>());

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<TeamLoading>(),
          isA<TeamActionSuccess>(),
          isA<TeamsLoaded>(),
        ]),
      );

      await cubit.requestToJoinTeam('team-1', 'user-1', 'علي');
      await expectation;

      expect(cubit.state, isA<TeamsLoaded>());
    });

    test('emits TeamLoading → TeamError → TeamsLoaded on failure', () async {
      when(() => mockTeamRepo.getTeams()).thenAnswer((_) async => [testTeam]);
      when(() => mockTeamRepo.requestToJoin(any(), any(), any()))
          .thenThrow(Exception('حدث خطأ أثناء إرسال الطلب'));

      final cubit = buildCubit();
      addTearDown(cubit.close);

      await cubit.fetchTeams();
      await Future.delayed(Duration.zero);
      expect(cubit.state, isA<TeamsLoaded>());

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<TeamLoading>(),
          isA<TeamError>(),
          isA<TeamsLoaded>(), // state restored after error
        ]),
      );

      await cubit.requestToJoinTeam('team-1', 'user-1', 'علي');
      await expectation;
    });
  });
}
