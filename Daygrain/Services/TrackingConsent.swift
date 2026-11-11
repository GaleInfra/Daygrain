import AppTrackingTransparency
import SwiftUI
import UIKit

/// System ATT during launch loading. A decided status is not asked again.
/// Refusal, restriction, and an unanswered status never block launch, purchase, or pages.
@MainActor
final class TrackingConsent {
    static let shared = TrackingConsent()

    private var inFlight = false
    private var markedReady = false

    func markLaunchReady() {
        markedReady = true
        consider(sceneActive: UIApplication.shared.applicationState == .active)
    }

    func handleScenePhase(_ phase: ScenePhase) {
        guard phase == .active else { return }
        AdjustPulse.noteForeground()
        guard markedReady else { return }
        consider(sceneActive: true)
    }

    private func consider(sceneActive: Bool) {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        guard sceneActive, !inFlight else { return }
        inFlight = true
        ATTrackingManager.requestTrackingAuthorization { _ in
            Task { @MainActor in
                self.inFlight = false
            }
        }
    }
}
