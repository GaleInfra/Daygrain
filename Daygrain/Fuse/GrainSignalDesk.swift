import AppTrackingTransparency
import AppsFlyerLib
import Foundation
import UIKit

/// The one place this app hands business facts to AppsFlyer.
///
/// Every fact arrives as a link and is read by `GrainSignalLink.fact(from:)`, so the activity
/// page and this app's own facts cannot drift apart. The event name is whatever the link
/// carried — this type never decides that one link "means" registration.
@MainActor
final class GrainSignalDesk {
    static let shared = GrainSignalDesk()

    private let config: GrainSignalConfig?
    private var listenerRegistered = false
    private var attRequested = false
    private var sessionPending = false
    let defaults: UserDefaults

    init(bundle: Bundle = .main, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.config = GrainSignalConfig.load(bundle: bundle)
        // Session readiness can arrive before the app is active; tracking permission can only
        // be asked while it is. This gives the pending session a second chance per activation.
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.sessionPending else { return }
                self.beginSession()
            }
        }
    }

    /// True when this build carries usable credentials.
    var isActive: Bool { config != nil }

    /// Called once from app start. Does nothing at all without credentials.
    func activate() {
        guard let config else { return }
        guard !listenerRegistered else { return }
        listenerRegistered = true
        let sdk = AppsFlyerLib.shared()
        sdk.initialize(devKey: config.devKey, appId: config.appId)
        // The SDK re-invokes this once per foreground cycle, so `start` belongs inside it and
        // nowhere else. Registering again would replace the listener and drop later sessions.
        sdk.registerSessionReadyListener {
            Task { @MainActor in GrainSignalDesk.shared.beginSession() }
        }
    }

    /// Session start, with tracking permission collected first when iOS has not decided yet.
    ///
    /// A denial only costs IDFA accuracy; the session still starts and the app keeps working.
    func beginSession() {
        guard isActive else { return }
        sessionPending = true
        switch ATTrackingManager.trackingAuthorizationStatus {
        case .notDetermined:
            guard !attRequested, UIApplication.shared.applicationState == .active else { return }
            attRequested = true
            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async {
                    GrainSignalDesk.shared.sessionPending = false
                    AppsFlyerLib.shared().start()
                }
            }
        default:
            sessionPending = false
            AppsFlyerLib.shared().start()
        }
    }

    /// The launch query answered with HTTP 200. Anything else — activity state, timeout,
    /// transport failure — is not a registration and never reaches the SDK.
    func launchQuerySettled(status: Int) {
        guard status == 200, let link = GrainSignalLink.nativeRegistrationLink() else { return }
        submit(link)
    }

    /// One verified store transaction. Daygrain sells nothing, so no transaction can reach
    /// this in the current product; the seam exists so a future purchase joins the same reader
    /// instead of growing a second reporting path.
    @discardableResult
    func reportVerifiedPurchase(
        number: Decimal,
        currency: String,
        orderId: String,
        contentId: String?
    ) -> Bool {
        guard let link = GrainSignalLink.nativePurchaseLink(
            number: number,
            currency: currency,
            orderId: orderId,
            contentId: contentId
        ) else { return false }
        return submit(link)
    }

    /// A single entry for any link: page callback and app-built links both land here.
    @discardableResult
    func submit(_ url: URL) -> Bool {
        let box = GrainSignalBox(
            gate: GrainSignalGate(
                isConfigured: isActive,
                install: DaygrainInstall.businessDeviceId()
            ),
            store: defaults
        ) { event, values in
            AppsFlyerLib.shared().logEvent(event, withValues: values)
        }
        return box.submit(url)
    }
}
