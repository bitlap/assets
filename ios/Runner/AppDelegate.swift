import BackgroundTasks
import Flutter
import UIKit

let profitBackgroundTaskIdentifier = "org.bitlap.assets.profitSnapshotTask"

@main
@objc class AppDelegate: FlutterAppDelegate {
  var flutterEngine: FlutterEngine!

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 创建显式 FlutterEngine
    flutterEngine = FlutterEngine(name: "assets engine")
    flutterEngine.run()
    GeneratedPluginRegistrant.register(with: flutterEngine)

    // 注册后台任务
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: profitBackgroundTaskIdentifier,
      using: nil
    ) { task in
      self.handleProfitSnapshotTask(task: task as! BGAppRefreshTask)
    }

    // 设置 iCloud MethodChannel
    let channel = FlutterMethodChannel(
      name: "org.bitlap.assets/icloud",
      binaryMessenger: flutterEngine as! FlutterBinaryMessenger)
    channel.setMethodCallHandler { (call, result) in
      if call.method == "getContainerUrl" {
        let url = FileManager.default.url(
          forUbiquityContainerIdentifier: nil)
        result(url?.appendingPathComponent("Documents").path)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // 创建 window 和 FlutterViewController
    let window = UIWindow(frame: UIScreen.main.bounds)
    window.rootViewController = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
    window.makeKeyAndVisible()
    self.window = window

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidEnterBackground(_ application: UIApplication) {
    scheduleProfitSnapshotTask()
  }

  private func scheduleProfitSnapshotTask() {
    let request = BGAppRefreshTaskRequest(identifier: profitBackgroundTaskIdentifier)
    request.earliestBeginDate = Date(timeIntervalSinceNow: 3600)
    do {
      try BGTaskScheduler.shared.submit(request)
    } catch {
      print("[BGTask] 提交后台任务失败: \(error)")
    }
  }

  private func handleProfitSnapshotTask(task: BGAppRefreshTask) {
    scheduleProfitSnapshotTask()

    task.expirationHandler = {
      task.setTaskCompleted(success: false)
    }

    // 通知 Dart 端执行收益快照
    let channel = FlutterMethodChannel(
      name: "org.bitlap.assets/background_profit",
      binaryMessenger: flutterEngine.binaryMessenger)
    channel.invokeMethod("recordProfitSnapshot", arguments: nil) { result in
      task.setTaskCompleted(success: result != nil)
    }
  }
}
