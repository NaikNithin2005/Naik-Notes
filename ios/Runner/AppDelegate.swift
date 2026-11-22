import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UIPencilInteractionDelegate, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private var isPencilChannelsSetup = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as? FlutterViewController
    if let flutterViewController = controller {
      setupApplePencilChannels(controller: flutterViewController)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  func setupApplePencilChannels(controller: FlutterViewController) {
    guard !isPencilChannelsSetup else { return }
    isPencilChannelsSetup = true

    let methodChannel = FlutterMethodChannel(
      name: "naik_notes/apple_pencil",
      binaryMessenger: controller.binaryMessenger
    )
    let eventChannel = FlutterEventChannel(
      name: "naik_notes/apple_pencil/events",
      binaryMessenger: controller.binaryMessenger
    )

    eventChannel.setStreamHandler(self)

    methodChannel.setMethodCallHandler { (call, result) in
      if call.method == "getPencilCapabilities" {
        var hasDoubleTap = false
        if #available(iOS 12.1, *) {
          hasDoubleTap = true
        }

        var hasSqueeze = false
        if #available(iOS 17.5, *) {
          hasSqueeze = true
        }

        let capabilities: [String: Any] = [
          "hasPressure": true,
          "hasTilt": true,
          "hasHover": true,
          "hasEraserTip": false,
          "hasBarrelButtons": false,
          "hasDoubleTap": hasDoubleTap,
          "hasSqueeze": hasSqueeze,
          "stylusType": "applePencil"
        ]
        result(capabilities)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // Attach UIPencilInteraction to root view controller
    if #available(iOS 12.1, *) {
      let pencilInteraction = UIPencilInteraction()
      pencilInteraction.delegate = self
      controller.view.addInteraction(pencilInteraction)
    }
  }

  // MARK: - UIPencilInteractionDelegate
  @available(iOS 12.1, *)
  func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
    emitTapAction()
  }

  @available(iOS 17.5, *)
  func pencilInteraction(_ interaction: UIPencilInteraction, didReceiveTap tap: UIPencilInteraction.Tap) {
    emitTapAction()
  }

  @available(iOS 17.5, *)
  func pencilInteraction(_ interaction: UIPencilInteraction, didReceiveSqueeze squeeze: UIPencilInteraction.Squeeze) {
    guard let sink = eventSink else { return }
    let payload: [String: Any] = [
      "type": "squeeze",
      "action": "switchPrevious"
    ]
    sink(payload)
  }

  private func emitTapAction() {
    guard let sink = eventSink else { return }

    var actionStr = "switchEraser"
    if #available(iOS 12.1, *) {
      switch UIPencilInteraction.preferredTapAction {
      case .switchEraser:
        actionStr = "switchEraser"
      case .switchPrevious:
        actionStr = "switchPrevious"
      case .showColorPalette:
        actionStr = "showColorPalette"
      case .ignore:
        actionStr = "ignore"
      default:
        actionStr = "switchEraser"
      }
    }

    let payload: [String: Any] = [
      "type": "doubleTap",
      "action": actionStr
    ]
    sink(payload)
  }

  // MARK: - FlutterStreamHandler
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }
}
