import Foundation
import SwiftUI
import Combine

// MARK: - App Mode
enum AppMode: String, Codable {
    case undetermined
    case webView
    case native
}

// MARK: - App State
enum AppState {
    case loading
    case noInternet
    case pushPermission
    case webView(url: String)
    case native
}

// MARK: - App State Manager
@MainActor
class AppStateManager: ObservableObject {
    static let shared = AppStateManager()

    // MARK: - Published Properties
    @Published var currentState: AppState = .loading
    @Published var isInitialized = false
    @Published var loadingProgress: String = "Initializing..."

    // MARK: - Services
    private let configService = ConfigService.shared
    private let appsFlyerService = AppsFlyerService.shared
    private let pushService = PushNotificationService.shared
    private let networkMonitor = NetworkMonitor.shared

    // MARK: - Network Observation
    private var networkObservationTask: Task<Void, Never>?
    private var cachedURLForReconnect: String?

    // MARK: - App Mode Persistence
    private let appModeKey = "determined_app_mode"

    var savedAppMode: AppMode {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: appModeKey),
                  let mode = AppMode(rawValue: rawValue) else {
                return .undetermined
            }
            return mode
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: appModeKey)
        }
    }

    // MARK: - Test Mode (set to nil to disable)
    private let testWebViewURL: String? = nil

    private init() {}

    // MARK: - Initialize App
    func initializeApp() async {

        // TEST MODE: Skip all logic and open WebView directly
        if let testURL = testWebViewURL {
            currentState = .webView(url: testURL)
            isInitialized = true
            return
        }

        loadingProgress = "Checking connection..."

        // Check if mode already determined
        if savedAppMode != .undetermined {
            await handleSubsequentLaunch()
            return
        }

        // First launch - need internet
        await handleFirstLaunch()
    }

    // MARK: - First Launch
    private func handleFirstLaunch() async {

        // Check internet connection
        guard networkMonitor.isConnected else {
            currentState = .noInternet
            return
        }

        loadingProgress = "Loading user's data..."

        // 1. Request ATT FIRST (before AppsFlyer)
        try? await Task.sleep(nanoseconds: 500_000_000)
        _ = await appsFlyerService.requestTrackingAuthorization()

        loadingProgress = "Loading user's data..."

        // 2. Configure AppsFlyer AFTER ATT
        appsFlyerService.configure()

        // 3. Start AppsFlyer
        appsFlyerService.start()

        loadingProgress = "Loading user's data..."

        // Wait for conversion data
        let conversionReceived = await waitForConversionData(timeout: AppConfiguration.Timeouts.conversionDataTimeout)

        if !conversionReceived {
            savedAppMode = .native
            currentState = .native
            return
        }

        loadingProgress = "Loading user's data..."

        // Make config request
        do {
            let response = try await configService.requestConfig(
                conversionData: appsFlyerService.conversionData,
                deepLinkData: appsFlyerService.deepLinkData,
                pushToken: pushService.fcmToken
            )

            if response.ok, let url = response.url {
                savedAppMode = .webView
                configService.isWebViewMode = true
                configService.isModeDetermined = true

                // Check if should show push permission
                if pushService.shouldShowPermissionScreen {
                    currentState = .pushPermission
                } else {
                    currentState = .webView(url: url)
                }
            } else {
                savedAppMode = .native
                configService.isModeDetermined = true
                currentState = .native
            }
        } catch {
            savedAppMode = .native
            configService.isModeDetermined = true
            currentState = .native
        }

        isInitialized = true
    }

    // MARK: - Subsequent Launch
    private func handleSubsequentLaunch() async {

        switch savedAppMode {
        case .webView:
            await handleWebViewMode()
        case .native:
            currentState = .native
        case .undetermined:
            await handleFirstLaunch()
        }

        isInitialized = true
    }

    // MARK: - WebView Mode
    private func handleWebViewMode() async {
        // Check internet - show no internet screen even if we have cached URL
        guard networkMonitor.isConnected else {

            // Save cached URL for when connection restores
            cachedURLForReconnect = configService.storedConfig?.url

            // Show no internet and start watching for reconnection
            currentState = .noInternet
            startNetworkObservation()
            return
        }

        // Stop network observation if running
        stopNetworkObservation()

        // Start AppsFlyer for attribution (configure if not done yet)
        if !appsFlyerService.isConfigured {
            appsFlyerService.configure()
        }
        appsFlyerService.start()

        // Check for pending notification URL
        if let notificationURL = pushService.pendingNotificationURL {
            pushService.clearPendingURL()
            currentState = .webView(url: notificationURL)
            return
        }

        // Check if should show push permission (after 3 days skip)
        if pushService.shouldShowPermissionScreen {
            currentState = .pushPermission
            return
        }

        // Try to get fresh URL
        if let url = await configService.getURLForWebView() {
            currentState = .webView(url: url)
        } else if let cachedURL = configService.storedConfig?.url {
            // Fallback to cached URL
            currentState = .webView(url: cachedURL)
        } else {
            // No URL available - show error
            currentState = .noInternet
            startNetworkObservation()
        }
    }

    // MARK: - Network Observation
    private func startNetworkObservation() {
        // Cancel existing task if any
        networkObservationTask?.cancel()

        networkObservationTask = Task { [weak self] in
            guard let self = self else { return }


            // Poll for network changes
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

                if self.networkMonitor.isConnected {

                    // Network restored - proceed to WebView
                    await MainActor.run {
                        Task {
                            await self.onNetworkRestored()
                        }
                    }
                    break
                }
            }
        }
    }

    private func stopNetworkObservation() {
        networkObservationTask?.cancel()
        networkObservationTask = nil
    }

    private func onNetworkRestored() async {
        stopNetworkObservation()

        // Only handle if we're in WebView mode and showing no internet
        guard savedAppMode == .webView else { return }

        if case .noInternet = currentState {
            await handleWebViewMode()
        }
    }

    // MARK: - Wait for Conversion Data
    private func waitForConversionData(timeout: TimeInterval) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if appsFlyerService.isConversionDataReceived {
                return true
            }
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
        }

        return appsFlyerService.isConversionDataReceived
    }

    // MARK: - Actions
    func onPushPermissionAccepted() async {
        let granted = await pushService.requestPermission()

        // Proceed to WebView
        if let url = await configService.getURLForWebView() {
            currentState = .webView(url: url)
        } else if let cachedURL = configService.storedConfig?.url {
            currentState = .webView(url: cachedURL)
        }
    }

    func onPushPermissionSkipped() async {
        pushService.skipPermission()

        // Proceed to WebView
        if let url = await configService.getURLForWebView() {
            currentState = .webView(url: url)
        } else if let cachedURL = configService.storedConfig?.url {
            currentState = .webView(url: cachedURL)
        }
    }

    func retryConnection() async {
        currentState = .loading
        loadingProgress = "Retrying..."

        // Wait for connection
        let connected = await networkMonitor.waitForConnection(timeout: 5)

        if connected {
            if savedAppMode == .undetermined {
                await handleFirstLaunch()
            } else {
                await handleSubsequentLaunch()
            }
        } else {
            currentState = .noInternet
        }
    }

    // MARK: - Handle Notification URL
    func handleNotificationURL(_ url: String) {
        guard savedAppMode == .webView else { return }
        currentState = .webView(url: url)
    }

    // MARK: - Reset (for testing)
    func reset() {
        savedAppMode = .undetermined
        configService.reset()
        currentState = .loading
        isInitialized = false
    }
}
