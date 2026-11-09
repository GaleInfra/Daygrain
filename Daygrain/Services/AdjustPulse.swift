import Foundation
import AdjustSdk

/// Thin Adjust 5.x wrapper. Reports only non-sensitive attribution and purchase signals.
enum AdjustPulse {
    private static let appTokenKey = "daygrain.adjust.appToken"
    private static let purchaseTokenKey = "daygrain.adjust.purchaseToken"
    private static let registerTokenKey = "daygrain.adjust.registerToken"
    private static var didStart = false

    /// Placeholder-safe defaults. Production tokens must replace these before shipping.
    private static let defaultAppToken = "REPLACE_ADJUST_APP_TOKEN"
    private static let defaultPurchaseToken = "REPLACE_PURCHASE_EVENT"
    private static let defaultRegisterToken = "REPLACE_REGISTER_EVENT"

    static func start() {
        guard !didStart else { return }
        didStart = true

        let appToken = resolvedAppToken()
        guard isUsableToken(appToken) else { return }

        #if DEBUG
        let environment = ADJEnvironmentSandbox
        #else
        let environment = ADJEnvironmentProduction
        #endif

        guard let config = ADJConfig(appToken: appToken, environment: environment) else { return }
        #if DEBUG
        config.logLevel = .verbose
        #else
        config.logLevel = .warn
        #endif
        config.attConsentWaitingInterval = 45
        Adjust.initSdk(config)
    }

    static func requestTrackingConsent(completion: ((UInt) -> Void)? = nil) {
        Adjust.requestAppTrackingAuthorization(completionHandler: { status in
            completion?(UInt(status))
        })
    }

    /// Purchase only: product id, revenue, currency, dedupe id. Never journal or AI content.
    static func trackPurchase(
        productId: String,
        price: Decimal,
        currencyCode: String,
        deduplicationId: String
    ) {
        let token = UserDefaults.standard.string(forKey: purchaseTokenKey) ?? defaultPurchaseToken
        guard isUsableToken(token), let event = ADJEvent(eventToken: token) else { return }
        let amount = NSDecimalNumber(decimal: price).doubleValue
        event.setRevenue(amount, currency: currencyCode)
        event.setProductId(productId)
        event.setDeduplicationId(deduplicationId)
        Adjust.trackEvent(event)
    }

    /// First meaningful local use signal only. No personal content.
    static func trackFirstOpenIfNeeded() {
        let flag = "daygrain.adjust.register.sent"
        guard !UserDefaults.standard.bool(forKey: flag) else { return }
        let token = UserDefaults.standard.string(forKey: registerTokenKey) ?? defaultRegisterToken
        guard isUsableToken(token), let event = ADJEvent(eventToken: token) else { return }
        Adjust.trackEvent(event)
        UserDefaults.standard.set(true, forKey: flag)
    }

    private static func resolvedAppToken() -> String {
        if let stored = UserDefaults.standard.string(forKey: appTokenKey), isUsableToken(stored) {
            return stored
        }
        return defaultAppToken
    }

    private static func isUsableToken(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 6 else { return false }
        let lower = trimmed.lowercased()
        let blocked = ["placeholder", "replace", "yourapptoken", "todo", "sample", "demo"]
        if blocked.contains(where: { lower.contains($0) }) {
            return false
        }
        if trimmed.unicodeScalars.contains(where: { !$0.isASCII }) {
            return false
        }
        return true
    }
}
