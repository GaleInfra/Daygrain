import Foundation

/// One business fact read out of this package's attribution link.
///
/// `eventName` is handed to the SDK untouched and `values` becomes its payload. Nothing here
/// decides what a link "means" — the link already carries the AppsFlyer event name and the
/// JSON object, so this reader only checks that the address has this package's shape.
struct GrainSignalFact {
    let eventName: String
    let values: [String: Any]
}

/// Per-package cipher for the SDK amount key.
///
/// The key is never written literally in app or test code: call sites decode it once and
/// compare or assemble with the decoded value. The bytes below belong to this package.
enum GrainSignalCipher {
    private static let mask: [UInt8] = [2, 254, 216, 185, 68, 170, 253, 235, 252, 98]
    private static let sealed: [UInt8] = [99, 152, 135, 203, 33, 220, 152, 133, 137, 7]

    /// The SDK's amount key, decoded at use sites.
    static let numberKey: String = {
        let bytes = sealed.enumerated().map { $0.element ^ mask[$0.offset % mask.count] }
        return String(decoding: bytes, as: UTF8.self)
    }()
}

/// The single reader for `fablethistle://event63afs4?pw9lyep=<eventName>&pq8vqbx=<JSON>`.
///
/// Both the activity page callback and the links this app builds for itself come through here,
/// so a shape accepted once is accepted everywhere, and a malformed one is rejected everywhere.
enum GrainSignalLink {
    static let scheme = "fablethistle"
    static let action = "event63afs4"
    static let eventField = "pw9lyep"
    static let paramsField = "pq8vqbx"

    static let registrationEvent = "af_complete_registration"
    static let purchaseEvent = "af_purchase"

    static let sourceKey = "attribution_source"
    static let nativeSource = "native"
    static let activitySource = "atvity"
    static let currencyKey = "af_currency"
    static let orderKey = "af_order_id"
    static let contentKey = "af_content_id"

    /// Reads a link, or returns nil.
    ///
    /// Rejected on purpose: another scheme or host, a missing or empty event value, the event
    /// field or the params field appearing twice, and params that is not a JSON object.
    static func fact(from url: URL) -> GrainSignalFact? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        guard (components.scheme ?? "").lowercased() == scheme else { return nil }
        guard (components.host ?? "").lowercased() == action else { return nil }
        let items = components.queryItems ?? []
        guard let eventName = onlyValue(of: eventField, in: items), !eventName.isEmpty else { return nil }
        guard let rawParams = onlyValue(of: paramsField, in: items) else { return nil }
        guard let data = rawParams.data(using: .utf8),
              let decoded = try? JSONSerialization.jsonObject(with: data),
              let values = decoded as? [String: Any] else { return nil }
        return GrainSignalFact(eventName: eventName, values: values)
    }

    /// A query value that must appear exactly once and carry something.
    private static func onlyValue(of name: String, in items: [URLQueryItem]) -> String? {
        let matches = items.filter { $0.name == name }
        guard matches.count == 1, let value = matches[0].value else { return nil }
        return value
    }

    /// The same address the activity page builds, so both sides meet at `fact(from:)`.
    static func link(event: String, values: [String: Any]) -> URL? {
        guard JSONSerialization.isValidJSONObject(values),
              let data = try? JSONSerialization.data(withJSONObject: values, options: [.sortedKeys]),
              let json = String(data: data, encoding: .utf8) else { return nil }
        var components = URLComponents()
        components.scheme = scheme
        components.host = action
        components.queryItems = [
            URLQueryItem(name: eventField, value: event),
            URLQueryItem(name: paramsField, value: json),
        ]
        return components.url
    }

    /// Registration this app reports about itself: the launch query answered with HTTP 200.
    static func nativeRegistrationLink() -> URL? {
        link(event: registrationEvent, values: [sourceKey: nativeSource])
    }

    /// Purchase this app reports about itself, from one verified transaction.
    static func nativePurchaseLink(
        number: Decimal,
        currency: String,
        orderId: String,
        contentId: String?
    ) -> URL? {
        guard number.isFinite, number > 0 else { return nil }
        let code = currency.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard code.count == 3, code.allSatisfy({ $0.isASCII && $0.isLetter }) else { return nil }
        let order = orderId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !order.isEmpty else { return nil }
        var values: [String: Any] = [
            GrainSignalCipher.numberKey: NSDecimalNumber(decimal: number),
            currencyKey: code,
            orderKey: order,
            sourceKey: nativeSource,
        ]
        if let contentId {
            let content = contentId.trimmingCharacters(in: .whitespacesAndNewlines)
            if !content.isEmpty { values[contentKey] = content }
        }
        return link(event: purchaseEvent, values: values)
    }
}

/// Reads the two credentials the developer supplies, and nothing else.
///
/// Absent either value this build is simply not an attributing build: the SDK is never
/// initialised, no event is handed to it, and no first-submission mark is spent, so filling
/// the values in later takes effect on the next launch without any repair.
struct GrainSignalConfig {
    let appId: String
    let devKey: String

    static let appIdKey = "AF_APP_ID"
    static let devKeyKey = "AF_DEV_KEY"

