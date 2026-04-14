import Flutter
import UIKit
import GoogleMaps
import flutter_local_notifications
import FirebaseAuth

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self // Set delegate to self
    }
    GMSServices.provideAPIKey("AIzaSyDLRt7r36ovJdIhsn4GeUV267P_taJaWpY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    // Handle Firebase Auth callbacks (phone auth / OAuth redirects) before Flutter routing.
    if Auth.auth().canHandle(url) {
      return true
    }

    return super.application(app, open: url, options: options)
  }

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if let incomingURL = userActivity.webpageURL,
       Auth.auth().canHandle(incomingURL) {
      return true
    }

    return super.application(
      application,
      continue: userActivity,
      restorationHandler: restorationHandler
    )
  }
}
