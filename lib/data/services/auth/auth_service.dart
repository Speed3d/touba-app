import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/error/auth_exceptions.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;

  AuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code), e.code);
    } catch (e) {
      throw AuthException('حدث خطأ غير متوقع أثناء تسجيل الدخول');
    }
  }

  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code), e.code);
    } catch (e) {
      throw AuthException('حدث خطأ غير متوقع أثناء إنشاء الحساب');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e.code), e.code);
    } catch (e) {
      throw AuthException('حدث خطأ غير متوقع أثناء إرسال رابط الاستعادة');
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw AuthException('حدث خطأ أثناء تسجيل الخروج');
    }
  }

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'لا يوجد حساب مرتبط بهذا البريد الإلكتروني';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل لحساب آخر';
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صالحة';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً';
      case 'user-disabled':
        return 'تم إيقاف هذا الحساب من قبل الإدارة';
      case 'too-many-requests':
        return 'تم حظر الحساب مؤقتاً بسبب كثرة المحاولات، يرجى المحاولة لاحقاً';
      default:
        return 'حدث خطأ في المصادقة، يرجى المحاولة مرة أخرى';
    }
  }
}
