// 📝 HINT AR: إعدادات Firebase لمشروع «طوبة» (touba-3ds).
// وُلِّد يدوياً من google-services.json (أندرويد) و GoogleService-Info.plist (iOS).
// الفائدة: تهيئة Firebase بقيم صريحة على كل المنصات — لا تعتمد التهيئة الأساسية
// على إضافة GoogleService-Info.plist لهدف Xcode (مفيد عند البناء من ويندوز).
// إن أعدتَ توليده مستقبلاً: شغّل `flutterfire configure` وسيستبدل هذا الملف.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// خيارات Firebase الافتراضية حسب المنصة الحالية.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'إعدادات الويب غير مهيّأة — أضِفها عند دعم منصة الويب.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'منصة غير مدعومة لإعدادات Firebase: $defaultTargetPlatform',
        );
    }
  }

  // 📝 HINT AR: قيم تطبيق أندرويد (من google-services.json).
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDA2dPlAr96HWqSsV9Aq_DCPYeYrBhDYTU',
    appId: '1:868610876965:android:4f7300e3b93e01725f81cc',
    messagingSenderId: '868610876965',
    projectId: 'touba-3ds',
    storageBucket: 'touba-3ds.firebasestorage.app',
  );

  // 📝 HINT AR: قيم تطبيق iOS (من GoogleService-Info.plist).
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB55XEHtaEAdBRHhZxpnPIlgBM8JJa1V2o',
    appId: '1:868610876965:ios:69e23a4c72fba8615f81cc',
    messagingSenderId: '868610876965',
    projectId: 'touba-3ds',
    storageBucket: 'touba-3ds.firebasestorage.app',
    iosClientId:
        '868610876965-0tdf9epsg5ap1ehmhimn4lbiflcfvi2c.apps.googleusercontent.com',
    iosBundleId: 'com.speed3d.touba',
  );
}
