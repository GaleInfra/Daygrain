import Foundation
import AdjustSdk

/// One Adjust SDK and one send path for native and activity events.
///
/// Operator fill-in, after the real native tokens exist in the Adjust dashboard:
/// `UserDefaults` key `daygrain.adjust.nativeEnabled` = true,
/// `daygrain.adjust.registerToken` = the token for `daygrain_seed_ccd3eb`,
/// `daygrain.adjust.purchaseToken` = the token for `daygrain_credit_828f0c`.
/// Until that switch is on, native events are not submitted and the first-registration mark is left unset.
/// Activity `regist` / `buy` use the ledger tokens and do not read those native keys.
enum AdjustPulse {
    private static let appTokenKey = "daygrain.adjust.appToken"
    private static let purchaseTokenKey = "daygrain.adjust.purchaseToken"
    private static let registerTokenKey = "daygrain.adjust.registerToken"
    static let nativeEnabledKey = "daygrain.adjust.nativeEnabled"
    private static var didStart = false

    static func start() {
        guard !didStart else { return }
        didStart = true
        let appToken = resolvedAppToken()
        guard GrainAdjustRoute.isOperatorToken(appToken, placeholder: "placeholder") else { return }
        guard let config = ADJConfig(appToken: appToken, environment: ADJEnvironmentSandbox) else { return }
        config.logLevel = .verbose
        config.attConsentWaitingInterval = 45
        Adjust.initSdk(config)
        print("AdjustPulse environment=sandbox")
    }

    static func requestTrackingConsent(completion: ((UInt) -> Void)? = nil) {
        Adjust.requestAppTrackingAuthorization(completionHandler: { status in
            completion?(UInt(status))
        })
    }

    static func recordLaunchQuery(status: Int) {
        guard let signal = GrainAdjustRoute.nativeRegistration(httpStatus: status) else { return }
        submit(signal)
    }

    static func submit(_ signal: GrainSignal) {
        let choice = GrainAdjustRoute.token(
            for: signal,
            nativeRegistration: UserDefaults.standard.string(forKey: registerTokenKey) ?? GrainAdjustRoute.nativeRegistrationPlaceholder,
            nativePurchase: UserDefaults.standard.string(forKey: purchaseTokenKey) ?? GrainAdjustRoute.nativePurchasePlaceholder,
            nativeEnabled: UserDefaults.standard.bool(forKey: nativeEnabledKey)
        )
        guard choice.sends else {
            if signal.source == .native {
                print("AdjustPulse native \(signal.kind.rawValue) held pending_manual")
            }
            return
        }
        switch signal.kind {
        case .registration:
            sendRegistration(signal, token: choice.token)
        case .purchase:
            sendPurchase(signal, token: choice.token)
        }
    }

    private static func sendRegistration(_ signal: GrainSignal, token: String) {
        let mark = GrainAdjustRoute.registrationMark(signal.source)
        let defaults = UserDefaults.standard
        guard GrainAdjustRoute.shouldMark(sends: true, alreadyMarked: defaults.bool(forKey: mark)) else { return }
        guard let event = ADJEvent(eventToken: token) else { return }
        Adjust.trackEvent(event)
        defaults.set(true, forKey: mark)
    }

    private static func sendPurchase(_ signal: GrainSignal, token: String) {
        guard let amount = signal.amount, let currency = signal.currency, let transactionId = signal.transactionId else { return }
        let mark = GrainAdjustRoute.purchaseMark(source: signal.source, transactionId: transactionId)
        let defaults = UserDefaults.standard
        var seen = Set(defaults.stringArray(forKey: "daygrain.adjust.purchase.marks") ?? [])
        guard GrainAdjustRoute.shouldMark(sends: true, alreadyMarked: seen.contains(mark)) else { return }
        guard let event = ADJEvent(eventToken: token) else { return }
        event.setRevenue(NSDecimalNumber(decimal: amount).doubleValue, currency: currency)
        if let productId = signal.productId, !productId.isEmpty {
            event.setProductId(productId)
        }
        event.setDeduplicationId(transactionId)
        Adjust.trackEvent(event)
        seen.insert(mark)
        defaults.set(Array(seen), forKey: "daygrain.adjust.purchase.marks")
    }

    private static func resolvedAppToken() -> String {
        if let stored = UserDefaults.standard.string(forKey: appTokenKey),
           GrainAdjustRoute.isOperatorToken(stored, placeholder: "placeholder") {
            return stored
        }
        return GrainAdjustRoute.ledgerAppToken
    }
}