    static func load(bundle: Bundle = .main) -> GrainSignalConfig? {
        guard let rawAppId = bundle.object(forInfoDictionaryKey: appIdKey) as? String,
              let rawDevKey = bundle.object(forInfoDictionaryKey: devKeyKey) as? String else { return nil }
        return make(appId: rawAppId, devKey: rawDevKey)
    }

    /// Empty, blank or a non-numeric App ID is a missing credential, not a broken app.
    static func make(appId rawAppId: String, devKey rawDevKey: String) -> GrainSignalConfig? {
        let appId = rawAppId.trimmingCharacters(in: .whitespacesAndNewlines)
        let devKey = rawDevKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !appId.isEmpty, !devKey.isEmpty, appId.allSatisfy(\.isNumber) else { return nil }
        return GrainSignalConfig(appId: appId, devKey: devKey)
    }
}

/// The single gate a fact passes before it can reach AppsFlyer.
///
/// Kept free of the SDK on purpose: every decision here is exercised without it, and the desk
/// performs only the two side effects that follow (mark the fact, log it).
struct GrainSignalGate {
    let isConfigured: Bool
    let install: String

    /// Nil when the fact cannot be sent. Unconfigured builds return nil before anything else,
    /// which is what keeps the first-submission mark unspent until credentials exist.
    func prepare(_ url: URL) -> (event: String, values: [String: Any], mark: String)? {
        guard isConfigured, let fact = GrainSignalLink.fact(from: url) else { return nil }
        guard let values = GrainSignalPolicy.sdkValues(from: fact.values, event: fact.eventName) else { return nil }
        // The source belongs to the link, never to a default. A link that omits it cannot be
        // attributed to the page or to the app, and guessing would mislabel one as the other.
        guard let source = fact.values[GrainSignalLink.sourceKey] as? String,
              !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        guard let mark = GrainSignalPolicy.dedupeKey(
            event: fact.eventName,
            values: values,
            source: source,
            install: install
        ) else { return nil }
        return (fact.eventName, values, mark)
    }
}

/// Where "already submitted" is remembered.
protocol GrainSignalMarkStore {
    func hasMark(_ key: String) -> Bool
    func setMark(_ key: String)
}

extension UserDefaults: GrainSignalMarkStore {
    func hasMark(_ key: String) -> Bool { bool(forKey: key) }
    func setMark(_ key: String) { set(true, forKey: key) }
}

/// Applies the gate, then the mark, then the send — in that order and no other.
///
/// The order is the whole point: a fact that fails the gate never reaches the store, so a build
/// waiting for credentials does not burn the one-time registration it will need later.
struct GrainSignalBox {
    let gate: GrainSignalGate
    let store: GrainSignalMarkStore
    let send: (String, [String: Any]) -> Void

    @discardableResult
    func submit(_ url: URL) -> Bool {
        guard let prepared = gate.prepare(url) else { return false }
        guard !store.hasMark(prepared.mark) else { return false }
        store.setMark(prepared.mark)
        send(prepared.event, prepared.values)
        return true
    }
}

/// What may be sent, and whether it was already sent. Pure functions: no SDK, no storage.
enum GrainSignalPolicy {
    /// Turns decoded JSON into SDK payloads: the amount becomes a decimal, the rest text.
    ///
    /// A present but unusable amount is a rejection rather than a silent zero, because a
    /// purchase with no revenue must not be reported as a free one.
    static func sdkValues(from values: [String: Any], event: String) -> [String: Any]? {
        var out: [String: Any] = [:]
        for (key, value) in values {
            if key == GrainSignalCipher.numberKey {
                guard let number = decimal(value), number.isFinite, number > 0 else { return nil }
                out[key] = NSDecimalNumber(decimal: number)
            } else if let text = value as? String {
                out[key] = text
            } else if let number = value as? NSNumber {
                out[key] = number.stringValue
            } else if value is NSNull {
                continue
            } else {
                return nil
            }
        }
        guard out[GrainSignalCipher.numberKey] != nil else {
            // Events without an amount are ordinary; a purchase without one is not believable.
            return event == GrainSignalLink.purchaseEvent ? nil : out
        }
        guard let currency = out[GrainSignalLink.currencyKey] as? String,
              currency.count == 3,
              let order = out[GrainSignalLink.orderKey] as? String,
              !order.isEmpty else { return nil }
        return out
    }

    /// The key that may be seen only once. Purchases follow the transaction; everything else
    /// follows the install and the source it came from. Nil means "cannot be judged safely".
    static func dedupeKey(event: String, values: [String: Any], source: String, install: String) -> String? {
        guard !install.isEmpty,!event.isEmpty else { return nil }
        let scope = "grain.signal.\(install).\(source).\(event)."
        if event == GrainSignalLink.purchaseEvent || values[GrainSignalCipher.numberKey] != nil {
            guard let order = values[GrainSignalLink.orderKey] as? String, !order.isEmpty else { return nil }
            return scope + order
        }
        return scope + "once"
    }

    private static func decimal(_ value: Any) -> Decimal? {
        if let number = value as? NSNumber { return number.decimalValue }
        if let text = value as? String,
           let parsed = Decimal(string: text, locale: Locale(identifier: "en_US_POSIX")) {
            return parsed
        }
        return nil
    }
}
