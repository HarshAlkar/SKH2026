import Flutter
import UIKit
import UserNotifications
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Maps SDK for iOS only. Restrict by iOS bundle ID in Google Cloud Console.
    // Places Web Service key stays in backend .env as GOOGLE_PLACES_API_KEY — never here.
    GMSServices.provideAPIKey("AIzaSyCumVZ_km61Iu2-sQcpoH42b_uc_szeW3c")
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
