import Foundation
import AppsFlyerLib
import AppTrackingTransparency
import AdSupport
import Combine

// MARK: - Conversion Data Model
struct ConversionData: Codable {
    var rawData: [String: Any]
    var afStatus: String?
    var mediaSource: String?
    var campaign: String?
    var afId: String?

    var isOrganic: Bool {
        return afStatus?.lowercased() == "organic"
    }

    var isNonOrganic: Bool {
        return afStatus?.lowercased() == "non-organic"
    }

    init(from dictionary: [String: Any]) {
        self.rawData = dictionary
        self.afStatus = dictionary["af_status"] as? String
        self.mediaSource = dictionary["media_source"] as? String
        self.campaign = dictionary["campaign"] as? String
    }

    enum CodingKeys: String, CodingKey {
        case rawData, afStatus, mediaSource, campaign, afId
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let jsonData = try JSONSerialization.data(withJSONObject: rawData)
        let jsonString = String(data: jsonData, encoding: .utf8)
        try container.encode(jsonString, forKey: .rawData)
        try container.encodeIfPresent(afStatus, forKey: .afStatus)
        try container.encodeIfPresent(mediaSource, forKey: .mediaSource)
        try container.encodeIfPresent(campaign, forKey: .campaign)
        try container.encodeIfPresent(afId, forKey: .afId)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let jsonString = try container.decode(String.self, forKey: .rawData)
        if let data = jsonString.data(using: .utf8),
           let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            self.rawData = dict
        } else {
            self.rawData = [:]
        }
        self.afStatus = try container.decodeIfPresent(String.self, forKey: .afStatus)
        self.mediaSource = try container.decodeIfPresent(String.self, forKey: .mediaSource)
        self.campaign = try container.decodeIfPresent(String.self, forKey: .campaign)
        self.afId = try container.decodeIfPresent(String.self, forKey: .afId)
    }

    func toDictionary() -> [String: Any] {
        return rawData
    }
}

// MARK: - Deep Link Data Model
struct DeepLinkData {
    var rawData: [String: Any]
    var deepLinkValue: String?
    var deepLinkSub1: String?
    var isDeferred: Bool

    init(from dictionary: [String: Any]) {
        self.rawData = dictionary
        self.deepLinkValue = dictionary["deep_link_value"] as? String
        self.deepLinkSub1 = dictionary["deep_link_sub1"] as? String
        self.isDeferred = dictionary["is_deferred"] as? Bool ?? false
    }

    func toDictionary() -> [String: Any] {
        return rawData
    }
}

// MARK: - AppsFlyer Service
class AppsFlyerService: NSObject, ObservableObject {
    static let shared = AppsFlyerService()

    private var devKey: String { AppConfiguration.AppsFlyer.devKey }
    private var appleAppID: String { AppConfiguration.AppsFlyer.appleAppID }

    @Published var conversionData: ConversionData?
    @Published var deepLinkData: DeepLinkData?
    @Published var isConversionDataReceived = false
    @Published var attStatus: ATTrackingManager.AuthorizationStatus = .notDetermined

    var onConversionDataReceived: ((ConversionData) -> Void)?
    var onDeepLinkReceived: ((DeepLinkData) -> Void)?
    var onConversionFailed: ((Error) -> Void)?

    private var conversionRetryCount = 0
    private let maxRetries = 1
    private(set) var isConfigured = false
    private let conversionDataCacheKey = "cached_conversion_data"

    private override init() {
        super.init()
        loadCachedConversionData()
    }

    private func loadCachedConversionData() {
        if let data = UserDefaults.standard.data(forKey: conversionDataCacheKey),
           let cached = try? JSONDecoder().decode(ConversionData.self, from: data) {
            self.conversionData = cached
        }
    }

    private func cacheConversionData(_ data: ConversionData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: conversionDataCacheKey)
        }
    }

    func configure() {
        guard !isConfigured else { return }

        AppsFlyerLib.shared().appsFlyerDevKey = devKey
        AppsFlyerLib.shared().appleAppID = appleAppID
        AppsFlyerLib.shared().delegate = self
        AppsFlyerLib.shared().deepLinkDelegate = self
        AppsFlyerLib.shared().isDebug = AppConfiguration.Debug.isAppsFlyerDebugEnabled

        #if DEBUG
        AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 10)
        #else
        AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
        #endif

        isConfigured = true
    }

    func start() {
        AppsFlyerLib.shared().start()
    }

    func requestTrackingAuthorization() async -> ATTrackingManager.AuthorizationStatus {
        if ATTrackingManager.trackingAuthorizationStatus != .notDetermined {
            attStatus = ATTrackingManager.trackingAuthorizationStatus
            return attStatus
        }

        let status = await ATTrackingManager.requestTrackingAuthorization()
        await MainActor.run {
            attStatus = status
        }
        return status
    }

    var appsFlyerUID: String {
        return AppsFlyerLib.shared().getAppsFlyerUID()
    }

    var idfa: String? {
        if attStatus == .authorized {
            return ASIdentifierManager.shared().advertisingIdentifier.uuidString
        }
        return nil
    }

    func retryConversionDataViaAPI() async {
        guard conversionRetryCount < maxRetries else { return }
        conversionRetryCount += 1

        let delay = UInt64(AppConfiguration.Timeouts.organicRetryDelay * 1_000_000_000)
        try? await Task.sleep(nanoseconds: delay)

        let bundleId = Bundle.main.bundleIdentifier ?? ""
        let afId = appsFlyerUID
        let urlString = "https://gcdsdk.appsflyer.com/install_data/v4.0/\(bundleId)?devkey=\(devKey)&device_id=\(afId)"

        guard let url = URL(string: urlString) else { return }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return }

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let newConversionData = ConversionData(from: json)
                await MainActor.run {
                    self.conversionData = newConversionData
                    self.isConversionDataReceived = true
                    self.cacheConversionData(newConversionData)
                    self.onConversionDataReceived?(newConversionData)
                }
            }
        } catch {
        }
    }
}

// MARK: - AppsFlyerLibDelegate
extension AppsFlyerService: AppsFlyerLibDelegate {
    func onConversionDataSuccess(_ installData: [AnyHashable : Any]) {
        let data = installData.reduce(into: [String: Any]()) { result, pair in
            if let key = pair.key as? String {
                result[key] = pair.value
            }
        }

        let conversion = ConversionData(from: data)

        DispatchQueue.main.async {
            self.conversionData = conversion
            self.isConversionDataReceived = true
            self.cacheConversionData(conversion)

            if conversion.isOrganic {
                Task { await self.retryConversionDataViaAPI() }
            } else {
                self.onConversionDataReceived?(conversion)
            }
        }

    }

    func onConversionDataFail(_ error: Error) {
        DispatchQueue.main.async {
            self.isConversionDataReceived = true
            self.onConversionFailed?(error)
        }
    }
}

// MARK: - DeepLinkDelegate
extension AppsFlyerService: DeepLinkDelegate {
    func didResolveDeepLink(_ result: DeepLinkResult) {
        switch result.status {
        case .notFound:
            break
        case .found:
            if let deepLink = result.deepLink {
                let data = deepLink.clickEvent.reduce(into: [String: Any]()) { result, pair in
                    if let key = pair.key as? String {
                        result[key] = pair.value
                    }
                }
                let deepLinkData = DeepLinkData(from: data)
                DispatchQueue.main.async {
                    self.deepLinkData = deepLinkData
                    self.onDeepLinkReceived?(deepLinkData)
                }
            }
        case .failure:
            break
        }
    }
}
