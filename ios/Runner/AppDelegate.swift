import BackgroundTasks
import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate {
  var flutterEngine: FlutterEngine!

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 14.0, *) {
      WorkmanagerDebug.setCurrent(LoggingDebugHandler())
    }

    if #available(iOS 13.0, *) {
      BGTaskScheduler.shared.register(
        forTaskWithIdentifier: "profit-snapshot",
        using: nil
      ) { task in
        if let task = task as? BGAppRefreshTask {
          WorkmanagerPlugin.handlePeriodicTask(
            identifier: "profit-snapshot",
            task: task,
            earliestBeginInSeconds: 10 * 60
          )
        }
      }
    }

    flutterEngine = FlutterEngine(name: "assets engine")
    flutterEngine.run()
    GeneratedPluginRegistrant.register(with: flutterEngine)

    let iCloudChannel = FlutterMethodChannel(
      name: "org.bitlap.assets/icloud",
      binaryMessenger: flutterEngine.binaryMessenger)
    iCloudChannel.setMethodCallHandler { (call, result) in
      if call.method == "getContainerUrl" {
        let url = FileManager.default.url(forUbiquityContainerIdentifier: nil)
        result(url?.appendingPathComponent("Documents").path)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    let window = UIWindow(frame: UIScreen.main.bounds)
    window.rootViewController = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
    window.makeKeyAndVisible()
    self.window = window

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
