import Foundation
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging
import Combine

// MARK: - Push Notification Service
class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()

    // MARK: - UserDefaults Keys
    private let pushPermissionRequestedKey = "push_permission_requested"
    private let pushPermissionSkippedKey = "push_permission_skipped_date"
    private let fcmTokenKey = "fcm_push_token"

    // MARK: - Published Properties
    @Published var fcmToken: String?
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var pendingNotificationURL: String?

    // MARK: - Properties
    var hasRequestedPermission: Bool {
        get { UserDefaults.standard.bool(forKey: pushPermissionRequestedKey) }
        set { UserDefaults.standard.set(newValue, forKey: pushPermissionRequestedKey) }
    }

    var lastSkippedDate: Date? {
        get { UserDefaults.standard.object(forKey: pushPermissionSkippedKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: pushPermissionSkippedKey) }
    }

    // Retry interval from configuration
    private var skipInterval: TimeInterval { AppConfiguration.PushNotifications.retryInterval }

    // MARK: - Should Show Permission Screen
    var shouldShowPermissionScreen: Bool {
        // Already granted - don't show
        if authorizationStatus == .authorized { return false }

        // Denied via system dialog - can't ask again
        if authorizationStatus == .denied { return false }

        // Never requested - show
        if !hasRequestedPermission && lastSkippedDate == nil { return true }

        // Skipped - check if 3 days passed
        if let skippedDate = lastSkippedDate {
            let elapsed = Date().timeIntervalSince(skippedDate)
            return elapsed >= skipInterval
        }

        return false
    }

    private override init() {
        super.init()

        // Load stored token
        fcmToken = UserDefaults.standard.string(forKey: fcmTokenKey)
    }

    // MARK: - Configure Firebase Messaging
    func configure() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        // Check current authorization status
        checkAuthorizationStatus()

    }

    // MARK: - Check Authorization Status
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    // MARK: - Request Permission
    func requestPermission() async -> Bool {
        hasRequestedPermission = true

        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )

            await MainActor.run {
                checkAuthorizationStatus()
            }

            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }

            return granted
        } catch {
            return false
        }
    }

    // MARK: - Skip Permission
    func skipPermission() {
        lastSkippedDate = Date()
    }

    // MARK: - Register for Remote Notifications
    func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    // MARK: - Handle Notification
    func handleNotification(userInfo: [AnyHashable: Any]) {

        // Check for URL in data payload
        if let data = userInfo["data"] as? [String: Any],
           let url = data["url"] as? String, !url.isEmpty {
            pendingNotificationURL = url
        } else if let url = userInfo["url"] as? String, !url.isEmpty {
            pendingNotificationURL = url
        }
    }

    // MARK: - Clear Pending URL
    func clearPendingURL() {
        pendingNotificationURL = nil
    }

    // MARK: - Handle Device Token
    func handleDeviceToken(_ deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

// MARK: - MessagingDelegate
extension PushNotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {

        guard let token = fcmToken else { return }

        DispatchQueue.main.async {
            self.fcmToken = token
            UserDefaults.standard.set(token, forKey: self.fcmTokenKey)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension PushNotificationService: UNUserNotificationCenterDelegate {
    // Called when notification is received while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo

        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Called when user taps on notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        handleNotification(userInfo: userInfo)

        completionHandler()
    }
}
