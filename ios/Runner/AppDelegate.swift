import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Google Maps API 키 설정
    GMSServices.provideAPIKey("AIzaSyCGgn6uldBF3G9iBsAoRgYFrP4w4Ptd7uU")

    // iOS 전용 설정
    if #available(iOS 15.0, *) {
      // iOS 15+ 전용 설정
      let appearance = UINavigationBarAppearance()
      appearance.configureWithOpaqueBackground()
      appearance.backgroundColor = UIColor.systemGreen
      appearance.titleTextAttributes = [.foregroundColor: UIColor.white]

      UINavigationBar.appearance().standardAppearance = appearance
      UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    // Flutter 플러그인 등록
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
