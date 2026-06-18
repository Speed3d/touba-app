import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:popular_football/core/error/auth_exceptions.dart';
import 'package:popular_football/data/models/user_model.dart';
import 'package:popular_football/data/repositories/user_repository.dart';
import 'package:popular_football/data/services/auth/auth_service.dart';
import 'package:popular_football/presentation/cubits/auth/auth_cubit.dart';
import 'package:popular_football/presentation/cubits/auth/auth_state.dart';

class MockAuthService extends Mock implements AuthService {}

class MockUserRepository extends Mock implements UserRepository {}

class MockUserCredential extends Mock implements UserCredential {}

void main() {
  late MockAuthService mockAuthService;
  late MockUserRepository mockUserRepository;
  late StreamController<User?> authStream;

  const testUser = UserModel(
    id: 'test-uid',
    name: 'لاعب تجريبي',
    email: 'test@example.com',
    phone: '07701234567',
  );

  setUpAll(() {
    registerFallbackValue(testUser);
  });

  setUp(() {
    mockAuthService = MockAuthService();
    mockUserRepository = MockUserRepository();
    authStream = StreamController<User?>.broadcast();
    when(() => mockAuthService.authStateChanges)
        .thenAnswer((_) => authStream.stream);
  });

  tearDown(() async {
    await authStream.close();
  });

  AuthCubit buildCubit() => AuthCubit(
        authService: mockAuthService,
        userRepository: mockUserRepository,
      );

  group('continueAsVisitor', () {
    test('emits AuthVisitor', () async {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      cubit.continueAsVisitor();

      expect(cubit.state, isA<AuthVisitor>());
    });
  });

  group('login', () {
    test('emits AuthLoading → AuthError → AuthUnauthenticated on AuthException',
        () async {
      when(() => mockAuthService.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(AuthException('كلمة المرور غير صحيحة', 'wrong-password'));

      final cubit = buildCubit();
      addTearDown(cubit.close);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthState>(
              (s) => s is AuthError && s.message == 'كلمة المرور غير صحيحة'),
          isA<AuthUnauthenticated>(),
        ]),
      );

      await cubit.login('test@example.com', 'wrong');
      await expectation;
    });

    test(
        'emits AuthLoading → AuthError → AuthUnauthenticated on unknown exception',
        () async {
      when(() => mockAuthService.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(Exception('unexpected'));

      final cubit = buildCubit();
      addTearDown(cubit.close);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthError>(),
          isA<AuthUnauthenticated>(),
        ]),
      );

      await cubit.login('test@example.com', 'pass');
      await expectation;
    });
  });

  group('logout', () {
    test('emits AuthLoading → AuthUnauthenticated on success', () async {
      when(() => mockAuthService.signOut()).thenAnswer((_) async {});

      final cubit = buildCubit();
      addTearDown(cubit.close);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthUnauthenticated>()]),
      );

      await cubit.logout();
      await expectation;
    });

    test('emits AuthLoading → AuthError on signOut failure', () async {
      when(() => mockAuthService.signOut())
          .thenThrow(Exception('network error'));

      final cubit = buildCubit();
      addTearDown(cubit.close);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthError>()]),
      );

      await cubit.logout();
      await expectation;
    });
  });

  group('auth stream integration', () {
    test('emits AuthAuthenticated when stream receives logged-in user',
        () async {
      final mockFirebaseUser = MockUser(uid: 'test-uid');
      when(() => mockUserRepository.getUser('test-uid'))
          .thenAnswer((_) async => testUser);

      final cubit = buildCubit();
      addTearDown(cubit.close);

      final states = <AuthState>[];
      final sub = cubit.stream.listen(states.add);

      authStream.add(mockFirebaseUser);
      await Future.delayed(Duration.zero);
      await sub.cancel();

      expect(states.last, isA<AuthAuthenticated>());
      expect((states.last as AuthAuthenticated).user, testUser);
    });

    test('emits AuthUnauthenticated when stream receives null', () async {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      final states = <AuthState>[];
      final sub = cubit.stream.listen(states.add);

      authStream.add(null);
      await Future.delayed(Duration.zero);
      await sub.cancel();

      expect(states.last, isA<AuthUnauthenticated>());
    });

    test('does not re-emit when already AuthVisitor and stream emits null',
        () async {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      cubit.continueAsVisitor();

      final states = <AuthState>[];
      final sub = cubit.stream.listen(states.add);

      authStream.add(null);
      await Future.delayed(Duration.zero);
      await sub.cancel();

      // AuthCubit skips emit when already AuthVisitor
      expect(states, isEmpty);
    });
  });

  group('updateProfile', () {
    test('emits updated AuthAuthenticated when currently authenticated',
        () async {
      final mockFirebaseUser = MockUser(uid: 'test-uid');
      when(() => mockUserRepository.getUser('test-uid'))
          .thenAnswer((_) async => testUser);
      when(() => mockUserRepository.updateUser(any()))
          .thenAnswer((_) async {});

      final cubit = buildCubit();
      addTearDown(cubit.close);

      // Trigger authentication via stream and wait for it to settle
      authStream.add(mockFirebaseUser);
      await Future.delayed(Duration.zero);
      expect(cubit.state, isA<AuthAuthenticated>());

      final updatedUser = testUser.copyWith(name: 'اسم جديد');

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          predicate<AuthState>(
              (s) => s is AuthAuthenticated && s.user.name == 'اسم جديد'),
        ]),
      );

      await cubit.updateProfile(updatedUser);
      await expectation;
    });

    test('emits nothing when not authenticated', () async {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      final states = <AuthState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.updateProfile(testUser);
      await Future.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      // No emissions because state is AuthInitial (not AuthAuthenticated)
      expect(states, isEmpty);
    });
  });
}
