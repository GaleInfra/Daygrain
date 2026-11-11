import Foundation

enum GrainSignalSource: String {
    case native
    case activity
}

enum GrainSignalKind: String {
    case registration
    case purchase
}

struct GrainSignal: Equatable {
    var source: GrainSignalSource
    var kind: GrainSignalKind
    var amount: Decimal?
    var currency: String?
    var transactionId: String?
    var productId: String?
}

enum GrainAdjustRoute {
    static let scheme = "daygrain-local"
    static let action = "tilem1flig"
    static let eventField = "ps1g199"
    static let amountField = "pfkiry3"
    static let currencyField = "p0h3vme"
    static let transactionField = "podvilk"
    static let productField = "p7b76q1"

    static let nativeRegistrationName = "daygrain_seed_ccd3eb"
    static let nativePurchaseName = "daygrain_credit_828f0c"
    static let nativeRegistrationPlaceholder = "tp2iar"
    static let nativePurchasePlaceholder = "4clegu"
    static let activityRegistrationToken = "pzbyu7"
    static let activityPurchaseToken = "m3q65e"
    static let ledgerAppToken = "wdg1q7iq9bsw"
    static let loginEvent = "af_login"
    static let purchaseEvent = "af_purchase"

    static func isActivityAction(_ url: URL) -> Bool {
        (url.scheme ?? "").lowercased() == scheme && (url.host ?? "").lowercased() == action
    }

    /// Purchase address consumed by the same protocol entry the activity page already uses.
    static func purchaseURL(amount: String, currency: String, transaction: String, product: String) -> URL? {
        var parts = URLComponents()
        parts.scheme = scheme
        parts.host = action
        parts.queryItems = [
            URLQueryItem(name: eventField, value: "buy"),
            URLQueryItem(name: amountField, value: amount),
            URLQueryItem(name: currencyField, value: currency),
            URLQueryItem(name: transactionField, value: transaction),
            URLQueryItem(name: productField, value: product),
        ]
        return parts.url
    }

    static func decodeActivityURL(_ url: URL) -> GrainSignal? {
        guard isActivityAction(url) else { return nil }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func value(_ name: String) -> String? {
            let raw = items.first { $0.name == name }?.value?.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let raw, !raw.isEmpty else { return nil }
            return raw
        }
        switch value(eventField)?.lowercased() {
        case "regist":
            return GrainSignal(source: .activity, kind: .registration, amount: nil, currency: nil, transactionId: nil, productId: nil)
        case "buy":
            guard let amountText = value(amountField),
                  let amount = Decimal(string: amountText, locale: Locale(identifier: "en_US_POSIX")),
                  amount > 0,
                  let currency = normalizedCurrency(value(currencyField)),
                  let transactionId = value(transactionField) else { return nil }
            return GrainSignal(
                source: .activity,
                kind: .purchase,
                amount: amount,
                currency: currency,
                transactionId: transactionId,
                productId: value(productField)
            )
        default:
            return nil
        }
    }

    /// HTTP 200 is one A-side registration call. Staying on the native page is the other. 480 does not use this helper.
    static func nativeRegistration(httpStatus: Int) -> GrainSignal? {
        guard httpStatus == 200 else { return nil }
        return GrainSignal(source: .native, kind: .registration, amount: nil, currency: nil, transactionId: nil, productId: nil)
    }

    struct TokenChoice: Equatable {
        var token: String
        var sends: Bool
    }

    static func token(for signal: GrainSignal, nativeRegistration: String, nativePurchase: String, nativeEnabled: Bool) -> TokenChoice {
        switch (signal.source, signal.kind) {
        case (.activity, .registration):
            return TokenChoice(token: activityRegistrationToken, sends: true)
        case (.activity, .purchase):
            return TokenChoice(token: activityPurchaseToken, sends: signal.amount != nil && signal.currency != nil && !(signal.transactionId ?? "").isEmpty)
        case (.native, .registration):
            _ = nativeRegistration
            _ = nativeEnabled
            return TokenChoice(token: loginEvent, sends: true)
        case (.native, .purchase):
            let token = nativePurchase.trimmingCharacters(in: .whitespacesAndNewlines)
            let ready = nativeEnabled && isOperatorToken(token, placeholder: nativePurchasePlaceholder)
            let priced = signal.amount != nil && signal.currency != nil && !(signal.transactionId ?? "").isEmpty
            return TokenChoice(token: token, sends: ready && priced)
        }
    }

    static func isOperatorToken(_ token: String, placeholder: String) -> Bool {
        guard token.count >= 6, token != placeholder else { return false }
        let lower = token.lowercased()
        if ["placeholder", "replace", "todo", "sample", "demo"].contains(where: { lower.contains($0) }) {
            return false
        }
        return token.unicodeScalars.allSatisfy(\.isASCII)
    }

    static func registrationMark(_ source: GrainSignalSource) -> String {
        "daygrain.adjust.registration.\(source.rawValue).sent"
    }

    static func purchaseMark(source: GrainSignalSource, transactionId: String) -> String {
        switch source {
        case .native:
            return "studio|\(transactionId)"
        case .activity:
            return "vessel|\(transactionId)"
        }
    }

    /// Earlier installs stored `daygrain.adjust.purchase.<source>.<id>`.
    static func settledPurchaseMark(_ key: String) -> String {
        let studioPrefix = "daygrain.adjust.purchase.native."
        let vesselPrefix = "daygrain.adjust.purchase.activity."
        if key.hasPrefix(studioPrefix) { return "studio|" + key.dropFirst(studioPrefix.count) }
        if key.hasPrefix(vesselPrefix) { return "vessel|" + key.dropFirst(vesselPrefix.count) }
        return key
    }

    static func purchaseAlreadyCovered(source: GrainSignalSource, transactionId: String, seen: Set<String>) -> Bool {
        if seen.contains(purchaseMark(source: source, transactionId: transactionId)) { return true }
        if source == .native {
            return seen.contains(purchaseMark(source: .activity, transactionId: transactionId))
        }
        return false
    }

    /// Amount plus a currency logs a purchase. Everything else logs registration.
    static func loggedEvent(for signal: GrainSignal) -> String {
        if signal.kind == .purchase,
           signal.amount != nil,
           let currency = signal.currency,
           !currency.isEmpty {
            return purchaseEvent
        }
        return loginEvent
    }

    static func shouldMark(sends: Bool, alreadyMarked: Bool) -> Bool {
        sends && !alreadyMarked
    }

    private static func normalizedCurrency(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let currency = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard currency.count == 3, currency.allSatisfy(\.isLetter) else { return nil }
        return currency
    }
}
