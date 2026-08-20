import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// 📝 HINT AR: معالج ومترجم أخطاء المصادقة و Firebase Auth
/// يحول كود الخطأ أو رسالته إلى نص مترجم تلقائياً بحسب لغة الواجهة الحالية.
class AuthErrorResolver {
  AuthErrorResolver._();

  static String resolve(BuildContext context, String codeOrMessage) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return codeOrMessage;

    final trimmed = codeOrMessage.trim();

    switch (trimmed) {
      case 'user-not-found':
      case 'لا يوجد حساب مرتبط بهذا البريد الإلكتروني':
        return l10n.authErrorUserNotFound;
      case 'wrong-password':
      case 'invalid-credential':
      case 'كلمة المرور غير صحيحة':
        return l10n.authErrorWrongPassword;
      case 'email-already-in-use':
      case 'البريد الإلكتروني مستخدم بالفعل لحساب آخر':
        return l10n.authErrorEmailAlreadyInUse;
      case 'invalid-email':
      case 'صيغة البريد الإلكتروني غير صالحة':
        return l10n.authErrorInvalidEmail;
      case 'weak-password':
      case 'كلمة المرور ضعيفة جداً':
        return l10n.authErrorWeakPassword;
      case 'user-disabled':
      case 'تم إيقاف هذا الحساب من قبل الإدارة':
        return l10n.authErrorUserDisabled;
      case 'too-many-requests':
      case 'تم حظر الحساب مؤقتاً بسبب كثرة المحاولات، يرجى المحاولة لاحقاً':
        return l10n.authErrorTooManyRequests;
      case 'network-request-failed':
        return l10n.authErrorNetworkFailed;
      case 'phone_used':
      case 'phone-already-in-use':
      case 'رقم الهاتف مستخدم بالفعل لحساب آخر':
        return l10n.authErrorPhoneAlreadyInUse;
      case 'fetch_user_failed':
      case 'fetch-user-failed':
      case 'فشل جلب بيانات المستخدم':
        return l10n.authErrorFetchUserDataFailed;
      case 'create_account_failed':
      case 'create-account-failed':
      case 'تعذّر إنشاء الحساب':
      case 'حدث خطأ أثناء إنشاء الحساب':
      case 'حدث خطأ غير متوقع أثناء إنشاء الحساب':
        return l10n.authErrorCreateAccountFailed;
      case 'reset_password_failed':
      case 'reset-password-failed':
      case 'حدث خطأ أثناء إرسال الرابط':
      case 'حدث خطأ غير متوقع أثناء إرسال رابط الاستعادة':
        return l10n.authErrorResetPasswordFailed;
      case 'update_profile_failed':
      case 'update-profile-failed':
      case 'حدث خطأ أثناء تحديث البيانات':
        return l10n.authErrorUpdateProfileFailed;
      case 'logout_failed':
      case 'logout-failed':
      case 'حدث خطأ أثناء تسجيل الخروج':
        return l10n.authErrorLogoutFailed;
      case 'unknown_error':
      case 'حدث خطأ غير متوقع':
      case 'حدث خطأ في المصادقة، يرجى المحاولة مرة أخرى':
      case 'حدث خطأ غير متوقع أثناء تسجيل الدخول':
        return l10n.authErrorGeneric;
      default:
        return trimmed.isNotEmpty ? trimmed : l10n.authErrorGeneric;
    }
  }
}
