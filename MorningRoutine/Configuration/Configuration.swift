import Foundation

// ============================================================================
// MARK: - APP CONFIGURATION
// ============================================================================
// TODO: Replace all placeholder values before building
// ============================================================================

enum AppConfiguration {

    // MARK: - AppsFlyer Configuration
    enum AppsFlyer {
        static let devKey = "8MrRDPwkLc8oJaJ7Nstp7n"
        static let appleAppID = "6757846912"
    }

    // MARK: - Config Endpoint
    // Your server that returns WebView URL or native mode
    enum Config {
        static let endpoint = "https://test-web.syndi-test.net/"
    }

    // MARK: - URLs
    enum URLs {
        static let privacyPolicy = "https://www.termsfeed.com/live/69fad1a1-6ee9-4b01-9cfd-d41fd4658f01"
        static let support = "https://www.termsfeed.com/live/69fad1a1-6ee9-4b01-9cfd-d41fd4658f01"
    }

    // MARK: - App Store
    enum AppStore {
        static var storeID: String {
            return "id\(AppsFlyer.appleAppID)"
        }
    }

    // MARK: - Bundle Info
    enum Bundle {
        static var bundleID: String {
            return Foundation.Bundle.main.bundleIdentifier ?? "com.morningRoutine"
        }

        static var appVersion: String {
            return Foundation.Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        }

        static var buildNumber: String {
            return Foundation.Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        }
    }

    // MARK: - Firebase
    // Get Project ID from Firebase Console -> Project Settings
    enum Firebase {
        static let projectID = "morningroutine-47077"  // TODO: Replace

        static var projectNumber: String {
            if let path = Foundation.Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
               let dict = NSDictionary(contentsOfFile: path),
               let gcmSenderID = dict["GCM_SENDER_ID"] as? String {
                return gcmSenderID
            }
            return ""
        }
    }

    // MARK: - Push Notifications
    enum PushNotifications {
        static let retryInterval: TimeInterval = 259200 // 3 days in seconds
    }

    // MARK: - Timeouts
    enum Timeouts {
        static let conversionDataTimeout: TimeInterval = 15   // Wait for AppsFlyer data
        static let configRequestTimeout: TimeInterval = 30    // Config endpoint timeout
        static let organicRetryDelay: TimeInterval = 5        // Retry for organic status
    }

    // MARK: - Debug
    enum Debug {
        static var isAppsFlyerDebugEnabled: Bool {
            #if DEBUG
            return true
            #else
            return false
            #endif
        }

        static var isLoggingEnabled: Bool {
            #if DEBUG
            return true
            #else
            return false
            #endif
        }
    }
}

// MARK: - Configuration Validation
extension AppConfiguration {

    /// Returns list of configuration errors (empty if all valid)
    static func validate() -> [String] {
        var errors: [String] = []

        if AppsFlyer.devKey == "YOUR_APPSFLYER_DEV_KEY" || AppsFlyer.devKey.isEmpty {
            errors.append("AppsFlyer Dev Key not configured")
        }

        if AppsFlyer.appleAppID == "YOUR_APPLE_APP_ID" || AppsFlyer.appleAppID.isEmpty {
            errors.append("Apple App ID not configured")
        }

        if Config.endpoint == "YOUR_CONFIG_ENDPOINT_URL" || Config.endpoint.isEmpty {
            errors.append("Config Endpoint not configured")
        }

        if Firebase.projectID == "YOUR_FIREBASE_PROJECT_ID" || Firebase.projectID.isEmpty {
            errors.append("Firebase Project ID not configured")
        }

        return errors
    }

    /// Prints configuration status to console (call in AppDelegate)
    static func printStatus() {
        print("=============================================================")
        print("              APP CONFIGURATION STATUS                       ")
        print("=============================================================")
        print(" Bundle ID: \(Bundle.bundleID)")
        print(" App Version: \(Bundle.appVersion) (\(Bundle.buildNumber))")
        print(" AppsFlyer Dev Key: \(AppsFlyer.devKey.prefix(10))...")
        print(" Apple App ID: \(AppsFlyer.appleAppID)")
        print(" Config Endpoint: \(Config.endpoint.prefix(30))...")
        print("=============================================================")

        let errors = validate()
        if errors.isEmpty {
            print(" All configurations are set correctly")
        } else {
            print(" Configuration errors found:")
            errors.forEach { print("   - \($0)") }
        }

        print("=============================================================")
    }
}
