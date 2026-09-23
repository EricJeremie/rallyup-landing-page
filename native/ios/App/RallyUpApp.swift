import CoreText
import SwiftUI
import UIKit
import UserNotifications

extension Notification.Name {
    static let rallyUpAPNsToken = Notification.Name("rallyup.apns-token")
}

final class RallyUpAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        NotificationCenter.default.post(name: .rallyUpAPNsToken, object: token)
    }
}

@MainActor
enum RallyUpPushNotifications {
    static func requestPermissionAndRegister() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            guard granted else { return }
            UIApplication.shared.registerForRemoteNotifications()
        } catch {
            // The app remains usable without notifications; the next launch can retry.
        }
    }
}

@main
struct RallyUpApp: App {
    @UIApplicationDelegateAdaptor(RallyUpAppDelegate.self) private var appDelegate
    @StateObject private var store = RallyStore()
    @StateObject private var accountSession = AccountSessionStore()

    init() {
        InterFontRegistrar.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            RallyRootView()
                .environmentObject(store)
                .environmentObject(accountSession)
                .tint(RallyTheme.darkGreen)
        }
    }
}


private enum InterFontRegistrar {
    static func registerBundledFonts() {
        for name in ["Inter-Regular", "Inter-Medium", "Inter-SemiBold", "Inter-Bold", "Inter-Black"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
