import AppTrackingTransparency
import Foundation
import SwiftUI

/// Soft explainer + system ATT. Copy stays limited to IAP measurement and Adjust.
@MainActor
final class TrackingConsent: ObservableObject {
    static let shared = TrackingConsent()

    @Published var showExplainer = false

    private static let promptedKey = "daygrain.att.prompted"

    var authorizationStatus: ATTrackingManager.AuthorizationStatus {
        ATTrackingManager.trackingAuthorizationStatus
    }

    /// Ask after the native journal is visible — never from cold launch alone.
    func askIfNeeded(after delay: TimeInterval = 1.4) {
        guard #available(iOS 14, *) else { return }
        guard authorizationStatus == .notDetermined else { return }
        guard !UserDefaults.standard.bool(forKey: Self.promptedKey) else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            guard self.authorizationStatus == .notDetermined else { return }
            guard !UserDefaults.standard.bool(forKey: Self.promptedKey) else { return }
            self.showExplainer = true
        }
    }

    func continueToSystemPrompt() {
        showExplainer = false
        UserDefaults.standard.set(true, forKey: Self.promptedKey)
        AdjustPulse.requestTrackingConsent { _ in }
    }

    func skipForNow() {
        showExplainer = false
        UserDefaults.standard.set(true, forKey: Self.promptedKey)
    }
}

@MainActor
struct TrackingExplainerSheet: View {
    @ObservedObject private var consent = TrackingConsent.shared

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Help Daygrain measure purchases")
                        .font(.system(size: 26, weight: .medium, design: .serif))
                    Text("Next, iOS may ask for permission to allow tracking. Daygrain uses this only to measure install attribution and in-app purchase performance with Adjust, our analytics partner.")
                        .font(.subheadline)
                        .foregroundColor(Palette.secondary)
                    Text("Journal notes, photos, and cloud AI text are never sent to Adjust for advertising profiles.")
                        .font(.subheadline)
                        .foregroundColor(Palette.secondary)
                    Button("Continue") {
                        consent.continueToSystemPrompt()
                    }
                    .buttonStyle(FilledButtonStyle())
                    Button("Not now") {
                        consent.skipForNow()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(22)
            }
            .pageBackground()
            .navigationTitle("App tracking")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }
}
