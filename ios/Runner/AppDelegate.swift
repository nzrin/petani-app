import AuthenticationServices
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var appIconChannel: FlutterMethodChannel?
  private var webAuthBridge: WebAuthSessionBridge?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    webAuthBridge = WebAuthSessionBridge(
      messenger: engineBridge.applicationRegistrar.messenger()
    )

    let channel = FlutterMethodChannel(
      name: "com.nazrinapp.petani/app_icon",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "getCurrentIcon":
        result(UIApplication.shared.alternateIconName ?? "Default")
      case "setIcon":
        guard
          let arguments = call.arguments as? [String: Any],
          let iconName = arguments["iconName"] as? String
        else {
          result(
            FlutterError(
              code: "INVALID_ICON",
              message: "Ikon aplikasi tidak dikenali.",
              details: nil
            )
          )
          return
        }

        guard UIApplication.shared.supportsAlternateIcons else {
          result(
            FlutterError(
              code: "UNSUPPORTED",
              message: "Peranti ini tidak menyokong ikon aplikasi alternatif.",
              details: nil
            )
          )
          return
        }

        let alternateName: String? = iconName == "Default" ? nil : iconName
        DispatchQueue.main.async {
          UIApplication.shared.setAlternateIconName(alternateName) { error in
            if let error {
              result(
                FlutterError(
                  code: "ICON_CHANGE_FAILED",
                  message: error.localizedDescription,
                  details: nil
                )
              )
            } else {
              result(true)
            }
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    appIconChannel = channel
  }
}

/// Keeps the OAuth session alive until Apple's authentication UI completes.
private final class WebAuthSessionBridge: NSObject,
  ASWebAuthenticationPresentationContextProviding
{
  private let channel: FlutterMethodChannel
  private var session: ASWebAuthenticationSession?
  private var anchor: ASPresentationAnchor?

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "com.nazrinapp.petani/web_auth",
      binaryMessenger: messenger
    )
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "authenticate" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.authenticate(arguments: call.arguments, result: result)
    }
  }

  private func authenticate(arguments: Any?, result: @escaping FlutterResult) {
    guard session == nil else {
      result(FlutterError(code: "AUTH_IN_PROGRESS", message: "Sign-in is already open.", details: nil))
      return
    }
    guard
      let arguments = arguments as? [String: String],
      let urlString = arguments["url"],
      let url = URL(string: urlString),
      url.scheme == "https",
      url.host != nil,
      let callbackString = arguments["callbackUrl"],
      let callbackURL = URL(string: callbackString),
      let callbackScheme = callbackURL.scheme,
      callbackScheme == "com.nazrinapp.petani"
    else {
      result(FlutterError(code: "AUTH_INVALID_URL", message: "Invalid sign-in URL.", details: nil))
      return
    }
    guard let window = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .filter({ $0.activationState == .foregroundActive })
      .flatMap({ $0.windows })
      .first(where: { $0.isKeyWindow })
    else {
      result(FlutterError(code: "AUTH_NO_WINDOW", message: "No active app window.", details: nil))
      return
    }

    anchor = window
    let authSession = ASWebAuthenticationSession(
      url: url,
      callbackURLScheme: callbackScheme
    ) { [weak self] callback, error in
      DispatchQueue.main.async {
        self?.session = nil
        self?.anchor = nil
        if let error = error as? ASWebAuthenticationSessionError,
          error.code == .canceledLogin
        {
          result(nil)
        } else if error != nil {
          result(FlutterError(code: "AUTH_FAILED", message: "Unable to complete sign-in.", details: nil))
        } else if let callback {
          result(callback.absoluteString)
        } else {
          result(FlutterError(code: "AUTH_NO_CALLBACK", message: "Sign-in returned no callback.", details: nil))
        }
      }
    }
    authSession.presentationContextProvider = self
    session = authSession
    if !authSession.start() {
      session = nil
      anchor = nil
      result(FlutterError(code: "AUTH_START_FAILED", message: "Unable to open sign-in.", details: nil))
    }
  }

  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    // The anchor is set before start() and retained for the session's lifetime.
    return anchor ?? ASPresentationAnchor()
  }
}
