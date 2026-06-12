import 'package:connectivity_plus/connectivity_plus.dart';

///  Base Repository - الأساس لجميع الـ Repositories
///
/// هذا الكلاس يحتوي على الدوال المشتركة بين جميع الـ Repositories
///
/// الفوائد:
/// 1. معالجة الأخطاء بشكل موحد (Centralized Error Handling)
/// 2. تجنب تكرار الكود (DRY - Don't Repeat Yourself)
/// 3. سهولة إضافة ميزات مشتركة (مثل: Logging, Caching)
///
/// الاستخدام:
/// ```dart
/// class AuthRepository extends BaseRepository {
///   Future<User?> signIn() async {
///     return handleError(() async {
///       // منطق تسجيل الدخول
///     });
///   }
/// }
/// ```
///
/// ملاحظة: كل Repository يجب أن يرث من BaseRepository
abstract class BaseRepository {
  ///  معالجة الأخطاء بشكل موحد
  ///
  /// هذه الدالة تلف (wrap) أي عملية async وتعالج الأخطاء بشكل موحد
  ///
  /// الفوائد:
  /// 1. مكان واحد لمعالجة جميع الأخطاء
  /// 2. سهولة إضافة Logging أو Analytics
  /// 3. يمكن تحويل الأخطاء لرسائل مفهومة للمستخدم
  ///
  /// مثال:
  /// ```dart
  /// Future<List<Craftsman>> getAllCraftsmen() async {
  ///   return handleError(() async {
  ///     return await _databaseService.getAllActiveCraftsmen();
  ///   });
  /// }
  /// ```
  Future<T> handleError<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e) {
      //  هنا يمكن إضافة:
      // 1. Logging للأخطاء (مثل: Firebase Crashlytics)
      // 2. Analytics (مثل: Firebase Analytics)
      // 3. تحويل الأخطاء لرسائل مفهومة

      // مثال على Logging (يمكن تفعيله لاحقاً):
      // FirebaseCrashlytics.instance.recordError(e, stackTrace);

      // مثال على تحويل الأخطاء:
      // if (e is FirebaseException) {
      //   throw _convertFirebaseError(e);
      // }

      // حالياً: نعيد رمي الخطأ كما هو
      rethrow;
    }
  }

  ///  التحقق من الاتصال بالإنترنت (اختياري)
  ///
  /// مفيد للتحقق قبل تنفيذ عمليات تحتاج إنترنت
  ///
  /// الاستخدام:
  /// ```dart
  /// if (!await hasInternetConnection()) {
  ///   throw 'لا يوجد اتصال بالإنترنت';
  /// }
  /// ```
  ///
  /// ملاحظة: يحتاج package connectivity_plus
  /// يمكن تفعيله لاحقاً عند الحاجة
  ///  التحقق من الاتصال بالإنترنت
  ///
  /// يمكن تفعيله لاحقاً عند الحاجة
  Future<bool> hasInternetConnection() async {
    //  استخدام مكتبة connectivity_plus
    final connectivityResult = await Connectivity().checkConnectivity();

    // ignore: unrelated_type_equality_checks
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }

    // تنويه: الاتصال بالشبكة لا يعني بالضرورة وجود إنترنت حقيقي
    // للتحقق الأدق يمكن عمل Ping لموقع Google مثلاً
    return true;
  }

  ///  تأخير العملية (Debounce) - للمستقبل
  ///
  /// مفيد للعمليات التي تُستدعى بشكل متكرر (مثل: البحث أثناء الكتابة)
  ///
  /// مثال:
  /// ```dart
  /// // بدلاً من البحث مع كل حرف، ننتظر 500ms بعد توقف الكتابة
  /// await debounce(() async {
  ///   return await searchCraftsmen(query);
  /// }, duration: Duration(milliseconds: 500));
  /// ```
  Future<T> debounce<T>(
    Future<T> Function() operation, {
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    // TODO: تطبيق Debounce logic
    // يمكن استخدام Timer للتأخير
    await Future.delayed(duration);
    return await operation();
  }

  ///  Retry Logic - إعادة المحاولة عند الفشل (للمستقبل)
  ///
  /// مفيد للعمليات التي قد تفشل بسبب مشاكل مؤقتة (مثل: ضعف الإنترنت)
  ///
  /// مثال:
  /// ```dart
  /// return retry(() async {
  ///   return await _apiClient.getCraftsmen();
  /// }, maxAttempts: 3);
  /// ```
  Future<T> retry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    while (attempts < maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= maxAttempts) rethrow;
        await Future.delayed(delay * attempts);
      }
    }
    throw Exception('Max retry attempts reached');
  }
}
