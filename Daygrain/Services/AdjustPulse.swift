import Foundation
import AdjustSdk

/// One Adjust SDK and one send path for native registration and protocol events.
///
/// Operator fill-in, after the real native tokens exist in the Adjust dashboard:
/// `UserDefaults` key `daygrain.adjust.nativeEnabled` = true,
/// `daygrain.adjust.registerToken` = the token for `daygrain_seed_ccd3eb`,
/// `daygrain.adjust.purchaseToken` = the token for `daygrain_credit_828f0c`.
/// Until that switch is on, native registration and a direct native purchase stay unsent,
/// and the first-registration mark is left unset.
/// Protocol `regist` / `buy` use the ledger tokens and do not read those native keys.
enum AdjustPulse {
    private static let appTokenKey = "daygrain.adjust.appToken"
    private static let purchaseTokenKey = "daygrain.adjust.purchaseToken"
    private static let registerTokenKey = "daygrain.adjust.registerToken"
    static let nativeEnabledKey = "daygrain.adjust.nativeEnabled"
    private static let purchaseMarksKey = "daygrain.adjust.purchase.marks"
    private static let eventLog = AdjustPulseLog()
    private static var didStart = false
    private static var ready = false

    static func start() {
        guard !didStart else { return }
        didStart = true
        let appToken = resolvedAppToken()
        guard GrainAdjustRoute.isOperatorToken(appToken, placeholder: "placeholder") else { return }
        guard let config = ADJConfig(appToken: appToken, environment: ADJEnvironmentProduction) else { return }
        #if DEBUG
        config.logLevel = .verbose
        #else
        config.logLevel = .suppress
        #endif
        config.attConsentWaitingInterval = 30
        config.delegate = eventLog
        Adjust.initSdk(config)
        ready = true
        silencePartnerSharing()
        Adjust.trackSubsessionStart()
        logAdvertisingID()
        print("AdjustPulse environment=production")
    }

    static func noteForeground() {
        guard ready else { return }
        Adjust.trackSubsessionStart()
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
            sendRegistration(token: choice.token, source: signal.source)
        case .purchase:
            sendPurchase(signal, token: choice.token)
        }
    }

    private static func silencePartnerSharing() {
        guard ready, let sharing = ADJThirdPartySharing(isEnabled: 0) else { return }
        sharing.addPartnerSharingSetting("all", key: "all", value: false)
        Adjust.trackThirdPartySharing(sharing)
    }

    private static func logAdvertisingID() {
        Adjust.idfa { idfa in
            print("adjust idfa \(idfa ?? "")")
        }
        Adjust.adid { adid in
            print("adjust adid \(adid ?? "")")
        }
    }

    private static func sendRegistration(token: String, source: GrainSignalSource) {
        let mark = GrainAdjustRoute.registrationMark(source)
        let defaults = UserDefaults.standard
        guard GrainAdjustRoute.shouldMark(sends: true, alreadyMarked: defaults.bool(forKey: mark)) else { return }
        guard let event = ADJEvent(eventToken: token) else { return }
        defaults.set(true, forKey: mark)
        wakeSession()
        Adjust.trackEvent(event)
    }

    private static func sendPurchase(_ signal: GrainSignal, token: String) {
        guard let amount = signal.amount, let currency = signal.currency, let transactionId = signal.transactionId else { return }
        let mark = GrainAdjustRoute.purchaseMark(source: signal.source, transactionId: transactionId)
        let defaults = UserDefaults.standard
        var seen = Set(defaults.stringArray(forKey: purchaseMarksKey) ?? [])
        guard GrainAdjustRoute.shouldMark(sends: true, alreadyMarked: seen.contains(mark)) else { return }
        guard let event = ADJEvent(eventToken: token) else { return }
        event.setRevenue(NSDecimalNumber(decimal: amount).doubleValue, currency: currency)
        seen.insert(mark)
        defaults.set(Array(seen), forKey: purchaseMarksKey)
        wakeSession()
        Adjust.trackEvent(event)
    }

    private static func wakeSession() {
        guard ready else { return }
        Adjust.trackSubsessionStart()
    }

    private static func resolvedAppToken() -> String {
        if let stored = UserDefaults.standard.string(forKey: appTokenKey),
           GrainAdjustRoute.isOperatorToken(stored, placeholder: "placeholder") {
            return stored
        }
        return GrainAdjustRoute.ledgerAppToken
    }
}

private final class AdjustPulseLog: NSObject, AdjustDelegate {
    func adjustSessionTrackingSucceeded(_ sessionSuccessResponse: ADJSessionSuccess?) {
        print("adjust adid \(sessionSuccessResponse?.adid ?? "")")
        Adjust.idfa { idfa in
            print("adjust idfa \(idfa ?? "")")
        }
    }

    func adjustEventTrackingSucceeded(_ eventSuccessResponse: ADJEventSuccess?) {
        print("adjust event ok \(eventSuccessResponse?.eventToken ?? "")")
    }

    func adjustEventTrackingFailed(_ eventFailureResponse: ADJEventFailure?) {
        print("adjust event failed \(eventFailureResponse?.eventToken ?? "")")
    }
}
