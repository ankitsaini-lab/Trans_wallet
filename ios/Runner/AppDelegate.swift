import Flutter
import UIKit
import app_links

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Block screenshots and screen recording on iOS
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(blockScreenCapture),
      name: UIScreen.capturedDidChangeNotification,
      object: nil
    )

    if let url = AppLinks.shared.getLink(launchOptions: launchOptions) {
      AppLinks.shared.handleLink(url: url)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    AppLinks.shared.handleLink(url: url)
    return super.application(app, open: url, options: options)
  }

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if let url = userActivity.webpageURL {
      AppLinks.shared.handleLink(url: url)
    }
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }

  @objc func blockScreenCapture() {
    if UIScreen.main.isCaptured {
      self.window?.isHidden = true
    } else {
      self.window?.isHidden = false
    }
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
