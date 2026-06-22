import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/services/auth/auth_service.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/models/user_model.dart';
import '../../../core/error/auth_exceptions.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  final UserRepository _userRepository;
  StreamSubscription<User?>? _authSubscription;

  AuthCubit({
    required AuthService authService,
    required UserRepository userRepository,
  })  : _authService = authService,
        _userRepository = userRepository,
        super(AuthInitial()) {
    _monitorAuthState();
  }

  void _monitorAuthState() {
    _authSubscription = _authService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser == null) {
        if (state is! AuthVisitor) {
          emit(AuthUnauthenticated());
        }
      } else {
        await _fetchUserData(firebaseUser.uid);
      }
    });
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      final userModel = await _userRepository.getUser(uid);
      if (userModel != null) {
        emit(AuthAuthenticated(userModel));
      } else {
        // User exists in Auth but no Firestore document found
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthError('فشل جلب بيانات المستخدم'));
    }
  }

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      await _authService.signInWithEmailAndPassword(email: email, password: password);
      // _monitorAuthState will handle the transition to Authenticated
    } on AuthException catch (e) {
      emit(AuthError(e.message));
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(const AuthError('حدث خطأ غير متوقع'));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    emit(AuthLoading());
    try {
      // 📝 HINT AR: ننشئ حساب المصادقة أولاً ليصبح المستخدم مسجّلاً، فيُسمح
      // بالاستعلام عن تفرّد الهاتف (قواعد users تتطلّب مصادقة لأي استعلام).
      final userCredential = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCredential.user?.uid;
      if (uid == null) {
        emit(const AuthError('تعذّر إنشاء الحساب'));
        emit(AuthUnauthenticated());
        return;
      }

      // التحقق من تفرّد رقم الهاتف (بعد المصادقة)
      final isPhoneUsed = await _userRepository.isPhoneNumberExists(phone);
      if (isPhoneUsed) {
        // تراجع: حذف الحساب اليتيم الذي أنشأناه للتو
        await userCredential.user?.delete();
        emit(const AuthError('رقم الهاتف مستخدم بالفعل لحساب آخر'));
        emit(AuthUnauthenticated());
        return;
      }

      // إنشاء مستند المستخدم ثم إصدار الحالة صراحةً (تفادي سباق المستمع
      // الذي قد يقرأ المستند قبل إنشائه فيُبقي المستخدم خارج التطبيق).
      // 📝 HINT AR: اللاعب (role=user) يحصل على كود لاعب دائم لا يتغيّر — هويته
      // الثابتة التي يُدخلها الكابتن لربطه/دعوته (يبقى عبر كل الانتقالات).
      final newUser = UserModel(
        id: uid,
        name: name,
        email: email,
        phone: phone,
        role: role,
        playerCode: role == 'user' ? _generatePlayerCode() : null,
      );
      await _userRepository.createUser(newUser);
      emit(AuthAuthenticated(newUser));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(const AuthError('حدث خطأ أثناء إنشاء الحساب'));
      emit(AuthUnauthenticated());
    }
  }

  // 📝 HINT AR: كود لاعب من 8 أحرف/أرقام واضحة (بلا أحرف ملتبسة كـ O/0/I/1).
  String _generatePlayerCode([int len = 8]) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(len, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<void> resetPassword(String email) async {
    emit(AuthLoading());
    try {
      await _authService.sendPasswordResetEmail(email);
      emit(AuthUnauthenticated()); // Return to login state
    } on AuthException catch (e) {
      emit(AuthError(e.message));
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(const AuthError('حدث خطأ أثناء إرسال الرابط'));
      emit(AuthUnauthenticated());
    }
  }

  void continueAsVisitor() {
    emit(AuthVisitor());
  }

  // 📝 HINT AR: إعادة جلب بيانات المستخدم الحالي (مثلاً بعد ربط حسابه بلاعب).
  Future<void> refreshUser() async {
    final uid = _authService.currentUser?.uid;
    if (uid != null) await _fetchUserData(uid);
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    if (state is AuthAuthenticated) {
      try {
        await _userRepository.updateUser(updatedUser);
        emit(AuthAuthenticated(updatedUser));
      } catch (e) {
        emit(const AuthError('حدث خطأ أثناء تحديث البيانات'));
        // Re-emit the old state
        final currentUser = (state as AuthAuthenticated).user;
        emit(AuthAuthenticated(currentUser));
      }
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    try {
      await _authService.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(const AuthError('حدث خطأ أثناء تسجيل الخروج'));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
