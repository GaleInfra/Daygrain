import AppsFlyerLib
import SwiftUI
import UIKit

@main
@MainActor
struct DaygrainApp: App {
    @UIApplicationDelegateAdaptor(DaygrainLaunchDelegate.self) private var launchDelegate
    @StateObject private var store = JournalStore()
    @StateObject private var privacy = AppPrivacy()
    @AppStorage("appearance") private var appearance = "system"
    @State private var launchRoute: GrainLaunchRoute = .launching
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let navigation = UINavigationBarAppearance()
        navigation.configureWithTransparentBackground()
        navigation.backgroundColor = .clear
        navigation.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = navigation
        UINavigationBar.appearance().scrollEdgeAppearance = navigation
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: "302722") : UIColor(hex: "FFFCF7") }
        tab.stackedLayoutAppearance.normal.iconColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: "C5B19D") : UIColor(hex: "7A6859") }
        tab.stackedLayoutAppearance.selected.iconColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: "E4AD91") : UIColor(hex: "974B36") }
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
        UITextView.appearance().backgroundColor = .clear
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: "694B37") : UIColor(hex: "FFFCF7") }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch launchRoute {
                case .launching:
                    GrainLaunchGateView(route: $launchRoute)
                case .native:
                    RootView()
                        .environmentObject(store)
                        .environmentObject(privacy)
                        .environmentObject(GrainLedger.shared)
                        .environment(\.locale, Locale(identifier: "en_US"))
                        .preferredColorScheme(appearance == "system" ? nil : (appearance == "dark" ? .dark : .light))
                        .tint(Palette.accent)
                case .activity:
                    GrainActivityRepresentable()
                        .ignoresSafeArea()
                }
            }
            .onChange(of: scenePhase) { phase in
                TrackingConsent.shared.handleScenePhase(phase)
            }
        }
    }
}

final class DaygrainLaunchDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AppsFlyerLib.shared().isDebug = false
        AppsFlyerLib.shared().appleAppID = "id6826098188"
        AppsFlyerLib.shared().appsFlyerDevKey = "mEj7NMB3mBZQAjYpkvdDoT"
        AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didBecomeActiveNotification),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        AppsFlyerLib.shared().customerUserID = DaygrainInstall.businessDeviceId
        AppsFlyerLib.shared().start(completionHandler: { dictionary, error in
            if error != nil {
                print(error ?? "")
                return
            } else {
                print(dictionary ?? "")
                return
            }
        })
        return true
    }

    @objc func didBecomeActiveNotification() {
        Task { @MainActor in
            TrackingConsent.shared.markLaunchReady()
        }
    }
}
