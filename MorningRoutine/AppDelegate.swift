import UIKit
import FirebaseCore
import FirebaseMessaging
import AppsFlyerLib

// ============================================================================
// MARK: - APP DELEGATE
// ============================================================================
// Handles app lifecycle, Firebase, and AppsFlyer integration.
// ============================================================================

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Print configuration status (for debugging)
        AppConfiguration.printStatus()

        // Configure Firebase
        FirebaseApp.configure()

        // Configure Push Notifications
        PushNotificationService.shared.configure()

        return true
    }

    // MARK: - Remote Notifications

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Pass token to Firebase Messaging
        PushNotificationService.shared.handleDeviceToken(deviceToken)

        // Register for AppsFlyer uninstall tracking
        AppsFlyerLib.shared().registerUninstall(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        PushNotificationService.shared.handleNotification(userInfo: userInfo)
        completionHandler(.newData)
    }

    // MARK: - URL Handling (Deep Links)

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // Handle AppsFlyer deep links
        AppsFlyerLib.shared().handleOpen(url, options: options)
        return true
    }

    // MARK: - Universal Links

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        // Handle AppsFlyer universal links
        AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
        return true
    }

    // MARK: - App Lifecycle

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart AppsFlyer tracking when app becomes active
        if AppsFlyerService.shared.isConfigured {
            AppsFlyerService.shared.start()
        }
    }
}
