import Foundation
import AppsFlyerLib

/// One send path for A-side registration and protocol events.
///
/// The AppsFlyer dev key is not this gate. A non-empty app token is still required
/// before any event is marked or logged. Protocol `regist` / `buy` do not read the
/// native purchase switch. While that switch is off, a direct native purchase stays unsent.
enum AdjustPulse {
    private static let appTokenKey = "daygrain.adjust.appToken"
    private static let purchaseTokenKey = "daygrain.adjust.purchaseToken"
    private static let registerTokenKey = "daygrain.adjust.registerToken"
    static let nativeEnabledKey = "daygrain.adjust.nativeEnabled"
    private static let purchaseMarksKey = "daygrain.adjust.purchase.marks"
    private static var ready = false

    static func armIfNeeded() {
        guard !ready else { return }
        guard !resolvedAppToken().isEmpty else { return }
        ready = true
    }

    static func noteForeground() {}

    static func recordLaunchQuery(status: Int) {
        guard status == 200 else { return }
        noteStayedOnStudio()
    }

    static func noteStayedOnStudio() {
        submit(GrainSignal(
            source: .native,
            kind: .registration,
            amount: nil,
            currency: nil,
            transactionId: nil,
            productId: nil
        ))
    }

    static func submit(_ signal: GrainSignal) {
        armIfNeeded()
        guard ready else { return }
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
            sendLogin(source: signal.source)
        case .purchase:
            sendPurchase(signal)
        }
    }

    private static func sendLogin(source: GrainSignalSource) {
        let mark = GrainAdjustRoute.registrationMark(source)
        let defaults = UserDefaults.standard
        guard GrainAdjustRoute.shouldMark(sends: true, alreadyMarked: defaults.bool(forKey: mark)) else { return }
        defaults.set(true, forKey: mark)
        AppsFlyerLib.shared().logEvent(name: "af_login",
            values: [
                "af_login_method": "regist"
            ],
            completionHandler: { (response: [String: Any]?, error: Error?) in
                if let response {
                    print("In app event callback Success: ", response)
                }
                if let error {
                    print("In app event callback ERROR:", error)
                }
            })
    }

    private static func sendPurchase(_ signal: GrainSignal) {
        guard let amount = signal.amount, let currency = signal.currency, let transactionId = signal.transactionId else { return }
        let mark = GrainAdjustRoute.purchaseMark(source: signal.source, transactionId: transactionId)
        let defaults = UserDefaults.standard
        var seen = Set((defaults.stringArray(forKey: purchaseMarksKey) ?? []).map(GrainAdjustRoute.settledPurchaseMark))
        guard !GrainAdjustRoute.purchaseAlreadyCovered(source: signal.source, transactionId: transactionId, seen: seen) else { return }
        seen.insert(mark)
        defaults.set(Array(seen), forKey: purchaseMarksKey)
        let revenue = NSDecimalNumber(decimal: amount).doubleValue
        AppsFlyerLib.shared().logEvent(name: "af_purchase",
            values: [
                "af_revenue": revenue,
                "af_currency": currency,
                "af_order_id": transactionId,
                "af_content_id": signal.productId ?? ""
            ],
            completionHandler: { (response: [String: Any]?, error: Error?) in
                if let response {
                    print("In app event callback Success: ", response)
                }
                if let error {
                    print("In app event callback ERROR:", error)
                }
            })
    }

    private static func resolvedAppToken() -> String {
        if let stored = UserDefaults.standard.string(forKey: appTokenKey),
           GrainAdjustRoute.isOperatorToken(stored, placeholder: "placeholder") {
            return stored
        }
        return GrainAdjustRoute.ledgerAppToken
    }
}
