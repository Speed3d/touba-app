import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // ضمان تسجيل الجهاز في APNs صراحةً (بدل الاعتماد على swizzling فقط).
    // FlutterAppDelegate يلتزم بـ UNUserNotificationCenterDelegate، و
    // إضافة firebase_messaging تلتقط الـ APNS token عبر method swizzling
    // عند نجاح didRegisterForRemoteNotificationsWithDeviceToken.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
